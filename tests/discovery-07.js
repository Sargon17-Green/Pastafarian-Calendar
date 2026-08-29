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

function rowShape(row) {
  return row === undefined ? undefined : [row.kind, row.a, row.b, row.c, row.d];
}

assert.equal(production.LEGACY_VISIBLE_GRIND_TABLE_ZERO_BASED.length, 11);
assert.deepEqual(
  production.LEGACY_VISIBLE_GRIND_TABLE_ZERO_BASED.map(rowShape),
  expected,
  'Li data del table legacy self deve conservar li deciun rows normativ in ordine zero-based.'
);

const actual = [];
for (let grind = 1; grind <= 11; grind += 1) {
  const routed = production.discovery07LegacyGrindRowThroughMonsterPath(1n, 1n, grind);
  assert.equal(routed.context.currentHandler, 'Discovery07GrindIndexHandler');
  assert.equal(routed.context.phase, 'DISCOVERY_07_LEGACY_GRIND_INDEX');
  assert.equal(routed.context.status, 'DISCOVERY_07_LEGACY_RESULT');
  assert.equal(routed.context.legacyGrindRequestedIndex, grind);
  assert.equal(routed.context.legacyGrindPhysicalIndex, grind);
  assert.equal(routed.context.legacyGrindMissing, grind === 11);
  assert.equal(routed.context.metrics['discovery07.legacyGrindIndex.calls'], 1n);
  assert.deepEqual(routed.context.branchTrace, [
    'BOOTSTRAP_VALIDATED',
    'DISCOVERY_07_LEGACY_GRIND_INDEX'
  ]);
  actual.push(rowShape(routed.result));
}

assert.deepEqual(actual[0], expected[1]);
assert.deepEqual(actual[9], expected[10]);
assert.equal(actual[10], undefined);

console.log('DISCOVERY 07 EXPECTED RED: li caller usa ordinals 1..11 quam indices direct in un table zero-based.');
console.log('legacy grind 1:  ' + String(actual[0]));
console.log('normativ grind 1:' + String(expected[0]));
console.log('legacy grind 11: ' + String(actual[10]));
console.log('normativ grind 11:' + String(expected[10]));

assert.deepEqual(
  actual,
  expected,
  'DISCOVERY 07 EXPECTED RED: grind 1 prende li duesim row e grind 11 cade ultra li table zero-based.'
);
