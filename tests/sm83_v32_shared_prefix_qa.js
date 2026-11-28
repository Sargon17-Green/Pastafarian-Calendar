// PROJECT_ID: PC-BRANCH-SM83-ASSEMBLY-GEEZ
// Host-only V32 shared-prefix factorization; no Native memory-fit claim.
// P = product C(s_i-1,r_i-1) for started nonempty prefix.
// For continuing any started label, suffix factor F(S-1,u) is common.
// Child prefix ratio at chosen nonfirst j is (r_j-1)/(s_j-1);
// later factors are (s_i-r_i)/(s_i-1). First nonempty factor is 1.
// Starting next label gets total minus all continuation blocks.
// Suffix DP streams old row in place using saved previous cell.
// Full-size benchmark is constructed early-start path, NOT actual sauce.
// stats.slots is max DP array length, not measured RSS or heap bytes.
function optimizedSuite(api){
"use strict";
const assert=(p,m)=>{if(!p)throw Error(m)},sum=a=>a.reduce((a,b)=>a+b,0);
function C(n,k){if(k<0||k>n)return 0n;k=Math.min(k,n-k);let z=1n;for(let i=1;i<=k;i++)z=z*BigInt(n-k+i)/BigInt(i);return z}
function suffix(S,L,u,stats){if(u===L.length)return 1n;let row=[0n],total=1n,has=false;
for(let j=u;j<L.length;j++){const r=L[j],T=S+r;stats.slots=Math.max(stats.slots,T+1);if(r===1){row.length=T+1;row.fill(0n);row[T]=total;has=true;S=T;continue}
let prefix=has?0n:total,z=C(T-2,r-2),nextTotal=0n,old=0n;row.length=T+1;
for(let k=1;k<=S+1;k++){if(has)prefix+=old;old=row[k]??0n;const v=prefix*z;row[k]=v;nextTotal+=v;if(k<S+1)z=z*BigInt(T-k-1-(r-2))/BigInt(T-k-1)}
row.fill(0n,S+2);total=nextTotal;has=true;S=T;stats.ops+=S-r+1;if(typeof process!=='undefined')stats.heapSampleBytes=Math.max(stats.heapSampleBytes||0,process.memoryUsage().heapUsed)}
return total}
function walk(L,rank,word=null){const R=L.map(()=>0),out=[],stats={calls:0,ops:0,slots:0};let S=0,u=0,P=1n,total=suffix(0,L,0,stats),N=total,rankOut=1n;
assert(word||rank>=1n&&rank<=total,"rank domain");
while(out.length<sum(L)){let first=R.findIndex(x=>x>0),chosen=-1,newP=0n,newN=0n;const blocks=[];let continuation=0n;
if(S){const F=suffix(S-1,L,u,stats);stats.calls++;const prefix=[];let s=0;for(let j=0;j<u;j++){s+=R[j];prefix[j]=s}
let num=1n,den=1n;
for(let j=u-1;j>=first;j--){const r=R[j],q=prefix[j];if(!r)continue;
if(r>1||j===first){let a=P*num,b=den;if(j!==first){a*=BigInt(r-1);b*=BigInt(q-1)}assert(a%b===0n,"P division");let child=a/b,n=child*F;blocks.push([j,child,n]);continuation+=n}
if(j!==first){num*=BigInt(q-r);den*=BigInt(q-1)}}
blocks.reverse()}
if(u<L.length&&(L[u]>1||S===0)){let r=L[u]-1,n=total-continuation;const p=r?P*C(S+r-1,r-1):P;blocks.push([u,p,n])}
assert(blocks.reduce((a,b)=>a+b[2],0n)===total,"partition");
for(const [j,p,n] of blocks){if(word?j===word[out.length]:rank<=n){assert(n>0n,"empty");chosen=j;newP=p;newN=n;break}if(word)rankOut+=n;else rank-=n}
assert(chosen>=0,"choice");if(chosen===u){R[u]=L[u]-1;S+=R[u];u++}else{R[chosen]--;S--}
out.push(chosen);P=newP;total=newN}
assert(total===1n&&P===1n,"terminal");return {word:out,rank:rankOut,N,stats}}
function oracle(L){let R=L.slice(),a=[],words=[];function go(){if(!sum(R)){const p=L.map((_,i)=>a.indexOf(i)),q=L.map((_,i)=>a.lastIndexOf(i));if(p.every((v,i)=>!i||p[i-1]<v)&&q.every((v,i)=>!i||q[i-1]<v))words.push(a.slice());return}for(let j=0;j<L.length;j++)if(R[j]){R[j]--;a.push(j);go();a.pop();R[j]++}}go();return words}
if(api)return {walk,suffix,oracle};
let tuples=0,words=0;function gen(a,k){if(!k){if(sum(a)>9)return;const w=oracle(a);for(let i=0;i<w.length;i++){const r=BigInt(i+1),x=walk(a,r),y=walk(a,0n,w[i]);assert(x.N===BigInt(w.length)&&x.word.join()===w[i].join()&&y.rank===r,"oracle "+a);words++}tuples++;return}for(let x=1;x<=4;x++)gen([...a,x],k-1)}
for(let m=1;m<=4;m++)gen([],m);
const large=[];for(const L of [Array(47).fill(6),[...Array(46).fill(123),120]]){const start=Date.now();const w=L.map((_,i)=>i);for(let j=0;j<L.length;j++)for(let k=1;k<L[j];k++)w.push(j);const a=walk(L,0n,w),mid=Date.now(),b=walk(L,a.rank);assert(b.word.join()===w.join(),"large word");large.push({length:sum(L),countBits:a.N.toString(2).length,rankBits:a.rank.toString(2).length,rankMs:mid-start,unrankMs:Date.now()-mid,rankStats:a.stats,unrankStats:b.stats})}
return {tuples,words,large}}
function chooseActual(L,first,step){
const {walk,suffix}=optimizedSuite(true);
if(!L.length||L.length>47||L.some(x=>!Number.isInteger(x)||x<4||x>123)||L.reduce((a,b)=>a+b,0)>5778)throw Error("length domain");
const M=(1n<<127n)-1n;
if(first<1n||first>M||![1,-1].includes(step))throw Error("flow domain");
const stats={slots:0,ops:0};const start=Date.now(),N=suffix(0,L,0,stats);
let R=M,k=1;while(R<N){R*=M;k++}
let W=1n,base=1n;
for(let j=0;j<k;j++){let digit=(first-1n+BigInt(step*j))%M;if(digit<0n)digit+=M;W+=digit*base;base*=M}
const cap=R/N*N,accepted=W<=cap?W:step===1?1n:cap;
const rank=1n+(accepted-1n)%N;
const x=walk(L,rank);
if(x.N!==N)throw Error("count mismatch");
return {count:N.toString(),rank:rank.toString(),digits:k,word:x.word,stats:x.stats,countStats:stats,elapsedMs:Date.now()-start};
}
function lateCases(){
const {walk}=optimizedSuite(true);
const cases=[];
for(const L of [Array(47).fill(6),Array(12).fill(20)]){
 const w=[];for(let block=0;block<L.length;block+=Math.ceil(L.length/2)){
 let end=Math.min(L.length,block+Math.ceil(L.length/2));
 for(let j=block;j<end;j++)w.push(j);
 for(let j=block;j<end;j++)for(let k=1;k<L[j];k++)w.push(j)}
 const start=Date.now(),a=walk(L,0n,w),b=walk(L,a.rank);
 if(b.word.join()!==w.join())throw Error("late-start roundtrip");
 cases.push({length:w.length,rankBits:a.rank.toString(2).length,rankStats:a.stats,unrankStats:b.stats,elapsedMs:Date.now()-start})
}
return cases;
}
if(typeof require!=="undefined"&&require.main===module){
 if(process.argv[2]==="--actual"){
 const q=JSON.parse(require("fs").readFileSync(0,"utf8"));
 const r=chooseActual(q.lengths,BigInt(q.first),q.step);
 r.maxRSSKiB=process.resourceUsage().maxRSS;r.heapEndBytes=process.memoryUsage().heapUsed;
 console.log(JSON.stringify(r))
 }else if(process.argv[2]==="--late"){
 const cases=lateCases();console.log(JSON.stringify({cases,maxRSSKiB:process.resourceUsage().maxRSS,heapEndBytes:process.memoryUsage().heapUsed}))
 }else console.log("HOST_V32_SHARED_PREFIX="+JSON.stringify(optimizedSuite()));
}

