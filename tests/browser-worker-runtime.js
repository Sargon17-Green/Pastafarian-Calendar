'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');
const vm = require('vm');

const ROOT = path.resolve(__dirname, '..');

function load(context, relativePath) {
  const source = fs.readFileSync(path.join(ROOT, relativePath), 'utf8');
  new vm.Script(source, { filename: relativePath }).runInContext(context);
}

const listeners = new Map();
const posted = [];
const coreCalls = [];
const cookingTraceCalls = [];
const context = vm.createContext({
  console,
  addEventListener(type, listener) { listeners.set(type, listener); },
  postMessage(message) { posted.push(message); },
  PastafariBrowserWorkerConfig: Object.freeze({ buildId: 'build-A' }),
  PastafariBrowserCore: {
    calendarDateSpaghetti(calculationDay, targetDay) {
      coreCalls.push([calculationDay, targetDay]);
      const position = Number((targetDay % 5n + 5n) % 5n) + 1;
      return [5000n, 'bronze', BigInt(position), 'argile', BigInt(position)];
    },
  },
  PastafariBrowserCookingTrace: {
    calendarDateSpaghettiCookingTrace(calculationDay, targetDay, options) {
      cookingTraceCalls.push({ calculationDay, targetDay, options });
      if (options && typeof options.onGateSauceDetail === 'function') {
        options.onGateSauceDetail({ kind: 'gate-gap', signedIndex: '2', marker: 'chunk' });
      }
      if (options && typeof options.onProgress === 'function') {
        options.onProgress({ sequence: 1, kind: 'stone-transition', elapsedMs: 2, durationMs: 2, payload: { ordinal: 2 } });
      }
      return {
        schemaVersion: '0.4.0',
        inputs: { calculationDay: String(calculationDay), targetDay: String(targetDay) },
        finalResult: {
          year: '5000',
          cutlet: { sourceName: 'bronze' },
          dayInCutlet: '3',
          month: { sourceName: 'argile' },
          dayInMonth: '3',
        },
      };
    },
  },
});

load(context, 'browser/result-normalizer.js');
load(context, 'browser/black-box-cutlet.js');
load(context, 'browser/pastafari-worker-entry.js');

const onMessage = listeners.get('message');
assert.strictEqual(typeof onMessage, 'function', 'Li Worker entry deve registrar un message handler.');

(async () => {
  await onMessage({ data: {
    id: 1, operation: 'convert', calculationDay: '10', targetDay: '2', buildId: 'build-A',
  } });
  assert.strictEqual(posted.length, 1);
  assert.strictEqual(posted[0].id, 1);
  assert.strictEqual(posted[0].ok, true);
  assert.strictEqual(posted[0].buildId, 'build-A');
  assert.strictEqual(posted[0].value.year, '5000');
  assert.strictEqual(posted[0].value.cutletName, 'bronze');
  assert.strictEqual(posted[0].value.dayInCutlet, 3);
  assert.strictEqual(coreCalls.length, 1);
  assert.strictEqual(coreCalls[0][0], 10n);
  assert.strictEqual(coreCalls[0][1], 2n);

  posted.length = 0;
  coreCalls.length = 0;
  await onMessage({ data: {
    id: 2, operation: 'getCutletView', calculationDay: '10', targetDay: '2', buildId: 'build-A',
  } });
  assert.strictEqual(posted.length, 1);
  assert.strictEqual(posted[0].ok, true);
  assert.strictEqual(posted[0].buildId, 'build-A');
  const view = posted[0].value;
  assert.strictEqual(view.selectedDay, '2');
  assert.strictEqual(view.selectedIndex, 2);
  assert.strictEqual(view.startDay, '0');
  assert.strictEqual(view.endDay, '4');
  assert.strictEqual(view.previousCutletDay, '-1');
  assert.strictEqual(view.nextCutletDay, '5');
  assert.strictEqual(view.days.length, 5);
  assert.strictEqual(view.days.map((day) => day.dayInCutlet).join(','), '1,2,3,4,5');
  assert(coreCalls.length >= 5, 'Li cutlet-view deve esser derivat per public black-box conversiones.');
  for (const [calculationDay] of coreCalls) assert.strictEqual(calculationDay, 10n);

  posted.length = 0;
  cookingTraceCalls.length = 0;
  await onMessage({ data: {
    id: 20, operation: 'cookingTrace', calculationDay: '10', targetDay: '2', buildId: 'build-A',
    streamGateSauceDetail: false,
  } });
  assert.strictEqual(posted.length, 1);
  assert.strictEqual(posted[0].kind, 'result');
  assert.strictEqual(posted[0].value.schemaVersion, '0.4.0');
  assert.strictEqual(cookingTraceCalls.length, 1);
  assert.strictEqual(cookingTraceCalls[0].calculationDay, 10n);
  assert.strictEqual(cookingTraceCalls[0].targetDay, 2n);
  assert.strictEqual(cookingTraceCalls[0].options, null);

  posted.length = 0;
  cookingTraceCalls.length = 0;
  await onMessage({ data: {
    id: 21, operation: 'cookingTrace', calculationDay: '10', targetDay: '2', buildId: 'build-A',
    streamGateSauceDetail: true,
    gateDetailGateIndices: ['2', '-3'],
  } });
  assert.strictEqual(posted.length, 2);
  assert.strictEqual(posted[0].kind, 'gate-detail');
  assert.strictEqual(posted[0].value.marker, 'chunk');
  assert.strictEqual(posted[1].kind, 'result');
  assert.deepStrictEqual(Array.from(cookingTraceCalls[0].options.gateDetailGateIndices), [2n, -3n]);

  posted.length = 0;
  cookingTraceCalls.length = 0;
  await onMessage({ data: {
    id: 22, operation: 'cookingTrace', calculationDay: '10', targetDay: '2', buildId: 'build-A',
    streamGateSauceDetail: false,
    streamProgress: true,
  } });
  assert.strictEqual(posted.length, 2);
  assert.strictEqual(posted[0].kind, 'progress');
  assert.strictEqual(posted[0].value.kind, 'stone-transition');
  assert.strictEqual(posted[1].kind, 'result');
  assert.strictEqual(typeof cookingTraceCalls[0].options.onProgress, 'function');

  posted.length = 0;
  cookingTraceCalls.length = 0;
  await onMessage({ data: {
    id: 23, operation: 'convertWithTrace', calculationDay: '10', targetDay: '2', buildId: 'build-A',
    streamProgress: true,
  } });
  assert.strictEqual(posted.length, 2);
  assert.strictEqual(posted[0].kind, 'progress');
  assert.strictEqual(posted[1].kind, 'result');
  assert.strictEqual(posted[1].value.result.year, '5000');
  assert.strictEqual(posted[1].value.result.cutletName, 'bronze');
  assert.strictEqual(posted[1].value.trace.schemaVersion, '0.4.0');

  posted.length = 0;
  coreCalls.length = 0;
  await onMessage({ data: {
    id: 24, operation: 'getCutletView', calculationDay: '10', targetDay: '2', buildId: 'build-A',
    streamProgress: true,
  } });
  assert(posted.length > 1);
  assert(posted.slice(0, -1).every((row) => row.kind === 'progress'));
  assert.strictEqual(posted[posted.length - 1].ok, true);
  assert.strictEqual(posted[posted.length - 1].value.days.length, 5);

  // Old/stale main + new Worker fails before any semantic core invocation.
  posted.length = 0;
  coreCalls.length = 0;
  await onMessage({ data: { id: 3, operation: 'convert', calculationDay: '10', targetDay: '2' } });
  assert.strictEqual(posted.length, 1);
  assert.strictEqual(posted[0].ok, false);
  assert.strictEqual(posted[0].buildId, 'build-A');
  assert.strictEqual(posted[0].error.code, 'ERR_BROWSER_BUILD_MISMATCH');
  assert.strictEqual(coreCalls.length, 0);

  posted.length = 0;
  await onMessage({ data: {
    id: 4, operation: 'convert', calculationDay: '10', targetDay: '2', buildId: 'build-B',
  } });
  assert.strictEqual(posted[0].ok, false);
  assert.strictEqual(posted[0].error.code, 'ERR_BROWSER_BUILD_MISMATCH');
  assert.strictEqual(coreCalls.length, 0);

  posted.length = 0;
  await onMessage({ data: {
    id: 5, operation: 'not-an-operation', calculationDay: '10', targetDay: '2', buildId: 'build-A',
  } });
  assert.strictEqual(posted[0].ok, false);
  assert.strictEqual(posted[0].id, 5);
  assert(/operation/i.test(posted[0].error.message));

  posted.length = 0;
  await onMessage({ data: {
    id: 6, operation: 'convert', calculationDay: 'bad', targetDay: '2', buildId: 'build-A',
  } });
  assert.strictEqual(posted[0].ok, false);
  assert.strictEqual(posted[0].id, 6);
  assert.strictEqual(typeof posted[0].error.name, 'string');
  assert.strictEqual(typeof posted[0].error.message, 'string');

  console.log('browser-worker-runtime: PASS');
})().catch((error) => {
  console.error(error && error.stack ? error.stack : error);
  process.exitCode = 1;
});
