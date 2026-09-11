'use strict';
const assert = require('assert');
const core = require('../src/index');
const traceApi = require('../src/normative-cooking-trace');
const bi = (value) => BigInt(value);

function assertCentralCheckpointShape(run) {
  assert.strictEqual(run.hiddenDrops.length, 7);
  for (const hidden of run.hiddenDrops) {
    assert.strictEqual(hidden.grinds.length, 7);
    assert.strictEqual(hidden.grinds[0].before, hidden.initial);
    assert.strictEqual(hidden.grinds[6].after, hidden.value);
  }
  assert.strictEqual(run.visibleDrops.length, 46);
  for (const visible of run.visibleDrops) assert.strictEqual(visible.grinds.length, 11);
  assert.strictEqual(run.bowlRounds.length, 46);
  assert.deepStrictEqual(run.bowlRounds[45].afterBowls, run.bowlsAfterDrops);
  assert.strictEqual(run.postStirs.length, 12);
  for (const stir of run.postStirs) {
    assert.strictEqual(stir.positions.length, 6);
    const raw = stir.beforeBowls.reduce((sum, value) => sum + bi(value), 0n);
    const saved = core.savePatch(raw + 149n * bi(stir.ordinal));
    assert.strictEqual(raw.toString(), stir.rawBowlSum);
    assert.strictEqual(saved.toString(), stir.savedOrderNumber);
    const byId = new Map(stir.positions.map((row) => [Number(row.bowlId), row]));
    for (let bowlId = 1; bowlId <= 6; bowlId += 1) assert.strictEqual(byId.get(bowlId).output, stir.afterBowls[bowlId - 1]);
    for (const row of stir.positions) {
      const expectedU = bi(row.oldBowl)
        + 3n * bi(row.oldPrev)
        + 5n * bi(row.oldNext)
        + bi(stir.savedOrderNumber)
        + bi(stir.ordinal)
        + bi(row.position) * bi(row.position);
      assert.strictEqual(expectedU.toString(), row.u);
    }
  }
}

(function main() {
  const c = core.FOUNDATION_DAY_OLD;
  const before = core.calendarDateSpaghetti(c, c);
  const trace = traceApi.calendarDateSpaghettiCookingTrace(c, c);
  const after = core.calendarDateSpaghetti(c, c);
  assert.deepStrictEqual(after, before);
  assert.strictEqual(trace.semanticProfile, 'PASTAFARIAN_STAGE57_CANONICAL_SAVED_SUM');
  assert.ok(trace.artifacts.sauceRuns.length >= 2);
  trace.artifacts.sauceRuns.forEach(assertCentralCheckpointShape);
  assert.deepStrictEqual(trace.coverage.missingCoreCheckpoints, []);
  console.log('Normative cooking trace saved-sum checkpoints: PASS');
})();
