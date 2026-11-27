#!/usr/bin/env node
// Test-only independent host oracle; not SystemVerilog and not production.
// Normative Scroll: 56bc4173aae4975ded019ef5ab5a36249f1424df README.md blob 74c424b44eadd4ece3f29072ddbf873236557604 (sections A–U, W, AC.1).
// Exact BigInt selection and month composition; no H/weave reconstruction yet.
// Run bounded: timeout 120s node --max-old-space-size=512 scripts/stage1_multivector_partial_oracle.js
// Scope: +/-50000 days from Foundation; gate index <=1400; wider inputs fail closed.
'use strict';
const M=(1n<<127n)-1n, F=-15055671;
function save(x){return 1n+((x-1n)%M+M)%M}
function day(d){const x=BigInt(d)-BigInt(F);return x>=0n?2n*x+1n:-2n*x}
function perm(n,k,r){let a=Array.from({length:n},(_,i)=>i+1),out=[];for(let j=0;j<k;j++){let b=1n;for(let i=1;i<k-j;i++)b*=BigInt(n-j-i);let q=(r-1n)/b;r=(r-1n)%b+1n;out.push(a.splice(Number(q),1)[0])}return out}
function sauce(c,t){
 const vals=[day(c),day(t),BigInt(Math.abs(t-c))+1n,day(c)+day(t),BigInt(t<c?1:t===c?2:3)];
 let stones=[[17n,29n,43n,71n,101n]];
 for(let i=2;i<=46;i++){let [a,b,e,d,f]=stones.at(-1);stones.push([save(a*a+3n*b+BigInt(i)),save(b*b+5n*e+a),save(e*e+7n*d+b),save(d*d+11n*f+e),save(f*f+13n*a+d)])}
 let ds=new Map();for(let k=1;k<=7;k++){const st=stones[k-1], [a,b,e,d,f]=vals;let x=save(a+BigInt(2*k+1)*b+BigInt(3*k+1)*e+BigInt(4*k+2)*d+BigInt(4*k+4)*f+st.reduce((p,q)=>p+q,0n));for(let r=1;r<=7;r++)x=save(x*x+3n*x+st[(r-1)%5]+BigInt(r));ds.set(1-k,x)}
 let Q=[17n,19n,23n,29n,31n,37n].map((p,i)=>{let b=BigInt(i+1),s=vals[0]+b*vals[1]+vals[2]+vals[3]+vals[4]+p*p;return save(s*s+b)}),order;
 const primes=[3n,5n,7n,11n,13n,17n,19n,23n,29n,31n,37n,41n,43n,47n];
 for(let i=1;i<=46;i++){const st=stones[i-1],p=ds.get(i-1),q=ds.get(i-3),r=ds.get(i-7);let x=save(st.reduce((a,b,j)=>a+b*vals[j],0n)+p+3n*q+5n*r+BigInt(i));for(let j=0;j<11;j++)x=save(x*x+primes[j]*x+primes[j+1]*p+primes[j+2]*q+primes[j+3]*r+st[j%5]);ds.set(i,x);order=perm(6,6,(x-1n)%720n+1n);let old=Q.slice();for(let j=0;j<6;j++){let b=order[j]-1,P=old[order[(j+5)%6]-1],N=old[order[(j+1)%6]-1],pour=j<3?save(x*x+st[j]*old[b]+BigInt((2*j+3)*i)):0n,u=old[b]+2n*P+3n*N+pour+x+st[j%5];Q[b]=save(u*u+5n*P*N+BigInt(i*(j+1)))}}
 for(let r=1;r<=12;r++){let old=Q.slice(),s=save(old.reduce((a,b)=>a+b,0n)+149n*BigInt(r)),o=perm(6,6,(s-1n)%720n+1n);for(let j=0;j<6;j++){let b=o[j]-1,P=old[o[(j+5)%6]-1],N=old[o[(j+1)%6]-1],u=old[b]+3n*P+5n*N+s+BigInt(r+(j+1)**2);Q[b]=save(u*u+7n*P*N)}}
 return {Q,order}
}
function choose(s,b,z,n){if(n<1n)throw Error("empty choice");let {Q,order}=s;let a=save((Q[b-1]+BigInt(z)+181n)**2n+179n*Q[order[(order.indexOf(b)+1)%6]-1]+BigInt(z));let d=save((a+BigInt(z)+194n)**2n+193n*a+197n*Q[5])%2n?1n:-1n;let domain=M,w=a,p=M,j=1n;while(domain<n){w+=(save(a+d*j)-1n)*p;p*=M;domain*=M;j++}let lim=domain/n*n;if(w>lim)w=d===1n?1n:lim;return (w-1n)%n+1n}
function check(b,msg){if(!b)throw Error(msg)}
function compositions(G,K,boundary){const memo=new Map();function count(left,k,used){if(k===0)return left===0&&(boundary===null||used)?1n:0n;const key=[left,k,used].join();if(memo.has(key))return memo.get(key);let total=0n;for(let x=1;x<=left-k+1;x++){let pos=G-left+x;if(boundary!==null&&!used&&pos>boundary)break;total+=count(left-x,k-1,used||pos===boundary)}memo.set(key,total);return total}return {total:count(G,K,false),unrank(rank){let left=G,k=K,used=false,out=[];while(k){let found=false;for(let x=1;x<=left-k+1;x++){let pos=G-left+x;if(boundary!==null&&!used&&pos>boundary)break;let hit=used||pos===boundary,b=count(left-x,k-1,hit);if(rank>b)rank-=b;else{out.push(x);left-=x;k--;used=hit;found=true;break}}check(found,"cutlet rank");}return out}}}
function oracle(c,t,cache){
 check(Number.isSafeInteger(c)&&Number.isSafeInteger(t)&&Math.abs(c-F)<=50000&&Math.abs(t-F)<=50000,"bounded domain");
 let gate=(i)=>{check(Math.abs(i)<=1400,"gate cap");if(!cache.has(i)){let sign=Math.sign(i),prev=gate(i-sign),gap=41+Number(choose(sauce(F,F+i),1,1,922n));cache.set(i,prev+sign*gap)}return cache.get(i)};
 let index=0;while(gate(index)<c)index++;while(gate(index-1)>=c)index--;
 let candidates=[];for(let i=index-1;gate(i)>=c-5778;i--)for(let j=Math.max(index,i+6);gate(j)-gate(i)<=5778;j++)candidates.push([i,j]);
 candidates.sort((a,b)=>(gate(a[1])-gate(a[0]))-(gate(b[1])-gate(b[0]))||a[0]-b[0]);
 let [i,j]=candidates[Number(choose(sauce(c,c),1,10,BigInt(candidates.length)))-1],year=5000;
 while(t>gate(j)){let v=[];for(let k=j+6;gate(k)-gate(j)<=5778;k++)v.push(k);let k=v[Number(choose(sauce(c,gate(j)),1,11,BigInt(v.length)))-1];i=j;j=k;year++}
 while(t<=gate(i)){let v=[];for(let k=i-6;gate(i)-gate(k)<=5778;k--)v.push(k);let k=v[Number(choose(sauce(c,gate(i)),1,12,BigInt(v.length)))-1];j=i;i=k;year--}
 let s=sauce(c,gate(i)+1),G=j-i,K=5+Number(choose(s,2,20,BigInt(Math.min(17,G)-5))),boundary=null;for(let k=i+1;k<j;k++)if(gate(k)===c)boundary=k-i;
 let co=compositions(G,K,boundary),parts=co.unrank(choose(s,2,21,co.total)),names=perm(17,K,choose(s,5,22,Array.from({length:K},(_,i)=>BigInt(17-i)).reduce((a,b)=>a*b,1n)));
 let k=i,cut;for(let p=0;p<K;p++){let end=k+parts[p];if(gate(k)<t&&t<=gate(end)){cut=[year,names[p],t-gate(k)];break}k=end}
 check(cut,"cutlet missing");
 let L=gate(j)-gate(i),min=Math.ceil(L/123),max=Math.min(47,Math.floor(L/4)),m=min-1+Number(choose(s,3,30,BigInt(max-min+1))),dp=[Array(L+1).fill(0n)];dp[0][0]=1n;
 for(let k=1;k<=m;k++){let row=Array(L+1).fill(0n),v=0n;for(let n=0;n<=L;n++){if(n>=4)v+=dp[k-1][n-4];if(n>=124)v-=dp[k-1][n-124];row[n]=v}dp.push(row)}
 let rank=choose(s,3,31,dp[m][L]),lengths=[],left=L;for(let k=m;k>0;k--){let found=false;for(let x=4;x<=Math.min(123,left);x++){let b=dp[k-1][left-x];if(rank>b)rank-=b;else{lengths.push(x);left-=x;found=true;break}}check(found,"month length rank")}
 let monthNames=perm(47,m,choose(s,5,33,Array.from({length:m},(_,i)=>BigInt(47-i)).reduce((a,b)=>a*b,1n)));
 check(left===0&&rank===1n,"composition residual");return {cut,open:gate(i),close:gate(j),m,lengths,monthNames,position:t-gate(i)}
}
const vectors=[[-15055671,-15055671,5000,10,503],[-15055671,-15055672,5000,10,502],[-15055671,-15055670,5000,14,1],[-15055671,-15056171,5000,10,3],[-15055671,-15055171,5000,14,500],[-15055671,-15061671,4999,5,158],[-15055671,-15049671,5001,12,95],[-15056905,-15056448,5000,9,167],[-15054437,-15053449,5000,14,10],[-15058171,-15053171,5002,5,288]];
const FOUNDATION_LENGTHS=[115,108,119,109,106,81,115,114,117,120,98,52,81,97,121,97,115,96,107,61,106,115,119,39,84,103,115,107,55,119,97,50,122,110,81,54,101,83,88,40,25,77,98,122,105];
const FOUNDATION_NAMES=[18,14,37,28,24,42,6,20,19,41,16,39,25,1,9,38,3,46,27,40,12,43,35,32,29,10,44,36,23,17,33,5,30,15,11,45,8,4,7,31,34,22,13,2,26];
function selfTest(log){
 let cache=new Map([[0,F]]);for(const [c,t,...expected] of vectors){let o=oracle(c,t,cache);check(o.cut.join()==expected.join(),"vector "+c+","+t+" got "+o.cut+" expected "+expected);check(o.open<t&&t<=o.close,"year bounds");check(o.lengths.length===o.m&&o.lengths.every(x=>x>=4&&x<=123)&&o.lengths.reduce((a,b)=>a+b,0)===o.close-o.open,"month composition");check(new Set(o.monthNames).size===o.m&&o.monthNames.every(x=>x>=1&&x<=47),"name range");log(JSON.stringify({c,t,...o,scope:"THREE_FIELDS_ONLY"}))}
 let f=oracle(F,F,cache);check(f.open===-15057703&&f.close===-15053459&&f.m===45,"Foundation geometry");check(f.lengths.join()===FOUNDATION_LENGTHS.join()&&f.monthNames.join()===FOUNDATION_NAMES.join(),"Foundation independent CSV");
 for(const [t,y] of [[f.open,4999],[f.open+1,5000],[f.close,5000],[f.close+1,5001]])check(oracle(F,t,cache).cut[0]===y,"boundary "+t);
 let rejected=false;try{oracle(F,F+50001,cache)}catch(e){rejected=e.message==="bounded domain"}check(rejected,"domain fail closed");
 log("HOST_ORACLE_PARTIAL_PASS canonical_three_fields=30/30 foundation_lengths=45/45 foundation_names=45/45 boundaries=4/4 domain_rejection=1/1 WEAVE_NOT_IMPLEMENTED");
}
selfTest(console.log);
