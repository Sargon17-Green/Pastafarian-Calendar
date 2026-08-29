'use strict';

const assert = require('assert/strict');
const production = require('../src');
const normative = require('./normative-reference');

assert.equal(typeof production.wrapMonth, 'function');
assert.equal(typeof production.legacyChooseEachDaySeparately, 'function');
assert.equal(typeof production.monthWeavingAnswerRingFromSauce, 'function');
assert.equal(typeof production.LegacyMonthWeavingAdapter, 'function');
assert.equal(typeof production.Discovery24MonthWeavingHandler, 'function');
assert.equal(typeof production.discovery24LegacyMonthWeavingThroughMonsterPath, 'function');
assert.equal(typeof production.DPUnrankLegalWeaving, 'function');
assert.equal(typeof production.MonthWeavingPatchWrapper, 'function');
assert.equal('countMonthOccurrencesThroughTarget' in production, false);

const legacySource = production.legacyChooseEachDaySeparately.toString();
assert.match(legacySource, /ringAnswerAt/);
assert.match(legacySource, /wrapMonth/);
assert.doesNotMatch(legacySource, /DPUnrank|wantedRank|MonthWeavingPatchWrapper/);

assert.equal(production.wrapMonth(4, 3), 1);
assert.equal(production.wrapMonth(0, 3), 3);
assert.deepEqual(
  production.legacyChooseEachDaySeparately([2,1], { first: 1n, directionStep: 1n }),
  [1,2,1]
);

function positionsAreOrdered(word, monthCount, useLast) {
  const pos = [];
  for (let monthId = 1; monthId <= monthCount; monthId += 1) {
    pos.push(useLast ? word.lastIndexOf(monthId) : word.indexOf(monthId));
  }
  for (let i = 1; i < pos.length; i += 1) if (!(pos[i - 1] < pos[i])) return false;
  return true;
}

const f = normative.FOUNDATION_DAY;
const lengths = [4,4,4];
const witnesses = [
  { calculationDay: f, yearFirstDay: f - 120n },
  { calculationDay: f + 7n, yearFirstDay: f - 120n },
  { calculationDay: f - 11n, yearFirstDay: f - 119n }
];
let firstDivergence = null;
for (const witness of witnesses) {
  const sauceProduction = production.sauceWithCurrentScars(witness.calculationDay, witness.yearFirstDay);
  const streamProduction = production.monthWeavingAnswerRingFromSauce(sauceProduction);
  const ghost = production.legacyChooseEachDaySeparately(lengths, streamProduction);
  const sauceReference = normative.sauce(witness.calculationDay, witness.yearFirstDay);
  const family = normative.makeMonthWeavingFamily(lengths);
  const wantedRank = normative.chooseRank(normative.askBowl(sauceReference, 4, 32n), family.count());
  const expected = family.unrank1(wantedRank);
  assert.equal(ghost.length, 12);
  assert.deepEqual([1,2,3].map((id) => ghost.filter((x) => x === id).length), lengths);
  assert.notDeepEqual(ghost, expected);
  assert.ok(!positionsAreOrdered(ghost, 3, false) || !positionsAreOrdered(ghost, 3, true));
  if (firstDivergence === null) firstDivergence = { witness, ghost, expected, wantedRank, familyCount: family.count() };
}

const calculationDay = f + 102n;
const gates = {
  10: f + 10n, 14: calculationDay, 20: f + 1010n,
  30: f + 20n, 40: f + 1020n, 50: f + 30n, 60: f + 1030n
};
const candidatePairs = [
  { openIndex: 50, closeIndex: 60 },
  { openIndex: 10, closeIndex: 20 },
  { openIndex: 30, closeIndex: 40 }
];
const selectionStream = { first: 1n, directionStep: 1n };
const noWalkExpected = {
  nextYear() { throw new Error('Discovery 24 ne deve caminar avante ex Year 5000 in ti witness.'); },
  previousYear() { throw new Error('Discovery 24 ne deve caminar retro ex Year 5000 in ti witness.'); }
};
const routed = production.discovery24LegacyMonthWeavingThroughMonsterPath(
  new production.BaseMonsterManager(), calculationDay, calculationDay, -1n,
  gates, candidatePairs, selectionStream, noWalkExpected
);
assert.equal(routed.context.status, 'DISCOVERY_24_LEGACY_RESULT');
assert.equal(routed.context.legacyMonthWeavingHelperExecuted, true);
assert.deepEqual(routed.result.ghost, routed.result.monthWeaving);
assert.deepEqual(routed.result.monthLengths, routed.context.patch23SemanticMonthLengths);
assert.equal(routed.result.ghost.length, routed.result.monthLengths.reduce((a,b) => a+b, 0));
for (let monthId = 1; monthId <= routed.result.monthLengths.length; monthId += 1) {
  assert.equal(routed.result.ghost.filter((x) => x === monthId).length, routed.result.monthLengths[monthId - 1]);
}
assert.deepEqual(routed.context.branchTrace.slice(-3), [
  'DISCOVERY_23_LEGACY_CONCRETE_MONTH_LENGTH_ALL_WAYS',
  'PATCH_23_VIRTUAL_MONTH_LENGTH_ALL_WAYS',
  'DISCOVERY_24_LEGACY_MONTH_CHOSEN_EACH_DAY'
]);
assert.equal(routed.context.metrics['discovery24.legacyChooseEachDaySeparately.calls'], 1n);

console.log('DISCOVERY 24 LEGACY witness: family=' + firstDivergence.familyCount +
  ' rank=' + firstDivergence.wantedRank +
  ' ghost=[' + firstDivergence.ghost.join(',') + '] expected=[' + firstDivergence.expected.join(',') + ']');

assert.notDeepEqual(
  firstDivergence.ghost,
  firstDivergence.expected,
  'Li scar de Discovery 24 deve continuar demostrar li divergence historic pos Patch 24.'
);
