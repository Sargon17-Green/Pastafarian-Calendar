#!/usr/bin/env node
// Stage52/DISCOVERY48 independent decimal-digit arithmetic + BigInt.
// The accepted COBOL code is never called; PASS_NOT_NATIVE is planning only.
import assert from "node:assert/strict";
const absolute = x => x < 0n ? -x : x;
const distance = (a, b) => absolute(a - b) + 1n;
// Decimal subtraction with explicit borrow: arguments are positive strings.
function subtractDecimal(larger, smaller) {
  assert.match(larger, /^[1-9][0-9]*$/);
  assert.match(smaller, /^[1-9][0-9]*$/);
  assert.ok(larger.length > smaller.length ||
    (larger.length === smaller.length && larger >= smaller));
  const result = [];
  let borrow = 0;
  for (let pos = 0; pos < larger.length; pos++) {
    const a = larger.charCodeAt(larger.length - pos - 1) - 48;
    const b = pos < smaller.length ?
      smaller.charCodeAt(smaller.length - pos - 1) - 48 : 0;
    let digit = a - b - borrow;
    borrow = digit < 0 ? 1 : 0;
    if (borrow) digit += 10;
    result.push(String(digit));
  }
  assert.equal(borrow, 0);
  return result.reverse().join("").replace(/^0+(?=.)/, "");
}
function plusOne(digits) {
  const a = [...digits];
  let carry = 1;
  for (let i = a.length - 1; i >= 0 && carry; i--) {
    const value = Number(a[i]) + carry;
    a[i] = String(value % 10);
    carry = value === 10 ? 1 : 0;
  }
  if (carry) a.unshift("1");
  return a.join("");
}
const widths = [3, 9, 128, 320, 8192];
const ids = new Set();
let cases = 0, comparisons = 0, orientations = 0;
let symmetries = 0, maximum = 0;
const slotCounts = [0, 0, 0, 0, 0];
for (const width of widths) {
  const B = 10n ** BigInt(width - 1);
  for (let j = 1; j <= 5; j++) {
    const T = 3n * B, C = T - BigInt(j);
    const T2 = -(T + BigInt(j)), C2 = -C;
    assert.equal(String(C).length, width);
    assert.equal(String(T).length, width);
    assert.equal(String(-C2).length, width);
    assert.equal(String(-T2).length, width);
    const key = String(C) + "|" + String(T);
    assert.ok(!ids.has(key)); ids.add(key);
    if (width === 8192) maximum++;
    const before = [], after = [];
    for (let slot = 1; slot <= 5; slot++) {
      const candidate = C - BigInt(slot - 1);
      const negCandidate = -candidate;
      assert.ok(candidate < T && negCandidate > T2);
      assert.equal(String(candidate).length, width);
      const oldResult = distance(candidate, T);
      const newResult = distance(negCandidate, T2);
      const oldDigitOracle = plusOne(
        subtractDecimal(String(T), String(candidate)));
      const newDigitOracle = plusOne(
        subtractDecimal(String(-T2), String(candidate)));
      assert.equal(String(oldResult), oldDigitOracle);
      assert.equal(String(newResult), newDigitOracle);
      assert.equal(oldResult, BigInt(j + slot));
      assert.equal(newResult, BigInt(2 * j + slot));
      comparisons += 2; orientations += 2;
      assert.equal(distance(T, candidate), oldResult);
      assert.equal(distance(-T, negCandidate), oldResult);
      assert.equal(distance(T2, negCandidate), newResult);
      assert.equal(distance(-T2, candidate), newResult);
      symmetries += 4;
      before.push(String(oldResult)); after.push(String(newResult));
    }
    const owners = before.map(value => ({value, token: Symbol()}));
    const saved = owners.slice();
    assert.equal(new Set(owners.map(v => v.token)).size, 5);
    for (let slot = 0; slot < 5; slot++)
      assert.equal(owners[slot], saved[slot]);
    const selected = cases % 5;
    slotCounts[selected]++;
    const retired = owners[selected];
    owners[selected] = null;
    for (let slot = 0; slot < 5; slot++)
      if (slot !== selected) assert.equal(owners[slot], saved[slot]);
    owners[selected] = {value: after[selected], token: Symbol()};
    assert.notEqual(owners[selected].token, retired.token);
    for (let slot = 0; slot < 5; slot++)
      if (slot !== selected) assert.equal(owners[slot], saved[slot]);
    owners[selected] = {value: before[selected], token: Symbol()};
    for (let slot = 0; slot < 5; slot++)
      assert.equal(owners[slot].value, before[slot]);
    cases++;
  }
}
assert.equal(cases, 25);
assert.equal(ids.size, 25);
assert.equal(comparisons, 250);
assert.equal(orientations, 250);
assert.equal(symmetries, 500);
assert.equal(maximum, 5);
assert.deepEqual(slotCounts, [5, 5, 5, 5, 5]);
const facts = {
  CASES: "25/25",
  ARITHMETIC: "250/250",
  ORIENTATION: "250/250",
  SIGN_AND_ENDPOINT_SYMMETRY: "500/500",
  UNIQUE_PAIRS: "25",
  MAX_WIDTH_CASES: "5",
  SLOT_BALANCE: "5,5,5,5,5",
  GATE: "PASS_NOT_NATIVE",
};
for (const [key, value] of Object.entries(facts))
  console.log("STAGE52_PLANNING_" + key + "=" + value);
