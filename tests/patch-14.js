'use strict';

const assert = require('assert/strict');
const production = require('../src');
const normative = require('./normative-reference');

const legacySource = production.legacySelectionAssumingNLeM.toString();
assert.match(legacySource, /return patchedSmallPick\(stream, N\);/);
assert.doesNotMatch(legacySource, /wideDetour|space|digits|selectionDispatcherWithWideDetour/);

const shortSource = production.patchedSmallPick.toString();
assert.match(shortSource, /const limit = \(M_OLD \/ N\) \* N;/);
assert.match(shortSource, /return biasedLegacyPick\(x, N\);/);

const wideSource = production.wideDetour.toString();
assert.match(wideSource, /while \(space < N\)/);
assert.match(wideSource, /space \*= M_OLD;/);
assert.match(wideSource, /const digit = ringAnswerAt\(stream, BigInt\(j\)\) - 1n;/);
assert.match(wideSource, /wide \+= digit \* weight;/);
assert.match(wideSource, /weight \*= M_OLD;/);
assert.match(wideSource, /const acceptanceLimit = \(space \/ N\) \* N;/);
assert.match(wideSource, /while \(wide > acceptanceLimit\)/);
assert.match(wideSource, /wide = 1n \+ regularMod\(wide - 1n \+ stream\.directionStep, space\);/);
const rejectionTail = wideSource.slice(wideSource.indexOf('const acceptanceLimit'));
assert.doesNotMatch(
  rejectionTail,
  /ringAnswerAt/,
  'Pos li construction del digits, rejection ne deve demandar null answer nov.'
);

const dispatcherSource = production.selectionDispatcherWithWideDetour.toString();
assert.match(dispatcherSource, /if \(N <= M_OLD\)/);
assert.match(dispatcherSource, /output: patchedSmallPick\(stream, N\)/);
assert.match(dispatcherSource, /return wideDetour\(stream, N\);/);

for (const stream of [
  { first: 1n, directionStep: 1n },
  { first: production.M_OLD, directionStep: 1n },
  { first: production.M_OLD / 2n + 10n, directionStep: -1n }
]) {
  for (const N of [1n, 2n, 10n, 997n, production.M_OLD]) {
    const dispatched = production.selectionDispatcherWithWideDetour(stream, N);
    assert.equal(dispatched.mode, 'short');
    assert.equal(dispatched.output, production.patchedSmallPick(stream, N));
    assert.equal(dispatched.output, normative.chooseRankShort(stream, N));
    assert.equal(dispatched.digitReadCount, 0);
    assert.equal(dispatched.digits, null);
  }
}

const M = production.M_OLD;
const wideCases = [
  { stream: { first: 1n, directionStep: 1n }, N: M + 1n },
  { stream: { first: M, directionStep: 1n }, N: M + 1n },
  { stream: { first: M / 3n + 7n, directionStep: -1n }, N: M * M },
  { stream: { first: 1n, directionStep: 1n }, N: M * M + 1n }
];
for (const { stream, N } of wideCases) {
  const detailed = production.wideDetour(stream, N);
  assert.equal(detailed.mode, 'wide');
  assert.equal(detailed.output, normative.chooseRankWide(stream, N));
  assert.ok(detailed.space >= N);
  assert.equal(detailed.space, M ** BigInt(detailed.places));
  assert.equal(detailed.digits.length, detailed.places);
  assert.equal(detailed.digitReadCount, detailed.places);
  assert.ok(detailed.acceptedWide <= detailed.acceptanceLimit);
  assert.ok(detailed.output >= 1n && detailed.output <= N);
}

const rejectionStream = { first: M / 2n + 10n, directionStep: -1n };
const firstDigit = production.ringAnswerAt(rejectionStream, 0n) - 1n;
const secondDigit = production.ringAnswerAt(rejectionStream, 1n) - 1n;
const initialWide = 1n + firstDigit + secondDigit * M;
const rejectionN = initialWide - 1n;
const rejected = production.wideDetour(rejectionStream, rejectionN);
assert.equal(rejected.places, 2);
assert.deepEqual(rejected.digits, [firstDigit, secondDigit]);
assert.equal(rejected.digitReadCount, 2);
assert.equal(rejected.initialWide, initialWide);
assert.equal(rejected.acceptanceLimit, rejectionN);
assert.equal(rejected.rejectionSteps, 1n);
assert.equal(rejected.acceptedWide, rejectionN);
assert.equal(rejected.output, normative.chooseRankWide(rejectionStream, rejectionN));

assert.throws(() => production.wideDetour({ first: 1n, directionStep: 1n }, M), RangeError);
assert.throws(() => production.wideDetour({ first: 0n, directionStep: 1n }, M + 1n), RangeError);
assert.throws(() => production.wideDetour({ first: 1n, directionStep: 0n }, M + 1n), RangeError);
assert.throws(() => production.wideDetour({ first: 1n, directionStep: 1n }, 1), TypeError);
assert.throws(() => production.selectionDispatcherWithWideDetour({ first: 1n, directionStep: 1n }, 0n), RangeError);

const calculationDay = normative.FOUNDATION_DAY;
const targetDay = normative.FOUNDATION_DAY;
const counts = normative.workCounts(calculationDay, targetDay);
const stones = production.getStoneTableThroughLegacyBuilder();
const queriedBowlId = 1;
const seal = 1n;
const N = M + 1n;
const legacy = production.discovery14LegacyWideSelectionThroughMonsterPath(
  calculationDay, targetDay, counts, stones, queriedBowlId, seal, N
);
const patched = production.historicSelectionThroughMonsterPath(
  calculationDay, targetDay, counts, stones, queriedBowlId, seal, N
);
const expected = normative.chooseRankWide(patched.stream, N);
assert.equal(legacy.result.failed, true);
assert.equal(legacy.result.output, null);
assert.equal(patched.result, expected);
assert.equal(expected, 2n);
assert.equal(patched.context.currentHandler, 'WideSelectionPatchWrapper');
assert.equal(patched.context.previousHandler, 'Discovery14WideSelectionHandler');
assert.equal(patched.context.phase, 'PATCH_14_SHORT_WIDE_DISPATCH');
assert.equal(patched.context.status, 'PATCH_14_RESULT');
assert.equal(patched.context.patch14Mode, 'wide');
assert.equal(patched.context.patch14LegacyDiagnosticPreserved, true);
assert.equal(patched.context.patch14LegacyDiagnosticFailed, true);
assert.equal(patched.context.patch14LegacyDiagnosticErrorName, 'RangeError');
assert.equal(patched.context.patch14Places, 2);
assert.equal(patched.context.patch14Space, M * M);
assert.equal(patched.context.patch14Digits.length, 2);
assert.equal(patched.context.patch14DigitReadCount, 2);
assert.equal(patched.context.patch14Output, expected);
assert.deepEqual(patched.context.branchTrace.slice(-5), [
  'PATCH_11_ORDER_AT_46_LATCH',
  'DISCOVERY_12_FIXED_ID_NEXT_BOWL',
  'PATCH_12_LATCH_CIRCULAR_SUCCESSOR',
  'DISCOVERY_14_LEGACY_ASSUMES_N_LE_M',
  'PATCH_14_SHORT_WIDE_DISPATCH'
]);
assert.equal(patched.context.metrics['discovery14.shortOnlyAssumption.calls'], 1n);
assert.equal(patched.context.metrics['patch14.wideDispatcher.calls'], 1n);
assert.equal(patched.context.metrics['patch14.wideDetour.calls'], 1n);

const shortN = 10n;
const shortPatched = production.historicSelectionThroughMonsterPath(
  calculationDay, targetDay, counts, stones, queriedBowlId, seal, shortN
);
assert.equal(shortPatched.context.patch14Mode, 'short');
assert.equal(shortPatched.context.patch14LegacyDiagnosticFailed, false);
assert.equal(shortPatched.result, normative.chooseRankShort(shortPatched.stream, shortN));
assert.equal(shortPatched.context.patch14Digits, null);
assert.equal(shortPatched.context.patch14DigitReadCount, 0);
assert.equal(shortPatched.context.metrics['patch14.shortCompatibility.calls'], 1n);
assert.equal(shortPatched.context.metrics['patch14.wideDetour.calls'], undefined);

console.log('PATCH 14: PASS — li dispatcher conserva li path curt e wideDetour construi digits un vez ante rejection sur li numero wide combinat.');
