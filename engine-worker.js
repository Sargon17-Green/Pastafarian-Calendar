'use strict';

const path = require('node:path');
const { parentPort, workerData } = require('node:worker_threads');
const { Stage58PersistenceBridge } = require('./stage58-persistence-bridge');

if (!parentPort) throw new Error('engine-worker.js deve esser executet quam Worker thread.');

const corePath = workerData && workerData.corePath
  ? path.resolve(workerData.corePath)
  : path.resolve(__dirname, '..', 'src', 'index.js');
const core = require(corePath);
if (!core || typeof core.calendarDateSpaghetti !== 'function') {
  throw new TypeError('Li Stage 59 worker ne trova calendarDateSpaghetti().');
}

const bridge = new Stage58PersistenceBridge(core, (workerData && workerData.initialSnapshots) || {});

function normalizeTuple(value) {
  if (!Array.isArray(value) || value.length !== 5) {
    throw new TypeError('calendarDateSpaghetti() deve retornar un five-part tuple.');
  }
  const [year, cutletName, dayInCutlet, monthName, dayInMonth] = value;
  if (typeof year !== 'bigint' || typeof cutletName !== 'string' || typeof dayInCutlet !== 'bigint'
      || typeof monthName !== 'string' || typeof dayInMonth !== 'bigint') {
    throw new TypeError('Li five-part tuple del core have un ínexpectat type-shape.');
  }
  return Object.freeze([year, cutletName, dayInCutlet, monthName, dayInMonth]);
}

parentPort.on('message', (message) => {
  if (!message || message.type !== 'compute') return;
  const id = message.id;
  try {
    const calculationDay = BigInt(message.calculationDay);
    const targetDay = BigInt(message.targetDay);
    bridge.beginTransaction();
    const started = process.hrtime.bigint();
    const result = normalizeTuple(core.calendarDateSpaghetti(calculationDay, targetDay));
    const elapsedNs = process.hrtime.bigint() - started;
    const snapshots = bridge.commitTransaction();
    parentPort.postMessage({
      type: 'result',
      id,
      ok: true,
      result,
      elapsedNs,
      snapshots,
      bridgeStatus: bridge.status(),
    });
  } catch (error) {
    bridge.rollbackTransaction();
    // Failed calculations never publish intermediate state. A retry must start from
    // the last successfully persisted Stage 58 snapshot, preserving failure isolation.
    parentPort.postMessage({
      type: 'result',
      id,
      ok: false,
      error: {
        name: error && error.name ? String(error.name) : 'Error',
        message: error && error.message ? String(error.message) : String(error),
        code: error && error.code ? String(error.code) : null,
        stack: error && error.stack ? String(error.stack) : null,
      },
    });
  }
});

parentPort.postMessage({ type: 'ready', bridgeStatus: bridge.status() });
