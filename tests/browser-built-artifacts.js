'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');
const vm = require('vm');

const ROOT = path.resolve(__dirname, '..');
const required = [
  'browser/dist/pastafari-worker.js',
  'browser/dist/pastafari-date.js',
  'browser/dist/pastafari-date.mjs',
  'browser/standalone/pastafari-date.js',
  'browser/standalone/pastafari-date.min.js',
];

for (const relative of required) {
  const full = path.join(ROOT, relative);
  assert(fs.existsSync(full), 'Manca li build-artefact: ' + relative);
  assert(fs.statSync(full).size > 100, 'Li build-artefact es suspectmen curt: ' + relative);
}

for (const relative of required.filter((value) => value.endsWith('.js'))) {
  const source = fs.readFileSync(path.join(ROOT, relative), 'utf8');
  new vm.Script(source, { filename: relative });
}

const standard = fs.readFileSync(path.join(ROOT, 'browser/dist/pastafari-date.js'), 'utf8');
const standalone = fs.readFileSync(path.join(ROOT, 'browser/standalone/pastafari-date.js'), 'utf8');
const worker = fs.readFileSync(path.join(ROOT, 'browser/dist/pastafari-worker.js'), 'utf8');

assert(standard.includes('PastafariBrowserLocaleData'));
assert(standard.includes("code: 'ie'"));
assert(standard.includes("code: 'en'"));
assert(!standard.includes('locales.generated.js'));
assert(standard.includes('PastafariCalendarBrowser'));
assert(standard.includes('pastafari-worker.js'));
assert(standalone.includes('PastafariCalendarStandalone'));
assert(standalone.includes('workerSource'));
assert(worker.includes('calendarDateSpaghetti'));
assert(worker.includes('deriveCutletViewBlackBox'));
assert(!worker.includes('calendarDateSpaghettiWithContext'));

console.log('browser-built-artifacts: PASS');
