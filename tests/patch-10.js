'use strict';

const assert = require('assert/strict');
const production = require('../src');
const normative = require('./normative-reference');

const stirStoneByPosition = [null, 'w', 'b', 's', 'm', 'r', 'w'];

function expectedRound(drop, index, sourceBowls, stoneRow) {
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
    nextBowls[bowlId] = normative.SAVE(
      s * s + 5n * old[prevId] * old[nextId] + index * BigInt(position)
    );
  }
  return { order, pours, bowls: nextBowls };
}

const oldBowls = [null, 11n, 13n, 17n, 19n, 23n, 29n];
const stoneRow = { w: 2n, b: 3n, s: 5n, m: 7n, r: 11n };
const originalBowls = oldBowls.slice();
const originalStone = { ...stoneRow };

const legacyMutable = oldBowls.slice();
const legacy = production.legacyStirOneDropInPlace(1n, 4n, legacyMutable, stoneRow);
const expectedIdentity = expectedRound(1n, 4n, oldBowls, stoneRow);
assert.equal(legacy.bowls, legacyMutable);
assert.notDeepEqual(legacy.bowls, expectedIdentity.bowls);

const patchedIdentity = production.stirOneDropViaShadow(1n, 4n, oldBowls, stoneRow);
assert.deepEqual(patchedIdentity.vaultOld, oldBowls);
assert.deepEqual(patchedIdentity.pending, expectedIdentity.bowls);
assert.deepEqual(patchedIdentity.bowls, expectedIdentity.bowls);
assert.deepEqual(patchedIdentity.order, expectedIdentity.order);
assert.deepEqual(patchedIdentity.pours, expectedIdentity.pours);
assert.deepEqual(patchedIdentity.legacyGarbage.bowls, legacy.bowls);
assert.deepEqual(oldBowls, originalBowls);
assert.deepEqual(stoneRow, originalStone);

const legacySource = production.legacyStirOneDropInPlace.toString();
assert.match(legacySource, /bowls\[bowlId\] = savePatch\(/);
assert.match(legacySource, /2n \* bowls\[prevId\]/);
assert.match(legacySource, /3n \* bowls\[nextId\]/);
assert.doesNotMatch(legacySource, /vaultOld|pending/);

const patchSource = production.stirOneDropViaShadow.toString();
assert.match(patchSource, /legacyStirOneDropInPlace\(drop, index, bowls\.slice\(\), stoneRow\)/);
assert.match(patchSource, /const vaultOld = bowls\.slice\(\)/);
assert.match(patchSource, /const pending = new Array\(7\)\.fill\(null\)/);
assert.match(patchSource, /vaultOld\[bowlId\]/);
assert.match(patchSource, /vaultOld\[prevId\]/);
assert.match(patchSource, /vaultOld\[nextId\]/);
assert.match(patchSource, /pending\[bowlId\] = savePatch\(/);
const pendingWriteAt = patchSource.indexOf('pending[bowlId] = savePatch(');
const commitAt = patchSource.indexOf('const committed = pending.slice()');
assert.ok(pendingWriteAt >= 0 && commitAt > pendingWriteAt, 'Li commit deve aparir solmen pos li loop quel scri pending.');

for (let drop = 1n; drop <= 720n; drop += 1n) {
  for (const index of [1n, 4n, 23n, 46n]) {
    const expected = expectedRound(drop, index, oldBowls, stoneRow);
    const actual = production.stirOneDropViaShadow(drop, index, oldBowls, stoneRow);
    assert.deepEqual(actual.order, expected.order, 'Li order deve esser exact por drop ' + drop);
    assert.deepEqual(actual.pours, expected.pours, 'Li pours deve esser exact por drop ' + drop + ', index ' + index);
    assert.deepEqual(actual.vaultOld, oldBowls, 'vaultOld deve restar li snapshot original.');
    assert.deepEqual(actual.pending, expected.bowls, 'pending deve contener omni six outputs exact ante commit.');
    assert.deepEqual(actual.bowls, expected.bowls, 'Li commit final deve esser exact por drop ' + drop + ', index ' + index);
  }
}

const routed = production.historicBowlRoundThroughMonsterPath(1n, 1n, 1n, 4n, oldBowls, stoneRow);
assert.equal(routed.context.currentHandler, 'Patch10ShadowBowlWrapper');
assert.equal(routed.context.previousHandler, 'Discovery10InPlaceBowlHandler');
assert.equal(routed.context.phase, 'PATCH_10_VAULT_PENDING_COMMIT');
assert.equal(routed.context.status, 'PATCH_10_RESULT');
assert.equal(routed.context.patch10LegacyCallPreserved, true);
assert.deepEqual(routed.context.patch10LegacyGarbage.bowls, legacy.bowls);
assert.deepEqual(routed.context.patch10VaultOld, oldBowls);
assert.deepEqual(routed.context.patch10Pending, expectedIdentity.bowls);
assert.equal(routed.context.patch10CommitAfterAllSix, true);
assert.deepEqual(routed.result.bowls, expectedIdentity.bowls);
assert.deepEqual(routed.context.branchTrace, [
  'BOOTSTRAP_VALIDATED',
  'DISCOVERY_10_BOWLS_IN_PLACE',
  'PATCH_10_VAULT_PENDING_COMMIT'
]);
assert.equal(routed.context.metrics['discovery10.inPlaceBowl.calls'], 1n);
assert.equal(routed.context.metrics['patch10.shadowBowl.calls'], 1n);

assert.throws(() => production.stirOneDropViaShadow(1n, 0n, oldBowls, stoneRow), RangeError);
assert.throws(() => production.stirOneDropViaShadow(1, 1n, oldBowls, stoneRow), TypeError);
console.log('PATCH 10: PASS — legacy in-place resta intact; vaultOld alimenta omni reads, pending recive omni six writes e commit evene solmen pos li round complet.');
