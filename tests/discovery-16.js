'use strict';

const assert = require('assert/strict');
const production = require('../src');
const normative = require('./normative-reference');

assert.equal(production.LEGACY_YEAR_MAX, 5781n);
assert.equal(production.REAL_YEAR_MAX_PATCH, 5778n);

const boundaryGates = { 0: 0n, 5: 252n, 6: 252n, 7: 251n, 8: 5781n, 9: 5782n };
assert.equal(production.legacyYearCandidateAllowed(boundaryGates, 0, 5), false);
assert.equal(production.legacyYearCandidateAllowed(boundaryGates, 0, 6), true);
assert.equal(production.legacyYearCandidateAllowed(boundaryGates, 0, 7), false);
assert.equal(production.legacyYearCandidateAllowed(boundaryGates, 0, 8), true);
assert.equal(production.legacyYearCandidateAllowed(boundaryGates, 0, 9), false);
const legacySource = production.legacyYearCandidateAllowed.toString();
assert.match(legacySource, /candidateLength <= LEGACY_YEAR_MAX/);
assert.doesNotMatch(legacySource, /REAL_YEAR_MAX_PATCH|candidateLength > 5778n/);

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

const legacyPrepared = production.legacyStableLengthOnlyYearCandidates(gates, candidatePairs);
assert.deepEqual(legacyPrepared.map((candidate) => candidate.candidateLength), [5778n, 5779n, 5780n, 5781n]);
assert.deepEqual(legacyPrepared.map((candidate) => candidate.inputOrdinal), [2, 1, 3, 0]);

const legacyRoute = production.discovery16LegacyYearCandidatesThroughMonsterPath(
  f,
  f,
  -1n,
  gates,
  candidatePairs,
  { first: 1n, directionStep: 1n }
);
assert.equal(legacyRoute.context.currentHandler, 'Discovery16LegacyYearCandidateHandler');
assert.equal(legacyRoute.context.status, 'DISCOVERY_16_LEGACY_RESULT');
assert.deepEqual(legacyRoute.context.legacyYearCandidateOverlongLengths, [5779n, 5780n, 5781n]);
assert.equal(legacyRoute.context.legacyYearCandidateSelectionFamilySize, 4);

const routed = production.historicYearCandidatesThroughMonsterPath(
  f,
  f,
  -1n,
  gates,
  candidatePairs,
  { first: 1n, directionStep: 1n }
);
assert.equal(routed.context.currentHandler, 'YearCandidateCeilingPatchWrapper');
assert.equal(routed.context.previousHandler, 'NegativeGateQuestionPatchWrapper');
assert.equal(routed.context.phase, 'PATCH_16_REAL_YEAR_MAX_5778_BEFORE_SORT');
assert.equal(routed.context.status, 'PATCH_16_RESULT');
assert.equal(routed.context.patch15Output, f - 1n);
assert.equal(routed.context.patch16LegacyCallsPreserved, true);
assert.deepEqual(
  routed.context.patch16LegacyPreSortFamily.map((candidate) => candidate.candidateLength),
  [5781n, 5779n, 5778n, 5780n]
);
assert.deepEqual(routed.context.patch16RejectedOverlongLengths, [5781n, 5779n, 5780n]);
assert.deepEqual(
  routed.context.patch16FilteredPreSortFamily.map((candidate) => candidate.candidateLength),
  [5778n]
);
assert.deepEqual(
  routed.context.patch16SortedFamily.map((candidate) => candidate.candidateLength),
  [5778n]
);
assert.equal(routed.context.patch16SelectionFamilySize, 1);
assert.equal(routed.context.patch16SelectedOrdinal, 1n);
assert.equal(routed.context.patch16Selected.candidateLength, 5778n);
assert.deepEqual(routed.context.branchTrace.slice(-3), [
  'DISCOVERY_15_NEGATIVE_GATE_ASKS_POSITIVE_SIDE',
  'PATCH_15_NEGATIVE_GATE_SIGN_DETOUR',
  'PATCH_16_REAL_YEAR_MAX_5778_BEFORE_SORT'
]);
assert.equal(routed.context.metrics['patch16.realYearCeiling.calls'], 1n);
assert.equal(routed.context.metrics['patch16.overlongRejected.beforeSort'], 3n);
assert.equal(routed.context.metrics['discovery16.selectionReached.calls'], undefined);

const normativeOverlong = routed.context.patch16SortedFamily
  .filter((candidate) => candidate.candidateLength > normative.YEAR_MAX_DAYS)
  .map((candidate) => candidate.candidateLength);
assert.deepEqual(normativeOverlong, []);

console.log('DISCOVERY 16 REGRESSION: PASS — li scar 5781 resta demonstrabil, ma Patch 16 rejecte 5779..5781 ante sort e selection semantic.');
