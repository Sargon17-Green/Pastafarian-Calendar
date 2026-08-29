'use strict';

const assert = require('assert/strict');
const production = require('../src');
const normative = require('./normative-reference');

const legacyFamilySource = production.legacyPositiveCompositions.toString();
assert.match(legacyFamilySource, /positiveCompositionCountExact/);
assert.doesNotMatch(legacyFamilySource, /internalGate|internal_gate|prefix|boundary|required/);
assert.equal('CutletPartitionPatchWrapper' in production, false);
assert.equal('legacyNameRowWithRepeats' in production, false);

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

const manager = new production.BaseMonsterManager();
const routed = production.discovery21LegacyCutletPartitionThroughMonsterPath(
  manager,
  calculationDay,
  originalTargetDay,
  -1n,
  gates,
  candidatePairs,
  selectionStream,
  noWalkExpected
);

assert.equal(routed.context.currentHandler, 'Discovery21CutletPartitionHandler');
assert.equal(routed.context.previousHandler, 'StructureSaucePatchWrapper');
assert.equal(routed.context.phase, 'DISCOVERY_21_ALL_POSITIVE_CUTLET_PARTITION');
assert.equal(routed.context.status, 'DISCOVERY_21_LEGACY_RESULT');
assert.equal(routed.context.patch20SelectorUsedYearFirstDaySauce, true);
assert.equal(routed.context.legacyCutletGapCount, 10);
assert.deepEqual(routed.context.legacyCutletCountCandidates, [6, 7, 8, 9, 10]);
assert.equal(routed.context.legacyCutletCountSelectedOrdinal, 3n);
assert.equal(routed.context.legacyCutletCount, 8);
assert.equal(routed.context.legacyCutletInternalGateIndex, 14);
assert.equal(routed.context.legacyCutletInternalGateOffset, 4);
assert.equal(routed.context.legacyCutletFamilyCount, 36n);
assert.equal(routed.context.legacyCutletSelectedRank, 15n);
assert.deepEqual(routed.context.legacyCutletSelectedPartition, [1, 1, 1, 3, 1, 1, 1, 1]);
assert.deepEqual(routed.context.legacyCutletPrefixSums, [1, 2, 3, 6, 7, 8, 9, 10]);
assert.equal(routed.context.legacyCutletInternalBoundaryHit, false);
assert.equal(routed.context.legacyCutletIgnoredInternalGate, true);
assert.equal(routed.context.metrics['discovery21.allPositiveFamily.calls'], 1n);
assert.equal(routed.context.metrics['discovery21.cutletCountSelection.calls'], 1n);
assert.equal(routed.context.metrics['discovery21.partitionSelection.calls'], 1n);
assert.equal(routed.context.metrics['discovery21.internalGateIgnored.calls'], 1n);
assert.deepEqual(routed.context.branchTrace.slice(-3), [
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

console.log('DISCOVERY 21 DIAGNOSTIC: li familie legacy usa omni positive compositions e ignora li gate intern del calculation-day.');
console.log('gap/count/offset: ' + [routed.result.gapCount, routed.result.cutletCount, routed.result.internalGateOffset].join(', '));
console.log('legacy rank/family: ' + routed.result.selectedRank + '/' + routed.result.familyCount);
console.log('legacy partition:   ' + routed.result.partition.join(', '));
console.log('legacy prefixes:    ' + routed.result.prefixSums.join(', '));
console.log('normativ partition: ' + expectedPartition.join(', '));

assert.deepEqual(
  routed.result.partition,
  expectedPartition,
  'DISCOVERY 21 EXPECTED RED: un cutlet partition con calculation-day quam gate intern deve haver un prefix sum egal al offset de ti gate.'
);
