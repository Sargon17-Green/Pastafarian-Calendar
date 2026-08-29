'use strict';

const assert = require('assert/strict');
const production = require('../src');
const normative = require('./normative-reference');

const f = normative.FOUNDATION_DAY;
const selectionStream = { first: 1n, directionStep: 1n };
const candidatePairs = [
  { openIndex: 30, closeIndex: 36 },
  { openIndex: 10, closeIndex: 16 },
  { openIndex: 20, closeIndex: 26 }
];
const noWalkExpected = {
  nextYear() { throw new Error('Patch 19 ne deve caminar avante in ti witnesses de Year 5000.'); },
  previousYear() { throw new Error('Patch 19 ne deve caminar retro in ti witnesses de Year 5000.'); }
};

function gatesBase() {
  return {
    10: f + 10n, 16: f + 1010n,
    20: f + 20n, 26: f + 1020n,
    30: f + 30n, 36: f + 1030n
  };
}
function gatesOpeningChangedOnly() {
  return {
    10: f + 11n, 16: f + 1010n,
    20: f + 21n, 26: f + 1020n,
    30: f + 31n, 36: f + 1030n
  };
}
function gatesClosingChangedOnly() {
  return {
    10: f + 10n, 16: f + 1011n,
    20: f + 20n, 26: f + 1021n,
    30: f + 30n, 36: f + 1031n
  };
}
function expectedValue(actionDay, openingDay, closingDay) {
  return { yearNumber: 5000n, actionDay, openingDay, closingDay };
}
function call(manager, calculationDay, gates) {
  return production.historicYearNumberCacheThroughMonsterPath(
    manager, calculationDay, calculationDay, -1n, gates, candidatePairs, selectionStream, noWalkExpected
  );
}

// Li scars historic deve restar fisicmen separati e sin guards.
const legacyLookupSource = production.legacyYearNumberOnlyLookup.toString();
assert.match(legacyLookupSource, /cacheMap\.has\(yearNumber\)/);
assert.match(legacyLookupSource, /cacheMap\.get\(yearNumber\)/);
assert.doesNotMatch(legacyLookupSource, /calculationDayFingerprint|openGate|closeGate|actionDay/);
const legacyPutSource = production.legacyYearNumberOnlyPut.toString();
assert.match(legacyPutSource, /cacheMap\.set\(yearNumber, value\)/);
assert.doesNotMatch(legacyPutSource, /calculationDayFingerprint|openGate|closeGate/);

assert.equal(production.calculationDayFingerprint(f + 100n), f + 100n);
assert.throws(() => production.calculationDayFingerprint(1), TypeError);

const directCache = new Map();
const year = { number: 5000n, openDay: f + 10n, closeDay: f + 1010n };
const valueA = expectedValue(f + 100n, f + 10n, f + 1010n);
const entry = production.cachePutWithGuard(directCache, year, f + 100n, valueA);
assert.deepEqual(Object.keys(entry), ['calculationDayFingerprint', 'openGate', 'closeGate', 'value']);
assert.equal(entry.calculationDayFingerprint, f + 100n);
assert.equal(entry.openGate, f + 10n);
assert.equal(entry.closeGate, f + 1010n);
assert.deepEqual(entry.value, valueA);
assert.equal(directCache.size, 1);
assert.equal(directCache.has(5000n), true);
assert.deepEqual(directCache.get(5000n), entry);

let guarded = production.cacheGetWithActionGuard(directCache, year, f + 100n);
assert.equal(guarded.hit, true);
assert.equal(guarded.reason, null);
assert.deepEqual(guarded.value, valueA);
guarded = production.cacheGetWithActionGuard(directCache, year, f + 101n);
assert.equal(guarded.hit, false);
assert.equal(guarded.reason, 'calculation-day');
guarded = production.cacheGetWithActionGuard(directCache, { ...year, openDay: f + 11n }, f + 100n);
assert.equal(guarded.hit, false);
assert.equal(guarded.reason, 'open-gate');
guarded = production.cacheGetWithActionGuard(directCache, { ...year, closeDay: f + 1011n }, f + 100n);
assert.equal(guarded.hit, false);
assert.equal(guarded.reason, 'close-gate');

// Un value legacy sin forma guardat es ancor trovat per li bad lookup, ma deven un MISS semantic.
const legacyShapeCache = new Map();
production.legacyYearNumberOnlyPut(legacyShapeCache, 5000n, valueA);
guarded = production.cacheGetWithActionGuard(legacyShapeCache, year, f + 100n);
assert.equal(guarded.legacyLookup.hit, true);
assert.equal(guarded.hit, false);
assert.equal(guarded.reason, 'legacy-value-shape');

const getSource = production.cacheGetWithActionGuard.toString();
assert.ok(
  getSource.indexOf('legacyYearNumberOnlyLookup(cacheMap, year.number)') < getSource.indexOf('entry.calculationDayFingerprint'),
  'Li lookup scar keyed solmen per year.number deve esser vocat ante li guards.'
);
assert.match(getSource, /entry.openGate !== year.openDay/);
assert.match(getSource, /entry.closeGate !== year.closeDay/);
const putSource = production.cachePutWithGuard.toString();
assert.match(putSource, /legacyYearNumberOnlyPut\(cacheMap, year\.number, entry\)/);
assert.match(putSource, /calculationDayFingerprint:/);
assert.match(putSource, /openGate: year.openDay/);
assert.match(putSource, /closeGate: year.closeDay/);

const scenarios = [
  {
    label: 'calculation-day', firstDay: f + 100n, secondDay: f + 101n,
    firstGates: gatesBase(), secondGates: gatesBase(), reason: 'calculation-day',
    firstExpected: expectedValue(f + 100n, f + 10n, f + 1010n),
    secondExpected: expectedValue(f + 101n, f + 10n, f + 1010n)
  },
  {
    label: 'opening-gate', firstDay: f + 100n, secondDay: f + 100n,
    firstGates: gatesBase(), secondGates: gatesOpeningChangedOnly(), reason: 'open-gate',
    firstExpected: expectedValue(f + 100n, f + 10n, f + 1010n),
    secondExpected: expectedValue(f + 100n, f + 11n, f + 1010n)
  },
  {
    label: 'closing-gate', firstDay: f + 100n, secondDay: f + 100n,
    firstGates: gatesBase(), secondGates: gatesClosingChangedOnly(), reason: 'close-gate',
    firstExpected: expectedValue(f + 100n, f + 10n, f + 1010n),
    secondExpected: expectedValue(f + 100n, f + 10n, f + 1011n)
  }
];

for (const scenario of scenarios) {
  const manager = new production.BaseMonsterManager();
  const first = call(manager, scenario.firstDay, scenario.firstGates);
  assert.equal(first.result.hit, false, scenario.label);
  assert.equal(first.result.recomputed, true, scenario.label);
  assert.deepEqual(first.result.value, scenario.firstExpected, scenario.label);
  assert.equal(first.result.key, 5000n, scenario.label);
  assert.equal(manager.LEGACY_STRUCTURE_CACHE_BY_YEAR_NUMBER.size, 1, scenario.label);
  let stored = manager.LEGACY_STRUCTURE_CACHE_BY_YEAR_NUMBER.get(5000n);
  assert.equal(stored.calculationDayFingerprint, scenario.firstDay, scenario.label);
  assert.deepEqual(stored.value, scenario.firstExpected, scenario.label);

  const second = call(manager, scenario.secondDay, scenario.secondGates);
  assert.equal(second.result.hit, false, scenario.label);
  assert.equal(second.result.reason, scenario.reason, scenario.label);
  assert.equal(second.result.recomputed, true, scenario.label);
  assert.deepEqual(second.result.value, scenario.secondExpected, scenario.label);
  assert.equal(second.context.currentHandler, 'YearCacheActionGuardPatchWrapper', scenario.label);
  assert.equal(second.context.previousHandler, 'SequentialYearWalkPatchWrapper', scenario.label);
  assert.equal(second.context.phase, 'PATCH_19_ACTION_AND_GATE_GUARDS', scenario.label);
  assert.equal(second.context.status, 'PATCH_19_RESULT', scenario.label);
  assert.equal(second.context.patch19LegacyDiagnosticPreserved, true, scenario.label);
  assert.equal(second.context.patch19OnlyNumberKeyPreserved, true, scenario.label);
  assert.equal(second.context.patch19CacheKey, 5000n, scenario.label);
  assert.equal(second.context.patch19GuardMismatchReason, scenario.reason, scenario.label);
  assert.equal(second.context.patch19Recomputed, true, scenario.label);
  assert.equal(second.context.metrics['patch19.actionGuard.calls'], 1n, scenario.label);
  assert.equal(second.context.metrics['patch19.actionGuard.misses'], 1n, scenario.label);
  assert.equal(second.context.metrics['patch19.actionGuard.replacements'], 1n, scenario.label);
  assert.equal(manager.LEGACY_STRUCTURE_CACHE_BY_YEAR_NUMBER.size, 1, scenario.label);
  stored = manager.LEGACY_STRUCTURE_CACHE_BY_YEAR_NUMBER.get(5000n);
  assert.equal(stored.calculationDayFingerprint, scenario.secondDay, scenario.label);
  assert.equal(stored.openGate, scenario.secondExpected.openingDay, scenario.label);
  assert.equal(stored.closeGate, scenario.secondExpected.closingDay, scenario.label);
  assert.deepEqual(stored.value, scenario.secondExpected, scenario.label);

  const third = call(manager, scenario.secondDay, scenario.secondGates);
  assert.equal(third.result.hit, true, scenario.label);
  assert.equal(third.result.reason, null, scenario.label);
  assert.equal(third.result.recomputed, false, scenario.label);
  assert.deepEqual(third.result.value, scenario.secondExpected, scenario.label);
  assert.equal(third.context.metrics['patch19.actionGuard.hits'], 1n, scenario.label);
  assert.deepEqual(third.context.branchTrace.slice(-3), [
    'DISCOVERY_18_OLD_JUMP_GUESS_365',
    'PATCH_18_SEQUENTIAL_YEAR_WALK',
    'PATCH_19_ACTION_AND_GATE_GUARDS'
  ], scenario.label);
}

// Observabilitá ne posse mutar li semantics: un manager fresh e un manager con stale history retorna li sam current value.
const freshManager = new production.BaseMonsterManager();
const freshCurrent = call(freshManager, f + 101n, gatesBase());
const historyManager = new production.BaseMonsterManager();
call(historyManager, f + 100n, gatesBase());
const afterHistory = call(historyManager, f + 101n, gatesBase());
assert.deepEqual(afterHistory.result.value, freshCurrent.result.value);
assert.equal(afterHistory.result.key, freshCurrent.result.key);
assert.equal(historyManager.LEGACY_STRUCTURE_CACHE_BY_YEAR_NUMBER.size, 1);
assert.equal(freshManager.LEGACY_STRUCTURE_CACHE_BY_YEAR_NUMBER.size, 1);

assert.equal('oldStructureSauce' in production, false);
console.log('PATCH 19: PASS — li bad key year.number resta, ma calculation-day e du gate guards decide semanticmen HIT contra MISS.');
