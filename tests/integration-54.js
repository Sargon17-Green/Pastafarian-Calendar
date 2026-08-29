'use strict';

const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const production = require('../src');

function sameSauce(calculationDay, targetDay) {
  const oldPath = production.sauceWithCurrentScars(calculationDay, targetDay);
  const integrated = production.sauceWithScars(calculationDay, targetDay);
  assert.deepEqual(integrated.bowls, oldPath.bowls);
  assert.deepEqual(integrated.orderAt46Latch, oldPath.orderAt46Latch);
  assert.equal(integrated.orderAt46LatchWriteCount, 1);
  assert.deepEqual(integrated.queryOrder, integrated.orderAt46Latch);
  assert.deepEqual(integrated.stateMachineTrace, [
    'SAUCE_ENTRY', 'PATCHED_COUNTS', 'STONES_THROUGH_LEGACY_BUILDER',
    'BACKWARD_HIDDEN_STORAGE_AND_PATCHED_PRIOR_READY',
    'VISIBLE_46_ALIAS_SHADOW_LATCH_POST12', 'QUERY_THROUGH_LATCHED_ORDER'
  ]);
  assert.equal(integrated.nextDiagnostics.length, 6);
}

sameSauce(production.FOUNDATION_DAY_OLD, production.FOUNDATION_DAY_OLD);
sameSauce(production.FOUNDATION_DAY_OLD + 17n, production.FOUNDATION_DAY_OLD - 9n);

const source = fs.readFileSync(path.join(__dirname, '..', 'src', 'index.js'), 'utf8');
assert.equal(source.includes("require('../tests/normative-reference')"), false);
assert.equal(source.includes('function sauceWithScars(calculationDay, targetDay)'), true);
assert.equal(source.includes('class Stage54MonsterIntegrationManager extends BaseMonsterManager'), true);
assert.match(production.calendarDateSpaghetti.toString(), /calendarDateSpaghettiWithContext/);
assert.match(production.Stage54MonsterIntegrationManager.prototype.executeCalendarDate.toString(), /programCounter/);
assert.match(production.Stage54MonsterIntegrationManager.prototype.executeCalendarDate.toString(), /switch/);

const first = production.calendarDateSpaghettiStage55HistoricalWithContext(production.FOUNDATION_DAY_OLD, production.FOUNDATION_DAY_OLD);
assert.equal(first.result.length, 5);
assert.equal(first.result[0], 5000n);
assert.equal(typeof first.result[1], 'string');
assert.equal(typeof first.result[3], 'string');
assert.ok(first.result[2] >= 1n);
assert.ok(first.result[4] >= 1n);
assert.equal(first.context.status, 'SUCCESS');
assert.equal(first.context.mode, 'AUTHORITATIVE_SPAGHETTI');
assert.equal(first.context.patch26ResolvedYear.number, first.result[0]);
assert.equal(first.context.structure.monthWeaving.length, Number(first.context.currentYear.closeDay - first.context.currentYear.openDay));
assert.equal(new Set(first.context.structure.cutletNameIndices).size, first.context.structure.cutletNameIndices.length);
assert.equal(new Set(first.context.structure.monthNameIndices).size, first.context.structure.monthNameIndices.length);
assert.equal(first.context.structure.cutletNameIndices.length, first.context.structure.cutletCount);
assert.equal(first.context.structure.monthNameIndices.length, first.context.structure.monthCount);
assert.equal(first.context.branchTrace.includes('STAGE_54_MAIN_90'), true);
assert.equal(first.context.branchTrace.includes('STAGE_54_SUCCESS'), true);

const labels = new Set(first.context.diagnostics.map((row) => row && row.label).filter(Boolean));
for (const required of [
  'oldJumpGuess', 'opening-gate-interval', 'structure-sauce-ghost', 'cutlet-partition-scar',
  'cutlet-names', 'month-length-concrete-scar', 'month-weaving-ghost', 'month-names', 'contiguous-month-ghost'
]) assert.equal(labels.has(required), true, 'Manca diagnostic integrat: ' + required);

const direct = production.calendarDateSpaghettiStage55Historical(production.FOUNDATION_DAY_OLD, production.FOUNDATION_DAY_OLD);
assert.deepEqual(direct, first.result);
const warm = production.calendarDateSpaghettiStage55HistoricalWithContext(production.FOUNDATION_DAY_OLD, production.FOUNDATION_DAY_OLD);
assert.deepEqual(warm.result, first.result);
const cacheProbe = warm.context.diagnostics.find((row) => row && row.label === 'pre-structure-cache-probe');
assert.ok(cacheProbe);
assert.equal(cacheProbe.hit, true);
assert.equal(production.SourceLanguageCatalog.version, '1.0.0-stage-01');
assert.equal(Object.isFrozen(production.SourceLanguageCatalog), true);
console.log('STAGE 54 INTEGRATION PASS: sauceWithScars, state-machine principal, scars historic e five-field return es conectet in un unic route GREEN.');
