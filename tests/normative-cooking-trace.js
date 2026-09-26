'use strict';
const assert = require('assert');
const core = require('../src/index');
const traceApi = require('../src/normative-cooking-trace');

function resultArray(trace) {
  return [BigInt(trace.finalResult.year), trace.finalResult.cutlet.sourceName, BigInt(trace.finalResult.dayInCutlet), trace.finalResult.month.sourceName, BigInt(trace.finalResult.dayInMonth)];
}
function assertNoBigInt(value, path = '$') {
  if (typeof value === 'bigint') throw new Error('BigInt survived serialization at ' + path);
  if (value === null || typeof value !== 'object') return;
  if (Array.isArray(value)) return value.forEach((item, i) => assertNoBigInt(item, path + '[' + i + ']'));
  for (const [key, item] of Object.entries(value)) assertNoBigInt(item, path + '.' + key);
}
function assertCentralSauceShape(run) {
  assert.strictEqual(run.hiddenDrops.length, 7);
  assert.strictEqual(run.visibleDrops.length, 46);
  assert.strictEqual(run.orderAtDrop46.length, 6);
  assert.strictEqual(run.bowlsAfterDrops.length, 6);
  assert.strictEqual(run.finalBowls.length, 6);
  assert.strictEqual(run.postStirs.length, 12);
  for (const stir of run.postStirs) {
    assert.strictEqual(stir.beforeBowls.length, 6);
    assert.strictEqual(stir.afterBowls.length, 6);
    assert.strictEqual(stir.order.length, 6);
    const raw = stir.beforeBowls.reduce((sum, value) => sum + BigInt(value), 0n);
    assert.strictEqual(raw.toString(), stir.rawBowlSum);
    const saved = core.savePatch(raw + 149n * BigInt(stir.ordinal));
    assert.strictEqual(saved.toString(), stir.savedOrderNumber);
  }
}

(function main() {
  const c = core.FOUNDATION_DAY_OLD;
  const t = c;
  const before = core.calendarDateSpaghetti(c, t);
  const trace1 = traceApi.calendarDateSpaghettiCookingTrace(c, t);
  const after = core.calendarDateSpaghetti(c, t);
  assert.deepStrictEqual(resultArray(trace1), before);
  assert.deepStrictEqual(after, before);
  assert.strictEqual(trace1.schemaVersion, '0.4.0');
  assert.strictEqual(trace1.semanticProfile, 'PASTAFARIAN_STAGE57_CANONICAL_SAVED_SUM');
  assertNoBigInt(trace1);
  assert.deepStrictEqual(JSON.parse(JSON.stringify(trace1)), trace1);
  assert.ok(trace1.artifacts.gateNetwork.gates.length >= 1);
  for (const gap of trace1.artifacts.gateNetwork.gaps) {
    assert.ok(gap.sauceRunId);
    assert.ok(gap.sauceSummary);
    assert.strictEqual(gap.sauceSummary.stage56SavedSumApplied, true);
    assert.strictEqual(gap.sauceSummary.stage56RawBowlSumApplied, false);
  }
  const stage56Archaeology = trace1.archaeology.find((row) => row.kind === 'stage56-raw-bowl-sum-corrective');
  assert.ok(stage56Archaeology);
  assert.strictEqual(stage56Archaeology.semanticRule, 'post-stir-u-uses-saved-order-number');
  assert.ok(!trace1.archaeology.some((row) => row.semanticRule === 'post-stir-u-uses-raw-bowl-sum'));
  assert.ok(trace1.artifacts.sauceRuns.length >= 2);
  trace1.artifacts.sauceRuns.forEach(assertCentralSauceShape);
  const progressEvents = [];
  const trace2 = traceApi.calendarDateSpaghettiCookingTrace(c, t, {
    onProgress(event) { progressEvents.push(event); },
  });
  assert.deepStrictEqual(trace2, trace1, 'progress observation must not change the deterministic trace');
  assert.ok(progressEvents.length > 100, 'live progress should expose the internal execution, not a token spinner');
  assertNoBigInt(progressEvents);
  const kinds = new Set(progressEvents.map((event) => event.kind));
  for (const kind of [
    'run-start',
    'stone-transition',
    'hidden-grind',
    'visible-grind',
    'initial-bowl',
    'bowl-round',
    'post-stir',
    'selection-result',
    'gate-gap-finished',
    'year-resolution-finished',
    'cutlet-count-ready',
    'month-weaving-ready',
    'final-result-ready',
    'trace-ready',
  ]) {
    assert.ok(kinds.has(kind), 'missing live progress kind: ' + kind);
  }
  for (let index = 0; index < progressEvents.length; index += 1) {
    const event = progressEvents[index];
    assert.strictEqual(event.sequence, index + 1);
    assert(Number.isFinite(event.elapsedMs) && event.elapsedMs >= 0);
    assert(Number.isFinite(event.durationMs) && event.durationMs >= 0);
  }
  const expensiveInnerKinds = new Set([
    'stone-seed', 'stone-transition', 'hidden-start', 'hidden-grind',
    'visible-start', 'visible-grind', 'initial-bowl', 'bowl-round', 'post-stir',
  ]);
  assert.strictEqual(progressEvents.some((event) =>
    expensiveInnerKinds.has(event.kind)
      && event.payload && event.payload.gateIndex !== null && event.payload.gateIndex !== undefined
  ), false, 'live observation must not disable Stage 58 acceleration merely to expand each gate Sauce');
  assert.strictEqual(progressEvents.some((event) =>
    event.kind === 'sauce-finished'
      && event.payload && event.payload.gateIndex !== null && event.payload.gateIndex !== undefined
  ), false, 'accelerated gate Sauce work must be represented by its gate completion, not duplicated as a second UI event');
  assert.ok(progressEvents.some((event) =>
    event.kind === 'gate-gap-finished'
      && event.payload && event.payload.signedIndex !== null && event.payload.signedIndex !== undefined
  ), 'real completed gate-gap steps must remain visible');
  assert.strictEqual(trace1.coverage.sameSemanticExecutionAsFinalResult, true);
  assert.strictEqual(trace1.coverage.independentExplanationEngine, false);
  console.log('Normative cooking trace foundation saved-sum: PASS');
})();
