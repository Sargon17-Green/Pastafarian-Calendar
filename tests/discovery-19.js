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
  nextYear() {
    throw new Error('Li witness de Discovery 19 ne deve caminar avante ex Year 5000.');
  },
  previousYear() {
    throw new Error('Li witness de Discovery 19 ne deve caminar retro ex Year 5000.');
  }
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
  return {
    yearNumber: 5000n,
    actionDay,
    openingDay,
    closingDay
  };
}

function call(manager, calculationDay, gates) {
  return production.discovery19LegacyYearNumberCacheThroughMonsterPath(
    manager,
    calculationDay,
    calculationDay,
    -1n,
    gates,
    candidatePairs,
    selectionStream,
    noWalkExpected
  );
}

const lookupSource = production.legacyYearNumberOnlyLookup.toString();
assert.match(lookupSource, /cacheMap\.has\(yearNumber\)/);
assert.match(lookupSource, /cacheMap\.get\(yearNumber\)/);
assert.doesNotMatch(lookupSource, /actionDay|openingDay|closingDay|calculationDayFingerprint/);
assert.equal('oldStructureSauce' in production, false);

const cases = [
  {
    label: 'calculation-day',
    firstDay: f + 100n,
    firstGates: gatesBase(),
    secondDay: f + 101n,
    secondGates: gatesBase(),
    firstExpected: expectedValue(f + 100n, f + 10n, f + 1010n),
    secondExpected: expectedValue(f + 101n, f + 10n, f + 1010n)
  },
  {
    label: 'opening-gate',
    firstDay: f + 100n,
    firstGates: gatesBase(),
    secondDay: f + 100n,
    secondGates: gatesOpeningChangedOnly(),
    firstExpected: expectedValue(f + 100n, f + 10n, f + 1010n),
    secondExpected: expectedValue(f + 100n, f + 11n, f + 1010n)
  },
  {
    label: 'closing-gate',
    firstDay: f + 100n,
    firstGates: gatesBase(),
    secondDay: f + 100n,
    secondGates: gatesClosingChangedOnly(),
    firstExpected: expectedValue(f + 100n, f + 10n, f + 1010n),
    secondExpected: expectedValue(f + 100n, f + 10n, f + 1011n)
  }
];

const actualSecondValues = [];
const expectedSecondValues = [];
for (const scenario of cases) {
  const manager = new production.BaseMonsterManager();
  assert.ok(manager.LEGACY_STRUCTURE_CACHE_BY_YEAR_NUMBER instanceof Map);
  assert.equal(manager.LEGACY_STRUCTURE_CACHE_BY_YEAR_NUMBER.size, 0);

  const first = call(manager, scenario.firstDay, scenario.firstGates);
  assert.equal(first.result.hit, false, scenario.label);
  assert.equal(first.result.key, 5000n, scenario.label);
  assert.deepEqual(first.result.freshValue, scenario.firstExpected, scenario.label);
  assert.deepEqual(first.result.value, scenario.firstExpected, scenario.label);
  assert.equal(first.context.currentHandler, 'Discovery19YearNumberCacheHandler');
  assert.equal(first.context.previousHandler, 'SequentialYearWalkPatchWrapper');
  assert.equal(first.context.phase, 'DISCOVERY_19_YEAR_NUMBER_ONLY_CACHE');
  assert.equal(first.context.status, 'DISCOVERY_19_LEGACY_CACHE_RESULT');
  assert.equal(first.context.patch18SemanticYearNumber, 5000n);
  assert.equal(first.context.legacyYearCacheOnlyNumberKeyPreserved, true);
  assert.equal(first.context.legacyYearCacheHit, false);
  assert.equal(first.context.metrics['discovery19.yearNumberOnlyCache.calls'], 1n);
  assert.equal(first.context.metrics['discovery19.yearNumberOnlyCache.misses'], 1n);
  assert.equal(manager.LEGACY_STRUCTURE_CACHE_BY_YEAR_NUMBER.size, 1);

  const second = call(manager, scenario.secondDay, scenario.secondGates);
  assert.equal(second.result.hit, true, scenario.label);
  assert.equal(second.result.key, 5000n, scenario.label);
  assert.deepEqual(second.result.freshValue, scenario.secondExpected, scenario.label);
  assert.deepEqual(second.result.value, scenario.firstExpected, scenario.label);
  assert.notDeepEqual(second.result.value, scenario.secondExpected, scenario.label);
  assert.equal(second.context.legacyYearCacheHit, true);
  assert.deepEqual(second.context.legacyYearCacheStoredBefore, scenario.firstExpected);
  assert.equal(second.context.metrics['discovery19.yearNumberOnlyCache.calls'], 1n);
  assert.equal(second.context.metrics['discovery19.yearNumberOnlyCache.hits'], 1n);
  assert.equal(manager.LEGACY_STRUCTURE_CACHE_BY_YEAR_NUMBER.size, 1);
  assert.deepEqual(manager.LEGACY_STRUCTURE_CACHE_BY_YEAR_NUMBER.get(5000n), scenario.firstExpected);
  assert.deepEqual(second.context.branchTrace.slice(-3), [
    'DISCOVERY_18_OLD_JUMP_GUESS_365',
    'PATCH_18_SEQUENTIAL_YEAR_WALK',
    'DISCOVERY_19_YEAR_NUMBER_ONLY_CACHE'
  ]);

  actualSecondValues.push(second.result.value);
  expectedSecondValues.push(scenario.secondExpected);
}

console.log('DISCOVERY 19 DIAGNOSTIC: li cache legacy keyed solmen per year.number reutilisa un value stale quand li request cambia.');
for (let index = 0; index < cases.length; index += 1) {
  console.log(cases[index].label + ' legacy:   ' + JSON.stringify(actualSecondValues[index], (_, value) => typeof value === 'bigint' ? value.toString() : value));
  console.log(cases[index].label + ' current:  ' + JSON.stringify(expectedSecondValues[index], (_, value) => typeof value === 'bigint' ? value.toString() : value));
}

assert.deepEqual(
  actualSecondValues,
  expectedSecondValues,
  'DISCOVERY 19 EXPECTED RED: un HIT de cache ne posse esser acceptat solmen per year.number si calculation-day, opening gate o closing gate cambia.'
);
