'use strict';

const assert = require('assert');
const crypto = require('crypto');
const fs = require('fs');
const path = require('path');
const vm = require('vm');
const childProcess = require('child_process');

const ROOT = path.resolve(__dirname, '..');
const required = [
  'browser/dist/index.html',
  'browser/dist/build-id.txt',
  'browser/dist/pastafari-worker.js',
  'browser/dist/pastafari-date.js',
  'browser/dist/pastafari-date.mjs',
  'browser/dist/reverse-engine/pastafari-diagnostics.js',
  'browser/dist/reverse-engine/pastafari-calendar-fast.js',
  'browser/dist/reverse-engine/pastafari-constraints.js',
  'browser/dist/reverse-engine/pastafari-reverse-worker.js',
  'browser/dist/reverse-engine/pastafari-constraints-client.js',
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
  if (relative.startsWith('browser/dist/reverse-engine/')) {
    childProcess.execFileSync(process.execPath, ['--input-type=module', '--check'], {
      input: source,
      stdio: ['pipe', 'ignore', 'pipe'],
    });
  } else {
    new vm.Script(source, { filename: relative });
  }
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
assert(standard.includes("reverse-engine/pastafari-constraints-client.js?v=' + encodeURIComponent(buildId)"));
assert(standard.includes('solveSimplePastafariDate'));
assert(standard.includes('ERR_REVERSE_FORWARD_MISMATCH'));
assert(standalone.includes('reverseClientUrl: null'));
assert(standard.includes('buildId,'));
assert(worker.includes('PastafariBrowserWorkerConfig'));
assert(worker.includes('buildId: ' + JSON.stringify(buildId)));
assert(worker.includes('ERR_BROWSER_BUILD_MISMATCH'));
assert(standalone.includes('buildId: ' + JSON.stringify(buildId)));
assert(standalone.includes('PastafariBrowserWorkerConfig'));
assert(moduleFacade.includes('export const buildId = api.buildId;'));
assert(moduleFacade.includes('export const getPastafariCookingTraceAsync = api.getPastafariCookingTraceAsync;'));
assert(moduleFacade.includes('export const PastafariCookingElement = api.PastafariCookingElement;'));
assert(standard.includes('class PastafariCookingElement'));
assert(standard.includes("customElements.define('pastafari-cooking'"));
assert(standard.includes('cooking.open'));
assert(standard.includes('<dialog class="shell"'));
assert(standard.includes('aria-modal="true"'));
assert(standard.includes('height: min(52rem, calc(100dvh - 2rem))'));
assert(standard.includes('grid-template-rows: auto auto auto minmax(0, 1fr)'));
assert(standard.includes(':host([live])'));
assert(standard.includes('monster-meatball'));
assert(standard.includes('sauce-drip'));
assert(standard.includes('beginLiveTrace()'));
assert(standard.includes('appendLiveProgress(event)'));
assert(standard.includes('finishLiveTrace(trace = null)'));
assert(standard.includes('grid-template-columns: repeat(2, minmax(0, 1fr))'));
assert(standard.includes('_syncDialogOpen()'));
assert(standard.includes('_cookingPagePosition'));
assert(!standard.includes('.nav {\n            display: flex;\n            gap: .45rem;\n            padding: .75rem clamp(1rem, 3vw, 2rem);\n            overflow-x: auto'));

assert(standard.includes('PastafariBrowserLocaleData'));
for (const code of ['ie', 'en', 'he', 'ar', 'ru', 'fr', 'de', 'es', 'it', 'cs']) {
  assert(standard.includes("code: '" + code + "'") || standard.includes('\"code\": \"' + code + '\"'),
    'Manca li locale in li constructet standard bundle: ' + code);
}
assert(!standard.includes('locales.generated.js'));
assert(standard.includes('PastafariCalendarBrowser'));
assert(standard.includes('function createScrollTarget(targetJdn, value)'));
assert(standard.includes('this._scrollTarget = createScrollTarget(targetJdn, this._value)'));
assert(standard.includes('const currentView = await service.getCutletView('));
assert(standard.includes('service.convertWithTrace(targetJdn, calculationJdn, progressSink)'));
assert(standard.includes("kind: 'view-start'"));
assert(standard.includes("kind: 'view-finished'"));
assert(standard.includes('resolveTargetCutletView(currentView, this._scrollTarget)'));
assert(standard.includes('this._positionTargetInViewport(this._scrollTarget)'));
assert(standard.includes('const isTarget = this._scrollTarget != null && sameScrollTargetDay(day, this._scrollTarget)'));
assert(standard.includes('exactTargetMatchCount'));
assert(standard.includes('ERR_TARGET_CUTLET_MISMATCH'));
assert(standard.includes('section.dataset.year = String(view.year)'));
assert(standard.includes('section.dataset.cutletName = String(view.cutletName)'));
assert(standard.includes('MAX_RENDERED_DAYS = 28'));
assert(standard.includes('_shiftWindow(direction)'));
assert(standard.includes('async _returnToTarget()'));
assert(standard.includes("class=\"window-controls before\""));
assert(standard.includes('overflow: visible'));
assert(standard.includes('this._trimCutlets(view.startJdn, view.startJdn)'));
assert(standard.includes("selected.scrollIntoView({ block: 'center', inline: 'nearest' })"));
assert(standard.includes("section.scrollIntoView({ block: 'start', inline: 'nearest' })"));
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
assert(!standard.includes('_positionElementInViewport('));
assert(!standard.includes('_positionCutletInViewport('));
assert(!standard.includes('_captureViewportAnchor('));
assert(!standard.includes('_restoreViewportAnchor('));
assert(!standard.includes('_rerenderCutletsPreservingViewport('));
assert(!standard.includes('_onScroll('));
assert(!standard.includes("viewport.scrollTop ="));
assert(!standard.includes('max-height: var(--pastafari-calendar-height, 46rem)'));
assert(!standard.includes('class="edge-loader'));
assert(!standard.includes('_scrollSelectedIntoView('));
assert(standard.includes('cacheNamespace'));
const expectedCoreFingerprint = crypto.createHash('sha256')
  .update(fs.readFileSync(path.join(ROOT, 'src/source-language-catalog.js'), 'utf8'), 'utf8')
  .update('\0', 'utf8')
  .update(fs.readFileSync(path.join(ROOT, 'src/index.js'), 'utf8'), 'utf8')
  .digest('hex')
  .slice(0, 24);
assert(standard.includes('pc-browser-core-' + expectedCoreFingerprint));
assert(standalone.includes('PastafariCalendarStandalone'));
assert(standalone.includes('workerSource'));
assert(standalone.includes('cacheNamespace'));
assert(worker.includes('calendarDateSpaghetti'));
assert(worker.includes('deriveCutletViewBlackBox'));
assert(worker.includes('PastafariBrowserCookingTrace'));
assert(worker.includes('calendarDateSpaghettiCookingTrace'));
assert(worker.includes("message.operation === 'cookingTrace'"));
assert(worker.includes("message.operation === 'convertWithTrace'"));
assert(worker.includes("kind: 'progress'"));

/*
 * Li build artefact contene li core self, ergo intern core identifiers posse
 * aparir quam implementation details. Li cassa-nigri limite deve esser verificat
 * al Worker entry: ordinari conversion usa li public calendarDateSpaghetti API;
 * cooking trace usa solmen su dedicat normative adapter, ne intern managers.
 */
assert(workerEntry.includes('core.calendarDateSpaghetti('));
assert(workerEntry.includes('cookingTraceApi.calendarDateSpaghettiCookingTrace('));
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
    id: 900, operation: 'convert', calculationDay: '-15055671', targetDay: '-15055671',
  } });
  assert.strictEqual(stale.posted.length, 1);
  assert.strictEqual(stale.posted[0].ok, false);
  assert.strictEqual(stale.posted[0].buildId, buildId);
  assert.strictEqual(stale.posted[0].error.code, 'ERR_BROWSER_BUILD_MISMATCH');

  // Regression witness for the exact discrepancy that reached the public UI.
  const runtime = evaluateBuiltWorker();
  assert.strictEqual(typeof runtime.handler, 'function');
  const message = {
    operation: 'convert', calculationDay: '-15055671', targetDay: '-15055671', buildId,
  };

  await runtime.handler({ data: { id: 901, ...message } });
  assert.strictEqual(runtime.posted.length, 1);
  const response = runtime.posted[0];
  assert.strictEqual(response.ok, true, response.error && response.error.message);
  assert.strictEqual(response.buildId, buildId);
  assert.deepStrictEqual(JSON.parse(JSON.stringify(response.value)), {
    year: '5000',
    cutletName: 'scorpion',
    dayInCutlet: 503,
    monthName: 'pute',
    dayInMonth: 56,
  });

  // The built Worker must also execute the bundled normative cooking trace.
  const traceRuntime = evaluateBuiltWorker();
  await traceRuntime.handler({ data: {
    id: 902,
    operation: 'cookingTrace',
    calculationDay: '-15055671',
    targetDay: '-15055671',
    buildId,
  } });
  assert.strictEqual(traceRuntime.posted.length, 1);
  const traceResponse = traceRuntime.posted[0];
  assert.strictEqual(traceResponse.ok, true, traceResponse.error && traceResponse.error.message);
  assert.strictEqual(traceResponse.kind, 'result');
  assert.strictEqual(traceResponse.buildId, buildId);
  assert.strictEqual(traceResponse.value.schemaVersion, '0.4.0');
  assert.deepStrictEqual(JSON.parse(JSON.stringify(traceResponse.value.finalResult)), {
    year: '5000',
    cutlet: { canonicalIndex: 10, sourceName: 'scorpion' },
    dayInCutlet: '503',
    month: { canonicalIndex: 20, sourceName: 'pute' },
    dayInMonth: '56',
  });

  assert(worker.includes("semanticRule: 'post-stir-u-uses-saved-order-number'"));
  assert.ok(!worker.includes("semanticRule: 'post-stir-u-uses-raw-bowl-sum'"));

  console.log('browser-built-artifacts: PASS');
})().catch((error) => {
  console.error(error && error.stack ? error.stack : error);
  process.exitCode = 1;
});
