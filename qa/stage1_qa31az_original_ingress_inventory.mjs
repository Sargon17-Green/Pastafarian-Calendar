#!/usr/bin/env node
// QA31AZ: conservative original-source lexical x/p/j ingress inventory.
// Not a Funge-98 Native interpreter; unresolved directions remain UNKNOWN.
import assert from "node:assert/strict";
import {readFileSync} from "node:fs";
import {createHash} from "node:crypto";

const expectations=JSON.parse(readFileSync("qa/QA31AZ_ORIGINAL_INGRESS_EXPECTATIONS_2026-11-07.json","utf8"));
const bytes=readFileSync("src/interleaved_work_counts.b98");
const blob=createHash("sha1").update(Buffer.from("blob "+bytes.length+"\0")).update(bytes).digest("hex");
assert.equal(blob,expectations.original_git_blob);
const rows=bytes.toString("utf8").split("\n");
assert.equal(rows.length,expectations.original_rows);

function backwardCertificate(row,x){
  let demand=2,start=-1,reason="no self-contained literal suffix";
  for(let i=x-1;i>=0;i--){
    const c=row[i];if(c===" ")continue;
    if(/^[0-9a-f]$/.test(c)){if(--demand===0){start=i;break;}}
    else if(["+","-","*","/","%",String.fromCharCode(96)].includes(c))demand++;
    else if(c==="!"){}
    else {reason="dependent or control opcode "+JSON.stringify(c)+" at "+i;break;}
  }
  return start<0?{certified:false,reason}:{certified:true,start};
}
// Separate forward evaluator of the independently located postfix suffix.
function forwardEvaluate(row,start,end){
  const stack=[],pop=()=>{assert.ok(stack.length,"underflow");return stack.pop();};
  for(let i=start;i<end;i++){
    const c=row[i];if(c===" ")continue;
    if(/^[0-9a-f]$/.test(c)){stack.push(parseInt(c,16));continue;}
    if(c==="!"){stack.push(Number(pop()===0));continue;}
    const v=pop(),u=pop();
    if(c==="+")stack.push(u+v);
    else if(c==="-")stack.push(u-v);
    else if(c==="*")stack.push(u*v);
    else if(c==="/")stack.push(v?Math.trunc(u/v):0);
    else if(c==="%")stack.push(v?u%v:0);
    else if(c===String.fromCharCode(96))stack.push(Number(u>v));
    else throw Error("unknown arithmetic opcode "+c);
  }
  assert.equal(stack.length,2);
  return stack;
}
const inventory={x:[],p:[],j:[]};
for(let y=0;y<rows.length;y++)for(let x=0;x<rows[y].length;x++){
  const c=rows[y][x];
  if(c!=="x"&&c!=="p"&&c!=="j")continue;
  if(c==="j"){inventory.j.push({ip:[x,y]});continue;}
  const cert=backwardCertificate(rows[y],x);
  const o={ip:[x,y],certified:cert.certified};
  if(cert.certified){
    const values=forwardEvaluate(rows[y],cert.start,x);
    o.suffix_start_x=cert.start;o.operands=values;
    o.destination=c==="x"?[x+values[0],y+values[1]]:values;
  }else o.reason=cert.reason;
  inventory[c].push(o);
}
assert.deepEqual(inventory.j.map(v=>v.ip),expectations.j_sites);
for(const op of ["x","p"]){
  const total=inventory[op].length,certified=inventory[op].filter(v=>v.certified).length;
  assert.equal(total,expectations.counts[op].total);
  assert.equal(certified,expectations.counts[op].certified);
  assert.equal(total-certified,expectations.counts[op].unresolved);
}
assert.equal(inventory.j.length,expectations.counts.j);
const certainX=inventory.x.filter(v=>v.certified),certainP=inventory.p.filter(v=>v.certified);
const protectedRows=new Set([5,6,8,11,14,17,20,23,26,29,32,35,38,44]);
const direct=certainX.filter(v=>[14,32].includes(v.destination[1]))
  .map(v=>({source:v.ip,destination:v.destination}));
assert.deepEqual(direct,expectations.direct_certified_ingress);
for(const p of certainP)assert.ok(!protectedRows.has(p.destination[1]),
  "new constant p write into protected parser corridor "+JSON.stringify(p));
for(const x of direct){
  assert.equal(rows[x.source[1]][x.source[0]],"x");
  assert.equal(rows[x.destination[1]][x.destination[0]],">");
}
// An original-byte mutant is accepted only when its numeric target changes;
// this is a synthetic hostile test and never presented as a Native receipt.
function hostile(op,site){
  const [x,y]=site.ip,row=rows[y];
  for(let pos=site.suffix_start_x;pos<x;pos++){
    const c=row[pos];if(!/^[0-9a-f]$/.test(c))continue;
    const modified=row.slice(0,pos)+((parseInt(c,16)+1)%16).toString(16)+row.slice(pos+1);
    assert.notEqual(modified,row);
    try{
      const cert=backwardCertificate(modified,x);if(!cert.certified)continue;
      const v=forwardEvaluate(modified,cert.start,x);
      const address=op==="x"?[x+v[0],y+v[1]]:v;
      if(address.some((n,i)=>n!==site.destination[i]))
        return {op,source_ip:[x,y],mutated_byte:[pos,y],before:site.destination,after:address};
    }catch{}
  }
  throw Error("hostile source mutation failed to change target at "+x+","+y);
}
const mutants=[
  ...certainX.slice(0,12).map(v=>hostile("x",v)),
  ...certainP.slice(0,12).map(v=>hostile("p",v))
];
assert.equal(mutants.length,24);
const report={
  schema:"qa31az-original-source-conservative-ingress-v1",
  project_id:"PC-BRANCH-BEFUNGE98-KYRGYZ",
  original_source_git_blob:blob,
  original_source_rows:rows.length,
  original_source_bytes:bytes.length,
  lexical_sites:{x:inventory.x.length,p:inventory.p.length,j:inventory.j.length},
  certified_literal_only_suffixes:{x:certainX.length,p:certainP.length},
  unresolved_static_sites:{x:inventory.x.length-certainX.length,p:inventory.p.length-certainP.length},
  certified_direct_ingress_to_y14_or_y32:direct,
  certified_p_targets_on_protected_source_rows:0,
  original_j_sites:inventory.j.map(v=>v.ip),
  hostile_nonnoop_source_mutations_detected:mutants.length,
  hostile_details:mutants,
  original_source_inventory:inventory,
  original_signed_receipts_newly_replayed:0,
  new_original_native_runs:0,
  new_full_original_corpus_CI_runs:0,
  uncertified_x_destinations:"UNKNOWN",
  uncertified_p_destinations:"UNKNOWN",
  vertical_fallthrough_or_dynamic_source_ingress:"UNKNOWN",
  global_unreachability:"NOT_PROVEN",
  stage1_pass:false
};
console.log(JSON.stringify(report,null,2));
