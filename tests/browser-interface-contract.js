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
  'grid-template-columns: repeat(7',
  '#17130e',
  '#9d3825',
  'min-height: 178px',
  'border-top: 7px solid',
  'border-radius: 20px',
  'translateY(-4px)',
  'MONTH_THEMES',
  'semanticHash',
  "card.className = 'day mod'",
]) {
  assert(source.includes(token), 'Manca li original-UI contract-token: ' + token);
}
assert(!source.includes("doc.createElement('button');\n        button.type = 'button';\n        button.className = 'day'"),
  'Li ordinary day-cards ne deve esser clickabil buttons.');
assert(!source.includes('_selectDay(event)'), 'Li old click-to-select day handler ne deve retornar.');

console.log('browser-interface-contract: PASS');
