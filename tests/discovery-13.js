'use strict';

const assert = require('assert/strict');
const production = require('../src');
const normative = require('./normative-reference');

const syntheticStream = { first: production.M_OLD, directionStep: 1n };
const syntheticN = 10n;
const syntheticInitial = production.ringAnswerAt(syntheticStream, 0n);
assert.equal(syntheticInitial, production.M_OLD);
assert.equal(production.biasedLegacyPick(syntheticInitial, syntheticN), 7n);
assert.equal(normative.chooseRankShort(syntheticStream, syntheticN), 1n);
assert.notEqual(
  production.biasedLegacyPick(syntheticInitial, syntheticN),
  normative.chooseRankShort(syntheticStream, syntheticN)
);

const calculationDay = normative.FOUNDATION_DAY;
const targetDay = normative.FOUNDATION_DAY;
const counts = normative.workCounts(calculationDay, targetDay);
const stones = production.getStoneTableThroughLegacyBuilder();
const patchedSauce = production.sauceWithOrderAt46Latch(counts, stones);
const queriedBowlId = 1;
const seal = 1n;
const nextBowlId = production.nextBowlFromOrderAt46Latch(
  patchedSauce.orderAt46Latch,
  queriedBowlId
);
const expectedStream = production.answerRingFromCurrentState(
  patchedSauce.bowls,
  queriedBowlId,
  nextBowlId,
  seal
);
assert.ok(expectedStream.first * 2n > production.M_OLD);
assert.equal(expectedStream.directionStep, -1n);

// Ti N rende li prim answer exactmen un unit supra li limite curt, ergo li rejection normativ es de un passu solmen.
const N = expectedStream.first - 1n;
const acceptanceLimit = (production.M_OLD / N) * N;
assert.equal(acceptanceLimit, N);
assert.equal(production.ringAnswerAt(expectedStream, 0n), N + 1n);
assert.equal(production.ringAnswerAt(expectedStream, 1n), N);

const routed = production.discovery13LegacyBiasedSelectionThroughMonsterPath(
  calculationDay,
  targetDay,
  counts,
  stones,
  queriedBowlId,
  seal,
  N
);
assert.deepEqual(routed.stream, expectedStream);
assert.equal(routed.context.currentHandler, 'Discovery13BiasedSelectionHandler');
assert.equal(routed.context.previousHandler, 'NextBowlPatchWrapper');
assert.equal(routed.context.phase, 'DISCOVERY_13_BIASED_MODULO_SELECTION');
assert.equal(routed.context.status, 'DISCOVERY_13_LEGACY_RESULT');
assert.equal(routed.context.legacySelectionSeal, seal);
assert.equal(routed.context.legacySelectionStreamFirst, expectedStream.first);
assert.equal(routed.context.legacySelectionDirectionStep, expectedStream.directionStep);
assert.equal(routed.context.legacySelectionN, N);
assert.equal(routed.context.legacySelectionInitialAnswer, N + 1n);
assert.equal(routed.result, 1n);
assert.equal(routed.context.metrics['discovery13.biasedModulo.calls'], 1n);
assert.deepEqual(routed.context.branchTrace.slice(-4), [
  'PATCH_11_ORDER_AT_46_LATCH',
  'DISCOVERY_12_FIXED_ID_NEXT_BOWL',
  'PATCH_12_LATCH_CIRCULAR_SUCCESSOR',
  'DISCOVERY_13_BIASED_MODULO_SELECTION'
]);

const legacySource = production.biasedLegacyPick.toString();
assert.match(legacySource, /regularMod\(x - 1n, N\) \+ 1n/);
assert.doesNotMatch(legacySource, /while|acceptanceLimit|floorDiv|ringAnswerAt/);
const adapterSource = production.LegacyBiasedSelectionAdapter.prototype.call.toString();
assert.match(adapterSource, /ringAnswerAt\(stream, 0n\)/);
assert.match(adapterSource, /biasedLegacyPick\(x, N\)/);
assert.doesNotMatch(adapterSource, /while|limit|offset \+=|offset = offset \+/);

const normativeExpected = normative.chooseRankShort(routed.stream, N);
assert.equal(normativeExpected, N);
console.log('DISCOVERY 13: li selector legacy usa directmen li prim answer e ne fa rejection sur li answer ring.');
console.log('first=' + routed.stream.first + ', N=' + N + ', legacy=' + routed.result + ', normative=' + normativeExpected);
assert.equal(
  routed.result,
  normativeExpected,
  'DISCOVERY 13 EXPECTED RED: biasedLegacyPick es vocat ante rejection; li prim answer rejectet ne deve esser mappat directmen al familie.'
);
