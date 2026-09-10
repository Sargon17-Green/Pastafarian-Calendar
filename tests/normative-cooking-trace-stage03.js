'use strict';

const assert = require('assert');
const core = require('../src/index');
const traceApi = require('../src/normative-cooking-trace');

function assertNoBigInt(value, path = '$') {
  if (typeof value === 'bigint') throw new Error('BigInt survived serialization at ' + path);
  if (value === null || typeof value !== 'object') return;
  if (Array.isArray(value)) {
    value.forEach((item, index) => assertNoBigInt(item, path + '[' + index + ']'));
    return;
  }
  for (const [key, item] of Object.entries(value)) assertNoBigInt(item, path + '.' + key);
}

function assertFullSauceShape(run) {
  assert.strictEqual(run.hiddenDrops.length, 7);
  assert.strictEqual(run.visibleDrops.length, 46);
  assert.strictEqual(run.initialBowls.length, 6);
  assert.strictEqual(run.bowlRounds.length, 46);
  assert.strictEqual(run.postStirs.length, 12);
  assert.strictEqual(run.orderAtDrop46.length, 6);
  assert.strictEqual(run.finalBowls.length, 6);
  for (const hidden of run.hiddenDrops) assert.strictEqual(hidden.grinds.length, 7);
  for (const visible of run.visibleDrops) assert.strictEqual(visible.grinds.length, 11);
  for (const round of run.bowlRounds) assert.strictEqual(round.positions.length, 6);
  for (const stir of run.postStirs) assert.strictEqual(stir.positions.length, 6);
}

function assertStoneTransitions(trace) {
  const table = trace.artifacts.stoneTable;
  assert.ok(table);
  assert.strictEqual(table.seed.ordinal, 1);
  assert.deepStrictEqual(table.seed.values, table.rows[0].values);
  assert.strictEqual(table.rows.length, 46);
  assert.strictEqual(table.rows[0].transition, null);

  for (let i = 1; i < table.rows.length; i += 1) {
    const row = table.rows[i];
    const transition = row.transition;
    assert.ok(transition);
    assert.strictEqual(Number(transition.index), row.ordinal);
    assert.deepStrictEqual(transition.after, row.values);
    assert.deepStrictEqual(transition.before, table.rows[i - 1].values);

    const old = Object.fromEntries(
      Object.entries(transition.before).map(([key, value]) => [key, BigInt(value)]),
    );
    const index = BigInt(transition.index);
    const expectedRaw = {
      w: old.w * old.w + 3n * old.b + index,
      b: old.b * old.b + 5n * old.s + old.w,
      s: old.s * old.s + 7n * old.m + old.b,
      m: old.m * old.m + 11n * old.r + old.s,
      r: old.r * old.r + 13n * old.w + old.m,
    };
    for (const key of ['w', 'b', 's', 'm', 'r']) {
      assert.strictEqual(expectedRaw[key].toString(), transition.rawBeforeSave[key]);
    }
  }
}

function assertSelectionRunEncoding(trace) {
  assert.ok(trace.artifacts.selections.length > 0);
  assert.strictEqual(
    trace.artifacts.selections.filter((row) => row.gateIndex !== null).length,
    trace.measurement.gateSauceCallsObserved,
  );
  for (const selection of trace.artifacts.selections) {
    assert.ok(selection.sourceLabel);
    assert.ok(selection.rejectionEncoding);
    assert.strictEqual(selection.rejectionEncoding.count, selection.rejectionSteps);
    assert.ok(BigInt(selection.acceptedCandidate) <= BigInt(selection.acceptanceLimit));
  }

  // Force one real short-mode rejection and verify that the checkpoint is
  // recorded by the actual selector loop, rather than reconstructed later.
  let checkpoint = null;
  const output = core.patchedSmallPick(
    { first: core.M_OLD, directionStep: -1n },
    2n,
    (kind, payload) => { checkpoint = { kind, payload }; },
  );
  assert.ok(output === 1n || output === 2n);
  assert.strictEqual(checkpoint.kind, 'selection-result');
  assert.strictEqual(checkpoint.payload.mode, 'short');
  assert.strictEqual(checkpoint.payload.firstCandidate, core.M_OLD);
  assert.strictEqual(checkpoint.payload.rejectionSteps, 1n);
  assert.strictEqual(checkpoint.payload.acceptedCandidate, core.M_OLD - 1n);
  assert.strictEqual(checkpoint.payload.rejectionEncoding.count, 1n);
}

(function main() {
  const c = core.FOUNDATION_DAY_OLD;
  const t = c;

  // Warm ordinary caches. The trace path must still expose execution-time
  // detail and must not alter the ordinary calendar result.
  const ordinaryBefore = core.calendarDateSpaghetti(c, t);
  const gateChunks = [];
  const trace = traceApi.calendarDateSpaghettiCookingTrace(c, t, {
    gateDetailGateIndices: [-10n],
    onGateSauceDetail(chunk) {
      gateChunks.push(chunk);
    },
  });
  const ordinaryAfter = core.calendarDateSpaghetti(c, t);

  assert.deepStrictEqual(ordinaryAfter, ordinaryBefore);
  assert.strictEqual(trace.schemaVersion, '0.3.0');
  assert.deepStrictEqual(trace.coverage.missingCoreCheckpoints, []);
  assert.strictEqual(trace.coverage.gateSauceDetail, 'selected-gates-streamed-from-same-execution');
  assert.strictEqual(trace.coverage.gateSauceDetailTransport, 'one-json-safe-chunk-per-gate-sauce');

  assertStoneTransitions(trace);
  assertSelectionRunEncoding(trace);

  assert.strictEqual(gateChunks.length, 1);
  assert.strictEqual(gateChunks.length, trace.measurement.gateDetailChunksStreamed);
  assert.deepStrictEqual(trace.coverage.gateDetailRequestedIndices, ['-10']);
  const gateIds = new Set(trace.artifacts.gateNetwork.gaps.map((row) => row.sauceRunId));
  const streamedGap = trace.artifacts.gateNetwork.gaps.find((row) => row.signedIndex === '-10');
  assert.ok(streamedGap);
  assert.strictEqual(streamedGap.detailCoverage, 'streamed-same-execution');
  for (const chunk of gateChunks) {
    assertNoBigInt(chunk);
    assertFullSauceShape(chunk);
    assert.strictEqual(chunk.role.kind, 'gate-gap');
    assert.ok(gateIds.has(chunk.id));
    assert.strictEqual(chunk.coverage.stoneTransitionOperands, 'shared-artifact-captured-at-execution');
  }

  assertNoBigInt(trace);
  JSON.stringify(trace);
  gateChunks.forEach((chunk) => JSON.stringify(chunk));

  const compactTrace = traceApi.calendarDateSpaghettiCookingTrace(c, t);
  assert.strictEqual(compactTrace.coverage.gateSauceDetail, 'same-execution-stream-option-available');
  assert.strictEqual(compactTrace.measurement.gateDetailChunksStreamed, 0);
  assert.deepStrictEqual(compactTrace.finalResult, trace.finalResult);

  process.stdout.write(
    'Normative cooking trace Stage 03: PASS\n'
    + 'Stone transitions: 45\n'
    + 'Selection executions: ' + trace.measurement.selectionCallsObserved + '\n'
    + 'Gate detail chunks: ' + gateChunks.length + '\n',
  );
})();
