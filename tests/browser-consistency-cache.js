'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');
const vm = require('vm');

const ROOT = path.resolve(__dirname, '..');

function load(context, relativePath) {
  const source = fs.readFileSync(path.join(ROOT, relativePath), 'utf8');
  new vm.Script(source, { filename: relativePath }).runInContext(context);
}

function makeLocalStorage() {
  const data = new Map();
  return {
    get length() { return data.size; },
    key(index) { return Array.from(data.keys())[index] || null; },
    getItem(key) { return data.has(String(key)) ? data.get(String(key)) : null; },
    setItem(key, value) { data.set(String(key), String(value)); },
    removeItem(key) { data.delete(String(key)); },
    clear() { data.clear(); },
  };
}

const localStorage = makeLocalStorage();
const context = vm.createContext({
  console,
  setTimeout,
  clearTimeout,
  localStorage,
  PastafariBrowserConfig: Object.freeze({ cacheNamespace: 'test-core-fingerprint' }),
});
context.globalThis = context;

load(context, 'browser/result-normalizer.js');
load(context, 'browser/date-axis.js');
load(context, 'browser/calendar-memory.js');
context.PastafariBrowserInternal.engineClient = {
  PastafariEngineClient: class {
    constructor() { throw new Error('Li default engine ne deve esser creat in ti prova.'); }
  },
};
load(context, 'browser/calendar-service.js');

const ns = context.PastafariBrowserInternal;
const axis = ns.dateAxis;
const PersistentCalendarMemory = ns.calendarMemory.PersistentCalendarMemory;
const CalendarService = ns.calendarService.CalendarService;

function projectJdn(day) {
  return axis.projectDayToJdn(BigInt(day));
}

function makeView(startValue, endValue, selectedValue, selectedMonth, selectedDayInMonth) {
  const startDay = BigInt(startValue);
  const endDay = BigInt(endValue);
  const selectedDay = BigInt(selectedValue);
  const days = [];
  for (let day = startDay; day <= endDay; day += 1n) {
    const position = Number(day - startDay) + 1;
    const isSelected = day === selectedDay;
    days.push(Object.freeze({
      day,
      year: '5000',
      cutletName: 'bronze',
      dayInCutlet: position,
      monthName: isSelected ? selectedMonth : 'argile',
      dayInMonth: isSelected ? selectedDayInMonth : position,
    }));
  }
  return Object.freeze({
    selectedDay,
    selectedIndex: Number(selectedDay - startDay),
    startDay,
    endDay,
    previousCutletDay: startDay - 1n,
    nextCutletDay: endDay + 1n,
    year: '5000',
    cutletName: 'bronze',
    days: Object.freeze(days),
  });
}

(async () => {
  // Schema 2 could contain an already-poisoned direct conversion from an older
  // browser session. Schema 3 must ignore and remove that legacy storage before
  // CalendarService gets a chance to trust it as a direct conversion authority.
  const legacyStorage = makeLocalStorage();
  const legacyNamespace = 'pc-browser-core-legacy-poison-test';
  const legacyTargetJdn = 739862n;
  const legacyCalculationJdn = 739862n;
  const legacyTargetDay = axis.jdnToProjectDay(legacyTargetJdn);
  const legacyCalculationDay = axis.jdnToProjectDay(legacyCalculationJdn);
  const legacyPairKey = String(legacyCalculationDay) + ':' + String(legacyTargetDay);
  const legacyStorageKey = 'pastafari-calendar-cache:' + legacyNamespace + ':schema-2';
  legacyStorage.setItem(legacyStorageKey, JSON.stringify({
    schemaVersion: 2,
    conversions: [{
      key: legacyPairKey,
      value: {
        year: '5000',
        cutletName: 'bronze',
        dayInCutlet: 677,
        monthName: 'costa',
        dayInMonth: 12,
      },
    }],
    cutlets: [],
  }));

  const migratedMemory = new PersistentCalendarMemory({
    namespace: legacyNamespace,
    storage: legacyStorage,
  });
  assert.strictEqual(
    migratedMemory.getConversion(legacyCalculationDay, legacyTargetDay),
    undefined,
    'Schema 3 ne deve leer un conversion direct poisonat ex schema 2.',
  );
  assert.strictEqual(
    legacyStorage.getItem(legacyStorageKey),
    null,
    'Li obsolete schema-2 storage deve esser removet durant migration.',
  );

  let migratedEngineCalls = 0;
  const canonicalAfterMigration = {
    async convert() {
      migratedEngineCalls += 1;
      return ['5000', 'bronze', 677, 'sand', 32];
    },
    async getCutletView() { throw new Error('Li cutlet-view ne es parte de ti migration-prova.'); },
    retry() {},
    dispose() {},
  };
  const migratedService = new CalendarService({
    engineClient: canonicalAfterMigration,
    memory: migratedMemory,
  });
  const migratedResult = await migratedService.convert(legacyTargetJdn, legacyCalculationJdn);
  assert.strictEqual(migratedEngineCalls, 1, 'Pos migration li direct authority deve esser recalculat ex li engine.');
  assert.strictEqual(migratedResult.monthName, 'sand');
  assert.strictEqual(migratedResult.dayInMonth, 32);
  assert.ok(
    legacyStorage.getItem('pastafari-calendar-cache:' + legacyNamespace + ':schema-3'),
    'Li recalculat result deve esser persistet solmen sub schema 3.',
  );

  // Persistent memory survives a new CalendarService instance on the same browser storage.
  const memoryA = new PersistentCalendarMemory({
    namespace: 'test-core-fingerprint',
    storage: localStorage,
    maxPersistedConversions: 8,
    maxPersistedCutlets: 2,
  });
  const targetDay = 2n;
  const calculationDay = 10n;
  const targetJdn = projectJdn(targetDay);
  const calculationJdn = projectJdn(calculationDay);
  const canonical = Object.freeze({
    year: '5000', cutletName: 'bronze', dayInCutlet: 3, monthName: 'argile', dayInMonth: 3,
  });
  const view = makeView(0n, 4n, targetDay, 'argile', 3);
  memoryA.setConversion(calculationDay, targetDay, canonical);
  memoryA.setCutletView(calculationDay, targetDay, view);

  let persistentEngineCalls = 0;
  const neverEngine = {
    async convert() { persistentEngineCalls += 1; throw new Error('Persistent conversion miss.'); },
    async getCutletView() { persistentEngineCalls += 1; throw new Error('Persistent cutlet miss.'); },
    retry() {},
    dispose() {},
  };
  const memoryB = new PersistentCalendarMemory({
    namespace: 'test-core-fingerprint',
    storage: localStorage,
    maxPersistedConversions: 8,
    maxPersistedCutlets: 2,
  });
  const persistentService = new CalendarService({ engineClient: neverEngine, memory: memoryB });
  const persistedConversion = await persistentService.convert(targetJdn, calculationJdn);
  const persistedView = await persistentService.getCutletView(targetJdn, calculationJdn);
  assert.strictEqual(persistedConversion.monthName, 'argile');
  assert.strictEqual(persistedView.days[persistedView.selectedIndex].monthName, 'argile');
  assert.strictEqual(persistentEngineCalls, 0, 'Li duesim page-load deve usar li persistent exact cache sin Worker.');

  // Different core fingerprint means a clean namespace; stale semantic values cannot cross builds.
  const memoryOtherBuild = new PersistentCalendarMemory({
    namespace: 'different-core-fingerprint',
    storage: localStorage,
  });
  assert.strictEqual(memoryOtherBuild.getConversion(calculationDay, targetDay), undefined);
  assert.strictEqual(memoryOtherBuild.getCutletView(calculationDay, targetDay), undefined);

  // Reproduce the critical class of bug: direct result says sand 32, the first
  // cutlet scan says costa 12. The service must discard the bad view, recreate the
  // Worker once, and accept only a clean view that agrees with the direct authority.
  let retries = 0;
  let divergentViewCalls = 0;
  const divergentEngine = {
    async convert() {
      return ['5000', 'bronze', 3, 'sand', 32];
    },
    async getCutletView(_calculationDay, requestedTarget) {
      divergentViewCalls += 1;
      return makeView(
        requestedTarget - 2n,
        requestedTarget + 2n,
        requestedTarget,
        divergentViewCalls === 1 ? 'costa' : 'sand',
        divergentViewCalls === 1 ? 12 : 32,
      );
    },
    retry() { retries += 1; },
    dispose() {},
  };
  const divergentMemory = new PersistentCalendarMemory({
    namespace: 'divergence-test',
    storage: makeLocalStorage(),
  });
  const divergentService = new CalendarService({ engineClient: divergentEngine, memory: divergentMemory });
  const direct = await divergentService.convert(targetJdn, calculationJdn);
  assert.strictEqual(direct.monthName, 'sand');
  assert.strictEqual(direct.dayInMonth, 32);
  const recoveredView = await divergentService.getCutletView(targetJdn, calculationJdn);
  assert.strictEqual(retries, 1, 'Un semantic divergence deve recrear li Worker exactmen un vez.');
  assert.strictEqual(divergentViewCalls, 2, 'Li divergent view deve esser recalculat ex un clean Worker.');
  assert.strictEqual(recoveredView.days[recoveredView.selectedIndex].monthName, 'sand');
  assert.strictEqual(recoveredView.days[recoveredView.selectedIndex].dayInMonth, 32);
  assert.strictEqual(divergentMemory.getConversion(calculationDay, targetDay).monthName, 'sand',
    'Solmen li direct authoritative result posse restar in conversion cache.');

  // If a clean Worker still disagrees, fail closed and purge the calculation instead
  // of choosing one result silently or poisoning persistent storage.
  let hardRetries = 0;
  const alwaysDivergentEngine = {
    async convert() { return ['5000', 'bronze', 3, 'sand', 32]; },
    async getCutletView(_calculationDay, requestedTarget) {
      return makeView(requestedTarget - 2n, requestedTarget + 2n, requestedTarget, 'costa', 12);
    },
    retry() { hardRetries += 1; },
    dispose() {},
  };
  const hardMemory = new PersistentCalendarMemory({
    namespace: 'hard-divergence-test',
    storage: makeLocalStorage(),
  });
  const hardService = new CalendarService({ engineClient: alwaysDivergentEngine, memory: hardMemory });
  await assert.rejects(
    hardService.getCutletView(targetJdn, calculationJdn),
    (error) => error && error.code === 'ERR_CALENDAR_INCONSISTENCY' && error.name === 'CalendarConsistencyError',
    'Un divergence quel survive un clean Worker deve fallir cludet.',
  );
  assert.strictEqual(hardRetries, 2, 'Li Worker es recreat ante li retry e purgat denov pos un persistent divergence.');
  assert.strictEqual(hardMemory.getConversion(calculationDay, targetDay), undefined);
  assert.strictEqual(hardMemory.getCutletView(calculationDay, targetDay), undefined);

  // A consistent direct/view pair remains cacheable.
  let consistentViewCalls = 0;
  const consistentEngine = {
    async convert() { return ['5000', 'bronze', 3, 'sand', 32]; },
    async getCutletView(_calculationDay, requestedTarget) {
      consistentViewCalls += 1;
      return makeView(requestedTarget - 2n, requestedTarget + 2n, requestedTarget, 'sand', 32);
    },
    retry() {},
    dispose() {},
  };
  const consistentMemory = new PersistentCalendarMemory({
    namespace: 'consistent-test',
    storage: makeLocalStorage(),
  });
  const consistentService = new CalendarService({ engineClient: consistentEngine, memory: consistentMemory });
  const firstView = await consistentService.getCutletView(targetJdn, calculationJdn);
  const secondView = await consistentService.getCutletView(targetJdn, calculationJdn);
  assert.strictEqual(firstView.days[firstView.selectedIndex].monthName, 'sand');
  assert.strictEqual(secondView.days[secondView.selectedIndex].dayInMonth, 32);
  assert.strictEqual(consistentViewCalls, 1, 'Li verified cutlet-view deve esser reutilisat ex memory.');

  console.log('browser-consistency-cache: PASS');
})().catch((error) => {
  console.error(error && error.stack ? error.stack : error);
  process.exitCode = 1;
});
