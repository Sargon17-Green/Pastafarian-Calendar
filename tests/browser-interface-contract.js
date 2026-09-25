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
  'min-height: 10.5rem',
  'border: 2px solid var(--month-edge',
  'border-radius: .85rem',
  'outline: 4px solid #000000',
  'inset 0 0 0 4px #ffea00',
  'transform: none',
  'border: 4px dashed #ffea00',
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
  '88% 49%',
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
assert(!source.includes('class="edge-loader'), 'Li old edge-loading scroll sentinels ne deve retornar.');
assert(!source.includes("this._els.viewport.addEventListener('scroll'"), 'Li calendar ne deve plu depender de nested-scroll edge loading.');
assert(!source.includes('max-height: var(--pastafari-calendar-height, 46rem)'), 'Li old internal vertical scroll viewport ne deve retornar.');

const cookingSource = fs.readFileSync(path.join(__dirname, '..', 'browser', 'pastafari-cooking.js'), 'utf8');
for (const token of [
  'class PastafariCookingElement',
  "['date', 'calculation-date', 'lang', 'open']",
  "'pastafari-cooking'",
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

const page = fs.readFileSync(path.join(__dirname, '..', 'index.html'), 'utf8');
assert(page.includes('#f4f0e7'));
assert(page.includes('radial-gradient(circle at 12% 6%'));
assert(page.includes('<pastafari-date></pastafari-date>'));
assert(!page.includes('<pastafari-date lang="ie"'));

console.log('browser-interface-contract: PASS');
