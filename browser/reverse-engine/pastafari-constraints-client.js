/* Vendored without semantic modification from Sargon17-Green/pastafari-calendar main.
 * Source blob: 11660b6c47b29fdd388e0e0e05a4ccb0d1a1edc0
 * Phase E reverse-search contract. Do not edit here independently of the source contract.
 */
"use strict";

import {
  beginDiagnosticOperation,
  endDiagnosticOperation,
  getPastafariDiagnosticsTransportConfig,
  incrementDiagnosticCounter,
  mergePastafariDiagnosticsSnapshot,
  recordDiagnosticError,
} from "./pastafari-diagnostics.js";

const REVERSE_WORKER_URL = new URL("./pastafari-reverse-worker.js", import.meta.url);
const STARTUP_TIMEOUT_MS = 45_000;

function createError(name, message, code, extra = {}) {
  const error = new Error(message);
  error.name = name || "Error";
  if (code) error.code = code;
  Object.assign(error, extra);
  return error;
}

function reviveWorkerError(serialized) {
  return createError(
    serialized?.name || "Error",
    serialized?.message || "Pastafari constraint solving failed.",
    serialized?.code || "ERR_CONSTRAINT_WORKER",
    { workerStack: serialized?.stack || "", ...(serialized?.extra || {}) },
  );
}

function abortError(message = "Pastafari constraint solving was aborted.") {
  return createError("AbortError", message, "ERR_REVERSE_ABORTED");
}

function timeoutError(timeoutMs) {
  return createError(
    "TimeoutError",
    `Pastafari constraint solving did not finish within ${timeoutMs} ms.`,
    "ERR_REVERSE_TIMEOUT",
  );
}

function serializableOptions(options) {
  const result = { ...options };
  delete result.signal;
  delete result.onProgress;
  delete result.timeoutMs;
  return result;
}

export class PastafariConstraintClient {
  constructor(options = {}) {
    this.startupTimeoutMs = options.startupTimeoutMs ?? STARTUP_TIMEOUT_MS;
    this._worker = null;
    this._inline = false;
    this._ready = null;
    this._pending = new Map();
    this._nextId = 1;
  }

  async solve(problem, options = {}) {
    if (options === null || typeof options !== "object") {
      throw new TypeError("solvePastafariConstraints options must be an object.");
    }
    if (options.signal?.aborted) throw abortError();
    if (options.onProgress !== undefined && typeof options.onProgress !== "function") {
      throw new TypeError("onProgress must be a function.");
    }
    const timeoutMs = options.timeoutMs === undefined ? null : Number(options.timeoutMs);
    if (timeoutMs !== null && (!Number.isSafeInteger(timeoutMs) || timeoutMs < 1)) {
      throw new RangeError("timeoutMs must be a positive safe integer.");
    }

    const transportState = this._ready ? "reused" : "cold";
    const token = beginDiagnosticOperation("constraints-client", "solve", {
      timeoutMs,
      transportState,
    });
    try {
      await this._ensureReady();
    } catch (error) {
      const outcome = error?.name === "TimeoutError" ? "timeout" : "error";
      recordDiagnosticError("constraints-client", error, token?.id, { phase: "initialize" });
      endDiagnosticOperation(token, outcome, { phase: "initialize", timeoutMs, transportState });
      throw error;
    }
    if (this._inline) {
      try {
        const result = await this._solveInline(problem, options, timeoutMs);
        endDiagnosticOperation(token, "ok", { mode: "inline", phase: "compute", transportState });
        return result;
      } catch (error) {
        const outcome = error?.name === "TimeoutError" ? "timeout" : error?.name === "AbortError" ? "cancelled" : "error";
        recordDiagnosticError("constraints-client", error, token?.id);
        endDiagnosticOperation(token, outcome, { mode: "inline", phase: "compute", timeoutMs, transportState });
        throw error;
      }
    }

    const id = this._nextId++;
    return new Promise((resolve, reject) => {
      let timer = null;
      const cleanup = () => {
        if (timer !== null) clearTimeout(timer);
        options.signal?.removeEventListener("abort", onAbort);
        this._pending.delete(id);
      };
      const cancel = (error) => {
        const pending = this._pending.get(id);
        if (!pending) return;
        incrementDiagnosticCounter(`constraints-client.${error?.name === "TimeoutError" ? "timeouts" : "cancellations"}`);
        try {
          this._worker.postMessage({ id, kind: "cancel" });
        } catch {
          // Best effort: the caller is already receiving the cancellation.
        }
        pending.reject(error);
      };
      const onAbort = () => cancel(abortError());

      this._pending.set(id, {
        resolve: (result) => {
          const pending = this._pending.get(id);
          cleanup();
          endDiagnosticOperation(token, "ok", {
            mode: "worker", phase: "search", transportState,
            progressEvents: pending?.progressEvents ?? 0,
            lastProgress: pending?.lastProgress ?? null,
          });
          resolve(result);
        },
        reject: (error) => {
          const pending = this._pending.get(id);
          cleanup();
          const outcome = error?.name === "TimeoutError" ? "timeout" : error?.name === "AbortError" ? "cancelled" : "error";
          recordDiagnosticError("constraints-client", error, token?.id, { phase: "search" });
          endDiagnosticOperation(token, outcome, {
            mode: "worker", phase: "search", timeoutMs, transportState,
            progressEvents: pending?.progressEvents ?? 0,
            lastProgress: pending?.lastProgress ?? null,
          });
          reject(error);
        },
        onProgress: options.onProgress,
        progressEvents: 0,
        lastProgress: null,
      });
      options.signal?.addEventListener("abort", onAbort, { once: true });
      if (timeoutMs !== null) timer = setTimeout(() => cancel(timeoutError(timeoutMs)), timeoutMs);

      try {
        this._worker.postMessage({
          id,
          kind: "solve",
          payload: { problem, options: serializableOptions(options) },
          diagnostics: getPastafariDiagnosticsTransportConfig(),
        });
      } catch (error) {
        this._pending.get(id)?.reject(error);
      }
    });
  }

  dispose() {
    incrementDiagnosticCounter("constraints-client.dispose");
    const error = abortError("Pastafari constraint client was disposed.");
    for (const pending of this._pending.values()) pending.reject(error);
    this._pending.clear();
    try { this._worker?.terminate(); } catch { /* best effort */ }
    this._worker = null;
    this._inline = false;
    this._ready = null;
  }

  async _ensureReady() {
    if (this._ready) {
      incrementDiagnosticCounter("constraints-client.transport.reused");
      return this._ready;
    }
    incrementDiagnosticCounter("constraints-client.transport.cold");
    const token = beginDiagnosticOperation("constraints-client", "initialize", { startupTimeoutMs: this.startupTimeoutMs });
    this._ready = this._start().then((value) => {
      endDiagnosticOperation(token, "ok", { mode: this._inline ? "inline" : "worker" });
      return value;
    }).catch((error) => {
      const outcome = error?.name === "TimeoutError" ? "timeout" : "error";
      recordDiagnosticError("constraints-client", error, token?.id, { phase: "initialize" });
      endDiagnosticOperation(token, outcome, { phase: "initialize" });
      this.dispose();
      throw error;
    });
    return this._ready;
  }

  async _solveInline(problem, options, timeoutMs) {
    const moduleNamespace = await import("./pastafari-constraints.js");
    if (timeoutMs === null) {
      return moduleNamespace.solvePastafariConstraintsDirect(problem, options);
    }
    const controller = new AbortController();
    const onAbort = () => controller.abort();
    options.signal?.addEventListener("abort", onAbort, { once: true });
    let timer;
    try {
      return await Promise.race([
        moduleNamespace.solvePastafariConstraintsDirect(problem, { ...options, signal: controller.signal }),
        new Promise((_, reject) => {
          timer = setTimeout(() => {
            controller.abort();
            reject(timeoutError(timeoutMs));
          }, timeoutMs);
        }),
      ]);
    } finally {
      clearTimeout(timer);
      options.signal?.removeEventListener("abort", onAbort);
    }
  }

  async _start() {
    if (typeof globalThis.Worker !== "function") {
      this._inline = true;
      incrementDiagnosticCounter("constraints-client.mode.inline");
      return;
    }
    await new Promise((resolve, reject) => {
      const creationToken = beginDiagnosticOperation("constraints-client", "worker-create");
      let worker;
      try {
        worker = new Worker(REVERSE_WORKER_URL, { type: "module", name: "pastafari-constraints" });
        endDiagnosticOperation(creationToken, "ok");
      } catch (error) {
        endDiagnosticOperation(creationToken, "error");
        throw error;
      }
      this._worker = worker;
      incrementDiagnosticCounter("constraints-client.mode.worker");
      const timer = setTimeout(() => reject(createError(
        "TimeoutError",
        `Pastafari constraint worker did not start within ${this.startupTimeoutMs} ms.`,
        "ERR_REVERSE_STARTUP_TIMEOUT",
      )), this.startupTimeoutMs);
      const finish = (handler, value) => { clearTimeout(timer); handler(value); };
      worker.addEventListener("message", (event) => {
        const message = event.data;
        if (message?.kind === "ready") {
          incrementDiagnosticCounter("constraints-client.worker.ready");
          finish(resolve);
          return;
        }
        if (!message || !Number.isSafeInteger(message.id)) return;
        const pending = this._pending.get(message.id);
        if (!pending) return;
        if (message.kind === "progress") {
          incrementDiagnosticCounter("constraints-client.progress-events");
          pending.progressEvents += 1;
          pending.lastProgress = message.progress;
          try { pending.onProgress?.(message.progress); }
          catch (error) {
            pending.reject(error);
            try { worker.postMessage({ id: message.id, kind: "cancel" }); } catch { /* best effort */ }
          }
          return;
        }
        if (message.kind === "result") {
          if (message.diagnostics) mergePastafariDiagnosticsSnapshot("worker.constraints", message.diagnostics);
          if (message.ok) pending.resolve(message.result);
          else pending.reject(reviveWorkerError(message.error));
        }
      });
      worker.addEventListener("error", (event) => {
        const error = createError("Error", event.message || "Pastafari constraint worker failed.", "ERR_REVERSE_WORKER_LOAD");
        for (const pending of this._pending.values()) pending.reject(error);
        finish(reject, error);
      });
      worker.addEventListener("messageerror", () => {
        const error = createError("DataCloneError", "Pastafari constraint worker returned an unreadable message.", "ERR_REVERSE_WORKER_MESSAGE");
        for (const pending of this._pending.values()) pending.reject(error);
      });
    });
  }
}

export const sharedPastafariConstraintClient = new PastafariConstraintClient();

export function solvePastafariConstraints(problem, options = {}) {
  return sharedPastafariConstraintClient.solve(problem, options);
}

export { SAME_AS_TARGET } from "./pastafari-calendar-fast.js";
