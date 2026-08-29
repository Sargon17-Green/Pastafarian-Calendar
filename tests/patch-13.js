'use strict';

const assert = require('assert/strict');
const production = require('../src');
const normative = require('./normative-reference');

const legacySource = production.biasedLegacyPick.toString();
assert.match(legacySource, /return regularMod\(x - 1n, N\) \+ 1n;/);
assert.doesNotMatch(legacySource, /while|limit|ringAnswerAt|patchedSmallPick/);

const patchSource = production.patchedSmallPick.toString();
assert.match(patchSource, /const limit = \(M_OLD \/ N\) \* N;/);
assert.match(patchSource, /let offset = 0n;/);
assert.match(patchSource, /let x = ringAnswerAt\(stream, offset\);/);
assert.match(patchSource, /while \(x > limit\)/);
assert.match(patchSource, /offset \+= 1n;/);
assert.match(patchSource, /x = ringAnswerAt\(stream, offset\);/);
assert.match(patchSource, /return biasedLegacyPick\(x, N\);/);
assert.ok(
  patchSource.indexOf('while (x > limit)') < patchSource.indexOf('return biasedLegacyPick(x, N);'),
  'Li helper legacy deve esser vocat solmen pos li rejection.'
);

const synthetic = { first: production.M_OLD, directionStep: 1n };
assert.equal(production.biasedLegacyPick(production.M_OLD, 10n), 7n);
assert.equal(production.patchedSmallPick(synthetic, 10n), 1n);
assert.equal(production.patchedSmallPick(synthetic, 10n), normative.chooseRankShort(synthetic, 10n));

for (let N = 1n; N <= 256n; N += 1n) {
  for (const directionStep of [1n, -1n]) {
    for (const distanceFromTop of [0n, 1n, 2n, 17n, 63n]) {
      const first = production.M_OLD - distanceFromTop;
      const stream = { first, directionStep };
      assert.equal(
        production.patchedSmallPick(stream, N),
        normative.chooseRankShort(stream, N),
        'Li short pick reparat deve esser exact por N=' + N + ', direction=' + directionStep + ', distance=' + distanceFromTop
      );
    }
  }
}

const calculationDay = normative.FOUNDATION_DAY;
const targetDay = normative.FOUNDATION_DAY;
const counts = normative.workCounts(calculationDay, targetDay);
const stones = production.getStoneTableThroughLegacyBuilder();
const sauce = production.sauceWithOrderAt46Latch(counts, stones);
const queriedBowlId = 1;
const seal = 1n;
const nextBowlId = production.nextBowlFromOrderAt46Latch(sauce.orderAt46Latch, queriedBowlId);
const stream = production.answerRingFromCurrentState(sauce.bowls, queriedBowlId, nextBowlId, seal);
const N = stream.first - 1n;
const legacy = production.discovery13LegacyBiasedSelectionThroughMonsterPath(
  calculationDay, targetDay, counts, stones, queriedBowlId, seal, N
);
const patched = production.historicSmallSelectionThroughMonsterPath(
  calculationDay, targetDay, counts, stones, queriedBowlId, seal, N
);
assert.equal(legacy.result, 1n);
assert.equal(patched.result, N);
assert.equal(patched.result, normative.chooseRankShort(stream, N));
assert.equal(patched.context.currentHandler, 'SelectionRejectionPatchWrapper');
assert.equal(patched.context.previousHandler, 'NextBowlPatchWrapper');
assert.equal(patched.context.phase, 'PATCH_13_REJECTION_BEFORE_LEGACY_PICK');
assert.equal(patched.context.status, 'PATCH_13_RESULT');
assert.equal(patched.context.patch13AcceptanceLimit, N);
assert.equal(patched.context.patch13AcceptedOffset, 1n);
assert.equal(patched.context.patch13AcceptedAnswer, N);
assert.equal(patched.context.patch13LegacyCallPreserved, true);
assert.equal(patched.context.patch13Output, N);
assert.deepEqual(patched.context.branchTrace.slice(-4), [
  'PATCH_11_ORDER_AT_46_LATCH',
  'DISCOVERY_12_FIXED_ID_NEXT_BOWL',
  'PATCH_12_LATCH_CIRCULAR_SUCCESSOR',
  'PATCH_13_REJECTION_BEFORE_LEGACY_PICK'
]);
assert.equal(patched.context.metrics['patch13.selectionRejection.calls'], 1n);
assert.equal(patched.context.metrics['discovery13.biasedModulo.calls'], undefined);

const wrapperSource = production.SelectionRejectionPatchWrapper.prototype.repair.toString();
assert.doesNotMatch(wrapperSource, /this\.discovery13|\.discovery13BiasedSelectionHandler/);
assert.match(wrapperSource, /patchedSmallPick\(stream, N\)/);
assert.match(wrapperSource, /while \(x > limit\)/);

assert.throws(() => production.patchedSmallPick({ first: 1n, directionStep: 1n }, 0n), RangeError);
assert.throws(() => production.patchedSmallPick({ first: 1n, directionStep: 1n }, production.M_OLD + 1n), RangeError);
assert.throws(() => production.patchedSmallPick({ first: 0n, directionStep: 1n }, 1n), RangeError);
assert.throws(() => production.patchedSmallPick({ first: 1n, directionStep: 0n }, 1n), RangeError);
assert.throws(() => production.patchedSmallPick({ first: 1n, directionStep: 1n }, 1), TypeError);

console.log('PATCH 13: PASS — li rejection avansa sur li sam answer ring e biasedLegacyPick es vocat solmen pos x<=limit.');
