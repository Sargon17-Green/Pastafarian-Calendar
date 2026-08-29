'use strict';

const assert = require('assert/strict');
const production = require('../src');
const normative = require('./normative-reference');

assert.equal(production.LEGACY_YEAR_MAX, 5781n);
assert.equal(production.REAL_YEAR_MAX_PATCH, 5778n);

const legacySource = production.legacyYearCandidateAllowed.toString();
assert.match(legacySource, /candidateLength <= LEGACY_YEAR_MAX/);
assert.doesNotMatch(legacySource, /REAL_YEAR_MAX_PATCH|5778n/);

const patchedSource = production.yearCandidateAfterFootnotePatch.toString();
assert.match(patchedSource, /legacyYearCandidateAllowed\(gates, openIndex, closeIndex\)/);
assert.match(patchedSource, /candidateLength > REAL_YEAR_MAX_PATCH/);
assert.ok(
  patchedSource.indexOf('legacyYearCandidateAllowed(gates, openIndex, closeIndex)') <
    patchedSource.indexOf('candidateLength > REAL_YEAR_MAX_PATCH'),
  'Li helper legacy deve esser vocat ante li footnote filter separat.'
);

const f = normative.FOUNDATION_DAY;
const boundary = { 0: f, 6: f + 252n, 7: f + 5778n, 8: f + 5779n, 9: f + 5780n, 10: f + 5781n, 11: f + 5782n };
assert.equal(production.yearCandidateAfterFootnotePatch(boundary, 0, 6), true);
assert.equal(production.yearCandidateAfterFootnotePatch(boundary, 0, 7), true);
assert.equal(production.yearCandidateAfterFootnotePatch(boundary, 0, 8), false);
assert.equal(production.yearCandidateAfterFootnotePatch(boundary, 0, 9), false);
assert.equal(production.yearCandidateAfterFootnotePatch(boundary, 0, 10), false);
assert.equal(production.yearCandidateAfterFootnotePatch(boundary, 0, 11), false);
assert.equal(production.legacyYearCandidateAllowed(boundary, 0, 10), true);

const gates = {
  0: f,
  6: f + 5778n,
  7: f + 5779n,
  8: f + 5780n,
  9: f + 5781n,
  20: f + 10n,
  26: f + 500n,
  30: f + 20n,
  36: f + 510n
};
const pairs = [
  { openIndex: 0, closeIndex: 9 },
  { openIndex: 0, closeIndex: 7 },
  { openIndex: 20, closeIndex: 26 },
  { openIndex: 0, closeIndex: 6 },
  { openIndex: 0, closeIndex: 8 },
  { openIndex: 30, closeIndex: 36 }
];

const legacyRaw = production.legacyYearCandidatesBeforeSort(gates, pairs);
assert.deepEqual(legacyRaw.map((candidate) => candidate.candidateLength), [5781n, 5779n, 490n, 5778n, 5780n, 490n]);

const filtered = production.yearCandidatesAfterFootnotePatchBeforeSort(gates, pairs);
assert.deepEqual(filtered.map((candidate) => candidate.candidateLength), [490n, 5778n, 490n]);
assert.deepEqual(filtered.map((candidate) => candidate.inputOrdinal), [2, 3, 5]);

const sorted = production.stableLengthOnlyPatchedYearCandidates(gates, pairs);
assert.deepEqual(sorted.map((candidate) => candidate.candidateLength), [490n, 490n, 5778n]);
assert.deepEqual(
  sorted.slice(0, 2).map((candidate) => candidate.inputOrdinal),
  [2, 5],
  'Patch 16 ne deve anticipar li tie repair de Patch 17; equal-length resta stabil secun input.'
);
assert.deepEqual(
  sorted.slice(0, 2).map((candidate) => candidate.openGate),
  [f + 10n, f + 20n]
);

const beforeSortSource = production.yearCandidatesAfterFootnotePatchBeforeSort.toString();
assert.doesNotMatch(beforeSortSource, /\.sort\(/);
const sortSource = production.stableLengthOnlyPatchedYearCandidates.toString();
assert.ok(
  sortSource.indexOf('yearCandidatesAfterFootnotePatchBeforeSort') < sortSource.indexOf('.sort('),
  'Li filter 5778 deve esser complet ante li sort.'
);
assert.match(sortSource, /candidateLength < right\.candidateLength/);
assert.match(sortSource, /candidateLength > right\.candidateLength/);
assert.doesNotMatch(sortSource, /openGate.*sort|sortEqualLengthRunsByOpeningGate|opening.*gate/i);

const routed = production.historicYearCandidatesThroughMonsterPath(
  f,
  f,
  -3n,
  gates,
  pairs,
  { first: 2n, directionStep: 1n }
);
assert.equal(routed.context.currentHandler, 'YearCandidateCeilingPatchWrapper');
assert.equal(routed.context.previousHandler, 'NegativeGateQuestionPatchWrapper');
assert.equal(routed.context.status, 'PATCH_16_RESULT');
assert.deepEqual(routed.context.patch16RejectedOverlongLengths, [5781n, 5779n, 5780n]);
assert.deepEqual(routed.context.patch16SortedFamily.map((candidate) => candidate.candidateLength), [490n, 490n, 5778n]);
assert.equal(routed.context.patch16SelectionFamilySize, 3);
assert.equal(routed.context.patch16SelectedOrdinal, 2n);
assert.equal(routed.context.patch16Selected.inputOrdinal, 5);
assert.equal(routed.context.patch16Selected.candidateLength, 490n);
assert.equal(routed.context.metrics['patch16.realYearCeiling.calls'], 1n);
assert.equal(routed.context.metrics['patch16.overlongRejected.beforeSort'], 3n);
assert.equal(routed.context.metrics['discovery16.selectionReached.calls'], undefined);

const wrapperSource = production.YearCandidateCeilingPatchWrapper.prototype.repair.toString();
assert.match(wrapperSource, /legacyYearCandidatesBeforeSort\(gates, candidatePairs\)/);
assert.match(wrapperSource, /yearCandidatesAfterFootnotePatchBeforeSort\(gates, candidatePairs\)/);
assert.match(wrapperSource, /stableLengthOnlyPatchedYearCandidates\(gates, candidatePairs\)/);
assert.ok(
  wrapperSource.indexOf('yearCandidatesAfterFootnotePatchBeforeSort(gates, candidatePairs)') <
    wrapperSource.indexOf('stableLengthOnlyPatchedYearCandidates(gates, candidatePairs)'),
  'Li familia filtrat ante sort deve esser materialisat ante li sort semantic.'
);
assert.ok(
  wrapperSource.indexOf('stableLengthOnlyPatchedYearCandidates(gates, candidatePairs)') <
    wrapperSource.indexOf('this.legacyAdapter.select(sorted, selectionStream)'),
  'Li sort del familie ja filtrat deve preceder selection.'
);
assert.doesNotMatch(wrapperSource, /Discovery16LegacyYearCandidateHandler|legacyStableLengthOnlyYearCandidates/);

const legacyRoute = production.discovery16LegacyYearCandidatesThroughMonsterPath(
  f, f, -3n, gates, pairs, { first: 2n, directionStep: 1n }
);
assert.deepEqual(legacyRoute.context.legacyYearCandidateOverlongLengths, [5779n, 5780n, 5781n]);
assert.equal(legacyRoute.context.legacyYearCandidateSelectionFamilySize, 6);
assert.notDeepEqual(
  legacyRoute.context.legacyYearCandidateSortedFamily.map((candidate) => candidate.candidateLength),
  routed.context.patch16SortedFamily.map((candidate) => candidate.candidateLength)
);

console.log('PATCH 16: PASS — LEGACY_YEAR_MAX=5781 resta intact; REAL_YEAR_MAX_PATCH=5778 filtra ante sort e selection, sin tie repair futur.');
