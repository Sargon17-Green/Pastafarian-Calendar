#!/usr/bin/env node
/** Stage56 QA-only: independently reproduce every external gate via the pinned Scroll oracle. */
import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { execFileSync } from 'node:child_process';
import { readFileSync, writeFileSync, realpathSync } from 'node:fs';
import { join, resolve, basename } from 'node:path';
import { pathToFileURL } from 'node:url';

const PROJECT = 'PC-BRANCH-PHP-MALAY';
const SOURCE = 'cc2cf0b422757a5e7c33218ce30cffa8f99c6786';
const REFERENCE_SHA = '46b2f316eb2b08c2dc99fd827d8e0a227061c9b97bbb708842318c08a7bf1880';
const ORACLE_PATH = 'verification/reference-oracle/reference.mjs';
const ORACLE_SHA = '21c103d3540eb5481445a190cef98f2628de7eb90b7240879fede0d519cf4a95';
const JDN = -13334246;
const hash = bytes => createHash('sha256').update(bytes).digest('hex');
const git = (root, ...args) => execFileSync('git', ['-C', root, ...args], { encoding: 'utf8', maxBuffer: 10 * 1024 * 1024 }).trim();

/** Explicitly injectable comparator, for negative-interface regression tests only. */
export function verifyExactGatePositions(gates, indices, at) {
  if (!gates || typeof gates !== 'object' || Array.isArray(gates)) throw Error('GATE_MAP_TYPE');
  if (!Array.isArray(indices) || indices.length === 0) throw Error('GATE_INDICES');
  const keys = Object.keys(gates).sort();
  const expected = indices.map(String).sort();
  assert.deepEqual(keys, expected, 'GATE_INDEX_COVERAGE');
  for (const index of indices) {
    if (!Number.isSafeInteger(index)) throw Error('GATE_INDEX_TYPE');
    const actual = gates[String(index)];
    if (!Number.isSafeInteger(actual)) throw Error('GATE_DAY_TYPE:' + index);
    const independent = at(index);
    if (typeof independent !== 'bigint' || BigInt(actual) !== independent) {
      throw Error('INDEPENDENT_SCROLL_GATE_MISMATCH:' + index);
    }
  }
  return indices.length;
}
function arg(name) {
  const args = process.argv.slice(2), i = args.indexOf(name);
  if (i < 0 || i + 1 >= args.length || args[i + 1].startsWith('--')) throw Error('MISSING_ARGUMENT:' + name);
  return args[i + 1];
}
async function main() {
  const root = realpathSync(resolve(arg('--canonical-repo')));
  const input = resolve(arg('--input')), reportPath = resolve(arg('--report'));
  if (input.startsWith(root + '/') || reportPath.startsWith(root + '/')) throw Error('SOURCE_CHECKOUT_MUST_BE_READ_ONLY');
  const origin = git(root, 'remote', 'get-url', 'origin');
  if (!['https://github.com/Sargon17-Green/pastafari-calendar',
         'https://github.com/Sargon17-Green/pastafari-calendar.git',
         'git@github.com:Sargon17-Green/pastafari-calendar.git'].includes(origin)) throw Error('SOURCE_ORIGIN');
  if (git(root, 'rev-parse', 'HEAD') !== SOURCE) throw Error('SOURCE_HEAD');
  if (git(root, 'status', '--porcelain', '--untracked-files=all') !== '') throw Error('SOURCE_DIRTY');
  const sourceBytes = readFileSync(join(root, ORACLE_PATH));
  const gitBytes = execFileSync('git', ['-C', root, 'show', SOURCE + ':' + ORACLE_PATH]);
  if (!sourceBytes.equals(gitBytes) || hash(sourceBytes) !== ORACLE_SHA) throw Error('SCROLL_ORACLE_SOURCE_BYTES');
  const inputBytes = readFileSync(input), witnessSha = hash(inputBytes);
  const sidecar = readFileSync(input + '.sha256', 'utf8');
  assert.equal(sidecar, witnessSha + '  ' + basename(input) + '\n', 'GATE_WITNESS_DIGEST');
  const data = JSON.parse(inputBytes.toString('utf8'));
  assert.equal(data.project_id, PROJECT);
  assert.equal(data.status, 'EXTERNAL_GATE_WITNESS_QA_ONLY_NOT_PHP_PRODUCTION');
  assert.equal(data.source_commit, SOURCE);
  assert.equal(data.reference_sha256, REFERENCE_SHA);
  assert.equal(data.calculation_jdn, JDN);
  assert.equal(data.independent_scroll_oracle, 'NOT_ASSESSED_HERE');
  assert.equal(data.php_production_export, 'NOT_GENERATED_HERE');
  assert.deepEqual(data.years?.map(y => y.number), [4999, 5000, 5001]);
  assert.deepEqual(data.year5000_anchor, data.years[1]);
  const indices = new Set();
  for (const year of data.years) {
    const p = year.openGateIndex, q = year.closeGateIndex;
    if (!Number.isSafeInteger(p) || !Number.isSafeInteger(q) || q - p < 6 || q - p > 137) throw Error('YEAR_GATE_RANGE');
    for (let i = p; i <= q; i++) indices.add(i);
  }
  const sorted = [...indices].sort((a, b) => a - b);
  if (sorted.length !== 27 || sorted[0] !== -12 || sorted.at(-1) !== 14) throw Error('UNEXPECTED_GATE_WINDOW');
  const { ReferenceGateTable } = await import(pathToFileURL(join(root, ORACLE_PATH)).href);
  const oracle = new ReferenceGateTable();
  const checked = verifyExactGatePositions(data.gate_positions, sorted, i => oracle.position(i));
  for (const y of data.years) {
    if (BigInt(y.openGateDay) !== oracle.position(y.openGateIndex) ||
        BigInt(y.closeGateDay) !== oracle.position(y.closeGateIndex)) throw Error('INDEPENDENT_YEAR_BOUNDARY:' + y.number);
  }
  if (git(root, 'status', '--porcelain', '--untracked-files=all') !== '') throw Error('SOURCE_CHANGED_DURING_ORACLE');
  const report = {
    project_id: PROJECT, status: 'INDEPENDENT_SCROLL_GATES_PASS_NOT_PHP_PRODUCTION',
    source_commit: SOURCE, reference_oracle_sha256: ORACLE_SHA,
    external_gate_witness_sha256: witnessSha, calculation_jdn: JDN,
    checked_gate_positions: checked, year_boundaries: [4999, 5000, 5001],
    php_real_year_profiles: 0, stage56_accepted: false
  };
  writeFileSync(reportPath, JSON.stringify(report, null, 2) + '\n', { flag: 'wx' });
  process.stdout.write(JSON.stringify(report) + '\n');
}
if (process.argv[1] && import.meta.url === pathToFileURL(resolve(process.argv[1])).href) {
  main().catch(e => { console.error('STAGE56_INDEPENDENT_GATES_REJECTED:', e.stack || String(e)); process.exitCode = 2; });
}
