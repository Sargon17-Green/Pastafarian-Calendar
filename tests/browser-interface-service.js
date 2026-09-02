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

const tabletsJdn = axis.gregorianToJdn({ year: -762n, month: 6, day: 7 });
assert.strictEqual(axis.jdnToProjectDay(tabletsJdn), -278522n);
assert.strictEqual(axis.projectDayToJdn(-278522n), tabletsJdn);

class Memory {
  constructor() {
    this.conversions = new Map();
    this.views = new Map();
    this.clearCount = 0;
  }
  key(c, t) { return String(c) + ':' + String(t); }
  getConversion(c, t) { return this.conversions.get(this.key(c, t)); }
  setConversion(c, t, value) { this.conversions.set(this.key(c, t), value); }
  getCutletView(c, t) { return this.views.get(this.key(c, t)); }
  setCutletView(c, t, value) { this.views.set(this.key(c, t), value); }
  clearCalculation(c) {
    const prefix = String(c) + ':';
    for (const key of Array.from(this.conversions.keys())) if (key.startsWith(prefix)) this.conversions.delete(key);
    for (const key of Array.from(this.views.keys())) if (key.startsWith(prefix)) this.views.delete(key);
  }
  clear() { this.conversions.clear(); this.views.clear(); this.clearCount += 1; }
}

let engineCalls = 0;
const fakeEngine = {
  async convert(calculationDay, targetDay) {
    engineCalls += 1;
    return ['5000', 'bronze', Number((targetDay % 5n + 5n) % 5n) + 1, 'argile', 1];
  },
  async getCutletView() { throw new Error('Ne usat in ti parte del prova.'); },
  retry() {},
  dispose() {},
};
const memory = new Memory();
const service = new ns.calendarService.CalendarService({ engineClient: fakeEngine, memory });

(async () => {
  const targetJdn = axis.projectDayToJdn(2n);
  const calculationJdn = axis.projectDayToJdn(10n);
  const first = await service.convert(targetJdn, calculationJdn);
  const second = await service.convert(targetJdn, calculationJdn);
  assert.deepStrictEqual(JSON.parse(JSON.stringify(first)), JSON.parse(JSON.stringify(second)));
  assert.strictEqual(engineCalls, 1, 'Li CalendarMemory seam deve evitar li duesim engine-call.');

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
