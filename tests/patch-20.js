'use strict';

const assert = require('assert/strict');
const production = require('../src');
const normative = require('./normative-reference');

const expectedOldSource = `function oldStructureSauce(cDay, originalTargetDay) {
  // Discovery 20 conserva li assumption historic: li sauce structural es calculat con li target original del request.
  return sauceWithCurrentScars(cDay, originalTargetDay);
}`;
assert.equal(production.oldStructureSauce.toString(), expectedOldSource);

const patchSource = production.structureSaucePatch.toString();
assert.ok(
  patchSource.indexOf('oldStructureSauce(cDay, originalTargetDay)') <
    patchSource.indexOf('sauceWithCurrentScars(cDay, yearFirstDay)'),
  'Li call ghost old deve preceder li materialisation semantic con year.firstDay.'
);
assert.match(patchSource, /const ghost = oldStructureSauce\(cDay, originalTargetDay\)/);
assert.match(patchSource, /const semanticSauce = sauceWithCurrentScars\(cDay, yearFirstDay\)/);
assert.doesNotMatch(patchSource, /legacyStructureSelectorToken|selectorAdapter/);

const wrapperSource = production.StructureSaucePatchWrapper.prototype.repair.toString();
assert.match(wrapperSource, /this\.selectorAdapter\.select\(patched\.semanticSauce\)/);
assert.doesNotMatch(wrapperSource, /select\(patched\.ghost\)/);
assert.match(wrapperSource, /patch20GhostIgnoredForSelector = true/);

const f = normative.FOUNDATION_DAY;
const calculationDay = f + 100n;
const yearFirstDay = f + 11n;
const originalTargetDay = f + 365n;
const patchedDirect = production.structureSaucePatch(calculationDay, originalTargetDay, yearFirstDay);
const normativeOriginal = normative.sauce(calculationDay, originalTargetDay);
const normativeFirstDay = normative.sauce(calculationDay, yearFirstDay);
assert.equal(patchedDirect.targetsDiffer, true);
assert.equal(patchedDirect.ghost.bowls[2], normativeOriginal.bowls[1]);
assert.deepEqual(patchedDirect.ghost.orderAt46Latch, normativeOriginal.orderAtDrop46);
assert.equal(patchedDirect.semanticSauce.bowls[2], normativeFirstDay.bowls[1]);
assert.deepEqual(patchedDirect.semanticSauce.orderAt46Latch, normativeFirstDay.orderAtDrop46);
assert.notEqual(patchedDirect.ghost.bowls[2], patchedDirect.semanticSauce.bowls[2]);
assert.notStrictEqual(patchedDirect.ghost, patchedDirect.semanticSauce);

const sameTarget = production.structureSaucePatch(calculationDay, yearFirstDay, yearFirstDay);
assert.equal(sameTarget.targetsDiffer, false);
assert.deepEqual(sameTarget.ghost.bowls, sameTarget.semanticSauce.bowls);
assert.deepEqual(sameTarget.ghost.orderAt46Latch, sameTarget.semanticSauce.orderAt46Latch);
assert.notStrictEqual(sameTarget.ghost, sameTarget.semanticSauce);
assert.throws(() => production.structureSaucePatch(1, 2n, 3n), TypeError);

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
const noWalkExpected = {
  nextYear() { throw new Error('Patch 20 ne deve caminar avante in ti witness de Year 5000.'); },
  previousYear() { throw new Error('Patch 20 ne deve caminar retro in ti witness de Year 5000.'); }
};

const legacyManager = new production.BaseMonsterManager();
const legacy = production.discovery20LegacyStructureSauceThroughMonsterPath(
  legacyManager,
  calculationDay,
  originalTargetDay,
  -1n,
  gates,
  candidatePairs,
  selectionStream,
  noWalkExpected
);
assert.equal(legacy.context.status, 'DISCOVERY_20_LEGACY_RESULT');
assert.equal(legacy.result.selectorToken.bowl2, normativeOriginal.bowls[1]);
assert.notEqual(legacy.result.selectorToken.bowl2, normativeFirstDay.bowls[1]);

const manager = new production.BaseMonsterManager();
const routed = production.historicStructureSauceThroughMonsterPath(
  manager,
  calculationDay,
  originalTargetDay,
  -1n,
  gates,
  candidatePairs,
  selectionStream,
  noWalkExpected
);
assert.equal(routed.context.currentHandler, 'StructureSaucePatchWrapper');
assert.equal(routed.context.previousHandler, 'YearCacheActionGuardPatchWrapper');
assert.equal(routed.context.status, 'PATCH_20_RESULT');
assert.equal(routed.context.patch20GhostCalculationDay, calculationDay);
assert.equal(routed.context.patch20GhostOriginalTargetDay, originalTargetDay);
assert.equal(routed.context.patch20YearFirstDay, yearFirstDay);
assert.equal(routed.context.patch20TargetsDiffer, true);
assert.equal(routed.context.patch20GhostExecuted, true);
assert.equal(routed.context.patch20GhostIgnoredForSelector, true);
assert.equal(routed.context.patch20SelectorUsedYearFirstDaySauce, true);
assert.equal(routed.context.patch20GhostSauceBowls[2], normativeOriginal.bowls[1]);
assert.deepEqual(routed.context.patch20GhostOrderAt46Latch, normativeOriginal.orderAtDrop46);
assert.equal(routed.context.patch20SemanticSauceBowls[2], normativeFirstDay.bowls[1]);
assert.deepEqual(routed.context.patch20SemanticOrderAt46Latch, normativeFirstDay.orderAtDrop46);
assert.equal(routed.context.patch20SemanticSelectorToken.bowl2, normativeFirstDay.bowls[1]);
assert.deepEqual(routed.context.patch20SemanticSelectorToken.orderAt46Latch, normativeFirstDay.orderAtDrop46);
assert.equal(routed.result.selectorToken.bowl2, normativeFirstDay.bowls[1]);
assert.deepEqual(routed.result.selectorToken.orderAt46Latch, normativeFirstDay.orderAtDrop46);
assert.equal(routed.context.metrics['patch20.oldStructureSauce.ghost.calls'], 1n);
assert.equal(routed.context.metrics['patch20.yearFirstDaySauce.calls'], 1n);
assert.equal(routed.context.metrics['patch20.semanticSelector.calls'], 1n);
assert.equal(routed.context.metrics['patch20.targetDetour.calls'], 1n);
assert.equal(routed.context.metrics['discovery20.oldStructureSauce.calls'], undefined);
assert.equal(routed.context.metrics['discovery20.legacySelector.calls'], undefined);

const sameManager = new production.BaseMonsterManager();
const sameRouted = production.historicStructureSauceThroughMonsterPath(
  sameManager,
  calculationDay,
  yearFirstDay,
  -1n,
  gates,
  candidatePairs,
  selectionStream,
  noWalkExpected
);
assert.equal(sameRouted.result.targetsDiffer, false);
assert.equal(sameRouted.result.semanticTargetDay, yearFirstDay);
assert.equal(sameRouted.result.selectorToken.bowl2, normativeFirstDay.bowls[1]);
assert.deepEqual(sameRouted.result.selectorToken.orderAt46Latch, normativeFirstDay.orderAtDrop46);
assert.equal(sameRouted.context.metrics['patch20.targetDetour.calls'], undefined);
assert.equal(sameRouted.context.patch20GhostIgnoredForSelector, true);

assert.ok(!production.StructureSaucePatchWrapper.prototype.repair.toString().includes('legacyPositiveCompositions'));
assert.equal(typeof production.CutletPartitionPatchWrapper, 'function');
assert.equal(typeof production.filteredCutletCompositions, 'function');
assert.equal(typeof production.RepeatedNamePatchWrapper, 'function');
assert.equal(typeof production.partialPermutationUnrank, 'function');

console.log('PATCH 20: PASS — oldStructureSauce resta un ghost real, ma solmen sauce(cDay,year.firstDay) atinge li selector semantic.');
