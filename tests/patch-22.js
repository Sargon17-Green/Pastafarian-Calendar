'use strict';

const assert = require('assert/strict');
const production = require('../src');
const normative = require('./normative-reference');

assert.equal(typeof production.fallingFactorialDistinct, 'function');
assert.equal(typeof production.partialPermutationUnrank, 'function');
assert.equal(typeof production.RepeatedNamePatchWrapper, 'function');
assert.equal(typeof production.historicRepeatedNamesThroughMonsterPath, 'function');
assert.equal(typeof production.VirtualLegacyList, 'function');
assert.equal('legacyChooseEachDaySeparately' in production, false);
assert.equal('oldContiguousMonthDayGuess' in production, false);

const legacyFamilySource = production.legacyNameRowWithRepeats.toString();
const legacyGeneratorSource = production.LegacyRepeatedNameGenerator.prototype.select.toString();
const discoverySource = production.Discovery22RepeatedNameHandler.prototype.handle.toString();
assert.doesNotMatch(legacyFamilySource, /partialPermutation|fallingFactorial|distinct/i);
assert.doesNotMatch(legacyGeneratorSource, /partialPermutation|fallingFactorial|RepeatedNamePatchWrapper/);
assert.doesNotMatch(discoverySource, /partialPermutation|fallingFactorial|RepeatedNamePatchWrapper/);
const wrapperSource = production.RepeatedNamePatchWrapper.prototype.repair.toString();
assert.match(wrapperSource, /partialPermutationUnrank/);
assert.match(wrapperSource, /legacyCutletNameIndices/);

assert.equal(production.fallingFactorialDistinct(17, 6), 8910720n);
assert.equal(production.fallingFactorialDistinct(3, 2), 6n);
assert.equal(production.fallingFactorialDistinct(1, 1), 1n);
assert.equal(production.fallingFactorialDistinct(0, 0), 1n);
assert.throws(() => production.fallingFactorialDistinct(-1, 0), RangeError);
assert.throws(() => production.fallingFactorialDistinct(3, 4), RangeError);

assert.deepEqual(
  [1n,2n,3n,4n,5n,6n].map((rank) => production.partialPermutationUnrank(3, 2, rank)),
  [[1,2],[1,3],[2,1],[2,3],[3,1],[3,2]]
);
assert.deepEqual(production.partialPermutationUnrank(0, 0, 1n), []);
assert.throws(() => production.partialPermutationUnrank(3, 2, 0n), RangeError);
assert.throws(() => production.partialPermutationUnrank(3, 2, 7n), RangeError);

for (let masterCount = 1; masterCount <= 7; masterCount += 1) {
  for (let itemCount = 1; itemCount <= masterCount; itemCount += 1) {
    const expected = [];
    function visit(prefix, remaining) {
      if (prefix.length === itemCount) {
        expected.push(prefix.slice());
        return;
      }
      for (let index = 0; index < remaining.length; index += 1) {
        const next = remaining.slice();
        const value = next.splice(index, 1)[0];
        visit(prefix.concat(value), next);
      }
    }
    visit([], Array.from({ length: masterCount }, (_, index) => index + 1));
    assert.equal(production.fallingFactorialDistinct(masterCount, itemCount), BigInt(expected.length));
    for (let index = 0; index < expected.length; index += 1) {
      assert.deepEqual(production.partialPermutationUnrank(masterCount, itemCount, BigInt(index + 1)), expected[index]);
    }
  }
}

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
  nextYear() { throw new Error('Patch 22 ne deve caminar avante ex Year 5000 in ti witness.'); },
  previousYear() { throw new Error('Patch 22 ne deve caminar retro ex Year 5000 in ti witness.'); }
};

const legacy = production.discovery22LegacyRepeatedNamesThroughMonsterPath(
  new production.BaseMonsterManager(), calculationDay, calculationDay, -1n,
  gates, candidatePairs, selectionStream, noWalkExpected
);
const patched = production.historicRepeatedNamesThroughMonsterPath(
  new production.BaseMonsterManager(), calculationDay, calculationDay, -1n,
  gates, candidatePairs, selectionStream, noWalkExpected
);
const expected = normative.chooseCutletNames(normative.sauce(calculationDay, f + 11n), 6);

assert.deepEqual(legacy.result.nameIndices, [6,6,10,10,17,9]);
assert.equal(legacy.result.hasRepeatedCanonicalIndex, true);
assert.equal(patched.context.status, 'PATCH_22_RESULT');
assert.equal(patched.context.previousHandler, 'Discovery22RepeatedNameHandler');
assert.equal(patched.context.patch22DistinctFamilyCount, 8910720n);
assert.equal(patched.context.patch22DistinctSelectedRank, 1348551n);
assert.deepEqual(patched.context.patch22BadNameIndices, legacy.result.nameIndices);
assert.deepEqual(patched.context.patch22CorrectNameIndices, expected);
assert.deepEqual(patched.result.nameIndices, expected);
assert.equal(patched.result.badEqualsCorrect, false);
assert.equal(patched.result.returnedLegacyObject, false);
assert.equal(patched.result.legacyDiagnostic.familyCount, 24137569n);
assert.equal(patched.result.legacyDiagnostic.selectedRank, 7563989n);
assert.deepEqual(patched.result.legacyDiagnostic.nameIndices, [6,6,10,10,17,9]);
assert.equal(patched.result.legacyDiagnostic.hasRepeatedCanonicalIndex, true);
assert.equal(patched.context.metrics['discovery22.repeatedNameGenerator.calls'], 1n);
assert.equal(patched.context.metrics['patch22.legacyDiagnosticPreserved.calls'], 1n);
assert.equal(patched.context.metrics['patch22.distinctPartialPermutation.calls'], 1n);
assert.equal(patched.context.metrics['patch22.correctedNameSelection.calls'], 1n);
assert.equal(patched.context.metrics['patch22.legacyIdentityReturn.calls'], undefined);
assert.deepEqual(patched.context.branchTrace.slice(-4), [
  'DISCOVERY_21_ALL_POSITIVE_CUTLET_PARTITION',
  'PATCH_21_FILTERED_INTERNAL_GATE_CUTLET_PARTITION',
  'DISCOVERY_22_LEGACY_REPEATED_CUTLET_NAMES',
  'PATCH_22_DISTINCT_PARTIAL_PERMUTATION_NAMES'
]);

const identityManager = new production.BaseMonsterManager();
const identityContext = new production.BaseMonsterContext(1n, 2n);
const identitySauce = production.sauceWithCurrentScars(1n, 2n);
const identityStream = production.cutletNameAnswerRingFromSauce(identitySauce);
const identityRank = production.selectionDispatcherWithWideDetour(identityStream, 3n).output;
const identityBad = [Number(identityRank)];
identityContext.status = 'DISCOVERY_22_LEGACY_RESULT';
identityContext.currentHandler = 'Discovery22RepeatedNameHandler';
identityContext.legacyCutletNameIndices = identityBad;
identityContext.legacyCutletNameMasterIndices = [1,2,3];
identityContext.legacyCutletNameCount = 1;
identityContext.legacyCutletNameFamilyCount = 3n;
identityContext.legacyCutletNameSelectedRank = identityRank;
identityContext.legacyCutletNameHasRepeatedCanonicalIndex = false;
identityContext.patch20SemanticSauceBowls = identitySauce.bowls.slice();
identityContext.patch20SemanticOrderAt46Latch = identitySauce.orderAt46Latch.slice();
const identity = identityManager.repeatedNamePatchWrapper.repair(identityContext);
assert.equal(identity.badEqualsCorrect, true);
assert.equal(identity.returnedLegacyObject, true);
assert.strictEqual(identity.nameIndices, identityBad);
assert.strictEqual(identityContext.patch22SemanticNameIndices, identityBad);
assert.equal(identityContext.metrics['patch22.legacyIdentityReturn.calls'], 1n);
assert.equal(identityContext.metrics['patch22.correctedNameSelection.calls'], undefined);

const second = production.historicRepeatedNamesThroughMonsterPath(
  new production.BaseMonsterManager(), calculationDay, calculationDay, -1n,
  gates, candidatePairs, selectionStream, noWalkExpected
);
assert.notStrictEqual(second.context, patched.context);
assert.deepEqual(second.result.nameIndices, patched.result.nameIndices);
assert.deepEqual(second.context.patch22BadNameIndices, patched.context.patch22BadNameIndices);
assert.equal(second.context.metrics['discovery22.repeatedNameGenerator.calls'], 1n);
assert.equal(second.context.metrics['patch22.distinctPartialPermutation.calls'], 1n);

console.log('PATCH 22: PASS — li generator legacy executa prim e resta diagnostic; li detour distinct usa partial-permutation lexicografic exact e retorna bad solmen quand bad e correct es identic.');
