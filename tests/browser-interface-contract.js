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
  "'pastafari-date'",
]) {
  assert(source.includes(token), 'Manca li extern contract-token: ' + token);
}
assert(source.includes("'lang'"), 'Li multilingue extension deve exponer li lang attribute.');
assert(source.includes('language-selector'), 'Li visibil selector de lingue manca.');
assert(source.includes('MAX_CACHED_CUTLETS = 5'), 'Li limitat UI cutlet-cache deve restar quin.');

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
  'outline: 6px solid #000000',
  '0 0 0 8px #ffea00',
  'border: 4px dashed #ffea00',
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

const page = fs.readFileSync(path.join(__dirname, '..', 'index.html'), 'utf8');
assert(page.includes('#f4f0e7'));
assert(page.includes('radial-gradient(circle at 12% 6%'));
assert(page.includes('<pastafari-date></pastafari-date>'));
assert(!page.includes('<pastafari-date lang="ie"'));

console.log('browser-interface-contract: PASS');
