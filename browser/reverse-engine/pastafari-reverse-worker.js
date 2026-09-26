/* Vendored without semantic modification from Sargon17-Green/pastafari-calendar main.
 * Source blob: 85054e6c5191ab460f38b0b585415f58e0f33ec9
 * Phase E reverse-search contract. Do not edit here independently of the source contract.
 */
"use strict";

import {
  applyPastafariDiagnosticsTransportConfig,
  beginDiagnosticOperation,
  endDiagnosticOperation,
  getPastafariDiagnosticsSnapshot,
  incrementDiagnosticCounter,
  isPastafariDiagnosticsEnabled,
  recordDiagnosticError,
} from "./pastafari-diagnostics.js";
import { findPastafariDate as findPastafariDateDirect } from "./pastafari-calendar-fast.js";
import { solvePastafariConstraintsDirect } from "./pastafari-constraints.js";

const activeRequests = new Map();

function serializeError(error) {
  return {
    name: error?.name || "Error",
    message: error?.message || String(error),
    code: error?.code || null,
    stack: error?.stack || "",
  };
}

export async function handlePastafariReverseRequest(payload = {}, hooks = {}) {
  if (payload === null || typeof payload !== "object") {
    throw new TypeError("The reverse worker payload must be an object.");
  }

  const sourceOptions = payload.options ?? {};
  if (sourceOptions === null || typeof sourceOptions !== "object") {
    throw new TypeError("The reverse worker options must be an object.");
  }

  const options = { ...sourceOptions };
  if (Object.hasOwn(options, "todaySnapshot")) {
    const todaySnapshot = options.todaySnapshot;
    delete options.todaySnapshot;
    options.todayProvider = () => todaySnapshot;
  }
  if (hooks.signal !== undefined) options.signal = hooks.signal;
  if (hooks.onProgress !== undefined) options.onProgress = hooks.onProgress;

  return findPastafariDateDirect(payload.pastafariDate, options);
}

export async function handlePastafariConstraintRequest(payload = {}, hooks = {}) {
  if (payload === null || typeof payload !== "object") {
    throw new TypeError("The constraint worker payload must be an object.");
  }

  const sourceOptions = payload.options ?? {};
  if (sourceOptions === null || typeof sourceOptions !== "object") {
    throw new TypeError("The constraint worker options must be an object.");
  }

  const options = { ...sourceOptions };
  if (hooks.signal !== undefined) options.signal = hooks.signal;
  if (hooks.onProgress !== undefined) options.onProgress = hooks.onProgress;

  return solvePastafariConstraintsDirect(payload.problem, options);
}

const isDedicatedWorker = (
  typeof DedicatedWorkerGlobalScope !== "undefined"
  && globalThis instanceof DedicatedWorkerGlobalScope
);

if (isDedicatedWorker) {
  globalThis.addEventListener("message", async (event) => {
    const message = event.data;
    if (!message || !Number.isSafeInteger(message.id)) return;

    if (message.kind === "cancel") {
      incrementDiagnosticCounter("worker.reverse.cancel-requests");
      const controller = activeRequests.get(message.id);
      if (controller) {
        incrementDiagnosticCounter("worker.reverse.cancel-active");
        controller.abort();
      } else {
        incrementDiagnosticCounter("worker.reverse.cancel-missing");
      }
      return;
    }
    if (message.kind !== "find" && message.kind !== "solve") return;

    applyPastafariDiagnosticsTransportConfig(message.diagnostics);
    const controller = new AbortController();
    activeRequests.set(message.id, controller);
    incrementDiagnosticCounter("worker.reverse.requests.started");
    const token = beginDiagnosticOperation("worker.reverse", message.kind, { requestId: message.id });
    try {
      const hooks = {
        signal: controller.signal,
        onProgress: (progress) => {
          globalThis.postMessage({ id: message.id, kind: "progress", progress });
        },
      };
      const result = message.kind === "find"
        ? await handlePastafariReverseRequest(message.payload, hooks)
        : await handlePastafariConstraintRequest(message.payload, hooks);
      endDiagnosticOperation(token, "ok", { kind: message.kind });
      globalThis.postMessage({
        id: message.id,
        kind: "result",
        ok: true,
        result,
        diagnostics: isPastafariDiagnosticsEnabled() ? getPastafariDiagnosticsSnapshot() : null,
      });
    } catch (error) {
      const outcome = error?.name === "AbortError" ? "cancelled" : "error";
      recordDiagnosticError("worker.reverse", error, token?.id, { kind: message.kind });
      endDiagnosticOperation(token, outcome, { kind: message.kind });
      globalThis.postMessage({
        id: message.id,
        kind: "result",
        ok: false,
        error: serializeError(error),
        diagnostics: isPastafariDiagnosticsEnabled() ? getPastafariDiagnosticsSnapshot() : null,
      });
    } finally {
      activeRequests.delete(message.id);
      incrementDiagnosticCounter("worker.reverse.requests.settled");
    }
  });

  globalThis.postMessage({ kind: "ready" });
}
