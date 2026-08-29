'use strict';

const assert = require('assert/strict');
const production = require('../src');
const normative = require('./normative-reference');

const f = normative.FOUNDATION_DAY;
const cases = [
  [f, f],
  [f - 2n, f + 2n],
  [f - 1n, f],
  [f, f + 1n],
  [f + 1n, f + 3n],
  [f - 3n, f - 1n]
];

const legacy = [];
const actual = [];
const expected = [];
for (const [calculationDay, targetDay] of cases) {
  const execution = production.historicDistanceThroughMonsterPath(calculationDay, targetDay);
  legacy.push(execution.context.legacyDistanceOutput);
  actual.push(execution.result);
  expected.push(normative.workCounts(calculationDay, targetDay).distance);
  assert.equal(execution.context.currentHandler, 'Patch03DistanceWrapper');
  assert.equal(execution.context.phase, 'PATCH_03_CHRONOLOGY_DETOUR');
  assert.equal(execution.context.status, 'PATCH_03_RESULT');
  assert.equal(execution.context.legacyDistanceCalculationDay, calculationDay);
  assert.equal(execution.context.legacyDistanceTargetDay, targetDay);
  assert.equal(execution.context.patch03CalculationDay, calculationDay);
  assert.equal(execution.context.patch03TargetDay, targetDay);
  assert.equal(execution.context.patch03Output, execution.result);
}

assert.deepEqual(legacy, [0n, 1n, 1n, 2n, 4n, 4n]);
assert.deepEqual(expected, [1n, 5n, 2n, 2n, 3n, 3n]);
assert.notDeepEqual(legacy, expected);
assert.deepEqual(actual, expected);
assert.equal(production.oldDistance(f, f + 1n), 2n);

console.log('DISCOVERY 03 REGRESSION: PASS pos Patch 03; li scar oldDistance resta divergent e li detour rende li distance normativ.');
console.log('legacy:   ' + legacy.map(String).join(', '));
console.log('reparat:  ' + actual.map(String).join(', '));
console.log('normativ: ' + expected.map(String).join(', '));
