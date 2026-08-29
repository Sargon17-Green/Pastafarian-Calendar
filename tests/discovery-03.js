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

const actual = [];
const expected = [];
for (const [calculationDay, targetDay] of cases) {
  const execution = production.discovery03LegacyDistanceThroughMonsterPath(calculationDay, targetDay);
  actual.push(execution.result);
  expected.push(normative.workCounts(calculationDay, targetDay).distance);
  assert.equal(execution.context.currentHandler, 'Discovery03DistanceHandler');
  assert.equal(execution.context.phase, 'DISCOVERY_03_LEGACY_DISTANCE');
  assert.equal(execution.context.status, 'DISCOVERY_03_LEGACY_RESULT');
  assert.equal(execution.context.legacyDistanceCalculationDay, calculationDay);
  assert.equal(execution.context.legacyDistanceTargetDay, targetDay);
  assert.equal(execution.context.legacyDistanceCalculationTag, production.dayTagWithFoundationScar(calculationDay));
  assert.equal(execution.context.legacyDistanceTargetTag, production.dayTagWithFoundationScar(targetDay));
  assert.equal(execution.context.legacyDistanceOutput, execution.result);
}

assert.deepEqual(actual, [0n, 1n, 1n, 2n, 4n, 4n]);
assert.deepEqual(expected, [1n, 5n, 2n, 2n, 3n, 3n]);
assert.equal(production.oldDistance(f, f + 1n), 2n);

console.log('DISCOVERY 03: oldDistance mesura li diferentie inter tags in vice del distance cronologic inclusiv.');
console.log('pares:    ' + cases.map(([c, t]) => '(' + c + ',' + t + ')').join(', '));
console.log('legacy:   ' + actual.map(String).join(', '));
console.log('normativ: ' + expected.map(String).join(', '));
console.log('Un coincidence local resta visibil: Foundation a Foundation+1 rende 2 in ambi paths, ma li formule diverge in li altri casos.');

assert.deepEqual(
  actual,
  expected,
  'Li regression de Discovery 03 deve restar rubi: oldDistance ne es li distance cronologic inclusiv normativ.'
);
