#!/usr/bin/env node
'use strict';
// Compare the augmented module's exact memory outputs with the independent
// Python BigInt oracle. Every export is run in a fresh WebAssembly instance.
const assert = require('node:assert/strict');
const fs = require('node:fs');

const [modulePath, oraclePath] = process.argv.slice(2);
if (!modulePath || !oraclePath) {
  process.stderr.write('usage: node stage02_b04_boundary_differential.cjs MODULE.wasm ORACLE.json\n');
  process.exit(2);
}
const oracle = JSON.parse(fs.readFileSync(oraclePath, 'utf8'));
assert.equal(oracle.project_id, 'PC-BRANCH-WAT-SPANISH');
assert.equal(oracle.oracle, 'independent_bigint_literal_ring_walk');
assert.equal(oracle.cases.length, 6);

const PTR = {
  M: 65536,
  FIRST: 74368,
  N: 83200,
  LIMIT: 96448,
  SPACE: 100864,
  RESULT: 145024,
};
const C5_SNAPSHOT = {
  RESULT: 149440,
  LIMIT: 153856,
  SPACE: 158272,
  N: 162688,
};

function readNatural(memory, offset) {
  const view = new DataView(memory.buffer);
  const count = view.getUint32(offset, true);
  assert.ok(count <= 1100, 'invalid base-2^30 limb count');
  let value = 0n;
  for (let index = count - 1; index >= 0; index -= 1) {
    const limb = view.getUint32(offset + 4 + 4 * index, true);
    assert.ok(limb < 2 ** 30, 'invalid base-2^30 limb');
    value = (value << 30n) + BigInt(limb);
  }
  return value;
}

function compareCase(memory, spec, snapshot) {
  const actual = {
    M: readNatural(memory, PTR.M),
    FIRST: readNatural(memory, PTR.FIRST),
    N: readNatural(memory, snapshot ? C5_SNAPSHOT.N : PTR.N),
    RESULT: readNatural(memory, snapshot ? C5_SNAPSHOT.RESULT : PTR.RESULT),
    LIMIT: readNatural(memory, snapshot ? C5_SNAPSHOT.LIMIT : PTR.LIMIT),
  };
  if (spec.check_space) {
    actual.SPACE = readNatural(memory, snapshot ? C5_SNAPSHOT.SPACE : PTR.SPACE);
  }

  const expected = {
    M: BigInt(oracle.M),
    FIRST: BigInt(spec.first),
    N: BigInt(spec.n),
    RESULT: BigInt(spec.result),
    LIMIT: BigInt(spec.limit),
  };
  if (spec.check_space) expected.SPACE = BigInt(spec.space);

  for (const [field, value] of Object.entries(expected)) {
    assert.equal(actual[field], value, spec.id + ': ' + field);
  }
  return Object.fromEntries(Object.entries(actual).map(([key, value]) => [key, value.toString()]));
}

const bytes = fs.readFileSync(modulePath);
const compiled = new WebAssembly.Module(bytes);
const byId = new Map(oracle.cases.map(item => [item.id, item]));
const runs = [];

function runOne(exportName, ids, snapshotId) {
  const instance = new WebAssembly.Instance(compiled, {});
  const fn = instance.exports[exportName];
  assert.equal(typeof fn, 'function', 'missing export ' + exportName);
  const result = fn();
  assert.equal(result, 1, exportName + ': WAT assertion export did not return i32(1)');
  assert.ok(instance.exports.memory instanceof WebAssembly.Memory, 'missing exported memory');

  for (const id of ids) {
    const spec = byId.get(id);
    assert.ok(spec, 'missing oracle case ' + id);
    const observed = compareCase(instance.exports.memory, spec, id === snapshotId);
    runs.push({id, export: exportName, return_value: result, observed});
  }
}

runOne('test_b04_c1_short_backward_m', ['C1'], null);
runOne('test_b04_c2_wide_backward_m_plus_one', ['C2'], null);
runOne('test_b04_c3_wide_backward_reject_2m', ['C3'], null);
runOne('test_b04_c4_wide_backward_reject_3m', ['C4'], null);
runOne('test_b04_c5_c6_parametric', ['C5', 'C6'], 'C5');

process.stdout.write(JSON.stringify({
  project_id: oracle.project_id,
  engine: 'Node WebAssembly',
  cases_compared: runs.length,
  exports_executed: 5,
  results: runs,
  all_exact: true,
  native_executed: false,
  stage02_accepted: false
}) + '\n');
