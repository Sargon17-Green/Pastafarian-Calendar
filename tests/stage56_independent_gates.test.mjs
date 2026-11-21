import test from 'node:test';
import assert from 'node:assert/strict';
import { verifyExactGatePositions as verify } from '../tools/stage56_verify_independent_gates.mjs';

// Synthetic comparator contract only. These are not canonical source fixtures.
const mk = () => ({ '0': 10, '1': 52, '2': 94 });
const at = i => BigInt(10 + 42 * i);
test('accepts independent values for all indices', () => assert.equal(verify(mk(), [0, 1, 2], at), 3));
test('rejects changed value with matching shape', () => {
  const g = mk(); g['1'] = 53;
  assert.throws(() => verify(g, [0, 1, 2], at), /INDEPENDENT_SCROLL_GATE_MISMATCH:1/);
});
test('rejects missing gate', () => {
  const g = mk(); delete g['1'];
  assert.throws(() => verify(g, [0, 1, 2], at), /GATE_INDEX_COVERAGE/);
});
test('rejects additional gate', () => {
  const g = mk(); g['3'] = 136;
  assert.throws(() => verify(g, [0, 1, 2], at), /GATE_INDEX_COVERAGE/);
});
test('rejects non-integer gate day', () => {
  const g = mk(); g['1'] = 52.5;
  assert.throws(() => verify(g, [0, 1, 2], at), /GATE_DAY_TYPE:1/);
});
test('rejects supplied non-BigInt oracle', () =>
  assert.throws(() => verify(mk(), [0, 1, 2], () => 10), /INDEPENDENT_SCROLL_GATE_MISMATCH:0/));
