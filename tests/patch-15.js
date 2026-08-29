'use strict';

const assert = require('assert/strict');
const production = require('../src');
const normative = require('./normative-reference');

const legacySource = production.oldGateQuestionDay.toString();
assert.match(legacySource, /return FOUNDATION_DAY_OLD \+ n;/);
assert.doesNotMatch(legacySource, /signedStep|FOUNDATION_DAY_OLD -/);

const patchSource = production.gateQuestionWithSignedStep.toString();
assert.match(patchSource, /const magnitude = signedStep < 0n \? -signedStep : signedStep;/);
assert.match(patchSource, /let q = oldGateQuestionDay\(magnitude\);/);
assert.match(patchSource, /if \(signedStep < 0n\)/);
assert.match(patchSource, /q = FOUNDATION_DAY_OLD - magnitude;/);
assert.match(patchSource, /return q;/);
assert.ok(
  patchSource.indexOf('oldGateQuestionDay(magnitude)') < patchSource.indexOf('if (signedStep < 0n)'),
  'Li scar legacy deve esser vocat ante li detour negativ.'
);

for (const signedStep of [-1n, -2n, -10n, -101n]) {
  const magnitude = -signedStep;
  assert.equal(production.oldGateQuestionDay(magnitude), normative.FOUNDATION_DAY + magnitude);
  assert.equal(production.gateQuestionWithSignedStep(signedStep), normative.FOUNDATION_DAY - magnitude);
}
for (const signedStep of [0n, 1n, 7n, 101n]) {
  assert.equal(
    production.gateQuestionWithSignedStep(signedStep),
    production.oldGateQuestionDay(signedStep),
    'Zero e passus positiv deve restar exactmen sur li path legacy.'
  );
}

const f = normative.FOUNDATION_DAY;
const negative = production.historicGateQuestionThroughMonsterPath(f, f, -101n);
assert.equal(negative.result, f - 101n);
assert.equal(negative.context.currentHandler, 'NegativeGateQuestionPatchWrapper');
assert.equal(negative.context.previousHandler, 'Discovery15NegativeGateQuestionHandler');
assert.equal(negative.context.phase, 'PATCH_15_NEGATIVE_GATE_SIGN_DETOUR');
assert.equal(negative.context.status, 'PATCH_15_RESULT');
assert.equal(negative.context.legacyGateSignedStep, -101n);
assert.equal(negative.context.legacyGateMagnitude, 101n);
assert.equal(negative.context.legacyGateQuestionDay, f + 101n);
assert.equal(negative.context.legacyGateQuestionAskedPositiveSide, true);
assert.equal(negative.context.patch15SignedStep, -101n);
assert.equal(negative.context.patch15Magnitude, 101n);
assert.equal(negative.context.patch15LegacyDiagnostic, f + 101n);
assert.equal(negative.context.patch15LegacyDiagnosticPreserved, true);
assert.equal(negative.context.patch15NegativeDetourUsed, true);
assert.equal(negative.context.patch15Output, f - 101n);
assert.deepEqual(negative.context.branchTrace, [
  'BOOTSTRAP_VALIDATED',
  'DISCOVERY_15_NEGATIVE_GATE_ASKS_POSITIVE_SIDE',
  'PATCH_15_NEGATIVE_GATE_SIGN_DETOUR'
]);
assert.equal(negative.context.metrics['discovery15.negativeGatePositiveSide.calls'], 1n);
assert.equal(negative.context.metrics['patch15.negativeGateDetour.calls'], 1n);
assert.equal(negative.context.metrics['patch15.negativeGateDetour.used'], 1n);
assert.equal(negative.context.metrics['patch15.legacySidePreserved.calls'], undefined);

for (const signedStep of [0n, 17n]) {
  const routed = production.historicGateQuestionThroughMonsterPath(f, f, signedStep);
  assert.equal(routed.result, production.oldGateQuestionDay(signedStep));
  assert.equal(routed.context.patch15LegacyDiagnostic, routed.result);
  assert.equal(routed.context.patch15NegativeDetourUsed, false);
  assert.equal(routed.context.metrics['patch15.legacySidePreserved.calls'], 1n);
  assert.equal(routed.context.metrics['patch15.negativeGateDetour.used'], undefined);
}

const first = production.historicGateQuestionThroughMonsterPath(f, f, -10n);
const second = production.historicGateQuestionThroughMonsterPath(f, f, -10n);
assert.notEqual(first.context, second.context);
assert.equal(first.result, second.result);
assert.equal(first.context.patch15LegacyDiagnostic, second.context.patch15LegacyDiagnostic);
assert.equal(first.context.patch15Output, second.context.patch15Output);

assert.throws(() => production.gateQuestionWithSignedStep(1), TypeError);
assert.throws(() => production.historicGateQuestionThroughMonsterPath(f, f, 1), production.BootstrapStageError);

const wrapperSource = production.NegativeGateQuestionPatchWrapper.prototype.repair.toString();
assert.match(wrapperSource, /requireDiscovery15Result\(context\)/);
assert.match(wrapperSource, /context\.patch15LegacyDiagnostic = context\.legacyGateQuestionDay;/);
assert.match(wrapperSource, /context\.patch15NegativeDetourUsed = signedStep < 0n;/);
assert.match(wrapperSource, /gateQuestionWithSignedStep\(signedStep\)/);
assert.doesNotMatch(wrapperSource, /LEGACY_YEAR_MAX|REAL_YEAR_MAX_PATCH/);

console.log('PATCH 15: PASS — oldGateQuestionDay resta intact quam scar; solmen signedStep negativ usa li detour al latere negativ.');
