'use strict';

const fs = require('node:fs');

async function main() {
  const wasmPath = process.argv[2];
  const oraclePath = process.argv[3];
  if (!wasmPath || !oraclePath) {
    throw new Error('USAGE: node stage02_k259_capacity_witness.cjs <instrumented.wasm> <oracle.json>');
  }
  const wasmBytes = fs.readFileSync(wasmPath);
  const oracle = JSON.parse(fs.readFileSync(oraclePath, 'utf8'));
  const module = await WebAssembly.compile(wasmBytes);
  const expectedN = BigInt(oracle.N_max_for_MN_below_capacity_decimal);
  const expected = {
    qa_k259_capacity_forward: BigInt(oracle.forward_expected_decimal),
    qa_k259_capacity_backward: BigInt(oracle.backward_expected_decimal),
  };

  function readNatural(memory, offset) {
    const view = new DataView(memory.buffer);
    const count = view.getUint32(offset, true);
    if (!Number.isInteger(count) || count < 1 || count > 1100) {
      throw new Error('INVALID_LIMB_COUNT:' + count);
    }
    let value = 0n;
    for (let i = count - 1; i >= 0; i -= 1) {
      const limb = view.getUint32(offset + 4 + (i * 4), true);
      if (limb >= (1 << 30)) throw new Error('INVALID_LIMB:' + i + ':' + limb);
      value = (value << 30n) + BigInt(limb);
    }
    return { value, count };
  }

  const results = [];
  for (const name of Object.keys(expected)) {
    const instance = await WebAssembly.instantiate(module, {});
    const memory = instance.exports.memory;
    if (!(memory instanceof WebAssembly.Memory)) throw new Error('EXPORTED_MEMORY_MISSING');
    if (memory.buffer.byteLength !== 96 * 65536) throw new Error('MEMORY_SIZE_MISMATCH');
    const fn = instance.exports[name];
    if (typeof fn !== 'function') throw new Error('EXPORT_MISSING:' + name);
    const started = process.hrtime.bigint();
    const returnValue = fn();
    const elapsedNs = process.hrtime.bigint() - started;
    if (returnValue !== 1) throw new Error(name + ':EXPECTED_I32_1_GOT_' + String(returnValue));
    const actual = readNatural(memory, 145024);
    const nAfter = readNatural(memory, 83200);
    if (actual.value !== expected[name]) throw new Error(name + ':FULL_LIMB_ORACLE_MISMATCH');
    if (nAfter.value !== expectedN) throw new Error(name + ':N_MUTATED');
    results.push({
      name,
      status: 'PASS',
      returnValue,
      resultLimbs: actual.count,
      nLimbsAfter: nAfter.count,
      elapsedMs: Number(elapsedNs) / 1e6,
    });
  }
  const summary = {
    project: 'PC-BRANCH-WAT-SPANISH',
    gate: 'CAPACITY_EDGE_K259_STRESS_ONLY',
    engine: 'Node WebAssembly',
    results,
    passed: results.length,
    failed: 0,
    legalDomainMaxVerified: false,
    stage02Accepted: false,
  };
  process.stdout.write(JSON.stringify(summary, null, 2) + '\n');
}

main().catch((error) => {
  process.stderr.write('K259_NODE_WITNESS_FAILED: ' + (error.stack || error) + '\n');
  process.exitCode = 1;
});
