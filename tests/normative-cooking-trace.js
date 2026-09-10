'use strict';

const assert = require('assert');
const core = require('../src/index');
const traceApi = require('../src/normative-cooking-trace');

function resultArray(trace) {
  return [
    BigInt(trace.finalResult.year),
    trace.finalResult.cutlet.sourceName,
    BigInt(trace.finalResult.dayInCutlet),
    trace.finalResult.month.sourceName,
    BigInt(trace.finalResult.dayInMonth),
  ];
}

function assertNoBigInt(value, path = '$') {
  if (typeof value === 'bigint') throw new Error('BigInt survived serialization at ' + path);
  if (value === null || typeof value !== 'object') return;
  if (Array.isArray(value)) {
    value.forEach((item, index) => assertNoBigInt(item, path + '[' + index + ']'));
    return;
  }
  for (const [key, item] of Object.entries(value)) assertNoBigInt(item, path + '.' + key);
}

function assertCentralSauceShape(run) {
  assert.strictEqual(run.counters && typeof run.counters, 'object');
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
  assert.strictEqual(trace1.schemaVersion, '0.3.0');
  assert.strictEqual(trace1.semanticProfile, 'PASTAFARIAN_STAGE57_STAGE56_RAW_SUM');

  assertNoBigInt(trace1);
  const roundTrip = JSON.parse(JSON.stringify(trace1));
  assert.deepStrictEqual(roundTrip, trace1);

  assert.ok(trace1.artifacts.gateNetwork.gates.length >= 1);
  assert.strictEqual(
    trace1.artifacts.gateNetwork.gaps.length,
    trace1.measurement.gateGapCountMaterialized,
  );
  for (const gap of trace1.artifacts.gateNetwork.gaps) {
    assert.ok(gap.sauceRunId);
    assert.ok(gap.sauceSummary);
    assert.strictEqual(gap.sauceSummary.stage56RawBowlSumApplied, true);
  }

  assert.ok(trace1.artifacts.stoneTable);
  assert.strictEqual(trace1.artifacts.stoneTable.rows.length, 46);
  assert.ok(trace1.artifacts.sauceRuns.length >= 2);
  trace1.artifacts.sauceRuns.forEach(assertCentralSauceShape);

  const trace2 = traceApi.calendarDateSpaghettiCookingTrace(c, t);
  assert.deepStrictEqual(trace2, trace1);

  const serialized = JSON.stringify(trace1);
  assert.strictEqual(serialized.includes('stage58MemoryReplay'), false);
  assert.strictEqual(serialized.includes('cacheBacked'), false);
  assert.strictEqual(trace1.coverage.sameSemanticExecutionAsFinalResult, true);
  assert.strictEqual(trace1.coverage.independentExplanationEngine, false);

  process.stdout.write(
    'Normative cooking trace foundation: PASS\n'
    + 'Sauce calls: ' + trace1.measurement.totalSauceCallsObserved + '\n'
    + 'Gate Sauce calls: ' + trace1.measurement.gateSauceCallsObserved + '\n'
    + 'Semantic year transitions: ' + trace1.measurement.semanticYearTransitionCount + '\n',
  );
})();
