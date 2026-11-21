#!/usr/bin/env node
'use strict';
// QA-only k253 witness for PC-BRANCH-WAT-SPANISH. Never edits normative WAT.
const fs = require('node:fs');
const path = require('node:path');
const os = require('node:os');
const crypto = require('node:crypto');
const cp = require('node:child_process');

const PROJECT_ID = 'PC-BRANCH-WAT-SPANISH';
const LOCKED_COMMIT = '871f9b70216c16c57abcd552ec6fb0ed1010e305';
const WAT_SHA256 = '18e2c15a142b3a262ff38a1e084d86bdc1a139ce030b0318f279dbcdb23f8980';
const WAT_BLOB = 'e23f013ab96b498b0ac365dbb1b25273c845e790';
const EXPECT_FORWARD_SHA = '82908b318fb3f8d991bdbec92b2ac2c51f96e093b806ef979df084974f08e6a5';
const EXPECT_BACKWARD_SHA = '3b8e337f6d91ec378519cd6dcc489d920f171c13910556889b56775697d18631';
const BASE = 1n << 30n;
const M = (1n << 127n) - 1n;
const N = 47n ** 5778n;
const MAX_LIMBS = 1100;
const MEM_BYTES = 96 * 65536;
const N_OFFSET = 83200;
const RESULT_OFFSET = 145024;
const CELL_BYTES = 4416;
const EVIDENCE = path.join(process.cwd(), 'evidence', 'wat-k253');
const SOURCE = path.join(process.cwd(), 'tests', 'normative_selector.wat');

function assert(ok, msg) { if (!ok) throw Error(msg); }
function sha(bytes) { return crypto.createHash('sha256').update(bytes).digest('hex'); }
function save(name, value) { fs.writeFileSync(path.join(EVIDENCE, name), value); }
function saveJson(name, object) { save(name, JSON.stringify(object, null, 2) + '\n'); }
function gitBlob(b) {
  return crypto.createHash('sha1').update(Buffer.concat([
    Buffer.from('blob ' + b.length + '\0', 'ascii'), b
  ])).digest('hex');
}
function limbWords(n) {
  const limbs = [];
  while (n > 0n) {
    limbs.push(Number(n % BASE));
    n /= BASE;
  }
  return limbs;
}
function writeNatural(memory, offset, n) {
  const words = limbWords(n);
  assert(words.length > 0 && words.length <= MAX_LIMBS, 'N_LENGTH_INVALID');
  assert(offset % 4 === 0 && offset + CELL_BYTES <= memory.buffer.byteLength,
    'N_MEMORY_BOUNDS');
  const view = new DataView(memory.buffer);
  view.setUint32(offset, words.length, true);
  for (let i = 0; i < words.length; i++) {
    assert(words[i] >= 0 && words[i] < Number(BASE), 'N_LIMB_INVALID');
    view.setUint32(offset + 4 + 4 * i, words[i], true);
  }
  return words.length;
}
function readNatural(memory, offset) {
  const view = new DataView(memory.buffer);
  assert(offset % 4 === 0 && offset + CELL_BYTES <= memory.buffer.byteLength,
    'RESULT_MEMORY_BOUNDS');
  const length = view.getUint32(offset, true);
  assert(length >= 1 && length <= MAX_LIMBS, 'RESULT_LENGTH_INVALID:' + length);
  let n = 0n;
  for (let i = length - 1; i >= 0; i--) {
    const word = view.getUint32(offset + 4 + 4 * i, true);
    assert(BigInt(word) < BASE, 'RESULT_NON_CANONICAL_LIMB:' + i);
    assert(i !== length - 1 || word !== 0, 'RESULT_LEADING_ZERO');
    n = n * BASE + BigInt(word);
  }
  return { value: n, limbs: length };
}
function oracle() {
  let space = 1n, k = 0;
  while (space < N) { space *= M; ++k; }
  assert(k === 253 && space / M < N && N <= space, 'K_253_NOT_MINIMAL');
  assert(space < M * N, 'SPACE_LIMIT');
  assert(M * N < (1n << 33000n), 'MAX_LIMB_OVERFLOW');
  const q = space / N;
  assert(q > 0n && q < M, 'Q_BOUND');
  const limit = q * N;
  let power = 1n, weighted = 0n;
  for (let j = 0; j < k; j++) {
    weighted += BigInt(j) * power;
    power *= M;
  }
  assert(power === space, 'INDEPENDENT_SPACE_MISMATCH');
  const closedNumerator = M - BigInt(k) * space
    + BigInt(k - 1) * space * M;
  const closedDenominator = (M - 1n) ** 2n;
  assert(closedNumerator % closedDenominator === 0n, 'CLOSED_FORM_NOT_INTEGER');
  const closed = closedNumerator / closedDenominator;
  assert(closed === weighted, 'WEIGHTED_SUM_DIFFERENTIAL');
  assert(1n + weighted <= limit, 'FORWARD_REJECTION_UNEXPECTED');
  assert(space - weighted > limit, 'BACKWARD_REJECTION_EXPECTED');
  const forward = 1n + (weighted % N);
  const backward = N;
  assert(sha(Buffer.from(forward.toString(), 'ascii')) === EXPECT_FORWARD_SHA,
    'FORWARD_ORACLE_HASH_MISMATCH');
  assert(sha(Buffer.from(backward.toString(), 'ascii')) === EXPECT_BACKWARD_SHA,
    'BACKWARD_ORACLE_HASH_MISMATCH');
  return { k, spaceBits: space.toString(2).length, nBits: N.toString(2).length,
    qBits: q.toString(2).length, forward, backward };
}
function instrument(sourceText) {
  const close = sourceText.lastIndexOf(')');
  assert(close >= 0 && sourceText.slice(close + 1).trim() === '',
    'NO_UNIQUE_END_OF_MODULE');
  const tail = [
    '  ;; QA ONLY: externally seeded N remains untouched.',
    '  (func (export "qa_k253_forward")',
    '    (call $init_constants)',
    '    (call $copy (global.get $FIRST) (global.get $ONE))',
    '    (call $choose (global.get $FIRST) (i32.const 1)',
    '      (global.get $N) (global.get $RESULT)))',
    '  (func (export "qa_k253_backward")',
    '    (call $init_constants)',
    '    (call $copy (global.get $FIRST) (global.get $M))',
    '    (call $choose (global.get $FIRST) (i32.const -1)',
    '      (global.get $N) (global.get $RESULT)))'
  ].join('\n') + '\n';
  const instrumented = sourceText.slice(0, close) + tail + sourceText.slice(close);
  assert(instrumented.replace(tail, '') === sourceText,
    'INSTRUMENTATION_CHANGED_ORIGINAL');
  return { instrumented, tail };
}
function cmd(program, argv, timeoutMs) {
  const result = cp.spawnSync(program, argv, {
    encoding: 'utf8', timeout: timeoutMs, maxBuffer: 5 * 1024 * 1024
  });
  return { exitCode: result.status, signal: result.signal,
    error: result.error ? result.error.message : null,
    stdout: result.stdout || '', stderr: result.stderr || '' };
}
function prepare() {
  fs.mkdirSync(EVIDENCE, { recursive: true });
  const raw = fs.readFileSync(SOURCE);
  assert(sha(raw) === WAT_SHA256, 'SOURCE_SHA256_MISMATCH');
  assert(gitBlob(raw) === WAT_BLOB, 'SOURCE_GIT_BLOB_MISMATCH');
  const sourceText = raw.toString('utf8');
  assert(Buffer.from(sourceText, 'utf8').equals(raw), 'UTF8_SOURCE_MISMATCH');
  assert(raw.length === 94201, 'SOURCE_BYTE_COUNT_CHANGED');
  const { instrumented, tail } = instrument(sourceText);
  const originalExports = [...sourceText.matchAll(/\(func\s+\(export\s+"([^"]+)"\)\s+\(result\s+i32\)/g)]
    .map(match => match[1]);
  assert(originalExports.length === 111
    && new Set(originalExports).size === 111, 'ORIGINAL_EXPORT_INVENTORY');
  assert(!sourceText.includes('qa_k253_forward') && !sourceText.includes('qa_k253_backward'),
    'QA_EXPORT_ALREADY_PRESENT');
  const originalSha = gitBlob(raw);
  save('source.wat', raw);
  save('instrumentation-only.diff.txt', tail);
  save('instrumented.wat', instrumented);
  const wasmFile = path.join(EVIDENCE, 'instrumented.wasm');
  const compiled = cmd('wat2wasm', [path.join(EVIDENCE, 'instrumented.wat'),
    '-o', wasmFile], 120000);
  save('wat2wasm.stdout.txt', compiled.stdout);
  save('wat2wasm.stderr.txt', compiled.stderr);
  assert(compiled.exitCode === 0, 'WAT2WASM_FAILED:' + compiled.exitCode
    + ':' + compiled.error);
  const validated = cmd('wasm-validate', [wasmFile], 120000);
  save('wasm-validate.stdout.txt', validated.stdout);
  save('wasm-validate.stderr.txt', validated.stderr);
  assert(validated.exitCode === 0, 'WASM_VALIDATE_FAILED:' + validated.exitCode);
  const oracleResult = oracle();
  const expected = { project: PROJECT_ID, sourceCommit: LOCKED_COMMIT,
    sourceSha256: WAT_SHA256, sourceGitBlob: originalSha,
    sourceBytes: raw.length, qaCommit: process.env.GITHUB_SHA || '',
    runId: process.env.GITHUB_RUN_ID || '',
    runAttempt: process.env.GITHUB_RUN_ATTEMPT || '',
    platform: os.platform(), arch: os.arch(), node: process.version,
    wat2wasmVersion: cmd('wat2wasm', ['--version'], 15000).stdout.trim(),
    wasmValidateVersion: cmd('wasm-validate', ['--version'], 15000).stdout.trim(),
    scriptSha256: sha(fs.readFileSync(__filename)),
    instrumentedWatSha256: sha(Buffer.from(instrumented, 'utf8')),
    instrumentedWasmSha256: sha(fs.readFileSync(wasmFile)),
    NBits: oracleResult.nBits, NLimbs: limbWords(N).length,
    NSha256Decimal: sha(Buffer.from(N.toString(), 'ascii')),
    minimalK: oracleResult.k, spaceBits: oracleResult.spaceBits,
    quotientBits: oracleResult.qBits, originalTestExports: originalExports.length,
    qaAddedExports: ['qa_k253_forward', 'qa_k253_backward'],
    oracleIndependentOfWAT: true, acceptedNative111Rerun: false,
    forwardExpectedSha256Decimal: EXPECT_FORWARD_SHA,
    backwardExpectedSha256Decimal: EXPECT_BACKWARD_SHA };
  saveJson('manifest.json', expected);
  saveJson('oracle.json', {
    expectedForwardDecimal: oracleResult.forward.toString(),
    expectedBackwardDecimal: oracleResult.backward.toString(),
    expectedForwardSha256Decimal: EXPECT_FORWARD_SHA,
    expectedBackwardSha256Decimal: EXPECT_BACKWARD_SHA,
    nDecimal: N.toString()
  });
  return expected;
}
async function runCase(mode) {
  assert(mode === 'forward' || mode === 'backward', 'INVALID_CASE');
  const preflight = oracle();
  const data = fs.readFileSync(path.join(EVIDENCE, 'instrumented.wasm'));
  const manifest = JSON.parse(fs.readFileSync(path.join(EVIDENCE, 'manifest.json'), 'utf8'));
  assert(sha(data) === manifest.instrumentedWasmSha256, 'WASM_BINARY_IDENTITY');
  const wasm = await WebAssembly.instantiate(data, {});
  const instance = wasm.instance;
  const memory = instance.exports.memory;
  assert(memory instanceof WebAssembly.Memory && memory.buffer.byteLength === MEM_BYTES,
    'MEMORY_EXPORT_OR_SIZE_CHANGED');
  const nLimbs = writeNatural(memory, N_OFFSET, N);
  const fn = instance.exports['qa_k253_' + mode];
  assert(typeof fn === 'function', 'QA_EXPORT_MISSING');
  const before = process.hrtime.bigint();
  const returnValue = fn();
  const elapsedMs = Number(process.hrtime.bigint() - before) / 1000000;
  assert(returnValue === undefined, 'UNEXPECTED_QA_RETURN');
  const measuredN = readNatural(memory, N_OFFSET);
  assert(measuredN.value === N && measuredN.limbs === nLimbs, 'N_WAS_MUTATED');
  const actual = readNatural(memory, RESULT_OFFSET);
  const expected = mode === 'forward' ? preflight.forward : preflight.backward;
  assert(actual.value === expected, 'NATIVE_OUTPUT_MISMATCH');
  const actualDigest = sha(Buffer.from(actual.value.toString(), 'ascii'));
  const knownDigest = mode === 'forward' ? EXPECT_FORWARD_SHA : EXPECT_BACKWARD_SHA;
  assert(actualDigest === knownDigest, 'NATIVE_DECIMAL_HASH_MISMATCH');
  const output = { mode, status: 'PASS', resultType: 'BigInt',
    resultLimbs: actual.limbs, resultBits: actual.value.toString(2).length,
    resultSha256Decimal: actualDigest, executionMs: elapsedMs,
    actualEqualsIndependentOracle: true };
  saveJson(mode + '.result.json', output);
  console.log(JSON.stringify(output));
}
async function main() {
  fs.mkdirSync(EVIDENCE, { recursive: true });
  if (process.argv[2] === '--case') {
    try { await runCase(process.argv[3]); }
    catch (e) {
      saveJson(String(process.argv[3] || 'unknown') + '.error.json', {
        status: 'FAIL', reason: String(e && e.stack || e)
      });
      console.error(e && e.stack || e);
      process.exitCode = 1;
    }
    return;
  }
  const summary = { project: PROJECT_ID, sourceSha256: WAT_SHA256,
    gate: 'FOCUSED_K253_QA_ONLY', historicalProvenanceVerified: false,
    stage02Accepted: false, cases: [] };
  try {
    prepare();
    for (const mode of ['forward', 'backward']) {
      const start = Date.now();
      const r = cmd(process.execPath, [__filename, '--case', mode], 300000);
      save(mode + '.stdout.txt', r.stdout);
      save(mode + '.stderr.txt', r.stderr);
      const passed = r.exitCode === 0
        && fs.existsSync(path.join(EVIDENCE, mode + '.result.json'));
      summary.cases.push({ mode, status: passed ? 'PASS' :
        (r.error && r.error.includes('ETIMEDOUT') ? 'TIMEOUT' : 'FAIL'),
        exitCode: r.exitCode, signal: r.signal, error: r.error,
        wallMs: Date.now() - start });
      console.log(mode + ': ' + summary.cases[summary.cases.length - 1].status);
    }
    summary.result = summary.cases.every(x => x.status === 'PASS')
      ? 'FOCUSED_NATIVE_PASS' : 'FOCUSED_NATIVE_NOT_ACCEPTED';
  } catch (e) {
    summary.result = 'PREPARE_FAILED';
    summary.error = String(e && e.stack || e);
    console.error(summary.error);
  } finally {
    saveJson('summary.json', summary);
  }
  if (summary.result !== 'FOCUSED_NATIVE_PASS') process.exitCode = 1;
}
main().catch(e => {
  console.error(e.stack || e);
  process.exitCode = 1;
});
