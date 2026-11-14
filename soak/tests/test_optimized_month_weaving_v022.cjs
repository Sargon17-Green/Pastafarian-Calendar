'use strict';
const assert = require('node:assert/strict');
const {makeFastMonthWeavingFamily}=require('../experiments/optimized_month_weaving_v022.cjs');
const reference=process.env.PINNED_JS_REFERENCE ? require(require('node:path').resolve(process.env.PINNED_JS_REFERENCE)) : null;
// Deliberately independent exhaustive enumerator for small legal profiles.
function brute(lengths){
 const out=[],remaining=lengths.slice(),m=lengths.length,days=lengths.reduce((a,b)=>a+b,0);
 function visit(prefix,opened,closed){
  if(prefix.length===days){out.push(prefix.join(','));return;}
  for(let i=0;i<m;i++){
   if(remaining[i]===0)continue;
   if(remaining[i]===lengths[i]&&i!==opened)continue;
   if(remaining[i]===1&&i!==closed)continue;
   if(i>opened)continue;
   const first=remaining[i]===lengths[i],last=remaining[i]===1;
   remaining[i]--;
   visit([...prefix,i+1],opened+(first?1:0),closed+(last?1:0));
   remaining[i]++;
  }
 }
 visit([],0,0);return out;
}
let cases=0,rankTests=0;
for(let m=1;m<=4;m++){
 const v=Array(m).fill(1);
 function enumerate(i){
   if(i===m){
     const expected=brute(v);
     if(expected.length>60000)return;
     const family=makeFastMonthWeavingFamily(v);
     assert.equal(family.count(),BigInt(expected.length),`count ${v}`);
     if(reference){
       const original=reference.makeMonthWeavingFamily(v);
       assert.equal(original.count(),BigInt(expected.length),"original count mismatch "+v);
       for(const k of new Set([1,Math.floor((expected.length+1)/2),expected.length])){
         assert.equal(original.unrank1(BigInt(k)).join(','),expected[k-1],"original rank mismatch "+v+" at "+k);
       }
     }
     for(let k=0;k<expected.length;k++){
       const got=family.unrank1(BigInt(k+1)).join(',');
       assert.equal(got,expected[k],`rank=${k+1} lengths=${v}`);rankTests++;
     }
     assert.throws(()=>family.unrank1(0n),RangeError);
     assert.throws(()=>family.unrank1(BigInt(expected.length)+1n),RangeError);
     cases++;return;
   }
   for(let x=1;x<=4;x++){v[i]=x;enumerate(i+1);}
 }
 enumerate(0);
}
const large=Array.from({length:37},(_,i)=>i%7+89);
const start=process.hrtime.bigint(),f=makeFastMonthWeavingFamily(large);
const n=f.count(),days=large.reduce((a,b)=>a+b,0);
const mid=(n+1n)/2n;
const w=f.unrank1(mid);
assert.equal(w.length,days);
for(let i=0;i<large.length;i++)assert.equal(w.filter(x=>x===i+1).length,large[i]);
console.log(JSON.stringify({
 status:'FAST_WEAVING_SMALL_EXHAUSTIVE_PASS',
 exhaustive_cases:cases,ranks_compared:rankTests,
 large_months:large.length,large_days:days,bigint_rank_digits:n.toString().length,
 table_cells:f.debugTableCells(),
 large_duration_ms:Number(process.hrtime.bigint()-start)/1e6,
 memory_rss_mib:process.memoryUsage().rss/2**20
}));
