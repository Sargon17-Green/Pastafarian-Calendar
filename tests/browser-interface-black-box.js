'use strict';

const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const root = path.resolve(__dirname, '..');
const browserDir = path.join(root, 'browser');
const files = fs.readdirSync(browserDir).filter((name) => name.endsWith('.js'));
const sources = Object.fromEntries(files.map((name) => [name, fs.readFileSync(path.join(browserDir, name), 'utf8')]));
const worker = sources['pastafari-worker-entry.js'];

assert.match(worker, /core\.calendarDateSpaghetti\s*\(/, 'li worker deve invocar li public function de conversion quam cassa nigri');
for (const forbidden of [
  'calendarDateSpaghettiWithContext',
  '.context',
  '.structure',
  'STAGE57_GLOBAL_MANAGER',
  'STAGE58',
  'sharedPastafariRouter',
  'authoritative-only',
  'verifying',
  'fast engine',
]) {
  for (const [name, source] of Object.entries(sources)) {
    assert.equal(source.includes(forbidden), false, `${name} exposa un prohibit detalie de implementation: ${forbidden}`);
  }
}

const component = sources['pastafari-date.js'];
assert.match(component, /MAX_CACHED_CUTLETS\s*=\s*5/);
assert.match(component, /\["date", "calculation-date", "headless", "no-editor"\]/);
assert.match(component, /pastafari-change/);
assert.match(component, /getSharedCalendarService\(\)\.getCutletView|getSharedCalendarService\(\)/);

const service = sources['calendar-service.js'];
assert.match(service, /memory\.getConversion/);
assert.match(service, /memory\.getCutletView/);
assert.match(service, /memory\.clearCalculation/);

console.log('browser-interface-black-box: PASS');
