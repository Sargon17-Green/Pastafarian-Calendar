'use strict';

const assert = require('assert/strict');
const production = require('../src');
const normative = require('./normative-reference');

const calculationDay = normative.FOUNDATION_DAY;
const targetDay = normative.FOUNDATION_DAY;
const counts = normative.workCounts(calculationDay, targetDay);
const stones = production.getStoneTableThroughLegacyBuilder();
const expected = normative.sauce(calculationDay, targetDay);

const legacy = production.legacySauceWithOverwritableOrderMemory(counts, stones);
assert.equal(legacy.orderWriteCount, 58);
assert.deepEqual(legacy.lastSource, { kind: 'post-stir', ordinal: 12 });
assert.deepEqual(legacy.queryOrder, legacy.lastPostStirOrder);
assert.notDeepEqual(legacy.queryOrder, expected.orderAtDrop46);

const patched = production.sauceWithOrderAt46Latch(counts, stones);
assert.equal(patched.legacyGarbage.orderWriteCount, 58);
assert.deepEqual(patched.legacyGarbage.queryOrder, legacy.queryOrder);
assert.deepEqual(patched.legacyGarbage.legacyOrderMemory, legacy.legacyOrderMemory);
assert.deepEqual(patched.orderAt46Latch, expected.orderAtDrop46);
assert.deepEqual(patched.orderAt46BeforePostStirs, expected.orderAtDrop46);
assert.equal(patched.orderAt46LatchWriteCount, 1);
assert.deepEqual(patched.orderAt46LatchSource, { kind: 'drop', ordinal: 46 });
assert.equal(patched.orderWriteCount, 58, 'Li memorie legacy deve continuar reciver 58 writes anc intra li path reparat.');
assert.deepEqual(patched.lastSource, { kind: 'post-stir', ordinal: 12 });
assert.deepEqual(patched.legacyOrderMemory, patched.lastPostStirOrder);
assert.deepEqual(patched.queryOrder, expected.orderAtDrop46);
assert.deepEqual(patched.bowls.slice(1), expected.bowls);

const latch = production.createOrderAt46LatchState();
const firstWrite = production.writeOrderAt46LatchOnce(latch, [1, 2, 3, 4, 5, 6]);
assert.deepEqual(firstWrite, [1, 2, 3, 4, 5, 6]);
firstWrite[0] = 6;
assert.deepEqual(production.readOrderAt46Latch(latch), [1, 2, 3, 4, 5, 6], 'Li read deve retornar un copie fisic del latch.');
assert.throws(
  () => production.writeOrderAt46LatchOnce(latch, [6, 5, 4, 3, 2, 1]),
  production.BootstrapStageError,
  'Un duesim write al latch deve esser rejectet.'
);
assert.equal(latch.writeCount, 1);

const legacySource = production.legacySauceWithOverwritableOrderMemory.toString();
assert.doesNotMatch(legacySource, /orderAt46Latch|writeOrderAt46LatchOnce|readOrderAt46Latch/);
assert.match(legacySource, /legacyOrderMemory = round.order.slice()/);
assert.match(legacySource, /queryOrder: legacyOrderMemory\.slice\(\)/);

const patchSource = production.sauceWithOrderAt46Latch.toString();
assert.match(patchSource, /legacySauceWithOverwritableOrderMemory\(counts, stones\)/);
assert.match(patchSource, /writeOrderAt46LatchOnce\(latchState, round\.order\)/);
assert.match(patchSource, /const orderAt46BeforePostStirs = readOrderAt46Latch\(latchState\)/);
assert.match(patchSource, /queryOrder: readOrderAt46Latch\(latchState\)/);
const latchWriteAt = patchSource.indexOf('writeOrderAt46LatchOnce(latchState, round.order)');
const postStirLoopAt = patchSource.indexOf('for (let stir = 1; stir <= 12; stir += 1)');
assert.ok(latchWriteAt >= 0 && postStirLoopAt > latchWriteAt, 'Li latch deve esser scrit ante li prim post-stir.');
assert.equal(
  (patchSource.match(/writeOrderAt46LatchOnce\(latchState, round\.order\)/g) || []).length,
  1,
  'Li path semantic deve contener un unic write-site al latch.'
);

const routed = production.historicOrderAt46ThroughMonsterPath(calculationDay, targetDay, counts, stones);
assert.equal(routed.context.currentHandler, 'Patch11OrderAt46LatchWrapper');
assert.equal(routed.context.previousHandler, 'Discovery11OverwrittenOrderHandler');
assert.equal(routed.context.phase, 'PATCH_11_ORDER_AT_46_LATCH');
assert.equal(routed.context.status, 'PATCH_11_RESULT');
assert.equal(routed.context.patch11LegacyCallPreserved, true);
assert.deepEqual(routed.context.patch11LegacyGarbage.queryOrder, legacy.queryOrder);
assert.deepEqual(routed.context.patch11OrderAt46Latch, expected.orderAtDrop46);
assert.equal(routed.context.patch11OrderAt46LatchWriteCount, 1);
assert.deepEqual(routed.context.patch11OrderAt46LatchSource, { kind: 'drop', ordinal: 46 });
assert.equal(routed.context.patch11LegacyOrderMemoryWriteCount, 58);
assert.deepEqual(routed.context.patch11LegacyOrderMemoryLastSource, { kind: 'post-stir', ordinal: 12 });
assert.deepEqual(routed.context.patch11LegacyOrderMemory, routed.context.patch11LastPostStirOrder);
assert.deepEqual(routed.context.patch11QueryOrder, expected.orderAtDrop46);
assert.deepEqual(routed.result.queryOrder, expected.orderAtDrop46);
assert.deepEqual(routed.result.bowls.slice(1), expected.bowls);
assert.deepEqual(routed.context.branchTrace, [
  'BOOTSTRAP_VALIDATED',
  'DISCOVERY_11_OVERWRITABLE_ORDER_MEMORY',
  'PATCH_11_ORDER_AT_46_LATCH'
]);
assert.equal(routed.context.metrics['discovery11.overwritableOrder.calls'], 1n);
assert.equal(routed.context.metrics['patch11.orderAt46Latch.calls'], 1n);

console.log('PATCH 11: PASS — li memorie legacy continua 58 writes; orderAt46Latch es clonat un vez pos drop 46, ne es superscrit e deven li unic fonte de queryOrder.');
