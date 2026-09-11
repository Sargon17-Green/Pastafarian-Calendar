'use strict';
const assert = require('assert/strict');
const production = require('../src');
function canonicalFive(result) {
  const cutlet = production.SourceLanguageCatalog.cutlets.find((row) => row.text === result[1]);
  const month = production.SourceLanguageCatalog.months.find((row) => row.text === result[3]);
  assert(cutlet); assert(month);
  return [result[0], cutlet.canonicalIndex, result[2], month.canonicalIndex, result[4]];
}
const calculationDay = -15048553n;
const targetDay = -15044872n;
const routed = production.calendarDateSpaghettiWithContext(calculationDay, targetDay);
assert.deepEqual(canonicalFive(routed.result), [5000n, 5, 347n, 31, 123n]);
assert.equal(routed.context.mode, 'AUTHORITATIVE_SPAGHETTI_STAGE_57');
assert.equal(routed.context.stage57Patch26RoundTripDetourEnabled, true);
assert.equal(routed.context.stage57LegacyGuardExecuted, true);
assert.equal(routed.context.stage57LegacyGuardPassed, true);
assert.equal(routed.context.stage57Patch26RoundTripMismatch, false);
assert.equal(routed.context.stage57LegacyGuardError, null);
assert.equal(routed.context.stage57SemanticYear.number, 5000n);
assert.equal(routed.context.stage57SemanticYear.openDay, -15049315n);
assert.equal(routed.context.stage57SemanticYear.closeDay, -15044808n);
assert.equal(routed.context.stage57SemanticYear.openGateIndex, 11n);
assert.equal(routed.context.stage57SemanticYear.closeGateIndex, 20n);
assert.deepEqual(routed.context.stage57Patch26RoundTripGhost, routed.context.stage57SemanticYear);
console.log('STAGE 57 E2E PASS — Patch 26 preserved; saved-sum downstream year and round-trip agree.');
