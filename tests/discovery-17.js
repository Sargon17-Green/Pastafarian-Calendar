'use strict';

const assert = require('assert/strict');
const production = require('../src');
const normative = require('./normative-reference');

const f = normative.FOUNDATION_DAY;
const calculationDay = f + 100n;
const targetDay = calculationDay;
const gates = {
  10: f + 10n,
  16: f + 500n,
  20: f + 20n,
  26: f + 510n,
  30: f + 30n,
  36: f + 520n
};

// Li tri candidates have li sam longore 490 e contene omnes li calculation-day de Year 5000.
// Lor input es intentionalmen in ordine de opening gate tardiv, tempran, medial.
const candidatePairs = [
  { openIndex: 30, closeIndex: 36 },
  { openIndex: 10, closeIndex: 16 },
  { openIndex: 20, closeIndex: 26 }
];
const selectionStream = { first: 1n, directionStep: 1n };

const stableSource = production.stableLengthOnlyPatchedYearCandidates.toString();
assert.match(stableSource, /candidateLength < right\.candidateLength/);
assert.match(stableSource, /candidateLength > right\.candidateLength/);
assert.doesNotMatch(stableSource, /openGate.*sort|opening.*gate|sortEqualLengthRunsByOpeningGate/i);

const prepared = production.stableLengthOnlyPatchedYearCandidates(gates, candidatePairs);
assert.deepEqual(prepared.map((candidate) => candidate.candidateLength), [490n, 490n, 490n]);
assert.deepEqual(prepared.map((candidate) => candidate.openGate), [f + 30n, f + 10n, f + 20n]);
for (const candidate of prepared) {
  assert.ok(candidate.openGate < calculationDay && calculationDay <= candidate.closeGate);
}

const routed = production.discovery17LegacyYear5000TieThroughMonsterPath(
  calculationDay,
  targetDay,
  -1n,
  gates,
  candidatePairs,
  selectionStream
);
assert.equal(routed.context.currentHandler, 'Discovery17Year5000TieHandler');
assert.equal(routed.context.previousHandler, 'YearCandidateCeilingPatchWrapper');
assert.equal(routed.context.phase, 'DISCOVERY_17_YEAR_5000_EQUAL_LENGTH_TIE');
assert.equal(routed.context.status, 'DISCOVERY_17_LEGACY_TIE_RESULT');
assert.equal(routed.context.patch15Output, f - 1n);
assert.deepEqual(routed.context.patch16RejectedOverlongLengths, []);
assert.deepEqual(
  routed.context.patch16SortedFamily.map((candidate) => candidate.openGate),
  [f + 30n, f + 10n, f + 20n]
);
assert.equal(routed.context.patch16SelectedOrdinal, 1n);
assert.equal(routed.context.patch16Selected.openGate, f + 30n);
assert.equal(routed.context.discovery17Year5000CalculationDay, calculationDay);
assert.equal(routed.context.discovery17StableLengthOnlyScarPreserved, true);
assert.equal(routed.context.discovery17WitnessCandidateLength, 490n);
assert.equal(routed.context.discovery17WitnessFamilySize, 3);
assert.equal(routed.context.discovery17SelectedOrdinal, 1n);
assert.equal(routed.context.discovery17Selected.openGate, f + 30n);
assert.deepEqual(routed.context.branchTrace.slice(-4), [
  'DISCOVERY_15_NEGATIVE_GATE_ASKS_POSITIVE_SIDE',
  'PATCH_15_NEGATIVE_GATE_SIGN_DETOUR',
  'PATCH_16_REAL_YEAR_MAX_5778_BEFORE_SORT',
  'DISCOVERY_17_YEAR_5000_EQUAL_LENGTH_TIE'
]);
assert.equal(routed.context.metrics['patch16.realYearCeiling.calls'], 1n);
assert.equal(routed.context.metrics['discovery17.year5000Tie.calls'], 1n);
assert.equal(routed.context.metrics['discovery17.equalLengthRuns.observed'], undefined);

const actualOpeningOrder = routed.result.preparedForSelection.map((candidate) => candidate.openGate);
const normativeOpeningOrder = routed.result.preparedForSelection
  .map((candidate) => ({ ...candidate }))
  .sort((left, right) => left.openGate < right.openGate ? -1 : left.openGate > right.openGate ? 1 : 0)
  .map((candidate) => candidate.openGate);
assert.deepEqual(normativeOpeningOrder, [f + 10n, f + 20n, f + 30n]);
assert.notDeepEqual(actualOpeningOrder, normativeOpeningOrder);
assert.equal(routed.result.selected.openGate, actualOpeningOrder[0]);
assert.notEqual(routed.result.selected.openGate, normativeOpeningOrder[0]);

const handlerSource = production.Discovery17Year5000TieHandler.prototype.handle.toString();
assert.doesNotMatch(handlerSource, /\.sort\(|sortEqualLengthRunsByOpeningGate|openGate.*candidateLength|candidateLength.*openGate/);
assert.equal('sortEqualLengthRunsByOpeningGate' in production, false);
assert.equal('oldJumpGuess' in production, false);

console.log('DISCOVERY 17 DIAGNOSTIC: li stable sort per longore conserva li ordre de input intra li tie de Year 5000.');
console.log('legacy opening order:    ' + actualOpeningOrder.map(String).join(', '));
console.log('normativ opening order:  ' + normativeOpeningOrder.map(String).join(', '));
console.log('legacy selected opening: ' + String(routed.result.selected.openGate));
console.log('normativ selected open:   ' + String(normativeOpeningOrder[0]));

assert.deepEqual(
  actualOpeningOrder,
  normativeOpeningOrder,
  'DISCOVERY 17 EXPECTED RED: pos li stable sort per longore, un run egal deve esser ordinat per opening gate tempran ante selection.'
);
