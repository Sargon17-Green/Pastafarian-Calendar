'use strict';

const assert = require('assert/strict');
const production = require('../src');
const normative = require('./normative-reference');

const fixedCases = [
  [1, 2],
  [2, 3],
  [3, 4],
  [4, 5],
  [5, 6],
  [6, 1]
];
for (const [queriedId, expectedFixed] of fixedCases) {
  assert.equal(production.oldNextBowlFixedName(queriedId), expectedFixed);
}
assert.throws(() => production.oldNextBowlFixedName(0), RangeError);
assert.throws(() => production.oldNextBowlFixedName(7), RangeError);

const fixtureLatch = [1, 2, 3, 4, 6, 5];
const fixtureQueries = [4, 5, 6];
const legacyFixture = fixtureQueries.map((id) => production.oldNextBowlFixedName(id));
const normativeFixture = fixtureQueries.map((id) =>
  normative.nextBowlInDrop46Order({ orderAtDrop46: fixtureLatch }, id)
);
const patchedFixture = fixtureQueries.map((id) => production.nextBowlFromOrderAt46Latch(fixtureLatch, id));
assert.deepEqual(legacyFixture, [5, 6, 1]);
assert.deepEqual(normativeFixture, [6, 1, 5]);
assert.notDeepEqual(legacyFixture, normativeFixture);
assert.deepEqual(patchedFixture, normativeFixture);

const calculationDay = normative.FOUNDATION_DAY;
const targetDay = normative.FOUNDATION_DAY;
const counts = normative.workCounts(calculationDay, targetDay);
const stones = production.getStoneTableThroughLegacyBuilder();
const latched = production.historicOrderAt46ThroughMonsterPath(
  calculationDay, targetDay, counts, stones
);
const queriedId = latched.result.orderAt46Latch[3];
const routedLegacy = production.discovery12LegacyNextBowlThroughMonsterPath(
  calculationDay, targetDay, counts, stones, queriedId
);
const routedPatched = production.historicNextBowlThroughMonsterPath(
  calculationDay, targetDay, counts, stones, queriedId
);
const expectedSauce = normative.sauce(calculationDay, targetDay);
const normativeRouted = normative.nextBowlInDrop46Order(expectedSauce, queriedId);
assert.equal(routedLegacy.context.currentHandler, 'Discovery12NextBowlHandler');
assert.equal(routedLegacy.context.previousHandler, 'Patch11OrderAt46LatchWrapper');
assert.equal(routedLegacy.context.phase, 'DISCOVERY_12_FIXED_ID_NEXT_BOWL');
assert.equal(routedLegacy.context.status, 'DISCOVERY_12_LEGACY_RESULT');
assert.deepEqual(routedLegacy.context.legacyNextBowlOrderAt46Latch, expectedSauce.orderAtDrop46);
assert.equal(routedLegacy.context.legacyNextBowlQueriedId, queriedId);
assert.equal(routedLegacy.context.legacyNextBowlOutput, production.oldNextBowlFixedName(queriedId));
assert.equal(routedLegacy.result, production.oldNextBowlFixedName(queriedId));
assert.notEqual(routedLegacy.result, normativeRouted);
assert.equal(routedPatched.result, normativeRouted);
assert.equal(routedPatched.context.patch12LegacyDiagnostic, production.oldNextBowlFixedName(queriedId));
assert.deepEqual(routedLegacy.context.branchTrace, [
  'BOOTSTRAP_VALIDATED',
  'DISCOVERY_11_OVERWRITABLE_ORDER_MEMORY',
  'PATCH_11_ORDER_AT_46_LATCH',
  'DISCOVERY_12_FIXED_ID_NEXT_BOWL'
]);
assert.equal(routedLegacy.context.metrics['discovery11.overwritableOrder.calls'], 1n);
assert.equal(routedLegacy.context.metrics['patch11.orderAt46Latch.calls'], 1n);
assert.equal(routedLegacy.context.metrics['discovery12.fixedIdNextBowl.calls'], 1n);

const source = production.oldNextBowlFixedName.toString();
assert.match(source, /id === 6 \? 1 : id \+ 1/);
assert.doesNotMatch(source, /indexOf|orderAt46Latch/);

console.log('DISCOVERY 12 PRESERVAT: li helper legacy usa li successor numeric fix e resta divergent del latch; Patch 12 rende li path semantic exact.');
console.log('fixture legacy:    ' + legacyFixture.join(', '));
console.log('fixture normativ:  ' + normativeFixture.join(', '));
console.log('fixture reparat:   ' + patchedFixture.join(', '));
