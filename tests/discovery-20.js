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
assert.equal('structureSaucePatch' in production, false);
assert.equal('legacyPositiveCompositions' in production, false);

const authoritativeSauce = normative.sauce(calculationDay, yearFirstDay);
const expectedToken = {
  bowl2: authoritativeSauce.bowls[1],
  orderAt46Latch: authoritativeSauce.orderAtDrop46.slice()
};
const actualTokens = [];
const expectedTokens = [];

for (const originalTargetDay of targets) {
  const directLegacy = production.oldStructureSauce(calculationDay, originalTargetDay);
  const directNormativeForOriginalTarget = normative.sauce(calculationDay, originalTargetDay);
  assert.equal(directLegacy.bowls[2], directNormativeForOriginalTarget.bowls[1]);
  assert.deepEqual(directLegacy.orderAt46Latch, directNormativeForOriginalTarget.orderAtDrop46);
  assert.notEqual(directLegacy.bowls[2], expectedToken.bowl2);

  const manager = new production.BaseMonsterManager();
  const routed = production.discovery20LegacyStructureSauceThroughMonsterPath(
    manager,
    calculationDay,
    originalTargetDay,
    -1n,
    gates,
    candidatePairs,
    selectionStream,
    noWalkExpected
  );
  assert.equal(routed.context.currentHandler, 'Discovery20StructureSauceHandler');
  assert.equal(routed.context.previousHandler, 'YearCacheActionGuardPatchWrapper');
  assert.equal(routed.context.phase, 'DISCOVERY_20_STRUCTURE_SAUCE_ORIGINAL_TARGET');
  assert.equal(routed.context.status, 'DISCOVERY_20_LEGACY_RESULT');
  assert.equal(routed.context.patch18SemanticYearNumber, 5000n);
  assert.equal(routed.context.patch18ResolvedYear.openDay, f + 10n);
  assert.equal(routed.context.legacyStructureSauceCalculationDay, calculationDay);
  assert.equal(routed.context.legacyStructureSauceOriginalTargetDay, originalTargetDay);
  assert.equal(routed.context.legacyStructureSauceYearFirstDay, yearFirstDay);
  assert.equal(routed.context.legacyStructureSauceTargetsDiffer, true);
  assert.equal(routed.context.legacyStructureSelectorUsedOriginalTargetSauce, true);
  assert.equal(routed.result.sauceTargetDay, originalTargetDay);
  assert.equal(routed.result.yearFirstDay, yearFirstDay);
  assert.equal(routed.result.targetsDiffer, true);
  assert.equal(routed.result.selectorToken.bowl2, directNormativeForOriginalTarget.bowls[1]);
  assert.deepEqual(routed.result.selectorToken.orderAt46Latch, directNormativeForOriginalTarget.orderAtDrop46);
  assert.equal(routed.context.metrics['discovery20.oldStructureSauce.calls'], 1n);
  assert.equal(routed.context.metrics['discovery20.legacySelector.calls'], 1n);
  assert.deepEqual(routed.context.branchTrace.slice(-4), [
    'DISCOVERY_18_OLD_JUMP_GUESS_365',
    'PATCH_18_SEQUENTIAL_YEAR_WALK',
    'PATCH_19_ACTION_AND_GATE_GUARDS',
    'DISCOVERY_20_STRUCTURE_SAUCE_ORIGINAL_TARGET'
  ]);

  actualTokens.push({
    bowl2: routed.result.selectorToken.bowl2,
    orderAt46Latch: routed.result.selectorToken.orderAt46Latch.slice()
  });
  expectedTokens.push({
    bowl2: expectedToken.bowl2,
    orderAt46Latch: expectedToken.orderAt46Latch.slice()
  });
}

console.log('DISCOVERY 20 DIAGNOSTIC: oldStructureSauce usa li target original e su resultate intra directmen li selector structural legacy.');
console.log('year first day: ' + yearFirstDay.toString());
for (let index = 0; index < targets.length; index += 1) {
  console.log('target ' + targets[index].toString() + ' legacy bowl2: ' + actualTokens[index].bowl2.toString());
  console.log('target ' + targets[index].toString() + ' normativ bowl2: ' + expectedTokens[index].bowl2.toString());
}

assert.deepEqual(
  actualTokens,
  expectedTokens,
  'DISCOVERY 20 EXPECTED RED: li structure sauce ne posse usar li target original quand it difere de year.firstDay; li selector deve vider sauce(cDay,year.firstDay).'
);
