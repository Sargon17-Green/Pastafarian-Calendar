#!/usr/bin/env node
// Test-only independent host oracle; not SystemVerilog and not production.
// Normative Scroll: 56bc4173aae4975ded019ef5ab5a36249f1424df README.md blob 74c424b44eadd4ece3f29072ddbf873236557604 (sections A–U, W, AC.1).
// Exact BigInt selection, month composition and generalized H/lex weave.
// Run bounded: timeout 120s node --max-old-space-size=512 scripts/stage1_multivector_full_oracle.js
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


/* Section V: exact suffix insertion counts, generalized to arbitrary valid lengths.
 A(r)=product C(prefix-1,r_i-1), zero unless exhausted labels form a prefix.
 H_s(N)=sum_{n=0}^N C(n+v-2,n) H_{s+1}(n+v-1).
 Old child blocks share H_s(N-1); use exact rational ratios of A. */
function div(a,b){check(b>0n&&a%b===0n,"nonintegral count");return a/b}
function binom(n,k){if(k<0||k>n)return 0n;k=Math.min(k,n-k);let b=1n;for(let j=1;j<=k;j++)b=div(b*BigInt(n-k+j),BigInt(j));return b}
function transfer(l){
 let m=l.length,L=l.reduce((a,b)=>a+b,0);
 check(m>=1&&m<=47&&L<=5778&&l.every(x=>Number.isInteger(x)&&x>=2&&x<=123),"weave domain");
 let max=[0];for(let v of l)max.push(max.at(-1)+v-1);
 check(max.slice(1).reduce((a,b)=>a+b+1,0)<=140000,"H cell cap");
 let H=Array(m+1);H[m]=Array(max[m]+1).fill(1n);
 for(let s=m-1;s>=1;s--){let v=l[s],row=[],b=1n,sum=0n;for(let n=0;n<=max[s];n++){if(n)b=div(b*BigInt(n+v-2),BigInt(n));sum+=b*H[s+1][n+v-1];row.push(sum)}H[s]=row}
 return H
}
function childCounts(r,A){
 let p=[],n=0,first=r.findIndex(x=>x>0);for(let v of r){n+=v;p.push(n)}
 let num=1n,den=1n,out=Array(r.length).fill(0n);
 for(let i=r.length-1;i>=first&&first>=0;i--){let v=r[i],P=p[i];check(v>0,"non-leading zero");if(i===first)out[i]=div(A*num,den);else if(v>1)out[i]=div(A*num*BigInt(v-1),den*BigInt(P-1));if(i>first){num*=BigInt(P-v);den*=BigInt(P-1)}}
 check(out.reduce((a,b)=>a+b,0n)===(first<0?0n:A),"old partition");return out
}
function unrankWeave(l,H,rank){
 let m=l.length,L=l.reduce((a,b)=>a+b,0),s=1,r=[l[0]-1],N=r[0],A=1n,w=[1];
 check(rank>=1n&&rank<=H[1][N],"rank domain");
 while(w.length<L){
  let parent=A*H[s][N],h=N?H[s][N-1]:0n,oldTotal=A*h;
  let v=s<m?l[s]:0,Af=s<m?A*binom(N+v-2,v-2):0n,fresh=s<m?Af*H[s+1][N+v-1]:0n;
  check(parent===oldTotal+fresh&&rank>=1n&&rank<=parent,"lex partition");
  if(rank>oldTotal){rank-=oldTotal;check(fresh>0n&&rank<=fresh,"fresh block");r.push(v-1);N+=v-1;s++;A=Af;w.push(s)}
  else{let children=childCounts(r,A),q=(rank-1n)/h+1n,skip=0n,i=0;for(;i<s;i++){if(q<=children[i])break;q-=children[i];skip+=children[i]}check(i<s&&children[i]>0n,"old child missing");rank-=skip*h;A=children[i];r[i]--;N--;w.push(i+1);check(rank>=1n&&rank<=A*h,"child interval")}
 }
 check(s===m&&N===0&&r.every(x=>x===0)&&A===1n&&rank===1n,"terminal residual");return w
}
function verifyWord(w,l){
 let count=Array(l.length).fill(0),first=Array(l.length).fill(-1),last=first.slice();
 check(w.length===l.reduce((a,b)=>a+b,0),"word length");
 for(let i=0;i<w.length;i++){let j=w[i]-1;check(Number.isInteger(j)&&j>=0&&j<l.length,"ordinal");if(!count[j])first[j]=i;last[j]=i;count[j]++}
 check(count.every((v,j)=>v===l[j]),"multiplicity");check(first.every((v,j)=>j===0||v>first[j-1]),"first order");check(last.every((v,j)=>j===0||v>last[j-1]),"last order");return {first,last}
}
function reject(fn,msg){let caught=false;try{fn()}catch(e){caught=e.message===msg}check(caught,"negative control "+msg)}
function brute(l){let out=[],r=l.slice(),L=l.reduce((a,b)=>a+b,0);function walk(w){if(w.length===L){try{verifyWord(w,l);out.push(w.slice())}catch(e){if(!["first order","last order"].includes(e.message))throw e}return}for(let j=0;j<r.length;j++)if(r[j]){r[j]--;w.push(j+1);walk(w);w.pop();r[j]++}}walk([]);return out}
const expectedMonths=[[20,56],[32,21],[29,38],[1,29],[18,76],[43,3],[5,81],[10,65],[1,45],[29,13]];
function fullTest(log){
 let small=0;for(let l of [[2],[2,2],[2,3],[3,2],[2,2,2],[2,3,2],[3,3,2],[2,2,2,2]]){let all=brute(l),H=transfer(l);check(H[1][l[0]-1]===BigInt(all.length),"small root");for(let i=0;i<all.length;i++){check(unrankWeave(l,H,BigInt(i+1)).join()===all[i].join(),"small lex");small++}}
 let l=[2,2],H=transfer(l);reject(()=>unrankWeave(l,H,0n),"rank domain");reject(()=>unrankWeave(l,H,H[1][1]+1n),"rank domain");reject(()=>verifyWord([2,1,1,2],l),"first order");reject(()=>verifyWord([1,2,2,1],l),"last order");reject(()=>verifyWord([1,1,1,2],l),"multiplicity");
 let groups=new Map(),gateCache=new Map([[0,F]]);for(let i=0;i<vectors.length;i++){let [c,t,...e]=vectors[i],o=oracle(c,t,gateCache);check(o.cut.join()===e.join(),"canonical first3");let key=[c,o.open,o.close].join();if(!groups.has(key))groups.set(key,[]);groups.get(key).push({i,c,t,o})}
 let total=0,ends=0,days=0,foundation=false;
 for(let items of groups.values()){
  let {c,o}=items[0],l=o.lengths,H=transfer(l),root=H[1][l[0]-1],rank=choose(sauce(c,o.open+1),4,32,root),w=unrankWeave(l,H,rank),p=verifyWord(w,l);days+=w.length;
  let count=Array(l.length).fill(0);for(let j=0;j<w.length;j++){let k=w[j]-1;count[k]++;if(j===p.first[k]){check(count[k]===1,"first occurrence number");ends++}if(j===p.last[k]){check(count[k]===l[k],"last occurrence number");ends++}}
  for(let a of items){let k=w[a.o.position-1],occ=w.slice(0,a.o.position).filter(x=>x===k).length,got=[a.o.monthNames[k-1],occ];check(got.join()===expectedMonths[a.i].join(),"canonical month vector "+(a.i+1)+" actual "+got+" expected "+expectedMonths[a.i]);total+=5;log(JSON.stringify({vector:a.i+1,c:a.c,t:a.t,tuple:[...a.o.cut,...got],yearDays:w.length,months:l.length,position:a.o.position}))}
  if(c===F&&o.open===-15057703){check(l.join()===FOUNDATION_LENGTHS.join()&&o.monthNames.join()===FOUNDATION_NAMES.join(),"Foundation composition");check(root.toString(2).length===22470&&rank.toString(2).length===22469,"Foundation root/rank bits");check(w.slice(0,11).join()==="1,2,3,4,5,6,7,4,8,9,10","Foundation prefix");foundation=true}
 }
 check(foundation,"Foundation missing");let f=oracle(F,F,gateCache);for(let [t,y] of [[f.open,4999],[f.open+1,5000],[f.close,5000],[f.close+1,5001]])check(oracle(F,t,gateCache).cut[0]===y,"year boundary");reject(()=>oracle(F,F+50001,gateCache),"bounded domain");
 log(JSON.stringify({status:"HOST_FULL_MULTIVECTOR_PASS",canonicalFields:total,yearGroups:groups.size,days,occurrenceEndpoints:ends,smallExactRanks:small,negativeControls:6,yearBoundaries:4,foundation:true,scope:"HOST_ONLY"}))
}
fullTest(console.log);
