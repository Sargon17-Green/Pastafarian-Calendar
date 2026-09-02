'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '..');
const files = [
  'browser/pastafari-date.js',
  'browser/calendar-service.js',
  'browser/engine-client.js',
  'browser/pastafari-worker-entry.js',
  'browser/black-box-cutlet.js',
];

const joined = files.map((relative) => fs.readFileSync(path.join(ROOT, relative), 'utf8')).join('\n');
for (const forbidden of [
  'calendarDateSpaghettiWithContext',
  '.context.structure',
  'sharedPastafariRouter',
  'authoritative-only',
  'ERR_FAST_MISMATCH',
  'verifyFast',
]) {
  assert(!joined.includes(forbidden), 'Li browser-strate ne deve depender de: ' + forbidden);
}

const worker = fs.readFileSync(path.join(ROOT, 'browser', 'pastafari-worker-entry.js'), 'utf8');
assert(worker.includes('calendarDateSpaghetti'));
assert(!worker.includes('stage58'));
assert(!worker.includes('Stage58'));
assert(worker.includes('deriveCutletViewBlackBox'));

const i18nRuntime = fs.readFileSync(path.join(ROOT, 'browser', 'i18n', 'runtime.js'), 'utf8');
const localeSource = fs.readFileSync(path.join(ROOT, 'browser', 'i18n', 'locales.js'), 'utf8');
assert(i18nRuntime.includes("Object.prototype.hasOwnProperty.call(names, key)"));
assert(i18nRuntime.includes("group === 'cutlet'"));
assert(i18nRuntime.includes("group === 'month'"));
assert(!i18nRuntime.includes('return String(sourceName);'), 'Li presentation deve localisar calendar-nómines.');
assert(localeSource.includes("keyMode: 'source-text'"));
assert(localeSource.includes("larice: 'Larch'"));
assert(localeSource.includes("leopard: 'Leopard'"));
assert(!localeSource.includes("lagash:"), 'Li obsolete old positional cutlet key ne deve esser reintroductet.');
assert(!localeSource.includes("tiger:"), 'Li obsolete old positional month key ne deve esser reintroductet.');
assert(!localeSource.includes("susa:"), 'Li obsolete old positional month key ne deve esser reintroductet.');

const service = fs.readFileSync(path.join(ROOT, 'browser', 'calendar-service.js'), 'utf8');
assert(service.includes('installSharedCalendarMemory'));
assert(service.includes('getConversion'));
assert(service.includes('getCutletView'));

console.log('browser-interface-black-box: PASS');
