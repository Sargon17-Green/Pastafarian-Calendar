// PROJECT_ID: PC-BRANCH-SM83-ASSEMBLY-GEEZ
// Host-only certified nonnegative dyadic intervals for V32 column counts.
// [lo,hi]*2^e, integer endpoints, outward rounding at every operation.
// Threshold test returns UNKNOWN for overlap; never approximate acceptance.
// Does NOT solve exact initial N/rank, accumulated rank subtraction, or Native fit.
function intervalSuite(prior){
"use strict";
const bits=n=>n===0n?0:n.toString(2).length;
const ceil=(a,b)=>(a+b-1n)/b;
const exact=(n)=>({lo:BigInt(n),hi:BigInt(n),e:0});
function engine(p){
 const norm=(lo,hi,e)=>{let d=Math.max(0,bits(hi)-p);if(d){const q=1n<<BigInt(d);lo/=q;hi=ceil(hi,q);e+=d;if(bits(hi)>p){lo/=2n;hi=ceil(hi,2n);e++}}return {lo,hi,e}};
 const add=(a,b)=>{if(!a.hi)return b;if(!b.hi)return a;const e=Math.max(a.e,b.e),q=1n<<BigInt(e-a.e),r=1n<<BigInt(e-b.e);return norm(a.lo/q+b.lo/r,ceil(a.hi,q)+ceil(b.hi,r),e)};
 const mul=(a,b)=>norm(a.lo*b.lo,a.hi*b.hi,a.e+b.e);
 const ratio=(a,n,d)=>{n=BigInt(n);d=BigInt(d);return norm(a.lo*n/d,ceil(a.hi*n,d),a.e)};
 // Binomial recurrence is exact over rationals; endpoints are rounded outward.
 const choose=(n,k)=>{if(k<0||k>n)return exact(0);k=Math.min(k,n-k);let z=exact(1);for(let i=1;i<=k;i++)z=ratio(z,n-k+i,i);return z};
 function count(S,L,u=0){let T=S,ops=0,rows=[];for(let j=u;j<L.length;j++){const r=L[j];rows.push({s:T,t:T+r,r,a:exact(0),z:r===1?exact(0):choose(T+r-2,r-2)});T+=r}
 if(!rows.length)return {v:exact(1),ops,slots:0};
 for(let k=1;k<=T;k++)for(let j=rows.length-1;j>=0;j--){const x=rows[j],pred=j?rows[j-1].a:exact(1);
 if(x.r===1){if(k===x.t)x.a=add(x.a,pred)}
 else if(k<=x.s+1){x.a=add(x.a,mul(pred,x.z));ops++;if(k<x.s+1)x.z=ratio(x.z,x.s+1-k,x.t-1-k)}}
 return {v:rows.at(-1).a,ops,slots:2*rows.length}}
 return {count}
}
const bounds=v=>[v.lo<<BigInt(v.e),v.hi<<BigInt(v.e)];
const classify=(v,t)=>{const [lo,hi]=bounds(v);return t<=lo?"LE":t>hi?"GT":"UNKNOWN"};
const check=(x,m)=>{if(!x)throw Error(m)};
let checks=0,unknown=0,decided=0;
const e=engine(64);
for(let m=1;m<=4;m++){function gen(L){if(L.length<m){for(let r=1;r<=5;r++)gen([...L,r]);return}for(let S=0;S<=8;S++){const n=prior.suffix(S,L,0,{slots:0,ops:0}),x=e.count(S,L),[lo,hi]=bounds(x.v);check(lo<=n&&n<=hi,"containment");for(const t of [0n,n/2n,n,n+1n,n*2n+1n]){const c=classify(x.v,t);if(c==="UNKNOWN")unknown++;else{check((c==="LE")===(t<=n),"threshold");decided++}}checks++}}gen([])}
const large=[];
for(const L of [Array(47).fill(6),[...Array(46).fill(123),120]]){const n=prior.suffix(0,L,0,{slots:0,ops:0});let measurements=[];for(const p of [32,64,96]){let start=Date.now(),x=engine(p).count(0,L),ms=Date.now()-start,[lo,hi]=bounds(x.v);check(lo<=n&&n<=hi,"large containment");const probes=[n/2n,n-n/1000n,n,n+1n,n+n/1000n,n*2n].map(t=>{const c=classify(x.v,t);if(c!=="UNKNOWN")check((c==="LE")===(t<=n),"large threshold");return c});measurements.push({p,ms,ops:x.ops,slots:x.slots,relativeWidthCeilPPQ:ceil((hi-lo)*1000000000000000n,n).toString(),probes,rawBytes:x.slots*(2*Math.ceil(p/8)+2)})}large.push({length:L.reduce((a,b)=>a+b,0),bits:bits(n),measurements})}
return {checks,decided,unknown,large};
}
if(typeof require!=="undefined"&&require.main===module){
 const fs=require("fs"),path=require("path");
 const prior=new Function(fs.readFileSync(path.join(__dirname,"sm83_v32_shared_prefix_qa.js"),"utf8")+"\nreturn optimizedSuite(true);")();
 console.log("HOST_V32_INTERVAL_COUNT="+JSON.stringify(intervalSuite(prior)));
}
