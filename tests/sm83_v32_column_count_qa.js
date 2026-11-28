// PROJECT_ID: PC-BRANCH-SM83-ASSEMBLY-GEEZ
// Host QA only. D_j(k)=C(T_j-k-1,r_j-2)*sum_{p<k}D_{j-1}(p).
// Sweep k ascending, j descending so the predecessor accumulator is
// strictly before k. r=1 has only a spike at k=T_j.
// Two persistent BigInts per label, plus temporaries; O(mL) arithmetic.
// rawBytes is sum of maximum per-register unsigned byte widths, NOT
// measured peak heap/RSS and NOT a simultaneous live byte measurement.
// The accumulators alone require 82482 bytes for 46*123+120 at completion.
// This representation cannot fit even the entire 32KiB cartridge SRAM.
// A modular alternative needs enough coprime primes for exact reconstruction:
// with 16-bit primes >=32768, ceil(32095/15)=2140 primes suffice for the
// conservative count bit bound; 2140*133010=284641400 product iterations
// for the full-size example alone, excluding coefficient update, inversion,
// CRT and repeated prefix queries. No Native feasibility claim.
function columnCount(S,L,u=0){
 const C=(n,k)=>{if(k<0||k>n)return 0n;k=Math.min(k,n-k);let v=1n;for(let i=1;i<=k;i++)v=v*BigInt(n-k+i)/BigInt(i);return v};
 const bits=x=>x===0n?0:x.toString(2).length;
 const rows=[];let t=S;
 for(let j=u;j<L.length;j++){let r=L[j];rows.push({s:t,t:t+r,r,a:0n,z:r===1?0n:C(t+r-2,r-2),maxZ:0});t+=r;}
 if(!rows.length)return {count:1n,ops:0,slots:0,rawBytes:0,maxProductBits:0};
 let ops=0,maxProductBits=0;
 for(let k=1;k<=t;k++)for(let j=rows.length-1;j>=0;j--){
 const x=rows[j];let v=0n;const p=j?rows[j-1].a:1n;
 if(x.r===1){if(k===x.t)v=p;}
 else if(k<=x.s+1){
 v=p*x.z;ops++;
 x.maxZ=Math.max(x.maxZ,bits(x.z));maxProductBits=Math.max(maxProductBits,bits(v));
 if(k<x.s+1)x.z=x.z*BigInt(x.s+1-k)/BigInt(x.t-1-k);
 }
 x.a+=v;
 }
 const rawBytes=rows.reduce((s,x)=>s+Math.ceil(bits(x.a)/8)+Math.ceil(x.maxZ/8),0);
 return {count:rows.at(-1).a,ops,slots:2*rows.length,rawBytes,maxProductBits,accBytes:rows.reduce((s,x)=>s+Math.ceil(bits(x.a)/8),0),coefBytes:rows.reduce((s,x)=>s+Math.ceil(x.maxZ/8),0)};
}
function suite(prior,columnCount){
 const start=Date.now();let checks=0;for(let m=1;m<=4;m++){function gen(l){if(l.length<m){for(let r=1;r<=5;r++)gen([...l,r]);return}for(let S=0;S<=8;S++){const x=columnCount(S,l),y=prior.suffix(S,l,0,{slots:0,ops:0});if(x.count!==y)throw Error(JSON.stringify({S,l,x:x.count.toString(),y:y.toString()}));checks++}}gen([])}
 const large=[];for(const L of [Array(47).fill(6),[...Array(46).fill(123),120]]){let t=Date.now(),x=columnCount(0,L),ms=Date.now()-t,y=prior.suffix(0,L,0,{slots:0,ops:0});if(x.count!==y)throw Error("large");large.push({...x,count:x.count.toString(2).length,ms,length:L.reduce((a,b)=>a+b,0)})}
 return {checks,elapsed:Date.now()-start,large};
}
if(typeof require!=="undefined" && require.main===module){
 const fs=require("fs"),path=require("path");
 const src=fs.readFileSync(path.join(__dirname,"sm83_v32_shared_prefix_qa.js"),"utf8");
 const prior=new Function(src+"\nreturn optimizedSuite(true);")();
 console.log("HOST_V32_COLUMN_COUNT="+JSON.stringify(suite(prior,columnCount)));
}
