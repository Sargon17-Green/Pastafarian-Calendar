'use strict';

(function (root) {
  const ns = root.PastafariBrowserInternal || (root.PastafariBrowserInternal = Object.create(null));
  const normalizeCalendarResult = ns.resultNormalizer && ns.resultNormalizer.normalizeCalendarResult;
  const DEFAULT_TIMEOUT_MS = 240000;
  const BUILD_MISMATCH_CODE = 'ERR_BROWSER_BUILD_MISMATCH';

  function deserializeView(value) {
    if (!value || typeof value !== 'object') throw new TypeError('Li worker retornat un ínvalid cutlet-view.');
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

  function deepFreezePlain(value, seen = new Set()) {
    if (value === null || typeof value !== 'object' || seen.has(value)) return value;
    seen.add(value);
    const items = Array.isArray(value) ? value : Object.values(value);
    for (const item of items) deepFreezePlain(item, seen);
    return Object.freeze(value);
  }

  function normalizeCookingTraceOptions(options) {
    if (options === null || options === undefined) {
      return { onGateSauceDetail: null, gateDetailGateIndices: null, timeoutMs: null };
    }
    if (!options || typeof options !== 'object' || Array.isArray(options)) {
      throw new TypeError('Li cooking-trace options deve esser un plain object.');
    }
    const onGateSauceDetail = options.onGateSauceDetail === undefined
      ? null : options.onGateSauceDetail;
    if (onGateSauceDetail !== null && typeof onGateSauceDetail !== 'function') {
      throw new TypeError('onGateSauceDetail deve esser null o un function.');
    }
    let gateDetailGateIndices = null;
    if (options.gateDetailGateIndices !== undefined && options.gateDetailGateIndices !== null) {
      if (!Array.isArray(options.gateDetailGateIndices)) {
        throw new TypeError('gateDetailGateIndices deve esser null o un array.');
      }
      gateDetailGateIndices = options.gateDetailGateIndices.map((value) => {
        const index = BigInt(value);
        if (index === 0n) throw new RangeError('Un gate-detail index ne posse esser zero.');
        return index;
      });
      if (onGateSauceDetail === null) {
        throw new TypeError('gateDetailGateIndices exige onGateSauceDetail.');
      }
    }
    const timeoutMs = options.timeoutMs == null ? null : Number(options.timeoutMs);
    if (timeoutMs !== null && (!Number.isFinite(timeoutMs) || timeoutMs <= 0)) {
      throw new RangeError('timeoutMs del cooking trace deve esser positiv.');
    }
    return { onGateSauceDetail, gateDetailGateIndices, timeoutMs };
  }

  function errorFromPayload(payload) {
    const error = new Error(payload && payload.message ? String(payload.message) : 'Li calendarium-worker raportat un ínconosset errore.');
    if (payload && payload.name) error.name = String(payload.name);
    if (payload && payload.code) error.code = String(payload.code);
    return error;
  }

  function buildMismatchError(expected, actual) {
    const error = new Error(
      'Li browser main-bundle e Worker ne apartene al sam build: expectat '
      + String(expected) + ', obtenet ' + (actual == null || actual === '' ? '(mancant)' : String(actual)) + '.',
    );
    error.name = 'BrowserBuildMismatchError';
    error.code = BUILD_MISMATCH_CODE;
    error.expectedBuildId = String(expected);
    error.actualBuildId = actual == null ? null : String(actual);
    return error;
  }

  class PastafariEngineClient {
    constructor(options) {
      const selected = options || {};
      const config = root.PastafariBrowserConfig || {};
      this.workerFactory = selected.workerFactory || null;
      this.workerUrl = selected.workerUrl || null;
      this.workerSource = selected.workerSource || null;
      this.buildId = selected.buildId != null
        ? String(selected.buildId)
        : (config.buildId != null && String(config.buildId) !== '' ? String(config.buildId) : null);
      this.timeoutMs = selected.timeoutMs || DEFAULT_TIMEOUT_MS;
      this.worker = null;
      this.workerObjectUrl = null;
      this.nextRequestId = 1;
      this.pending = new Map();
    }

    _createWorker() {
      if (this.workerFactory) return this.workerFactory();
      if (typeof root.Worker !== 'function') throw new Error('Ti navigator ne supporta Web Workers.');
      const config = root.PastafariBrowserConfig || {};
      const source = this.workerSource || config.workerSource || null;
      if (source != null) {
        if (typeof root.Blob !== 'function' || !root.URL || typeof root.URL.createObjectURL !== 'function') {
          throw new Error('Ti navigator ne supporta li Blob Worker besonat por li Standalone variante.');
        }
        const blob = new Blob([String(source)], { type: 'text/javascript' });
        this.workerObjectUrl = URL.createObjectURL(blob);
        return new Worker(this.workerObjectUrl, { name: 'pastafari-calendar' });
      }
      const url = this.workerUrl || config.workerUrl;
      if (!url) throw new Error('Null URL por li calendarium-worker esset configurat.');
      return new Worker(url, { name: 'pastafari-calendar' });
    }

    _ensureWorker() {
      if (this.worker) return this.worker;
      const worker = this._createWorker();
      worker.addEventListener('message', (event) => this._handleMessage(event.data));
      worker.addEventListener('error', (event) => {
        this._handleFatal(event && event.error ? event.error : new Error(event && event.message ? event.message : 'Errore del calendarium-worker'));
      });
      worker.addEventListener('messageerror', () => {
        this._handleFatal(new Error('Li worker retornat un message quel ne posse esser clonat.'));
      });
      this.worker = worker;
      return worker;
    }

    _handleMessage(message) {
      const id = Number(message && message.id);
      const entry = this.pending.get(id);
      if (!entry) return;
      if (this.buildId != null) {
        const actualBuildId = message && message.buildId != null ? String(message.buildId) : null;
        if (actualBuildId !== this.buildId) {
          this._handleFatal(buildMismatchError(this.buildId, actualBuildId));
          return;
        }
      }
      if (message && message.ok && message.kind === 'gate-detail') {
        if (typeof entry.onChunk !== 'function') {
          this._handleFatal(new Error('Li Worker inviat un gate-detail chunk sin un registrat sink.'));
          return;
        }
        try {
          entry.onChunk(deepFreezePlain(message.value));
        } catch (error) {
          this._handleFatal(error);
        }
        return;
      }
      this.pending.delete(id);
      clearTimeout(entry.timer);
      if (message.ok) entry.resolve(message.value);
      else entry.reject(errorFromPayload(message.error));
    }

    _handleFatal(error) {
      const worker = this.worker;
      this.worker = null;
      try { if (worker) worker.terminate(); } catch (_) {}
      if (this.workerObjectUrl) {
        try { URL.revokeObjectURL(this.workerObjectUrl); } catch (_) {}
        this.workerObjectUrl = null;
      }
      for (const entry of this.pending.values()) {
        clearTimeout(entry.timer);
        entry.reject(error instanceof Error ? error : new Error(String(error)));
      }
      this.pending.clear();
    }

    _request(operation, payload, timeoutMs, onChunk = null) {
      const worker = this._ensureWorker();
      const id = this.nextRequestId++;
      const limit = timeoutMs || this.timeoutMs;
      return new Promise((resolve, reject) => {
        const timer = setTimeout(() => {
          if (!this.pending.has(id)) return;
          this._handleFatal(new Error('Li operation ' + operation + ' excedet ' + limit + ' ms.'));
        }, limit);
        this.pending.set(id, { resolve, reject, timer, onChunk });
        try {
          const message = { id, operation, ...payload };
          if (this.buildId != null) message.buildId = this.buildId;
          worker.postMessage(message);
        } catch (error) {
          clearTimeout(timer);
          this.pending.delete(id);
          reject(error);
        }
      });
    }

    async convert(calculationDay, targetDay) {
      const value = await this._request('convert', {
        calculationDay: String(BigInt(calculationDay)),
        targetDay: String(BigInt(targetDay)),
      });
      return normalizeCalendarResult(value);
    }

    async getCutletView(calculationDay, targetDay) {
      return deserializeView(await this._request('getCutletView', {
        calculationDay: String(BigInt(calculationDay)),
        targetDay: String(BigInt(targetDay)),
      }));
    }

    async getCookingTrace(calculationDay, targetDay, options = null) {
      const selected = normalizeCookingTraceOptions(options);
      const payload = {
        calculationDay: String(BigInt(calculationDay)),
        targetDay: String(BigInt(targetDay)),
        streamGateSauceDetail: selected.onGateSauceDetail !== null,
      };
      if (selected.gateDetailGateIndices !== null) {
        payload.gateDetailGateIndices = selected.gateDetailGateIndices.map((value) => String(value));
      }
      const value = await this._request(
        'cookingTrace',
        payload,
        selected.timeoutMs,
        selected.onGateSauceDetail,
      );
      return deepFreezePlain(value);
    }

    retry() {
      this._handleFatal(new Error('Li calendarium-worker esset reinicialisat.'));
    }

    dispose() {
      this._handleFatal(new Error('Li calendarium-client esset cludet.'));
    }
  }

  ns.engineClient = Object.freeze({ PastafariEngineClient, DEFAULT_TIMEOUT_MS, BUILD_MISMATCH_CODE });
})(typeof globalThis === 'object' ? globalThis : this);
