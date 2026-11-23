#!/usr/bin/env node
// Stage53/DISCOVERY49 independent planning-only model. No COBOL calls.
import assert from 'node:assert/strict';

const widths = [3, 9, 128, 320, 8192];
const zeroTexts = ['0', '+000', '-000', '0'.repeat(8192), '-' + '0'.repeat(8191)];
const abs = x => x < 0n ? -x : x;
const distance = (a, b) => abs(b - a) + 1n;

function addSmall(text, amount) {
  const digits = [...text];
  let carry = amount;
  for (let p = digits.length - 1; p >= 0 && carry; p--) {
    const value = Number(digits[p]) + carry;
    digits[p] = String(value % 10);
    carry = Math.floor(value / 10);
  }
  if (carry) digits.unshift(String(carry));
  return digits.join('');
}
function subtractSmall(text, amount) {
  const digits = [...text];
  let borrow = amount;
  for (let p = digits.length - 1; p >= 0 && borrow; p--) {
    let value = Number(digits[p]) - borrow;
    borrow = value < 0 ? 1 : 0;
    if (value < 0) value += 10;
    digits[p] = String(value);
  }
  assert.equal(borrow, 0);
  return digits.join('').replace(/^0+(?=.)/, '');
}
function parseZero(text) {
  assert.ok(text.length >= 1 && text.length <= 8192);
  assert.match(text, /^[+-]?[0-9]+$/);
  const parsed = BigInt(text);
  assert.equal(parsed, 0n);
  return { sign: 0, magnitude: '0' };
}

let cases = 0, arithmetic = 0, symmetries = 0;
let zeroCanonical = 0, maxWidth = 0, occupiedModel = 0;
let survivorFree = 0, survivorReuse = 0, restored = 0;
const slots = [0, 0, 0, 0, 0];
const pairs = new Set();
for (const width of widths) {
  const B = BigInt('1' + '0'.repeat(width - 1));
  for (let j = 1; j <= 5; j++) {
    const M = B + BigInt(j + 5);
    const m = String(M);
    const s = j % 2 ? -1n : 1n;
    assert.equal(m.length, width);
    const originalZero = parseZero(zeroTexts[j - 1]);
    const replacementZero = parseZero(zeroTexts[j % 5]);
    assert.deepEqual(originalZero, replacementZero);
    zeroCanonical += 2;
    const T = s * M;
    const pair = width + '|' + j + '|' + String(T);
    assert.ok(!pairs.has(pair));
    pairs.add(pair);
    if (width === 8192) maxWidth++;
    const before = [], after = [];
    for (let k = 0; k < 5; k++) {
      const Ck = s * BigInt(k); // C0 is a normalized zero.
      const reversedC = -s * (M + BigInt(k));
      const oldResult = distance(Ck, T);
      const newResult = distance(reversedC, 0n);
      const independentOld = k === 0 ? addSmall(m, 1) :
        subtractSmall(m, k - 1);
      const independentNew = addSmall(m, k + 1);
      assert.equal(String(oldResult), independentOld);
      assert.equal(String(newResult), independentNew);
      assert.equal(oldResult, M - BigInt(k) + 1n);
      assert.equal(newResult, M + BigInt(k) + 1n);
      arithmetic += 2;
      // Two independent transformations for each of the two regimes.
      assert.equal(distance(T, Ck), oldResult);
      assert.equal(distance(-Ck, -T), oldResult);
      assert.equal(distance(0n, reversedC), newResult);
      assert.equal(distance(-reversedC, 0n), newResult);
      symmetries += 4;
      before.push({text: independentOld, identity: Symbol()});
      after.push(independentNew);
    }
    // Conceptual owner bookkeeping only; not an allocator/Native test.
    assert.equal(new Set(before.map(x => x.identity)).size, 5);
    const outputs = before.slice();
    const selected = cases % 5;
    slots[selected]++;
    const original = outputs[selected];
    occupiedModel++;
    assert.deepEqual(outputs, before);
    outputs[selected] = null;
    for (let k = 0; k < 5; k++) if (k !== selected) {
      assert.equal(outputs[k], before[k]); survivorFree++;
    }
    outputs[selected] = {text: after[selected], identity: Symbol()};
    assert.notEqual(outputs[selected].identity, original.identity);
    for (let k = 0; k < 5; k++) if (k !== selected) {
      assert.equal(outputs[k], before[k]); survivorReuse++;
    }
    outputs[selected] = {text: original.text, identity: Symbol()};
    for (let k = 0; k < 5; k++) assert.equal(outputs[k].text, before[k].text);
    restored++;
    cases++;
  }
}
assert.equal(cases, 25);
assert.equal(pairs.size, 25);
assert.equal(arithmetic, 250);
assert.equal(symmetries, 500);
assert.equal(zeroCanonical, 50);
assert.equal(maxWidth, 5);
assert.equal(occupiedModel, 25);
assert.equal(survivorFree, 100);
assert.equal(survivorReuse, 100);
assert.equal(restored, 25);
assert.deepEqual(slots, [5,5,5,5,5]);
for (const [name, value] of Object.entries({
  CASES: '25/25', UNIQUE_PAIRS: '25', ARITHMETIC: '250/250',
  METAMORPHIC_SYMMETRIES: '500/500', ZERO_CANONICAL: '50/50',
  WIDTH_8192_CASES: '5', OCCUPIED_OWNER_MODEL: '25/25',
  SURVIVORS_FREE_MODEL: '100/100', SURVIVORS_REUSE_MODEL: '100/100',
  RESTORED_MODEL: '25/25', TARGET_SLOT_BALANCE: '5,5,5,5,5',
  GATE: 'PASS_NOT_NATIVE'
})) console.log('STAGE53_PLANNING_' + name + '=' + value);
