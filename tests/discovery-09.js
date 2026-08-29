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

const primary = production.legacyPoursToFixedBowlIds(127n, index, oldBowls, stoneRow);
const primaryExpected = normativePours(127n);
assert.deepEqual(primary.order, [2, 1, 4, 3, 5, 6]);
assert.deepEqual(primary.pours.slice(1, 4), [16163n, 16188n, 16242n]);
assert.deepEqual(primaryExpected.pours.slice(1, 4), [16167n, 16182n, 16252n]);
assert.notDeepEqual(primary.pours.slice(1, 4), primaryExpected.pours.slice(1, 4));

const routed = production.discovery09LegacyFixedPoursThroughMonsterPath(
  normative.FOUNDATION_DAY,
  normative.FOUNDATION_DAY,
  127n,
  index,
  oldBowls,
  stoneRow
);
assert.equal(routed.context.currentHandler, 'Discovery09FixedPourHandler');
assert.equal(routed.context.phase, 'DISCOVERY_09_FIXED_BOWL_POURS');
assert.equal(routed.context.status, 'DISCOVERY_09_LEGACY_RESULT');
assert.equal(routed.context.legacyPourDrop, 127n);
assert.equal(routed.context.legacyPourIndex, index);
assert.deepEqual(routed.context.legacyPourOrder, [2, 1, 4, 3, 5, 6]);
assert.deepEqual(routed.context.legacyPourFixedBowlIds, [1, 2, 3]);
assert.deepEqual(routed.context.legacyPourOldBowls, oldBowls);
assert.deepEqual(routed.context.legacyPourStoneRow, stoneRow);
assert.deepEqual(routed.result.pours.slice(1, 4), [16163n, 16188n, 16242n]);
assert.deepEqual(routed.context.branchTrace, [
  'BOOTSTRAP_VALIDATED',
  'DISCOVERY_09_POURS_TO_FIXED_BOWL_IDS'
]);
assert.equal(routed.context.metrics['discovery09.fixedPour.calls'], 1n);

const legacyActual = [];
const normativeExpected = [];
for (const drop of drops) {
  const legacy = production.legacyPoursToFixedBowlIds(drop, index, oldBowls, stoneRow);
  const expected = normativePours(drop);
  assert.deepEqual(legacy.order, expected.order);
  legacyActual.push(legacy.pours.slice(1, 4));
  normativeExpected.push(expected.pours.slice(1, 4));
}

assert.deepEqual(
  legacyActual,
  normativeExpected,
  'Li regression de Discovery 09 deve restar rubi: li pours legacy usa bowl IDs fix 1,2,3 in vice de IDs selectet per position in order.'
);
