#!/usr/bin/env node
'use strict';
// QA ONLY. Compiles an instrumented COPY of the locked calendar WAT.
// The 5-field foundation tuple is a regression fixture, not an independent calendar oracle.
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const assert = require('node:assert/strict');
const root = path.resolve(__dirname, '..');
const outdir = path.join(root, 'evidence', 'wat-calendar-trace');
const sourceFile = path.join(root, 'oracle', 'normative_calendar_wide.wat');
const WAT_BLOB = '70267bb5730678f81d6138a2224d6b8d9a193eb8';
const M = (1n << 127n) - 1n;
const RADIX = 1n << 30n;
const expectedSeals = new Set([1, 10, 11, 12, 20, 21, 22, 30, 31, 32, 33]);
const hash = b => crypto.createHash('sha256').update(b).digest('hex');
const gitBlob = b => crypto.createHash('sha1').update('blob ' + b.length + '\0').update(b).digest('hex');
function fail(s) { throw Error('CALENDAR_TRACE_QA: ' + s); }
function findFunction(src, name) {
  const re = new RegExp('\\(func\\s+\\$' + name + '(?=\\s|\\))', 'g');
  const matches = [...src.matchAll(re)];
  assert.equal(matches.length, 1, 'unique function ' + name);
  let depth = 0, inString = false, escaped = false, inComment = false;
  for (let i = matches[0].index; i < src.length; i++) {
    const c = src[i];
    if (inComment) { if (c === '\n') inComment = false; continue; }
    if (inString) {
      if (escaped) escaped = false;
      else if (c === '\\') escaped = true;
      else if (c === '"') inString = false;
      continue;
    }
    if (c === ';' && src[i+1] === ';') { inComment = true; i++; continue; }
    if (c === '"') { inString = true; continue; }
    if (c === '(') depth++;
    if (c === ')' && --depth === 0) return [matches[0].index, i+1];
  }
  fail('unbalanced function ' + name);
}
function instrument(original) {
  let s = original;
  function after(name, marker, call) {
    const [start, end] = findFunction(s, name);
    const b = s.slice(start, end);
    assert.equal(b.split(marker).length, 2, 'one marker for ' + name);
    s = s.slice(0, start) + b.replace(marker, marker + '\n    ' + call) + s.slice(end);
  }
  after('year5000_wide',
    '(local.set $rank (call $choose_small_n (global.get $TMP4) (local.get $dir) (local.get $total)))',
    '(call $qa_selection (i32.const 0) (i32.const 1) (i32.const 10) (local.get $total) (global.get $TMP4) (local.get $dir) (local.get $rank))');
  for (const [name, seal] of [['next_year_wide',11], ['previous_year_wide',12]]) {
    after(name,
      '(local.set $rank (call $choose_small_n (global.get $TMP4) (local.get $dir) (local.get $countc)))',
      '(call $qa_selection (i32.const 0) (i32.const 1) (i32.const ' + seal + ') (local.get $countc) (global.get $TMP4) (local.get $dir) (local.get $rank))');
  }
  after('s_select_family',
    '(call $s_choose (global.get $s_FIRST) (local.get $direction) (local.get $familyCount) (local.get $dst))',
    '(call $qa_selection (i32.const 1) (local.get $bowl) (local.get $seal) (local.get $familyCount) (global.get $s_FIRST) (local.get $direction) (local.get $dst))');
  after('gate_gap_wide',
    '(local.set $rank (call $choose_922 (global.get $TMP4) (local.get $dir)))',
    '(call $qa_selection (i32.const 0) (i32.const 1) (i32.const 1) (i32.const 922) (global.get $TMP4) (local.get $dir) (local.get $rank))');
  const imported = '  (import "trace" "selection" (func $qa_selection (param i32 i32 i32 i32 i32 i32 i32)))\n';
  assert.ok(s.startsWith('(module\n'), 'module header');
  return s.replace('(module\n', '(module\n' + imported);
}
function getN(memory, ptr, maxLimb) {
  const v = new DataView(memory.buffer);
  if (ptr < 0 || ptr+4 > v.byteLength) fail('pointer range');
  const len = v.getUint32(ptr, true);
  if (len > maxLimb || ptr+4*(len+1) > v.byteLength) fail('integer limb bounds: ' + len);
  let n=0n;
  for (let i=len-1; i>=0; i--) {
    const d = BigInt(v.getUint32(ptr+4*(i+1), true));
    if (d >= RADIX || (i===len-1 && d===0n)) fail('noncanonical integer');
    n = n*RADIX + d;
  }
  return n;
}
function calcRank(first, step, n) {
  if (n < 1n || first < 1n || first > M || ![1,-1].includes(step)) fail('selector input domain');
  let space=M, k=1;
  while (space<n) { space*=M; k++; if(k>253) fail('k overflow'); }
  let x=1n, digit=first, weight=1n;
  for (let j=0; j<k; j++) {
    x += (digit-1n)*weight;
    digit = ((digit-1n+BigInt(step)+M)%M)+1n;
    weight *= M;
  }
  const limit=(space/n)*n;
  if (x>limit) x=step===1?1n:limit;
  return {rank:((x-1n)%n)+1n, k, limit};
}
function selfTest() {
  for (const n of [1n,2n,3n,922n,M-1n,M,M+1n,47n**47n]) {
    for (const first of [1n,2n,M-1n,M]) for(const step of [-1,1]) {
      const {rank,k}=calcRank(first,step,n);
      assert.ok(rank>=1n && rank<=n && k>=1);
    }
  }
  assert.equal(calcRank(M,-1,2n).rank, 2n);
  assert.equal(calcRank(1n,1,1n).rank, 1n);
  return 'PASS';
}
function prepare() {
  const src=fs.readFileSync(sourceFile);
  assert.equal(gitBlob(src), WAT_BLOB, 'locked calendar blob');
  const copy=instrument(src.toString('utf8'));
  fs.mkdirSync(outdir,{recursive:true});
  fs.writeFileSync(path.join(outdir,'instrumented.wat'), copy);
  fs.writeFileSync(path.join(outdir,'source.json'),JSON.stringify({
    project_id:'PC-BRANCH-WAT-SPANISH',
    original_blob:gitBlob(src), original_sha256:hash(src),
    instrumented_sha256:hash(Buffer.from(copy)), original_unchanged:true,
    type:'instrumented_copy_NOT_normative', oracle_selftest:selfTest(),
    overall_stage02_accepted:false
  },null,2)+'\n');
  console.log('PREPARE_OK original_sha256='+hash(src)+' copy_sha256='+hash(Buffer.from(copy)));
}
async function native() {
  const src=fs.readFileSync(sourceFile);
  assert.equal(gitBlob(src),WAT_BLOB,'locked calendar');
  const wasm=fs.readFileSync(path.join(outdir,'instrumented.wasm'));
  const records=[];
  const cases=[
    {name:'foundation',c:-15055671n,t:-15055671n,expected:['5000',10,949,3,54]},
    {name:'future_navigation_probe',c:-15055671n,t:-15049671n},
    {name:'past_navigation_probe',c:-15055671n,t:-15061671n}
  ];
  for(const tc of cases) {
    const events=[];
    let memory=null;
    const instance=(await WebAssembly.instantiate(wasm,{trace:{selection(kind,bowl,seal,nRaw,firstPtr,dir,rankRaw) {
      if (!memory) fail('memory callback uninitialized');
      if(!expectedSeals.has(seal)) fail('unexpected seal '+seal);
      const n = kind===1 ? getN(memory,nRaw,1100) : BigInt(nRaw>>>0);
      const first = getN(memory,firstPtr,14);
      const rank = kind===1 ? getN(memory,rankRaw,1100) : BigInt(rankRaw>>>0);
      const oracle=calcRank(first,dir,n);
      if(rank!==oracle.rank) fail('rank discrepancy bowl='+bowl+' seal='+seal+' expected='+oracle.rank+' actual='+rank);
      if (events.length>=30000) fail('trace event cap');
      events.push({bowl,seal,kind:kind===1?'big':'small',n:n.toString(),first:first.toString(),direction:dir,
        k:oracle.k,rank:rank.toString()});
    }}})).instance;
    memory=instance.exports.memory;
    assert.ok(memory instanceof WebAssembly.Memory);
    const c=instance.exports.wide_day_from_i64(tc.c);
    const t=instance.exports.wide_day_from_i64(tc.t);
    const result=instance.exports.wide_calendar_date(c,t);
    if(!Number.isInteger(result) || result<=0) fail('missing result record '+tc.name);
    const v=new DataView(memory.buffer);
    const yp=v.getUint32(result,true);
    const sign=v.getInt32(yp,true);
    // Read signed wide-year directly: sign at +0, len at +4, capacity at +8, limbs at +12.
    const len=v.getUint32(yp+4,true);
    if(len>100) fail('year limb cap');
    let year=0n;
    for(let i=len-1;i>=0;i--) year=year*RADIX+BigInt(v.getUint32(yp+12+i*4,true));
    year*=BigInt(sign);
    const fields=[
      year.toString(),
      instance.exports.wide_calendar_result_cutlet(),
      instance.exports.wide_calendar_result_day_in_cutlet(),
      instance.exports.wide_calendar_result_month(),
      instance.exports.wide_calendar_result_day_in_month()
    ];
    if(tc.expected) assert.deepEqual(fields,tc.expected,'foundation regression');
    if(!events.some(e=>e.seal===1)) fail('missing gate-gap trace');
    if(!events.some(e=>e.seal===10 || e.seal===11 || e.seal===12)) fail('missing year selection');
    for(const seal of [20,21,22,30,31,32,33])if(!events.some(e=>e.seal===seal)) fail('missing family '+seal);
    records.push({case:tc.name,calculation_day:tc.c.toString(),target_day:tc.t.toString(),
      five_fields:fields,oracle_scope:'rank independent; five fields foundation regression only',
      trace_count:events.length,observed_seals:[...new Set(events.map(e=>e.seal))].sort((a,b)=>a-b),
      events});
  }
  const result={
    project_id:'PC-BRANCH-WAT-SPANISH',source_blob:WAT_BLOB,
    qa_sha:process.env.GITHUB_SHA||'LOCAL_UNCOMMITTED',
    run_id:process.env.GITHUB_RUN_ID||null,run_attempt:process.env.GITHUB_RUN_ATTEMPT||null,
    node:process.version,wasm_sha256:hash(wasm),type:'NATIVE_INSTRUMENTED_COPY',
    independent_rank_oracle:true,independent_five_field_oracle:false,
    original_stage02_zip_manifest_verified:false,overall_stage02_accepted:false,
    cases:records
  };
  fs.writeFileSync(path.join(outdir,'native-results.json'),JSON.stringify(result,null,2)+'\n');
  console.log('TRACE_NATIVE_PASS cases='+records.length+' event_counts='+records.map(r=>r.trace_count).join(','));
}
async function main() {
  const cmd=process.argv[2];
  if(cmd==='prepare') prepare();
  else if(cmd==='native') await native();
  else if(cmd==='selftest') console.log('RANK_ORACLE_SELFTEST_'+selfTest());
  else fail('usage: node runner.cjs prepare|native|selftest');
}
main().catch(e=>{console.error(e.stack||String(e));process.exitCode=1;});