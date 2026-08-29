'use strict';

const assert = require('assert/strict');
const production = require('../src');
const normative = require('./normative-reference');

assert.equal(typeof production.legacyMaterializeMonthLengthWays, 'function');
assert.equal(typeof production.LegacyMonthLengthAllWaysAPI, 'function');
assert.equal(typeof production.Discovery23MonthLengthMaterializationHandler, 'function');
assert.equal(typeof production.discovery23LegacyMonthLengthMaterializationThroughMonsterPath, 'function');
assert.equal(typeof production.VirtualLegacyList, 'function');
assert.equal(typeof production.MonthLengthVirtualPatchWrapper, 'function');
assert.equal(typeof production.historicMonthLengthVirtualListThroughMonsterPath, 'function');
assert.equal(typeof production.legacyChooseEachDaySeparately, 'function');
assert.equal(typeof production.DPUnrankLegalWeaving, 'function');
assert.equal('oldContiguousMonthDayGuess' in production, false);

const legacySource = production.legacyMaterializeMonthLengthWays.toString();
const legacyApiSource = production.LegacyMonthLengthAllWaysAPI.prototype.allWays.toString();
const discoverySource = production.Discovery23MonthLengthMaterializationHandler.prototype.handle.toString();
assert.doesNotMatch(legacySource, /VirtualLegacyList|itemAt1|_buildExactCountTable/i);
assert.doesNotMatch(legacyApiSource, /VirtualLegacyList|itemAt1|_buildExactCountTable/i);
assert.doesNotMatch(discoverySource, /VirtualLegacyList|itemAt1|DPUnrank|legacyChooseEachDaySeparately/);

assert.deepEqual(production.legacyMaterializeMonthLengthWays(12, 3), [[4,4,4]]);
assert.deepEqual(production.legacyMaterializeMonthLengthWays(13, 3), [[4,4,5],[4,5,4],[5,4,4]]);
assert.deepEqual(production.legacyMaterializeMonthLengthWays(11, 3), []);
assert.deepEqual(production.legacyMaterializeMonthLengthWays(370, 3), []);
assert.throws(() => production.legacyMaterializeMonthLengthWays(0, 3), RangeError);
assert.throws(() => production.legacyMaterializeMonthLengthWays(12, 0), RangeError);

const concreteApi = new production.LegacyMonthLengthAllWaysAPI();
const tinyAllWays = concreteApi.allWays(14, 3);
assert.ok(Array.isArray(tinyAllWays));
assert.deepEqual(tinyAllWays, [[4,4,6],[4,5,5],[4,6,4],[5,4,5],[5,5,4],[6,4,4]]);

const f = normative.FOUNDATION_DAY;
const calculationDay = f + 102n;
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
  nextYear() { throw new Error('Patch 23 ne deve caminar avante ex Year 5000 in ti witness.'); },
  previousYear() { throw new Error('Patch 23 ne deve caminar retro ex Year 5000 in ti witness.'); }
};

const legacyRouted = production.discovery23LegacyMonthLengthMaterializationThroughMonsterPath(
  new production.BaseMonsterManager(),
  calculationDay,
  calculationDay,
  -1n,
  gates,
  candidatePairs,
  selectionStream,
  noWalkExpected
);

assert.equal(legacyRouted.context.status, 'DISCOVERY_23_LEGACY_RESULT');
assert.equal(legacyRouted.context.currentHandler, 'Discovery23MonthLengthMaterializationHandler');
assert.equal(legacyRouted.context.previousHandler, 'RepeatedNamePatchWrapper');
assert.equal(legacyRouted.context.phase, 'DISCOVERY_23_LEGACY_CONCRETE_MONTH_LENGTH_ALL_WAYS');
assert.equal(legacyRouted.context.patch22BadEqualsCorrect, false);
assert.deepEqual(legacyRouted.context.patch22SemanticNameIndices, [3,11,4,9,12,5]);
assert.equal(legacyRouted.result.yearLength, 1000n);
assert.equal(legacyRouted.result.minMonths, 9);
assert.equal(legacyRouted.result.maxMonths, 47);
assert.equal(legacyRouted.result.monthCount, 16);
assert.equal(legacyRouted.result.countSelectedRank, 8n);
assert.equal(legacyRouted.result.apiContract, 'ALL_WAYS_CONCRETE_ARRAY');
assert.equal(legacyRouted.result.concreteArrayContract, true);
assert.equal(legacyRouted.result.probeLimit, 2048);
assert.equal(legacyRouted.result.probeSampleCount, 2048);
assert.equal(legacyRouted.result.probeExceededLimit, true);
assert.equal(legacyRouted.context.legacyMonthLengthMaterializerExecuted, true);
assert.equal(legacyRouted.context.metrics['discovery23.monthLengthConcreteApi.calls'], 1n);
assert.equal(legacyRouted.context.metrics['discovery23.monthLengthProbe.calls'], 1n);
assert.equal(legacyRouted.context.metrics['discovery23.monthLengthProbe.exceeded.calls'], 1n);
assert.deepEqual(legacyRouted.context.branchTrace.slice(-5), [
  'DISCOVERY_21_ALL_POSITIVE_CUTLET_PARTITION',
  'PATCH_21_FILTERED_INTERNAL_GATE_CUTLET_PARTITION',
  'DISCOVERY_22_LEGACY_REPEATED_CUTLET_NAMES',
  'PATCH_22_DISTINCT_PARTIAL_PERMUTATION_NAMES',
  'DISCOVERY_23_LEGACY_CONCRETE_MONTH_LENGTH_ALL_WAYS'
]);

for (const row of legacyRouted.context.legacyMonthLengthProbeSample) {
  assert.equal(row.length, legacyRouted.result.monthCount);
  assert.equal(row.reduce((sum, length) => sum + length, 0), Number(legacyRouted.result.yearLength));
  for (const length of row) assert.ok(4 <= length && length <= 123);
}

const exactFamily = normative.makeBoundedCompositionCounter(
  Number(legacyRouted.result.yearLength), legacyRouted.result.monthCount, 4, 123
);
const exactFamilyCount = exactFamily.countAll();
assert.equal(exactFamilyCount, 5239332298078798668173613753510n);
assert.ok(exactFamilyCount > 1000000000000000000n);
assert.equal(BigInt(legacyRouted.result.probeSampleCount) < exactFamilyCount, true);

const routed = production.historicMonthLengthVirtualListThroughMonsterPath(
  new production.BaseMonsterManager(),
  calculationDay,
  calculationDay,
  -1n,
  gates,
  candidatePairs,
  selectionStream,
  noWalkExpected
);
const authoritativeSauce = normative.sauce(calculationDay, f + 11n);
const expectedMonthLengths = normative.chooseMonthLengths(
  authoritativeSauce,
  { openGateDay: f + 10n, closeGateDay: f + 1010n },
  16
);

assert.equal(routed.context.status, 'PATCH_23_RESULT');
assert.equal(routed.context.currentHandler, 'MonthLengthVirtualPatchWrapper');
assert.equal(routed.context.previousHandler, 'Discovery23MonthLengthMaterializationHandler');
assert.equal(routed.context.phase, 'PATCH_23_VIRTUAL_MONTH_LENGTH_ALL_WAYS');
assert.equal(routed.result.apiContract, 'VIRTUAL_EXACT_COUNT_LEXICOGRAPHIC_UNRANK');
assert.ok(routed.result.allWays instanceof production.VirtualLegacyList);
assert.equal(Array.isArray(routed.result.allWays), false);
assert.equal(routed.result.familyCount, exactFamilyCount);
assert.equal(routed.result.allWays.count(), exactFamilyCount);
assert.equal(routed.result.selectedRank, 1892970349028658514214546085756n);
assert.deepEqual(routed.result.monthLengths, expectedMonthLengths);
assert.deepEqual(routed.result.allWays.itemAt1(routed.result.selectedRank), expectedMonthLengths);
assert.equal(routed.result.legacyDiagnostic.apiContract, 'ALL_WAYS_CONCRETE_ARRAY');
assert.equal(routed.result.legacyDiagnostic.materializerExecuted, true);
assert.equal(routed.result.legacyDiagnostic.probeSampleCount, 2048);
assert.equal(routed.result.legacyDiagnostic.probeExceededLimit, true);
assert.equal(routed.context.metrics['discovery23.monthLengthConcreteApi.calls'], 1n);
assert.equal(routed.context.metrics['patch23.legacyConcreteDiagnosticPreserved.calls'], 1n);
assert.equal(routed.context.metrics['patch23.virtualExactCount.calls'], 1n);
assert.equal(routed.context.metrics['patch23.virtualLexicographicItemAt1.calls'], 1n);
assert.deepEqual(routed.context.branchTrace.slice(-2), [
  'DISCOVERY_23_LEGACY_CONCRETE_MONTH_LENGTH_ALL_WAYS',
  'PATCH_23_VIRTUAL_MONTH_LENGTH_ALL_WAYS'
]);

assert.equal(
  routed.result.apiContract,
  'VIRTUAL_EXACT_COUNT_LEXICOGRAPHIC_UNRANK',
  'Patch 23 deve conservar li façade historic de omni vias ma exposir semanticmen un VirtualLegacyList con count exact e itemAt1 lexicografic.'
);
