'use strict';

const assert = require('assert/strict');
const production = require('../src');
const normative = require('./normative-reference');

assert.equal(typeof production.legacyMaterializeMonthLengthWays, 'function');
assert.equal(typeof production.LegacyMonthLengthAllWaysAPI, 'function');
assert.equal(typeof production.Discovery23MonthLengthMaterializationHandler, 'function');
assert.equal(typeof production.discovery23LegacyMonthLengthMaterializationThroughMonsterPath, 'function');
assert.equal('VirtualLegacyList' in production, false);
assert.equal('legacyChooseEachDaySeparately' in production, false);
assert.equal('oldContiguousMonthDayGuess' in production, false);

const legacySource = production.legacyMaterializeMonthLengthWays.toString();
const legacyApiSource = production.LegacyMonthLengthAllWaysAPI.prototype.allWays.toString();
const discoverySource = production.Discovery23MonthLengthMaterializationHandler.prototype.handle.toString();
assert.doesNotMatch(legacySource, /VirtualLegacyList|unrank|countAll|memo/i);
assert.doesNotMatch(legacyApiSource, /VirtualLegacyList|unrank|countAll|memo/i);
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
  nextYear() { throw new Error('Discovery 23 ne deve caminar avante ex Year 5000 in ti witness.'); },
  previousYear() { throw new Error('Discovery 23 ne deve caminar retro ex Year 5000 in ti witness.'); }
};

const routed = production.discovery23LegacyMonthLengthMaterializationThroughMonsterPath(
  new production.BaseMonsterManager(),
  calculationDay,
  calculationDay,
  -1n,
  gates,
  candidatePairs,
  selectionStream,
  noWalkExpected
);

assert.equal(routed.context.status, 'DISCOVERY_23_LEGACY_RESULT');
assert.equal(routed.context.currentHandler, 'Discovery23MonthLengthMaterializationHandler');
assert.equal(routed.context.previousHandler, 'RepeatedNamePatchWrapper');
assert.equal(routed.context.phase, 'DISCOVERY_23_LEGACY_CONCRETE_MONTH_LENGTH_ALL_WAYS');
assert.equal(routed.context.patch22BadEqualsCorrect, false);
assert.deepEqual(routed.context.patch22SemanticNameIndices, [3,11,4,9,12,5]);
assert.equal(routed.result.yearLength, 1000n);
assert.equal(routed.result.minMonths, 9);
assert.equal(routed.result.maxMonths, 47);
assert.equal(routed.result.monthCount, 16);
assert.equal(routed.result.countSelectedRank, 8n);
assert.equal(routed.result.apiContract, 'ALL_WAYS_CONCRETE_ARRAY');
assert.equal(routed.result.concreteArrayContract, true);
assert.equal(routed.result.probeLimit, 2048);
assert.equal(routed.result.probeSampleCount, 2048);
assert.equal(routed.result.probeExceededLimit, true);
assert.equal(routed.context.legacyMonthLengthMaterializerExecuted, true);
assert.equal(routed.context.metrics['discovery23.monthLengthConcreteApi.calls'], 1n);
assert.equal(routed.context.metrics['discovery23.monthLengthProbe.calls'], 1n);
assert.equal(routed.context.metrics['discovery23.monthLengthProbe.exceeded.calls'], 1n);
assert.deepEqual(routed.context.branchTrace.slice(-5), [
  'DISCOVERY_21_ALL_POSITIVE_CUTLET_PARTITION',
  'PATCH_21_FILTERED_INTERNAL_GATE_CUTLET_PARTITION',
  'DISCOVERY_22_LEGACY_REPEATED_CUTLET_NAMES',
  'PATCH_22_DISTINCT_PARTIAL_PERMUTATION_NAMES',
  'DISCOVERY_23_LEGACY_CONCRETE_MONTH_LENGTH_ALL_WAYS'
]);

for (const row of routed.context.legacyMonthLengthProbeSample) {
  assert.equal(row.length, routed.result.monthCount);
  assert.equal(row.reduce((sum, length) => sum + length, 0), Number(routed.result.yearLength));
  for (const length of row) assert.ok(4 <= length && length <= 123);
}

const exactFamily = normative.makeBoundedCompositionCounter(
  Number(routed.result.yearLength), routed.result.monthCount, 4, 123
);
const exactFamilyCount = exactFamily.countAll();
assert.equal(exactFamilyCount, 5239332298078798668173613753510n);
assert.ok(exactFamilyCount > 1000000000000000000n);
assert.equal(BigInt(routed.result.probeSampleCount) < exactFamilyCount, true);

assert.equal(
  routed.result.apiContract,
  'VIRTUAL_EXACT_COUNT_LEXICOGRAPHIC_UNRANK',
  'Discovery 23 EXPECTED_RED: li Legacy API ancor expone un Array concret de omni vias, durante que li familie real have 5239332298078798668173613753510 membres e ne posse esser materialisat securmen.'
);
