'use strict';

const crypto = require('node:crypto');
const fs = require('node:fs/promises');
const path = require('node:path');
const codec = require('./cache-codec');
const { EngineWorkerClient } = require('./engine-worker-client');

const SNAPSHOT_SCOPES = Object.freeze([
  'gate-days',
  'gate-gaps',
  'year-5000',
  'year-transitions',
  'year-histories',
  'semantic-structures',
  'selection-results',
  'sauce-stage56',
]);

function requireIntegerDay(value, label) {
  if (typeof value === 'bigint') return value;
  if (typeof value === 'number') {
    if (!Number.isSafeInteger(value)) throw new RangeError(label + ' deve esser un safe integer o decimal string.');
    return BigInt(value);
  }
  const text = String(value == null ? '' : value).trim();
  if (!/^-?\d+$/.test(text)) throw new TypeError(label + ' deve esser un integer decimal.');
  return BigInt(text);
}

async function semanticFingerprint(corePath, override) {
  if (override) return String(override).trim();
  const bytes = await fs.readFile(corePath);
  return crypto.createHash('sha256').update(bytes).digest('hex').slice(0, 32);
}

function finalCacheKey(fingerprint, calculationDay, targetDay) {
  return 'pastafari:stage59:' + fingerprint + ':final:' + calculationDay + ':' + targetDay;
}

function snapshotCacheKey(fingerprint, scope) {
  return 'pastafari:stage59:' + fingerprint + ':stage58:' + scope;
}

class ServerCalendarEngine {
  constructor(options) {
    const selected = options || {};
    if (!selected.store) throw new TypeError('ServerCalendarEngine exige un cache store.');
    this.store = selected.store;
    this.corePath = path.resolve(selected.corePath || path.resolve(__dirname, '..', 'src', 'index.js'));
    this.workerPath = selected.workerPath;
    this.fingerprintOverride = selected.fingerprint || null;
    this.workerFactory = selected.workerFactory || ((workerOptions) => new EngineWorkerClient(workerOptions));
    this.worker = null;
    this.fingerprint = null;
    this.initialized = false;
    this.initializing = null;
    this.inflight = new Map();
    this.metrics = {
      requests: 0,
      finalHits: 0,
      finalMisses: 0,
      finalCorruptions: 0,
      singleFlightJoins: 0,
      workerComputations: 0,
      workerFailures: 0,
      cacheReadFailures: 0,
      cacheWriteFailures: 0,
      intermediateSnapshotsLoaded: 0,
      intermediateSnapshotsWritten: 0,
    };
  }

  async initialize() {
    if (this.initialized) return;
    if (this.initializing) return this.initializing;
    this.initializing = (async () => {
      this.fingerprint = await semanticFingerprint(this.corePath, this.fingerprintOverride);
      const initialSnapshots = Object.create(null);
      for (const scope of SNAPSHOT_SCOPES) {
        const key = snapshotCacheKey(this.fingerprint, scope);
        try {
          const raw = await this.store.get(key);
          if (raw != null) {
            // Validate now; worker receives the original encoded blob and validates again.
            const decoded = codec.decode(raw);
            if (Array.isArray(decoded)) {
              initialSnapshots[scope] = raw;
              this.metrics.intermediateSnapshotsLoaded += 1;
            }
          }
        } catch (_) {
          this.metrics.cacheReadFailures += 1;
        }
      }
      const worker = this.workerFactory({
        corePath: this.corePath,
        workerPath: this.workerPath,
        initialSnapshots,
      });
      this.worker = worker;
      await worker.start();
      this.initialized = true;
    })();
    try { await this.initializing; }
    finally { this.initializing = null; }
  }

  async _cacheGet(key) {
    try { return await this.store.get(key); }
    catch (_) { this.metrics.cacheReadFailures += 1; return null; }
  }

  async _cacheSet(key, value) {
    try { await this.store.set(key, value); return true; }
    catch (_) { this.metrics.cacheWriteFailures += 1; return false; }
  }

  async _persistSnapshots(snapshots) {
    if (!snapshots || typeof snapshots !== 'object') return;
    for (const [scope, encoded] of Object.entries(snapshots)) {
      if (!SNAPSHOT_SCOPES.includes(scope) || typeof encoded !== 'string') continue;
      if (await this._cacheSet(snapshotCacheKey(this.fingerprint, scope), encoded)) {
        this.metrics.intermediateSnapshotsWritten += 1;
      }
    }
  }

  async convert(calculationDayInput, targetDayInput) {
    await this.initialize();
    const calculationDay = requireIntegerDay(calculationDayInput, 'calculationDay');
    const targetDay = requireIntegerDay(targetDayInput, 'targetDay');
    this.metrics.requests += 1;
    const key = finalCacheKey(this.fingerprint, calculationDay, targetDay);

    const cached = await this._cacheGet(key);
    if (cached != null) {
      try {
        const tuple = codec.decode(cached);
        if (Array.isArray(tuple) && tuple.length === 5) {
          this.metrics.finalHits += 1;
          return Object.freeze({ result: tuple, cache: 'HIT', fingerprint: this.fingerprint, computeNs: 0n });
        }
        throw new TypeError('Ínvalid cached tuple.');
      } catch (_) {
        this.metrics.finalCorruptions += 1;
        try { await this.store.delete(key); } catch (_) { this.metrics.cacheWriteFailures += 1; }
      }
    }

    this.metrics.finalMisses += 1;
    const existing = this.inflight.get(key);
    if (existing) {
      this.metrics.singleFlightJoins += 1;
      const value = await existing;
      return Object.freeze({ ...value, cache: 'COALESCED' });
    }

    const task = (async () => {
      this.metrics.workerComputations += 1;
      try {
        const message = await this.worker.compute(calculationDay, targetDay);
        await this._persistSnapshots(message.snapshots);
        await this._cacheSet(key, codec.encode(message.result));
        return Object.freeze({
          result: message.result,
          cache: 'MISS',
          fingerprint: this.fingerprint,
          computeNs: BigInt(message.elapsedNs),
          bridgeStatus: message.bridgeStatus || null,
        });
      } catch (error) {
        this.metrics.workerFailures += 1;
        throw error;
      }
    })();

    this.inflight.set(key, task);
    try { return await task; }
    finally { if (this.inflight.get(key) === task) this.inflight.delete(key); }
  }

  snapshotMetrics() {
    return Object.freeze({
      fingerprint: this.fingerprint,
      inflight: this.inflight.size,
      ...this.metrics,
      workerBridge: this.worker && this.worker.lastBridgeStatus ? this.worker.lastBridgeStatus : null,
    });
  }

  async close() {
    if (this.worker) await this.worker.close();
    this.worker = null;
    await this.store.close();
    this.initialized = false;
    this.initializing = null;
  }
}

module.exports = Object.freeze({
  ServerCalendarEngine,
  SNAPSHOT_SCOPES,
  requireIntegerDay,
  semanticFingerprint,
  finalCacheKey,
  snapshotCacheKey,
});
