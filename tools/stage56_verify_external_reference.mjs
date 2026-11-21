#!/usr/bin/env node
/** QA only: independent Scroll reference vs pinned Python year data and fast JS runtime. */
import { readFileSync, writeFileSync } from 'node:fs';
import { createHash } from 'node:crypto';
import { resolve, join } from 'node:path';
import { pathToFileURL } from 'node:url';

const SOURCE_SHA = 'cc2cf0b422757a5e7c33218ce30cffa8f99c6786';
const PROJECT = 'PC-BRANCH-PHP-MALAY';
const args = process.argv.slice(2);
const getArg = name => {
  const at = args.indexOf(name);
  if (at < 0 || !args[at + 1]) throw Error(`Missing ${name}`);
  return args[at + 1];
};
const eq = (a, b, where) => {
  if (JSON.stringify(a) !== JSON.stringify(b)) {
    throw Error(`${where}: ${JSON.stringify(a)} != ${JSON.stringify(b)}`);
  }
};
const sha256 = bytes => createHash('sha256').update(bytes).digest('hex');
const readBoundJson = path => {
  const bytes = readFileSync(path);
  const digest = sha256(bytes);
  const sidecar = readFileSync(path + '.sha256', 'utf8').trim();
  eq(sidecar, `${digest}  ${path.split('/').at(-1)}`, `${path} checksum`);
  return { data: JSON.parse(bytes), digest };
};
const sortedObject = v => Array.isArray(v) ? v.map(sortedObject)
  : v && typeof v === 'object' ? Object.fromEntries(Object.keys(v).sort().map(k => [k, sortedObject(v[k])])) : v;
const tuple = x => ({
  year: String(x.year), cutletName: x.cutletName, dayInCutlet: Number(x.dayInCutlet),
  monthName: x.monthName, dayInMonth: Number(x.dayInMonth),
});
function sampleOffsets(record) {
  const seenFirst = new Map(), seenLast = new Map();
  record.month_weaving.forEach((m, i) => {if (!seenFirst.has(m)) seenFirst.set(m, i); seenLast.set(m, i);});
  const n = record.month_weaving.length;
  const selected = new Set([0, 1, n - 2, n - 1]);
  for (let f = 1; f < 8; f++) selected.add(Math.floor((n - 1) * f / 8));
  for (const i of seenFirst.values()) selected.add(i);
  for (const i of seenLast.values()) selected.add(i);
  return [...selected].sort((a,b) => a - b);
}
async function main() {
  const root = resolve(getArg('--canonical-repo'));
  const jdn = Number(getArg('--calculation-jdn'));
  if (!Number.isSafeInteger(jdn) || jdn !== -13334246) throw Error('Unexpected calculation context');
  const {data: external, digest: exportSha} = readBoundJson(resolve(getArg('--input')));
  const {data: python, digest: sampleSha} = readBoundJson(resolve(getArg('--python-samples')));
  if (external.project_id !== PROJECT || external.status !== 'EXTERNAL_REFERENCE_NOT_PHP_PROVIDER' ||
      external.source?.kind !== 'external_canonical_reference' || external.source.source_commit !== SOURCE_SHA ||
      external.calculation_jdn !== jdn || python.status !== 'EXTERNAL_PYTHON_QA_ONLY' ||
      python.project_id !== PROJECT || python.source_commit !== SOURCE_SHA || python.calculation_jdn !== jdn) {
    throw Error('Wrong provenance or calculation context');
  }
  const anchorSha = sha256(Buffer.from(JSON.stringify(sortedObject(external.year5000_anchor)) + '\n'));
  eq(anchorSha, external.source.anchor_sha256, 'anchor hash');
  const oracle = await import(pathToFileURL(join(root, 'verification/reference-oracle/reference.mjs')).href);
  const fast = await import(pathToFileURL(join(root, 'browser/pastafari-calendar-fast.js')).href);
  const reference = new oracle.ReferenceCalendar(BigInt(jdn));
  const js = new fast.PastafariCalendar();
  const anchor = reference.years.get('5000');
  const referenceYears = [reference.previousYear(anchor), anchor, reference.nextYear(anchor)];
  eq(external.years.map(x => x.number), [4999,5000,5001], 'year sequence');
  eq(external.year5000_anchor.open_gate_day, Number(anchor.startJdn - 1n), 'anchor opening gate');
  eq(external.year5000_anchor.open_gate_index, Number(anchor.openGateIndex), 'anchor gate index');
  eq(external.year5000_anchor.close_gate_index, Number(anchor.closeGateIndex), 'anchor closing gate index');
  let tested = 0;
  const details = [];
  for (let i = 0; i < 3; i++) {
    const record = external.years[i], year = referenceYears[i];
    const structure = reference.structure(year);
    eq(record.number, Number(year.number), `year ${i} number`);
    eq(record.open_gate_day, Number(year.startJdn - 1n), `year ${i} opening`);
    eq(record.close_gate_day, Number(year.endJdn), `year ${i} closing`);
    eq(record.month_lengths, structure.monthLengths, `year ${i} independent month lengths`);
    eq(record.month_weaving, structure.monthWeave.map(x => x + 1), `year ${i} independent complete month weaving`);
    const indices = sampleOffsets(record);
    const samples = python.years[i];
    eq(samples.year, record.number, `year ${i} python label`);
    eq(samples.samples.length, indices.length, `year ${i} Python sample count`);
    for (let k = 0; k < indices.length; k++) {
      const target = year.startJdn + BigInt(indices[k]);
      eq(samples.samples[k].jdn, Number(target), `year ${i} sample JDN`);
      const expected = tuple(reference.convertJdn(target));
      eq(samples.samples[k].tuple, expected, `year ${i} Python vs Scroll oracle JDN=${target}`);
      eq(tuple(js.convertJdn(target, {calculationJdn: BigInt(jdn)}).toJSON()), expected,
        `year ${i} JS runtime vs Scroll oracle JDN=${target}`);
      tested++;
    }
    details.push({year: record.number, days: record.month_weaving.length, months: record.month_lengths.length,
                  checked_tuples: indices.length, complete_month_weave_equal: true});
  }
  const report = {project_id: PROJECT, status: 'EXTERNAL_SEMANTIC_DIFFERENTIAL_PASS_NOT_PHP_B5',
    source_commit: SOURCE_SHA, calculation_jdn: jdn, reference_sha256: exportSha,
    python_samples_sha256: sampleSha, checked_tuples: tested, years: details,
    scope: 'External Python structure/tuples vs independent Scroll oracle vs authoritative fast JS; NOT PHP production provider'};
  writeFileSync(resolve(getArg('--report')), JSON.stringify(report, null, 2) + '\n');
  console.log(JSON.stringify(report));
}
main().catch(e => {console.error('STAGE56_EXTERNAL_DIFFERENTIAL_FAILED:', e.stack || String(e)); process.exitCode = 1;});
