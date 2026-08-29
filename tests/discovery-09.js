'use strict';

const assert = require('assert/strict');
const production = require('../src');
const normative = require('./normative-reference');

const oldBowls = [null, 11n, 13n, 17n, 19n, 23n, 29n];
const stoneRow = { w: 2n, b: 3n, s: 5n };
const index = 4n;
const drops = [1n, 127n, 241n, 720n];

function normativePours(drop) {
  const order = normative.bowlOrderFromDrop(drop);
  const pours = [null, 0n, 0n, 0n, 0n, 0n, 0n];
  pours[1] = production.savePatch(drop * drop + stoneRow.w * oldBowls[order[0]] + 3n * index);
  pours[2] = production.savePatch(drop * drop + stoneRow.b * oldBowls[order[1]] + 5n * index);
  pours[3] = production.savePatch(drop * drop + stoneRow.s * oldBowls[order[2]] + 7n * index);
  return { order, pours };
}

const identityLegacy = production.legacyPoursToFixedBowlIds(1n, index, oldBowls, stoneRow);
const identityExpected = normativePours(1n);
assert.deepEqual(identityLegacy.order, [1, 2, 3, 4, 5, 6]);
assert.deepEqual(identityLegacy.pours.slice(1, 4), identityExpected.pours.slice(1, 4));

const primaryLegacy = production.legacyPoursToFixedBowlIds(127n, index, oldBowls, stoneRow);
const primaryExpected = normativePours(127n);
assert.deepEqual(primaryLegacy.order, [2, 1, 4, 3, 5, 6]);
assert.deepEqual(primaryLegacy.pours.slice(1, 4), [16163n, 16188n, 16242n]);
assert.deepEqual(primaryExpected.pours.slice(1, 4), [16167n, 16182n, 16252n]);
assert.notDeepEqual(primaryLegacy.pours.slice(1, 4), primaryExpected.pours.slice(1, 4));

const routed = production.historicPoursThroughMonsterPath(
  normative.FOUNDATION_DAY,
  normative.FOUNDATION_DAY,
  127n,
  index,
  oldBowls,
  stoneRow
);
assert.equal(routed.context.currentHandler, 'Patch09BowlAliasWrapper');
assert.equal(routed.context.previousHandler, 'Discovery09FixedPourHandler');
assert.equal(routed.context.phase, 'PATCH_09_BOWL_ALIAS');
assert.equal(routed.context.status, 'PATCH_09_RESULT');
assert.deepEqual(routed.context.legacyPourOutput.pours.slice(1, 4), [16163n, 16188n, 16242n]);
assert.deepEqual(routed.context.patch09BowlAlias, [null, 2, 1, 4, 3, 5, 6]);
assert.deepEqual(routed.context.patch09AliasedBowlIds, [2, 1, 4]);
assert.equal(routed.context.patch09LegacyCallPreserved, true);
assert.deepEqual(routed.result.pours.slice(1, 4), primaryExpected.pours.slice(1, 4));
assert.deepEqual(routed.context.branchTrace, [
  'BOOTSTRAP_VALIDATED',
  'DISCOVERY_09_POURS_TO_FIXED_BOWL_IDS',
  'PATCH_09_BOWL_ALIAS'
]);
assert.equal(routed.context.metrics['discovery09.fixedPour.calls'], 1n);
assert.equal(routed.context.metrics['patch09.bowlAlias.calls'], 1n);

for (const drop of drops) {
  const legacy = production.legacyPoursToFixedBowlIds(drop, index, oldBowls, stoneRow);
  const expected = normativePours(drop);
  const patched = production.poursThroughBowlAlias(drop, index, oldBowls, stoneRow);
  assert.deepEqual(legacy.order, expected.order);
  assert.deepEqual(patched.order, expected.order);
  assert.deepEqual(patched.pours.slice(1, 4), expected.pours.slice(1, 4));
}

console.log('DISCOVERY 09 REGRESSION: PASS pos Patch 09; li legacy resta ligat a IDs fix e li route semantic lee per bowlAlias.');
