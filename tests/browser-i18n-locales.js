'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');
const vm = require('vm');

const ROOT = path.resolve(__dirname, '..');
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
assert.strictEqual(data.defaultLocale, 'ie');
assert.deepStrictEqual(Array.from(data.locales, (locale) => locale.code), ['ie', 'en']);
for (const locale of data.locales) {
  assert.strictEqual(locale.dir, 'ltr');
  for (const key of REQUIRED_MESSAGES) {
    assert.strictEqual(typeof locale.messages[key], 'string', locale.code + ' manca ' + key);
    assert(locale.messages[key].trim().length > 0, locale.code + ' have vacui ' + key);
  }
}

const i18n = sandbox.PastafariBrowserInternal.i18n;
assert.strictEqual(i18n.resolveLocale('ie', []).code, 'ie');
assert.strictEqual(i18n.resolveLocale('en-US', []).code, 'en');
assert.strictEqual(i18n.resolveLocale(null, ['en-GB']).code, 'en');
assert.strictEqual(i18n.resolveLocale(null, ['he']).code, 'ie');
assert.strictEqual(i18n.translate(i18n.resolveLocale('en', []), 'field.day'), 'Day');
assert.strictEqual(i18n.translate(i18n.resolveLocale('ie', []), 'field.day'), 'Die');
assert.strictEqual(i18n.calendarName(i18n.resolveLocale('en', []), 'cutlet', 'larice'), 'larice');
assert.throws(() => i18n.translate({ code: 'x', messages: {} }, 'field.day'), /Manca li browser-message/);

console.log('browser-i18n-locales: PASS');
