'use strict';

const assert = require('assert/strict');
const production = require('../src');
const normative = require('./normative-reference');

assert.equal(typeof production.oldContiguousMonthDayGuess, 'function');
assert.equal(typeof production.LegacyContiguousMonthDayAdapter, 'function');
assert.equal(typeof production.Discovery25ContiguousMonthDayHandler, 'function');
assert.equal(typeof production.discovery25LegacyContiguousMonthDayThroughMonsterPath, 'function');
assert.equal('countMonthOccurrencesThroughTarget' in production, false);
assert.equal('MonthDayOccurrencePatchWrapper' in production, false);
assert.equal('OpeningGateIntervalPatchWrapper' in production, false);

const helperSource = production.oldContiguousMonthDayGuess.toString();
assert.match(helperSource, /indexOf/);
assert.ok(helperSource.includes('targetPosition - firstPosition + 1'));
assert.doesNotMatch(helperSource, /filter|occurrence|countMonthOccurrencesThroughTarget/);

const weaving = [1,1,2,1,3,3,1,2,2,2,3,3];
assert.equal(production.oldContiguousMonthDayGuess(weaving, 4), 4);
assert.equal(production.oldContiguousMonthDayGuess(weaving, 8), 6);
assert.equal(production.oldContiguousMonthDayGuess(weaving, 6), 2);
assert.equal(weaving.slice(0, 4).filter((value) => value === 1).length, 3);
assert.equal(weaving.slice(0, 8).filter((value) => value === 2).length, 2);
assert.equal(weaving.slice(0, 6).filter((value) => value === 3).length, 2);

const f = normative.FOUNDATION_DAY;
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
  nextYear() { throw new Error('Discovery 25 ne deve caminar avante ex Year 5000 in ti witness.'); },
  previousYear() { throw new Error('Discovery 25 ne deve caminar retro ex Year 5000 in ti witness.'); }
};

const routed = production.discovery25LegacyContiguousMonthDayThroughMonsterPath(
  new production.BaseMonsterManager(), calculationDay, calculationDay, -1n,
  gates, candidatePairs, selectionStream, noWalkExpected
);
assert.equal(routed.context.status, 'DISCOVERY_25_LEGACY_RESULT');
assert.equal(routed.context.legacyMonthDayHelperExecuted, true);
assert.equal(routed.result.helperExecuted, true);
assert.equal(routed.result.targetPosition, 92);
assert.equal(routed.result.monthId, 9);
assert.equal(routed.result.firstPosition, 15);
assert.equal(routed.result.dayInMonth, 78);
assert.equal(routed.context.legacyMonthDaySemantic, 78);
assert.equal(routed.context.patch24SemanticMonthWeaving, routed.result.monthWeaving);
assert.deepEqual(routed.context.branchTrace.slice(-3), [
  'DISCOVERY_24_LEGACY_MONTH_CHOSEN_EACH_DAY',
  'PATCH_24_LEGAL_WHOLE_MONTH_WEAVING',
  'DISCOVERY_25_CONTIGUOUS_MONTH_DAY_GUESS'
]);
assert.equal(routed.context.metrics['discovery25.oldContiguousMonthDayGuess.calls'], 1n);

const expectedOccurrenceCount = routed.result.monthWeaving
  .slice(0, routed.result.targetPosition)
  .filter((monthId) => monthId === routed.result.monthId).length;
assert.equal(expectedOccurrenceCount, 14);

console.log('DISCOVERY 25 DIAGNOSTIC: li guess old tracta occurrences intertexet quam si ili esset contigui.');
console.log('target position: ' + routed.result.targetPosition);
console.log('monthId: ' + routed.result.monthId);
console.log('first position: ' + routed.result.firstPosition);
console.log('legacy contiguous guess: ' + routed.result.dayInMonth);
console.log('normativ occurrence count til target inclusiv: ' + expectedOccurrenceCount);

assert.equal(
  routed.result.dayInMonth,
  expectedOccurrenceCount,
  'Discovery 25 deve restar EXPECTED_RED: li guess contigui ne conta solmen occurrences del monthId til target inclusiv.'
);
