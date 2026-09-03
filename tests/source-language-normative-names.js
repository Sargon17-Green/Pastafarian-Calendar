'use strict';

const assert = require('assert/strict');
const { SourceLanguageCatalog, textByCanonicalIndex } = require('../src/source-language-catalog');

assert.equal(SourceLanguageCatalog.cutlets.length, 17);
assert.equal(SourceLanguageCatalog.months.length, 47);

assert.equal(SourceLanguageCatalog.cutlets[6].canonicalIndex, 7);
assert.equal(SourceLanguageCatalog.cutlets[6].text, 'Palgurash');
assert.equal(textByCanonicalIndex('cutlet', 7), 'Palgurash');

assert.equal(SourceLanguageCatalog.months[7].canonicalIndex, 8);
assert.equal(SourceLanguageCatalog.months[7].text, 'Karshumab');
assert.equal(textByCanonicalIndex('month', 8), 'Karshumab');

const allText = [
  ...SourceLanguageCatalog.cutlets.map((row) => row.text),
  ...SourceLanguageCatalog.months.map((row) => row.text)
].join('\n');

assert.doesNotMatch(allText, /\bPalgursh\b/);
assert.doesNotMatch(allText, /\bKarshumb\b/);

console.log('PASS normative transliterations: Palgurash / Karshumab');
