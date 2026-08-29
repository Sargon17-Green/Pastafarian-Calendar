'use strict';

const assert = require('assert/strict');
const production = require('../src');
const normative = require('./normative-reference');

function expectedPours(drop, index, oldBowls, stoneRow) {
  const order = normative.bowlOrderFromDrop(drop);
  const pours = [null, 0n, 0n, 0n, 0n, 0n, 0n];
  pours[1] = production.savePatch(drop * drop + stoneRow.w * oldBowls[order[0]] + 3n * index);
  pours[2] = production.savePatch(drop * drop + stoneRow.b * oldBowls[order[1]] + 5n * index);
  pours[3] = production.savePatch(drop * drop + stoneRow.s * oldBowls[order[2]] + 7n * index);
  return { order, pours };
}

const oldBowls = [null, 11n, 13n, 17n, 19n, 23n, 29n];
const stoneRow = { w: 2n, b: 3n, s: 5n };
const originalBowls = oldBowls.slice();
const originalStone = { ...stoneRow };
const legacy = production.legacyPoursToFixedBowlIds(127n, 4n, oldBowls, stoneRow);
assert.deepEqual(legacy.pours.slice(1, 4), [16163n, 16188n, 16242n]);
assert.notDeepEqual(legacy.pours.slice(1, 4), expectedPours(127n, 4n, oldBowls, stoneRow).pours.slice(1, 4));

const alias = production.installBowlAlias([2, 1, 4, 3, 5, 6]);
assert.deepEqual(alias, [null, 2, 1, 4, 3, 5, 6]);
assert.equal(production.bowlAtLegacyPosition(oldBowls, alias, 1), 13n);
assert.equal(production.bowlAtLegacyPosition(oldBowls, alias, 2), 11n);
assert.equal(production.bowlAtLegacyPosition(oldBowls, alias, 3), 19n);

const legacySource = production.legacyPoursToFixedBowlIds.toString();
assert.match(legacySource, /oldBowls\[1\]/);
assert.match(legacySource, /oldBowls\[2\]/);
assert.match(legacySource, /oldBowls\[3\]/);
const patchSource = production.poursThroughBowlAlias.toString();
assert.match(patchSource, /legacyPoursToFixedBowlIds\(drop, index, oldBowls, stoneRow\)/, 'Li call legacy real deve restar in li helper de patch.');
assert.match(patchSource, /installBowlAlias\(order\)/);
for (const position of [1, 2, 3]) {
  assert.match(patchSource, new RegExp('bowlAtLegacyPosition\\(oldBowls, bowlAlias, ' + position + '\\)'));
}

for (let drop = 1n; drop <= 720n; drop += 1n) {
  for (const index of [1n, 4n, 23n, 46n]) {
    const actual = production.poursThroughBowlAlias(drop, index, oldBowls, stoneRow);
    const expected = expectedPours(drop, index, oldBowls, stoneRow);
    assert.deepEqual(actual.order, expected.order, 'Li order deve restar exact por drop ' + drop);
    assert.deepEqual(actual.bowlAlias.slice(1), expected.order, 'Li bowlAlias deve mappar positions al order por drop ' + drop);
    assert.deepEqual(actual.pours.slice(1, 4), expected.pours.slice(1, 4), 'Li pours aliased deve esser exact por drop ' + drop + ', index ' + index);
  }
}
assert.deepEqual(oldBowls, originalBowls);
assert.deepEqual(stoneRow, originalStone);

const routed = production.historicPoursThroughMonsterPath(1n, 1n, 127n, 4n, oldBowls, stoneRow);
assert.equal(routed.context.currentHandler, 'Patch09BowlAliasWrapper');
assert.equal(routed.context.previousHandler, 'Discovery09FixedPourHandler');
assert.equal(routed.context.phase, 'PATCH_09_BOWL_ALIAS');
assert.equal(routed.context.status, 'PATCH_09_RESULT');
assert.deepEqual(routed.context.legacyPourOutput.pours.slice(1, 4), [16163n, 16188n, 16242n]);
assert.deepEqual(routed.context.patch09BowlAlias, [null, 2, 1, 4, 3, 5, 6]);
assert.deepEqual(routed.context.patch09AliasedBowlIds, [2, 1, 4]);
assert.equal(routed.context.patch09LegacyCallPreserved, true);
assert.deepEqual(routed.result.pours.slice(1, 4), [16167n, 16182n, 16252n]);
assert.deepEqual(routed.context.branchTrace, [
  'BOOTSTRAP_VALIDATED',
  'DISCOVERY_09_POURS_TO_FIXED_BOWL_IDS',
  'PATCH_09_BOWL_ALIAS'
]);
assert.equal(routed.context.metrics['discovery09.fixedPour.calls'], 1n);
assert.equal(routed.context.metrics['patch09.bowlAlias.calls'], 1n);

assert.throws(() => production.installBowlAlias([1, 1, 2, 3, 4, 5]), RangeError);
assert.throws(() => production.bowlAtLegacyPosition(oldBowls, alias, 0), RangeError);
console.log('PATCH 09: PASS — li legacy fixed-bowl resta intact; omni read semantic de pour passa per bowlAlias[position]=order[position].');
