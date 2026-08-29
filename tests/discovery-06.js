'use strict';

const assert = require('assert/strict');
const production = require('../src');
const normative = require('./normative-reference');

const f = normative.FOUNDATION_DAY;
const dropStore = [];
dropStore[1] = 1001n;
dropStore[2] = 1002n;
dropStore[3] = 1003n;
dropStore[4] = 1004n;

assert.equal(
  production.legacyPrior(dropStore, 3, 1),
  1002n,
  'legacyPrior deve ancor functionar quand i-back indica un visible drop ja present.'
);

const legacyHidden = [null, 707n, 606n, 505n, 404n, 303n, 202n, 101n];
const probes = [
  { i: 1, back: 1, nearness: 1 },
  { i: 1, back: 3, nearness: 3 },
  { i: 1, back: 7, nearness: 7 },
  { i: 2, back: 3, nearness: 2 }
];

const legacy = probes.map(({ i, back }) => production.legacyPrior(dropStore, i, back));
const expected = probes.map(({ nearness }) => production.hiddenByNearness(legacyHidden, nearness));
const patched = probes.map(({ i, back }) => production.priorPatch(dropStore, legacyHidden, i, back));

assert.deepEqual(
  legacy,
  [undefined, undefined, undefined, undefined],
  'Li scar de Discovery 06 deve restar directmen observabil in legacyPrior.'
);
assert.deepEqual(
  patched,
  expected,
  'Li mem regression normativ de Discovery 06 deve devenir verd exclusivmen tra Patch 06.'
);

const routedLegacy = production.discovery06LegacyPriorThroughMonsterPath(f, f, dropStore, 1, 3);
assert.equal(routedLegacy.result, undefined);
assert.equal(routedLegacy.context.currentHandler, 'Discovery06PriorHandler');
assert.equal(routedLegacy.context.phase, 'DISCOVERY_06_LEGACY_PRIOR_VISIBLE_ONLY');
assert.equal(routedLegacy.context.status, 'DISCOVERY_06_LEGACY_RESULT');
assert.deepEqual(routedLegacy.context.branchTrace, [
  'BOOTSTRAP_VALIDATED',
  'DISCOVERY_06_LEGACY_PRIOR_VISIBLE_ONLY'
]);
assert.equal(routedLegacy.context.legacyPriorVisibleIndex, 1);
assert.equal(routedLegacy.context.legacyPriorBack, 3);
assert.equal(routedLegacy.context.legacyPriorSlot, -2);
assert.equal(routedLegacy.context.legacyPriorSlotIsVisible, false);
assert.equal(routedLegacy.context.legacyPriorOutput, undefined);
assert.equal(routedLegacy.context.metrics['discovery06.legacyPrior.calls'], 1n);

const routedPatched = production.historicPriorThroughMonsterPath(f, f, dropStore, legacyHidden, 1, 3);
assert.equal(routedPatched.result, 303n);
assert.equal(routedPatched.context.patch06PriorSlot, -2);
assert.equal(routedPatched.context.patch06HiddenNearness, 3);
assert.equal(routedPatched.context.patch06LegacyVisibleCallUsed, false);
assert.equal(routedPatched.context.patch06Output, 303n);
assert.equal(routedPatched.context.currentHandler, 'Patch06PriorWrapper');
assert.equal(routedPatched.context.status, 'PATCH_06_RESULT');
assert.deepEqual(routedPatched.context.branchTrace, [
  'BOOTSTRAP_VALIDATED',
  'DISCOVERY_06_LEGACY_PRIOR_VISIBLE_ONLY',
  'PATCH_06_PRIOR_HIDDEN_MAPPING'
]);

const realCounts = normative.workCounts(f, f);
const realStones = production.getStoneTableThroughLegacyBuilder();
const realHidden = production.buildHiddenWithBackwardStorage(realCounts, realStones);
assert.equal(production.hiddenByNearness(realHidden, 1), normative.buildHiddenDrops(realCounts, normative.STONES)[0]);

console.log('DISCOVERY 06: PASS pos Patch 06 — legacyPrior resta ciec por slots 0..-6, ma li route historic traducte a hidden drops.');
console.log('slots legacy:  ' + probes.map(({ i, back }) => i - back).join(', '));
console.log('legacy direct: ' + legacy.map((value) => value === undefined ? 'undefined' : value.toString()).join(', '));
console.log('patched:       ' + patched.map((value) => value.toString()).join(', '));
