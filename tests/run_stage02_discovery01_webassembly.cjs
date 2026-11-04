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
const TARGETS = new Map([
  ['test_discovery01_k3_backward_q3_n_minus_one', -1n],
  ['test_discovery01_k3_backward_q3_exact_limit', 0n],
  ['test_discovery01_k3_backward_q3_n_plus_one', 1n]
]);
const SOURCE = path.join(__dirname, 'normative_selector.wat');
const PTR = {M: 65536, N: 83200, LIMIT: 96448, SPACE: 100864, WIDE: 105280, RESULT: 145024};
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
  if (TARGETS.has(name)) {
    const mem = instance.exports.memory;
    assert.ok(mem instanceof WebAssembly.Memory, 'missing memory export');
    record.numerics = {};
    for (const [key, offset] of Object.entries(PTR)) {
      record.numerics[key] = bigintFromWasm(mem, offset);
    }
  }
  process.stdout.write(JSON.stringify(record) + '\n');
}
function checkNumerics(name, values) {
  assert.ok(TARGETS.has(name), 'unexpected numeric target');
  const delta = TARGETS.get(name);
  // Independiente del módulo: el flujo de respuestas desde 1 con paso -1
  // produce los dígitos [0, M-1, M-2] en base M.
  const x = 1n + (M - 1n) * M + (M - 2n) * M * M;
  const t = ((M - 1n) / 3n) * (M * M - 1n);
  const n = t + delta;
  const space = M ** 3n;
  const q = space / n;
  const limit = q * n;
  const chosen = x <= limit ? x : limit; // step=-1: primera aceptación
  const rank = ((chosen - 1n) % n) + 1n;
  const expectedRank = delta === -1n ? t - 1n : delta === 0n ? t : t - 2n;
  assert.equal((M - 1n) % 3n, 0n);
  assert.ok(n > M * M && n < space, 'not a k=3 input');
  assert.equal(q, 3n);
  assert.equal(x, 3n * t);
  assert.equal(x - limit, -3n * delta);
  assert.equal(rank, expectedRank);
  for (const [key, value] of Object.entries({
    M, N: n, SPACE: space, LIMIT: limit, WIDE: chosen, RESULT: rank
  })) {
    assert.equal(BigInt(values[key]), value, name + ': ' + key);
  }
  return {
    name, delta: Number(delta), q: '3', n: n.toString(),
    initial_x: x.toString(), wide: chosen.toString(),
    limit: limit.toString(), rank: rank.toString(),
    acceptance: x > limit ? 'backward_rejection_to_limit' :
      x === limit ? 'exact_limit' : 'below_limit'
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
    assert.equal(tests.length, 31, 'unexpected regression set size');
    assert.equal(new Set(tests).size, 31, 'duplicate export');
    for (const name of TARGETS.keys()) assert.ok(tests.includes(name), 'missing target: ' + name);
    let passed = 0;
    const numerics = {};
    for (const name of tests) {
      const p = spawnSync(process.execPath, [__filename, '--one', compiled, name],
        {encoding: 'utf8', timeout: 30000, maxBuffer: 1000000});
      if (p.error || p.status !== 0 || p.stderr !== '') {
        throw new Error(name + ': process failed: ' + (p.error || p.stderr));
      }
      const outcome = JSON.parse(p.stdout);
      assert.equal(outcome.name, name);
      assert.equal(outcome.value, 1, 'WAT test failed: ' + name);
      if (TARGETS.has(name)) numerics[name] = checkNumerics(name, outcome.numerics);
      passed++;
    }
    assert.equal(Object.keys(numerics).length, TARGETS.size, 'missing numeric probes');
    const report = {
      project_id: 'PC-BRANCH-WAT-SPANISH',
      native_engine: 'Node WebAssembly via WABT',
      source_sha256: crypto.createHash('sha256').update(fs.readFileSync(SOURCE)).digest('hex'),
      total: tests.length, passed, failed: tests.length - passed,
      numeric_oracles: numerics
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
