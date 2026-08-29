'use strict';

const assert = require('assert/strict');
const production = require('../src');
const normative = require('./normative-reference');

const f = normative.FOUNDATION_DAY;
const initial = { w: 17n, b: 29n, s: 43n, m: 71n, r: 101n };
const legacyExecution = production.discovery04LegacyStoneMutationThroughMonsterPath(f, f, 2n, initial);
const legacy = [
  legacyExecution.result.w, legacyExecution.result.b, legacyExecution.result.s,
  legacyExecution.result.m, legacyExecution.result.r
];
const expected = normative.STONES[1].slice();

assert.equal(legacyExecution.context.currentHandler, 'Discovery04StoneMutationHandler');
assert.equal(legacyExecution.context.phase, 'DISCOVERY_04_SEQUENTIAL_STONE_MUTATION');
assert.equal(legacyExecution.context.status, 'DISCOVERY_04_LEGACY_RESULT');
assert.equal(legacyExecution.context.legacyStoneIndex, 2n);
assert.deepEqual(legacyExecution.context.legacyStoneInputBefore, initial);
assert.equal(legacyExecution.context.legacyStoneReturnedSameObject, true);
assert.equal(legacyExecution.context.metrics['discovery04.legacyStoneMutation.calls'], 1n);
assert.deepEqual(legacyExecution.context.branchTrace, [
  'BOOTSTRAP_VALIDATED',
  'DISCOVERY_04_MUTATE_STONES_WRONG'
]);
assert.deepEqual(legacy, [378n, 1434n, 3780n, 9932n, 25047n]);
assert.deepEqual(expected, [378n, 1073n, 2375n, 6195n, 10493n]);
assert.equal(legacy[0], expected[0]);
assert.notDeepEqual(legacy.slice(1), expected.slice(1));

const patchedExecution = production.historicStoneMutationThroughMonsterPath(f, f, 2n, initial);
const patched = [
  patchedExecution.result.w, patchedExecution.result.b, patchedExecution.result.s,
  patchedExecution.result.m, patchedExecution.result.r
];
assert.deepEqual(patched, expected);
assert.deepEqual(patchedExecution.context.patch04LegacyGarbageBeforeOverwrite, {
  w: 378n, b: 1434n, s: 3780n, m: 9932n, r: 25047n
});
assert.equal(patchedExecution.context.patch04LegacyCallPreserved, true);

console.log('DISCOVERY 04 REGRESSION: PASS pos Patch 04; mutateStonesWrong resta divergent e li snapshot-overwrite rende li transition normativ.');
console.log('legacy:   ' + legacy.map(String).join(', '));
console.log('reparat:  ' + patched.map(String).join(', '));
console.log('normativ: ' + expected.map(String).join(', '));
