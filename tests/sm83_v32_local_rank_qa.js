// PROJECT_ID: PC-BRANCH-SM83-ASSEMBLY-GEEZ
// Host-only local residual rank certification with exact lazy deduction ledger.
// Bounds are full-width integer endpoints: no Native storage fit is claimed.
// Rebase only skipped cumulative blocks; never restart the certified prefix.
function localSuite(prior){
"use strict";
const assert=(q,m)=>{if(!q)throw Error(m)}, sum=a=>a.reduce((x,y)=>x+y,0);
const bits=n=>n===0n?0:n.toString(2).length, ceil=(a,b)=>(a+b-1n)/b;
function C(n,k){if(k<0||k>n)return 0n;k=Math.min(k,n-k);let z=1n;for(let i=1;i<=k;i++)z=z*BigInt(n-k+i)/BigInt(i);return z}
function engine(p){
 const norm=(lo,hi,e=0)=>{let d=Math.max(0,bits(hi)-p);while(d){const q=1n<<BigInt(d);lo/=q;hi=ceil(hi,q);e+=d;d=Math.max(0,bits(hi)-p)}return {lo,hi,e}};
 const exact=n=>norm(BigInt(n),BigInt(n));
 const add=(a,b)=>{if(!a.hi)return b;if(!b.hi)return a;const e=Math.max(a.e,b.e),q=1n<<BigInt(e-a.e),r=1n<<BigInt(e-b.e);return norm(a.lo/q+b.lo/r,ceil(a.hi,q)+ceil(b.hi,r),e)};
 const mul=(a,b)=>norm(a.lo*b.lo,a.hi*b.hi,a.e+b.e);
 const ratio=(a,n,d)=>norm(a.lo*BigInt(n)/BigInt(d),ceil(a.hi*BigInt(n),BigInt(d)),a.e);
 const choose=(n,k)=>{k=Math.min(k,n-k);let z=exact(1);for(let i=1;i<=k;i++)z=ratio(z,n-k+i,i);return z};
 function count(S,L,u,stats){let T=S,rows=[];for(let j=u;j<L.length;j++){const r=L[j];rows.push({s:T,t:T+r,r,a:exact(0),z:r===1?exact(0):choose(T+r-2,r-2)});T+=r}
 stats.slots=Math.max(stats.slots,2*rows.length);stats.calls++;
 if(!rows.length)return exact(1);
 for(let k=1;k<=T;k++)for(let j=rows.length-1;j>=0;j--){const x=rows[j],pred=j?rows[j-1].a:exact(1);
 if(x.r===1){if(k===x.t)x.a=add(x.a,pred)}
 else if(k<=x.s+1){x.a=add(x.a,mul(pred,x.z));stats.ops++;if(k<x.s+1)x.z=ratio(x.z,x.s+1-k,x.t-1-k)}}
 return rows.at(-1).a}
 return {exact,add,mul,count,bounds:v=>[v.lo<<BigInt(v.e),v.hi<<BigInt(v.e)]};
}
function ring(N,first,step,M=(1n<<127n)-1n){assert(N>=1n&&first>=1n&&first<=M&&[1,-1].includes(step),"ring input");let R=M,k=1;while(R<N){R*=M;k++}let W=1n,b=1n;for(let j=0;j<k;j++){let d=(first-1n+BigInt(step*j))%M;if(d<0n)d+=M;W+=d*b;b*=M}const cap=R/N*N,accepted=W<=cap?W:step===1?1n:cap;return {rank:1n+(accepted-1n)%N,k,W,cap,R}}

function local(L,rank,N,p,period=32){
 const E=engine(p),R=L.map(()=>0),out=[],ledger=[];
 const stats={calls:0,ops:0,slots:0,exactOps:0,exactCalls:0,rebases:0,overlaps:0,maxLedger:0,maxLedgerBits:0,maxRankBits:bits(rank)};
 let P=1n,S=0,u=0,anchor=rank,lo=rank,hi=rank,ledgerBits=0;
 assert(rank>=1n&&rank<=N&&period>=1,"domain");
 function exactF(s,v){const x={ops:0,slots:0};const f=prior.suffix(s,L,v,x);stats.exactCalls++;stats.exactOps+=x.ops;return f}
 function rebase(){if(!ledger.length)return;for(const [s,v,c] of ledger)anchor-=c*exactF(s,v);
 assert(anchor>=lo&&anchor<=hi&&anchor>=1n,"rebase containment");lo=hi=anchor;ledger.length=0;ledgerBits=0;stats.rebases++}
 while(out.length<sum(L)){
 const first=R.findIndex(x=>x>0),blocks=[],prefix=[];let s=0,num=1n,den=1n;
 for(let j=0;j<u;j++){s+=R[j];prefix[j]=s}
 for(let j=u-1;j>=first&&j>=0;j--){const r=R[j],q=prefix[j];if(!r)continue;if(r>1||j===first){let a=P*num,b=den;if(j!==first){a*=BigInt(r-1);b*=BigInt(q-1)}assert(a%b===0n,"ratio");blocks.push([j,a/b])}if(j!==first){num*=BigInt(q-r);den*=BigInt(q-1)}}
 blocks.reverse();if(u<L.length&&(L[u]>1||S===0)){const r=L[u]-1;blocks.push([u,r?P*C(S+r-1,r-1):P])}
 assert(blocks.length,"empty choice");let chosen=blocks.at(-1),skip=0n,skipLo=0n,skipHi=0n,fExact=null;
 if(blocks.length>1){
 const F=E.count(S-1,L,u,stats);let cum=0n;
 for(let i=0;i<blocks.length-1;i++){
 cum+=blocks[i][1];let [a,b]=fExact===null?E.bounds(E.mul(E.exact(cum),F)):[cum*fExact,cum*fExact];
 if(hi<=a){chosen=blocks[i];break}
 if(lo<=b){stats.overlaps++;rebase();fExact=exactF(S-1,u);a=b=cum*fExact;
 // Previous boundary was certified; use its exact value after rebasing.
 skipLo=skipHi=skip*fExact;
 if(hi<=a){chosen=blocks[i];break}assert(lo>b,"exact comparison")}
 skip=cum;skipLo=a;skipHi=b;
 }
 if(skip){
 if(fExact!==null){assert(ledger.length===0&&lo===hi,"exact residual");anchor-=skipLo;lo=hi=anchor}
 else {lo=lo>skipHi?lo-skipHi:1n;hi-=skipLo;ledger.push([S-1,u,skip]);ledgerBits+=bits(skip);stats.maxLedger=Math.max(stats.maxLedger,ledger.length);stats.maxLedgerBits=Math.max(stats.maxLedgerBits,ledgerBits)}
 assert(lo>=1n&&lo<=hi,"residual interval");if(ledger.length>=period)rebase();
 }}
 const [j,nextP]=chosen;P=nextP;if(j===u){R[u]=L[u]-1;S+=R[u];u++}else{R[j]--;S--}out.push(j)
 }
 rebase();assert(anchor===1n&&P===1n,"terminal residual");return {word:out,stats}
}
let checks=0,tuples=0,overlaps=0,rebases=0;
function gen(L,m){if(m){for(let r=1;r<=4;r++)gen([...L,r],m-1);return}if(sum(L)>9)return;const words=prior.oracle(L),N=BigInt(words.length);for(let i=0;i<words.length;i++)for(const p of [3,8,64]){const x=local(L,BigInt(i+1),N,p,8);assert(x.word.join()===words[i].join(),"enumeration");checks++;overlaps+=x.stats.overlaps;rebases+=x.stats.rebases}tuples++}
for(let m=1;m<=4;m++)gen([],m);
const measured=[];
for(const L of [Array(47).fill(6),Array(12).fill(20)]){
 const ns={ops:0,slots:0},N=prior.suffix(0,L,0,ns),rr=ring(N,((1n<<127n)-1n)/3n,1);
 for(const [kind,r] of [["ring",rr.rank],["first",1n],["last",N],["middle",N/2n]]){
 const t=Date.now(),x=local(L,r,N,64);const ms=Date.now()-t,ref=prior.walk(L,r);assert(x.word.join()===ref.word.join(),"whole word");measured.push({length:sum(L),kind,countBits:bits(N),initialCountOps:ns.ops,ringDigits:rr.k,ms,...x.stats,referenceOps:ref.stats.ops})}
}
return {checks,tuples,overlaps,rebases,measured};
}
if(typeof require!=="undefined"&&require.main===module){
 const fs=require("fs"),path=require("path"),prior=new Function(fs.readFileSync(path.join(__dirname,"sm83_v32_shared_prefix_qa.js"),"utf8")+"\nreturn optimizedSuite(true);")();
 console.log("HOST_V32_LOCAL_RANK="+JSON.stringify(localSuite(prior)));
}
