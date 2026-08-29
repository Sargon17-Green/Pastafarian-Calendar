'use strict';

const assert = require('assert/strict');
const production = require('../src');
const normative = require('./normative-reference');

assert.equal(typeof production.oldContiguousMonthDayGuess, 'function');
assert.equal(typeof production.countMonthOccurrencesThroughTarget, 'function');
assert.equal(typeof production.MonthDayOccurrencePatchWrapper, 'function');
assert.equal(typeof production.historicMonthDayOccurrenceThroughMonsterPath, 'function');
assert.equal(typeof production.OpeningGateIntervalPatchWrapper, 'function');

const oldSource = production.oldContiguousMonthDayGuess.toString();
assert.match(oldSource, /indexOf/);
assert.ok(oldSource.includes('targetPosition - firstPosition + 1'));
assert.doesNotMatch(oldSource, /countMonthOccurrencesThroughTarget|occurrence/);

const weaving = [1,1,2,1,3,3,1,2,2,2,3,3];
assert.equal(production.oldContiguousMonthDayGuess(weaving, 4), 4);
assert.equal(production.countMonthOccurrencesThroughTarget(weaving, 4), 3);
assert.equal(production.oldContiguousMonthDayGuess(weaving, 8), 6);
assert.equal(production.countMonthOccurrencesThroughTarget(weaving, 8), 2);
assert.equal(production.oldContiguousMonthDayGuess(weaving, 6), 2);
assert.equal(production.countMonthOccurrencesThroughTarget(weaving, 6), 2);
assert.throws(() => production.countMonthOccurrencesThroughTarget([], 1), RangeError);
assert.throws(() => production.countMonthOccurrencesThroughTarget(weaving, 0), RangeError);
assert.throws(() => production.countMonthOccurrencesThroughTarget(weaving, weaving.length + 1), RangeError);

function patchContextFor(targetPosition) {
  const context = new production.BaseMonsterContext(1n, 1n);
  const monthId = weaving[targetPosition - 1];
  context.status = 'DISCOVERY_25_LEGACY_RESULT';
  context.currentHandler = 'Discovery25ContiguousMonthDayHandler';
  context.phase = 'DISCOVERY_25_CONTIGUOUS_MONTH_DAY_GUESS';
  context.branchTrace.push('DISCOVERY_25_CONTIGUOUS_MONTH_DAY_GUESS');
  context.legacyMonthDayWeaving = weaving;
  context.legacyMonthDayTargetDay = BigInt(targetPosition);
  context.legacyMonthDayTargetPosition = targetPosition;
  context.legacyMonthDayMonthId = monthId;
  context.legacyMonthDayFirstPosition = weaving.indexOf(monthId) + 1;
  context.legacyMonthDayGuess = production.oldContiguousMonthDayGuess(weaving, targetPosition);
  context.legacyMonthDaySemantic = context.legacyMonthDayGuess;
  context.legacyMonthDayHelperExecuted = true;
  return context;
}

const wrapper = new production.MonthDayOccurrencePatchWrapper(
  new production.BaseValidationManager(),
  new production.BaseMetricsManager()
);

const wrongContext = patchContextFor(4);
const wrong = wrapper.repair(wrongContext);
assert.equal(wrong.legacyGuess, 4);
assert.equal(wrong.dayInMonth, 3);
assert.equal(wrongContext.patch25LegacyGuess, 4);
assert.equal(wrongContext.patch25LegacyGuessPreserved, true);
assert.equal(wrongContext.patch25OccurrenceCount, 3);
assert.equal(wrongContext.patch25SemanticMonthDay, 3);
assert.equal(wrongContext.legacyMonthDaySemantic, 3);
assert.equal(wrongContext.status, 'PATCH_25_RESULT');
assert.deepEqual(wrongContext.branchTrace.slice(-2), [
  'DISCOVERY_25_CONTIGUOUS_MONTH_DAY_GUESS',
  'PATCH_25_MONTH_DAY_OCCURRENCE_COUNT'
]);
assert.equal(wrongContext.metrics['patch25.legacyGuessPreserved.calls'], 1n);
assert.equal(wrongContext.metrics['patch25.countMonthOccurrencesThroughTarget.calls'], 1n);
assert.equal(wrongContext.metrics['patch25.semanticOverwrite.calls'], 1n);

const alreadyCorrectContext = patchContextFor(6);
const alreadyCorrect = wrapper.repair(alreadyCorrectContext);
assert.equal(alreadyCorrect.legacyGuess, 2);
assert.equal(alreadyCorrect.dayInMonth, 2);
assert.equal(alreadyCorrectContext.patch25SemanticMonthDay, 2);
assert.equal(alreadyCorrectContext.patch25LegacyGuess, 2);

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
  nextYear() { throw new Error('Patch 25 ne deve caminar avante ex Year 5000 in ti witness.'); },
  previousYear() { throw new Error('Patch 25 ne deve caminar retro ex Year 5000 in ti witness.'); }
};

const manager = new production.BaseMonsterManager();
const routed = production.historicMonthDayOccurrenceThroughMonsterPath(
  manager, calculationDay, calculationDay, -1n,
  gates, candidatePairs, selectionStream, noWalkExpected
);
assert.equal(routed.context.status, 'PATCH_25_RESULT');
assert.equal(routed.context.legacyMonthDayHelperExecuted, true);
assert.equal(routed.context.patch25LegacyGuessPreserved, true);
assert.equal(routed.result.targetPosition, 92);
assert.equal(routed.result.monthId, 9);
assert.equal(routed.result.legacyGuess, 78);
assert.equal(routed.result.dayInMonth, 14);
assert.equal(routed.context.legacyMonthDayGuess, 78);
assert.equal(routed.context.patch25OccurrenceCount, 14);
assert.equal(routed.context.patch25SemanticMonthDay, 14);
assert.equal(routed.context.legacyMonthDaySemantic, 14);
assert.deepEqual(routed.context.branchTrace.slice(-4), [
  'DISCOVERY_24_LEGACY_MONTH_CHOSEN_EACH_DAY',
  'PATCH_24_LEGAL_WHOLE_MONTH_WEAVING',
  'DISCOVERY_25_CONTIGUOUS_MONTH_DAY_GUESS',
  'PATCH_25_MONTH_DAY_OCCURRENCE_COUNT'
]);
assert.equal(routed.context.metrics['discovery25.oldContiguousMonthDayGuess.calls'], 1n);
assert.equal(routed.context.metrics['patch25.legacyGuessPreserved.calls'], 1n);
assert.equal(routed.context.metrics['patch25.countMonthOccurrencesThroughTarget.calls'], 1n);
assert.equal(routed.context.metrics['patch25.semanticOverwrite.calls'], 1n);

const expected = routed.result.monthWeaving
  .slice(0, routed.result.targetPosition)
  .filter((monthId) => monthId === routed.result.monthId).length;
assert.equal(expected, 14);
assert.equal(routed.result.dayInMonth, expected);

const second = production.historicMonthDayOccurrenceThroughMonsterPath(
  manager, calculationDay, calculationDay, -1n,
  gates, candidatePairs, selectionStream, noWalkExpected
);
assert.notEqual(second.context, routed.context);
assert.equal(second.context.patch25LegacyGuess, 78);
assert.equal(second.result.dayInMonth, 14);
assert.notEqual(second.result.monthWeaving, routed.result.monthWeaving);
assert.deepEqual(second.result.monthWeaving, routed.result.monthWeaving);

console.log('PATCH 25 PASS: legacy-guess=78 occurrence-count=14 target-inclusive overwrite verified.');
