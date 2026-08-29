'use strict';

const assert = require('assert/strict');
const production = require('../src');
const normative = require('./normative-reference');

const f = normative.FOUNDATION_DAY;
const initial = { w: 17n, b: 29n, s: 43n, m: 71n, r: 101n };
const execution = production.discovery04LegacyStoneMutationThroughMonsterPath(f, f, 2n, initial);
const actual = [
  execution.result.w, execution.result.b, execution.result.s, execution.result.m, execution.result.r
];
const expected = normative.STONES[1].slice();

assert.equal(execution.context.currentHandler, 'Discovery04StoneMutationHandler');
assert.equal(execution.context.phase, 'DISCOVERY_04_SEQUENTIAL_STONE_MUTATION');
assert.equal(execution.context.status, 'DISCOVERY_04_LEGACY_RESULT');
assert.equal(execution.context.legacyStoneIndex, 2n);
assert.deepEqual(execution.context.legacyStoneInputBefore, initial);
assert.equal(execution.context.legacyStoneReturnedSameObject, true);
assert.equal(execution.context.metrics['discovery04.legacyStoneMutation.calls'], 1n);
assert.deepEqual(execution.context.branchTrace, [
  'BOOTSTRAP_VALIDATED',
  'DISCOVERY_04_MUTATE_STONES_WRONG'
]);
assert.deepEqual(actual, [378n, 1434n, 3780n, 9932n, 25047n]);
assert.deepEqual(expected, [378n, 1073n, 2375n, 6195n, 10493n]);
assert.equal(actual[0], expected[0]);
assert.notDeepEqual(actual.slice(1), expected.slice(1));

console.log('DISCOVERY 04 EXPECTED RED: mutateStonesWrong usa valores ja mutat durant li sam passu.');
console.log('legacy:   ' + actual.map(String).join(', '));
console.log('normativ: ' + expected.map(String).join(', '));

assert.deepEqual(
  actual,
  expected,
  'EXPECTED RED Discovery 04: li mutation sequential in-place diverge del transition simultan normativ.'
);
