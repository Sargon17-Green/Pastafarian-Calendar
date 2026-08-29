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
assert.equal(production.patchedSmallPick(syntheticStream, syntheticN), 1n);

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

const N = expectedStream.first - 1n;
const acceptanceLimit = (production.M_OLD / N) * N;
assert.equal(acceptanceLimit, N);
assert.equal(production.ringAnswerAt(expectedStream, 0n), N + 1n);
assert.equal(production.ringAnswerAt(expectedStream, 1n), N);

const legacyRouted = production.discovery13LegacyBiasedSelectionThroughMonsterPath(
  calculationDay,
  targetDay,
  counts,
  stones,
  queriedBowlId,
  seal,
  N
);
assert.deepEqual(legacyRouted.stream, expectedStream);
assert.equal(legacyRouted.context.currentHandler, 'Discovery13BiasedSelectionHandler');
assert.equal(legacyRouted.context.previousHandler, 'NextBowlPatchWrapper');
assert.equal(legacyRouted.context.phase, 'DISCOVERY_13_BIASED_MODULO_SELECTION');
assert.equal(legacyRouted.context.status, 'DISCOVERY_13_LEGACY_RESULT');
assert.equal(legacyRouted.context.legacySelectionInitialAnswer, N + 1n);
assert.equal(legacyRouted.result, 1n);
assert.equal(legacyRouted.context.metrics['discovery13.biasedModulo.calls'], 1n);
assert.notEqual(legacyRouted.result, normative.chooseRankShort(legacyRouted.stream, N));

const patchedRouted = production.historicSmallSelectionThroughMonsterPath(
  calculationDay,
  targetDay,
  counts,
  stones,
  queriedBowlId,
  seal,
  N
);
assert.deepEqual(patchedRouted.stream, expectedStream);
assert.equal(patchedRouted.result, N);
assert.equal(patchedRouted.result, normative.chooseRankShort(patchedRouted.stream, N));
assert.equal(patchedRouted.context.patch13AcceptanceLimit, N);
assert.equal(patchedRouted.context.patch13AcceptedOffset, 1n);
assert.equal(patchedRouted.context.patch13AcceptedAnswer, N);
assert.equal(patchedRouted.context.patch13LegacyCallPreserved, true);
assert.ok(!patchedRouted.context.branchTrace.includes('DISCOVERY_13_BIASED_MODULO_SELECTION'));

const legacySource = production.biasedLegacyPick.toString();
assert.match(legacySource, /regularMod\(x - 1n, N\) \+ 1n/);
assert.doesNotMatch(legacySource, /while|limit|ringAnswerAt/);
const adapterSource = production.LegacyBiasedSelectionAdapter.prototype.call.toString();
assert.match(adapterSource, /ringAnswerAt\(stream, 0n\)/);
assert.match(adapterSource, /biasedLegacyPick\(x, N\)/);
assert.doesNotMatch(adapterSource, /while|limit|offset \+=/);
const patchSource = production.patchedSmallPick.toString();
assert.match(patchSource, /const limit = \(M_OLD \/ N\) \* N/);
assert.match(patchSource, /while \(x > limit\)/);
assert.match(patchSource, /offset \+= 1n/);
assert.match(patchSource, /return biasedLegacyPick\(x, N\)/);
assert.ok(patchSource.indexOf('while (x > limit)') < patchSource.indexOf('biasedLegacyPick(x, N)'));

console.log('DISCOVERY 13 REGRESSION: PASS pos Patch 13; li selector legacy resta biased, ma li route reparat rejecte ante li call legacy.');
