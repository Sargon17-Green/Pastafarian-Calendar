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
const workerEntry = fs.readFileSync(path.join(ROOT, 'browser/pastafari-worker-entry.js'), 'utf8');

assert(standard.includes('PastafariBrowserLocaleData'));
for (const code of ['ie', 'en', 'he', 'ar', 'ru', 'fr', 'de', 'es', 'it', 'cs']) {
  assert(standard.includes("code: '" + code + "'") || standard.includes('\"code\": \"' + code + '\"'),
    'Manca li locale in li constructet standard bundle: ' + code);
}
assert(!standard.includes('locales.generated.js'));
assert(standard.includes('PastafariCalendarBrowser'));
assert(standard.includes('pastafari-worker.js'));
assert(standard.includes('cacheNamespace'));
assert(standard.includes('pc-browser-core-'));
assert(standalone.includes('PastafariCalendarStandalone'));
assert(standalone.includes('workerSource'));
assert(standalone.includes('cacheNamespace'));
assert(worker.includes('calendarDateSpaghetti'));
assert(worker.includes('deriveCutletViewBlackBox'));

/*
 * Li build artefact contene li core self, ergo intern core identifiers posse
 * aparir quam implementation details. Li cassa-nigri limite deve esser verificat
 * al Worker entry: it posse invocar solmen li public calendarDateSpaghetti API.
 */
assert(workerEntry.includes('core.calendarDateSpaghetti('));
assert(!workerEntry.includes('calendarDateSpaghettiWithContext'));
assert(!workerEntry.includes('executeCalendarDate'));
assert(!workerEntry.includes('STAGE57_GLOBAL_MANAGER'));
assert(!workerEntry.includes('calendarDateSpaghettiWithContext('));

function evaluateBuiltWorker() {
  const listeners = new Map();
  const posted = [];
  const context = vm.createContext({
    console,
    setTimeout,
    clearTimeout,
    addEventListener(type, listener) { listeners.set(type, listener); },
    postMessage(message) { posted.push(message); },
  });
  context.globalThis = context;
  context.self = context;
  new vm.Script(worker, { filename: 'browser/dist/pastafari-worker.js' }).runInContext(context);
  return { handler: listeners.get('message'), posted };
}

(async () => {
  // Regression witness for the exact discrepancy that reached the public UI.
  // This pins which side of the observed public mismatch is semantically correct.
  const runtime = evaluateBuiltWorker();
  assert.strictEqual(typeof runtime.handler, 'function');
  const message = { operation: 'convert', calculationDay: '739862', targetDay: '739862' };

  await runtime.handler({ data: { id: 901, ...message } });
  assert.strictEqual(runtime.posted.length, 1);
  const response = runtime.posted[0];
  assert.strictEqual(response.ok, true, response.error && response.error.message);
  assert.deepStrictEqual(JSON.parse(JSON.stringify(response.value)), {
    year: '5000',
    cutletName: 'bronze',
    dayInCutlet: 677,
    monthName: 'sand',
    dayInMonth: 32,
  });

  console.log('browser-built-artifacts: PASS');
})().catch((error) => {
  console.error(error && error.stack ? error.stack : error);
  process.exitCode = 1;
});
