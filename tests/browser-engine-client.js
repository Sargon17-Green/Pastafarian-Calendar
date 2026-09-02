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

class FakeWorker {
  constructor(mode) {
    this.mode = mode || 'reply';
    this.listeners = new Map();
    this.messages = [];
    this.terminated = false;
  }
  addEventListener(type, listener) { this.listeners.set(type, listener); }
  postMessage(message) {
    this.messages.push(message);
    if (this.mode === 'silent') return;
    setTimeout(() => {
      if (this.terminated) return;
      const listener = this.listeners.get('message');
      if (!listener) return;
      if (message.operation === 'convert') {
        listener({ data: {
          id: message.id,
          ok: true,
          value: ['5000', 'bronze', 3, 'argile', 3],
        } });
      } else if (message.operation === 'getCutletView') {
        listener({ data: {
          id: message.id,
          ok: true,
          value: {
            selectedDay: message.targetDay,
            selectedIndex: 0,
            startDay: message.targetDay,
            endDay: message.targetDay,
            previousCutletDay: String(BigInt(message.targetDay) - 1n),
            nextCutletDay: String(BigInt(message.targetDay) + 1n),
            year: '5000',
            cutletName: 'bronze',
            days: [{
              day: message.targetDay,
              year: '5000',
              cutletName: 'bronze',
              dayInCutlet: 1,
              monthName: 'argile',
              dayInMonth: 1,
            }],
          },
        } });
      }
    }, 0);
  }
  terminate() { this.terminated = true; }
  emitError(error) {
    const listener = this.listeners.get('error');
    if (listener) listener({ error, message: error.message });
  }
}

const context = vm.createContext({ console, setTimeout, clearTimeout });
load(context, 'browser/result-normalizer.js');
load(context, 'browser/engine-client.js');
const PastafariEngineClient = context.PastafariBrowserInternal.engineClient.PastafariEngineClient;

(async () => {
  const workers = [];
  const client = new PastafariEngineClient({
    workerFactory() {
      const worker = new FakeWorker();
      workers.push(worker);
      return worker;
    },
    timeoutMs: 1000,
  });

  const converted = await client.convert(10n, 2n);
  assert.strictEqual(converted.year, '5000');
  assert.strictEqual(converted.dayInCutlet, 3);
  assert.strictEqual(Object.isFrozen(converted), true);
  assert.strictEqual(workers.length, 1);
  assert.deepStrictEqual(JSON.parse(JSON.stringify(workers[0].messages[0])), {
    id: 1,
    operation: 'convert',
    calculationDay: '10',
    targetDay: '2',
  });

  const view = await client.getCutletView(10n, 7n);
  assert.strictEqual(view.selectedDay, 7n);
  assert.strictEqual(view.startDay, 7n);
  assert.strictEqual(view.days[0].day, 7n);
  assert.strictEqual(view.days[0].dayInCutlet, 1);
  assert.strictEqual(Object.isFrozen(view), true);
  assert.strictEqual(Object.isFrozen(view.days), true);
  assert.strictEqual(workers.length, 1, 'Li client deve reutilisar un unic Worker til fatal/retry.');

  // A fatal Worker error rejects all pending operations and the next request gets a new Worker.
  let fatalWorker;
  const fatalClient = new PastafariEngineClient({
    workerFactory() {
      fatalWorker = new FakeWorker('silent');
      return fatalWorker;
    },
    timeoutMs: 1000,
  });
  const pending = fatalClient.convert(1n, 1n);
  await new Promise((resolve) => setTimeout(resolve, 0));
  fatalWorker.emitError(new Error('boom'));
  await assert.rejects(pending, /boom/);
  assert.strictEqual(fatalWorker.terminated, true);

  let factoryCount = 0;
  const recoveringClient = new PastafariEngineClient({
    workerFactory() {
      factoryCount += 1;
      return new FakeWorker(factoryCount === 1 ? 'silent' : 'reply');
    },
    timeoutMs: 1000,
  });
  const oldPending = recoveringClient.convert(1n, 1n);
  await new Promise((resolve) => setTimeout(resolve, 0));
  recoveringClient.retry();
  await assert.rejects(oldPending, /reinicialisat/);
  const recovered = await recoveringClient.convert(1n, 2n);
  assert.strictEqual(recovered.dayInCutlet, 3);
  assert.strictEqual(factoryCount, 2);

  // Timeout is fatal for the Worker and does not leave pending entries behind.
  let timeoutWorker;
  const timeoutClient = new PastafariEngineClient({
    workerFactory() {
      timeoutWorker = new FakeWorker('silent');
      return timeoutWorker;
    },
    timeoutMs: 20,
  });
  await assert.rejects(timeoutClient.convert(4n, 5n), /excedet 20 ms/);
  assert.strictEqual(timeoutWorker.terminated, true);
  assert.strictEqual(timeoutClient.pending.size, 0);

  client.dispose();
  recoveringClient.dispose();
  timeoutClient.dispose();
  assert.strictEqual(workers[0].terminated, true);

  console.log('browser-engine-client: PASS');
})().catch((error) => {
  console.error(error && error.stack ? error.stack : error);
  process.exitCode = 1;
});
