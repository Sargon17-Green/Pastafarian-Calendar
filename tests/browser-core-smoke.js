'use strict';

const assert = require('node:assert/strict');
const path = require('node:path');
const { pathToFileURL } = require('node:url');
const core = require('../src/index.js');

(async () => {
  assert.equal(typeof core.calendarDateSpaghetti, 'function');
  const { normalizeCalendarResult } = await import(pathToFileURL(path.resolve(__dirname, '..', 'browser', 'result-normalizer.js')).href);
  const raw = core.calendarDateSpaghetti(1n, 1n);
  const normalized = normalizeCalendarResult(raw);
  assert.equal(typeof normalized.year, 'string');
  assert.equal(typeof normalized.cutletName, 'string');
  assert.equal(Number.isSafeInteger(normalized.dayInCutlet), true);
  assert.equal(typeof normalized.monthName, 'string');
  assert.equal(Number.isSafeInteger(normalized.dayInMonth), true);
  assert.ok(Object.isFrozen(normalized));
  console.log('browser-core-smoke: PASS');
})().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
