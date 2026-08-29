'use strict';

const assert = require('assert/strict');
const production = require('../src');
const normative = require('./normative-reference');

const f = normative.FOUNDATION_DAY;
const cases = [f - 2n, f - 1n, f, f + 1n, f + 2n];

const actual = cases.map((day) => {
  const execution = production.discovery02LegacyDayTagThroughMonsterPath(f, f, day);
  assert.equal(execution.context.currentHandler, 'Discovery02DayTagHandler');
  assert.equal(execution.context.phase, 'DISCOVERY_02_LEGACY_DAY_TAG');
  assert.equal(execution.context.status, 'DISCOVERY_02_LEGACY_RESULT');
  assert.equal(execution.context.legacyDayTagInput, day);
  assert.equal(execution.context.legacyDayTagOutput, execution.result);
  assert.deepEqual(execution.context.branchTrace, [
    'BOOTSTRAP_VALIDATED',
    'DISCOVERY_02_OLD_DAY_TAG'
  ]);
  return execution.result;
});

const expected = cases.map((day) => normative.dayCount(day));

console.log('DISCOVERY 02: oldDayTag usa 2 * abs(day - FOUNDATION) e es nu conectet al path real.');
console.log('dies:     ' + cases.map(String).join(', '));
console.log('legacy:   ' + actual.map(String).join(', '));
console.log('normativ: ' + expected.map(String).join(', '));

assert.deepEqual(
  actual,
  [4n, 2n, 0n, 2n, 4n],
  'Li output legacy exact deve restar stabil durant li discovery.'
);

assert.deepEqual(
  actual,
  expected,
  'EXPECTED RED: oldDayTag perde 1 al Foundation e por omni die pos li Foundation; Patch 02 ne deve esser present in ti stage.'
);
