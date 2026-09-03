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

const context = vm.createContext({ console, setTimeout, clearTimeout });
load(context, 'browser/result-normalizer.js');
load(context, 'browser/date-axis.js');
load(context, 'browser/calendar-memory.js');

context.PastafariBrowserInternal.engineClient = {
  PastafariEngineClient: class {
    constructor() { throw new Error('Li default engine ne deve esser creat in ti prova.'); }
  },
};
load(context, 'browser/calendar-service.js');
load(context, 'browser/black-box-cutlet.js');

const ns = context.PastafariBrowserInternal;
const axis = ns.dateAxis;
const BoundedCalendarMemory = ns.calendarMemory.BoundedCalendarMemory;

function projectJdn(day) {
  return axis.projectDayToJdn(BigInt(day));
}

function rawResult(dayInCutlet, monthName) {
  return Object.freeze({
    year: '5000',
    cutletName: 'bronze',
    dayInCutlet,
    monthName: monthName || 'argile',
    dayInMonth: dayInCutlet,
  });
}

function makeView(startValue, endValue, selectedValue, cutletName) {
  const startDay = BigInt(startValue);
  const endDay = BigInt(endValue);
  const selectedDay = BigInt(selectedValue);
  const days = [];
  for (let day = startDay; day <= endDay; day += 1n) {
    const position = Number(day - startDay) + 1;
    days.push(Object.freeze({
      day,
      year: '5000',
      cutletName: cutletName || 'bronze',
      dayInCutlet: position,
      monthName: position <= 3 ? 'argile' : 'granat',
      dayInMonth: position <= 3 ? position : position - 3,
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
    cutletName: cutletName || 'bronze',
    days: Object.freeze(days),
  });
}

function resultForFiveDayView(targetDay) {
  const position = Number(targetDay) + 1;
  return [
    '5000',
    'bronze',
    position,
    position <= 3 ? 'argile' : 'granat',
    position <= 3 ? position : position - 3,
  ];
}

const tabletsJdn = axis.gregorianToJdn({ year: -762n, month: 6, day: 7 });
assert.strictEqual(axis.jdnToProjectDay(tabletsJdn), -278522n);
assert.strictEqual(axis.projectDayToJdn(-278522n), tabletsJdn);

(async () => {
  // Bounded semantic memory: LRU conversions, range-aware cutlets and calculation isolation.
  const bounded = new BoundedCalendarMemory({ maxConversions: 2, maxCutlets: 2 });
  bounded.setConversion(10n, 1n, rawResult(1));
  bounded.setConversion(10n, 2n, rawResult(2));
  assert.strictEqual(bounded.getConversion(10n, 1n).dayInCutlet, 1); // touch 10:1
  bounded.setConversion(10n, 3n, rawResult(3));
  assert.strictEqual(bounded.getConversion(10n, 2n), undefined, 'Li oldest conversion deve esser ejectet per LRU.');
  assert.strictEqual(bounded.getConversion(10n, 1n).dayInCutlet, 1);
  assert.strictEqual(bounded.getConversion(10n, 3n).dayInCutlet, 3);

  const firstView = makeView(0n, 4n, 2n);
  bounded.setCutletView(10n, 2n, firstView);
  const retargeted = bounded.getCutletView(10n, 3n);
  assert(retargeted, 'Un target intra un memorisat cutlet deve esser un range-hit.');
  assert.strictEqual(retargeted.selectedDay, 3n);
  assert.strictEqual(retargeted.selectedIndex, 3);
  assert.strictEqual(retargeted.days, firstView.days, 'Retargeting deve reutilisar li immutable day-array.');
  assert.strictEqual(bounded.getCutletView(11n, 3n), undefined, 'Cutlet memory deve esser isolat per calculationDay.');

  bounded.setCutletView(10n, 10n, makeView(10n, 14n, 10n, 'vulpe'));
  bounded.getCutletView(10n, 2n); // touch first view
  bounded.setCutletView(10n, 20n, makeView(20n, 24n, 20n, 'ren'));
  assert.strictEqual(bounded.getCutletView(10n, 12n), undefined, 'Li oldest cutlet deve esser ejectet per LRU.');
  assert(bounded.getCutletView(10n, 2n));
  assert(bounded.getCutletView(10n, 22n));
  bounded.clearCalculation(10n);
  assert.strictEqual(bounded.getConversion(10n, 1n), undefined);
  assert.strictEqual(bounded.getCutletView(10n, 2n), undefined);

  // A directly constructed CalendarService keeps the bounded in-memory default.
  // The shared browser service installs the persistent wrapper separately.
  let engineCalls = 0;
  const fakeEngine = {
    async convert(_calculationDay, targetDay) {
      engineCalls += 1;
      return ['5000', 'bronze', Number((targetDay % 5n + 5n) % 5n) + 1, 'argile', 1];
    },
    async getCutletView() { throw new Error('Ne usat in ti parte del prova.'); },
    retry() {},
    dispose() {},
  };
  const service = new ns.calendarService.CalendarService({ engineClient: fakeEngine });
  assert.strictEqual(service.memory.constructor.name, 'BoundedCalendarMemory');
  const targetJdn = projectJdn(2n);
  const calculationJdn = projectJdn(10n);
  const first = await service.convert(targetJdn, calculationJdn);
  const second = await service.convert(targetJdn, calculationJdn);
  assert.deepStrictEqual(JSON.parse(JSON.stringify(first)), JSON.parse(JSON.stringify(second)));
  assert.strictEqual(engineCalls, 1, 'Li default memory deve evitar li duesim engine-call.');

  // Concurrent identical conversion requests share one Worker operation.
  let concurrentCalls = 0;
  const concurrentEngine = {
    async convert() {
      concurrentCalls += 1;
      await new Promise((resolve) => setTimeout(resolve, 15));
      return ['5000', 'bronze', 2, 'argile', 2];
    },
    async getCutletView() { throw new Error('unexpected'); },
    retry() {},
    dispose() {},
  };
  const concurrentService = new ns.calendarService.CalendarService({ engineClient: concurrentEngine });
  const concurrentResults = await Promise.all([
    concurrentService.convert(projectJdn(1n), projectJdn(9n)),
    concurrentService.convert(projectJdn(1n), projectJdn(9n)),
    concurrentService.convert(projectJdn(1n), projectJdn(9n)),
  ]);
  assert.strictEqual(concurrentCalls, 1, 'Identic in-flight conversiones deve esser coalescet.');
  assert.strictEqual(concurrentResults.map((item) => item.dayInCutlet).join(','), '2,2,2');

  // A cached cutlet remains range-reusable, but every selected target must first have
  // an independently authoritative direct conversion. View-derived values never populate
  // the direct conversion cache.
  let viewCalls = 0;
  let directCallsForViews = 0;
  const rangeEngine = {
    async convert(_calculationDay, targetDay) {
      directCallsForViews += 1;
      return resultForFiveDayView(targetDay);
    },
    async getCutletView(_calculationDay, targetDay) {
      viewCalls += 1;
      await new Promise((resolve) => setTimeout(resolve, 10));
      return makeView(0n, 4n, targetDay);
    },
    retry() {},
    dispose() {},
  };
  const rangeService = new ns.calendarService.CalendarService({ engineClient: rangeEngine });
  const sameViewPair = await Promise.all([
    rangeService.getCutletView(projectJdn(2n), projectJdn(10n)),
    rangeService.getCutletView(projectJdn(2n), projectJdn(10n)),
  ]);
  assert.strictEqual(viewCalls, 1, 'Identic in-flight cutlet demandes deve esser coalescet.');
  assert.strictEqual(directCallsForViews, 1, 'Li direct authority por identic in-flight demandes deve esser coalescet.');
  assert.strictEqual(sameViewPair[0].selectedIndex, 2);

  const neighboringView = await rangeService.getCutletView(projectJdn(3n), projectJdn(10n));
  assert.strictEqual(viewCalls, 1, 'Un neighboring target in li sam cutlet deve esser servit ex cutlet memory.');
  assert.strictEqual(directCallsForViews, 2, 'Un nov target deve esser verificat per un direct conversion ante range reuse.');
  assert.strictEqual(neighboringView.selectedIndex, 3);
  assert.strictEqual(neighboringView.selectedJdn, projectJdn(3n));
  const neighboringConversion = await rangeService.convert(projectJdn(3n), projectJdn(10n));
  assert.strictEqual(directCallsForViews, 2, 'Li direct result verificat durant getCutletView deve esser reutilisat.');
  assert.strictEqual(neighboringConversion.dayInCutlet, 4);

  await rangeService.getCutletView(projectJdn(3n), projectJdn(11n));
  assert.strictEqual(viewCalls, 2, 'Li sam target sub un altri calculationDay ne deve compartir cutlet memory.');
  assert.strictEqual(directCallsForViews, 3, 'Calculation-day isolation vale anc por direct authority.');

  // Retry invalidates semantic memory generation even if an old custom request settles later.
  let staleCalls = 0;
  let releaseOld;
  const oldGate = new Promise((resolve) => { releaseOld = resolve; });
  const retryEngine = {
    async convert() {
      staleCalls += 1;
      if (staleCalls === 1) {
        await oldGate;
        return ['5000', 'bronze', 1, 'argile', 1];
      }
      return ['5000', 'bronze', 2, 'argile', 2];
    },
    async getCutletView() { throw new Error('unexpected'); },
    retry() {},
    dispose() {},
  };
  const retryService = new ns.calendarService.CalendarService({ engineClient: retryEngine });
  const stalePromise = retryService.convert(projectJdn(7n), projectJdn(30n));
  await new Promise((resolve) => setTimeout(resolve, 0));
  await retryService.retry(projectJdn(30n));
  releaseOld();
  const staleResult = await stalePromise;
  assert.strictEqual(staleResult.dayInCutlet, 1);
  const freshResult = await retryService.convert(projectJdn(7n), projectJdn(30n));
  assert.strictEqual(freshResult.dayInCutlet, 2);
  assert.strictEqual(staleCalls, 2, 'Un pre-retry completion ne deve repopular li semantic memory.');

  // Black-box cutlet normative fixture remains unchanged.
  const fakeConvert = async (_c, t) => {
    const position = Number((t % 5n + 5n) % 5n) + 1;
    return { year: '5000', cutletName: 'bronze', dayInCutlet: position, monthName: 'argile', dayInMonth: position };
  };
  const view = await ns.blackBoxCutlet.deriveCutletViewBlackBox({
    calculationDay: 10n,
    targetDay: 2n,
    convert: fakeConvert,
  });
  assert.strictEqual(view.startDay, 0n);
  assert.strictEqual(view.endDay, 4n);
  assert.strictEqual(view.previousCutletDay, -1n);
  assert.strictEqual(view.nextCutletDay, 5n);
  assert.strictEqual(view.days.length, 5);
  assert.strictEqual(Array.from(view.days, (day) => day.dayInCutlet).join(','), '1,2,3,4,5');

  console.log('browser-interface-service: PASS');
})().catch((error) => {
  console.error(error && error.stack ? error.stack : error);
  process.exitCode = 1;
});
