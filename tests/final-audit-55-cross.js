'use strict';

const assert = require('node:assert/strict');
const production = require('../src');
const { FastAuditOracle } = require('./final-audit-55-e2e');

const F = production.FOUNDATION_DAY_OLD;
const oracle = new FastAuditOracle();
const expected = oracle.calendarDate(F - 1n, F + 1n).result;
const actual = production.calendarDateSpaghetti(F - 1n, F + 1n);
assert.deepEqual(actual, expected, 'Divergentie end-to-end trans Foundation.');
assert.equal(actual.length, 5);
console.log('STAGE 55 CROSS AUDIT PASS — differential end-to-end trans Foundation avante.');
