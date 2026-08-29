'use strict';

const assert = require('assert/strict');
const production = require('../src');
const normative = require('./normative-reference');

const calculationDay = normative.FOUNDATION_DAY;
const targetDay = normative.FOUNDATION_DAY;
const counts = normative.workCounts(calculationDay, targetDay);
const stones = production.getStoneTableThroughLegacyBuilder();
const expected = normative.sauce(calculationDay, targetDay);

const direct = production.legacySauceWithOverwritableOrderMemory(counts, stones);
assert.deepEqual(direct.bowls.slice(1), expected.bowls, 'Li six bowls final deve restar exact anc in li scar legacy.');
assert.deepEqual(direct.drop46OrderDiagnostic, expected.orderAtDrop46);
assert.equal(direct.orderWriteCount, 58);
assert.deepEqual(direct.lastSource, { kind: 'post-stir', ordinal: 12 });
assert.deepEqual(direct.queryOrder, direct.lastPostStirOrder);
const legacyMismatchPositions = [1, 2, 6].filter(
  (position) => direct.queryOrder[position - 1] !== expected.orderAtDrop46[position - 1]
);
assert.deepEqual(legacyMismatchPositions, [1, 2, 6], 'Li scar legacy deve restar defectiv exactmen a ti witness.');

const routed = production.historicOrderAt46ThroughMonsterPath(
  calculationDay,
  targetDay,
  counts,
  stones
);
assert.equal(routed.context.currentHandler, 'Patch11OrderAt46LatchWrapper');
assert.equal(routed.context.previousHandler, 'Discovery11OverwrittenOrderHandler');
assert.equal(routed.context.phase, 'PATCH_11_ORDER_AT_46_LATCH');
assert.equal(routed.context.status, 'PATCH_11_RESULT');
assert.equal(routed.context.legacyOrderMemoryWriteCount, 58);
assert.deepEqual(routed.context.legacyOrderMemoryLastSource, { kind: 'post-stir', ordinal: 12 });
assert.deepEqual(routed.context.legacyDrop46OrderDiagnostic, expected.orderAtDrop46);
assert.deepEqual(routed.context.legacyQueryOrder, direct.queryOrder);
assert.equal(routed.context.patch11LegacyCallPreserved, true);
assert.deepEqual(routed.context.patch11LegacyGarbage.queryOrder, direct.queryOrder);
assert.deepEqual(routed.context.patch11OrderAt46Latch, expected.orderAtDrop46);
assert.equal(routed.context.patch11OrderAt46LatchWriteCount, 1);
assert.deepEqual(routed.context.patch11OrderAt46LatchSource, { kind: 'drop', ordinal: 46 });
assert.equal(routed.context.patch11LegacyOrderMemoryWriteCount, 58);
assert.deepEqual(routed.context.patch11LegacyOrderMemoryLastSource, { kind: 'post-stir', ordinal: 12 });
assert.deepEqual(routed.context.patch11LegacyOrderMemory, routed.result.lastPostStirOrder);
assert.deepEqual(routed.context.patch11QueryOrder, expected.orderAtDrop46);
assert.deepEqual(routed.result.queryOrder, expected.orderAtDrop46);
assert.deepEqual(routed.result.orderAt46Latch, expected.orderAtDrop46);
assert.deepEqual(routed.result.bowls.slice(1), expected.bowls);
assert.deepEqual(routed.context.branchTrace, [
  'BOOTSTRAP_VALIDATED',
  'DISCOVERY_11_OVERWRITABLE_ORDER_MEMORY',
  'PATCH_11_ORDER_AT_46_LATCH'
]);
assert.equal(routed.context.metrics['discovery11.overwritableOrder.calls'], 1n);
assert.equal(routed.context.metrics['patch11.orderAt46Latch.calls'], 1n);

const mismatchPositions = [1, 2, 6].filter(
  (position) => routed.result.queryOrder[position - 1] !== expected.orderAtDrop46[position - 1]
);
assert.deepEqual(mismatchPositions, []);
console.log('DISCOVERY 11 REGRESSION: PASS pos Patch 11; li memorie legacy resta superscribil, ma queryOrder lee exclusivmen li latch single-write de drop 46.');
