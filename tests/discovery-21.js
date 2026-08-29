'use strict';

const assert = require('assert/strict');
const production = require('../src');
const normative = require('./normative-reference');

const legacyFamilySource = production.legacyPositiveCompositions.toString();
assert.match(legacyFamilySource, /positiveCompositionCountExact/);
assert.doesNotMatch(legacyFamilySource, /internalGate|internal_gate|prefix|boundary|required/);
assert.equal(typeof production.CutletPartitionPatchWrapper, 'function');
assert.equal(typeof production.filteredCutletCompositions, 'function');
assert.equal('RepeatedNamePatchWrapper' in production, false);
assert.equal('partialPermutationUnrank' in production, false);

const small = production.legacyPositiveCompositions(5, 3);
assert.equal(small.count(), 6n);
assert.deepEqual(
  [1n, 2n, 3n, 4n, 5n, 6n].map((rank) => small.unrank1(rank)),
  [
    [1, 1, 3],
    [1, 2, 2],
    [1, 3, 1],
    [2, 1, 2],
    [2, 2, 1],
    [3, 1, 1]
  ]
);
assert.throws(() => production.legacyPositiveCompositions(4, 5), RangeError);
assert.throws(() => small.unrank1(0n), RangeError);
assert.throws(() => small.unrank1(7n), RangeError);

const f = normative.FOUNDATION_DAY;
const calculationDay = f + 100n;
const originalTargetDay = calculationDay;
const gates = {
  10: f + 10n,
  14: calculationDay,
  20: f + 1010n,
  30: f + 20n,
  40: f + 1020n,
  50: f + 30n,
  60: f + 1030n
};
const candidatePairs = [
  { openIndex: 50, closeIndex: 60 },
  { openIndex: 10, closeIndex: 20 },
  { openIndex: 30, closeIndex: 40 }
];
const selectionStream = { first: 1n, directionStep: 1n };
const noWalkExpected = {
  nextYear() { throw new Error('Discovery 21 ne deve caminar avante ex Year 5000 in ti witness.'); },
  previousYear() { throw new Error('Discovery 21 ne deve caminar retro ex Year 5000 in ti witness.'); }
};

const legacyManager = new production.BaseMonsterManager();
const legacyRouted = production.discovery21LegacyCutletPartitionThroughMonsterPath(
  legacyManager,
  calculationDay,
  originalTargetDay,
  -1n,
  gates,
  candidatePairs,
  selectionStream,
  noWalkExpected
);

assert.equal(legacyRouted.context.currentHandler, 'Discovery21CutletPartitionHandler');
assert.equal(legacyRouted.context.previousHandler, 'StructureSaucePatchWrapper');
assert.equal(legacyRouted.context.phase, 'DISCOVERY_21_ALL_POSITIVE_CUTLET_PARTITION');
assert.equal(legacyRouted.context.status, 'DISCOVERY_21_LEGACY_RESULT');
assert.equal(legacyRouted.context.patch20SelectorUsedYearFirstDaySauce, true);
assert.equal(legacyRouted.context.legacyCutletGapCount, 10);
assert.deepEqual(legacyRouted.context.legacyCutletCountCandidates, [6, 7, 8, 9, 10]);
assert.equal(legacyRouted.context.legacyCutletCountSelectedOrdinal, 3n);
assert.equal(legacyRouted.context.legacyCutletCount, 8);
assert.equal(legacyRouted.context.legacyCutletInternalGateIndex, 14);
assert.equal(legacyRouted.context.legacyCutletInternalGateOffset, 4);
assert.equal(legacyRouted.context.legacyCutletFamilyCount, 36n);
assert.equal(legacyRouted.context.legacyCutletSelectedRank, 15n);
assert.deepEqual(legacyRouted.context.legacyCutletSelectedPartition, [1, 1, 1, 3, 1, 1, 1, 1]);
assert.deepEqual(legacyRouted.context.legacyCutletPrefixSums, [1, 2, 3, 6, 7, 8, 9, 10]);
assert.equal(legacyRouted.context.legacyCutletInternalBoundaryHit, false);
assert.equal(legacyRouted.context.legacyCutletIgnoredInternalGate, true);
assert.equal(legacyRouted.context.metrics['discovery21.allPositiveFamily.calls'], 1n);
assert.equal(legacyRouted.context.metrics['discovery21.cutletCountSelection.calls'], 1n);
assert.equal(legacyRouted.context.metrics['discovery21.partitionSelection.calls'], 1n);
assert.equal(legacyRouted.context.metrics['discovery21.internalGateIgnored.calls'], 1n);
assert.deepEqual(legacyRouted.context.branchTrace.slice(-3), [
  'PATCH_19_ACTION_AND_GATE_GUARDS',
  'PATCH_20_STRUCTURE_SAUCE_YEAR_FIRST_DAY_GHOST',
  'DISCOVERY_21_ALL_POSITIVE_CUTLET_PARTITION'
]);

const yearFirstDay = f + 11n;
const authoritativeSauce = normative.sauce(calculationDay, yearFirstDay);
const cutletCountCandidates = [6, 7, 8, 9, 10];
const expectedCutletCountRank = normative.chooseRank(
  normative.askBowl(authoritativeSauce, 2, 20n),
  BigInt(cutletCountCandidates.length)
);
const expectedCutletCount = cutletCountCandidates[Number(expectedCutletCountRank - 1n)];
assert.equal(expectedCutletCount, 8);

const filteredFamily = normative.makeCutletPartitionFamily(10, expectedCutletCount, 4);
const expectedPartitionRank = normative.chooseRank(
  normative.askBowl(authoritativeSauce, 2, 21n),
  filteredFamily.count()
);
const expectedPartition = filteredFamily.unrank1(expectedPartitionRank);
assert.equal(filteredFamily.count(), 28n);
assert.equal(expectedPartitionRank, 3n);
assert.deepEqual(expectedPartition, [1, 1, 1, 1, 1, 1, 3, 1]);
let expectedCumulative = 0;
assert.ok(expectedPartition.some((part) => {
  expectedCumulative += part;
  return expectedCumulative === 4;
}));
assert.notDeepEqual(legacyRouted.result.partition, expectedPartition);

const patchedManager = new production.BaseMonsterManager();
const patchedRouted = production.historicCutletPartitionThroughMonsterPath(
  patchedManager,
  calculationDay,
  originalTargetDay,
  -1n,
  gates,
  candidatePairs,
  selectionStream,
  noWalkExpected
);
assert.equal(patchedRouted.context.status, 'PATCH_21_RESULT');
assert.equal(patchedRouted.context.currentHandler, 'CutletPartitionPatchWrapper');
assert.equal(patchedRouted.context.previousHandler, 'Discovery21CutletPartitionHandler');
assert.equal(patchedRouted.context.patch21LegacyDiagnosticPreserved, true);
assert.equal(patchedRouted.context.patch21FilteredFamilyUsed, true);
assert.equal(patchedRouted.context.patch21RawLegacyPassedThrough, false);
assert.equal(patchedRouted.context.patch21LegacyFamilyCountDiagnostic, 36n);
assert.equal(patchedRouted.context.patch21LegacySelectedRankDiagnostic, 15n);
assert.deepEqual(patchedRouted.context.patch21LegacyPartitionDiagnostic, legacyRouted.result.partition);
assert.deepEqual(patchedRouted.context.patch21LegacyPrefixSumsDiagnostic, legacyRouted.result.prefixSums);
assert.equal(patchedRouted.context.patch21LegacyBoundaryHitDiagnostic, false);
assert.equal(patchedRouted.result.familyCount, 28n);
assert.equal(patchedRouted.result.selectedRank, 3n);
assert.deepEqual(patchedRouted.result.partition, expectedPartition);
assert.deepEqual(patchedRouted.result.prefixSums, [1, 2, 3, 4, 5, 6, 9, 10]);
assert.equal(patchedRouted.result.internalBoundaryHit, true);
assert.equal(patchedRouted.context.patch21SelectionChangedFromLegacy, true);
assert.equal(patchedRouted.context.metrics['patch21.filteredFamily.calls'], 1n);
assert.equal(patchedRouted.context.metrics['patch21.legacyDiagnosticPreserved.calls'], 1n);
assert.equal(patchedRouted.context.metrics['patch21.semanticPartitionSelection.calls'], 1n);
assert.deepEqual(patchedRouted.context.branchTrace.slice(-4), [
  'PATCH_19_ACTION_AND_GATE_GUARDS',
  'PATCH_20_STRUCTURE_SAUCE_YEAR_FIRST_DAY_GHOST',
  'DISCOVERY_21_ALL_POSITIVE_CUTLET_PARTITION',
  'PATCH_21_FILTERED_INTERNAL_GATE_CUTLET_PARTITION'
]);

console.log('DISCOVERY 21: PASS pos Patch 21 — li scar all-positive resta real e diagnosticmen divergente, ma li route semantic usa li subsequence filtrat lexicografic.');
