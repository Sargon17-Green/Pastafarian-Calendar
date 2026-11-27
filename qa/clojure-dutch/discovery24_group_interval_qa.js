#!/usr/bin/env node
/* DISCOVERY24 QA only. Parent partition certificate: for a reachable prefix,
   its completions are a disjoint lexicographic union of legal child blocks.
   The active group precedes the at-most-one fresh child. With exact parent T
   and fresh count N, active interval is [1,T-N], fresh interval [T-N+1,T].
   Strict r>T-N permits omitting every active block computation, NOT its
   fixed charge. The last active block is the residual of the active interval.
   At the first letter the only legal child is 1, so parent=T. Inductively
   the selected child count becomes the next parent. No rank crossing.
   Baseline and certificate use same branch's exact suffix recurrence;
   independent brute-force small oracle, source-locked canonical input.
   This is an offline model: speculative fresh calculation can occur before
   charging it; do not infer production resource safety or waive billing.
   Cache operation ledger counts has/get/set/delete/iterator retrieval, not
   Map internal implementation costs. keyChars counts constructed cache key
   characters, not all JS operations. Conservative integer payload bound:
   completions <= m^S, binomial <=2^S, recurrence intermediates <= products
   of two such counts and polynomial S factors. Aggregate bound covers
   counted cache values and one tail array, excludes objects, keys, transient
   integers, other arrays, GC and engine overhead. No total heap/JVM proof.
   Prior Native job 140363223107, run 45956230947, input exact 785c57411...
   Production blob 62f304dc013a9a9f70475bb0d34f186838b27318 unchanged.
   Predecessor 47f43176e47f6646fb07daccf65633b9fb04cc0a. No CI or Native run. */
function audit(data, memoLimit=4096){
 const CAP=5000000,LIMIT=2048;
 function trace(profile,rank,target,certified=false){
  const m=profile.length,S=profile.reduce((a,b)=>a+b,0),sc=new Map(),tc=new Map(),bc=new Map(),memo=new Map(); let memoHits=0,memoEvictions=0,peakMemo=0;
  let skippedGroups=0,skippedCandidates=0,certificateQueries=0,speculativeQueries=0,cacheOps=0,keyChars=0,peakEntries=0,peakArray=0; let queries=0,rows=0,writes=0,shared=0,groups=0,candidates=0,oldBin=0,newBin=0,binCalls=0,ratioCalls=0,hits=0,allocated=0,oldSlots=0,tailMiss=0,weightSteps=0;const snaps=[];
  function peak(){peakEntries=Math.max(peakEntries,sc.size+tc.size+bc.size+memo.size)} function cache(map,key,f){keyChars+=key.length;cacheOps++;if(map.has(key)){cacheOps+=3;const v=map.get(key);map.delete(key);map.set(key,v);return v}const v=f();cacheOps++;map.set(key,v);peak();if(map.size>LIMIT){cacheOps+=2;map.delete(map.keys().next().value)}return v}
  function exactBin(n,k){
   oldBin+=k;binCalls++;
   const kk=Math.min(k,n-k),key=n+':'+kk,prev=bc.get(kk);keyChars+=key.length;cacheOps+=2;let x;if(memo.has(key)){cacheOps+=4;x=memo.get(key);memo.delete(key);memo.set(key,x);bc.set(kk,{n,x});memoHits++;return x;}
   if(prev&&Math.abs(n-prev.n)<=kk){
    x=prev.x;let j=prev.n;ratioCalls++;
    if(j===n)hits++;
    while(j<n){j++;const num=x*BigInt(j),den=BigInt(j-kk);if(num%den!==0n)throw Error("nonexact up");x=num/den;newBin++}
    while(j>n){const num=x*BigInt(j-kk),den=BigInt(j);if(num%den!==0n)throw Error("nonexact down");x=num/den;j--;newBin++}
   }else{x=1n;for(let j=1;j<=kk;j++){const num=x*BigInt(n-kk+j),den=BigInt(j);if(num%den!==0n)throw Error("nonexact direct");x=num/den;newBin++}}
   cacheOps++;bc.set(kk,{n,x});if(memoLimit){cacheOps++;memo.set(key,x);peak();if(memo.size>memoLimit){cacheOps+=2;memo.delete(memo.keys().next().value);memoEvictions++;}peakMemo=Math.max(peakMemo,memo.size);}return x;
  }
  function tail(n,future,first){
   return cache(tc,JSON.stringify([n,future,first]),()=>{
    if(!future.length)return 1n;
    const size=n+future.reduce((a,b)=>a+b,0)+1;
    peakArray=Math.max(peakArray,size);const dp=Array(size).fill(0n);allocated+=size;tailMiss++;
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
  let [f,c,o,z]=moves(profile,0,0)[0],prefix=[f],parent=total;
  function snap(){if(newBin>oldBin||bc.size>S+1)throw Error("cold bound");snaps.push({p:prefix.length,skippedGroups,skippedCandidates,certificateQueries,speculativeQueries,cacheOps,keyChars,peakEntries,peakArray,queries,rows,writes,shared,groups,candidates,oldBin,newBin,binCalls,ratioCalls,hits,cacheEntries:bc.size,memoHits,memoEvictions,peakMemo,memoValueBitsUpper:peakMemo*S,allocated,oldSlots,tailMiss,weightSteps,month:prefix[prefix.length-1],day:prefix.filter(x=>x===prefix[prefix.length-1]).length,prefix:prefix.slice(),coldBinUpperBound:(1+(prefix.length-1)*m)*S})}
  snap();
  while(prefix.length<target){
   const all=moves(c,o,z),remaining=c.reduce((a,b)=>a+b,0);let chosen=null;
   if(!certified){
    for(const kind of [0,1]){const group=all.filter(x=>kind===0?x[0]<=o:x[0]===o+1);if(!group.length)continue;groups++;shared+=1+(m-o-kind)*remaining;for(const x of group){candidates++;const block=suffix(x[1],x[2],x[3]);if(rank>block)rank-=block;else{chosen=x;parent=block;break}}if(chosen)break}
   }else{
    const active=all.filter(x=>x[0]<=o), fresh=all.filter(x=>x[0]===o+1);
    if(fresh.length>1||rank<1n||rank>parent)throw Error("parent invariant");
    let newCount=0n;
    if(fresh.length){if(!active.length)newCount=parent;else{const x=fresh[0];newCount=suffix(x[1],x[2],x[3]);certificateQueries++}}
    const activeCount=parent-newCount;
    if(activeCount<0n||(!active.length&&activeCount!==0n)||newCount<0n)throw Error("partition");
    if(active.length){
      groups++;shared+=1+(m-o)*remaining;
      if(rank>activeCount){rank-=activeCount;skippedGroups++;skippedCandidates+=active.length}
      else{
        if(fresh.length)speculativeQueries++;
        let residual=activeCount;
        for(let i=0;i<active.length;i++){
          const x=active[i];candidates++;
          const block=i===active.length-1?residual:suffix(x[1],x[2],x[3]);
          if(block<0n||block>residual)throw Error("invalid interval");
          if(rank>block){rank-=block;residual-=block}
          else{chosen=x;parent=block;break}
        }
        if(!chosen)throw Error("active crossing");
      }
    }
    if(!chosen&&fresh.length){groups++;shared+=1+(m-o-1)*remaining;candidates++;if(rank<1n||rank>newCount)throw Error("fresh crossing");chosen=fresh[0];parent=newCount}
   }
   if(!chosen)throw Error("candidate");prefix.push(chosen[0]);[c,o,z]=chosen.slice(1);snap()
  }return {total,snaps}
 }
 function brute(profile){let out=[],rem=profile.slice(),w=[],S=profile.reduce((a,b)=>a+b,0);function visit(){if(w.length===S){const f=profile.map((_,i)=>w.indexOf(i+1)),l=profile.map((_,i)=>w.lastIndexOf(i+1));if(f.every((x,i)=>!i||x>f[i-1])&&l.every((x,i)=>!i||x>l[i-1]))out.push(w.slice());return}for(let i=0;i<rem.length;i++)if(rem[i]){rem[i]--;w.push(i+1);visit();w.pop();rem[i]++}}visit();return out}
 let words=0,checks=0,smallSkips=0,budgetChecks=0;
 for(const p of [[2,2],[2,3],[3,2],[2,2,2],[2,3,2],[3,2,2],[2,2,2,2],[4,4]]){const w=brute(p);words+=w.length;for(let i=0;i<w.length;i++){const t=trace(p,BigInt(i+1),w[i].length,true), baseline=trace(p,BigInt(i+1),w[i].length);smallSkips+=t.snaps.at(-1).skippedGroups;if(t.total!==BigInt(w.length))throw Error("total");for(const s of t.snaps){if(s.prefix.join()!==w[i].slice(0,s.p).join())throw Error("prefix");if(s.shared!==baseline.snaps[s.p-1].shared||s.groups!==baseline.snaps[s.p-1].groups)throw Error('billing drift');budgetChecks+=s.shared>0?2:1;checks++}}}
 if(data.project_id!=="PC-BRANCH-CLOJURE-DUTCH"||data.source_sha!=="785c57411f544ea331e208a0272def0234dbb104"||data.production_rank_matches_normative!==true||data.production_profile_matches_normative!==true||data.production_year_matches_normative!==true||data.weaving_rank!==data.production_weaving_rank)throw Error("lock");
 const profile=data.profile.map(Number),rank=BigInt(data.weaving_rank), baseline=trace(profile,rank,520),t=trace(profile,rank,520,true);for(let i=0;i<t.snaps.length;i++){const x=t.snaps[i],y=baseline.snaps[i];if(x.prefix.join()!==y.prefix.join()||x.shared!==y.shared||x.groups!==y.groups)throw Error('canonical prefix/billing drift '+x.p)}if(t.total!==BigInt(data.weaving_total))throw Error("canonical total");
 const expected={81:[3500995,4995675,2789579,7318550,20,4],82:[3507625,5002652,2852220,7332258,20,5],520:[3713186,5218257,25890841,7757708,10,18]};
 const canonical=[81,82,520].map(p=>{const s=t.snaps[p-1],old=baseline.snaps[p-1];if([old.writes,old.shared,old.oldBin,old.oldSlots,old.month,old.day].join()!==expected[p].join())throw Error("canonical baseline mismatch "+p);const {prefix,...rest}=s;const S=profile.reduce((a,b)=>a+b,0),m=profile.length;const integerBitsUpper=2*S*Math.ceil(Math.log2(m+1))+2*Math.ceil(Math.log2(S+1))+8;return {...rest,baselineQueries:old.queries,baselineWrites:old.writes,baselineCacheOps:old.cacheOps,baselineKeyChars:old.keyChars,integerBitsUpper,cacheAndArrayValueBitsUpper:(s.peakEntries+s.peakArray)*integerBitsUpper,sharedWithinCap:s.shared<=CAP}});
 return {status:"PASS_QA_GROUP_INTERVAL_ONLY",small:{profiles:8,words,checks,smallSkips,budgetChecks},canonical,canonicalPrefixComparisons:520,productionChanged:false,stage2:"OPEN"}
}


const fs=require('node:fs');if(process.argv.length!==3){console.error('usage: node discovery24_group_interval_qa.js canonical-input.json');process.exit(2)}console.log(JSON.stringify(audit(JSON.parse(fs.readFileSync(process.argv[2],'utf8'))),null,2));
/* Observed JS sandbox result (not Native):
{
  "status": "PASS_QA_GROUP_INTERVAL_ONLY",
  "small": {
    "profiles": 8,
    "words": 67,
    "checks": 480,
    "smallSkips": 87,
    "budgetChecks": 893
  },
  "canonical": [
    {
      "p": 81,
      "skippedGroups": 30,
      "skippedCandidates": 465,
      "certificateQueries": 80,
      "speculativeQueries": 50,
      "cacheOps": 116544,
      "keyChars": 273409,
      "peakEntries": 1878,
      "peakArray": 3570,
      "queries": 758,
      "rows": 1253,
      "writes": 3246155,
      "shared": 4995675,
      "groups": 110,
      "candidates": 708,
      "oldBin": 1983991,
      "newBin": 51147,
      "binCalls": 19024,
      "ratioCalls": 484,
      "hits": 0,
      "cacheEntries": 46,
      "memoHits": 18081,
      "memoEvictions": 0,
      "peakMemo": 943,
      "memoValueBitsUpper": 3365567,
      "allocated": 461813,
      "oldSlots": 6769572,
      "tailMiss": 131,
      "weightSteps": 3244902,
      "month": 20,
      "day": 4,
      "coldBinUpperBound": 9425729,
      "baselineQueries": 1174,
      "baselineWrites": 3500995,
      "baselineCacheOps": 165432,
      "baselineKeyChars": 412953,
      "integerBitsUpper": 42860,
      "cacheAndArrayValueBitsUpper": 233501280,
      "sharedWithinCap": true
    },
    {
      "p": 82,
      "skippedGroups": 30,
      "skippedCandidates": 465,
      "certificateQueries": 81,
      "speculativeQueries": 51,
      "cacheOps": 120424,
      "keyChars": 281393,
      "peakEntries": 1915,
      "peakArray": 3570,
      "queries": 779,
      "rows": 1256,
      "writes": 3256151,
      "shared": 5002652,
      "groups": 111,
      "candidates": 728,
      "oldBin": 2049865,
      "newBin": 52151,
      "binCalls": 19655,
      "ratioCalls": 489,
      "hits": 0,
      "cacheEntries": 46,
      "memoHits": 18698,
      "memoEvictions": 0,
      "peakMemo": 957,
      "memoValueBitsUpper": 3415533,
      "allocated": 468789,
      "oldSlots": 6790256,
      "tailMiss": 133,
      "weightSteps": 3254895,
      "month": 20,
      "day": 5,
      "coldBinUpperBound": 9543506,
      "baselineQueries": 1194,
      "baselineWrites": 3507625,
      "baselineCacheOps": 169124,
      "baselineKeyChars": 420553,
      "integerBitsUpper": 42860,
      "cacheAndArrayValueBitsUpper": 235087100,
      "sharedWithinCap": false
    },
    {
      "p": 520,
      "skippedGroups": 32,
      "skippedCandidates": 528,
      "certificateQueries": 122,
      "speculativeQueries": 90,
      "cacheOps": 1569238,
      "keyChars": 3019353,
      "peakEntries": 6826,
      "peakArray": 3570,
      "queries": 8100,
      "rows": 1334,
      "writes": 3515561,
      "shared": 5218257,
      "groups": 551,
      "candidates": 8022,
      "oldBin": 24979450,
      "newBin": 613243,
      "binCalls": 252991,
      "ratioCalls": 5073,
      "hits": 0,
      "cacheEntries": 71,
      "memoHits": 242019,
      "memoEvictions": 6876,
      "peakMemo": 4096,
      "memoValueBitsUpper": 14618624,
      "allocated": 673571,
      "oldSlots": 7327348,
      "tailMiss": 192,
      "weightSteps": 3514227,
      "month": 10,
      "day": 18,
      "coldBinUpperBound": 61129832,
      "baselineQueries": 8551,
      "baselineWrites": 3713186,
      "baselineCacheOps": 1625642,
      "baselineKeyChars": 3172022,
      "integerBitsUpper": 42860,
      "cacheAndArrayValueBitsUpper": 445572560,
      "sharedWithinCap": false
    }
  ],
  "canonicalPrefixComparisons": 520,
  "productionChanged": false,
  "stage2": "OPEN"
}
*/
