'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');
const vm = require('vm');

const ROOT = path.resolve(__dirname, '..');
const { SourceLanguageCatalog } = require(path.join(ROOT, 'src', 'source-language-catalog.js'));
const REQUIRED_MESSAGES = Object.freeze([
  'app.title',
  'language.label',
  'loading.kicker',
  'loading.title',
  'error.kicker',
  'error.reload',
  'error.timeout',
  'error.engineFailed',
  'error.engineLoadFailed',
  'calendar.toolbarAria',
  'calendar.previous',
  'calendar.next',
  'calendar.daysAria',
  'calendar.currentCutlet',
  'calendar.cutletDescription',
  'search.kicker',
  'search.heading',
  'search.submit',
  'search.invalid',
  'settings.summary',
  'settings.heading',
  'settings.invalid',
  'reverse.action.cancel',
  'field.day',
  'date.aria',
  'date.cutletLine',
  'date.monthLine',
]);

const sandbox = {
  Intl,
  globalThis: null,
};
sandbox.globalThis = sandbox;
vm.createContext(sandbox);
for (const relative of ['browser/i18n/locales.js', 'browser/i18n/runtime.js']) {
  vm.runInContext(fs.readFileSync(path.join(ROOT, relative), 'utf8'), sandbox, { filename: relative });
}

const data = sandbox.PastafariBrowserLocaleData;
assert(data);
assert.strictEqual(data.schemaVersion, 2);
assert.strictEqual(data.defaultLocale, 'ie');
assert.deepStrictEqual(Array.from(data.locales, (locale) => locale.code), ['ie', 'en']);

const sourceCutlets = SourceLanguageCatalog.cutlets.map((row) => row.text).sort();
const sourceMonths = SourceLanguageCatalog.months.map((row) => row.text).sort();
assert.strictEqual(sourceCutlets.length, 17);
assert.strictEqual(sourceMonths.length, 47);

for (const locale of data.locales) {
  assert.strictEqual(locale.dir, 'ltr');
  for (const key of REQUIRED_MESSAGES) {
    assert.strictEqual(typeof locale.messages[key], 'string', locale.code + ' manca ' + key);
    assert(locale.messages[key].trim().length > 0, locale.code + ' have vacui ' + key);
  }

  assert(locale.calendar, locale.code + ' manca calendar names');
  assert.strictEqual(locale.calendar.keyMode, 'source-text');
  assert.strictEqual(locale.calendar.sourceCatalogVersion, SourceLanguageCatalog.version);
  assert.deepStrictEqual(Object.keys(locale.calendar.cutlets).sort(), sourceCutlets, locale.code + ' cutlet coverage mismatch');
  assert.deepStrictEqual(Object.keys(locale.calendar.months).sort(), sourceMonths, locale.code + ' month coverage mismatch');
  for (const value of Object.values(locale.calendar.cutlets).concat(Object.values(locale.calendar.months))) {
    assert.strictEqual(typeof value, 'string');
    assert(value.trim().length > 0);
  }
}

const i18n = sandbox.PastafariBrowserInternal.i18n;
const ie = i18n.resolveLocale('ie', []);
const en = i18n.resolveLocale('en', []);
assert.strictEqual(i18n.resolveLocale('en-US', []).code, 'en');
assert.strictEqual(i18n.resolveLocale(null, ['en-GB']).code, 'en');
assert.strictEqual(i18n.resolveLocale(null, ['he']).code, 'ie');
assert.strictEqual(i18n.translate(en, 'field.day'), 'Day');
assert.strictEqual(i18n.translate(ie, 'field.day'), 'Die');

// Regression witnesses: current source identities, not the old positional table.
assert.strictEqual(i18n.calendarName(ie, 'cutlet', 'larice'), 'larice');
assert.strictEqual(i18n.calendarName(en, 'cutlet', 'larice'), 'Larch');
assert.strictEqual(i18n.calendarName(ie, 'month', 'leopard'), 'leopard');
assert.strictEqual(i18n.calendarName(en, 'month', 'leopard'), 'Leopard');
assert.strictEqual(i18n.calendarName(en, 'month', 'lilie'), 'Lily');
assert.strictEqual(i18n.calendarName(en, 'month', 'candel'), 'Candle');

// Obsolete old-table identities must never be accepted as aliases by position.
assert.throws(() => i18n.calendarName(en, 'cutlet', 'lagash'), /Manca li cutlet-nómine/);
assert.throws(() => i18n.calendarName(en, 'month', 'tiger'), /Manca li month-nómine/);
assert.throws(() => i18n.calendarName(en, 'month', 'susa'), /Manca li month-nómine/);
assert.throws(() => i18n.calendarName(en, 'planet', 'bronze'), /Ínvalid grupp/);
assert.throws(() => i18n.translate({ code: 'x', messages: {} }, 'field.day'), /Manca li browser-message/);

console.log('browser-i18n-locales: PASS');
