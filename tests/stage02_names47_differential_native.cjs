#!/usr/bin/env node
/* Check externally supplied SHA-locked WAT instrumented WASM against independently derived JSON vectors. */
'use strict';
const fs=require('node:fs');
const crypto=require('node:crypto');
const assert=require('node:assert/strict');
if(process.argv.length !== 4) {
  console.error('USAGE: node stage02_names47_differential_native.cjs instrumented.wasm differential-vectors.json');
  process.exit(64);
}
const wasm=fs.readFileSync(process.argv[2]);
const bytesHash=crypto.createHash('sha256').update(wasm).digest('hex');
const EXPECTED_WASM_SHA='fa579a0a8d6e2d35ec4b0cad44688f4f3122bb2759e9a068c6af95343590a202';
assert.equal(bytesHash,EXPECTED_WASM_SHA,'source-fresh wasm mismatch');
const vectors=JSON.parse(fs.readFileSync(process.argv[3],'utf8'));
assert.equal(vectors.project,'PC-BRANCH-WAT-SPANISH');
const RADIX=1n<<30n;
function put(view,addr,n) {
  const digits=[];
  while(n!==0n) {digits.push(Number(n%RADIX)); n/=RADIX;}
  if(digits.length===0)digits.push(0);
  assert.ok(digits.length<=1100,'capacity');
  view.setUint32(addr,digits.length,true);
  digits.forEach((d,i)=>view.setUint32(addr+4*(i+1),d,true));
}
function get(view,addr) {
  const size=view.getUint32(addr,true);
  assert.ok(size>0 && size<=1100,'length');
  let total=0n;
  for(let i=size-1;i>=0;i--) {
    const digit=view.getUint32(addr+4*(i+1),true);
    assert.ok(digit<2**30,'base overflow');
    if(i===size-1 && size>1) assert.notEqual(digit,0,'leading zero');
    total=total*RADIX+BigInt(digit);
  }
  return total;
}
(async()=>{
  let passed=0;
  const results=[];
  for(const v of vectors.cases) {
    const module=await WebAssembly.instantiate(wasm,{});
    const exports=module.instance.exports;
    const memory=exports.memory;
    assert.equal(memory.buffer.byteLength,96*65536);
    const view=new DataView(memory.buffer);
    const input=BigInt(v.n);
    put(view,83200,input);
    const operation=exports['qa_names47_'+v.mode];
    assert.equal(typeof operation,'function');
    operation();
    const rank=get(view,145024);
    assert.equal(get(view,83200),input,'N mutated');
    assert.equal(rank,BigInt(v.expected_rank),`${v.case}/${v.mode} rank`);
    assert.equal(crypto.createHash('sha256').update(String(rank)).digest('hex'),v.expected_sha256,`${v.case}/${v.mode} sha256`);
    results.push({case:v.case,mode:v.mode,k:v.k,status:'PASS',reject:v.expected_rejection});
    passed++;
  }
  console.log(JSON.stringify({project:vectors.project,wasm_sha256:bytesHash,total:vectors.cases.length,passed,failed:0,cases:results},null,2));
})().catch(e=>{console.error(e.stack);process.exitCode=1;});
