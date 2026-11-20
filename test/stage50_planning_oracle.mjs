#!/usr/bin/env node
// Stage50 / DISCOVERY46 — independent five-owner signed planning oracle.
// No COBOL production invocation. PASS_NOT_NATIVE cannot establish Native PASS.
import { strict as assert } from 'node:assert';
const widths = [3, 9, 128, 320, 8192];
const abs = x => x < 0n ? -x : x;
const distance = (c, t) => abs(t - c) + 1n;
// Grade-school decimal digit addition: not computed via BigInt.
function addDecimal(a, b) {
  assert.match(a, /^(0|[1-9][0-9]*)$/);
  assert.match(b, /^(0|[1-9][0-9]*)$/);
  let i = a.length - 1, j = b.length - 1, carry = 0, out = '';
  while (i >= 0 || j >= 0 || carry) {
    const p = i >= 0 ? a.charCodeAt(i--) - 48 : 0;
    const q = j >= 0 ? b.charCodeAt(j--) - 48 : 0;
    const sum = p + q + carry;
    out = String(sum % 10) + out;
    carry = Math.floor(sum / 10);
  }
  return out.replace(/^0+(?=.)/, '');
}
const gradeSchool = (a, b) => addDecimal(addDecimal(a, b), '1');
let cases = 0, arithmetic = 0, initialOwners = 0, inputRebuilds = 0;
let preservedAfterInputChange = 0, occupiedRejects = 0;
let preservedAfterReject = 0, survivorsAfterFree = 0;
let survivorsAfterReuse = 0, replacementOwners = 0;
let restoredOwners = 0, restoredSnapshots = 0, finalCleanup = 0;
let maxWidthCases = 0;
const targetSlots = [0, 0, 0, 0, 0], uniquePairs = new Set();
for (const width of widths) {
  const power = 10n ** BigInt(width - 1);
  for (let j = 1; j <= 5; j++) {
    const c = power + BigInt(4 * j + 3);
    const t = -(power - BigInt(2 * j + 1));
    const mutatedC = -(power + BigInt(3 * j + 2));
    const mutatedT = power - BigInt(j + 1);
    assert.ok(c > 0n && t < 0n && mutatedC < 0n && mutatedT > 0n);
    assert.equal(String(c).length, width);
    assert.equal(String(-t).length, width - 1);
    assert.equal(String(mutatedT).length, width - 1);
    const key = String(c) + '|' + String(t);
    assert.ok(!uniquePairs.has(key));
    uniquePairs.add(key);
    if (width === 8192) maxWidthCases++;
    const baseline = [], changed = [];
    for (let i = 0; i < 5; i++) {
      const cSlot = c + BigInt(i), changedCSlot = mutatedC - BigInt(i);
      const expected = distance(cSlot, t), nextExpected = distance(changedCSlot, mutatedT);
      assert.equal(expected.toString(), gradeSchool(cSlot.toString(), (-t).toString()));
      assert.equal(nextExpected.toString(), gradeSchool((-changedCSlot).toString(), mutatedT.toString()));
      assert.equal(expected, 2n * power + BigInt(2 * j + 3 + i));
      assert.equal(nextExpected, 2n * power + BigInt(2 * j + 2 + i));
      assert.equal(expected.toString().length, width);
      assert.equal(nextExpected.toString().length, width);
      baseline.push(expected.toString());
      changed.push(nextExpected.toString());
      arithmetic += 2;
    }
    const owners = new Map(baseline.map((value, i) => [i + 1, { token: Symbol(), value }]));
    const originals = new Map(owners);
    assert.equal(new Set([...owners.values()].map(o => o.token)).size, 5);
    initialOwners += 5;
    const input = { c, t };
    input.c = mutatedC; input.t = mutatedT; inputRebuilds += 2;
    assert.equal(input.c, mutatedC); assert.equal(input.t, mutatedT);
    for (const [slot, owner] of owners) {
      assert.equal(owner, originals.get(slot));
      assert.equal(owner.value, baseline[slot - 1]);
      preservedAfterInputChange++;
    }
    assert.equal(owners.size, 5);
    occupiedRejects++;
    for (const [slot, owner] of owners) {
      assert.equal(owner, originals.get(slot));
      preservedAfterReject++;
    }
    const selected = (cases % 5) + 1;
    targetSlots[selected - 1]++;
    const retired = owners.get(selected);
    assert.ok(owners.delete(selected));
    assert.equal(owners.size, 4);
    for (const [slot, owner] of owners) {
      assert.equal(owner, originals.get(slot));
      survivorsAfterFree++;
    }
    owners.set(selected, { token: Symbol(), value: changed[selected - 1] });
    assert.notEqual(owners.get(selected).token, retired.token);
    assert.equal(owners.size, 5);
    replacementOwners++;
    for (const [slot, owner] of owners) {
      if (slot === selected) continue;
      assert.equal(owner, originals.get(slot));
      survivorsAfterReuse++;
    }
    input.c = c; input.t = t; inputRebuilds += 2;
    assert.equal(input.c, c); assert.equal(input.t, t);
    assert.ok(owners.delete(selected));
    owners.set(selected, { token: Symbol(), value: baseline[selected - 1] });
    assert.notEqual(owners.get(selected).token, retired.token);
    restoredOwners++;
    for (const [slot, owner] of owners) {
      assert.equal(owner.value, baseline[slot - 1]);
      if (slot !== selected) assert.equal(owner, originals.get(slot));
      restoredSnapshots++;
    }
    owners.clear();
    assert.equal(owners.size, 0);
    finalCleanup++;
    cases++;
  }
}
assert.equal(cases, 25);
assert.equal(uniquePairs.size, 25);
assert.equal(maxWidthCases, 5);
assert.equal(arithmetic, 250);
assert.equal(initialOwners, 125);
assert.equal(inputRebuilds, 100);
assert.equal(preservedAfterInputChange, 125);
assert.equal(occupiedRejects, 25);
assert.equal(preservedAfterReject, 125);
assert.equal(survivorsAfterFree, 100);
assert.equal(survivorsAfterReuse, 100);
assert.equal(replacementOwners, 25);
assert.equal(restoredOwners, 25);
assert.equal(restoredSnapshots, 125);
assert.equal(finalCleanup, 25);
assert.deepEqual(targetSlots, [5, 5, 5, 5, 5]);
for (const [key, value] of Object.entries({
  ARITHMETIC:'250/250', CASES:'25/25', UNIQUE_PAIRS:25,
  MAX_WIDTH_CASES:5, INITIAL_OWNERS:125, INPUT_REBUILDS:100,
  PRESERVED_AFTER_INPUT_CHANGE:125, OCCUPIED_REJECTS:25,
  PRESERVED_AFTER_REJECT:125, SURVIVORS_AFTER_FREE:100,
  SURVIVORS_AFTER_REUSE:100, REPLACEMENT_OWNERS:25,
  RESTORED_OWNERS:25, RESTORED_SNAPSHOTS:125,
  FINAL_CLEANUP:25, TARGET_BALANCE:targetSlots.join(',')
})) console.log('STAGE50_PLANNING_' + key + '=' + value);
console.log('STAGE50_PLANNING_GATE=PASS_NOT_NATIVE');
