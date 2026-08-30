'use strict';

const assert = require('assert/strict');
const production = require('../src');

function canonicalFive(result) {
  const cutlet = production.SourceLanguageCatalog.cutlets.find((row) => row.text === result[1]);
  const month = production.SourceLanguageCatalog.months.find((row) => row.text === result[3]);
  assert(cutlet, 'Li cutlet retornat deve existir in li catalog congelat.');
  assert(month, 'Li mensu retornat deve existir in li catalog congelat.');
  return [result[0], cutlet.canonicalIndex, result[2], month.canonicalIndex, result[4]];
}

const calculationDay = -15048553n;
const targetDay = -15044872n;
const routed = production.calendarDateSpaghettiWithContext(calculationDay, targetDay);
assert.deepEqual(canonicalFive(routed.result), [5000n, 14, 547n, 7, 72n]);
assert.equal(routed.context.mode, 'AUTHORITATIVE_SPAGHETTI_STAGE_57');
assert.equal(routed.context.stage57Patch26RoundTripDetourEnabled, true);
assert.equal(routed.context.stage57Patch26RoundTripMismatch, true);
assert.equal(routed.context.stage57LegacyGuardExecuted, true);
assert.equal(routed.context.stage57LegacyGuardPassed, false);
assert.equal(routed.context.stage57LegacyGuardError.name, 'BootstrapStageError');
assert.equal(routed.context.stage57SemanticYearPreservedFromPatch18, true);
assert.equal(routed.context.stage57SemanticYear.number, 5000n);
assert.equal(routed.context.stage57SemanticYear.openDay, -15049671n);
assert.equal(routed.context.stage57SemanticYear.closeDay, targetDay);
assert.equal(routed.context.stage57SemanticYear.openGateIndex, 10n);
assert.equal(routed.context.stage57SemanticYear.closeGateIndex, 20n);
assert.equal(routed.context.stage57Patch26RoundTripGhost.number, 5000n);
assert.equal(routed.context.stage57Patch26RoundTripGhost.openDay, -15050458n);
assert.equal(routed.context.stage57Patch26RoundTripGhost.closeDay, targetDay);
assert.equal(routed.context.stage57Patch26RoundTripGhost.openGateIndex, 9n);
assert.equal(routed.context.stage57Patch26RoundTripGhost.closeGateIndex, 20n);
assert.notEqual(routed.context.stage57Patch26RoundTripGhost.openDay, routed.context.stage57SemanticYear.openDay);

console.log('STAGE 57 E2E PASS: (-15048553,-15044872) => (5000,14,547,7,72); non-invertible Patch 26 round-trip resta ghost.');
