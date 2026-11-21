import { test } from 'node:test';
import assert from 'node:assert/strict';
import { assertJsonSemanticEqual as eq } from '../tools/stage56_semantic_compare.mjs';

const python = { cutletName: 'מחשבה', dayInCutlet: 1, dayInMonth: 1,
                 monthName: 'צפרדע', year: '4999' };
const scroll = { year: '4999', cutletName: 'מחשבה', dayInCutlet: 1,
                 monthName: 'צפרדע', dayInMonth: 1 };

test('identical five-component tuple ignores JSON object member order', () => {
  assert.doesNotThrow(() => eq(python, scroll, 'same five-component tuple'));
});

test('every five-component semantic mutation fails closed', () => {
  for (const [field, wrong] of Object.entries({
    year: '5000', cutletName: 'different', dayInCutlet: 2,
    monthName: 'different', dayInMonth: 2,
  })) {
    assert.throws(() => eq({ ...python, [field]: wrong }, scroll, field),
                  new RegExp('^Error: ' + field + ':'));
  }
});

test('missing or extra properties, or scalar type changes, are rejected', () => {
  const { year, ...withoutYear } = python;
  assert.throws(() => eq(withoutYear, scroll, 'missing year'));
  assert.throws(() => eq({ ...python, extra: 1 }, scroll, 'extra'));
  assert.throws(() => eq({ ...python, dayInCutlet: '1' }, scroll, 'type'));
});

test('array element order and length remain significant', () => {
  eq([{ a: 1, b: 2 }, { a: 3 }], [{ b: 2, a: 1 }, { a: 3 }], 'object order');
  assert.throws(() => eq([1, 2, 3], [2, 1, 3], 'array order'));
  assert.throws(() => eq([1, 2, 3], [1, 2], 'array length'));
});

test('nested objects may reorder keys but changed nested data fails', () => {
  eq({ source: { sha: 'abc', year: 5000 }, days: [1, 2] },
     { days: [1, 2], source: { year: 5000, sha: 'abc' } }, 'nested order');
  assert.throws(() => eq({ source: { sha: 'abc' } },
                         { source: { sha: 'abd' } }, 'nested value'));
});
