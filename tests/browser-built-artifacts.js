'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');
const vm = require('vm');

const ROOT = path.resolve(__dirname, '..');
const required = [
  'browser/dist/index.html',
  'browser/dist/build-id.txt',
  'browser/dist/pastafari-worker.js',
  'browser/dist/pastafari-date.js',
  'browser/dist/pastafari-date.mjs',
  'browser/standalone/pastafari-date.js',
  'browser/standalone/pastafari-date.min.js',
];

for (const relative of required) {
  const full = path.join(ROOT, relative);
  assert(fs.existsSync(full), 'Manca li build-artefact: ' + relative);
  assert(fs.statSync(full).size > 10, 'Li build-artefact es suspectmen curt: ' + relative);
}

for (const relative of required.filter((value) => value.endsWith('.js'))) {
  const source = fs.readFileSync(path.join(ROOT, relative), 'utf8');
  new vm.Script(source, { filename: relative });
}

const buildId = fs.readFileSync(path.join(ROOT, 'browser/dist/build-id.txt'), 'utf8').trim();
assert(/^[0-9a-f]{24}$/.test(buildId), 'Li browser build ID deve esser un curt SHA-256 fingerprint.');

const page = fs.readFileSync(path.join(ROOT, 'browser/dist/index.html'), 'utf8');
const standard = fs.readFileSync(path.join(ROOT, 'browser/dist/pastafari-date.js'), 'utf8');
const moduleFacade = fs.readFileSync(path.join(ROOT, 'browser/dist/pastafari-date.mjs'), 'utf8');
const standalone = fs.readFileSync(path.join(ROOT, 'browser/standalone/pastafari-date.js'), 'utf8');
const worker = fs.readFileSync(path.join(ROOT, 'browser/dist/pastafari-worker.js'), 'utf8');
const workerEntry = fs.readFileSync(path.join(ROOT, 'browser/pastafari-worker-entry.js'), 'utf8');

assert(page.includes('pastafari-date.js?v=' + buildId));
assert(!page.includes('__PASTAFARI_BROWSER_BUILD_ID__'));
assert(standard.includes('const buildId = ' + JSON.stringify(buildId)));
assert(standard.includes("pastafari-worker.js?v=' + encodeURIComponent(buildId)"));
assert(standard.includes('buildId,'));
assert(worker.includes('PastafariBrowserWorkerConfig'));
assert(worker.includes('buildId: ' + JSON.stringify(buildId)));
assert(worker.includes('ERR_BROWSER_BUILD_MISMATCH'));
assert(standalone.includes('buildId: ' + JSON.stringify(buildId)));
assert(standalone.includes('PastafariBrowserWorkerConfig'));
assert(moduleFacade.includes('export const buildId = api.buildId;'));

assert(standard.includes('PastafariBrowserLocaleData'));
for (const code of ['ie', 'en', 'he', 'ar', 'ru', 'fr', 'de', 'es', 'it', 'cs']) {
  assert(standard.includes("code: '" + code + "'") || standard.includes('\"code\": \"' + code + '\"'),
    'Manca li locale in li constructet standard bundle: ' + code);
}
assert(!standard.includes('locales.generated.js'));
assert(standard.includes('PastafariCalendarBrowser'));
assert(standard.includes('function createScrollTarget(targetJdn, value)'));
assert(standard.includes('this._scrollTarget = createScrollTarget(targetJdn, this._value)'));
assert(standard.includes('service.getCutletView(this._scrollTarget.startJdn, calculationJdn)'));
assert(standard.includes('resolveTargetCutletView(currentView, this._scrollTarget)'));
assert(standard.includes('this._positionTargetInViewport(this._scrollTarget)'));
assert(standard.includes('const isTarget = this._scrollTarget != null && sameScrollTargetDay(day, this._scrollTarget)'));
assert(standard.includes('exactTargetMatchCount'));
assert(standard.includes('ERR_TARGET_CUTLET_MISMATCH'));
assert(standard.includes('section.dataset.year = String(view.year)'));
assert(standard.includes('section.dataset.cutletName = String(view.cutletName)'));
assert(standard.includes('_positionElementInViewport(element, block)'));
assert(standard.includes('_positionCutletInViewport(startJdn)'));
assert(standard.includes('_captureViewportAnchor()'));
assert(standard.includes('_restoreViewportAnchor(anchor)'));
assert(standard.includes('_rerenderCutletsPreservingViewport(existingAnchor)'));
assert(standard.includes("section.className = 'cutlet-section'"));
assert(standard.includes("cutletLine.className = 'day-line cutlet-line'"));
assert(standard.includes("querySelectorAll('section.cutlet-section')"));
assert(standard.includes("closest('section.cutlet-section')"));
assert(standard.includes('await nextLayoutFrame()'));
assert(standard.includes('this._hideOverlays();\n        await nextLayoutFrame();'));
assert(!standard.includes("section.className = 'cutlet'"));
assert(!standard.includes("querySelectorAll('.cutlet')"));
assert(!standard.includes("closest('.cutlet')"));
assert(!standard.includes("cutletLine.className = 'day-line cutlet'"));
assert(!standard.includes('scrollIntoView('));
assert(!standard.includes('_scrollSelectedIntoView('));
assert.strictEqual((standard.match(/viewport\.scrollTop\s*=/g) || []).length, 1,
  'Omni browser scrolling deve esser possedet per un unic viewport.scrollTop primitive.');
assert(standard.includes('cacheNamespace'));
assert(standard.includes('pc-browser-core-368e258d1ca347f846f32d94'));
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
  // A stale main from an unversioned deployment cannot silently drive this Worker.
  const stale = evaluateBuiltWorker();
  await stale.handler({ data: {
    id: 900, operation: 'convert', calculationDay: '739862', targetDay: '739862',
  } });
  assert.strictEqual(stale.posted.length, 1);
  assert.strictEqual(stale.posted[0].ok, false);
  assert.strictEqual(stale.posted[0].buildId, buildId);
  assert.strictEqual(stale.posted[0].error.code, 'ERR_BROWSER_BUILD_MISMATCH');

  // Regression witness for the exact discrepancy that reached the public UI.
  const runtime = evaluateBuiltWorker();
  assert.strictEqual(typeof runtime.handler, 'function');
  const message = {
    operation: 'convert', calculationDay: '739862', targetDay: '739862', buildId,
  };

  await runtime.handler({ data: { id: 901, ...message } });
  assert.strictEqual(runtime.posted.length, 1);
  const response = runtime.posted[0];
  assert.strictEqual(response.ok, true, response.error && response.error.message);
  assert.strictEqual(response.buildId, buildId);
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
