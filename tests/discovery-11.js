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
assert.deepEqual(direct.bowls.slice(1), expected.bowls, 'Li six bowls final deve ja esser exact ante li defect de memorie de order.');
assert.deepEqual(
  direct.drop46OrderDiagnostic,
  expected.orderAtDrop46,
  'Li order real de drop 46 deve esser calculat exactmen ante que li post-stirs lo superscri.'
);
assert.equal(direct.orderWriteCount, 58, 'Li memorie legacy deve esser scrit 46 vezes per drops e 12 vezes per post-stirs.');
assert.deepEqual(direct.lastSource, { kind: 'post-stir', ordinal: 12 });
assert.deepEqual(direct.queryOrder, direct.lastPostStirOrder, 'Li query legacy deve leer li ultim valore superscrit in li memorie general.');
assert.notDeepEqual(
  direct.queryOrder,
  direct.drop46OrderDiagnostic,
  'Li witness deve realmen demonstrar que li ultim post-stir ha superscrit li order de drop 46.'
);

const routed = production.discovery11LegacyOverwrittenOrderThroughMonsterPath(
  calculationDay,
  targetDay,
  counts,
  stones
);
assert.equal(routed.context.currentHandler, 'Discovery11OverwrittenOrderHandler');
assert.equal(routed.context.phase, 'DISCOVERY_11_OVERWRITABLE_ORDER_MEMORY');
assert.equal(routed.context.status, 'DISCOVERY_11_LEGACY_RESULT');
assert.equal(routed.context.legacyOrderMemoryWriteCount, 58);
assert.deepEqual(routed.context.legacyOrderMemoryLastSource, { kind: 'post-stir', ordinal: 12 });
assert.deepEqual(routed.context.legacyDrop46OrderDiagnostic, expected.orderAtDrop46);
assert.deepEqual(routed.context.legacyOrderMemory, routed.result.lastPostStirOrder);
assert.deepEqual(routed.context.legacyQueryOrder, routed.result.queryOrder);
assert.deepEqual(routed.result.bowls.slice(1), expected.bowls);
assert.deepEqual(routed.context.branchTrace, [
  'BOOTSTRAP_VALIDATED',
  'DISCOVERY_11_OVERWRITABLE_ORDER_MEMORY'
]);
assert.equal(routed.context.metrics['discovery11.overwritableOrder.calls'], 1n);

const mismatchPositions = [1, 2, 6].filter(
  (position) => routed.result.queryOrder[position - 1] !== expected.orderAtDrop46[position - 1]
);
assert.deepEqual(
  mismatchPositions,
  [],
  'DISCOVERY 11 EXPECTED RED: li query order es li post-stir 12 superscrit in vice del order de drop 46 a positions 1, 2 e 6.'
);
