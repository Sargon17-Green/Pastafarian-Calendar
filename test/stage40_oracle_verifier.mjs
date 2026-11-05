#!/usr/bin/env node
// Independent Stage40 source-emitted fixture oracle; test-only, never production.
import { readFileSync } from "node:fs";
import { strict as assert } from "node:assert";
const source = readFileSync(
  new URL("./stage40_discovery_tests.cob", import.meta.url), "utf8"
);
const rx = /WHEN ([1-6])\s+MOVE "(\d{2})" TO WS-BASE-X\(WS-X-POS:2\)\s+MOVE "(\d{2})" TO WS-BASE-Y\(WS-Y-POS:2\)/g;
const suffixes = [...source.matchAll(rx)].map(m => ({
  j: Number(m[1]), x: m[2], y: m[3]
}));
assert.equal(suffixes.length, 6, "Six source-defined fixture suffix pairs");
assert.equal(new Set(suffixes.map(p => p.j)).size, 6);
for (const needle of [
  "COMPUTE WS-TAIL-POS =",
  "FUNCTION LENGTH(FUNCTION TRIM(WS-C-LITERAL)) - 1",
  "FUNCTION NUMVAL(WS-C-LITERAL(WS-TAIL-POS:2))",
  "PERFORM CHECK-DISTINCT",
  "PERFORM RELEASE-RESULT",
  "STAGE40_NONLIFO_CLEANUP="
]) {
  assert.ok(source.includes(needle), "COBOL lifecycle/suffix contract: " + needle);
}
let total = 0;
let maxInput = 0;
let longest = 0;
const cases = new Set();
for (const n of [3, 9, 320, 8192]) {
  for (const { j, x, y } of suffixes) {
    const emittedX = "1" + "0".repeat(n - 3) + x;
    const emittedY = "9".repeat(n - 3) + y;
    const k = 10n ** BigInt(n - 1);
    assert.equal(BigInt(emittedX), k + BigInt(5 * j + 2));
    assert.equal(BigInt(emittedY), k - BigInt(2 * j + 5));
    const c = j % 2 ? emittedX : emittedY;
    const t = j % 2 ? emittedY : emittedX;
    const key = c + "|" + t;
    assert.ok(!cases.has(key), "Unique ordered input pair");
    cases.add(key);
    maxInput = Math.max(maxInput, c.length, t.length);
    for (let d = 0; d < 3; d++) {
      // Reconstruct precisely the decimal string emitted by COBOL:
      // leading unchanged prefix + the actual TWO-DIGIT suffix of C.
      const adjustment = j % 2 ? d : -d;
      const last2 = Number(c.slice(-2)) + adjustment;
      assert.ok(last2 >= 0 && last2 <= 99);
      const emittedC = c.slice(0, -2) + String(last2).padStart(2, "0");
      assert.equal(emittedC.length, c.length);
      const diff = BigInt(t) - BigInt(emittedC);
      const oracle = (diff < 0n ? -diff : diff) + 1n;
      const closedForm = BigInt(7 * j + 8 + d);
      assert.equal(oracle, closedForm, "Independent BigInt vs closed form");
      longest = Math.max(longest, emittedC.length);
      total++;
    }
  }
}
assert.equal(total, 72);
assert.equal(cases.size, 24);
assert.equal(maxInput, 8192);
assert.equal(longest, 8192);
console.log("STAGE40_ORACLE_PASS=72/72");
console.log("STAGE40_UNIQUE_BASE_PAIRS=24");
console.log("STAGE40_MAX_DIGITS=8192");
console.log("STAGE40_8192_DIGIT_CASES=6");
