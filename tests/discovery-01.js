'use strict';

const assert = require('assert/strict');
const production = require('../src');
const normative = require('./normative-reference');

const cases = [
  normative.M,
  2n * normative.M,
  3n * normative.M,
  normative.M + 1n
];

const legacyActual = [];
const actual = cases.map((value) => {
  const legacyExecution = production.discovery01LegacyRemainderThroughMonsterPath(
    normative.FOUNDATION_DAY,
    normative.FOUNDATION_DAY,
    value
  );
  legacyActual.push(legacyExecution.result);
  assert.equal(legacyExecution.context.currentHandler, 'Discovery01RemainderHandler');
  assert.equal(legacyExecution.context.phase, 'DISCOVERY_01_LEGACY_REMAINDER');
  assert.equal(legacyExecution.context.status, 'DISCOVERY_01_LEGACY_RESULT');

  const execution = production.historicRemainderThroughMonsterPath(
    normative.FOUNDATION_DAY,
    normative.FOUNDATION_DAY,
    value
  );
  assert.equal(execution.context.previousHandler, 'Discovery01RemainderHandler');
  assert.equal(execution.context.currentHandler, 'Patch01SaveWrapper');
  assert.equal(execution.context.phase, 'PATCH_01_SAVE_ZERO_REMAP');
  assert.equal(execution.context.status, 'PATCH_01_RESULT');
  assert.equal(execution.context.legacyRemainderInput, value);
  assert.equal(execution.context.legacyRemainderOutput, production.oldRemainder(value));
  assert.equal(execution.context.patch01Input, value);
  assert.equal(execution.context.patch01Output, execution.result);
  return execution.result;
});

const expected = cases.map((value) => normative.SAVE(value));

console.log('DISCOVERY 01 resta visibil: oldRemainder continua rendre 0 por multiplicas de M.');
console.log('PATCH 01: savePatch remappa solmen residu zero a M e passa tra li wrapper historic.');
console.log('inputs:   ' + cases.map(String).join(', '));
console.log('legacy:   ' + legacyActual.map(String).join(', '));
console.log('expected: ' + expected.map(String).join(', '));
console.log('patched:  ' + actual.map(String).join(', '));

assert.deepEqual(
  legacyActual,
  [0n, 0n, 0n, 1n],
  'Li scar legacy de Discovery 01 deve restar fisicmen e comportamentalmen present.'
);

assert.deepEqual(
  actual,
  expected,
  'Patch 01 deve far li regression original verd sin modificar oldRemainder.'
);
