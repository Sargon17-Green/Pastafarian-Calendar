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

const routed = production.discovery06LegacyPriorThroughMonsterPath(f, f, dropStore, 1, 3);
assert.equal(routed.result, undefined);
assert.equal(routed.context.currentHandler, 'Discovery06PriorHandler');
assert.equal(routed.context.phase, 'DISCOVERY_06_LEGACY_PRIOR_VISIBLE_ONLY');
assert.equal(routed.context.status, 'DISCOVERY_06_LEGACY_RESULT');
assert.deepEqual(routed.context.branchTrace, [
  'BOOTSTRAP_VALIDATED',
  'DISCOVERY_06_LEGACY_PRIOR_VISIBLE_ONLY'
]);
assert.equal(routed.context.legacyPriorVisibleIndex, 1);
assert.equal(routed.context.legacyPriorBack, 3);
assert.equal(routed.context.legacyPriorSlot, -2);
assert.equal(routed.context.legacyPriorSlotIsVisible, false);
assert.equal(routed.context.legacyPriorOutput, undefined);
assert.equal(routed.context.metrics['discovery06.legacyPrior.calls'], 1n);

const realCounts = normative.workCounts(f, f);
const realStones = production.getStoneTableThroughLegacyBuilder();
const realHidden = production.buildHiddenWithBackwardStorage(realCounts, realStones);
assert.equal(production.hiddenByNearness(realHidden, 1), normative.buildHiddenDrops(realCounts, normative.STONES)[0]);

console.log('DISCOVERY 06: legacyPrior conosse solmen dropStore[i-back] e ne posse resolver slots 0..-6 quam hidden drops.');
console.log('slots:    ' + probes.map(({ i, back }) => i - back).join(', '));
console.log('legacy:   ' + legacy.map((value) => value === undefined ? 'undefined' : value.toString()).join(', '));
console.log('normativ: ' + expected.map((value) => value.toString()).join(', '));

assert.deepEqual(
  legacy,
  expected,
  'DISCOVERY 06 EXPECTED RED: legacyPrior ne conosse li mapping de slots non-positiv a hidden1..hidden7.'
);
