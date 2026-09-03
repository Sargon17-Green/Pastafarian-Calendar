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
