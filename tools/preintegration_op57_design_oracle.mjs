// PC-BRANCH-FALSE-ARABIC | preintegration op57 design only | 2026-11-27
// Base HEAD 7f7dddc01229497aa6f86621007906fdac565e0f.
// Reference test/normative_reference.false blob 3e9acc012bedf83294a6ec3cccb081a069556b5b:
// op57 lines 447-451, op38/42/46/48/54/55/56. No production op40 implemented.
// Production src/monster_bootstrap.false blob 80ffa4428a39fe048fb9e30067e692fa493c5c24.
// Candidate op40 receives exactly TWO physically allocated tuple cells [calculationDay,targetDay]
// (no length header). Each is immutable canonical signed base512 BigInt. Proposed first gate:
// signed 64-bit days [-2^63,2^63-1], fully allocated, canonical zero/sign/limb/length validation.
// This is a proposed bounded gate, not a restriction of the normative calendar.
// Output direct [2,finalBowls,order46], each direct [6,...], final bowls in ID order;
// preserve the visible drop-46 order, never the last batch permutation.
// Production call graph: f(tuple)->counts; op24(dummy)->stones; op29([counts,stones])->hidden;
// op31([counts,stones,hidden])->visible; op37([counts])->initial;
// op38([initial,visible,stones])->[2,after46,order46]; op39([after46])->finalBowls.
// f is direct lambda (not heap op), uses unframed scratch; run before storing subsequent
// live handles, retain original input pointer in outer frame and preserve caller registers.
// op24..39 framed heap calls: complete contiguous argument cells first; use single argument
// handle with h; no untracked stack temporaries while reading g; snapshot z/k and check
// parent k, one return handle, fresh output descriptor, fresh final values and distinct
// handles, no writes to original input or intermediate records. Do not compare raw addresses
// across runs. Reference sequences are linked descriptors; compare decoded values not layouts.
// Gate plan (not executed): pin source+original interpreter eb3135565a8670cced3f6bbca4dbf7b014c45634;
// compare all 5 counts, 230 stones, 7 hidden, 46 visible, 6 initial, 6 after46, 6 order46,
// 6 final and 6 returned order values per case; compare full output limbs; input heap snapshots;
// same-process repeat with different cases and interleaved identical case; distinguish
// shape/ownership errors from numerical ones. Check bounds, sign/digit/top/zero/length malformed
// allocated BigInts and exact diagnostic + exit; unallocated pointers/truncation excluded.
// Seven design mutants below must become actual source substitutions in a later authorized
// gate, with first numeric assertion predicted independently; no invented Native expected-red.
// 2 GiB AS cap, 600 s hard cap per integrated process with watchdog and no core dump;
// first measure one full path and peak RSS/heap cells before widening, no unlimited retry;
// stop on failure and preserve exact stdout/stderr/exits, programs/source hashes, ZIP CRC and SHA.
// No full normative dependency/runtime acceptance implied by previous bounded receipts.
// Run this independent mathematical design model: node tools/preintegration_op57_design_oracle.mjs

function preintegrationOracle(){
 const M=(1n<<127n)-1n,E=-15055671n,L=(1n<<63n)-1n;
 const save=x=>{if(x<=0n)throw Error("nonpositive SAVE argument");return 1n+(x-1n)%M};
 const sum=a=>a.reduce((s,x)=>s+x,0n);
 const assert=(c,m)=>{if(!c)throw Error(m)};
 const eq=(a,b)=>JSON.stringify(a,(_,v)=>typeof v==="bigint"?v.toString():v)===JSON.stringify(b,(_,v)=>typeof v==="bigint"?v.toString():v);
 const order=rank=>{let rem=rank-1,a=[1,2,3,4,5,6],out=[];for(const f of [120,24,6,2,1,1]){let i=Math.floor(rem/f);rem%=f;out.push(a.splice(i,1)[0]);}return out};
 const rank=t=>Number((t-1n)%720n)+1;
 assert(new Set(Array.from({length:720},(_,i)=>order(i+1).join())).size===720,"rank uniqueness");
 assert(eq(order(1),[1,2,3,4,5,6])&&eq(order(720),[6,5,4,3,2,1]),"rank endpoints");
 const hiddenC=[[3,4,6,8],[5,7,10,12],[7,10,14,16],[9,13,18,20],[11,16,22,24],[13,19,26,28],[15,22,30,32]].map(a=>a.map(BigInt));
 const grind=[[3,5,7,11,1],[5,7,11,13,2],[7,11,13,17,3],[11,13,17,19,4],[13,17,19,23,5],[17,19,23,29,1],[19,23,29,31,2],[23,29,31,37,3],[29,31,37,41,4],[31,37,41,43,5],[37,41,43,47,1]].map(a=>a.map(BigInt));
 const stones=[[17n,29n,43n,71n,101n]];
 for(let i=2;i<=46;i++){let [a,b,c,d,e]=stones.at(-1);stones.push([a*a+3n*b+BigInt(i),b*b+5n*c+a,c*c+7n*d+b,d*d+11n*e+c,e*e+13n*a+d].map(save))}
 function solve(c,t,mut=""){
  const epoch=mut==="old_epoch"?-E:E;
  const dc=x=>x>=epoch?2n*(x-epoch)+1n:2n*(epoch-x);
  const C=dc(c),T=dc(t),D=(t>=c?t-c:c-t)+1n,S=C+T;
  const sign=t<c?-1:t>c?1:0;
  const q=BigInt(mut==="old_direction"?(sign<0?3:sign===0?1:2):2+sign);
  const counts=[C,T,D,S,q],hidden=[],visible=[];
  for(let i=0;i<7;i++){
   let v=save(C+sum(hiddenC[i].map((k,j)=>k*counts[j+1]))+sum(stones[i]));
   for(let j=0;j<7;j++)v=save(v*v+3n*v+stones[i][j%5]+BigInt(j+1));
   hidden.push(v);
  }
  for(let i=0;i<46;i++){
   const pred=b=>i-b>=0?visible[i-b]:hidden[b-i-1];
   const [a,b,d]=[pred(1),pred(3),pred(7)];
   let v=save(sum(stones[i].map((s,j)=>s*counts[j]))+a+3n*b+5n*d+BigInt(i+1));
   for(const [j,k,l,m,n] of grind)v=save(v*v+j*v+k*a+l*b+m*d+stones[i][Number(n)-1]);
   visible.push(v);
  }
  const initial=[17n,19n,23n,29n,31n,37n].map((x,i)=>save(C+BigInt(i+1)*T+D+S+q+x*x+BigInt(i+1)));
  let bowls=initial.slice(),order46,lastBatch;
  for(let i=0;i<46;i++){
   const t=visible[i],o=order(rank(t)),u=BigInt(i+1),old=bowls;
   bowls=old.map((x,j)=>{let p=o.indexOf(j+1),P=BigInt(p+1),left=old[o[(p+5)%6]-1],right=old[o[(p+1)%6]-1];
   const aux=p<3?save(t*t+x*stones[i][p]+u*(2n*P+1n)):mut==="old_aux"?2n:0n;
   return save(x*x+2n*left+3n*right+aux+t+stones[i][p%5]+5n*left*right+u*P)});
   order46=o;
  }
  const after46=bowls.slice();
  for(let i=1;i<=12;i++){
   const u=BigInt(i),t=save(sum(bowls)+149n*u+(mut==="old_offset"?6n:0n));let r=mut==="old_rank"?Number(((t-4n)%7n+7n)%7n)+4:rank(t);
   if(mut==="truncated_rank")r=1+(r-1)%512;
   const o=order(r),old=bowls;
   bowls=old.map((x,j)=>{let p=o.indexOf(j+1),P=BigInt(p+1),left=old[o[(p+5)%6]-1],right=old[o[(p+1)%6]-1];return save(x*x+3n*left+5n*right+t+u+P*P+7n*left*right)});
   lastBatch=o;
  }
  assert([...stones.flat(),...hidden,...visible,...initial,...after46,...bowls].every(x=>x>=1n&&x<=M),"SAVE range");
  return {counts,hidden,visible,initial,after46,order46,finalBowls:bowls,returnOrder:mut==="wrong_order"?lastBatch:order46,lastBatch};
 }
 const pairs=[[E,E],[E-1n,E],[E,E-1n],[E+1n,E],[E,E+1n],[0n,0n],[0n,1n],[1n,0n],[-1n,1n],[1n,-1n],[E-512n,E+513n],[E+513n,E-512n],[-L,L],[L,-L],[L,L],[-L,-L]];
 let seed=20261127n; const rnd=()=>{seed=(6364136223846793005n*seed+1442695040888963407n)&((1n<<64n)-1n);return seed-L-1n};
 for(let i=0;i<32;i++){let c=rnd(),t=rnd();pairs.push([c,t])}
 const baseline=pairs.map(([c,t])=>solve(c,t));
 assert(eq(baseline[0].counts,[1n,1n,1n,2n,2n]),"epoch equal");
 assert(eq(baseline[1].counts,[2n,1n,2n,3n,3n]),"epoch earlier");
 assert(eq(baseline[2].counts,[1n,2n,2n,3n,1n]),"epoch later");
 assert(eq(solve(...pairs[0]),baseline[0]),"replay");
 const mutants={};for(const m of ["old_epoch","old_direction","old_aux","old_offset","old_rank","truncated_rank","wrong_order"]){let i=baseline.findIndex((b,j)=>{let w=solve(...pairs[j],m);return !eq([b.finalBowls,b.returnOrder],[w.finalBowls,w.returnOrder])});assert(i>=0,"no output witness for "+m);mutants[m]={case:i,pair:pairs[i],expected:[baseline[i].finalBowls,baseline[i].returnOrder],wrong:(()=>{let w=solve(...pairs[i],m);return [w.finalBowls,w.returnOrder]})()}}
 return {scope:"mathematical design oracle only, no FALSE execution or acceptance",source:"7f7dddc01229497aa6f86621007906fdac565e0f",referenceBlob:"3e9acc012bedf83294a6ec3cccb081a069556b5b",productionBlob:"80ffa4428a39fe048fb9e30067e692fa493c5c24",caseCount:pairs.length,permutationRanks:720,visibleRounds:pairs.length*46,batches:pairs.length*12,finalFields:pairs.length*12,mutants,stones,records:pairs.map((p,i)=>({pair:p,...baseline[i]}))};
}
console.log(JSON.stringify(preintegrationOracle(),(_,v)=>typeof v==='bigint'?v.toString():v,2));
