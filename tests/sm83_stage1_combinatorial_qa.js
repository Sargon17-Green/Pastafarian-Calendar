// Host-only Stage1 S-X exact combinatorial QA. Run: node tests/sm83_stage1_combinatorial_qa.js
// Source contract: docs/SM83_STAGE1_FIVE_FIELD_INTEGRATION_CONTRACT.md
// No full-scale V32 or Native claim; bounded state guard is deliberate.
function suite(){
"use strict";
const started=Date.now(), stats={S21:0,TW:0,U31:0,V32:0,ring:0,large:0}, maxStates={n:0};
const ok=(x,m)=>{if(!x)throw Error(m)};
const eq=(a,b,m)=>ok(JSON.stringify(a)===JSON.stringify(b),m);
function C(n,k){if(k<0||n<k||n<0)return 0n;k=Math.min(k,n-k);let v=1n;for(let i=1;i<=k;i++)v=v*BigInt(n-i+1)/BigInt(i);return v}
function split(g,k,r=0){if(k===0)return g===0&&r===0?1n:0n;if(g<k||r<0||r>=g)return 0n;if(!r)return C(g-1,k-1);let n=0n;for(let j=1;j<k;j++)n+=C(r-1,j-1)*C(g-r-1,k-j-1);return n}
function select(rank,blocks){ok(typeof rank==="bigint"&&rank>=1n,"rank invalid");for(const [choice,n] of blocks){if(rank<=n)return [choice,rank];rank-=n}throw Error("rank exceeds count")}
function sUn(g,k,r,rank){ok(rank>=1n&&rank<=split(g,k,r),"S rank");const out=[];while(k){const blocks=[];for(let a=1;a<=g-k+1;a++){if(r&&a>r)break;blocks.push([a,split(g-a,k-1,r?r-a:0)])}let a;[a,rank]=select(rank,blocks);out.push(a);g-=a;k--;if(r)r-=a}return out}
function P(n,k){if(k<0||n<k)return 0n;let p=1n;for(let i=0;i<k;i++)p*=BigInt(n-i);return p}
function pUn(n,k,rank){ok(rank>=1n&&rank<=P(n,k),"P rank");const a=Array.from({length:n},(_,i)=>i),out=[];while(k){const block=P(a.length-1,k-1),index=Number((rank-1n)/block);out.push(a.splice(index,1)[0]);rank=(rank-1n)%block+1n;k--}return out}
function pRank(n,a){let rank=1n;const unused=Array.from({length:n},(_,i)=>i);for(let j=0;j<a.length;j++){const i=unused.indexOf(a[j]);ok(i>=0,"duplicate name");rank+=BigInt(i)*P(unused.length-1,a.length-j-1);unused.splice(i,1)}return rank}
function bounded(s,k,lo=4,hi=123){if(!k)return s===0?1n:0n;if(s<k*lo||s>k*hi)return 0n;let n=0n;for(let j=0;j<=Math.min(k,Math.floor((s-k*lo)/(hi-lo+1)));j++){let x=C(k,j)*C(s-k*lo-j*(hi-lo+1)+k-1,k-1);n+=j%2?-x:x}return n}
function bUn(s,k,rank,lo=4,hi=123){ok(rank>=1n&&rank<=bounded(s,k,lo,hi),"U rank");const out=[];while(k){let a;[a,rank]=select(rank,Array.from({length:hi-lo+1},(_,i)=>[i+lo,bounded(s-i-lo,k-1,lo,hi)]));out.push(a);s-=a;k--}return out}
function dp(k,s,lo,hi){let row=Array(s+1).fill(0n);row[0]=1n;const rows=[row];for(let j=1;j<=k;j++){let acc=0n;const next=[];for(let t=0;t<=s;t++){if(t>=lo)acc+=row[t-lo];if(t>hi)acc-=row[t-hi-1];next.push(acc)}rows.push(next);row=next}return rows}
function vCounter(L,limit=200000){ok(L.every(x=>Number.isInteger(x)&&x>0),"length");const memo=new Map();function legal(R,j){return R[j]>0&&(R[j]!==L[j]||R.slice(0,j).every((v,i)=>v<L[i]))&&(R[j]!==1||R.slice(0,j).every(v=>v===0))}
function count(R){const key=R.join(",");if(memo.has(key))return memo.get(key);ok(memo.size<limit,"V32 state limit");let n=R.every(x=>!x)?1n:0n;for(let j=0;j<R.length;j++)if(legal(R,j)){const next=R.slice();next[j]--;n+=count(next)}memo.set(key,n);return n}
function un(rank){ok(rank>=1n&&rank<=count(L),"V rank");let R=L.slice(),out=[];while(R.some(x=>x)){const blocks=[];for(let j=0;j<R.length;j++)if(legal(R,j)){let n=R.slice();n[j]--;blocks.push([j,count(n)])}let j;[j,rank]=select(rank,blocks);out.push(j);R[j]--}return out}
return {count,un,states:()=>memo.size}}
function words(L){const a=[],out=[];function f(R){if(R.every(x=>!x)){const first=L.map((_,i)=>a.indexOf(i)),last=L.map((_,i)=>a.lastIndexOf(i));if(first.every((x,i)=>!i||first[i-1]<x)&&last.every((x,i)=>!i||last[i-1]<x))out.push(a.slice());return}for(let j=0;j<R.length;j++)if(R[j]){R[j]--;a.push(j);f(R);a.pop();R[j]++}}f(L.slice());return out}
function ring(R,N,W,dir){ok(N>=1n&&N<=R&&W>=1n&&W<=R&&(dir===1||dir===-1),"ring domain");const cap=R/N*N;const accepted=W<=cap?W:dir===1?1n:cap;return {accepted,rank:1n+(accepted-1n)%N}}
function wide(M,N,digits,dir){ok(M>=2n&&N>=1n,"wide domain");let R=M,k=1;while(R<N){R*=M;k++}ok(digits.length===k&&digits.every(x=>x>=0n&&x<M),"digit count");let W=1n,p=1n;for(const d of digits){W+=p*d;p*=M}return {...ring(R,N,W,dir),k,W,R}}
function direct(R,N,W,dir){const cap=R/N*N;while(W>cap)W=dir===1?(W===R?1n:W+1n):W-1n;return {accepted:W,rank:(W-1n)%N+1n}}
function same(a,b){return a.accepted===b.accepted&&a.rank===b.rank}
for(let g=1;g<=9;g++)for(let k=1;k<=g;k++)for(let r=0;r<g;r++){const a=[];for(let mask=0;mask<2**(g-1);mask++){const cuts=[];for(let j=1;j<g;j++)if(mask&(1<<(j-1)))cuts.push(j);if(cuts.length!==k-1||(r&&!cuts.includes(r)))continue;const b=[0,...cuts,g];a.push(b.slice(1).map((x,i)=>x-b[i]))}a.sort((x,y)=>{for(let i=0;i<x.length;i++)if(x[i]!==y[i])return x[i]-y[i];return 0});ok(split(g,k,r)===BigInt(a.length),"S count");a.forEach((v,i)=>{eq(sUn(g,k,r,BigInt(i+1)),v,"S unrank");stats.S21++})}
for(let n=1;n<=7;n++)for(let k=0;k<=n;k++){let a=[];function f(prefix){if(prefix.length===k){a.push(prefix);return}for(let j=0;j<n;j++)if(!prefix.includes(j))f([...prefix,j])}f([]);ok(P(n,k)===BigInt(a.length),"P count");a.forEach((v,i)=>{let r=BigInt(i+1);eq(pUn(n,k,r),v,"P unrank");ok(pRank(n,v)===r,"P rank");stats.TW++})}
for(let k=1;k<=5;k++){const groups=new Map();function f(a){if(a.length===k){const s=a.reduce((x,y)=>x+y,0);if(!groups.has(s))groups.set(s,[]);groups.get(s).push(a);return}for(let j=4;j<=7;j++)f([...a,j])}f([]);const d=dp(k,k*7,4,7);for(let s=0;s<=k*7;s++){const a=groups.get(s)||[];ok(bounded(s,k,4,7)===BigInt(a.length)&&d[k][s]===BigInt(a.length),"U count");a.forEach((v,i)=>{eq(bUn(s,k,BigInt(i+1),4,7),v,"U unrank");stats.U31++})}}
for(const L of [[1],[1,1],[1,3],[3,1],[2,2],[2,3,2],[3,2,3],[4,4],[4,5],[5,4],[4,4,4],[4,5,4],[4,4,5],[2,2,2,2]]){const a=words(L),v=vCounter(L),prefix=new Map();for(const w of a)for(let j=0;j<=w.length;j++){const p=w.slice(0,j).join(",");prefix.set(p,(prefix.get(p)||0n)+1n)}ok(v.count(L)===BigInt(a.length),"V count");a.forEach((w,i)=>{eq(v.un(BigInt(i+1)),w,"V unrank");stats.V32++});for(const [p,n] of prefix){const R=L.slice();if(p)p.split(",").forEach(j=>R[Number(j)]--);ok(v.count(R)===n,"V prefix count")}maxStates.n=Math.max(maxStates.n,v.states())}
for(let R=1n;R<=35n;R++)for(let N=1n;N<=R;N++)for(let W=1n;W<=R;W++)for(const d of [1,-1]){ok(same(ring(R,N,W,d),direct(R,N,W,d)),"ring direct");stats.ring++}
for(let M=2n;M<=5n;M++)for(let N=1n;N<=M*M+1n;N++){let R=M,k=1;while(R<N){R*=M;k++}for(let W=1n;W<=R;W++){let v=W-1n,ds=[];for(let i=0;i<k;i++){ds.push(v%M);v/=M}for(const d of [1,-1]){const z=wide(M,N,ds,d);ok(z.W===W&&same(z,direct(R,N,W,d)),"wide direct");stats.ring++}}}
const M=(1n<<127n)-1n;for(const N of [1n,M-1n,M,M+1n,M*M-1n,M*M,M*M+1n,47n**5778n]){let R=M,k=1;while(R<N){R*=M;k++}const cap=R/N*N;for(const W of new Set([1n,cap,cap<R?cap+1n:cap,R]))for(const d of [1,-1]){let a=W-1n,ds=[];for(let i=0;i<k;i++){ds.push(a%M);a/=M}const z=wide(M,N,ds,d);ok(z.W===W&&z.R===R&&z.k===k&&z.accepted===(W<=cap?W:d===1?1n:cap)&&z.rank===(z.accepted-1n)%N+1n,"full width");stats.large++}}
for(const r of [0,1,68,136]){const n=split(137,17,r);for(const rank of [1n,n/2n,n])if(rank){const a=sUn(137,17,r,rank);ok(a.length===17&&a.reduce((x,y)=>x+y,0)===137,"S full");if(r){let p=0;ok(a.slice(0,-1).some(x=>(p+=x)===r),"forced split")}stats.large++}}
for(const n of [17,47])for(const k of [6,n]){const total=P(n,k);for(const r of [1n,total/2n,total]){const a=pUn(n,k,r);ok(pRank(n,a)===r,"P full");stats.large++}}
const rows=dp(47,5778,4,123);for(const [s,k] of [[252,3],[252,47],[3000,47],[5778,47]]){const n=bounded(s,k);ok(n===rows[k][s]&&n>0n,"U full count");for(const r of [1n,n/2n,n])if(r){const a=bUn(s,k,r);ok(a.length===k&&a.every(x=>x>=4&&x<=123)&&a.reduce((x,y)=>x+y,0)===s,"U full");let rank=1n,left=s;for(let j=0;j<k;j++){for(let x=4;x<a[j];x++)rank+=rows[k-j-1][left-x]||0n;left-=a[j]}ok(rank===r,"U full rank");stats.large++}}
for(const f of [()=>sUn(6,6,0,0n),()=>pUn(17,17,P(17,17)+1n),()=>bUn(3,1,1n),()=>vCounter([4,4]).un(0n),()=>ring(3n,4n,1n,1)]){let rejected=false;try{f()}catch(e){rejected=true}ok(rejected,"invalid rank not rejected")}
return {stats,maxVStates:maxStates.n,elapsedMs:Date.now()-started,V32Full:"UNRESOLVED",native:"NOT_RUN"};
}
console.log(JSON.stringify(suite()));
