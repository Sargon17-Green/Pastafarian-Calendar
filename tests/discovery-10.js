'use strict';

const assert = require('assert/strict');
const production = require('../src');
const normative = require('./normative-reference');

const oldBowls = [null, 11n, 13n, 17n, 19n, 23n, 29n];
const stoneRow = { w: 2n, b: 3n, s: 5n, m: 7n, r: 11n };
const drop = 1n;
const index = 4n;
const stirStoneByPosition = [null, 'w', 'b', 's', 'm', 'r', 'w'];

function normativeRound(sourceBowls) {
  const old = sourceBowls.slice();
  const order = normative.bowlOrderFromDrop(drop);
  const pours = [null, 0n, 0n, 0n, 0n, 0n, 0n];
  pours[1] = normative.SAVE(drop * drop + stoneRow.w * old[order[0]] + 3n * index);
  pours[2] = normative.SAVE(drop * drop + stoneRow.b * old[order[1]] + 5n * index);
  pours[3] = normative.SAVE(drop * drop + stoneRow.s * old[order[2]] + 7n * index);
  const nextBowls = new Array(7).fill(null);
  for (let position = 1; position <= 6; position += 1) {
    const bowlId = order[position - 1];
    const prevId = order[(position + 4) % 6];
    const nextId = order[position % 6];
    const s = old[bowlId]
      + 2n * old[prevId]
      + 3n * old[nextId]
      + pours[position]
      + drop
      + stoneRow[stirStoneByPosition[position]];
    nextBowls[bowlId] = normative.SAVE(s * s + 5n * old[prevId] * old[nextId] + index * BigInt(position));
  }
  return { order, pours, bowls: nextBowls };
}

const expected = normativeRound(oldBowls);
assert.deepEqual(expected.order, [1, 2, 3, 4, 5, 6]);
assert.deepEqual(expected.bowls.slice(1), [23205n, 23443n, 49647n, 18871n, 28375n, 13610n]);

const mutable = oldBowls.slice();
const direct = production.legacyStirOneDropInPlace(drop, index, mutable, stoneRow);
assert.equal(direct.bowls, mutable, 'Li helper legacy deve mutar e retornar li sam vector de bowls.');
assert.deepEqual(direct.bowls.slice(1), [
  23205n,
  2167757877n,
  18796698741299337031n,
  52134066600902479800271676581807921729n,
  49276137518158613509478075707571518903n,
  122328037836810514334452521434516846956n
]);
assert.notDeepEqual(direct.bowls, expected.bowls);

const routed = production.historicBowlRoundThroughMonsterPath(
  normative.FOUNDATION_DAY, normative.FOUNDATION_DAY, drop, index, oldBowls, stoneRow
);
assert.equal(routed.context.currentHandler, 'Patch10ShadowBowlWrapper');
assert.equal(routed.context.previousHandler, 'Discovery10InPlaceBowlHandler');
assert.equal(routed.context.phase, 'PATCH_10_VAULT_PENDING_COMMIT');
assert.equal(routed.context.status, 'PATCH_10_RESULT');
assert.equal(routed.context.legacyBowlRoundReturnedSameObject, true);
assert.deepEqual(routed.context.legacyBowlRoundOutput, direct.bowls);
assert.equal(routed.context.patch10LegacyCallPreserved, true);
assert.deepEqual(routed.context.patch10LegacyGarbage.bowls, direct.bowls);
assert.deepEqual(routed.context.patch10VaultOld, oldBowls);
assert.deepEqual(routed.context.patch10Pending, expected.bowls);
assert.equal(routed.context.patch10CommitAfterAllSix, true);
assert.deepEqual(routed.result.bowls, expected.bowls);
assert.deepEqual(routed.context.branchTrace, [
  'BOOTSTRAP_VALIDATED',
  'DISCOVERY_10_BOWLS_IN_PLACE',
  'PATCH_10_VAULT_PENDING_COMMIT'
]);
assert.equal(routed.context.metrics['discovery10.inPlaceBowl.calls'], 1n);
assert.equal(routed.context.metrics['patch10.shadowBowl.calls'], 1n);
assert.deepEqual(oldBowls, [null, 11n, 13n, 17n, 19n, 23n, 29n]);

console.log('DISCOVERY 10 REGRESSION: PASS pos Patch 10; li legacy resta contaminat in-place e li route semantic usa vaultOld/pending con commit pos six writes.');
