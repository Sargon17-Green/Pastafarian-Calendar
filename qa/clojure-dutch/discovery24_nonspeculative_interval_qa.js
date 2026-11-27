#!/usr/bin/env node
/* DISCOVERY24 QA-only; parent 2dd3f6178b3a9d8c69c9ec98ff7b3ae0e5c38ae0.
   Production source blob 62f304dc013a9a9f70475bb0d34f186838b27318.
   Canonical input: Native job 140363223107, run 45956230947, exact
   785c57411f544ea331e208a0272def0234dbb104. No new Native/CI.
   Each child block partitions its parent's exact count. Sequentially
   subtract preceding exact blocks; the final child's size is the residual.
   For rank=parent, last legal child is nonempty: close remaining symbols
   in increasing order. Thus choose it directly, charging traversed groups.
   Induction preserves local rank and parent count. Both active and fresh
   fixed group charges are invariant; p82 and p520 cannot be accepted under
   the same observable logical charging contract, even with free arithmetic.
   Coarse envelopes refer only to the explicitly defined abstract machine;
   they are not measured bit work or runtime/physical heap certification.
   Independent brute-force oracle on small profiles; canonical comparison
   to predecessor exact recurrence. No production/API/budget change. */
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
    // Disjoint ordered intervals. Charge each traversed nonempty group.
    // No count of a fresh block unless it is selected; residual supplies it.
    // Every legal move has a completion: exhaust all remaining symbols in
    // increasing order, thereby preserving both first and last order.
    if(rank<1n||rank>parent)throw Error("parent invariant");
    let residual=parent;
    if(rank===parent && all.length>1){
      const x=all.at(-1),fresh=x[0]===o+1,active=all.some(a=>a[0]<=o);
      if(active){groups++;shared+=1+(m-o)*remaining;}
      if(fresh){groups++;shared+=1+(m-o-1)*remaining;if(active){skippedGroups++;skippedCandidates+=all.length-1;}}
      certificateQueries++;candidates++;
      const count=suffix(x[1],x[2],x[3]);
      if(count<=0n||count>parent)throw Error("last-child feasibility");
      rank=count;parent=count;chosen=x;
    }else{
      for(const kind of [0,1]){
        const group=all.filter(x=>kind===0?x[0]<=o:x[0]===o+1);
        if(!group.length)continue;
        groups++;shared+=1+(m-o-kind)*remaining;
        for(const x of group){
          candidates++;
          const final=x===all.at(-1);
          const block=final?residual:suffix(x[1],x[2],x[3]);
          if(block<0n||block>residual)throw Error("invalid residual");
          if(rank>block){rank-=block;residual-=block;}
          else{chosen=x;parent=block;break;}
        }
        if(chosen)break;
      }
    }
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
 const canonical=[81,82,520].map(p=>{const s=t.snaps[p-1],old=baseline.snaps[p-1];if([old.writes,old.shared,old.oldBin,old.oldSlots,old.month,old.day].join()!==expected[p].join())throw Error("canonical baseline mismatch "+p);const {prefix,...rest}=s;const S=profile.reduce((a,b)=>a+b,0),m=profile.length;const integerBitsUpper=2*S*Math.ceil(Math.log2(m+1))+2*Math.ceil(Math.log2(S+1))+8;if(s.speculativeQueries!==0)throw Error("speculation");
 const Q=1n+BigInt(p-1)*BigInt(m), M=BigInt(m), N=BigInt(S), B=BigInt(integerBitsUpper);
 // Abstract machine: candidate vectors, snapshots, keys and JSON are
 // charged per scalar/character; DP and ratio steps per scalar operation.
 // Deliberately loose envelope: Q*(m+1)*(S+1) covers each row/cell or
 // ratio iteration; multiply by 1024 for fixed per-event scalar operations.
 // Additional m^2 per position covers candidate construction and scan;
 // p^2 covers prefix snapshot copies/comparisons; key construction at most
 // O(m log S) per call, bounded by (m+1)*(S+1).
 const abstractOpsUpper=1024n*(Q*(M+1n)*(N+1n)+BigInt(p)*(M+1n)**2n+BigInt(p)**2n+100000n);
 // Implementable reference machine uses linear dictionary search, schoolbook
 // arithmetic (including long division), and character-by-character JSON.
 // Factor bounds a scan of all logical cache entries and B-bit operands.
 // Not a bound on JS engine/JVM runtime, allocator overhead, or physical heap.
 const mapSlots=8192n+N+1n;
 const bitWorkEnvelope=abstractOpsUpper*64n*(mapSlots+1n)*(B+1n)**2n;
 const cumulativeOperandPayloadBitsEnvelope=abstractOpsUpper*64n*(B+1n);
 return {...rest,abstractOpsUpper:String(abstractOpsUpper),bitWorkEnvelope:String(bitWorkEnvelope),cumulativeOperandPayloadBitsEnvelope:String(cumulativeOperandPayloadBitsEnvelope),baselineQueries:old.queries,baselineWrites:old.writes,baselineCacheOps:old.cacheOps,baselineKeyChars:old.keyChars,integerBitsUpper,cacheAndArrayValueBitsUpper:(s.peakEntries+s.peakArray)*integerBitsUpper,sharedWithinCap:s.shared<=CAP}});
 return {status:"PASS_QA_NONSPECULATIVE_INTERVAL_ONLY",small:{profiles:8,words,checks,smallSkips,budgetChecks},canonical,canonicalPrefixComparisons:520,productionChanged:false,stage2:"OPEN"}
}



const fs=require('node:fs');if(process.argv.length!==3){console.error('usage: node discovery24_nonspeculative_interval_qa.js canonical-input.json');process.exit(2)}console.log(JSON.stringify(audit(JSON.parse(fs.readFileSync(process.argv[2],'utf8'))),null,2));
/* Observed offline JS result (not Native):
{
  "status": "PASS_QA_NONSPECULATIVE_INTERVAL_ONLY",
  "small": {
    "profiles": 8,
    "words": 67,
    "checks": 480,
    "smallSkips": 40,
    "budgetChecks": 893
  },
  "canonical": [
    {
      "p": 81,
      "skippedGroups": 0,
      "skippedCandidates": 0,
      "certificateQueries": 0,
      "speculativeQueries": 0,
      "cacheOps": 162562,
      "keyChars": 403243,
      "peakEntries": 2229,
      "peakArray": 3570,
      "queries": 1144,
      "rows": 945,
      "writes": 2344731,
      "shared": 4995675,
      "groups": 110,
      "candidates": 1173,
      "oldBin": 2740962,
      "newBin": 51118,
      "binCalls": 26296,
      "ratioCalls": 500,
      "hits": 0,
      "cacheEntries": 46,
      "memoHits": 25338,
      "memoEvictions": 0,
      "peakMemo": 958,
      "memoValueBitsUpper": 3419102,
      "allocated": 285850,
      "oldSlots": 4897722,
      "tailMiss": 81,
      "weightSteps": 2343786,
      "month": 20,
      "day": 4,
      "coldBinUpperBound": 9425729,
      "abstractOpsUpper": "328463131648",
      "bitWorkEnvelope": "454265023385964142865350656",
      "cumulativeOperandPayloadBitsEnvelope": "901008530276155392",
      "baselineQueries": 1174,
      "baselineWrites": 3500995,
      "baselineCacheOps": 165432,
      "baselineKeyChars": 412953,
      "integerBitsUpper": 42860,
      "cacheAndArrayValueBitsUpper": 248545140,
      "sharedWithinCap": true
    },
    {
      "p": 82,
      "skippedGroups": 0,
      "skippedCandidates": 0,
      "certificateQueries": 0,
      "speculativeQueries": 0,
      "cacheOps": 166254,
      "keyChars": 410843,
      "peakEntries": 2263,
      "peakArray": 3570,
      "queries": 1164,
      "rows": 947,
      "writes": 2351361,
      "shared": 5002652,
      "groups": 111,
      "candidates": 1193,
      "oldBin": 2803603,
      "newBin": 52022,
      "binCalls": 26896,
      "ratioCalls": 505,
      "hits": 0,
      "cacheEntries": 46,
      "memoHits": 25925,
      "memoEvictions": 0,
      "peakMemo": 971,
      "memoValueBitsUpper": 3465499,
      "allocated": 289338,
      "oldSlots": 4911430,
      "tailMiss": 82,
      "weightSteps": 2350414,
      "month": 20,
      "day": 5,
      "coldBinUpperBound": 9543506,
      "abstractOpsUpper": "332566155264",
      "bitWorkEnvelope": "459939511446538390079275008",
      "cumulativeOperandPayloadBitsEnvelope": "912263550769299456",
      "baselineQueries": 1194,
      "baselineWrites": 3507625,
      "baselineCacheOps": 169124,
      "baselineKeyChars": 420553,
      "integerBitsUpper": 42860,
      "cacheAndArrayValueBitsUpper": 250002380,
      "sharedWithinCap": false
    },
    {
      "p": 520,
      "skippedGroups": 0,
      "skippedCandidates": 0,
      "certificateQueries": 0,
      "speculativeQueries": 0,
      "cacheOps": 1620282,
      "keyChars": 3157756,
      "peakEntries": 6736,
      "peakArray": 3570,
      "queries": 8509,
      "rows": 1008,
      "writes": 2553576,
      "shared": 5218257,
      "groups": 551,
      "candidates": 8550,
      "oldBin": 25803914,
      "newBin": 609851,
      "binCalls": 260923,
      "ratioCalls": 5091,
      "hits": 0,
      "cacheEntries": 71,
      "memoHits": 249965,
      "memoEvictions": 6862,
      "peakMemo": 4096,
      "memoValueBitsUpper": 14618624,
      "allocated": 431485,
      "oldSlots": 5329944,
      "tailMiss": 123,
      "weightSteps": 2552568,
      "month": 10,
      "day": 18,
      "coldBinUpperBound": 61129832,
      "abstractOpsUpper": "2129887395840",
      "bitWorkEnvelope": "2945637590515310251978260480",
      "cumulativeOperandPayloadBitsEnvelope": "5842502635078287360",
      "baselineQueries": 8551,
      "baselineWrites": 3713186,
      "baselineCacheOps": 1625642,
      "baselineKeyChars": 3172022,
      "integerBitsUpper": 42860,
      "cacheAndArrayValueBitsUpper": 441715160,
      "sharedWithinCap": false
    }
  ],
  "canonicalPrefixComparisons": 520,
  "productionChanged": false,
  "stage2": "OPEN"
}
*/
