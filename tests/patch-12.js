'use strict';

const assert = require('assert/strict');
const production = require('../src');
const normative = require('./normative-reference');

const fixtureLatch = [1, 2, 3, 4, 6, 5];
const expectedById = new Map([
  [1, 2], [2, 3], [3, 4], [4, 6], [5, 1], [6, 5]
]);
for (let id = 1; id <= 6; id += 1) {
  assert.equal(production.nextBowlFromOrderAt46Latch(fixtureLatch, id), expectedById.get(id));
}
assert.equal(production.oldNextBowlFixedName(4), 5);
assert.equal(production.oldNextBowlFixedName(5), 6);
assert.equal(production.oldNextBowlFixedName(6), 1);
assert.equal(production.nextBowlFromOrderAt46Latch(fixtureLatch, 4), 6);
assert.equal(production.nextBowlFromOrderAt46Latch(fixtureLatch, 5), 1);
assert.equal(production.nextBowlFromOrderAt46Latch(fixtureLatch, 6), 5);

for (let rank0 = 0n; rank0 < 720n; rank0 += 1n) {
  const order = production.oldPermutationUnrank0(rank0);
  for (let queriedId = 1; queriedId <= 6; queriedId += 1) {
    const expected = normative.nextBowlInDrop46Order({ orderAtDrop46: order }, queriedId);
    assert.equal(
      production.nextBowlFromOrderAt46Latch(order, queriedId),
      expected,
      'Li successor circular deve esser exact por rank0 ' + rank0 + ', bowl ' + queriedId
    );
  }
}

assert.throws(() => production.nextBowlFromOrderAt46Latch([1, 2, 3, 4, 5], 1), TypeError);
assert.throws(() => production.nextBowlFromOrderAt46Latch([1, 2, 3, 4, 5, 5], 1), RangeError);
assert.throws(() => production.nextBowlFromOrderAt46Latch(fixtureLatch, 0), RangeError);
assert.throws(() => production.nextBowlFromOrderAt46Latch(fixtureLatch, 7), RangeError);

const oldSource = production.oldNextBowlFixedName.toString();
assert.match(oldSource, /return id === 6 \? 1 : id \+ 1;/);
assert.doesNotMatch(oldSource, /indexOf|orderAt46Latch/);
const patchSource = production.nextBowlFromOrderAt46Latch.toString();
assert.match(patchSource, /orderAt46Latch\.indexOf\(queriedBowlId\)/);
assert.match(patchSource, /\(position \+ 1\) % orderAt46Latch\.length/);

const calculationDay = normative.FOUNDATION_DAY;
const targetDay = normative.FOUNDATION_DAY;
const counts = normative.workCounts(calculationDay, targetDay);
const stones = production.getStoneTableThroughLegacyBuilder();
const sauce = normative.sauce(calculationDay, targetDay);
const queriedId = sauce.orderAtDrop46[3];
const execution = production.historicNextBowlThroughMonsterPath(
  calculationDay, targetDay, counts, stones, queriedId
);
const expected = normative.nextBowlInDrop46Order(sauce, queriedId);
assert.equal(execution.result, expected);
assert.equal(execution.context.currentHandler, 'NextBowlPatchWrapper');
assert.equal(execution.context.previousHandler, 'Discovery12NextBowlHandler');
assert.equal(execution.context.phase, 'PATCH_12_LATCH_CIRCULAR_SUCCESSOR');
assert.equal(execution.context.status, 'PATCH_12_RESULT');
assert.deepEqual(execution.context.patch12OrderAt46Latch, sauce.orderAtDrop46);
assert.equal(execution.context.patch12QueriedId, queriedId);
assert.equal(execution.context.patch12QueriedPosition, 3);
assert.equal(execution.context.patch12LegacyDiagnosticPreserved, true);
assert.equal(execution.context.patch12LegacyDiagnostic, production.oldNextBowlFixedName(queriedId));
assert.equal(execution.context.patch12Output, expected);
assert.deepEqual(execution.context.branchTrace, [
  'BOOTSTRAP_VALIDATED',
  'DISCOVERY_11_OVERWRITABLE_ORDER_MEMORY',
  'PATCH_11_ORDER_AT_46_LATCH',
  'DISCOVERY_12_FIXED_ID_NEXT_BOWL',
  'PATCH_12_LATCH_CIRCULAR_SUCCESSOR'
]);
assert.equal(execution.context.metrics['discovery12.fixedIdNextBowl.calls'], 1n);
assert.equal(execution.context.metrics['patch12.nextBowl.calls'], 1n);

console.log('PATCH 12: PASS — oldNextBowlFixedName resta intact e diagnostic; li resultate semantic veni del successor circular in orderAt46Latch.');
