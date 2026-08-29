'use strict';

const assert = require('assert/strict');
const production = require('../src');
const normative = require('./normative-reference');

const f = normative.FOUNDATION_DAY;
const calculationDay = f + 100n;
const selectionStream = { first: 1n, directionStep: 1n };
const candidatePairs = [
  { openIndex: 30, closeIndex: 36 },
  { openIndex: 10, closeIndex: 16 },
  { openIndex: 20, closeIndex: 26 }
];
const gates = {
  10: f + 10n, 16: f + 1010n,
  20: f + 20n, 26: f + 1020n,
  30: f + 30n, 36: f + 1030n
};
const yearFirstDay = f + 11n;
const targets = [f + 100n, f + 365n, f + 1000n];
const noWalkExpected = {
  nextYear() {
    throw new Error('Li witnesses de Discovery 20 deve restar intra Year 5000.');
  },
  previousYear() {
    throw new Error('Li witnesses de Discovery 20 deve restar intra Year 5000.');
  }
};

const oldSource = production.oldStructureSauce.toString();
assert.match(oldSource, /sauceWithCurrentScars\(cDay, originalTargetDay\)/);
assert.doesNotMatch(oldSource, /yearFirstDay|structureSaucePatch|ghost/);
assert.equal(typeof production.structureSaucePatch, 'function');
assert.ok(!production.Discovery20StructureSauceHandler.prototype.handle.toString().includes('legacyPositiveCompositions'));

const authoritativeSauce = normative.sauce(calculationDay, yearFirstDay);
const expectedToken = {
  bowl2: authoritativeSauce.bowls[1],
  orderAt46Latch: authoritativeSauce.orderAtDrop46.slice()
};
const legacyTokens = [];
const patchedTokens = [];
const expectedTokens = [];

for (const originalTargetDay of targets) {
  const directLegacy = production.oldStructureSauce(calculationDay, originalTargetDay);
  const directNormativeForOriginalTarget = normative.sauce(calculationDay, originalTargetDay);
  assert.equal(directLegacy.bowls[2], directNormativeForOriginalTarget.bowls[1]);
  assert.deepEqual(directLegacy.orderAt46Latch, directNormativeForOriginalTarget.orderAtDrop46);
  assert.notEqual(directLegacy.bowls[2], expectedToken.bowl2);

  const legacyManager = new production.BaseMonsterManager();
  const legacyRouted = production.discovery20LegacyStructureSauceThroughMonsterPath(
    legacyManager,
    calculationDay,
    originalTargetDay,
    -1n,
    gates,
    candidatePairs,
    selectionStream,
    noWalkExpected
  );
  assert.equal(legacyRouted.context.currentHandler, 'Discovery20StructureSauceHandler');
  assert.equal(legacyRouted.context.previousHandler, 'YearCacheActionGuardPatchWrapper');
  assert.equal(legacyRouted.context.phase, 'DISCOVERY_20_STRUCTURE_SAUCE_ORIGINAL_TARGET');
  assert.equal(legacyRouted.context.status, 'DISCOVERY_20_LEGACY_RESULT');
  assert.equal(legacyRouted.context.patch18SemanticYearNumber, 5000n);
  assert.equal(legacyRouted.context.patch18ResolvedYear.openDay, f + 10n);
  assert.equal(legacyRouted.context.legacyStructureSauceCalculationDay, calculationDay);
  assert.equal(legacyRouted.context.legacyStructureSauceOriginalTargetDay, originalTargetDay);
  assert.equal(legacyRouted.context.legacyStructureSauceYearFirstDay, yearFirstDay);
  assert.equal(legacyRouted.context.legacyStructureSauceTargetsDiffer, true);
  assert.equal(legacyRouted.context.legacyStructureSelectorUsedOriginalTargetSauce, true);
  assert.equal(legacyRouted.result.sauceTargetDay, originalTargetDay);
  assert.equal(legacyRouted.result.yearFirstDay, yearFirstDay);
  assert.equal(legacyRouted.result.targetsDiffer, true);
  assert.equal(legacyRouted.result.selectorToken.bowl2, directNormativeForOriginalTarget.bowls[1]);
  assert.deepEqual(legacyRouted.result.selectorToken.orderAt46Latch, directNormativeForOriginalTarget.orderAtDrop46);
  assert.equal(legacyRouted.context.metrics['discovery20.oldStructureSauce.calls'], 1n);
  assert.equal(legacyRouted.context.metrics['discovery20.legacySelector.calls'], 1n);

  const patchedManager = new production.BaseMonsterManager();
  const patched = production.historicStructureSauceThroughMonsterPath(
    patchedManager,
    calculationDay,
    originalTargetDay,
    -1n,
    gates,
    candidatePairs,
    selectionStream,
    noWalkExpected
  );
  assert.equal(patched.context.currentHandler, 'StructureSaucePatchWrapper');
  assert.equal(patched.context.previousHandler, 'YearCacheActionGuardPatchWrapper');
  assert.equal(patched.context.phase, 'PATCH_20_STRUCTURE_SAUCE_YEAR_FIRST_DAY_GHOST');
  assert.equal(patched.context.status, 'PATCH_20_RESULT');
  assert.equal(patched.context.patch20GhostExecuted, true);
  assert.equal(patched.context.patch20GhostIgnoredForSelector, true);
  assert.equal(patched.context.patch20SelectorUsedYearFirstDaySauce, true);
  assert.equal(patched.result.ghostTargetDay, originalTargetDay);
  assert.equal(patched.result.semanticTargetDay, yearFirstDay);
  assert.equal(patched.result.targetsDiffer, true);
  assert.equal(patched.result.ghostSauce.bowls[2], directNormativeForOriginalTarget.bowls[1]);
  assert.deepEqual(patched.result.ghostSauce.orderAt46Latch, directNormativeForOriginalTarget.orderAtDrop46);
  assert.equal(patched.result.selectorToken.bowl2, expectedToken.bowl2);
  assert.deepEqual(patched.result.selectorToken.orderAt46Latch, expectedToken.orderAt46Latch);
  assert.equal(patched.context.metrics['patch20.oldStructureSauce.ghost.calls'], 1n);
  assert.equal(patched.context.metrics['patch20.yearFirstDaySauce.calls'], 1n);
  assert.equal(patched.context.metrics['patch20.semanticSelector.calls'], 1n);
  assert.equal(patched.context.metrics['patch20.targetDetour.calls'], 1n);
  assert.deepEqual(patched.context.branchTrace.slice(-4), [
    'DISCOVERY_18_OLD_JUMP_GUESS_365',
    'PATCH_18_SEQUENTIAL_YEAR_WALK',
    'PATCH_19_ACTION_AND_GATE_GUARDS',
    'PATCH_20_STRUCTURE_SAUCE_YEAR_FIRST_DAY_GHOST'
  ]);

  legacyTokens.push({
    bowl2: legacyRouted.result.selectorToken.bowl2,
    orderAt46Latch: legacyRouted.result.selectorToken.orderAt46Latch.slice()
  });
  patchedTokens.push({
    bowl2: patched.result.selectorToken.bowl2,
    orderAt46Latch: patched.result.selectorToken.orderAt46Latch.slice()
  });
  expectedTokens.push({
    bowl2: expectedToken.bowl2,
    orderAt46Latch: expectedToken.orderAt46Latch.slice()
  });
}

console.log('DISCOVERY 20: PASS post-Patch 20 — li route legacy resta diagnosticmen wrong, durante que li route reparat manda solmen sauce(cDay,year.firstDay) al selector.');
assert.notDeepEqual(legacyTokens, expectedTokens);
assert.deepEqual(patchedTokens, expectedTokens);
