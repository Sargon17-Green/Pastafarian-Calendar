#!/usr/bin/env node
"use strict";
// QA-only: multi-intervention algebra and independent pinned reference replay.
// Parent 9592ea10ae61bc36f959dff3010b6c49ae212b2a; candidate blob 7418e1ec5fe88fe5c14b75710dea2d5607527f28.
// QA31CU/CV/CW scoped evidence retained. No Native or production execution.
// For opposite input signs, a selected nonzero weighted digit at highest
// place h dominates all lower digits: 10^h > 9*(10^h-1)/9.
// Therefore exact cancellation of nonzero distinct iterations is impossible;
// use partial cancellation, net sign reversal, and multiple zero shams.
// NEXT: Native 4 healthy + 8 multi-force cases on fresh, exact pinned source;
// require all physical writes/fetches/arms/joins, exact intervention set,
// reference first five fields and unchanged two SAVE outputs, bounded runtime.
const fs=require("fs"),crypto=require("crypto");
function audit(source) {
  const need=(b,m)=>{if(!b)throw Error(m)};
  const cases=[
    ["opposed_near",0,21008,1,10979,[-1,-70,-900,1000,10000]],
    ["opposed_mirror",1,21008,0,10979,[1,70,900,-1000,-10000]],
    ["two_zero_digits",0,50204,1,49804,[0,0,-600,-9000,10000]],
    ["two_zero_mirror",1,50204,0,49804,[0,0,600,9000,-10000]]
  ];
  // Restricted, fail-closed interpreter of the pinned, straight-line reference.
  // No production interpreter or physical execution claims.
  function ref(c,t){
    const input=[c<0n?1n:0n,c<0n?-c:c,t<0n?1n:0n,t<0n?-t:t], stack=[],mem=new Map(),out=[];
    const pop=()=>{need(stack.length>0,"reference stack underflow");return stack.pop()};
    let k=0, halted=false;
    for(const op of source.trimEnd()){
      need(!halted,"trailing code");
      if(/^[0-9a-f]$/.test(op)){stack.push(BigInt(parseInt(op,16)));continue}
      if(op==="&"){need(k<input.length,"extra input");stack.push(input[k++]);continue}
      if(op===":"){const a=pop();stack.push(a,a);continue}
      if(op==="\\"){const b=pop(),a=pop();stack.push(b,a);continue}
      if(op==="!"){stack.push(pop()===0n?1n:0n);continue}
      if(op==="p"){const y=pop(),x=pop(),v=pop();need(y===20n,"unexpected reference write row");mem.set(`${x},${y}`,v);continue}
      if(op==="g"){const y=pop(),x=pop(),key=`${x},${y}`;need(mem.has(key),"uninitialized reference read");stack.push(mem.get(key));continue}
      if(op==="."){out.push(pop());continue}
      if(op==="@"){halted=true;continue}
      if("+-*`".includes(op)){const b=pop(),a=pop();stack.push(op==="+"?a+b:op==="-"?a-b:op==="*"?a*b:a>b?1n:0n);continue}
      throw Error("unsupported reference opcode "+op);
    }
    need(halted&&k===4&&out.length===5&&stack.length===0,"reference completion shape");
    return out;
  }
  const results=[];let comparisons=0,zeroOnly=0,multi=0,netSignFlip=0,nearCancel=0,nonzeroExactCancel=0;
  for(const [label,sc,mc,st,mt,literal] of cases){
    const C=BigInt((1-2*sc)*mc),T=BigInt((1-2*st)*mt);
    const z=Array.from({length:5},(_,i)=>BigInt((1-2*sc)*Number(String(mc).padStart(5,"0")[4-i])+(1-2*st)*Number(String(mt).padStart(5,"0")[4-i]))*10n**BigInt(i));
    need(z.every((v,i)=>v===BigInt(literal[i]))&&z.reduce((a,b)=>a+b,0n)===C+T,"literal or whole sum mismatch");
    const base=ref(C,T);
    for(let mask=0;mask<32;mask++){
      const ids=z.map((_,i)=>i).filter(i=>(mask>>i)&1),Z=ids.reduce((s,i)=>s+z[i],0n);
      let S=0n;const joins=z.map((v,i)=>{S+=ids.includes(i)?-v:v;return S});
      need(S===C+T-2n*Z,"join/whole sum mismatch");
      const alt=ref(C-Z,T-Z), delta=alt.map((v,i)=>v-base[i]);
      const want=[-2n*Z,-2n*Z,0n,-4n*Z,0n];
      need(delta.every((v,i)=>v===want[i]),"reference delta mismatch");
      const nonzero=ids.filter(i=>z[i]!==0n);
      if(nonzero.length===0)zeroOnly++;
      if(ids.length>=2)multi++;
      if(nonzero.length&&Z===0n)nonzeroExactCancel++;
      if((C+T)*S<0n)netSignFlip++;
      if(nonzero.length>=2&&nonzero.some(i=>z[i]>0n)&&nonzero.some(i=>z[i]<0n)&& (Z<0n?-Z:Z)<nonzero.reduce((s,i)=>s+(z[i]<0n?-z[i]:z[i]),0n))nearCancel++;
      comparisons++;
      results.push({label,mask,indices:ids,z:z.map(String),Z:String(Z),joins:joins.map(String),alternate:[String(C-Z),String(T-Z)],reference:alt.map(String),delta:delta.map(String)});
    }
  }
  need(comparisons===128&&multi===104&&nonzeroExactCancel===0,"coverage counts");
  // Exhaustively check the highest-place dominance lower bound for every
  // possible highest digit and five-digit mixed-sign lower-digit envelope.
  let dominance=0;
  for(let h=0;h<5;h++)for(let d=1;d<=9;d++){
    const w=10n**BigInt(h);need(BigInt(d)*w-(w-1n)>=1n,"dominance");dominance++;
  }
  return {status:"OFFLINE_REFERENCE_ONLY",comparisons,multi,zeroOnly,netSignFlip,nearCancel,nonzeroExactCancel,dominance,results};
}
const raw=fs.readFileSync(process.argv[2]||"reference/work_counts.b98");
const blob=crypto.createHash("sha1").update(Buffer.from("blob "+raw.length+"\0")).update(raw).digest("hex");
if(blob!=="f941efc793c9eee4accf5d03873f8ed029b16725")throw Error("reference blob mismatch");
const receipt=audit(raw.toString("utf8"));
console.log(JSON.stringify(receipt,null,2));
/* Executed bounded independent audit 2026-11-27:
{"status":"OFFLINE_REFERENCE_ONLY","comparisons":128,"multi":104,"zeroOnly":10,"netSignFlip":64,"nearCancel":66,"nonzeroExactCancel":0,"dominance":45}
*/
