'use strict';

const assert = require('assert/strict');
const production = require('../src');
const normative = require('./normative-reference');

const f = normative.FOUNDATION_DAY;
const cases = [f - 2n, f - 1n, f, f + 1n, f + 2n];

const legacyActual = [];
const actual = cases.map((day) => {
  const legacyExecution = production.discovery02LegacyDayTagThroughMonsterPath(f, f, day);
  legacyActual.push(legacyExecution.result);
  assert.equal(legacyExecution.context.currentHandler, 'Discovery02DayTagHandler');
  assert.equal(legacyExecution.context.phase, 'DISCOVERY_02_LEGACY_DAY_TAG');
  assert.equal(legacyExecution.context.status, 'DISCOVERY_02_LEGACY_RESULT');

  const execution = production.historicDayTagThroughMonsterPath(f, f, day);
  assert.equal(execution.context.previousHandler, 'Discovery02DayTagHandler');
  assert.equal(execution.context.currentHandler, 'Patch02DayTagWrapper');
  assert.equal(execution.context.phase, 'PATCH_02_DAY_TAG_FOUNDATION_SCAR');
  assert.equal(execution.context.status, 'PATCH_02_RESULT');
  assert.equal(execution.context.legacyDayTagInput, day);
  assert.equal(execution.context.legacyDayTagOutput, production.oldDayTag(day));
  assert.equal(execution.context.patch02Input, day);
  assert.equal(execution.context.patch02Output, execution.result);
  return execution.result;
});

const expected = cases.map((day) => normative.dayCount(day));

console.log('DISCOVERY 02 resta visibil: oldDayTag continua perder li paritá posterior e li Foundation special.');
console.log('PATCH 02: li wrapper adjunte un unit al Foundation e pos it, con li guard redundant conservat quam scar.');
console.log('dies:     ' + cases.map(String).join(', '));
console.log('legacy:   ' + legacyActual.map(String).join(', '));
console.log('normativ: ' + expected.map(String).join(', '));
console.log('patched:  ' + actual.map(String).join(', '));

assert.deepEqual(
  legacyActual,
  [4n, 2n, 0n, 2n, 4n],
  'Li scar legacy de Discovery 02 deve restar fisicmen e comportamentalmen present.'
);

assert.deepEqual(
  actual,
  expected,
  'Patch 02 deve far li regression original verd sin modificar oldDayTag.'
);
