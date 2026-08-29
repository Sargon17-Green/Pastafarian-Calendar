'use strict';

const assert = require('assert/strict');
const production = require('../src');
const normative = require('./normative-reference');

assert.equal(typeof production.filteredCutletCompositions, 'function');
assert.equal(typeof production.CutletPartitionPatchWrapper, 'function');
assert.equal(typeof production.RepeatedNamePatchWrapper, 'function');
assert.equal(typeof production.partialPermutationUnrank, 'function');
assert.equal(typeof production.VirtualLegacyList, 'function');

const legacySource = production.legacyPositiveCompositions.toString();
assert.doesNotMatch(legacySource, /internalGate|internal_gate|prefix|boundary|required/);
const legacyAdapterSource = production.LegacyCutletPartitionAdapter.prototype.selectAllPositive.toString();
assert.doesNotMatch(legacyAdapterSource, /filteredCutletCompositions|CutletPartitionPatchWrapper/);
const discoverySource = production.Discovery21CutletPartitionHandler.prototype.handle.toString();
assert.doesNotMatch(discoverySource, /filteredCutletCompositions|CutletPartitionPatchWrapper/);
const wrapperSource = production.CutletPartitionPatchWrapper.prototype.repair.toString();
assert.match(wrapperSource, /filteredCutletCompositions/);
assert.match(wrapperSource, /patch21LegacyDiagnosticPreserved/);

function prefixes(parts) {
  let sum = 0;
  return parts.map((part) => (sum += part));
}

for (const [gapCount, cutletCount, offset] of [
  [5, 3, 2], [6, 3, 4], [7, 4, 3], [8, 5, 6], [10, 8, 4]
]) {
  const legacy = production.legacyPositiveCompositions(gapCount, cutletCount);
  const expected = [];
  for (let rank = 1n; rank <= legacy.count(); rank += 1n) {
    const candidate = legacy.unrank1(rank);
    if (prefixes(candidate).includes(offset)) expected.push(candidate);
  }
  const filtered = production.filteredCutletCompositions(gapCount, cutletCount, offset);
  assert.equal(filtered.count(), BigInt(expected.length));
  assert.deepEqual(
    expected.map((_, index) => filtered.unrank1(BigInt(index + 1))),
    expected
  );
}
assert.throws(() => production.filteredCutletCompositions(10, 8, 0), RangeError);
assert.throws(() => production.filteredCutletCompositions(10, 8, 10), RangeError);
assert.throws(() => production.filteredCutletCompositions(4, 5, 2), RangeError);

const witnessFamily = production.filteredCutletCompositions(10, 8, 4);
assert.equal(witnessFamily.count(), 28n);
assert.deepEqual(witnessFamily.unrank1(3n), [1, 1, 1, 1, 1, 1, 3, 1]);
assert.throws(() => witnessFamily.unrank1(0n), RangeError);
assert.throws(() => witnessFamily.unrank1(29n), RangeError);

const f = normative.FOUNDATION_DAY;
const calculationDay = f + 100n;
const originalTargetDay = calculationDay;
const candidatePairs = [
  { openIndex: 50, closeIndex: 60 },
  { openIndex: 10, closeIndex: 20 },
  { openIndex: 30, closeIndex: 40 }
];
const selectionStream = { first: 1n, directionStep: 1n };
const noWalkExpected = {
  nextYear() { throw new Error('Patch 21 ne deve caminar avante ex Year 5000 in ti witness.'); },
  previousYear() { throw new Error('Patch 21 ne deve caminar retro ex Year 5000 in ti witness.'); }
};

const gatesWithInternal = {
  10: f + 10n,
  14: calculationDay,
  20: f + 1010n,
  30: f + 20n,
  40: f + 1020n,
  50: f + 30n,
  60: f + 1030n
};
const routed = production.historicCutletPartitionThroughMonsterPath(
  new production.BaseMonsterManager(),
  calculationDay,
  originalTargetDay,
  -1n,
  gatesWithInternal,
  candidatePairs,
  selectionStream,
  noWalkExpected
);
assert.equal(routed.context.status, 'PATCH_21_RESULT');
assert.equal(routed.result.filteredFamilyUsed, true);
assert.equal(routed.result.rawLegacyPassedThrough, false);
assert.equal(routed.result.internalGateOffset, 4);
assert.equal(routed.result.familyCount, 28n);
assert.equal(routed.result.selectedRank, 3n);
assert.deepEqual(routed.result.partition, [1, 1, 1, 1, 1, 1, 3, 1]);
assert.deepEqual(routed.result.legacyDiagnostic.partition, [1, 1, 1, 3, 1, 1, 1, 1]);
assert.equal(routed.result.legacyDiagnostic.familyCount, 36n);
assert.equal(routed.result.legacyDiagnostic.selectedRank, 15n);
assert.equal(routed.result.legacyDiagnostic.internalBoundaryHit, false);
assert.equal(routed.result.internalBoundaryHit, true);

const gatesWithoutInternal = {
  10: f + 10n,
  14: f + 14n,
  20: f + 1010n,
  30: f + 20n,
  40: f + 1020n,
  50: f + 30n,
  60: f + 1030n
};
const passThrough = production.historicCutletPartitionThroughMonsterPath(
  new production.BaseMonsterManager(),
  calculationDay,
  originalTargetDay,
  -1n,
  gatesWithoutInternal,
  candidatePairs,
  selectionStream,
  noWalkExpected
);
assert.equal(passThrough.context.status, 'PATCH_21_RESULT');
assert.equal(passThrough.result.internalGateOffset, null);
assert.equal(passThrough.result.filteredFamilyUsed, false);
assert.equal(passThrough.result.rawLegacyPassedThrough, true);
assert.equal(passThrough.context.patch21FilteredFamilyUsed, false);
assert.equal(passThrough.context.patch21RawLegacyPassedThrough, true);
assert.equal(passThrough.context.metrics['patch21.filteredFamily.calls'], undefined);
assert.equal(passThrough.context.metrics['patch21.rawLegacyPassThrough.calls'], 1n);
assert.equal(passThrough.result.familyCount, passThrough.result.legacyDiagnostic.familyCount);
assert.equal(passThrough.result.selectedRank, passThrough.result.legacyDiagnostic.selectedRank);
assert.deepEqual(passThrough.result.partition, passThrough.result.legacyDiagnostic.partition);
assert.deepEqual(passThrough.result.prefixSums, passThrough.result.legacyDiagnostic.prefixSums);
assert.equal(passThrough.context.patch21SelectionChangedFromLegacy, false);

console.log('PATCH 21: PASS — li scar legacy es executet e conservat quam diagnostic; un gate intern usa exactmen li subsequence filtrat lexicografic, e sin gate intern li partition raw passa intact.');
