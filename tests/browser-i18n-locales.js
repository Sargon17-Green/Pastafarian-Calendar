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
  'loading.long',
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
  'reverse.open',
  'reverse.heading',
  'reverse.year',
  'reverse.cutlet',
  'reverse.dayInCutlet',
  'reverse.month',
  'reverse.dayInMonth',
  'reverse.calculation',
  'reverse.submit',
  'reverse.searching',
  'reverse.progress',
  'reverse.noMatch',
  'reverse.found',
  'reverse.incomplete',
  'reverse.error',
  'reverse.timeout',
  'reverse.useResult',
  'field.day',
  'date.aria',
  'date.yearLine',
  'date.cutletLine',
  'date.monthLine',
  'target.searched',
  'target.context',
  'cooking.open',
  'cooking.title',
  'cooking.subtitle',
  'cooking.close',
  'cooking.loading',
  'cooking.error',
  'cooking.retry',
  'cooking.live.kicker',
  'cooking.live.title',
  'cooking.live.subtitle',
  'cooking.live.starting',
  'cooking.live.now',
  'cooking.live.nextGate',
  'cooking.live.yearAnchor',
  'cooking.live.explain.inputs',
  'cooking.live.explain.gates',
  'cooking.live.explain.yearAnchor',
  'cooking.live.explain.years',
  'cooking.live.explain.stones',
  'cooking.live.explain.hidden',
  'cooking.live.explain.visible',
  'cooking.live.explain.bowls',
  'cooking.live.explain.postStirs',
  'cooking.live.explain.selection',
  'cooking.live.explain.structure',
  'cooking.live.explain.cutlets',
  'cooking.live.explain.months',
  'cooking.live.explain.weaving',
  'cooking.live.explain.result',
  'cooking.live.explain.position',
  'cooking.previous',
  'cooking.next',
  'cooking.exactShow',
  'cooking.exactHide',
  'cooking.captureGate',
  'cooking.captureGateBusy',
  'cooking.gateDetailReady',
  'cooking.noYearWalk',
  'cooking.empty',
  'cooking.sameExecution',
  'cooking.chapter.inputs',
  'cooking.chapter.gates',
  'cooking.chapter.year5000',
  'cooking.chapter.yearWalk',
  'cooking.chapter.structureSauce',
  'cooking.chapter.cutlets',
  'cooking.chapter.months',
  'cooking.chapter.position',
  'cooking.chapter.result',
  'cooking.phase.stones',
  'cooking.phase.hidden',
  'cooking.phase.visible',
  'cooking.phase.bowls',
  'cooking.phase.postStirs',
  'cooking.term.gate',
  'cooking.term.compactSauce',
  'cooking.term.year',
  'cooking.term.sauce',
  'cooking.term.stone',
  'cooking.term.hiddenDrop',
  'cooking.term.visibleDrop',
  'cooking.term.grind',
  'cooking.term.bowlRound',
  'cooking.term.position',
  'cooking.term.bowl',
  'cooking.term.postStir',
  'cooking.term.cutlet',
  'cooking.term.monthSlot',
  'cooking.term.measurement',
  'cooking.term.gateGap',
  'cooking.term.weaving',
  'cooking.term.selection',
  'cooking.term.stream',
  'cooking.term.initialBowls',
  'cooking.term.checkpoints',
  'cooking.term.archaeology',
  'cooking.term.fromYear',
  'cooking.term.toYear',
  'cooking.term.finalYear',
  'cooking.result.year',
  'cooking.result.cutlet',
  'cooking.result.dayInCutlet',
  'cooking.result.month',
  'cooking.result.dayInMonth',
  'cooking.archaeology.note',
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
assert(data.megillahStageGuide, 'manca canonical Megillah stage guide');
assert.strictEqual(
  data.megillahCanonicalUrl,
  'https://the-scroll-of-the-appointed-times.blogspot.com/2026/08/Megilat-HaItim.html',
);
assert.strictEqual(Object.keys(data.megillahStageGuide).length, 16);
assert.strictEqual(data.megillahStageGuide.gates.quote, 'וכן עשה שער אחר שער.');
assert(data.megillahStageGuide.gates.source.includes('לוח שבעה עשר: שערי הקציצה'));
assert.strictEqual(data.megillahStageGuide.yearAnchor.quote, 'לשנה אשר תבחר קרא שנת חמשת אלפים לבריאת העולם.');
assert.strictEqual(data.megillahStageGuide.stones.quote, 'כל אחת מחמש האבנים החדשות עשה מן חמש האבנים הישנות.');
assert.strictEqual(data.megillahStageGuide.hidden.quote, 'כל טיפה נסתרת טחון שבע טחינות.');
assert.strictEqual(data.megillahStageGuide.visible.quote, 'את ראשית הטיפה טחון עשתי עשרה טחינות.');
assert.strictEqual(data.megillahStageGuide.postStirs.quote, 'אחרי אשר תעשה את הטיפה השש וארבעים בלול עוד שתים עשרה בלילות.');
assert.strictEqual(data.megillahStageGuide.weaving.quote, 'לא תבחר את הימים אחד אחד. את השזירה כולה תבחר.');
assert.strictEqual(data.megillahStageGuide.position.quote, 'אחרי אשר תעשה את דבר השנה הדברים האלה יוצאים ממקום היום בתוך אשר עשית.');
assert.deepStrictEqual(Array.from(data.locales, (locale) => locale.code), ['ie', 'en', 'he', 'ar', 'ru', 'fr', 'de', 'es', 'it', 'cs']);

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
const fr = i18n.resolveLocale('fr', []);
const de = i18n.resolveLocale('de', []);
const es = i18n.resolveLocale('es', []);
const it = i18n.resolveLocale('it', []);
const cs = i18n.resolveLocale('cs', []);

assert.strictEqual(i18n.resolveLocale('en-US', []).code, 'en');
assert.strictEqual(i18n.resolveLocale(null, ['en-GB']).code, 'en');
assert.strictEqual(i18n.resolveLocale('he-IL', []).code, 'he');
assert.strictEqual(i18n.resolveLocale('ar-EG', []).code, 'ar');
assert.strictEqual(i18n.resolveLocale('ru-RU', []).code, 'ru');
assert.strictEqual(i18n.resolveLocale('fr-CA', []).code, 'fr');
assert.strictEqual(i18n.resolveLocale('de-AT', []).code, 'de');
assert.strictEqual(i18n.resolveLocale('es-MX', []).code, 'es');
assert.strictEqual(i18n.resolveLocale('it-CH', []).code, 'it');
assert.strictEqual(i18n.resolveLocale('cs-CZ', []).code, 'cs');
assert.strictEqual(i18n.resolveLocale(null, ['xx-ZZ']).code, 'ie');
assert.strictEqual(he.dir, 'rtl');
assert.strictEqual(ar.dir, 'rtl');
assert.strictEqual(ru.dir, 'ltr');
for (const locale of [fr, de, es, it, cs]) assert.strictEqual(locale.dir, 'ltr');

assert.strictEqual(i18n.translate(en, 'field.day'), 'Day');
assert.strictEqual(i18n.translate(ie, 'field.day'), 'Die');
assert.strictEqual(i18n.translate(he, 'field.day'), '\u05D9\u05D5\u05DD');
assert.strictEqual(i18n.translate(ar, 'field.day'), 'اليوم');
assert.strictEqual(i18n.translate(ru, 'field.day'), 'День');
assert.strictEqual(i18n.translate(fr, 'field.day'), 'Jour');
assert.strictEqual(i18n.translate(de, 'field.day'), 'Tag');
assert.strictEqual(i18n.translate(es, 'field.day'), 'Día');
assert.strictEqual(i18n.translate(it, 'field.day'), 'Giorno');
assert.strictEqual(i18n.translate(cs, 'field.day'), 'Den');
assert.strictEqual(i18n.translate(ie, 'cooking.chapter.gates'), 'Portas');
assert.strictEqual(i18n.translate(en, 'cooking.title'), 'How this date was cooked');
assert.strictEqual(i18n.translate(en, 'cooking.live.title'), 'The calculation is in motion');
assert.strictEqual(i18n.translate(he, 'cooking.live.title'), 'החישוב מתבשל עכשיו');
assert.strictEqual(i18n.translate(he, 'cooking.live.now', { step: 'אבן 3' }), 'עכשיו: אבן 3…');
assert(i18n.translate(he, 'cooking.live.explain.gates').includes('רצף שערים'));
assert(i18n.translate(en, 'cooking.live.explain.weaving').includes('complete weaving'));
assert(i18n.translate(de, 'cooking.live.explain.stones').includes('46 Zeilen'));
assert.strictEqual(i18n.translate(he, 'cooking.close'), 'סגור');
assert.strictEqual(i18n.translate(he, 'cooking.term.gate'), 'שער');
assert.strictEqual(i18n.translate(he, 'cooking.term.gateGap'), 'מרווח שער');
assert.strictEqual(i18n.translate(he, 'cooking.term.archaeology'), 'ארכאולוגיה היסטורית');
assert.strictEqual(i18n.translate(ar, 'cooking.chapter.result'), 'النتيجة');
assert.strictEqual(i18n.translate(ar, 'cooking.term.stone'), 'حجر');

// Regression witnesses: current semantic identities, including names that differ
// from the pinned old positional catalog.
const witnesses = [
  ['cutlet', 'Lagash', ['Lagash', 'Lagash', 'לגש', 'لَجَش', 'Лагаш', 'Lagash', 'Lagasch', 'Lagash', 'Lagash', 'Lagaš']],
  ['cutlet', 'Palgurash', ['Palgurash', 'Palgursh', '\u05E4\u05B7\u05BC\u05DC\u05B0\u05D2\u05BC\u05D5\u05BC\u05E8\u05B0\u05E9\u05C1', 'بالغورش', 'Палгурш', 'Palgursh', 'Palgursh', 'Palgursh', 'Palgursh', 'Palgursh']],
  ['cutlet', 'papirus', ['papirus', 'Papyrus', '\u05E4\u05E4\u05D9\u05E8\u05D5\u05E1', 'بردي', 'Папирус', 'Papyrus', 'Papyrus', 'Papiro', 'Papiro', 'Papyrus']],
  ['month', 'Karshumav', ['Karshumav', 'Karshumav', 'כַּרְשׁוּמַב', 'كَرْشُومَڤ', 'Каршумав', 'Karshumav', 'Karschumav', 'Karshumav', 'Karshumav', 'Karšumav']],
  ['month', 'leopard', ['leopard', 'Leopard', '\u05E0\u05DE\u05E8', 'نمر', 'Леопард', 'Léopard', 'Leopard', 'Leopardo', 'Leopardo', 'Leopard']],
  ['month', 'lampe', ['lampe', 'Lamp', 'נר', 'سِرَاج', 'лампа', 'lampe', 'Lampe', 'Lámpara', 'lampada', 'lampa']],
  ['month', 'Susa', ['Susa', 'Susa', 'שושן', 'سُوسَا', 'Сузы', 'Suse', 'Susa', 'Susa', 'Susa', 'Súsy']],
  ['month', 'pech', ['pech', 'Pitch', 'זפת', 'قَار', 'пек', 'poix', 'Pech', 'Brea', 'bitume', 'smůla']],
  ['month', 'oliban', ['oliban', 'Frankincense', '\u05DC\u05D1\u05D5\u05E0\u05D4', 'لبان', 'Ладан', 'Oliban', 'Weihrauch', 'Olíbano', 'Olibano', 'Kadidlo']],
];
const locales = [ie, en, he, ar, ru, fr, de, es, it, cs];
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
  assert.throws(() => i18n.calendarName(locale, 'cutlet', 'papyrusSedge'), /Manca li cutlet-nómine/);
  assert.throws(() => i18n.calendarName(locale, 'month', 'lamp'), /Manca li month-nómine/);
  assert.throws(() => i18n.calendarName(locale, 'month', 'karshumab'), /Manca li month-nómine/);
}
assert.throws(() => i18n.calendarName(en, 'planet', 'bronze'), /Ínvalid grupp/);
assert.throws(() => i18n.translate({ code: 'x', messages: {} }, 'field.day'), /Manca li browser-message/);

console.log('browser-i18n-locales: PASS');
