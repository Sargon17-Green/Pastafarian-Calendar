'use strict';

const assert = require('assert/strict');
const production = require('../src');
const normative = require('./normative-reference');

const f = normative.FOUNDATION_DAY;
const dropStore = [];
for (let slot = 1; slot <= 16; slot += 1) {
  dropStore[slot] = 10000n + BigInt(slot);
}
const legacyHidden = [null, 707n, 606n, 505n, 404n, 303n, 202n, 101n];
const hiddenSnapshot = legacyHidden.slice();

assert.equal(production.legacyPrior(dropStore, 1, 1), undefined);
assert.equal(production.legacyPrior(dropStore, 1, 7), undefined);
assert.equal(production.priorPatch(dropStore, legacyHidden, 1, 1), 101n);
assert.equal(production.priorPatch(dropStore, legacyHidden, 1, 7), 707n);
assert.equal(production.priorPatch(dropStore, legacyHidden, 4, 1), dropStore[3]);
assert.deepEqual(legacyHidden, hiddenSnapshot, 'Patch 06 ne deve reversar o mutar li storage hidden legacy.');

for (let i = 1; i <= 9; i += 1) {
  for (let back = 1; back <= 7; back += 1) {
    const slot = i - back;
    if (slot < -6) continue;
    const expected = slot >= 1
      ? dropStore[slot]
      : production.hiddenByNearness(legacyHidden, 1 - slot);
    assert.equal(
      production.priorPatch(dropStore, legacyHidden, i, back),
      expected,
      'priorPatch deve resolver exactmen li slot historic ' + slot + '.'
    );
  }
}

const patchSource = production.priorPatch.toString();
assert.match(
  patchSource,
  /return legacyPrior\(dropStore, i, back\)/,
  'Por slots visibil li call a legacyPrior deve restar real in li patch.'
);
assert.match(patchSource, /const k = 1 - slot/);
assert.match(patchSource, /return hiddenByNearness\(legacyHidden, k\)/);
assert.doesNotMatch(patchSource, /\.reverse\s*\(/);

const hiddenRoute = production.historicPriorThroughMonsterPath(f, f, dropStore, legacyHidden, 1, 7);
assert.equal(hiddenRoute.result, 707n);
assert.equal(hiddenRoute.context.legacyPriorOutput, undefined);
assert.equal(hiddenRoute.context.patch06PriorSlot, -6);
assert.equal(hiddenRoute.context.patch06HiddenNearness, 7);
assert.equal(hiddenRoute.context.patch06LegacyVisibleCallUsed, false);
assert.equal(hiddenRoute.context.patch06Output, 707n);
assert.equal(hiddenRoute.context.currentHandler, 'Patch06PriorWrapper');
assert.equal(hiddenRoute.context.phase, 'PATCH_06_PRIOR_HIDDEN_MAPPING');
assert.equal(hiddenRoute.context.status, 'PATCH_06_RESULT');
assert.deepEqual(hiddenRoute.context.branchTrace, [
  'BOOTSTRAP_VALIDATED',
  'DISCOVERY_06_LEGACY_PRIOR_VISIBLE_ONLY',
  'PATCH_06_PRIOR_HIDDEN_MAPPING'
]);
assert.equal(hiddenRoute.context.metrics['discovery06.legacyPrior.calls'], 1n);
assert.equal(hiddenRoute.context.metrics['patch06.prior.calls'], 1n);

const visibleRoute = production.historicPriorThroughMonsterPath(f, f, dropStore, legacyHidden, 5, 2);
assert.equal(visibleRoute.result, dropStore[3]);
assert.equal(visibleRoute.context.legacyPriorOutput, dropStore[3]);
assert.equal(visibleRoute.context.patch06PriorSlot, 3);
assert.equal(visibleRoute.context.patch06HiddenNearness, null);
assert.equal(visibleRoute.context.patch06LegacyVisibleCallUsed, true);
assert.equal(visibleRoute.context.patch06Output, dropStore[3]);

const realCounts = normative.workCounts(f, f);
const realStones = production.getStoneTableThroughLegacyBuilder();
const realHidden = production.buildHiddenWithBackwardStorage(realCounts, realStones);
const expectedHidden = normative.buildHiddenDrops(realCounts, normative.STONES);
for (let back = 1; back <= 7; back += 1) {
  assert.equal(
    production.priorPatch([], realHidden, 1, back),
    expectedHidden[back - 1],
    'Li prim visible drop deve reciver hidden' + back + ' quam predecessor.'
  );
}

assert.throws(
  () => production.priorPatch(dropStore, legacyHidden, 1, 8),
  RangeError,
  'Un slot plu lontan quam hidden7 ne deve esser silentmen fabricat.'
);

console.log('PATCH 06: PASS — legacyPrior resta intact; slots visibil usa li call legacy real e slots 0..-6 passa per k=1-slot e hiddenByNearness.');
