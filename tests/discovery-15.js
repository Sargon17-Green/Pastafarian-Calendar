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
const patchedActual = [];
for (const signedStep of negativeSteps) {
  const magnitude = -signedStep;
  const legacy = production.oldGateQuestionDay(magnitude);
  const expected = normative.FOUNDATION_DAY - magnitude;
  const patched = production.gateQuestionWithSignedStep(signedStep);
  legacyActual.push(legacy);
  normativeExpected.push(expected);
  patchedActual.push(patched);
  assert.equal(legacy, normative.FOUNDATION_DAY + magnitude);
  assert.notEqual(legacy, expected);
  assert.equal(patched, expected);
}

assert.equal(production.oldGateQuestionDay(0n), normative.FOUNDATION_DAY);
assert.equal(production.oldGateQuestionDay(7n), normative.FOUNDATION_DAY + 7n);
assert.equal(production.gateQuestionWithSignedStep(0n), production.oldGateQuestionDay(0n));
assert.equal(production.gateQuestionWithSignedStep(7n), production.oldGateQuestionDay(7n));
assert.throws(() => production.oldGateQuestionDay(-1n), RangeError);
assert.throws(() => production.oldGateQuestionDay(1), TypeError);

const routedLegacy = production.discovery15LegacyGateQuestionThroughMonsterPath(
  normative.FOUNDATION_DAY,
  normative.FOUNDATION_DAY,
  -10n
);
assert.equal(routedLegacy.result, normative.FOUNDATION_DAY + 10n);
assert.equal(routedLegacy.context.currentHandler, 'Discovery15NegativeGateQuestionHandler');
assert.equal(routedLegacy.context.previousHandler, null);
assert.equal(routedLegacy.context.phase, 'DISCOVERY_15_NEGATIVE_GATE_ASKS_POSITIVE_SIDE');
assert.equal(routedLegacy.context.status, 'DISCOVERY_15_LEGACY_RESULT');
assert.equal(routedLegacy.context.legacyGateSignedStep, -10n);
assert.equal(routedLegacy.context.legacyGateMagnitude, 10n);
assert.equal(routedLegacy.context.legacyGateQuestionDay, normative.FOUNDATION_DAY + 10n);
assert.equal(routedLegacy.context.legacyGateQuestionAskedPositiveSide, true);
assert.deepEqual(routedLegacy.context.branchTrace, [
  'BOOTSTRAP_VALIDATED',
  'DISCOVERY_15_NEGATIVE_GATE_ASKS_POSITIVE_SIDE'
]);
assert.equal(routedLegacy.context.metrics['discovery15.negativeGatePositiveSide.calls'], 1n);

const routedPatched = production.historicGateQuestionThroughMonsterPath(
  normative.FOUNDATION_DAY,
  normative.FOUNDATION_DAY,
  -10n
);
assert.equal(routedPatched.result, normative.FOUNDATION_DAY - 10n);
assert.equal(routedPatched.context.currentHandler, 'NegativeGateQuestionPatchWrapper');
assert.equal(routedPatched.context.previousHandler, 'Discovery15NegativeGateQuestionHandler');
assert.equal(routedPatched.context.status, 'PATCH_15_RESULT');
assert.equal(routedPatched.context.patch15LegacyDiagnostic, normative.FOUNDATION_DAY + 10n);
assert.equal(routedPatched.context.patch15NegativeDetourUsed, true);

const positive = production.historicGateQuestionThroughMonsterPath(
  normative.FOUNDATION_DAY,
  normative.FOUNDATION_DAY,
  10n
);
assert.equal(positive.result, normative.FOUNDATION_DAY + 10n);
assert.equal(positive.context.patch15NegativeDetourUsed, false);

console.log('DISCOVERY 15 REGRESSION: PASS pos Patch 15 — li helper legacy resta positiv, ma li route semantic devia solmen passus negativ.');
console.log('legacy negativ:    ' + legacyActual.map(String).join(', '));
console.log('normativ negativ:  ' + normativeExpected.map(String).join(', '));
console.log('reparat negativ:   ' + patchedActual.map(String).join(', '));

assert.deepEqual(
  patchedActual,
  normativeExpected,
  'Patch 15 deve questionar FOUNDATION-abs(step) solmen por signedStep negativ.'
);
