'use strict';

const assert = require('assert/strict');
const production = require('../src');
const normative = require('./normative-reference');

assert.equal(typeof production.legacyNameRowWithRepeats, 'function');
assert.equal(typeof production.LegacyRepeatedNameGenerator, 'function');
assert.equal(typeof production.Discovery22RepeatedNameHandler, 'function');
assert.equal(typeof production.RepeatedNamePatchWrapper, 'function');
assert.equal(typeof production.partialPermutationUnrank, 'function');
assert.equal('VirtualLegacyList' in production, false);

const legacySource = production.legacyNameRowWithRepeats.toString();
assert.doesNotMatch(legacySource, /partialPermutation|fallingFactorial|distinct/i);
const legacyGeneratorSource = production.LegacyRepeatedNameGenerator.prototype.select.toString();
assert.doesNotMatch(legacyGeneratorSource, /partialPermutation|fallingFactorial|RepeatedNamePatchWrapper/);

const small = production.legacyNameRowWithRepeats(3, 2);
assert.equal(small.count(), 9n);
assert.deepEqual(
  [1n,2n,3n,4n,5n,6n,7n,8n,9n].map((rank) => small.unrank1(rank)),
  [
    [1,1],[1,2],[1,3],
    [2,1],[2,2],[2,3],
    [3,1],[3,2],[3,3]
  ]
);
assert.throws(() => production.legacyNameRowWithRepeats(0, 2), RangeError);
assert.throws(() => production.legacyNameRowWithRepeats(3, 0), RangeError);
assert.throws(() => small.unrank1(0n), RangeError);
assert.throws(() => small.unrank1(10n), RangeError);

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
  nextYear() { throw new Error('Discovery 22 ne deve caminar avante ex Year 5000 in ti witness.'); },
  previousYear() { throw new Error('Discovery 22 ne deve caminar retro ex Year 5000 in ti witness.'); }
};

const legacyRouted = production.discovery22LegacyRepeatedNamesThroughMonsterPath(
  new production.BaseMonsterManager(),
  calculationDay,
  calculationDay,
  -1n,
  gates,
  candidatePairs,
  selectionStream,
  noWalkExpected
);

assert.equal(legacyRouted.context.status, 'DISCOVERY_22_LEGACY_RESULT');
assert.equal(legacyRouted.context.currentHandler, 'Discovery22RepeatedNameHandler');
assert.equal(legacyRouted.context.previousHandler, 'CutletPartitionPatchWrapper');
assert.equal(legacyRouted.context.phase, 'DISCOVERY_22_LEGACY_REPEATED_CUTLET_NAMES');
assert.equal(legacyRouted.context.patch21SemanticPartition.length, 6);
assert.equal(legacyRouted.result.cutletCount, 6);
assert.deepEqual(legacyRouted.result.masterIndices, [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17]);
assert.equal(legacyRouted.result.familyCount, 24137569n);
assert.equal(legacyRouted.result.selectedRank, 7563989n);
assert.deepEqual(legacyRouted.result.nameIndices, [6,6,10,10,17,9]);
assert.equal(legacyRouted.result.hasRepeatedCanonicalIndex, true);
assert.equal(legacyRouted.context.legacyRepeatedNameGeneratorExecuted, true);
assert.equal(legacyRouted.context.legacyCutletNameUsedSemanticStructureSauce, true);
assert.equal(legacyRouted.context.metrics['discovery22.repeatedNameGenerator.calls'], 1n);
assert.equal(legacyRouted.context.metrics['discovery22.nameSelection.calls'], 1n);
assert.equal(legacyRouted.context.metrics['discovery22.repeatedCanonicalIndex.calls'], 1n);
assert.deepEqual(legacyRouted.context.branchTrace.slice(-3), [
  'DISCOVERY_21_ALL_POSITIVE_CUTLET_PARTITION',
  'PATCH_21_FILTERED_INTERNAL_GATE_CUTLET_PARTITION',
  'DISCOVERY_22_LEGACY_REPEATED_CUTLET_NAMES'
]);

const yearFirstDay = f + 11n;
const authoritativeSauce = normative.sauce(calculationDay, yearFirstDay);
const expected = normative.chooseCutletNames(authoritativeSauce, legacyRouted.result.cutletCount);
assert.deepEqual(expected, [3,11,4,9,12,5]);
assert.equal(new Set(expected).size, expected.length);
assert.notDeepEqual(legacyRouted.result.nameIndices, expected);

const routed = production.historicRepeatedNamesThroughMonsterPath(
  new production.BaseMonsterManager(),
  calculationDay,
  calculationDay,
  -1n,
  gates,
  candidatePairs,
  selectionStream,
  noWalkExpected
);
assert.equal(routed.context.status, 'PATCH_22_RESULT');
assert.equal(routed.context.previousHandler, 'Discovery22RepeatedNameHandler');
assert.deepEqual(routed.context.patch22BadNameIndices, legacyRouted.result.nameIndices);
assert.equal(routed.context.legacyCutletNameHasRepeatedCanonicalIndex, true);
assert.deepEqual(routed.result.nameIndices, expected);
assert.equal(new Set(routed.result.nameIndices).size, routed.result.nameIndices.length);
assert.deepEqual(routed.result.legacyDiagnostic.nameIndices, [6,6,10,10,17,9]);
assert.equal(routed.result.legacyDiagnostic.hasRepeatedCanonicalIndex, true);
assert.deepEqual(
  routed.result.nameIndices,
  expected,
  'Patch 22 deve retornar li partial permutation distinct durant que li candidate legacy repetit resta diagnostic.'
);
