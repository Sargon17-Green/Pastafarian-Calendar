#!/usr/bin/env node
// QA31AY: source-only, conditional, NOT a Native Funge-98 execution.
import assert from "node:assert/strict";
import {readFileSync} from "node:fs";
import {createHash} from "node:crypto";

const raw=readFileSync("src/interleaved_work_counts.b98");
const original="560d6aa5807a7f766213a33835cce85eab0fa40c";
const sha=createHash("sha1").update(Buffer.from("blob "+raw.length+"\0")).update(raw).digest("hex");
assert.equal(sha,original,"original production blob pin");
const source=raw.toString("utf8").split("\n");
assert.equal(source.length,2016);

function ray(y,values={},jOnly=false,override=null) {
  const b=values.b??0,q=values.q??0,m=values.m??0,n=values.n??0;
  const line=override??source[y],stk=[],puts=[];
  const mem=new Map([["0,49",b],["1,49",q],["2,49",n],["3,49",m]]);
  const pop=()=>stk.length?stk.pop():0;
  for(let x=10;x<line.length;x++){
    const c=line[x];
    if(c===" "||c===">")continue;
    if(c>="0"&&c<="9"){stk.push(Number(c));continue;}
    if(c>="a"&&c<="f"){stk.push(c.charCodeAt(0)-87);continue;}
    if(c===String.fromCharCode(96)){const v=pop(),u=pop();stk.push(Number(u>v));continue;}
    switch(c){
      case "+":{const v=pop(),u=pop();stk.push(u+v);break;}
      case "-":{const v=pop(),u=pop();stk.push(u-v);break;}
      case "*":{const v=pop(),u=pop();stk.push(u*v);break;}
      case "!":stk.push(Number(pop()===0));break;
      case "g":{const yy=pop(),xx=pop();stk.push(mem.get(xx+","+yy)??0);break;}
      case "p":{const yy=pop(),xx=pop(),v=pop();mem.set(xx+","+yy,v);puts.push({ip:[x,y],target:[xx,yy],value:v});break;}
      case "j":{const offset=pop();if(jOnly)return {offset,at:x};x+=offset;break;}
      case "x":{const dy=pop(),dx=pop();return {to:[x+dx,y+dy],at:x,puts,mem:Object.fromEntries(mem)};}
      case "@":return {halt:true,at:x,puts,mem:Object.fromEntries(mem)};
      default:throw Error("unsupported opcode "+JSON.stringify(c)+" at "+x+","+y);
    }
  }
  return {missingJ:true};
}
function independent(y,b,q,m) {
  if(y===8)return b>=48&&b<=57?61:0;
  if(y===17)return [9,10,13,32].includes(b)?61:0;
  if(y===20||y===29)return 61*m;
  if(y===38)return q===4?61:0;
  return q>3?61:0;
}
const gates=[8,11,17,20,23,29,32,38];
const jIPs={};
let gateTests=0;
for(const y of gates){
  for(let q=0;q<=5;q++)for(let m=0;m<=1;m++)for(let b=0;b<256;b++){
    const result=ray(y,{b,q,m},true);
    assert.equal(result.offset,independent(y,b,q,m),"original row "+y+" q"+q+" m"+m+" b"+b);
    jIPs[y]=result.at;gateTests++;
  }
}
assert.equal(gateTests,24576);
const ingress=[
  [8,{b:32},[10,17]],[8,{b:49},[10,11]],
  [11,{q:3},[10,14]],[11,{q:4},[10,44]],
  [17,{b:32},[10,20]],[17,{b:33},[10,44]],
  [20,{m:0},[10,5]],[20,{m:1},[10,23]],
  [23,{q:3},[10,26]],[23,{q:4},[10,44]],
  [29,{m:0},[10,38]],[29,{m:1},[10,32]],
  [32,{q:3},[10,35]],[32,{q:4},[10,44]]
];
for(const [y,v,to] of ingress)assert.deepEqual(ray(y,v).to,to,"original x vector "+y);
let rays=0;
for(let q=0;q<=3;q++)for(const n of [0,1,9,23])for(const b of [48,49,57]){
  const z=ray(14,{b,q,n}),v=z.mem;
  assert.deepEqual([v["1,49"],v["2,49"],v["3,49"]],[q,10*n+b-48,1]);
  assert.deepEqual(z.to,[10,5]);assert.deepEqual(z.puts.map(p=>p.ip),[[200,14],[248,14]]);
  rays++;
}
for(let q=0;q<=3;q++)for(const n of [0,1,9,23])for(let m=0;m<=1;m++){
  const z=ray(26,{q,m,n,b:32}),v=z.mem;
  assert.deepEqual([v["1,49"],v["2,49"],v["3,49"],v[String(10+q)+",49"]],[q+1,0,0,n]);
  assert.deepEqual(z.to,[10,5]);assert.deepEqual(z.puts.map(p=>p.ip),[[152,26],[248,26],[296,26],[344,26]]);
  rays++;
}
for(let q=0;q<=3;q++)for(const n of [0,1,9,23])for(let m=0;m<=1;m++){
  const z=ray(35,{q,m,n,b:32}),v=z.mem;
  assert.deepEqual([v["1,49"],v[String(10+q)+",49"]],[q+1,n]);
  assert.deepEqual(z.to,[10,38]);assert.deepEqual(z.puts.map(p=>p.ip),[[152,35],[248,35]]);
  rays++;
}
assert.equal(rays,112);
assert.equal(ray(26,{q:-9,m:1,n:12,b:32}).mem["1,49"],13,"negative q address alias");
let frontier=new Set(["0,0"]),observed=new Set(frontier),row32=new Set();
for(let i=0;i<16;i++){
  const next=new Set();
  for(const s of frontier){
    const [q,m]=s.split(",").map(Number);
    if(q<=3)next.add(q+",1");
    if(!m)next.add(s);
    else if(q<=3)next.add((q+1)+",0");
    if(m){assert.ok(q<=3,"row32 on canonical route");row32.add(s);}
  }
  for(const s of next){const [q,m]=s.split(",").map(Number);assert.ok(q<=4&&!(q===4&&m===1));observed.add(s);}
  frontier=next;
}
assert.deepEqual([...observed].sort(),["0,0","0,1","1,0","1,1","2,0","2,1","3,0","3,1","4,0"].sort());
assert.deepEqual([...row32].sort(),["0,1","1,1","2,1","3,1"].sort());
let hostile=0;
for(const y of gates){
  const witness=y===8?{b:48,q:1,m:1}:y===17?{b:9,q:1,m:1}:y===20||y===29?{b:48,q:1,m:1}:{b:48,q:4,m:1};
  const line=source[y],j=jIPs[y],g=line.indexOf("g",10);
  assert.equal(line[j],"j");assert.ok(g>=10);
  for(const at of [j,g]){
    const altered=line.slice(0,at)+"0"+line.slice(at+1);
    assert.notEqual(altered,line);
    let detected=false;
    try{detected=ray(y,witness,true,altered).offset!==independent(y,witness.b,witness.q,witness.m);}
    catch{detected=true;}
    assert.ok(detected,"hostile gate mutation "+y+" at "+at);
    hostile++;
  }
}
assert.equal(hostile,16);
console.log(JSON.stringify({
  project_id:"PC-BRANCH-BEFUNGE98-KYRGYZ",original_source_blob:original,
  source_gate_checks:gateTests,gate_j_coordinates:jIPs,
  source_x_vector_checks:ingress.length,source_ray_checks:rays,
  negative_q_alias_tests:1,canonical_transition_rounds:16,
  canonical_input_boundary_states:[...observed].sort(),
  canonical_row32_states:[...row32].sort(),
  hostile_source_mutations_detected:hostile,
  original_signed_receipts_newly_replayed:0,new_native_runs:0,
  global_alternate_ingress:"UNKNOWN",stage1_pass:false
},null,2));
