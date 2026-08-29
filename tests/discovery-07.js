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
  return row === undefined || row === null ? row : [row.kind, row.a, row.b, row.c, row.d];
}

assert.equal(production.LEGACY_VISIBLE_GRIND_TABLE_ZERO_BASED.length, 11);
assert.deepEqual(
  production.LEGACY_VISIBLE_GRIND_TABLE_ZERO_BASED.map(rowShape),
  expected,
  'Li data del table legacy self deve conservar li undec rows normativ in ordine zero-based.'
);

const legacyActual = [];
const patchedActual = [];
for (let grind = 1; grind <= 11; grind += 1) {
  const legacyRoute = production.discovery07LegacyGrindRowThroughMonsterPath(1n, 1n, grind);
  assert.equal(legacyRoute.context.currentHandler, 'Discovery07GrindIndexHandler');
  assert.equal(legacyRoute.context.phase, 'DISCOVERY_07_LEGACY_GRIND_INDEX');
  assert.equal(legacyRoute.context.status, 'DISCOVERY_07_LEGACY_RESULT');
  assert.equal(legacyRoute.context.legacyGrindRequestedIndex, grind);
  assert.equal(legacyRoute.context.legacyGrindPhysicalIndex, grind);
  assert.equal(legacyRoute.context.legacyGrindMissing, grind === 11);
  assert.equal(legacyRoute.context.metrics['discovery07.legacyGrindIndex.calls'], 1n);
  legacyActual.push(rowShape(legacyRoute.result));

  const patchedRoute = production.historicGrindRowThroughMonsterPath(1n, 1n, grind);
  assert.equal(patchedRoute.context.legacyGrindRequestedIndex, grind);
  assert.equal(patchedRoute.context.legacyGrindPhysicalIndex, grind);
  assert.equal(patchedRoute.context.patch07RequestedIndex, grind);
  assert.equal(patchedRoute.context.patch07PhysicalIndex, grind);
  assert.equal(patchedRoute.context.patch07SentinelPreserved, true);
  assert.equal(patchedRoute.context.currentHandler, 'Patch07GrindSentinelWrapper');
  assert.equal(patchedRoute.context.phase, 'PATCH_07_GRIND_SENTINEL');
  assert.equal(patchedRoute.context.status, 'PATCH_07_RESULT');
  assert.equal(patchedRoute.context.metrics['discovery07.legacyGrindIndex.calls'], 1n);
  assert.equal(patchedRoute.context.metrics['patch07.grindSentinel.calls'], 1n);
  assert.deepEqual(patchedRoute.context.branchTrace, [
    'BOOTSTRAP_VALIDATED',
    'DISCOVERY_07_LEGACY_GRIND_INDEX',
    'PATCH_07_GRIND_SENTINEL'
  ]);
  patchedActual.push(rowShape(patchedRoute.result));
}

assert.deepEqual(legacyActual[0], expected[1]);
assert.deepEqual(legacyActual[9], expected[10]);
assert.equal(legacyActual[10], undefined);
assert.deepEqual(patchedActual, expected);

console.log('DISCOVERY 07 REGRESSION: PASS pos Patch 07; li legacy indexing resta deplazzat e li sentinel rende ordinals 1..11 exact.');
