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
  'calendar.today',
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
  'date.yearLine',
  'date.cutletLine',
  'date.monthLine',
  'target.searched',
  'target.context',
]);

const sandbox = { Intl, globalThis: null };
sandbox.globalThis = sandbox;
vm.createContext(sandbox);
for (const relative of ['browser/i18n/locales.js', 'browser/i18n/runtime.js']) {
  vm.runInContext(fs.readFileSync(path.join(ROOT, relative), 'utf8'), sandbox, { filename: relative });
}

const data = sandbox.PastafariBrowserLocaleData;
assert(data);
assert.strictEqual(data.schemaVersion, 3);
assert.strictEqual(data.defaultLocale, 'ie');
assert.deepStrictEqual(Array.from(data.locales, (locale) => locale.code), ['ie', 'en', 'he', 'ar', 'ru']);

const sourceCutlets = SourceLanguageCatalog.cutlets.map((row) => row.text).sort();
const sourceMonths = SourceLanguageCatalog.months.map((row) => row.text).sort();
assert.strictEqual(sourceCutlets.length, 17);
assert.strictEqual(sourceMonths.length, 47);

for (const locale of data.locales) {
  assert(['ltr', 'rtl'].includes(locale.dir), locale.code + ' invalid dir');
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
const he = i18n.resolveLocale('he', []);
const ar = i18n.resolveLocale('ar', []);
const ru = i18n.resolveLocale('ru', []);

assert.strictEqual(i18n.resolveLocale('en-US', []).code, 'en');
assert.strictEqual(i18n.resolveLocale(null, ['en-GB']).code, 'en');
assert.strictEqual(i18n.resolveLocale('he-IL', []).code, 'he');
assert.strictEqual(i18n.resolveLocale('ar-EG', []).code, 'ar');
assert.strictEqual(i18n.resolveLocale('ru-RU', []).code, 'ru');
assert.strictEqual(i18n.resolveLocale(null, ['xx-ZZ']).code, 'ie');
assert.strictEqual(he.dir, 'rtl');
assert.strictEqual(ar.dir, 'rtl');
assert.strictEqual(ru.dir, 'ltr');

assert.strictEqual(i18n.translate(en, 'field.day'), 'Day');
assert.strictEqual(i18n.translate(ie, 'field.day'), 'Die');
assert.strictEqual(i18n.translate(he, 'field.day'), 'יום');
assert.strictEqual(i18n.translate(ar, 'field.day'), 'اليوم');
assert.strictEqual(i18n.translate(ru, 'field.day'), 'День');

// Regression witnesses: current semantic identities, including names that differ
// from the pinned old positional catalog.
const witnesses = [
  ['cutlet', 'larice', ['larice', 'Larch', 'ארזית', 'لاركس', 'Лиственница']],
  ['cutlet', 'Palgursh', ['Palgursh', 'Palgursh', 'פַּלְגּוּרְשׁ', 'بالغورش', 'Палгурш']],
  ['month', 'leopard', ['leopard', 'Leopard', 'נמר', 'نمر', 'Леопард']],
  ['month', 'candel', ['candel', 'Candle', 'נר', 'شمعة', 'Свеча']],
  ['month', 'lilie', ['lilie', 'Lily', 'שושן', 'زنبق', 'Лилия']],
];
const locales = [ie, en, he, ar, ru];
for (const [group, key, values] of witnesses) {
  values.forEach((expected, index) => {
    assert.strictEqual(i18n.calendarName(locales[index], group, key), expected, locales[index].code + ' ' + key);
  });
}

// Obsolete old-table identities must never be accepted as aliases by position.
for (const locale of locales) {
  assert.throws(() => i18n.calendarName(locale, 'cutlet', 'lagash'), /Manca li cutlet-nómine/);
  assert.throws(() => i18n.calendarName(locale, 'month', 'tiger'), /Manca li month-nómine/);
  assert.throws(() => i18n.calendarName(locale, 'month', 'susa'), /Manca li month-nómine/);
}
assert.throws(() => i18n.calendarName(en, 'planet', 'bronze'), /Ínvalid grupp/);
assert.throws(() => i18n.translate({ code: 'x', messages: {} }, 'field.day'), /Manca li browser-message/);

console.log('browser-i18n-locales: PASS');
