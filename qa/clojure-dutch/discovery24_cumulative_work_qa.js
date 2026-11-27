#!/usr/bin/env node
/*
DISCOVERY24 cumulative abstract work certificate — QA only — 2026-11-27.
Input: discovery24_canonical_dp_input JSON from run 45956230947 job 140363223107,
artifact 15179872209 (SHA256 3d7cefbd036f85ede95e656917ab31f5b123f95b811e92d935d3ca66373db5af).
Run: node discovery24_cumulative_work_qa.js path/to/canonical-input.json
Source HEAD: 785c57411f544ea331e208a0272def0234dbb104; production blob 62f304dc013a9a9f70475bb0d34f186838b27318.
Contract: cold LRU, capacity 2048 each, integer abstract work units; arbitrary precision
arithmetic/comparisons and cache actions treated as logical operations, NOT CPU cycles,
bit complexity, heap bytes or production shared-group units. Conservative weights
cover explicit array initialization/copy, output loops, weights, binomial iterations,
suffix validation, candidate construction and rank/block operations. No timing guarantee.
Every row n+k+1 <= S+1, at most m rows per tail, sum of binomial k <= S.
At most m candidates per position, <=2 groups, one root suffix evaluation.
Ignoring cache hits gives the static upper bound in bound(p). Charged trace <= bound.
2*DP writes is a lower bound on the chosen array-slot model alone (initialization
and result writes); the actual prototype allocates a new object array per row.
Exact and one-below refer to this NEW diagnostic ledger, not the production budget.
Refusal is lack of a certificate under this ledger, not a claim of mathematical
impossibility or a production refusal. No production API invocation or Stage2 acceptance.
Small oracle: enumerate all multiset words independently and filter first/last order.
Canonical: compare independently recomputed rank total, writes and shared charge to
the accepted exact-SHA model evidence. No new CI/Native run.
Observed execution (JS sandbox, not Clojure Native):
{
  "status": "PASS_QA_ABSTRACT_WORK_ONLY",
  "small": {
    "profiles": 8,
    "words": 67,
    "checks": 480,
    "exactAccepts": 480,
    "minusOneRefusals": 480,
    "positiveSharedPrefixes": 413,
    "maxCost": 4574
  },
  "canonical": [
    {
      "p": 81,
      "cost": 62314932,
      "writes": 3500995,
      "shared": 4995675,
      "queries": 1174,
      "rows": 1440,
      "slots": 7318550,
      "weights": 3499555,
      "binSteps": 2789579,
      "groups": 110,
      "candidates": 1173,
      "events": 31914,
      "month": 20,
      "day": 4,
      "lowerBound": 7001990,
      "staticUpperBound": 4397816022,
      "capCertifiable": false,
      "exactAccept": true,
      "minusOneRefuse": true
    },
    {
      "p": 82,
      "cost": 62685084,
      "writes": 3507625,
      "shared": 5002652,
      "queries": 1194,
      "rows": 1442,
      "slots": 7332258,
      "weights": 3506183,
      "binSteps": 2852220,
      "groups": 111,
      "candidates": 1193,
      "events": 32578,
      "month": 20,
      "day": 5,
      "lowerBound": 7015250,
      "staticUpperBound": 4452767732,
      "capCertifiable": false,
      "exactAccept": true,
      "minusOneRefuse": true
    },
    {
      "p": 520,
      "cost": 168459258,
      "writes": 3713186,
      "shared": 5218257,
      "queries": 8551,
      "rows": 1504,
      "slots": 7757708,
      "weights": 3711682,
      "binSteps": 25890841,
      "groups": 551,
      "candidates": 8550,
      "events": 289999,
      "month": 10,
      "day": 18,
      "lowerBound": 7426372,
      "staticUpperBound": 28521616712,
      "capCertifiable": false,
      "exactAccept": true,
      "minusOneRefuse": true
    }
  ],
  "productionChanged": false,
  "stage2": "OPEN"
}
*/
function audit(data) {
  const CAP=5000000, LIMIT=2048;
  function trace(profile,rank,target) {
    const m=profile.length,S=profile.reduce((a,b)=>a+b,0), sc=new Map(),tc=new Map();
    let cost=0,writes=0,shared=0,queries=0,rows=0,slots=0,weights=0,binSteps=0,groups=0,candidates=0;
    const charges=[],snaps=[];
    function pay(n){if(!Number.isSafeInteger(n)||n<=0)throw Error("invalid charge");cost+=n;charges.push(n)}
    function cached(map,key,f){if(map.has(key)){const v=map.get(key);map.delete(key);map.set(key,v);return v}const v=f();map.set(key,v);if(map.size>LIMIT)map.delete(map.keys().next().value);return v}
    function bin(n,k){pay(6+4*k);binSteps+=k;let x=1n;for(let i=1;i<=k;i++)x=x*BigInt(n-k+i)/BigInt(i);return x}
    function tail(n,future,first){
      pay(8+4*(m+1));const key=JSON.stringify([n,future,first]);
      return cached(tc,key,()=>{
        let dp=null,total=1n,step=0;
        for(const k of future){
          const len=n+k+1, constrained=first||step>0;
          // Two full-array slot passes cover allocation initialization plus copy/fill.
          // 12 per output covers read, write, multiply, sum, prefix subtract,
          // weight multiply/divide, indices and scalar bookkeeping.
          pay(2*len+12*(n+1)+16);slots+=2*len;rows++;writes+=n+1;
          if(k>=2)weights+=n;
          const next=Array(len).fill(0n);
          if(dp!==null)for(let j=0;j<dp.length;j++)next[j]=dp[j];
          let prefix=total,subtotal=0n,weight=1n;
          for(let a=n;a>=0;a--){
            const t=n-a;if(k>=2&&t>0)weight=weight*BigInt(t+k-2)/BigInt(t);
            const ways=k>=2?weight:(t===0?1n:0n);
            const old=dp===null?0n:next[a];
            const factor=dp===null?(constrained?(a>0?1n:0n):total):(constrained?prefix:total);
            const value=factor*ways;next[a+1]=value;subtotal+=value;
            if(dp!==null&&constrained)prefix-=old;
          }
          next[0]=0n;dp=next;total=subtotal;n+=k;step++;
        }return total;
      })
    }
    function suffix(c,o,z){
      queries++;pay(16+8*(m+1));const key=JSON.stringify([c,o,z]);
      return cached(sc,key,()=>{
        if(!(0<=z&&z<=o&&o<=m)||c.slice(0,z).some(x=>x!==0)||c.slice(z).some(x=>x<=0))throw Error("invalid state");
        if(z===m)return 1n;
        if(o===z)return tail(c[z],c.slice(z+1),true);
        let active=c[z],base=1n;
        for(let i=z+1;i<o;i++){active+=c[i];base*=bin(active-1,c[i]-1)}
        return base*tail(active,c.slice(o),false)
      })
    }
    function moves(c,o,z){let a=[];for(let i=0;i<Math.min(m,o+1);i++){if(c[i]===0||(c[i]===1&&i!==z))continue;let n=c.slice();n[i]--;a.push([i+1,n,Math.max(o,i+1),z+(c[i]===1?1:0)])}return a}
    function snap(prefix){snaps.push({p:prefix.length,cost,writes,shared,queries,rows,slots,weights,binSteps,groups,candidates,events:charges.length,month:prefix.at(-1),day:prefix.filter(x=>x===prefix.at(-1)).length,prefix:prefix.slice()})}
    pay(32+16*(m+1));const total=suffix(profile,0,0);if(rank<1n||rank>total)throw Error("rank");
    let [first,c,o,z]=moves(profile,0,0)[0];pay(12*(m+1)**2);let prefix=[first];snap(prefix);
    while(prefix.length<target){
      pay(12*(m+1)**2);const all=moves(c,o,z),remaining=c.reduce((a,b)=>a+b,0);
      let chosen=null;
      for(const kind of [0,1]){
        const group=all.filter(x=>kind===0?x[0]<=o:x[0]===o+1);
        if(!group.length)continue;
        groups++;pay(16);shared+=1+(m-o-kind)*remaining;
        for(const x of group){
          candidates++;pay(8);const block=suffix(x[1],x[2],x[3]);
          if(rank>block)rank-=block;else {chosen=x;break}
        }if(chosen)break;
      }
      if(!chosen)throw Error("no candidate");
      prefix.push(chosen[0]);[c,o,z]=chosen.slice(1);snap(prefix)
    }
    // independent closed form ignoring all cache hits; at most m candidates per position.
    // per suffix: <= m binomial calls with total k<=S; <=m tail rows each n+k<=S.
    const perSuffix=16+8*(m+1)+6*m+4*S+8+4*(m+1)+m*(14*(S+1)+16);
    function bound(p){return 32+16*(m+1)+p*12*(m+1)**2+(1+(p-1)*m)*perSuffix+(p-1)*(32+8*m)}
    function gate(b,end){let x=0;for(let i=0;i<end;i++){if(x+charges[i]>b)return false;x+=charges[i]}return true}
    for(const s of snaps){
      if(s.cost>bound(s.p)||s.cost<2*s.writes)throw Error("bound");
      if(!gate(s.cost,s.events)||gate(s.cost-1,s.events))throw Error("budget boundary");
    }
    return {total,snaps,bound,charges}
  }
  function brute(profile){
    let out=[],rem=profile.slice(),word=[],S=profile.reduce((a,b)=>a+b,0);
    function visit(){if(word.length===S){let first=profile.map((_,i)=>word.indexOf(i+1)),last=profile.map((_,i)=>word.lastIndexOf(i+1));if(first.every((x,i)=>!i||x>first[i-1])&&last.every((x,i)=>!i||x>last[i-1]))out.push(word.slice());return}for(let i=0;i<rem.length;i++)if(rem[i]){rem[i]--;word.push(i+1);visit();word.pop();rem[i]++}}
    visit();return out
  }
  let words=0,checks=0,sharedBoundaries=0,maxCost=0;
  for(const p of [[2,2],[2,3],[3,2],[2,2,2],[2,3,2],[3,2,2],[2,2,2,2],[4,4]]){
    const w=brute(p);words+=w.length;
    for(let i=0;i<w.length;i++){
      const t=trace(p,BigInt(i+1),w[i].length);if(t.total!==BigInt(w.length))throw Error("small total");
      for(const s of t.snaps){if(s.prefix.join()!==w[i].slice(0,s.p).join())throw Error("small prefix");checks++;if(s.shared>0)sharedBoundaries++;maxCost=Math.max(maxCost,s.cost)}
    }
  }
  if(data.project_id!=="PC-BRANCH-CLOJURE-DUTCH"||data.source_sha!=="785c57411f544ea331e208a0272def0234dbb104"||data.production_rank_matches_normative!==true||data.production_profile_matches_normative!==true||data.production_year_matches_normative!==true||data.weaving_rank!==data.production_weaving_rank)throw Error("canonical lock");
  const t=trace(data.profile.map(Number),BigInt(data.weaving_rank),520);
  if(t.total!==BigInt(data.weaving_total))throw Error("canonical total");
  const expected={81:[3500995,4995675],82:[3507625,5002652],520:[3713186,5218257]};
  const canonical=[81,82,520].map(p=>{const s=t.snaps[p-1];if(s.writes!==expected[p][0]||s.shared!==expected[p][1])throw Error("canonical accounting mismatch p"+p+" "+s.writes+" "+s.shared);const {prefix,...rest}=s;return {...rest,lowerBound:2*s.writes,staticUpperBound:t.bound(p),capCertifiable:s.cost<=CAP,exactAccept:true,minusOneRefuse:true}});
  return {status:"PASS_QA_ABSTRACT_WORK_ONLY",small:{profiles:8,words,checks,exactAccepts:checks,minusOneRefusals:checks,positiveSharedPrefixes:sharedBoundaries,maxCost},canonical,productionChanged:false,stage2:"OPEN"};
}
const fs=require("node:fs");
if(process.argv.length!==3){console.error("usage: node discovery24_cumulative_work_qa.js canonical-input.json");process.exit(2)}
console.log(JSON.stringify(audit(JSON.parse(fs.readFileSync(process.argv[2],"utf8"))),null,2));
