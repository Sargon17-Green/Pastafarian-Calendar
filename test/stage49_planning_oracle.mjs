#!/usr/bin/env node
// Stage49 / DISCOVERY45: independent arithmetic and ownership planning oracle.
// No production COBOL is invoked; this script CANNOT establish a Native PASS.
import { strict as assert } from 'node:assert';

const widths = [3, 9, 320, 8192];
let arithmetic = 0, cases = 0, inputRebuilds = 0;
let preservedAfterMutation = 0, survivorsAfterFree = 0;
let survivorsAfterReuse = 0, freshOwners = 0, restoredOwners = 0;
let maxWidthCases = 0;
const targetSlots = [0, 0, 0, 0];
const uniquePairs = new Set();
const abs = v => v < 0n ? -v : v;
const distance = (c, t) => abs(t - c) + 1n;

for (const width of widths) {
  for (let j = 1; j <= 6; j++) {
    const place = 10n ** BigInt(width - 1);
    const x = place + BigInt(5 * j + 2);
    const y = place - BigInt(2 * j + 5);
    const direction = j % 2 === 1 ? 1n : -1n;
    const c = j % 2 === 1 ? x : y;
    const t = j % 2 === 1 ? y : x;
    const pair = String(c) + '|' + String(t);
    assert.ok(!uniquePairs.has(pair));
    uniquePairs.add(pair);
    assert.ok(c > 0n && t > 0n);
    if (width === 8192) maxWidthCases++;
    const baseline = Array.from({ length: 4 }, (_, i) =>
      distance(c + direction * BigInt(i), t));
    const shift = BigInt(10 * j + 3);
    const nextC = c + direction * shift;
    const nextT = t - direction * shift;
    assert.ok(nextC > 0n && nextT > 0n);
    const changed = Array.from({ length: 4 }, (_, i) =>
      distance(nextC + direction * BigInt(i), nextT));
    for (let i = 0; i < 4; i++) {
      assert.equal(baseline[i], BigInt(7 * j + 8 + i));
      assert.equal(changed[i], BigInt(27 * j + 14 + i));
      arithmetic += 2;
    }

    // A fresh output object owns its own snapshot, never a reference to input.
    const owners = new Map(baseline.map((value, i) =>
      [i + 1, { value, generation: 0 }]));
    const before = new Map(owners);
    const inputs = { c, t };
    // Simulate release/reinitialization of both caller-owned inputs.
    inputs.c = nextC;
    inputs.t = nextT;
    inputRebuilds += 2;
    assert.equal(inputs.c, nextC);
    assert.equal(inputs.t, nextT);
    for (let slot = 1; slot <= 4; slot++) {
      assert.equal(owners.get(slot), before.get(slot));
      assert.equal(owners.get(slot).value, baseline[slot - 1]);
      preservedAfterMutation++;
    }

    const index = widths.indexOf(width) * 6 + j - 1;
    const selected = index % 4 + 1;
    targetSlots[selected - 1]++;
    const oldOwner = owners.get(selected);
    assert.ok(owners.delete(selected));
    assert.equal(owners.size, 3);
    for (const [slot, owner] of owners) {
      assert.equal(owner, before.get(slot));
      assert.equal(owner.value, baseline[slot - 1]);
      survivorsAfterFree++;
    }
    owners.set(selected, { value: changed[selected - 1], generation: 1 });
    assert.notEqual(owners.get(selected), oldOwner);
    assert.equal(owners.get(selected).value, changed[selected - 1]);
    assert.equal(new Set(owners.values()).size, 4);
    freshOwners++;
    for (const [slot, owner] of owners) {
      if (slot === selected) continue;
      assert.equal(owner, before.get(slot));
      assert.equal(owner.value, baseline[slot - 1]);
      survivorsAfterReuse++;
    }

    // Restore the initial inputs, then retire only the re-used output.
    inputs.c = c;
    inputs.t = t;
    inputRebuilds += 2;
    assert.ok(owners.delete(selected));
    owners.set(selected, { value: baseline[selected - 1], generation: 2 });
    assert.equal(owners.size, 4);
    assert.notEqual(owners.get(selected), oldOwner);
    for (const [slot, owner] of owners) {
      assert.equal(owner.value, baseline[slot - 1]);
      if (slot !== selected) assert.equal(owner, before.get(slot));
    }
    restoredOwners++;
    owners.clear();
    assert.equal(owners.size, 0);
    cases++;
  }
}
assert.equal(cases, 24);
assert.equal(uniquePairs.size, 24);
assert.equal(maxWidthCases, 6);
assert.equal(arithmetic, 192);
assert.equal(inputRebuilds, 96);
assert.equal(preservedAfterMutation, 96);
assert.equal(survivorsAfterFree, 72);
assert.equal(survivorsAfterReuse, 72);
assert.equal(freshOwners, 24);
assert.equal(restoredOwners, 24);
assert.deepEqual(targetSlots, [6, 6, 6, 6]);
console.log('STAGE49_PLANNING_ARITHMETIC=192/192');
console.log('STAGE49_PLANNING_CASES=24/24');
console.log('STAGE49_PLANNING_UNIQUE_PAIRS=24');
console.log('STAGE49_PLANNING_8192_DIGIT_CASES=6');
console.log('STAGE49_PLANNING_INPUT_REBUILDS=96/96');
console.log('STAGE49_PLANNING_PRESERVED_AFTER_MUTATION=96/96');
console.log('STAGE49_PLANNING_SURVIVORS_AFTER_FREE=72/72');
console.log('STAGE49_PLANNING_SURVIVORS_AFTER_REUSE=72/72');
console.log('STAGE49_PLANNING_FRESH_OWNERS=24/24');
console.log('STAGE49_PLANNING_RESTORED_OWNERS=24/24');
console.log('STAGE49_PLANNING_TARGET_BALANCE=6,6,6,6');
console.log('STAGE49_PLANNING_GATE=PASS_NOT_NATIVE');
