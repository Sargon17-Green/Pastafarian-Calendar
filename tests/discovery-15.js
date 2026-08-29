'use strict';

const assert = require('assert/strict');
const production = require('../src');
const normative = require('./normative-reference');

const source = production.oldGateQuestionDay.toString();
assert.match(source, /return FOUNDATION_DAY_OLD \+ n;/);
assert.doesNotMatch(source, /signedStep|abs|FOUNDATION_DAY_OLD -/);

const negativeSteps = [-1n, -2n, -10n];
const legacyActual = [];
const normativeExpected = [];
for (const signedStep of negativeSteps) {
  const magnitude = -signedStep;
  const legacy = production.oldGateQuestionDay(magnitude);
  const expected = normative.FOUNDATION_DAY - magnitude;
  legacyActual.push(legacy);
  normativeExpected.push(expected);
  assert.equal(legacy, normative.FOUNDATION_DAY + magnitude);
  assert.notEqual(legacy, expected);
}

assert.equal(production.oldGateQuestionDay(0n), normative.FOUNDATION_DAY);
assert.equal(production.oldGateQuestionDay(7n), normative.FOUNDATION_DAY + 7n);
assert.throws(() => production.oldGateQuestionDay(-1n), RangeError);
assert.throws(() => production.oldGateQuestionDay(1), TypeError);

const routed = production.discovery15LegacyGateQuestionThroughMonsterPath(
  normative.FOUNDATION_DAY,
  normative.FOUNDATION_DAY,
  -10n
);
assert.equal(routed.result, normative.FOUNDATION_DAY + 10n);
assert.equal(routed.context.currentHandler, 'Discovery15NegativeGateQuestionHandler');
assert.equal(routed.context.previousHandler, null);
assert.equal(routed.context.phase, 'DISCOVERY_15_NEGATIVE_GATE_ASKS_POSITIVE_SIDE');
assert.equal(routed.context.status, 'DISCOVERY_15_LEGACY_RESULT');
assert.equal(routed.context.legacyGateSignedStep, -10n);
assert.equal(routed.context.legacyGateMagnitude, 10n);
assert.equal(routed.context.legacyGateQuestionDay, normative.FOUNDATION_DAY + 10n);
assert.equal(routed.context.legacyGateQuestionAskedPositiveSide, true);
assert.deepEqual(routed.context.branchTrace, [
  'BOOTSTRAP_VALIDATED',
  'DISCOVERY_15_NEGATIVE_GATE_ASKS_POSITIVE_SIDE'
]);
assert.equal(routed.context.metrics['discovery15.negativeGatePositiveSide.calls'], 1n);

const positive = production.discovery15LegacyGateQuestionThroughMonsterPath(
  normative.FOUNDATION_DAY,
  normative.FOUNDATION_DAY,
  10n
);
assert.equal(positive.result, normative.FOUNDATION_DAY + 10n);
assert.equal(positive.context.legacyGateQuestionAskedPositiveSide, false);

console.log('DISCOVERY 15 DIAGNOSTIC: li helper legacy pregunta sempre li latere positiv quand li caller perde li signe.');
console.log('legacy negativ:    ' + legacyActual.map(String).join(', '));
console.log('normativ negativ:  ' + normativeExpected.map(String).join(', '));

assert.deepEqual(
  legacyActual,
  normativeExpected,
  'DISCOVERY 15 EXPECTED RED: un signedStep negativ deve questionar FOUNDATION-abs(step), ne li latere positiv.'
);
