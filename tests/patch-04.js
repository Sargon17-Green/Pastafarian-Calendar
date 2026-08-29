'use strict';

const assert = require('assert/strict');
const production = require('../src');
const normative = require('./normative-reference');

function row(state) {
  return [state.w, state.b, state.s, state.m, state.r];
}

const initial = { w: 17n, b: 29n, s: 43n, m: 71n, r: 101n };
const original = { ...initial };
const legacyProbe = production.mutateStonesWrong(2n, { ...initial });
assert.deepEqual(row(legacyProbe), [378n, 1434n, 3780n, 9932n, 25047n]);
assert.notDeepEqual(row(legacyProbe), normative.STONES[1]);

const patched = production.stonePatch(2n, initial);
assert.deepEqual(initial, original, 'stonePatch ne deve mutar li statu fonte.');
assert.deepEqual(row(patched), normative.STONES[1]);
assert.notEqual(patched, initial);

const source = production.stonePatch.toString();
assert.match(source, /mutateStonesWrong\(index, cloneStoneState\(state\)\)/, 'Li call legacy deve restar fisicmen in stonePatch.');
assert.match(source, /const old = cloneStoneState\(state\)/, 'Li snapshot old deve esser creat ante li overwrite.');
for (const key of ['w', 'b', 's', 'm', 'r']) {
  assert.match(source, new RegExp('garbage\\.' + key + ' = savePatch\\('), 'Omni quin resultates deve esser superscrit: ' + key);
}

const table = production.getStoneTableThroughLegacyBuilder();
assert.equal(table.length, 46);
for (let i = 0; i < 46; i += 1) {
  assert.deepEqual(row(table[i]), normative.STONES[i], 'Li row ' + (i + 1) + ' del builder legacy reparat deve concordar exactmen.');
  if (i > 0) assert.notEqual(table[i], table[i - 1], 'Li rows del table deve esser copies separat.');
}

const f = normative.FOUNDATION_DAY;
const execution = production.historicStoneMutationThroughMonsterPath(f, f, 2n, initial);
assert.deepEqual(row(execution.result), normative.STONES[1]);
assert.equal(execution.context.currentHandler, 'Patch04StoneWrapper');
assert.equal(execution.context.phase, 'PATCH_04_SNAPSHOT_OVERWRITE');
assert.equal(execution.context.status, 'PATCH_04_RESULT');
assert.deepEqual(execution.context.branchTrace, [
  'BOOTSTRAP_VALIDATED',
  'DISCOVERY_04_MUTATE_STONES_WRONG',
  'PATCH_04_STONE_SNAPSHOT_OVERWRITE'
]);
assert.deepEqual(execution.context.patch04OldSnapshot, initial);
assert.deepEqual(execution.context.patch04LegacyGarbageBeforeOverwrite, {
  w: 378n, b: 1434n, s: 3780n, m: 9932n, r: 25047n
});
assert.equal(execution.context.patch04LegacyCallPreserved, true);
assert.deepEqual(row(execution.context.patch04Output), normative.STONES[1]);
assert.equal(execution.context.metrics['discovery04.legacyStoneMutation.calls'], 1n);
assert.equal(execution.context.metrics['patch04.stoneSnapshot.calls'], 1n);

const syntheticStates = [
  { w: 1n, b: 2n, s: 3n, m: 4n, r: 5n },
  { w: 13n, b: 17n, s: 19n, m: 23n, r: 29n },
  { w: normative.M, b: normative.M - 1n, s: 7n, m: 11n, r: 31n }
];
for (const state of syntheticStates) {
  for (let index = 2n; index <= 9n; index += 1n) {
    const old = { ...state };
    const expected = {
      w: production.savePatch(old.w * old.w + 3n * old.b + index),
      b: production.savePatch(old.b * old.b + 5n * old.s + old.w),
      s: production.savePatch(old.s * old.s + 7n * old.m + old.b),
      m: production.savePatch(old.m * old.m + 11n * old.r + old.s),
      r: production.savePatch(old.r * old.r + 13n * old.w + old.m)
    };
    const actual = production.stonePatch(index, state);
    assert.deepEqual(actual, expected);
    assert.deepEqual(state, old);
  }
}

console.log('PATCH 04: PASS — mutateStonesWrong resta intact e es realmen vocat, ma omni quin outputs es superscrit ex li snapshot old.');
console.log('Li builder legacy reparat rende omni 46 rows exactmen quam li table normativ.');
