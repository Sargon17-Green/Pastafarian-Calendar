#!/usr/bin/env node
/* DISCOVERY24 independent state/charge audit, 2026-11-27.
Pinned parent 4ce9c6213f403708d91968ddf9434b4e8c58b27f;
src/pastafari/maandrang.clj blob 62f304dc013a9a9f70475bb0d34f186838b27318.
No production change, no Native/CI, no Stage2 acceptance.
Run: node qa/clojure-dutch/discovery24_independent_interval_charge_audit.js

Proof against source: prefix-legale-kandidaten admits positive remaining counts
with label <= opened+1; closing is permitted only for closed+1.
For every reachable legal state, closed labels form an initial interval;
opened labels form an initial interval; all not-yet-opened labels have
their original positive multiplicity. After any legal candidate, exhaust
remaining labels in increasing order. This is a completion witness: first
occurrences of unopened labels and last occurrences of unfinished labels
are ordered, and neither conflicts with the already fixed prefix.
Thus legal child blocks are nonempty and partition all parent completions
in lexicographic order. With parent count T and rank r in [1,T], subtract
exact counts of preceding blocks; residual is the final child's exact size.
For r=T, choose last legal child and use its exact count as its local rank.
Induction establishes prefix/rank equivalence. The independent oracle below
generates unrestricted multiset permutations and filters first/last order,
not a suffix DP. Includes small profiles outside production domain (2/3)
deliberately for mathematical coverage; no API acceptance claim.

Source charge: prefix-gedeelde-raming = 1+(m-o)*S for S=sum(parent rest);
prefix-volgende-keuze charges the active group if nonempty before counting,
then charges fresh group iff chosen fresh, at 1+(m-o-1)*S. Initial label 1
is free in prefix-op-rang-begrensd; validation position < total days.
Given identical prefix, group traversal is invariant even if exact count
is free. Charge positive, cumulative monotone. Source rejects before work
when proposed cost > supplied budget. The canonical fixed charges from
Native model run 45956230947 (job 140363223107; source 785c57411f544ea331e208a0272def0234dbb104;
artifact 15179872209 digest 3d7cefbd036f85ede95e656917ab31f5b123f95b811e92d935d3ca66373db5af)
are 4995675/5002652/5218257 at p81/82/520. They are previously measured
model values, not rerun here. At cap 5000000, margins +4325/-2652/-218257.
The p81 charge alone does not certify production date API. At p82/p520
same-charge acceptance is impossible, regardless of arithmetic savings.

Explicit reference-machine envelope (NOT the existing cached JS or JVM):
Use no caches, no snapshots; one parent and one mutable candidate vector.
For exact suffix, count active last-order product via binomial recurrence
(sum of k <= N); for each unopened month use direct insertion recurrence
with weight array and two rolling count arrays of N+1 slots. Compute root
once; at most m child counts per subsequent position, even if no residual
shortcut: Q=1+(p-1)m. At most m rows of <=N+1 cells per count, plus <=N
binomial iterations. Define a scalar primitive as one word load/store,
index/branch/compare/add/subtract/multiply/divide or move. Implementation
recipe: each cell computes weight and prefix/ways/product/sum with <=256
such primitives including loop/index/init; each binomial iteration <=256;
each active label and suffix entry/exit <=256; enumerate at most m moves
per position, copy <=m counts per move; <=256(m+1)^2 primitives per
position including selecting and charging. Input/profile/output scan
<=256(N+p+1). Therefore a deliberately loose scalar budget is U below.
All counts and nonnegative partial sums count constrained words or
insertion choices, bounded by (m+1)^N; products of two such counts and
small factors <=(m+1)^(2N)*(N+1)^2. B=2N ceil(log2(m+1))+2ceil(log2(N+1))+8.
Use W=2B+2 bits per scalar slot including multiplication scratch result.
Define bit work in a word-addressed abstract RAM (addressing counted as
word operation, not physical memory latency): schoolbook binary
multiplication and restoring division using at most W shift-add/subtract
steps with W-bit operands, each step bounded by 16(W+1) bit primitives.
Use separate <=16(W+1) scratch bits, fixed registers counted in slots.
Bound 16(W+1)^2 per scalar primitive. No arbitrary input size claim:
input is a validated profile, valid bounded rank/total, p, fixed cap.
Serialization schema is bounded ASCII decimal JSON of profile, rank,
total, p, prefix, charge, month/day, fixed labels, no snapshots/logs:
reserve chars=4B+8m+8p+256. Each decimal digit parse/emit uses at most
one word multiply/add or div/remainder by 10; charge <=32(W+1)^2 per
character. One reusable buffer, or separate input/output with combined
length <=chars. Live payload <=W*(3(N+1)+4m+p+128)+8*chars+16(W+1)
bits: 3 rolling arrays, 4 profile/candidate vectors, prefix, 128 scalar
registers, JSON bytes, arithmetic scratch; excludes physical allocator,
GC, native object headers, OS, and implementation timing. No claim that
existing JS has this bound; a future implementation must enforce the
specified machine schedule and independently measure actual resources.
This is a conservative analytical bound, not a 5-million logical cell
charge or practical performance certificate. Canonical numbers computed
below. The fixed budget is a distinct policy metric.

Policy alternatives (no changes made): (A) retain contract and fail
closed at p82/p520; (B) explicitly raise cap (minimum 5002652 or 5218257
for these exact model traces only; not a universal guarantee), keep charge
units; (C) explicitly replace charge contract with a new certified
primitive/DP accounting and its own cap, refusal semantics, API scope and
regression gates; DP writes alone omit arithmetic, serialization and
transients. (D) an API/coverage exception is a policy waiver, not PASS.
No production/API/budget/128N changes or new CI without applicable approval.
*/
function audit(){
let profiles=0,words=0,states=0,edges=0,checks=0,last=0,refusals=0;
for(let m=2;m<=4;m++){
 function prof(a){if(a.length<m){for(let k=2;k<=4;k++)if(a.reduce((x,y)=>x+y,0)+k+2*(m-a.length-1)<=11)prof([...a,k]);return}
 profiles++;const N=a.reduce((x,y)=>x+y,0), all=[],w=[],r=a.slice();
 function gen(){if(w.length===N){let f=a.map((_,i)=>w.indexOf(i+1)),l=a.map((_,i)=>w.lastIndexOf(i+1));if(f.every((x,i)=>!i||x>f[i-1])&&l.every((x,i)=>!i||x>l[i-1]))all.push(w.join(""));return}for(let i=0;i<m;i++)if(r[i]){r[i]--;w.push(i+1);gen();w.pop();r[i]++}}gen();words+=all.length;
 const map=new Map();for(const word of all)for(let p=0;p<=N;p++){const s=word.slice(0,p);if(!map.has(s))map.set(s,[]);map.get(s).push(word)}
 for(const [s,ws] of map){if(s.length===N)continue;states++;const c=a.map((k,i)=>k-[...s].filter(x=>+x===i+1).length),o=Math.max(0,...[...s].map(Number)),z=c.findIndex(x=>x>0),S=N-s.length;
 const legal=[];for(let i=0;i<Math.min(m,o+1);i++)if(c[i]>0&&(c[i]>1||i===z))legal.push(i+1);
 const empirical=[...new Set(ws.map(w=>+w[s.length]))];if(legal.join()!=empirical.join())throw Error("legal drift");let rem=ws.length;
 for(const [i,k] of legal.entries()){let n=map.get(s+k).length;edges++;if(n<=0)throw Error("empty");const d=c.slice();d[k-1]--;const witness=s+k+d.map((n,j)=>String(j+1).repeat(n)).join("");if(!map.get(s+k).includes(witness))throw Error("witness");if(i===legal.length-1&&n!==rem)throw Error("residual");rem-=n}
 if(rem!==0)throw Error("partition");if(ws.at(-1)[s.length]!=legal.at(-1))throw Error("last");last++;
 for(let i=0;i<ws.length;i++){let rank=i+1,res=ws.length,choice=null,bill=0;for(const k of legal){if(s.length&&k===legal[0]&&k<=o)bill+=1+(m-o)*S;if(s.length&&k===o+1)bill+=1+(m-o-1)*S;let n=k===legal.at(-1)?res:map.get(s+k).length;if(rank<=n){choice=k;break}rank-=n;res-=n}let expected=+ws[i][s.length],b=s.length?((legal.some(k=>k<=o)?1+(m-o)*S:0)+(expected===o+1?1+(m-o-1)*S:0)):0;if(choice!==expected||bill!==b)throw Error("rank/bill");checks++;if(s.length>0&&b>0){const prev=137;if(!(prev+b>prev+b-1&&prev+b<=prev+b))throw Error("boundary");refusals++}}
 }
 }prof([])
}
const bounds=[];const N=3569n,m=33n,B=2n*N*6n+2n*12n+8n,W=2n*B+2n;
for(const [p,bill] of [[81n,4995675n],[82n,5002652n],[520n,5218257n]]){const Q=1n+(p-1n)*m;const U=256n*(Q*((m+1n)*(N+1n)+N+m+1n)+p*(m+1n)**2n+N+p+1n);const chars=4n*B+8n*m+8n*p+256n;const serial=32n*chars*(W+1n)**2n;const work=U*16n*(W+1n)**2n+serial;const slots=3n*(N+1n)+4n*m+p+128n;const transient=slots*W+8n*chars+16n*(W+1n);bounds.push({p:String(p),bill:String(bill),margin:String(5000000n-bill),Q:String(Q),primitive:String(U),chars:String(chars),work:String(work),slots:String(slots),transientBits:String(transient)})}
return {status:"PASS_EXHAUSTIVE_INTERVAL_AND_LOGICAL_BILL_MODEL_ONLY",profiles,words,states,edges,checks,last,refusals,bounds,stage2:"OPEN"};
}
console.log(JSON.stringify(audit(),null,2));
/* Observed independent JS result: {"status":"PASS_EXHAUSTIVE_INTERVAL_AND_LOGICAL_BILL_MODEL_ONLY","profiles":66,"words":7352,"states":26408,"edges":33694,"checks":77507,"last":26408,"refusals":70155,"bounds":[{"p":"81","bill":"4995675","margin":"4325","Q":"2641","primitive":"84525411840","chars":"172608","work":"9938109433501009373184","slots":"11051","transientBits":"950066254"},{"p":"82","bill":"5002652","margin":"-2652","Q":"2674","primitive":"85581564416","chars":"172616","work":"10062286493882945110272","slots":"11052","transientBits":"950152040"},{"p":"520","bill":"5218257","margin":"-218257","Q":"17128","primitive":"548176392704","chars":"176120","work":"64451838941170797954816","slots":"11490","transientBits":"987726308"}],"stage2":"OPEN"} */
