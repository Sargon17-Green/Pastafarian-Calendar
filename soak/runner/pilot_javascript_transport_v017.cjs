#!/usr/bin/env node
'use strict';
// Pinned JavaScript/Interlingue F(c,t) transport. This wrapper never calculates
// calendar fields: it only invokes the original exported calendarDate(BigInt,BigInt)
// and converts its native name strings with the pinned source-language catalog.
// Use only under admitted Windows resource governance. Evidence files are write-once.
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');

const LOCK = path.resolve(__dirname, '..', 'control', 'pilot_two_engine_source_locks_v001.json');
const DECIMAL = /^(?:0|-?[1-9][0-9]*)$/;
const DIGEST = /^[0-9a-f]{64}$/;

function parseArgs(argv) {
  const args = {};
  const flags = new Set(['check-only', 'allow-whole-year']);
  for (let i = 0; i < argv.length; i++) {
    const token = argv[i];
    if (!token.startsWith('--')) throw Error('unexpected positional argument');
    const name = token.slice(2);
    if (Object.hasOwn(args, name)) throw Error('duplicate flag');
    if (flags.has(name)) args[name] = true;
    else {
      if (i + 1 >= argv.length || argv[i + 1].startsWith('--')) throw Error('missing flag value: ' + name);
      args[name] = argv[++i];
    }
  }
  const allowed = new Set(['sources-root', 'check-only', 'calculation-day',
    'first-target-day', 'last-target-day', 'raw-out', 'normalized-out',
    'receipt-out', 'allow-whole-year', 'boundary-evidence-sha256']);
  for (const key of Object.keys(args)) if (!allowed.has(key)) throw Error('unknown flag: ' + key);
  if (!args['sources-root']) throw Error('sources-root required');
  return args;
}

function exactDay(value) {
  if (typeof value !== 'string' || !DECIMAL.test(value)) throw Error('noncanonical signed decimal input');
  return BigInt(value);
}

function hash(data) {
  return crypto.createHash('sha256').update(data).digest('hex');
}

function gitBlob(data) {
  return crypto.createHash('sha1')
    .update(Buffer.from('blob ' + data.length + '\0', 'ascii'))
    .update(data).digest('hex');
}

function loadSource(root) {
  const manifest = JSON.parse(fs.readFileSync(LOCK, 'utf8'));
  if (manifest.schema !== 'PASTAFARI_SOAK_PILOT_SOURCE_LOCK/1' || manifest.main_changes_permitted)
    throw Error('invalid source lock');
  const engine = manifest.engines.find(e => e.id === 'REF-24');
  if (!engine || engine.language !== 'JavaScript' || engine.sources.length !== 2)
    throw Error('unexpected JS source closure');
  const files = new Map();
  for (const item of engine.sources) {
    if (path.isAbsolute(item.path) || item.path.split('/').includes('..')) throw Error('unsafe source path');
    const file = path.join(root, 'JavaScript-Interlingue', engine.commit, item.path);
    const data = fs.readFileSync(file);
    if (data.length !== item.bytes || hash(data) !== item.sha256 || gitBlob(data) !== item.git_blob_sha1)
      throw Error('pinned JavaScript source identity mismatch: ' + item.path);
    files.set(item.path, file);
  }
  const engineFile = files.get('tests/normative-reference.js');
  const catalogFile = files.get('src/source-language-catalog.js');
  if (!engineFile || !catalogFile) throw Error('missing original source dependency');
  const native = require(engineFile);
  const lang = require(catalogFile);
  if (typeof native.calendarDate !== 'function') throw Error('original calendarDate not exported');
  if (!lang.SourceLanguageCatalog || lang.SourceLanguageCatalog !== native.SourceLanguageCatalog)
    throw Error('source catalog identity is not preserved');
  function indexFromNative(group, name) {
    const rows = group === 'cutlet' ? lang.SourceLanguageCatalog.cutlets :
      group === 'month' ? lang.SourceLanguageCatalog.months : null;
    const size = group === 'cutlet' ? 17 : 47;
    if (!rows || rows.length !== size || typeof name !== 'string' || !name) throw Error('invalid native name');
    if (new Set(rows.map(x => x.text)).size !== rows.length ||
        rows.some((x, i) => x.canonicalIndex !== i + 1))
      throw Error('original catalog contains duplicate or noncanonical indices');
    const matched = rows.find(x => x.text === name);
    if (!matched) throw Error('native name missing from pinned catalog: ' + group);
    return matched.canonicalIndex;
  }
  return { engine, native, indexFromNative };
}

function produce(entry, c, t) {
  const tuple = entry.native.calendarDate(c, t); // Original calendar computation only.
  if (!Array.isArray(tuple) || tuple.length !== 5 ||
      typeof tuple[0] !== 'bigint' || typeof tuple[1] !== 'string' ||
      typeof tuple[2] !== 'bigint' || typeof tuple[3] !== 'string' ||
      typeof tuple[4] !== 'bigint') throw Error('unexpected native date tuple');
  const [year, cutletName, cutletDay, monthName, monthDay] = tuple;
  const ci = entry.indexFromNative('cutlet', cutletName);
  const mi = entry.indexFromNative('month', monthName);
  for (const number of [cutletDay, monthDay]) {
    if (number < 1n || number > BigInt(Number.MAX_SAFE_INTEGER)) throw Error('invalid native day ordinal');
  }
  const raw = {
    calculation_day: c.toString(), target_day: t.toString(),
    native_tuple: [year.toString(), cutletName, cutletDay.toString(),
                   monthName, monthDay.toString()]
  };
  const rawLine = Buffer.from(JSON.stringify(raw) + '\n', 'utf8');
  const norm = {
    calculation_day: c.toString(), target_day: t.toString(),
    year: year.toString(), cutlet_index: ci, day_in_cutlet: Number(cutletDay),
    month_index: mi, day_in_month: Number(monthDay),
    cutlet_name_raw: cutletName, month_name_raw: monthName,
    source_raw_sha256: hash(rawLine)
  };
  const normLine = Buffer.from(JSON.stringify(norm) + '\n', 'utf8');
  return [rawLine, normLine];
}

function main() {
  const args = parseArgs(process.argv.slice(2));
  const entry = loadSource(path.resolve(args['sources-root']));
  if (args['check-only']) {
    console.log(JSON.stringify({status: 'SOURCE_AND_TRANSPORT_PREFLIGHT_ONLY',
      engine: entry.engine.id, sha256: entry.engine.sources.map(x => x.sha256),
      converter_calls: 0}));
    return;
  }
  if (process.env.PASTAFARI_SOAK_RESOURCE_ADMITTED !== '1')
    throw Error('Windows resource admission not confirmed by scheduler');
  const c = exactDay(args['calculation-day']);
  const first = exactDay(args['first-target-day']);
  const last = exactDay(args['last-target-day']);
  if (first > last) throw Error('inverted target range');
  if (first !== last && (!args['allow-whole-year'] ||
      typeof args['boundary-evidence-sha256'] !== 'string' ||
      !DIGEST.test(args['boundary-evidence-sha256'])))
    throw Error('multi-day range requires independently pinned year boundaries');
  if (first !== last && last - first + 1n > 5778n) throw Error('range exceeds normative year maximum');
  const outputs = [args['raw-out'], args['normalized-out'], args['receipt-out']];
  if (outputs.some(x => !x) || new Set(outputs.map(x => path.resolve(x))).size !== 3)
    throw Error('three unique output paths required');
  if (outputs.some(x => fs.existsSync(x))) throw Error('refusing to overwrite evidence');
  const rawFd = fs.openSync(outputs[0], 'wx');
  let normFd;
  try { normFd = fs.openSync(outputs[1], 'wx'); }
  catch (error) { fs.closeSync(rawFd); throw error; }
  const rh = crypto.createHash('sha256');
  const nh = crypto.createHash('sha256');
  let count = 0;
  try {
    for (let t = first; t <= last; t += 1n) {
      const [rawLine, normLine] = produce(entry, c, t);
      fs.writeSync(rawFd, rawLine);
      fs.writeSync(normFd, normLine);
      rh.update(rawLine);
      nh.update(normLine);
      count++;
      console.log('PILOT_NATIVE_DAY_WRITTEN engine=REF-24 day=' + t.toString() + ' rows=' + count);
    }
    fs.fsyncSync(rawFd);
    fs.fsyncSync(normFd);
  } finally {
    fs.closeSync(rawFd);
    fs.closeSync(normFd);
  }
  const receipt = {
    status: 'NATIVE_TRANSPORT_OUTPUT_COMPLETE_NOT_COMPARED',
    engine: entry.engine.id, source_commit: entry.engine.commit,
    source_sha256: entry.engine.sources.map(x => x.sha256),
    calculation_day: c.toString(),
    first_target_day: first.toString(), last_target_day: last.toString(),
    rows: count, raw_stream_sha256: rh.digest('hex'),
    normalized_stream_sha256: nh.digest('hex'),
    boundary_evidence_sha256: args['boundary-evidence-sha256'] || null,
    verified_comparisons_completed: 0
  };
  fs.writeFileSync(outputs[2], JSON.stringify(receipt, null, 2) + '\n',
    {flag: 'wx', encoding: 'utf8'});
  console.log(JSON.stringify(receipt));
}

try { main(); }
catch (error) {
  console.error('PILOT_TRANSPORT_BLOCKED type=' + error.name + ' message=' + error.message);
  process.exitCode = 2;
}
