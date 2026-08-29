'use strict';

const assert = require('assert/strict');
const production = require('../src');
const normative = require('./normative-reference');

assert.equal(production.LEGACY_YEAR_MAX, 5781n);
const boundaryGates = { 0: 0n, 5: 252n, 6: 252n, 7: 251n, 8: 5781n, 9: 5782n };
assert.equal(production.legacyYearCandidateAllowed(boundaryGates, 0, 5), false);
assert.equal(production.legacyYearCandidateAllowed(boundaryGates, 0, 6), true);
assert.equal(production.legacyYearCandidateAllowed(boundaryGates, 0, 7), false);
assert.equal(production.legacyYearCandidateAllowed(boundaryGates, 0, 8), true);
assert.equal(production.legacyYearCandidateAllowed(boundaryGates, 0, 9), false);
const legacySource = production.legacyYearCandidateAllowed.toString();
assert.match(legacySource, /candidateLength <= LEGACY_YEAR_MAX/);
assert.doesNotMatch(legacySource, /REAL_YEAR_MAX_PATCH|5778n.*reject|candidateLength > 5778n/);

const f = normative.FOUNDATION_DAY;
const gates = {
  0: f,
  6: f + 5778n,
  7: f + 5779n,
  8: f + 5780n,
  9: f + 5781n,
  10: f + 5782n
};
const candidatePairs = [
  { openIndex: 0, closeIndex: 9 },
  { openIndex: 0, closeIndex: 7 },
  { openIndex: 0, closeIndex: 6 },
  { openIndex: 0, closeIndex: 8 },
  { openIndex: 0, closeIndex: 10 }
];

assert.equal(production.legacyYearCandidateAllowed(gates, 0, 6), true);
assert.equal(production.legacyYearCandidateAllowed(gates, 0, 7), true);
assert.equal(production.legacyYearCandidateAllowed(gates, 0, 8), true);
assert.equal(production.legacyYearCandidateAllowed(gates, 0, 9), true);
assert.equal(production.legacyYearCandidateAllowed(gates, 0, 10), false);

const prepared = production.legacyStableLengthOnlyYearCandidates(gates, candidatePairs);
assert.deepEqual(prepared.map((candidate) => candidate.candidateLength), [5778n, 5779n, 5780n, 5781n]);
assert.deepEqual(prepared.map((candidate) => candidate.inputOrdinal), [2, 1, 3, 0]);

const route = production.discovery16LegacyYearCandidatesThroughMonsterPath(
  f,
  f,
  -1n,
  gates,
  candidatePairs,
  { first: 1n, directionStep: 1n }
);
assert.equal(route.context.currentHandler, 'Discovery16LegacyYearCandidateHandler');
assert.equal(route.context.previousHandler, 'NegativeGateQuestionPatchWrapper');
assert.equal(route.context.phase, 'DISCOVERY_16_LEGACY_YEAR_MAX_5781');
assert.equal(route.context.status, 'DISCOVERY_16_LEGACY_RESULT');
assert.equal(route.context.patch15Output, f - 1n);
assert.deepEqual(
  route.context.legacyYearCandidatePreSortFamily.map((candidate) => candidate.candidateLength),
  [5781n, 5779n, 5778n, 5780n]
);
assert.deepEqual(
  route.context.legacyYearCandidateSortedFamily.map((candidate) => candidate.candidateLength),
  [5778n, 5779n, 5780n, 5781n]
);
assert.deepEqual(route.context.legacyYearCandidateOverlongLengths, [5779n, 5780n, 5781n]);
assert.equal(route.context.legacyYearCandidateSelectionFamilySize, 4);
assert.equal(route.context.legacyYearCandidateSelectedOrdinal, 1n);
assert.equal(route.context.legacyYearCandidateSelected.candidateLength, 5778n);
assert.deepEqual(route.context.branchTrace.slice(-3), [
  'DISCOVERY_15_NEGATIVE_GATE_ASKS_POSITIVE_SIDE',
  'PATCH_15_NEGATIVE_GATE_SIGN_DETOUR',
  'DISCOVERY_16_LEGACY_YEAR_MAX_5781'
]);
assert.equal(route.context.metrics['discovery16.legacy5781Candidate.calls'], 1n);
assert.equal(route.context.metrics['discovery16.selectionReached.calls'], 1n);

const sortSource = production.legacyStableLengthOnlyYearCandidates.toString();
assert.match(sortSource, /candidateLength < right.candidateLength/);
assert.match(sortSource, /candidateLength > right.candidateLength/);
assert.doesNotMatch(sortSource, /openGate.*sort|opening|REAL_YEAR_MAX_PATCH/);
assert.equal('REAL_YEAR_MAX_PATCH' in production, false);

const normativeOverlong = route.context.legacyYearCandidateSortedFamily
  .filter((candidate) => candidate.candidateLength > normative.YEAR_MAX_DAYS)
  .map((candidate) => candidate.candidateLength);
console.log('DISCOVERY 16 DIAGNOSTIC: LEGACY_YEAR_MAX=5781 lassa candidates supra 5778 arrivar al familie de selection.');
console.log('legacy familie:   ' + route.context.legacyYearCandidateSortedFamily.map((candidate) => candidate.candidateLength).join(', '));
console.log('overlong legacy:  ' + normativeOverlong.join(', '));

assert.deepEqual(
  normativeOverlong,
  [],
  'DISCOVERY 16 EXPECTED RED: 5779, 5780 e 5781 ne deve arrivar al sort/selection normativ ante li filter de Patch 16.'
);
