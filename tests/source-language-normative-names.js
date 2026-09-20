'use strict';

const assert = require('assert/strict');
const { SourceLanguageCatalog, textByCanonicalIndex } = require('../src/source-language-catalog');

assert.equal(SourceLanguageCatalog.cutlets.length, 17);
assert.equal(SourceLanguageCatalog.months.length, 47);

assert.equal(SourceLanguageCatalog.cutlets[6].canonicalIndex, 7);
assert.equal(SourceLanguageCatalog.cutlets[6].text, 'Palgurash');
assert.equal(textByCanonicalIndex('cutlet', 7), 'Palgurash');

assert.equal(SourceLanguageCatalog.months[7].canonicalIndex, 8);
assert.equal(SourceLanguageCatalog.months[7].text, 'Karshumav');
assert.equal(textByCanonicalIndex('month', 8), 'Karshumav');

const allText = [
  ...SourceLanguageCatalog.cutlets.map((row) => row.text),
  ...SourceLanguageCatalog.months.map((row) => row.text)
].join('\n');

assert.doesNotMatch(allText, /\bPalgursh\b/);
assert.equal(textByCanonicalIndex('cutlet', 4), 'Lagash');
assert.equal(textByCanonicalIndex('month', 30), 'pech');
assert.equal(textByCanonicalIndex('month', 31), 'lampe');
assert.equal(textByCanonicalIndex('month', 36), 'Susa');
assert.doesNotMatch(allText, /\b(?:larice|Karshumab|Karshumb|gudron|candel|lilie)\b/);

console.log('PASS canonical names: Lagash / Palgurash / Karshumav / pech / lampe / Susa');
