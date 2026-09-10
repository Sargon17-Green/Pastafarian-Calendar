'use strict';

const assert = require('assert');
const core = require('../src/index');
const traceApi = require('../src/normative-cooking-trace');

function bi(value) { return BigInt(value); }

function assertCentralCheckpointShape(run) {
  assert.strictEqual(run.hiddenDrops.length, 7);
  for (const hidden of run.hiddenDrops) {
    assert.strictEqual(hidden.grinds.length, 7);
    assert.strictEqual(hidden.grinds[0].before, hidden.initial);
    assert.strictEqual(hidden.grinds[6].after, hidden.value);
  }

  assert.strictEqual(run.visibleDrops.length, 46);
  for (const visible of run.visibleDrops) {
    assert.strictEqual(visible.grinds.length, 11);
    assert.strictEqual(visible.grinds[0].before, visible.initial);
    assert.strictEqual(visible.grinds[10].after, visible.value);
    assert.ok(visible.priors);
  }

  assert.strictEqual(run.initialBowls.length, 6);
  assert.strictEqual(run.bowlRounds.length, 46);
  for (let index = 0; index < 46; index += 1) {
    const round = run.bowlRounds[index];
    assert.strictEqual(round.ordinal, index + 1);
    assert.strictEqual(round.beforeBowls.length, 6);
    assert.strictEqual(round.afterBowls.length, 6);
    assert.strictEqual(round.order.length, 6);
    assert.strictEqual(round.poursByPosition.length, 6);
    assert.strictEqual(round.positions.length, 6);
    if (index > 0) assert.deepStrictEqual(round.beforeBowls, run.bowlRounds[index - 1].afterBowls);
  }
  assert.deepStrictEqual(run.bowlRounds[45].afterBowls, run.bowlsAfterDrops);

  assert.strictEqual(run.postStirs.length, 12);
  for (const stir of run.postStirs) {
    assert.strictEqual(stir.positions.length, 6);
    const byId = new Map(stir.positions.map((row) => [Number(row.bowlId), row]));
    for (let bowlId = 1; bowlId <= 6; bowlId += 1) {
      assert.strictEqual(byId.get(bowlId).output, stir.afterBowls[bowlId - 1]);
    }
  }

  assert.strictEqual(run.coverage.hiddenGrinds, 'captured-at-execution');
  assert.strictEqual(run.coverage.visiblePriorsAndGrinds, 'captured-at-execution');
  assert.strictEqual(run.coverage.initialBowls, 'captured-at-execution');
  assert.strictEqual(run.coverage.bowlRounds, 'captured-at-execution');
  assert.strictEqual(run.coverage.postStirPositionU, 'captured-at-execution');
}

(function main() {
  const c = core.FOUNDATION_DAY_OLD;
  const t = c;

  // Warm ordinary caches first. Detailed trace must still come from an actual
  // observed execution, never by deriving missing arithmetic from cached output.
  const ordinaryBefore = core.calendarDateSpaghetti(c, t);
  const trace = traceApi.calendarDateSpaghettiCookingTrace(c, t);
  const ordinaryAfter = core.calendarDateSpaghetti(c, t);

  assert.deepStrictEqual(ordinaryAfter, ordinaryBefore);
  assert.strictEqual(trace.schemaVersion, '0.2.0');
  assert.strictEqual(trace.coverage.sameSemanticExecutionAsFinalResult, true);
  assert.strictEqual(trace.coverage.independentExplanationEngine, false);

  assert.ok(trace.artifacts.sauceRuns.length >= 2);
  trace.artifacts.sauceRuns.forEach(assertCentralCheckpointShape);

  assert.deepStrictEqual(trace.coverage.missingCoreCheckpoints, [
    'stone-transition-operands',
    'selection-candidate-rejections',
    'full-gate-sauce-detail-without-rerun',
  ]);

  // This recomputation exists only in the regression test. The adapter itself
  // exposes the u value recorded at the canonical execution point.
  const stir = trace.artifacts.sauceRuns[0].postStirs[0];
  for (const row of stir.positions) {
    const expectedU =
      bi(row.oldBowl)
      + 3n * bi(row.oldPrev)
      + 5n * bi(row.oldNext)
      + bi(stir.rawBowlSum)
      + bi(stir.ordinal)
      + bi(row.position) * bi(row.position);
    assert.strictEqual(expectedU.toString(), row.u);
  }

  process.stdout.write(
    'Normative cooking trace execution checkpoints: PASS\n'
    + 'Central Sauce runs: ' + trace.artifacts.sauceRuns.length + '\n'
    + 'Gate Sauce detail: compact\n',
  );
})();
