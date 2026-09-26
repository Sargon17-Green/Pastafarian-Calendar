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
  constructor(mode, replyBuildId) {
    this.mode = mode || 'reply';
    this.replyBuildId = replyBuildId == null ? null : String(replyBuildId);
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
      const envelope = { id: message.id, ok: true };
      if (this.replyBuildId != null) envelope.buildId = this.replyBuildId;
      if (message.operation === 'convert') {
        envelope.value = ['5000', 'bronze', 3, 'argile', 3];
      } else if (message.operation === 'convertWithTrace') {
        if (message.streamProgress === true) {
          const chunk = {
            id: message.id,
            ok: true,
            kind: 'progress',
            value: { sequence: 1, kind: 'stone-transition', elapsedMs: 2, durationMs: 2, payload: { ordinal: 2 } },
          };
          if (this.replyBuildId != null) chunk.buildId = this.replyBuildId;
          listener({ data: chunk });
        }
        envelope.kind = 'result';
        envelope.value = {
          result: ['5000', 'bronze', 3, 'argile', 3],
          trace: {
            schemaVersion: '0.4.0',
            finalResult: {
              year: '5000',
              cutlet: { sourceName: 'bronze' },
              dayInCutlet: '3',
              month: { sourceName: 'argile' },
              dayInMonth: '3',
            },
          },
        };
      } else if (message.operation === 'cookingTrace') {
        if (message.streamGateSauceDetail === true) {
          const chunk = {
            id: message.id,
            ok: true,
            kind: 'gate-detail',
            value: { kind: 'gate-gap', signedIndex: '2', marker: 'client-chunk' },
          };
          if (this.replyBuildId != null) chunk.buildId = this.replyBuildId;
          listener({ data: chunk });
        }
        if (message.streamProgress === true) {
          const progress = {
            id: message.id,
            ok: true,
            kind: 'progress',
            value: { sequence: 1, kind: 'bowl-round', elapsedMs: 3, durationMs: 3, payload: { ordinal: 1 } },
          };
          if (this.replyBuildId != null) progress.buildId = this.replyBuildId;
          listener({ data: progress });
        }
        envelope.kind = 'result';
        envelope.value = {
          schemaVersion: '0.4.0',
          inputs: { calculationDay: message.calculationDay, targetDay: message.targetDay },
          finalResult: { year: '5000' },
        };
      } else if (message.operation === 'getCutletView') {
        if (message.streamProgress === true) {
          const progress = {
            id: message.id,
            ok: true,
            kind: 'progress',
            value: { kind: 'view-day-ready', elapsedMs: 4, durationMs: 4, payload: { ordinal: 1, targetDay: message.targetDay } },
          };
          if (this.replyBuildId != null) progress.buildId = this.replyBuildId;
          listener({ data: progress });
        }
        envelope.value = {
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
        };
      }
      listener({ data: envelope });
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
const engineApi = context.PastafariBrowserInternal.engineClient;
const PastafariEngineClient = engineApi.PastafariEngineClient;

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

  const viewProgress = [];
  const view = await client.getCutletView(10n, 7n, (event) => viewProgress.push(event));
  assert.strictEqual(viewProgress.length, 1);
  assert.strictEqual(viewProgress[0].kind, 'view-day-ready');
  assert.strictEqual(view.selectedDay, 7n);
  assert.strictEqual(view.startDay, 7n);
  assert.strictEqual(view.days[0].day, 7n);
  assert.strictEqual(view.days[0].dayInCutlet, 1);
  assert.strictEqual(Object.isFrozen(view), true);
  assert.strictEqual(Object.isFrozen(view.days), true);
  assert.strictEqual(workers.length, 1, 'Li client deve reutilisar un unic Worker til fatal/retry.');

  const gateChunks = [];
  const progressChunks = [];
  const cookingTrace = await client.getCookingTrace(10n, 7n, {
    gateDetailGateIndices: [2n, -3n],
    onGateSauceDetail(chunk) { gateChunks.push(chunk); },
    onProgress(chunk) { progressChunks.push(chunk); },
  });
  assert.strictEqual(cookingTrace.schemaVersion, '0.4.0');
  assert.strictEqual(Object.isFrozen(cookingTrace), true);
  assert.strictEqual(Object.isFrozen(cookingTrace.inputs), true);
  assert.strictEqual(gateChunks.length, 1);
  assert.strictEqual(gateChunks[0].marker, 'client-chunk');
  assert.strictEqual(Object.isFrozen(gateChunks[0]), true);
  assert.strictEqual(progressChunks.length, 1);
  assert.strictEqual(progressChunks[0].kind, 'bowl-round');
  assert.strictEqual(Object.isFrozen(progressChunks[0]), true);
  assert.deepStrictEqual(JSON.parse(JSON.stringify(workers[0].messages[2])), {
    id: 3,
    operation: 'cookingTrace',
    calculationDay: '10',
    targetDay: '7',
    streamGateSauceDetail: true,
    streamProgress: true,
    gateDetailGateIndices: ['2', '-3'],
  });
  await assert.rejects(
    Promise.resolve().then(() => client.getCookingTrace(10n, 7n, { gateDetailGateIndices: [2n] })),
    /exige onGateSauceDetail/,
  );

  const tracedProgress = [];
  const traced = await client.convertWithTrace(10n, 7n, (event) => tracedProgress.push(event));
  assert.strictEqual(traced.result.year, '5000');
  assert.strictEqual(traced.trace.schemaVersion, '0.4.0');
  assert.strictEqual(tracedProgress.length, 1);
  assert.strictEqual(tracedProgress[0].kind, 'stone-transition');
  assert.strictEqual(Object.isFrozen(traced.trace), true);

  // A generated build must bind request and response to the same main/Worker ID.
  let coherentWorker;
  const coherentClient = new PastafariEngineClient({
    buildId: 'build-A',
    workerFactory() {
      coherentWorker = new FakeWorker('reply', 'build-A');
      return coherentWorker;
    },
    timeoutMs: 1000,
  });
  const coherent = await coherentClient.convert(10n, 2n);
  assert.strictEqual(coherent.monthName, 'argile');
  assert.strictEqual(coherentWorker.messages[0].buildId, 'build-A');

  // New main + stale Worker (missing ID) fails closed and terminates the Worker.
  let staleWorker;
  const staleClient = new PastafariEngineClient({
    buildId: 'build-A',
    workerFactory() {
      staleWorker = new FakeWorker('reply');
      return staleWorker;
    },
    timeoutMs: 1000,
  });
  await assert.rejects(
    staleClient.convert(10n, 2n),
    (error) => error && error.code === 'ERR_BROWSER_BUILD_MISMATCH'
      && error.expectedBuildId === 'build-A' && error.actualBuildId === null,
  );
  assert.strictEqual(staleWorker.terminated, true);
  assert.strictEqual(staleClient.pending.size, 0);

  // A Worker from a different version is rejected even if its payload looks valid.
  let wrongWorker;
  const wrongClient = new PastafariEngineClient({
    buildId: 'build-A',
    workerFactory() {
      wrongWorker = new FakeWorker('reply', 'build-B');
      return wrongWorker;
    },
    timeoutMs: 1000,
  });
  await assert.rejects(
    wrongClient.convert(10n, 2n),
    (error) => error && error.code === 'ERR_BROWSER_BUILD_MISMATCH'
      && error.actualBuildId === 'build-B',
  );
  assert.strictEqual(wrongWorker.terminated, true);

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
  coherentClient.dispose();
  staleClient.dispose();
  wrongClient.dispose();
  recoveringClient.dispose();
  timeoutClient.dispose();
  assert.strictEqual(workers[0].terminated, true);
  assert.strictEqual(engineApi.BUILD_MISMATCH_CODE, 'ERR_BROWSER_BUILD_MISMATCH');

  console.log('browser-engine-client: PASS');
})().catch((error) => {
  console.error(error && error.stack ? error.stack : error);
  process.exitCode = 1;
});
