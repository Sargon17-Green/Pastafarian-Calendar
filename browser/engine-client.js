import { normalizeCalendarResult } from "./result-normalizer.js";

const DEFAULT_TIMEOUT_MS = 240000;

function deserializeView(value) {
  if (!value || typeof value !== "object") throw new TypeError("Li worker retornat un ínvalid cutlet-view.");
  return Object.freeze({
    selectedDay: BigInt(value.selectedDay),
    selectedIndex: Number(value.selectedIndex),
    startDay: BigInt(value.startDay),
    endDay: BigInt(value.endDay),
    previousCutletDay: BigInt(value.previousCutletDay),
    nextCutletDay: BigInt(value.nextCutletDay),
    year: String(value.year),
    cutletName: String(value.cutletName),
    days: Object.freeze(value.days.map((day) => Object.freeze({
      day: BigInt(day.day),
      ...normalizeCalendarResult(day),
    }))),
  });
}

function errorFromPayload(payload) {
  const error = new Error(payload?.message || "Li calendarium-worker raportat un ínconosset errore.");
  if (payload?.name) error.name = String(payload.name);
  if (payload?.code) error.code = String(payload.code);
  return error;
}

export class PastafariEngineClient {
  constructor({ workerFactory = null, workerUrl = null, timeoutMs = DEFAULT_TIMEOUT_MS } = {}) {
    this.workerFactory = workerFactory;
    this.workerUrl = workerUrl;
    this.timeoutMs = timeoutMs;
    this.worker = null;
    this.nextRequestId = 1;
    this.pending = new Map();
  }

  _createWorker() {
    if (this.workerFactory) return this.workerFactory();
    if (typeof Worker !== "function") throw new Error("Ti navigator ne supporta Web Workers.");
    const url = this.workerUrl ?? new URL("./pastafari-worker.js", import.meta.url);
    return new Worker(url, { type: "module", name: "pastafari-calendar" });
  }

  _ensureWorker() {
    if (this.worker) return this.worker;
    const worker = this._createWorker();
    const onMessage = (event) => this._handleMessage(event.data);
    const onError = (event) => this._handleFatal(event?.error || new Error(event?.message || "Errore del Worker"));
    const onMessageError = () => this._handleFatal(new Error("Li worker retornat un message quel ne posse esser clonat."));
    if (typeof worker.addEventListener === "function") {
      worker.addEventListener("message", onMessage);
      worker.addEventListener("error", onError);
      worker.addEventListener("messageerror", onMessageError);
    } else {
      worker.onmessage = onMessage;
      worker.onerror = onError;
      worker.onmessageerror = onMessageError;
    }
    this.worker = worker;
    return worker;
  }

  _handleMessage(message) {
    const id = Number(message?.id);
    const entry = this.pending.get(id);
    if (!entry) return;
    this.pending.delete(id);
    clearTimeout(entry.timer);
    if (message.ok) entry.resolve(message.value);
    else entry.reject(errorFromPayload(message.error));
  }

  _handleFatal(error) {
    const worker = this.worker;
    this.worker = null;
    try { worker?.terminate?.(); } catch {}
    for (const entry of this.pending.values()) {
      clearTimeout(entry.timer);
      entry.reject(error instanceof Error ? error : new Error(String(error)));
    }
    this.pending.clear();
  }

  _request(operation, payload, timeoutMs = this.timeoutMs) {
    const worker = this._ensureWorker();
    const id = this.nextRequestId++;
    return new Promise((resolve, reject) => {
      const timer = setTimeout(() => {
        if (!this.pending.has(id)) return;
        this._handleFatal(new Error(`Li operation ${operation} excedet ${timeoutMs} ms.`));
      }, timeoutMs);
      this.pending.set(id, { resolve, reject, timer });
      try {
        worker.postMessage({ id, operation, ...payload });
      } catch (error) {
        clearTimeout(timer);
        this.pending.delete(id);
        reject(error);
      }
    });
  }

  async convert(calculationDay, targetDay) {
    const value = await this._request("convert", {
      calculationDay: String(BigInt(calculationDay)),
      targetDay: String(BigInt(targetDay)),
    });
    return normalizeCalendarResult(value);
  }

  async getCutletView(calculationDay, targetDay) {
    const value = await this._request("getCutletView", {
      calculationDay: String(BigInt(calculationDay)),
      targetDay: String(BigInt(targetDay)),
    });
    return deserializeView(value);
  }

  async retry() {
    this._handleFatal(new Error("Li calendarium-worker esset reinicialisat."));
  }

  dispose() {
    this._handleFatal(new Error("Li calendarium-client esset cludet."));
  }
}
