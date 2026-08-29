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

const actual = cases.map((value) => {
  const execution = production.historicRemainderThroughMonsterPath(
    normative.FOUNDATION_DAY,
    normative.FOUNDATION_DAY,
    value
  );
  assert.equal(execution.context.currentHandler, 'Discovery01RemainderHandler');
  assert.equal(execution.context.phase, 'DISCOVERY_01_LEGACY_REMAINDER');
  assert.equal(execution.context.status, 'DISCOVERY_01_LEGACY_RESULT');
  assert.equal(execution.context.legacyRemainderInput, value);
  assert.equal(execution.context.legacyRemainderOutput, execution.result);
  return execution.result;
});

const expected = cases.map((value) => normative.SAVE(value));

console.log('DISCOVERY 01: li legacy oldRemainder es activ in li path de production.');
console.log('inputs:   ' + cases.map(String).join(', '));
console.log('expected: ' + expected.map(String).join(', '));
console.log('actual:   ' + actual.map(String).join(', '));
console.log('Li regression seque deve fallir in ti stage; savePatch ne es ancor present.');

assert.deepEqual(
  actual,
  expected,
  'Divergentie expectat: regular modulo scri 0 por multiplicas de M, ma SAVE deve scrir M.'
);
