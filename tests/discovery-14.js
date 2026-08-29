'use strict';

const assert = require('assert/strict');
const production = require('../src');
const normative = require('./normative-reference');

const N = production.M_OLD + 1n;
const synthetic = { first: production.M_OLD, directionStep: 1n };
assert.throws(
  () => production.legacySelectionAssumingNLeM(synthetic, N),
  RangeError,
  'Li route legacy de wide selection deve ancora fallir pro su assumption N<=M.'
);
assert.equal(normative.chooseRankWide(synthetic, N), production.M_OLD);

const calculationDay = normative.FOUNDATION_DAY;
const targetDay = normative.FOUNDATION_DAY;
const counts = normative.workCounts(calculationDay, targetDay);
const stones = production.getStoneTableThroughLegacyBuilder();
const queriedBowlId = 1;
const seal = 1n;
const routed = production.discovery14LegacyWideSelectionThroughMonsterPath(
  calculationDay,
  targetDay,
  counts,
  stones,
  queriedBowlId,
  seal,
  N
);

assert.equal(routed.context.currentHandler, 'Discovery14WideSelectionHandler');
assert.equal(routed.context.previousHandler, 'NextBowlPatchWrapper');
assert.equal(routed.context.phase, 'DISCOVERY_14_LEGACY_ASSUMES_N_LE_M');
assert.equal(routed.context.status, 'DISCOVERY_14_LEGACY_RESULT');
assert.equal(routed.context.legacyWideSelectionSeal, seal);
assert.equal(routed.context.legacyWideSelectionStreamFirst, routed.stream.first);
assert.equal(routed.context.legacyWideSelectionDirectionStep, routed.stream.directionStep);
assert.equal(routed.context.legacyWideSelectionN, N);
assert.equal(routed.context.legacyWideSelectionAssumedShort, true);
assert.equal(routed.context.legacyWideSelectionFailed, true);
assert.equal(routed.context.legacyWideSelectionErrorName, 'RangeError');
assert.equal(
  routed.context.legacyWideSelectionErrorMessage,
  'Li familie curt reparat deve haver un grandore inter 1 e M.'
);
assert.equal(routed.result.failed, true);
assert.equal(routed.result.output, null);
assert.equal(routed.result.errorName, 'RangeError');
assert.deepEqual(routed.context.branchTrace.slice(-4), [
  'PATCH_11_ORDER_AT_46_LATCH',
  'DISCOVERY_12_FIXED_ID_NEXT_BOWL',
  'PATCH_12_LATCH_CIRCULAR_SUCCESSOR',
  'DISCOVERY_14_LEGACY_ASSUMES_N_LE_M'
]);
assert.equal(routed.context.metrics['discovery14.shortOnlyAssumption.calls'], 1n);
assert.equal(routed.context.metrics['patch13.selectionRejection.calls'], undefined);

const legacySource = production.legacySelectionAssumingNLeM.toString();
assert.match(legacySource, /return patchedSmallPick\(stream, N\);/);
assert.doesNotMatch(legacySource, /wideDetour|space|digits/);
const handlerSource = production.Discovery14WideSelectionHandler.prototype.handle.toString();
assert.doesNotMatch(handlerSource, /wideDetour/);

const expectedWide = normative.chooseRankWide(routed.stream, N);
assert.equal(expectedWide, 2n);
assert.equal(
  routed.result.output,
  expectedWide,
  'DISCOVERY 14 EXPECTED RED: li route legacy presume N<=M e falla in vice de seleccionar un rank wide exact.'
);
