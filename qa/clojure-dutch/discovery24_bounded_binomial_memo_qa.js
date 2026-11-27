#!/usr/bin/env node
/* DISCOVERY24 QA-only, source predecessor 1852955ede3f433075f78b4393c5ad35397339e4.
Exact (n,min(k,n-k)) LRU of 4096 entries layered over prior single-k ratio cache.
Cold start per trace, no reuse across ranks. A binomial value is at most 2^n, for 0<k<n strictly less; payload bound S bits per cached value for S>=1 (excludes keys, BigInt object/Map overhead, temporary integers and suffix/tail caches). Insertion may transiently hold one extra entry before eviction. No JVM heap bound.
Selected arithmetic upper = 3*coldBinUpperBound + 2*weightSteps + 5*writes + 3*rows + binCalls + queries; conservative for the selected row arithmetic and exact-bin recurrence categories only, NOT total work, bit complexity or runtime. Row weight recurrence counted separately; shared billing unchanged, so no budget proof. A cache hit cannot waive the fixed group charge: for the same visited groups, sum(1+(m-o-kind)*remaining) is invariant. Structural skipping of entire groups would require independent proof under the existing contract, not established here.
Independent brute-force small oracle inherited from QA predecessor; canonical exact input from job 140363223107, run 45956230947, source 785c57411f544ea331e208a0272def0234dbb104. Previous single-k iterations p81/82/520: 1126072/1159406/13338729. No production changes or native execution. */
function audit(data, memoLimit=4096){
 const CAP=5000000,LIMIT=2048;
 function trace(profile,rank,target){
  const m=profile.length,S=profile.reduce((a,b)=>a+b,0),sc=new Map(),tc=new Map(),bc=new Map(),memo=new Map(); let memoHits=0,memoEvictions=0,peakMemo=0;
  let queries=0,rows=0,writes=0,shared=0,groups=0,candidates=0,oldBin=0,newBin=0,binCalls=0,ratioCalls=0,hits=0,allocated=0,oldSlots=0,tailMiss=0,weightSteps=0;const snaps=[];
  function cache(map,key,f){if(map.has(key)){const v=map.get(key);map.delete(key);map.set(key,v);return v}const v=f();map.set(key,v);if(map.size>LIMIT)map.delete(map.keys().next().value);return v}
  function exactBin(n,k){
   oldBin+=k;binCalls++;
   const kk=Math.min(k,n-k),key=n+':'+kk,prev=bc.get(kk);let x;if(memo.has(key)){x=memo.get(key);memo.delete(key);memo.set(key,x);bc.set(kk,{n,x});memoHits++;return x;}
   if(prev&&Math.abs(n-prev.n)<=kk){
    x=prev.x;let j=prev.n;ratioCalls++;
    if(j===n)hits++;
    while(j<n){j++;const num=x*BigInt(j),den=BigInt(j-kk);if(num%den!==0n)throw Error("nonexact up");x=num/den;newBin++}
    while(j>n){const num=x*BigInt(j-kk),den=BigInt(j);if(num%den!==0n)throw Error("nonexact down");x=num/den;j--;newBin++}
   }else{x=1n;for(let j=1;j<=kk;j++){const num=x*BigInt(n-kk+j),den=BigInt(j);if(num%den!==0n)throw Error("nonexact direct");x=num/den;newBin++}}
   bc.set(kk,{n,x});if(memoLimit){memo.set(key,x);if(memo.size>memoLimit){memo.delete(memo.keys().next().value);memoEvictions++;}peakMemo=Math.max(peakMemo,memo.size);}return x;
  }
  function tail(n,future,first){
   return cache(tc,JSON.stringify([n,future,first]),()=>{
    if(!future.length)return 1n;
    const size=n+future.reduce((a,b)=>a+b,0)+1;
    const dp=Array(size).fill(0n);allocated+=size;tailMiss++;
    let total=1n,step=0;
    for(const k of future){
     rows++;writes+=n+1;oldSlots+=2*(n+k+1);if(k>=2)weightSteps+=n;
     let prefix=total,subtotal=0n,weight=1n;
     const constrained=first||step>0;
     for(let a=n;a>=0;a--){
      const t=n-a;
      if(k>=2&&t>0)weight=weight*BigInt(t+k-2)/BigInt(t);
      const ways=k>=2?weight:(t===0?1n:0n),old=dp[a];
      const factor=step===0?(constrained?(a>0?1n:0n):total):(constrained?prefix:total);
      const value=factor*ways;dp[a+1]=value;subtotal+=value;
      if(step>0&&constrained)prefix-=old;
     }
     dp[0]=0n;total=subtotal;n+=k;step++;
    }return total;
   })
  }
  function suffix(c,o,z){queries++;return cache(sc,JSON.stringify([c,o,z]),()=>{
   if(z===m)return 1n;
   if(o===z)return tail(c[z],c.slice(z+1),true);
   let active=c[z],base=1n;
   for(let i=z+1;i<o;i++){active+=c[i];base*=exactBin(active-1,c[i]-1)}
   return base*tail(active,c.slice(o),false)
  })}
  function moves(c,o,z){const a=[];for(let i=0;i<Math.min(m,o+1);i++){if(!c[i]||(c[i]===1&&i!==z))continue;const d=c.slice();d[i]--;a.push([i+1,d,Math.max(o,i+1),z+(c[i]===1?1:0)])}return a}
  const total=suffix(profile,0,0);if(rank<1n||rank>total)throw Error("rank");
  let [f,c,o,z]=moves(profile,0,0)[0],prefix=[f];
  function snap(){if(newBin>oldBin||bc.size>S+1)throw Error("cold bound");snaps.push({p:prefix.length,queries,rows,writes,shared,groups,candidates,oldBin,newBin,binCalls,ratioCalls,hits,cacheEntries:bc.size,memoHits,memoEvictions,peakMemo,memoValueBitsUpper:peakMemo*S,allocated,oldSlots,tailMiss,weightSteps,month:prefix[prefix.length-1],day:prefix.filter(x=>x===prefix[prefix.length-1]).length,prefix:prefix.slice(),coldBinUpperBound:(1+(prefix.length-1)*m)*S})}
  snap();
  while(prefix.length<target){
   const all=moves(c,o,z),remaining=c.reduce((a,b)=>a+b,0);let chosen=null;
   for(const kind of [0,1]){const group=all.filter(x=>kind===0?x[0]<=o:x[0]===o+1);if(!group.length)continue;groups++;shared+=1+(m-o-kind)*remaining;for(const x of group){candidates++;const block=suffix(x[1],x[2],x[3]);if(rank>block)rank-=block;else{chosen=x;break}}if(chosen)break}
   if(!chosen)throw Error("candidate");prefix.push(chosen[0]);[c,o,z]=chosen.slice(1);snap()
  }return {total,snaps}
 }
 function brute(profile){let out=[],rem=profile.slice(),w=[],S=profile.reduce((a,b)=>a+b,0);function visit(){if(w.length===S){const f=profile.map((_,i)=>w.indexOf(i+1)),l=profile.map((_,i)=>w.lastIndexOf(i+1));if(f.every((x,i)=>!i||x>f[i-1])&&l.every((x,i)=>!i||x>l[i-1]))out.push(w.slice());return}for(let i=0;i<rem.length;i++)if(rem[i]){rem[i]--;w.push(i+1);visit();w.pop();rem[i]++}}visit();return out}
 let words=0,checks=0;
 for(const p of [[2,2],[2,3],[3,2],[2,2,2],[2,3,2],[3,2,2],[2,2,2,2],[4,4]]){const w=brute(p);words+=w.length;for(let i=0;i<w.length;i++){const t=trace(p,BigInt(i+1),w[i].length);if(t.total!==BigInt(w.length))throw Error("total");for(const s of t.snaps){if(s.prefix.join()!==w[i].slice(0,s.p).join())throw Error("prefix");checks++}}}
 if(data.project_id!=="PC-BRANCH-CLOJURE-DUTCH"||data.source_sha!=="785c57411f544ea331e208a0272def0234dbb104"||data.production_rank_matches_normative!==true||data.production_profile_matches_normative!==true||data.production_year_matches_normative!==true||data.weaving_rank!==data.production_weaving_rank)throw Error("lock");
 const t=trace(data.profile.map(Number),BigInt(data.weaving_rank),520);if(t.total!==BigInt(data.weaving_total))throw Error("canonical total");
 const expected={81:[3500995,4995675,2789579,7318550,20,4],82:[3507625,5002652,2852220,7332258,20,5],520:[3713186,5218257,25890841,7757708,10,18]};
 const canonical=[81,82,520].map(p=>{const s=t.snaps[p-1];if([s.writes,s.shared,s.oldBin,s.oldSlots,s.month,s.day].join()!==expected[p].join())throw Error("canonical mismatch "+p);const {prefix,...rest}=s;return {...rest,arraySlotLowerBound:s.allocated+s.writes+s.rows,selectedArithmeticUpper:3*s.coldBinUpperBound+2*s.weightSteps+5*s.writes+3*s.rows+s.binCalls+s.queries,sharedWithinCap:s.shared<=CAP}});
 return {status:"PASS_QA_BOUNDED_MEMO_ONLY",small:{profiles:8,words,checks},canonical,productionChanged:false,stage2:"OPEN"}
}

const fs=require('node:fs');if(process.argv.length!==3){console.error('usage: node discovery24_bounded_binomial_memo_qa.js canonical-input.json');process.exit(2)}console.log(JSON.stringify(audit(JSON.parse(fs.readFileSync(process.argv[2],'utf8'))),null,2));
/* Observed JS sandbox result (not Native):
{
  "status": "PASS_QA_BOUNDED_MEMO_ONLY",
  "small": {
    "profiles": 8,
    "words": 67,
    "checks": 480
  },
  "canonical": [
    {
      "p": 81,
      "queries": 1174,
      "rows": 1440,
      "writes": 3500995,
      "shared": 4995675,
      "groups": 110,
      "candidates": 1173,
      "oldBin": 2789579,
      "newBin": 51811,
      "binCalls": 26761,
      "ratioCalls": 514,
      "hits": 0,
      "cacheEntries": 46,
      "memoHits": 25783,
      "memoEvictions": 0,
      "peakMemo": 978,
      "memoValueBitsUpper": 3490482,
      "allocated": 392167,
      "oldSlots": 7318550,
      "tailMiss": 111,
      "weightSteps": 3499555,
      "month": 20,
      "day": 4,
      "coldBinUpperBound": 9425729,
      "arraySlotLowerBound": 3894602,
      "selectedArithmeticUpper": 52813527,
      "sharedWithinCap": true
    },
    {
      "p": 82,
      "queries": 1194,
      "rows": 1442,
      "writes": 3507625,
      "shared": 5002652,
      "groups": 111,
      "candidates": 1193,
      "oldBin": 2852220,
      "newBin": 52715,
      "binCalls": 27361,
      "ratioCalls": 519,
      "hits": 0,
      "cacheEntries": 46,
      "memoHits": 26370,
      "memoEvictions": 0,
      "peakMemo": 991,
      "memoValueBitsUpper": 3536879,
      "allocated": 395655,
      "oldSlots": 7332258,
      "tailMiss": 112,
      "weightSteps": 3506183,
      "month": 20,
      "day": 5,
      "coldBinUpperBound": 9543506,
      "arraySlotLowerBound": 3904722,
      "selectedArithmeticUpper": 53213890,
      "sharedWithinCap": false
    },
    {
      "p": 520,
      "queries": 8551,
      "rows": 1504,
      "writes": 3713186,
      "shared": 5218257,
      "groups": 551,
      "candidates": 8550,
      "oldBin": 25890841,
      "newBin": 611121,
      "binCalls": 261771,
      "ratioCalls": 5112,
      "hits": 0,
      "cacheEntries": 71,
      "memoHits": 250781,
      "memoEvictions": 6894,
      "peakMemo": 4096,
      "memoValueBitsUpper": 14618624,
      "allocated": 541270,
      "oldSlots": 7757708,
      "tailMiss": 154,
      "weightSteps": 3711682,
      "month": 10,
      "day": 18,
      "coldBinUpperBound": 61129832,
      "arraySlotLowerBound": 4255960,
      "selectedArithmeticUpper": 209653624,
      "sharedWithinCap": false
    }
  ],
  "productionChanged": false,
  "stage2": "OPEN"
}
*/
