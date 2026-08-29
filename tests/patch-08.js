'use strict';

const assert = require('assert/strict');
const production = require('../src');
const normative = require('./normative-reference');

assert.deepEqual(production.oldPermutationUnrank0(0n), [1, 2, 3, 4, 5, 6]);
assert.deepEqual(production.oldPermutationUnrank0(719n), [6, 5, 4, 3, 2, 1]);
assert.deepEqual(production.legacyBowlOrderFromDrop(1n), [1, 2, 3, 4, 6, 5]);
assert.deepEqual(production.orderPatchFromValue(1n), [1, 2, 3, 4, 5, 6]);
assert.deepEqual(production.orderPatchFromValue(720n), [6, 5, 4, 3, 2, 1]);

const source = production.orderPatchFromValue.toString();
assert.match(source, /oneBased = regularMod\(value - 1n, 720n\) \+ 1n/);
assert.match(source, /legacyRank0 = oneBased - 1n/);
assert.match(source, /oldPermutationUnrank0\(legacyRank0\)/);

for (let drop = -1440n; drop <= 1440n; drop += 1n) {
  const expected = normative.bowlOrderFromDrop(drop);
  assert.deepEqual(production.orderPatchFromValue(drop), expected, 'Li bridge deve esser exact por drop ' + drop);
}

for (const drop of [1n, 2n, 3n, 719n, 721n, -1n, -719n]) {
  const execution = production.historicBowlOrderThroughMonsterPath(1n, 1n, drop);
  const oneBased = normative.regularMod(drop - 1n, 720n) + 1n;
  assert.deepEqual(execution.result, normative.bowlOrderFromDrop(drop));
  assert.equal(execution.context.currentHandler, 'Patch08PermutationWrapper');
  assert.equal(execution.context.previousHandler, 'Discovery08PermutationRankHandler');
  assert.equal(execution.context.phase, 'PATCH_08_ZERO_BASED_RANK_BRIDGE');
  assert.equal(execution.context.status, 'PATCH_08_RESULT');
  assert.equal(execution.context.patch08Drop, drop);
  assert.equal(execution.context.patch08OneBased, oneBased);
  assert.equal(execution.context.patch08LegacyRank0, oneBased - 1n);
  assert.deepEqual(execution.context.patch08Output, normative.bowlOrderFromDrop(drop));
  assert.deepEqual(execution.context.branchTrace, [
    'BOOTSTRAP_VALIDATED',
    'DISCOVERY_08_ONE_BASED_AS_RANK0',
    'PATCH_08_ZERO_BASED_RANK_BRIDGE'
  ]);
  assert.equal(execution.context.metrics['discovery08.legacyPermutationRank.calls'], 1n);
  assert.equal(execution.context.metrics['patch08.permutationRank.calls'], 1n);
}

assert.throws(() => production.orderPatchFromValue(1), TypeError);
console.log('PATCH 08: PASS — oldPermutationUnrank0 resta intact; oneBased es traductet per legacyRank0=oneBased-1 ante li call legacy.');
