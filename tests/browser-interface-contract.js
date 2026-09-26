'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');

const source = fs.readFileSync(path.join(__dirname, '..', 'browser', 'pastafari-date.js'), 'utf8');

for (const attribute of ['date', 'calculation-date', 'headless', 'no-editor']) {
  assert(source.includes("'" + attribute + "'"), 'Manca li extern attribute ' + attribute);
}
for (const token of [
  'get value()',
  'async refresh()',
  "'pastafari-change'",
  'this.ready = new Promise',
  'getPastafariDateAsync',
  'getPastafariDate: getPastafariDateAsync',
  'getPastafariCookingTraceAsync',
  'PastafariCookingElement',
  'cooking-open',
  "'pastafari-date'",
]) {
  assert(source.includes(token), 'Manca li extern contract-token: ' + token);
}
assert(source.includes("'lang'"), 'Li multilingue extension deve exponer li lang attribute.');
assert(source.includes('language-selector'), 'Li visibil selector de lingue manca.');
assert(source.includes('MAX_CACHED_CUTLETS = 5'), 'Li limitat UI cutlet-cache deve restar quin.');
assert(source.includes('MAX_RENDERED_DAYS = 28'), 'Li rendered day-window deve restar explicitmen bounded a 28.');
assert(source.includes('LONG_LOADING_DELAY_MS = 8000'), 'Li long-calculation orientation threshold deve restar explicit.');
assert(source.includes("this._t('loading.long')"), 'Li long calculation deve mutar a truthful local-running guidance.');
assert(source.includes('_clearLoadingNotice()'), 'Li loading guidance timer deve esser cancellabil.');

// Public visual contract inherited from the original site character.
for (const token of [
  'class="masthead"',
  '>PASTAFARI<',
  'class="search-panel"',
  'class="target-beacon"',
  'class="today-button"',
  "this._t('calendar.today')",
  "this._t('date.yearLine'",
  "doc.createElement('article')",
  "className = 'cutlet-grid'",
  'grid-template-columns: repeat(7',
  '#17130e',
  '#9d3825',
  'min-height: 6.4rem',
  'border: 1px solid var(--month-edge',
  'border-radius: .8rem',
  'border: 3px solid var(--accent-dark)',
  'background: #fff7e3',
  'transform: none',
  'box-shadow: 0 8px 20px rgb(54 36 20 / 20%)',
  '@media (max-width: 74rem)',
  'grid-template-columns: repeat(auto-fit, minmax(min(100%, 11rem), 1fr))',
  'unicode-bidi: isolate',
  'white-space: nowrap',
  "doc.createElement('bdi')",
  '.overlay.error .loading-title',
  'class="target-button"',
  'class="window-controls before"',
  'class="window-controls after"',
  'overflow: visible',
  "this._t('calendar.target')",
  "this._t('calendar.windowStatus'",
  "className = 'target-badge'",
  'MONTH_THEME_NAMES',
  'MONTH_THEMES',
  'semanticHash',
  '62% 88%',
  "card.className = 'day'",
  "LOCALE_STORAGE_KEY = 'pastafari.browser.locale'",
  'data-state="loading"',
  '.calendar[data-state="loading"] > .target-beacon',
  'width: min(100%, 42rem)',
]) {
  assert(source.includes(token), 'Manca li original-UI contract-token: ' + token);
}
assert(!source.includes("doc.createElement('button');\n        button.type = 'button';\n        button.className = 'day'"),
  'Li ordinary day-cards ne deve esser clickabil buttons.');
assert(!source.includes('_selectDay(event)'), 'Li old click-to-select day handler ne deve retornar.');
assert(!source.includes('transform: scale(1.035)'), 'Li selected card ne deve plu crescer extra su layout-box.');
assert(!source.includes('outline: 6px solid #000000'), 'Li clipped old six-pixel outline ne deve retornar.');
assert(!source.includes('0 0 0 8px #ffea00'), 'Li external yellow ring ne deve retornar.');
assert(!source.includes('#ffea00'), 'Li old high-noise yellow target treatment ne deve retornar.');
assert(!source.includes('border: 4px dashed'), 'Li old dashed target ring ne deve retornar.');
assert(source.includes('width: min(100%, 68rem)'), 'Li search card deve restar compact e bounded.');
assert(source.includes('font-size: clamp(2.5rem, 5.6vw, 5.2rem)'), 'Li masthead title deve restar visualmen bounded.');
assert(source.includes('.day-line.month'), 'Li day-card hierarchy deve dar un separat month line.');
assert(!source.includes("yearLine.className = 'day-line year'"), 'Li repeated year line ne deve retornar in omni day-card.');
assert(source.includes("cutletLine.textContent = this._t('field.day') + ' ' + String(day.dayInCutlet)"), 'Li compact day-in-cutlet line deve restar.');
assert(!source.includes('class="edge-loader'), 'Li old edge-loading scroll sentinels ne deve retornar.');
assert(!source.includes("this._els.viewport.addEventListener('scroll'"), 'Li calendar ne deve plu depender de nested-scroll edge loading.');
assert(!source.includes('max-height: var(--pastafari-calendar-height, 46rem)'), 'Li old internal vertical scroll viewport ne deve retornar.');
assert(source.includes('_cookingPagePosition'), 'Li calendar deve memorisar su page-position durant li modal trace.');
assert(source.includes('preventScroll: true'), 'Li trace-close focus return deve evitar involuntari scrolling.');
assert(source.includes('const reverseApi = ns.reverseBridge || null'), 'Li public UI deve usar li verified reverse bridge.');
assert(source.includes('class="reverse-open"'), 'Li public reverse-search entry point manca.');
assert(source.includes('class="reverse-dialog"'), 'Li public reverse-search dialog manca.');
assert(source.includes('class="reverse-form"'), 'Li public reverse-search form manca.');
for (const field of [
  'reverse-year',
  'reverse-cutlet',
  'reverse-day-cutlet',
  'reverse-month',
  'reverse-day-month',
  'reverse-calculation',
]) {
  assert(source.includes('name="' + field + '"'), 'Manca li reverse-search field: ' + field);
}
assert(source.includes('async _applyReverseDialog(event)'), 'Li reverse-search submit workflow manca.');
assert(source.includes('reverseApi.solveSimplePastafariDate'), 'Li reverse-search UI ne usa li verified bridge.');
assert(source.includes('timeoutMs: 120000'), 'Li reverse-search UI deve haver un explicit timeout.');
assert(source.includes('onProgress: (progress)'), 'Li reverse-search UI deve exponer truthful progress.');
assert(source.includes('_selectReverseResult(solution)'), 'Li reverse result ne retorna al ordinari target flow.');
assert(source.includes("date.setAttribute('dir', 'ltr')"), 'Li reverse Gregorian result deve esser BiDi-isolat.');
assert(source.includes("this.setAttribute('date', targetIso)"), 'Li reverse result deve usar li ordinari date attribute.');
assert(source.includes("this.setAttribute('calculation-date', calculationIso)"), 'Li reverse result deve conservar li calculation day.');
assert(source.includes('reverseOpen.hidden = !(reverseApi'), 'Li reverse entry point deve esser celat si li engine ne es disponibil.');

const reverseBridgeSource = fs.readFileSync(path.join(__dirname, '..', 'browser', 'reverse-bridge.js'), 'utf8');
assert(reverseBridgeSource.includes('async function solveSimplePastafariDate'));
assert(reverseBridgeSource.includes('moduleApi.solvePastafariConstraints(problem, options || {})'));
assert(reverseBridgeSource.includes('await service.convert(targetJdn, calc)'),
  'Omni reverse candidate deve esser verificat per li authoritative forward service.');
assert(reverseBridgeSource.includes('ERR_REVERSE_FORWARD_MISMATCH'),
  'Li reverse bridge deve fallir explicitmen si forward verification diverge.');
assert(reverseBridgeSource.includes('solutions: Object.freeze(verified)'),
  'Li reverse bridge deve publicar solmen verified solutions.');

const cookingSource = fs.readFileSync(path.join(__dirname, '..', 'browser', 'pastafari-cooking.js'), 'utf8');
for (const token of [
  'class PastafariCookingElement',
  "['date', 'calculation-date', 'lang', 'open']",
  "'pastafari-cooking'",
  '<dialog class="shell"',
  'aria-modal="true"',
  'height: min(52rem, calc(100dvh - 2rem))',
  'grid-template-rows: auto auto minmax(0, 1fr)',
  'flex-wrap: wrap',
  'grid-template-columns: repeat(2, minmax(0, 1fr))',
  'overscroll-behavior: contain',
  'async load(',
  '_loadGateDetail(',
  'gateDetailGateIndices',
  'onGateSauceDetail',
  "this._t('cooking.sameExecution')",
  'prefers-reduced-motion',
  '@media print',
]) {
  assert(cookingSource.includes(token), 'Manca li cooking-component contract-token: ' + token);
}
assert(!cookingSource.includes('calendarDateSpaghettiWithContext'));
assert(!cookingSource.includes('executeCalendarDate'));
assert(!cookingSource.includes('overflow-x: auto'), 'Li trace chapter navigation ne deve depender de hidden horizontal overflow.');

const page = fs.readFileSync(path.join(__dirname, '..', 'index.html'), 'utf8');
assert(page.includes('#f4f0e7'));
assert(page.includes('radial-gradient(circle at 12% 6%'));
assert(page.includes('<pastafari-date></pastafari-date>'));
assert(!page.includes('<pastafari-date lang="ie"'));

console.log('browser-interface-contract: PASS');
