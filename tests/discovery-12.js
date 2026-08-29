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
assert.deepEqual(legacyFixture, [5, 6, 1]);
assert.deepEqual(normativeFixture, [6, 1, 5]);
assert.notDeepEqual(legacyFixture, normativeFixture);

const calculationDay = normative.FOUNDATION_DAY;
const targetDay = normative.FOUNDATION_DAY;
const counts = normative.workCounts(calculationDay, targetDay);
const stones = production.getStoneTableThroughLegacyBuilder();
const latched = production.historicOrderAt46ThroughMonsterPath(
  calculationDay, targetDay, counts, stones
);
const queriedId = latched.result.orderAt46Latch[3];
const routed = production.discovery12LegacyNextBowlThroughMonsterPath(
  calculationDay, targetDay, counts, stones, queriedId
);
const expectedSauce = normative.sauce(calculationDay, targetDay);
const normativeRouted = normative.nextBowlInDrop46Order(expectedSauce, queriedId);
assert.equal(routed.context.currentHandler, 'Discovery12NextBowlHandler');
assert.equal(routed.context.previousHandler, 'Patch11OrderAt46LatchWrapper');
assert.equal(routed.context.phase, 'DISCOVERY_12_FIXED_ID_NEXT_BOWL');
assert.equal(routed.context.status, 'DISCOVERY_12_LEGACY_RESULT');
assert.deepEqual(routed.context.legacyNextBowlOrderAt46Latch, expectedSauce.orderAtDrop46);
assert.equal(routed.context.legacyNextBowlQueriedId, queriedId);
assert.equal(routed.context.legacyNextBowlOutput, production.oldNextBowlFixedName(queriedId));
assert.equal(routed.result, production.oldNextBowlFixedName(queriedId));
assert.notEqual(routed.result, normativeRouted);
assert.deepEqual(routed.context.branchTrace, [
  'BOOTSTRAP_VALIDATED',
  'DISCOVERY_11_OVERWRITABLE_ORDER_MEMORY',
  'PATCH_11_ORDER_AT_46_LATCH',
  'DISCOVERY_12_FIXED_ID_NEXT_BOWL'
]);
assert.equal(routed.context.metrics['discovery11.overwritableOrder.calls'], 1n);
assert.equal(routed.context.metrics['patch11.orderAt46Latch.calls'], 1n);
assert.equal(routed.context.metrics['discovery12.fixedIdNextBowl.calls'], 1n);

const source = production.oldNextBowlFixedName.toString();
assert.match(source, /id === 6 \? 1 : id \+ 1/);
assert.doesNotMatch(source, /indexOf|orderAt46Latch/);

console.log('DISCOVERY 12: li helper legacy usa li successor numeric fix de bowl ID e ignora li position in orderAt46Latch.');
console.log('fixture legacy:    ' + legacyFixture.join(', '));
console.log('fixture normativ:  ' + normativeFixture.join(', '));
console.log('route latch:       ' + expectedSauce.orderAtDrop46.join(', '));
console.log('route queried ID:  ' + queriedId + '; legacy=' + routed.result + '; normativ=' + normativeRouted);

assert.deepEqual(
  legacyFixture,
  normativeFixture,
  'DISCOVERY 12 EXPECTED RED: li next-bowl legacy avansa per ID numeric fix in vice del successor circular in orderAt46Latch.'
);
