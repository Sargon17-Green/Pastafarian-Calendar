'use strict';

const assert = require('node:assert/strict');
const path = require('node:path');
const { pathToFileURL } = require('node:url');

const root = path.resolve(__dirname, '..');
const url = (name) => pathToFileURL(path.join(root, 'browser', name)).href;

(async () => {
  const axis = await import(url('date-axis.js'));
  const { normalizeCalendarResult } = await import(url('result-normalizer.js'));
  const { deriveCutletViewBlackBox } = await import(url('black-box-cutlet.js'));
  const { CalendarService } = await import(url('calendar-service.js'));

  const epochJdn = axis.gregorianToJdn({ year: 1n, month: 1, day: 1 });
  assert.equal(epochJdn, 1721426n);
  assert.equal(axis.jdnToProjectDay(epochJdn), 1n);
  assert.equal(axis.projectDayToJdn(1n), epochJdn);
  for (const date of [
    { year: -762n, month: 6, day: 7 },
    { year: 1n, month: 1, day: 1 },
    { year: 2026n, month: 9, day: 2 },
    { year: 12026n, month: 12, day: 31 },
  ]) {
    assert.deepEqual(axis.jdnToGregorian(axis.gregorianToJdn(date)), date);
  }

  assert.deepEqual(normalizeCalendarResult([5000n, 'Cutlet', 3n, 'Mensu', 4n]), {
    year: '5000', cutletName: 'Cutlet', dayInCutlet: 3, monthName: 'Mensu', dayInMonth: 4,
  });
  assert.throws(() => normalizeCalendarResult([1n, 'C', 0n, 'M', 1n]), /dayInCutlet/);

  const floorDiv = (a, b) => {
    let q = a / b; const r = a % b;
    if (r !== 0n && ((r > 0n) !== (b > 0n))) q -= 1n;
    return q;
  };
  let blackBoxCalls = 0;
  const syntheticConvert = async (_c, t) => {
    blackBoxCalls += 1;
    const start = floorDiv(t, 4n) * 4n;
    const index = Number(t - start);
    return Object.freeze({
      year: String(1000n + floorDiv(start, 16n)),
      cutletName: `C${start}`,
      dayInCutlet: index + 1,
      monthName: index < 2 ? 'A' : 'B',
      dayInMonth: index % 2 + 1,
    });
  };
  const view = await deriveCutletViewBlackBox({ calculationDay: 20n, targetDay: 6n, convert: syntheticConvert });
  assert.equal(view.startDay, 4n);
  assert.equal(view.endDay, 7n);
  assert.equal(view.selectedIndex, 2);
  assert.equal(view.previousCutletDay, 3n);
  assert.equal(view.nextCutletDay, 8n);
  assert.deepEqual(view.days.map((day) => day.dayInCutlet), [1, 2, 3, 4]);
  assert.ok(blackBoxCalls >= 4);

  class Memory {
    constructor() { this.conversions = new Map(); this.views = new Map(); }
    key(c, t) { return `${c}:${t}`; }
    async getConversion(c, t) { return this.conversions.get(this.key(c, t)); }
    async setConversion(c, t, v) { this.conversions.set(this.key(c, t), v); }
    async getCutletView(c, t) { return this.views.get(this.key(c, t)); }
    async setCutletView(c, t, v) { this.views.set(this.key(c, t), v); }
    async clearCalculation(c) {
      const prefix = `${c}:`;
      for (const key of [...this.conversions.keys()]) if (key.startsWith(prefix)) this.conversions.delete(key);
      for (const key of [...this.views.keys()]) if (key.startsWith(prefix)) this.views.delete(key);
    }
    async clear() { this.conversions.clear(); this.views.clear(); }
  }
  const engine = {
    convertCalls: 0,
    viewCalls: 0,
    async convert(c, t) { this.convertCalls += 1; return syntheticConvert(c, t); },
    async getCutletView(c, t) {
      this.viewCalls += 1;
      return deriveCutletViewBlackBox({ calculationDay: c, targetDay: t, convert: syntheticConvert });
    },
    async retry() {},
    dispose() {},
  };
  const service = new CalendarService({ engineClient: engine, memory: new Memory() });
  const targetJdn = axis.projectDayToJdn(6n);
  const calcJdn = axis.projectDayToJdn(20n);
  const first = await service.convert(targetJdn, calcJdn);
  const second = await service.convert(targetJdn, calcJdn);
  assert.deepEqual(second, first);
  assert.equal(engine.convertCalls, 1, 'li punctu de memorisation deve posser evitar un repetit invocation del motor');
  const jdnView1 = await service.getCutletView(targetJdn, calcJdn);
  const jdnView2 = await service.getCutletView(targetJdn, calcJdn);
  assert.equal(engine.viewCalls, 1);
  assert.equal(jdnView1.startJdn, axis.projectDayToJdn(4n));
  assert.equal(jdnView2.days[2].jdn, targetJdn);

  console.log('browser-interface-service: PASS');
})().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
