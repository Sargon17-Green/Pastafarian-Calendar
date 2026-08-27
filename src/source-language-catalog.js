'use strict';

const CUTLETS = Object.freeze([
  Object.freeze({ canonicalIndex: 1, text: 'bronze' }),
  Object.freeze({ canonicalIndex: 2, text: 'vulpe' }),
  Object.freeze({ canonicalIndex: 3, text: 'ren' }),
  Object.freeze({ canonicalIndex: 4, text: 'larice' }),
  Object.freeze({ canonicalIndex: 5, text: 'pense' }),
  Object.freeze({ canonicalIndex: 6, text: 'quar partes de nin' }),
  Object.freeze({ canonicalIndex: 7, text: 'Palgursh' }),
  Object.freeze({ canonicalIndex: 8, text: 'papirus' }),
  Object.freeze({ canonicalIndex: 9, text: 'grappe' }),
  Object.freeze({ canonicalIndex: 10, text: 'scorpion' }),
  Object.freeze({ canonicalIndex: 11, text: 'cindre' }),
  Object.freeze({ canonicalIndex: 12, text: 'frument' }),
  Object.freeze({ canonicalIndex: 13, text: 'fluvie' }),
  Object.freeze({ canonicalIndex: 14, text: 'rise' }),
  Object.freeze({ canonicalIndex: 15, text: 'Akkad' }),
  Object.freeze({ canonicalIndex: 16, text: 'corn' }),
  Object.freeze({ canonicalIndex: 17, text: 'li vacui vase' })
]);

const MONTHS = Object.freeze([
  Object.freeze({ canonicalIndex: 1, text: 'argile' }),
  Object.freeze({ canonicalIndex: 2, text: 'granat' }),
  Object.freeze({ canonicalIndex: 3, text: 'cubit' }),
  Object.freeze({ canonicalIndex: 4, text: 'invidie' }),
  Object.freeze({ canonicalIndex: 5, text: 'Eridu' }),
  Object.freeze({ canonicalIndex: 6, text: 'dent-pasta' }),
  Object.freeze({ canonicalIndex: 7, text: 'tri partes de quin' }),
  Object.freeze({ canonicalIndex: 8, text: 'Karshumb' }),
  Object.freeze({ canonicalIndex: 9, text: 'leopard' }),
  Object.freeze({ canonicalIndex: 10, text: 'stann' }),
  Object.freeze({ canonicalIndex: 11, text: 'brume' }),
  Object.freeze({ canonicalIndex: 12, text: 'oliban' }),
  Object.freeze({ canonicalIndex: 13, text: 'fus' }),
  Object.freeze({ canonicalIndex: 14, text: 'costa' }),
  Object.freeze({ canonicalIndex: 15, text: 'carob' }),
  Object.freeze({ canonicalIndex: 16, text: 'Uruk' }),
  Object.freeze({ canonicalIndex: 17, text: 'honte' }),
  Object.freeze({ canonicalIndex: 18, text: 'camel' }),
  Object.freeze({ canonicalIndex: 19, text: 'cupr' }),
  Object.freeze({ canonicalIndex: 20, text: 'pute' }),
  Object.freeze({ canonicalIndex: 21, text: 'vitelle' }),
  Object.freeze({ canonicalIndex: 22, text: 'stelle' }),
  Object.freeze({ canonicalIndex: 23, text: 'mel' }),
  Object.freeze({ canonicalIndex: 24, text: 'splen' }),
  Object.freeze({ canonicalIndex: 25, text: 'calcari' }),
  Object.freeze({ canonicalIndex: 26, text: 'joy' }),
  Object.freeze({ canonicalIndex: 27, text: 'fig' }),
  Object.freeze({ canonicalIndex: 28, text: 'Ninive' }),
  Object.freeze({ canonicalIndex: 29, text: 'ran' }),
  Object.freeze({ canonicalIndex: 30, text: 'gudron' }),
  Object.freeze({ canonicalIndex: 31, text: 'candel' }),
  Object.freeze({ canonicalIndex: 32, text: 'li cludet porta' }),
  Object.freeze({ canonicalIndex: 33, text: 'sesam' }),
  Object.freeze({ canonicalIndex: 34, text: 'nuca' }),
  Object.freeze({ canonicalIndex: 35, text: 'argent' }),
  Object.freeze({ canonicalIndex: 36, text: 'lilie' }),
  Object.freeze({ canonicalIndex: 37, text: 'tempeste' }),
  Object.freeze({ canonicalIndex: 38, text: 'asin' }),
  Object.freeze({ canonicalIndex: 39, text: 'farine' }),
  Object.freeze({ canonicalIndex: 40, text: 'regret' }),
  Object.freeze({ canonicalIndex: 41, text: 'Babylon' }),
  Object.freeze({ canonicalIndex: 42, text: 'lingue' }),
  Object.freeze({ canonicalIndex: 43, text: 'lin' }),
  Object.freeze({ canonicalIndex: 44, text: 'sal' }),
  Object.freeze({ canonicalIndex: 45, text: 'pir' }),
  Object.freeze({ canonicalIndex: 46, text: 'arc' }),
  Object.freeze({ canonicalIndex: 47, text: 'sand' })
]);

const SourceLanguageCatalog = Object.freeze({
  version: '1.0.0-stage-01',
  language: 'Interlingue / Occidental',
  cutlets: CUTLETS,
  months: MONTHS
});

function textByCanonicalIndex(group, canonicalIndex) {
  const rows = group === 'cutlet' ? SourceLanguageCatalog.cutlets : group === 'month' ? SourceLanguageCatalog.months : null;
  if (rows === null || !Number.isInteger(canonicalIndex) || canonicalIndex < 1 || canonicalIndex > rows.length) {
    throw new RangeError('Índice canonic ínvalid in li catalog de lingue-fonte.');
  }
  return rows[canonicalIndex - 1].text;
}

module.exports = Object.freeze({ SourceLanguageCatalog, textByCanonicalIndex });
