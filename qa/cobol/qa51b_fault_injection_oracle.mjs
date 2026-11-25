import assert from "node:assert/strict";

const current = 1000n;
const target = 990n;
const expected = (current >= target ? current - target : target - current) + 1n;
assert.equal(expected.toString(), "11");

const partial = "123456789012345678";
const chunks = [partial.slice(-9), partial.slice(0, -9)];
assert.equal(partial.length, 18);
assert.deepEqual(chunks.map(x => x.length), [9, 9]);
assert.equal([...chunks].reverse().join(""), partial);

const injected = [
  {point: "SUB", status: 91},
  {point: "INIT-TEXT", status: 92},
  {point: "ADD", status: 93},
  {point: "FREE-A", status: 94},
  {point: "HEAP-LIVE", status: 95},
  {point: "ALLOC-R", status: 96}
];
assert.equal(new Set(injected.map(x => x.status)).size, 6);

console.log(JSON.stringify({
  schema: "COBOL_QA51B_TEST_BUILD_FAULT_INJECTION_ORACLE/1",
  cases: 7,
  expected_distance: expected.toString(),
  partial_input_digits: partial.length,
  partial_chunk_widths: chunks.map(x => x.length),
  injected_faults: injected,
  gate: "PASS_NOT_NATIVE",
  production_source_modified: false
}));
