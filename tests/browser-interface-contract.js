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

console.log('browser-interface-contract: PASS');
