'use strict';

const assert = require('assert/strict');
const production = require('../src');

const expected = [
  ['w', 3n, 5n, 7n, 11n],
  ['b', 5n, 7n, 11n, 13n],
  ['s', 7n, 11n, 13n, 17n],
  ['m', 11n, 13n, 17n, 19n],
  ['r', 13n, 17n, 19n, 23n],
  ['w', 17n, 19n, 23n, 29n],
  ['b', 19n, 23n, 29n, 31n],
  ['s', 23n, 29n, 31n, 37n],
  ['m', 29n, 31n, 37n, 41n],
  ['r', 31n, 37n, 41n, 43n],
  ['w', 37n, 41n, 43n, 47n]
];

function shape(row) {
  return row === undefined || row === null ? row : [row.kind, row.a, row.b, row.c, row.d];
}

assert.equal(production.LEGACY_VISIBLE_GRIND_TABLE_ZERO_BASED.length, 11);
assert.equal(production.GRIND_TABLE_WITH_SENTINEL.length, 12);
assert.equal(production.GRIND_TABLE_WITH_SENTINEL[0], null, 'Li sentinel deve restar in index 0.');
assert.equal(Object.isFrozen(production.GRIND_TABLE_WITH_SENTINEL), true);
assert.deepEqual(production.GRIND_TABLE_WITH_SENTINEL.slice(1).map(shape), expected);

assert.deepEqual(shape(production.legacyGrindRow(1)), expected[1]);
assert.equal(production.legacyGrindRow(11), undefined);
for (let grind = 1; grind <= 11; grind += 1) {
  assert.deepEqual(shape(production.grindRowWithSentinel(grind)), expected[grind - 1]);
}

const source = production.grindRowWithSentinel.toString();
assert.match(source, /GRIND_TABLE_WITH_SENTINEL\[grind\]/, 'Li lookup reparat deve conservar li ordinal one-based quam index direct.');

for (let grind = 1; grind <= 11; grind += 1) {
  const routed = production.historicGrindRowThroughMonsterPath(1n, 1n, grind);
  assert.deepEqual(shape(routed.result), expected[grind - 1]);
  assert.equal(routed.context.patch07RequestedIndex, grind);
  assert.equal(routed.context.patch07PhysicalIndex, grind);
  assert.equal(routed.context.patch07SentinelPreserved, true);
  assert.equal(routed.context.currentHandler, 'Patch07GrindSentinelWrapper');
  assert.equal(routed.context.status, 'PATCH_07_RESULT');
  assert.equal(routed.context.metrics['patch07.grindSentinel.calls'], 1n);
}

const last = production.historicGrindRowThroughMonsterPath(1n, 1n, 11);
assert.equal(last.context.legacyGrindOutput, undefined);
assert.equal(last.context.legacyGrindMissing, true);
assert.deepEqual(shape(last.context.patch07Output), expected[10]);
assert.deepEqual(last.context.branchTrace, [
  'BOOTSTRAP_VALIDATED',
  'DISCOVERY_07_LEGACY_GRIND_INDEX',
  'PATCH_07_GRIND_SENTINEL'
]);

console.log('PATCH 07: PASS — li sentinel resta fisicmen a index 0 e li undec grinds real ocupa indices 1..11.');
console.log('legacyGrindRow resta intact e continua expor li displacement historic.');
