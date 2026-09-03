'use strict';

const path = require('node:path');
const { Worker } = require('node:worker_threads');

class EngineWorkerError extends Error {
  constructor(payload) {
    super(payload && payload.message ? payload.message : 'Li calculation worker fallit.');
    this.name = payload && payload.name ? payload.name : 'EngineWorkerError';
    if (payload && payload.code) this.code = payload.code;
    if (payload && payload.stack) this.remoteStack = payload.stack;
  }
}

class EngineWorkerClient {
  constructor(options) {
    const selected = options || {};
    this.workerPath = selected.workerPath || path.resolve(__dirname, 'engine-worker.js');
    this.corePath = selected.corePath || path.resolve(__dirname, '..', 'src', 'index.js');
    this.initialSnapshots = selected.initialSnapshots || Object.create(null);
    this.worker = null;
    this.readyPromise = null;
    this.pending = new Map();
    this.nextId = 1;
    this.lastBridgeStatus = null;
  }

  async start() {
    if (this.readyPromise) return this.readyPromise;
    this.readyPromise = new Promise((resolve, reject) => {
      const worker = new Worker(this.workerPath, {
        workerData: {
          corePath: this.corePath,
          initialSnapshots: this.initialSnapshots,
        },
      });
      this.worker = worker;
      let ready = false;

      worker.on('message', (message) => {
        if (!message || typeof message !== 'object') return;
        if (message.type === 'ready') {
          ready = true;
          this.lastBridgeStatus = message.bridgeStatus || null;
          resolve(message.bridgeStatus || null);
          return;
        }
        if (message.type !== 'result') return;
        const pending = this.pending.get(message.id);
        if (!pending) return;
        this.pending.delete(message.id);
        if (message.bridgeStatus) this.lastBridgeStatus = message.bridgeStatus;
        if (message.ok) pending.resolve(message);
        else pending.reject(new EngineWorkerError(message.error));
      });

      worker.on('error', (error) => {
        if (!ready) reject(error);
        this._rejectAll(error);
      });
      worker.on('exit', (code) => {
        const error = code === 0 ? new Error('Li calculation worker esset cludet.')
          : new Error('Li calculation worker terminat con code ' + code + '.');
        if (!ready) reject(error);
        this._rejectAll(error);
        this.worker = null;
        this.readyPromise = null;
      });
    });
    return this.readyPromise;
  }

  _rejectAll(error) {
    for (const pending of this.pending.values()) pending.reject(error);
    this.pending.clear();
  }

  async compute(calculationDay, targetDay) {
    await this.start();
    if (!this.worker) throw new Error('Li calculation worker ne es disponibil.');
    const id = this.nextId++;
    return new Promise((resolve, reject) => {
      this.pending.set(id, { resolve, reject });
      this.worker.postMessage({
        type: 'compute',
        id,
        calculationDay: BigInt(calculationDay).toString(),
        targetDay: BigInt(targetDay).toString(),
      });
    });
  }

  async close() {
    if (!this.worker) return;
    const worker = this.worker;
    this.worker = null;
    this.readyPromise = null;
    this._rejectAll(new Error('Li calculation worker es cludet.'));
    await worker.terminate();
  }
}

module.exports = Object.freeze({ EngineWorkerClient, EngineWorkerError });
