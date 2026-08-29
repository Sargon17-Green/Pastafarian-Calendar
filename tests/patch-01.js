'use strict';

const assert = require('assert/strict');
const production = require('../src');
const normative = require('./normative-reference');

const values = [
  -3n * normative.M,
  -2n * normative.M,
  -normative.M,
  0n,
  1n,
  normative.M - 1n,
  normative.M,
  normative.M + 1n,
  2n * normative.M,
  3n * normative.M
];

for (const value of values) {
  assert.equal(production.savePatch(value), normative.SAVE(value));
}

assert.equal(production.oldRemainder(normative.M), 0n);
assert.equal(production.oldRemainder(2n * normative.M), 0n);
assert.equal(production.oldRemainder(3n * normative.M), 0n);
assert.equal(production.savePatch(normative.M), normative.M);
assert.equal(production.savePatch(2n * normative.M), normative.M);
assert.equal(production.savePatch(3n * normative.M), normative.M);

const execution = production.historicRemainderThroughMonsterPath(
  normative.FOUNDATION_DAY,
  normative.FOUNDATION_DAY,
  2n * normative.M
);
assert.deepEqual(execution.context.branchTrace, [
  'BOOTSTRAP_VALIDATED',
  'DISCOVERY_01_OLD_REMAINDER',
  'PATCH_01_SAVE_ZERO_REMAP'
]);
assert.equal(execution.context.legacyRemainderOutput, 0n);
assert.equal(execution.context.patch01LegacyWasZero, true);
assert.equal(execution.result, normative.M);
assert.equal(execution.context.metrics['discovery01.legacyRemainder.calls'], 1n);
assert.equal(execution.context.metrics['patch01.save.calls'], 1n);

console.log('PATCH 01: PASS — li legacy resta intact e li remappage zero->M es exactmen equivalent a SAVE.');
