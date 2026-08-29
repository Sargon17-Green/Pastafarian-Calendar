'use strict';

const assert = require('assert/strict');
const production = require('../src');
const normative = require('./normative-reference');

assert.equal(typeof production.VirtualLegacyList, 'function');
assert.equal(typeof production.MonthLengthVirtualPatchWrapper, 'function');
assert.equal(typeof production.historicMonthLengthVirtualListThroughMonsterPath, 'function');
assert.equal(typeof production.legacyChooseEachDaySeparately, 'function');
assert.equal('DPUnrankLegalWeaving' in production, false);
assert.equal('oldContiguousMonthDayGuess' in production, false);

const legacyMaterializerSource = production.legacyMaterializeMonthLengthWays.toString();
const legacyApiSource = production.LegacyMonthLengthAllWaysAPI.prototype.allWays.toString();
const discoverySource = production.Discovery23MonthLengthMaterializationHandler.prototype.handle.toString();
assert.doesNotMatch(legacyMaterializerSource, /VirtualLegacyList|itemAt1|_buildExactCountTable/);
assert.doesNotMatch(legacyApiSource, /VirtualLegacyList|itemAt1|_buildExactCountTable/);
assert.doesNotMatch(discoverySource, /VirtualLegacyList|MonthLengthVirtualPatchWrapper|itemAt1/);
const patchSource = production.MonthLengthVirtualPatchWrapper.prototype.repair.toString();
assert.match(patchSource, /VirtualLegacyList/);
assert.match(patchSource, /legacyMonthLengthMaterializerExecuted/);

const tiny = new production.VirtualLegacyList(13, 3);
assert.equal(tiny.count(), 3n);
assert.deepEqual([1n,2n,3n].map((rank) => tiny.itemAt1(rank)), [[4,4,5],[4,5,4],[5,4,4]]);
assert.deepEqual(production.legacyMaterializeMonthLengthWays(13, 3), [
  tiny.itemAt1(1n), tiny.itemAt1(2n), tiny.itemAt1(3n)
]);
assert.throws(() => new production.VirtualLegacyList(0, 3), RangeError);
assert.throws(() => new production.VirtualLegacyList(13, 0), RangeError);
assert.throws(() => tiny.itemAt1(0n), RangeError);
assert.throws(() => tiny.itemAt1(4n), RangeError);

let comparedFamilies = 0;
let comparedMembers = 0;
for (let monthCount = 1; monthCount <= 5; monthCount += 1) {
  const minTotal = monthCount * 4;
  const maxSmallTotal = Math.min(monthCount * 10, minTotal + 8);
  for (let totalDays = minTotal; totalDays <= maxSmallTotal; totalDays += 1) {
    const concrete = production.legacyMaterializeMonthLengthWays(totalDays, monthCount);
    const virtual = new production.VirtualLegacyList(totalDays, monthCount);
    assert.equal(virtual.count(), BigInt(concrete.length));
    for (let index = 0; index < concrete.length; index += 1) {
      assert.deepEqual(virtual.itemAt1(BigInt(index + 1)), concrete[index]);
      comparedMembers += 1;
    }
    comparedFamilies += 1;
  }
}
assert.equal(comparedFamilies, 43);
assert.ok(comparedMembers > 100);

const huge = new production.VirtualLegacyList(1000, 16);
assert.equal(huge.count(), 5239332298078798668173613753510n);
assert.equal(Array.isArray(huge), false);
assert.equal('ways' in huge, false);
assert.deepEqual(huge.itemAt1(1n), [4,4,4,4,4,4,4,4,107,123,123,123,123,123,123,123]);
assert.deepEqual(huge.itemAt1(huge.count()), [123,123,123,123,123,123,123,107,4,4,4,4,4,4,4,4]);
assert.deepEqual(
  huge.itemAt1(1892970349028658514214546085756n),
  [46,62,31,19,31,123,10,47,108,96,7,97,113,29,74,107]
);

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
  nextYear() { throw new Error('Patch 23 ne deve caminar avante ex Year 5000 in ti witness.'); },
  previousYear() { throw new Error('Patch 23 ne deve caminar retro ex Year 5000 in ti witness.'); }
};

const legacy = production.discovery23LegacyMonthLengthMaterializationThroughMonsterPath(
  new production.BaseMonsterManager(), calculationDay, calculationDay, -1n,
  gates, candidatePairs, selectionStream, noWalkExpected
);
const patched = production.historicMonthLengthVirtualListThroughMonsterPath(
  new production.BaseMonsterManager(), calculationDay, calculationDay, -1n,
  gates, candidatePairs, selectionStream, noWalkExpected
);
const sauce = normative.sauce(calculationDay, f + 11n);
const expected = normative.chooseMonthLengths(
  sauce, { openGateDay: f + 10n, closeGateDay: f + 1010n }, 16
);

assert.equal(legacy.result.apiContract, 'ALL_WAYS_CONCRETE_ARRAY');
assert.equal(legacy.result.probeSampleCount, 2048);
assert.equal(legacy.result.probeExceededLimit, true);
assert.equal(patched.result.apiContract, 'VIRTUAL_EXACT_COUNT_LEXICOGRAPHIC_UNRANK');
assert.equal(patched.context.previousHandler, 'Discovery23MonthLengthMaterializationHandler');
assert.equal(patched.context.patch23LegacyMaterializerExecuted, true);
assert.equal(patched.context.patch23LegacyApiContractDiagnostic, 'ALL_WAYS_CONCRETE_ARRAY');
assert.equal(patched.result.familyCount, 5239332298078798668173613753510n);
assert.equal(patched.result.selectedRank, 1892970349028658514214546085756n);
assert.deepEqual(patched.result.monthLengths, expected);
assert.deepEqual(patched.result.allWays.itemAt1(patched.result.selectedRank), expected);
assert.equal(patched.context.metrics['discovery23.monthLengthConcreteApi.calls'], 1n);
assert.equal(patched.context.metrics['discovery23.monthLengthProbe.calls'], 1n);
assert.equal(patched.context.metrics['patch23.legacyConcreteDiagnosticPreserved.calls'], 1n);
assert.equal(patched.context.metrics['patch23.virtualExactCount.calls'], 1n);
assert.equal(patched.context.metrics['patch23.virtualLexicographicItemAt1.calls'], 1n);
assert.deepEqual(patched.context.branchTrace.slice(-6), [
  'DISCOVERY_21_ALL_POSITIVE_CUTLET_PARTITION',
  'PATCH_21_FILTERED_INTERNAL_GATE_CUTLET_PARTITION',
  'DISCOVERY_22_LEGACY_REPEATED_CUTLET_NAMES',
  'PATCH_22_DISTINCT_PARTIAL_PERMUTATION_NAMES',
  'DISCOVERY_23_LEGACY_CONCRETE_MONTH_LENGTH_ALL_WAYS',
  'PATCH_23_VIRTUAL_MONTH_LENGTH_ALL_WAYS'
]);

const second = production.historicMonthLengthVirtualListThroughMonsterPath(
  new production.BaseMonsterManager(), calculationDay, calculationDay, -1n,
  gates, candidatePairs, selectionStream, noWalkExpected
);
assert.notStrictEqual(second.context, patched.context);
assert.notStrictEqual(second.result.allWays, patched.result.allWays);
assert.equal(second.result.familyCount, patched.result.familyCount);
assert.equal(second.result.selectedRank, patched.result.selectedRank);
assert.deepEqual(second.result.monthLengths, patched.result.monthLengths);
assert.equal(second.context.metrics['patch23.virtualExactCount.calls'], 1n);

console.log('PATCH 23: PASS — li concrete scar resta executet diagnosticmen; VirtualLegacyList furni count exact e itemAt1 lexicografic sin materialisar li familie complet. Families audit: ' + comparedFamilies + '; membres audit: ' + comparedMembers + '.');
