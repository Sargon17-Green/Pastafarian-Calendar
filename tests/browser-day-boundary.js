'use strict';
const assert = require('assert');
const fs = require('fs');
const path = require('path');
const vm = require('vm');
const ROOT = path.resolve(__dirname, '..');
let instantMs = Date.parse('2026-11-13T18:00:00Z');
class ControlledDate extends Date {
  constructor(...args) { super(...(args.length ? args : [instantMs])); }
  static now() { return instantMs; }
}
const sandbox = { Date: ControlledDate, console, setTimeout, clearTimeout };
sandbox.globalThis = sandbox;
vm.createContext(sandbox);
for (const filename of ['venus-day-boundary.js', 'observer-location.js', 'date-axis.js']) {
  vm.runInContext(fs.readFileSync(path.join(ROOT, 'browser', filename), 'utf8'), sandbox, { filename });
}
const ns = sandbox.PastafariBrowserInternal;
const boundary = ns.venusDayBoundary;
const axis = ns.dateAxis;
const kisurra = ns.observerLocation.KISURRA_OBSERVER;
const nextJdn = 2461359n;
const transition = boundary.boundaryForDayJdn(nextJdn, kisurra).instant.getTime();
assert(Number.isFinite(transition), 'Venus transition must be finite.');
for (const [delta, expectedJdn] of [[-1000, 2461358n], [1000, nextJdn]]) {
  instantMs = transition + delta;
  assert.strictEqual(axis.currentDaySnapshot().jdn, expectedJdn);
  assert.strictEqual(axis.gregorianToJdn(axis.localToday()), expectedJdn);
}
const israel = { latitude: 32.0853, longitude: 34.7818, elevationM: 0 };
const israelTransition = boundary.boundaryForDayJdn(nextJdn, israel).instant.getTime();
assert(Math.abs(israelTransition - transition) > 5 * 60 * 1000);
axis.setObserver(israel);
instantMs = israelTransition + 1000;
assert.strictEqual(axis.currentDaySnapshot().jdn, nextJdn);
assert.strictEqual(axis.gregorianToJdn(axis.localToday()), nextJdn);
assert.strictEqual(axis.setObserver(israel), false);
assert.strictEqual(axis.gregorianToJdn(axis.parseIsoDate('2026-11-13')), 2461358n);
console.log('browser-day-boundary: PASS');
