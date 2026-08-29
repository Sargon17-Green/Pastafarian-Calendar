'use strict';

const assert = require('assert/strict');
const production = require('../src');
const normative = require('./normative-reference');

const f = normative.FOUNDATION_DAY;
const probes = [
  [f, f],
  [f - 19n, f + 31n],
  [f + 1000n, f - 777n]
];

for (const [c, t] of probes) {
  const counts = normative.workCounts(c, t);
  const stones = production.getStoneTableThroughLegacyBuilder();
  const expected = normative.buildHiddenDrops(counts, normative.STONES);
  const legacy = production.buildHiddenWithBackwardStorage(counts, stones);
  const before = legacy.slice();

  assert.deepEqual(legacy.slice(1), expected.slice().reverse());
  for (let k = 1; k <= 7; k += 1) {
    assert.equal(production.hiddenByNearness(legacy, k), expected[k - 1]);
  }
  assert.deepEqual(legacy, before, 'hiddenByNearness ne deve mutar ni reversar li storage legacy.');
}

const counts = normative.workCounts(f, f);
const stones = production.getStoneTableThroughLegacyBuilder();
const expected = normative.buildHiddenDrops(counts, normative.STONES);
const run = production.historicHiddenByNearnessThroughMonsterPath(f, f, counts, stones, 1);
assert.equal(run.result, expected[0]);
assert.equal(run.context.currentHandler, 'Patch05HiddenNearnessWrapper');
assert.equal(run.context.phase, 'PATCH_05_HIDDEN_NEARNESS_TRANSLATOR');
assert.equal(run.context.status, 'PATCH_05_RESULT');
assert.deepEqual(run.context.branchTrace, [
  'BOOTSTRAP_VALIDATED',
  'DISCOVERY_05_HIDDEN_BACKWARD_STORAGE',
  'PATCH_05_HIDDEN_NEARNESS_TRANSLATOR'
]);
assert.equal(run.context.patch05RequestedNearness, 1);
assert.equal(run.context.patch05PhysicalSlot, 7);
assert.equal(run.context.patch05StoragePreserved, true);
assert.equal(run.context.patch05Output, expected[0]);
assert.equal(run.context.legacyHiddenStorage[1], expected[6]);
assert.equal(run.context.legacyHiddenStorage[7], expected[0]);
assert.equal(run.context.metrics['discovery05.hiddenBackward.calls'], 1n);
assert.equal(run.context.metrics['patch05.hiddenNearness.calls'], 1n);

const source = production.hiddenByNearness.toString();
assert.match(source, /legacyHidden\[8 - k\]/, 'Patch 05 deve usar explicitmen li translator 8-k.');
assert.doesNotMatch(source, /reverse\s*\(/, 'Patch 05 ne deve reversar li array legacy.');
assert.throws(() => production.hiddenByNearness(new Array(8).fill(null), 0), RangeError);
assert.throws(() => production.hiddenByNearness(new Array(8).fill(null), 8), RangeError);

console.log('PATCH 05: PASS — hiddenByNearness usa 8-k, conserva li storage retrograd e rende omni sett hidden drops in ordine normativ.');
