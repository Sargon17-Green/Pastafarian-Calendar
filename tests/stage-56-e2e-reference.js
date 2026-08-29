'use strict';
const assert = require('node:assert/strict');
const production = require('../src');
function canonicalFive(result) {
  const cutlet = production.SourceLanguageCatalog.cutlets.find((row) => row.text === result[1]);
  const month = production.SourceLanguageCatalog.months.find((row) => row.text === result[3]);
  assert.ok(cutlet); assert.ok(month);
  return [result[0], cutlet.canonicalIndex, result[2], month.canonicalIndex, result[4]];
}
const cases = [
  [-15048173n, -15048173n, [5000n, 12, 21n, 47, 57n]],
  [-15048173n, -15048172n, [5000n, 12, 22n, 18, 58n]],
  [-15048173n, -15048174n, [5000n, 12, 20n, 7, 58n]]
];
for (const [c, t, expected] of cases) assert.deepEqual(canonicalFive(production.calendarDateSpaghetti(c, t)), expected);
console.log('STAGE 56 E2E REFERENCE PASS — tri witnesses extern pos-Foundation es reproductet per canonical indices.');
