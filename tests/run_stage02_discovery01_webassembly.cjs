#!/usr/bin/env node
'use strict';
// Stage02 DISCOVERY01 native WebAssembly runner and independent BigInt oracle.
// Requires Node.js >=18 and WABT wat2wasm on PATH; does not modify sources.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const crypto = require('node:crypto');
const { spawnSync } = require('node:child_process');
const TARGET = 'test_discovery01_k3_backward_q3_exact_limit';
const SOURCE = path.join(__dirname, 'normative_selector.wat');
const PTR = {M: 65536, N: 83200, LIMIT: 96448, WIDE: 105280, RESULT: 145024};
const M = (1n << 127n) - 1n;
const MAX_LIMBS = 1100;
function bigintFromWasm(memory, offset) {
  const view = new DataView(memory.buffer);
  const len = view.getUint32(offset, true);
  assert.ok(len <= MAX_LIMBS, 'invalid limb count');
  let number = 0n;
  for (let i = len - 1; i >= 0; --i) {
    const limb = view.getUint32(offset + 4 + 4 * i, true);
    assert.ok(limb < 2 ** 30, 'invalid base-2^30 limb');
    number = (number << 30n) + BigInt(limb);
  }
  return number.toString();
}
function child(file, name) {
  const bytes = fs.readFileSync(file);
  const module = new WebAssembly.Module(bytes);
  const instance = new WebAssembly.Instance(module, {});
  assert.equal(typeof instance.exports[name], 'function', 'missing export');
  const value = instance.exports[name]();
  const record = {name, value};
  if (name === TARGET) {
    const mem = instance.exports.memory;
    assert.ok(mem instanceof WebAssembly.Memory, 'missing memory export');
    record.numerics = {};
    for (const [key, offset] of Object.entries(PTR)) {
      record.numerics[key] = bigintFromWasm(mem, offset);
    }
  }
  process.stdout.write(JSON.stringify(record) + '\n');
}
function checkNumerics(values) {
  const digits = [1n, M, M - 1n];
  const x = 1n + (digits[0] - 1n) +
    (digits[1] - 1n) * M + (digits[2] - 1n) * M * M;
  const n = ((M - 1n) / 3n) * (M * M - 1n);
  const space = M ** 3n;
  const q = space / n;
  const limit = q * n;
  const rank = ((x - 1n) % n) + 1n;
  assert.equal((M - 1n) % 3n, 0n);
  assert.ok(n > M * M && n <= space, 'not a k=3 input');
  assert.equal(q, 3n);
  assert.equal(x, limit, 'not on acceptance boundary');
  assert.equal(rank, n, 'independent rank computation failed');
  assert.equal(BigInt(values.M), M);
  assert.equal(BigInt(values.N), n);
  assert.equal(BigInt(values.LIMIT), limit);
  assert.equal(BigInt(values.WIDE), x);
  assert.equal(BigInt(values.RESULT), rank);
  return {
    q: q.toString(), n: n.toString(), wide: x.toString(),
    limit: limit.toString(), result: rank.toString(),
    acceptance: 'x_equals_limit', step: -1, first: 1, k: 3
  };
}
function main() {
  if (process.argv[2] === '--one') {
    child(process.argv[3], process.argv[4]);
    return;
  }
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'wat-es-stage02-'));
  try {
    const compiled = path.join(dir, 'selector.wasm');
    const compile = spawnSync('wat2wasm', [SOURCE, '-o', compiled],
      {encoding: 'utf8', timeout: 30000});
    if (compile.error || compile.status !== 0) {
      throw new Error('wat2wasm failed: ' + (compile.error || compile.stderr));
    }
    const mod = new WebAssembly.Module(fs.readFileSync(compiled));
    const tests = WebAssembly.Module.exports(mod)
      .filter(e => e.kind === 'function' && e.name.startsWith('test_'))
      .map(e => e.name).sort();
    assert.equal(tests.length, 29, 'unexpected regression set size');
    assert.equal(new Set(tests).size, 29, 'duplicate export');
    assert.ok(tests.includes(TARGET), 'target export missing');
    let passed = 0;
    let numerics = null;
    for (const name of tests) {
      const p = spawnSync(process.execPath, [__filename, '--one', compiled, name],
        {encoding: 'utf8', timeout: 30000, maxBuffer: 1000000});
      if (p.error || p.status !== 0 || p.stderr !== '') {
        throw new Error(name + ': process failed: ' + (p.error || p.stderr));
      }
      const outcome = JSON.parse(p.stdout);
      assert.equal(outcome.name, name);
      assert.equal(outcome.value, 1, 'WAT test failed: ' + name);
      if (name === TARGET) numerics = checkNumerics(outcome.numerics);
      passed++;
    }
    assert.ok(numerics, 'numeric probe did not run');
    const report = {
      project_id: 'PC-BRANCH-WAT-SPANISH',
      native_engine: 'Node WebAssembly via WABT',
      source_sha256: crypto.createHash('sha256').update(fs.readFileSync(SOURCE)).digest('hex'),
      total: tests.length, passed, failed: tests.length - passed,
      numeric_oracle: numerics
    };
    process.stdout.write(JSON.stringify(report, null, 2) + '\n');
  } finally {
    fs.rmSync(dir, {recursive: true, force: true});
  }
}
try { main(); } catch (err) {
  process.stderr.write(String(err.stack || err) + '\n');
  process.exitCode = 1;
}
