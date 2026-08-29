'use strict';

const assert = require('assert/strict');
const production = require('../src');
const normative = require('./normative-reference');

assert.deepEqual(production.oldPermutationUnrank0(0n), [1, 2, 3, 4, 5, 6]);
assert.deepEqual(production.oldPermutationUnrank0(719n), [6, 5, 4, 3, 2, 1]);
assert.throws(() => production.oldPermutationUnrank0(-1n), RangeError);
assert.throws(() => production.oldPermutationUnrank0(720n), RangeError);

const drops = [1n, 2n, 3n, 719n];
const legacyActual = [];
const legacyExpectedFromScar = [];
const normativeExpected = [];

for (const drop of drops) {
  const oneBased = normative.regularMod(drop - 1n, 720n) + 1n;
  const routed = production.discovery08LegacyBowlOrderThroughMonsterPath(1n, 1n, drop);
  assert.equal(routed.context.currentHandler, 'Discovery08PermutationRankHandler');
  assert.equal(routed.context.phase, 'DISCOVERY_08_LEGACY_PERMUTATION_RANK');
  assert.equal(routed.context.status, 'DISCOVERY_08_LEGACY_RESULT');
  assert.equal(routed.context.legacyPermutationDrop, drop);
  assert.equal(routed.context.legacyPermutationOneBased, oneBased);
  assert.equal(routed.context.legacyPermutationRankPassedToUnrank0, oneBased);
  assert.equal(routed.context.metrics['discovery08.legacyPermutationRank.calls'], 1n);
  assert.deepEqual(routed.context.branchTrace, [
    'BOOTSTRAP_VALIDATED',
    'DISCOVERY_08_ONE_BASED_AS_RANK0'
  ]);
  legacyActual.push(routed.result);
  legacyExpectedFromScar.push(normative.bowlOrderFromNumber(oneBased + 1n));
  normativeExpected.push(normative.bowlOrderFromDrop(drop));
}

assert.deepEqual(legacyActual, legacyExpectedFromScar, 'Li legacy route deve expor exactmen li shift rank0 mandat.');
assert.deepEqual(
  legacyActual,
  normativeExpected,
  'EXPECTED RED: li ordinal one-based es passat directmen a oldPermutationUnrank0; Patch 08 ne deve esser present in ti stage.'
);
