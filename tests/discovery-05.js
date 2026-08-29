'use strict';

const assert = require('assert/strict');
const production = require('../src');
const normative = require('./normative-reference');

const f = normative.FOUNDATION_DAY;
const counts = normative.workCounts(f, f);
const stones = production.getStoneTableThroughLegacyBuilder();
const expectedByNearness = normative.buildHiddenDrops(counts, normative.STONES);
const legacyExecution = production.discovery05LegacyHiddenStorageThroughMonsterPath(f, f, counts, stones);
const legacyHidden = legacyExecution.result;

assert.deepEqual(
  legacyHidden.slice(1),
  expectedByNearness.slice().reverse(),
  'Li scar de Discovery 05 deve restar fisicmen retrograd pos Patch 05.'
);

const patched = [];
for (let k = 1; k <= 7; k += 1) {
  patched.push(production.hiddenByNearness(legacyHidden, k));
}
assert.deepEqual(
  patched,
  expectedByNearness,
  'DISCOVERY 05 REGRESSION: li translator 8-k deve rendre hidden1..hidden7 sin reversar li storage.'
);

console.log('DISCOVERY 05 REGRESSION: PASS pos Patch 05; li storage retrograd resta intact e access per proximity es exact.');
