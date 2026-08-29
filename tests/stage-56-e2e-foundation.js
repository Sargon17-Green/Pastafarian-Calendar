'use strict';
const assert = require('node:assert/strict');
const production = require('../src');
const F = production.FOUNDATION_DAY_OLD;
function canonicalFive(result) {
  const cutlet = production.SourceLanguageCatalog.cutlets.find((row) => row.text === result[1]);
  const month = production.SourceLanguageCatalog.months.find((row) => row.text === result[3]);
  assert.ok(cutlet); assert.ok(month);
  return [result[0], cutlet.canonicalIndex, result[2], month.canonicalIndex, result[4]];
}
const historic = production.calendarDateSpaghettiStage55Historical(F, F);
const corrected = production.calendarDateSpaghettiWithContext(F, F);
assert.deepEqual(historic, [5000n, 'scorpion', 503n, 'pute', 56n]);
assert.deepEqual(canonicalFive(corrected.result), [5000n, 4, 762n, 12, 105n]);
assert.notDeepEqual(corrected.result, historic);
assert.equal(corrected.context.mode, 'AUTHORITATIVE_SPAGHETTI_STAGE_56');
assert.equal(corrected.context.stage56CorrectiveApplied, true);
assert.ok(Array.isArray(corrected.context.stage56SauceStates));
assert.ok(corrected.context.stage56SauceStates.length >= 1);
for (const row of corrected.context.stage56SauceStates) {
  assert.equal(row.state.appliedCount, 12);
  assert.equal(row.state.legacyScarCallCount, 12);
  assert.equal(row.state.appliedFlag, true);
}
console.log('STAGE 56 E2E FOUNDATION PASS — historic Stage 55 resta witness e Foundation canonical es correct.');
