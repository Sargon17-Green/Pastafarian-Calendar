// PROJECT_ID: PC-BRANCH-SM83-ASSEMBLY-GEEZ
// Host QA only; no Native or full-size unrank performance claim.
// Proof: remove largest label j; its last occurrence must be final.
// If j and j-1 are unstarted, its first position k must exceed the first
// position p of j-1 in the smaller word. For r>=2, choose r-2 copies
// among T-k-1 slots between first and final. Thus D_j(k)=C(T-k-1,r-2)*sum_{p<k}D_{j-1}(p).
// For first unstarted label use the total of started-prefix words as the prefix sum.
// r=1 forces k=T; for started-prefix labels only last-order applies.
// O(m*L) BigInt operations and O(L) BigInt slots per count, not per whole unrank.
function suite(){
"use strict";
// V32: insertion DP by first position of newest label; exact BigInt.
const t0=Date.now();const check=(p,m)=>{if(!p)throw Error(m)};
const sum=a=>a.reduce((x,y)=>x+y,0);
function C(n,k){if(k<0||k>n)return 0n;k=Math.min(k,n-k);let z=1n;for(let i=1;i<=k;i++)z=z*BigInt(n-k+i)/BigInt(i);return z}
function count(L,R=L){
 check(L.length===R.length&&L.every((x,i)=>Number.isInteger(x)&&x>0&&Number.isInteger(R[i])&&R[i]>=0&&R[i]<=x),"domain");
 // Reachable states: ended prefix, unstarted suffix. Other states are invalid.
 let positive=false,unstarted=false;
 for(let i=0;i<L.length;i++){if(R[i]===0){if(positive)return 0n;continue}positive=true;if(R[i]===L[i])unstarted=true;else if(unstarted)return 0n}
 let S=0,total=1n,row=null;
 for(let i=0;i<L.length;i++){
  const r=R[i];if(!r)continue;
  const T=S+r;
  if(R[i]<L[i]){total*=C(T-1,r-1);S=T;continue}
  // Insert r copies after first of previous unstarted label (if any);
  // last copy is fixed at T. For first new label there is no lower bound.
  if(r===1){row=Array(T+1).fill(0n);row[T]=total;S=T;continue}
  const next=Array(T+1).fill(0n);
  let prefix=row?0n:total,z=C(T-2,r-2),nextTotal=0n;
  for(let k=1;k<=S+1;k++){
   if(row)prefix+=row[k-1];
   next[k]=prefix*z;nextTotal+=next[k];
   if(k<S+1)z=z*BigInt(T-k-1-(r-2))/BigInt(T-k-1);
  }
  row=next;total=nextTotal;S=T;
 }
 return total;
}
function legal(L,R,j){return R[j]>0&&(R[j]!==L[j]||R.slice(0,j).every((x,i)=>x<L[i]))&&(R[j]!==1||R.slice(0,j).every(x=>x===0))}
function oracle(L){const m=new Map();function f(R){const key=R.join(",");if(m.has(key))return m.get(key);let n=sum(R)?0n:1n;for(let j=0;j<L.length;j++)if(legal(L,R,j)){const a=R.slice();a[j]--;n+=f(a)}m.set(key,n);return n}return {f,m}}
function rankPath(L,rank,word=null){let R=L.slice(),out=[],rankOut=1n;check(word||rank>=1n&&rank<=count(L),"rank");while(sum(R)){let found=false;for(let j=0;j<L.length;j++)if(legal(L,R,j)){const a=R.slice();a[j]--;const n=count(L,a);if(word?j===word[out.length]:rank<=n){check(n>0n,"empty block");out.push(j);R=a;found=true;break}if(word)rankOut+=n;else rank-=n}check(found,"no candidate")}return word?rankOut:out}
let tuples=0,states=0,words=0;
function brute(L){let out=[],a=[],R=L.slice();function f(){if(!sum(R)){const p=L.map((_,i)=>a.indexOf(i)),q=L.map((_,i)=>a.lastIndexOf(i));if(p.every((v,i)=>!i||p[i-1]<v)&&q.every((v,i)=>!i||q[i-1]<v))out.push(a.slice());return}for(let j=0;j<L.length;j++)if(R[j]){R[j]--;a.push(j);f();a.pop();R[j]++}}f();return out}
function audit(L){tuples++;const o=oracle(L),n=o.f(L);check(n===count(L),"total "+L);for(const [k,v] of o.m){check(count(L,k.split(",").map(Number))===v,"state "+L+" "+k);states++}if(sum(L)<=9){const a=brute(L);check(n===BigInt(a.length),"brute total");for(let i=0;i<a.length;i++){let r=BigInt(i+1);check(rankPath(L,r).join(",")===a[i].join(","),"unrank");check(rankPath(L,0n,a[i])===r,"rank");words++}}}
function gen(a,k){if(!k){audit(a);return}for(let x=1;x<=4;x++)gen([...a,x],k-1)}
for(let m=1;m<=4;m++)gen([],m);
for(const L of [[4,5,4],[4,4,5],[5,4,4],[6,6,6],[4,4,4,4,4],[1,2,1,3,2]])audit(L);
const large=[];
for(const L of [Array(47).fill(6),Array(47).fill(4),[...Array(46).fill(123),120],Array.from({length:47},(_,i)=>4+(i*37)%120)]){
 const t=Date.now(),n=count(L);check(n>0n,"full count");
 const r=L.map(x=>x-1),tail=count(L,r);let s=0,ind=1n;
 // Independent reversed size-biased order: multinomial * product r_i / prefix sum.
 let num=1n,den=1n;
 for(const x of r){s+=x;for(let j=1;j<=x;j++)num*=BigInt(s-x+j),den*=BigInt(j);num*=BigInt(x);den*=BigInt(s)}
 ind=num/den;check(num%den===0n&&ind===tail,"tail independent");
 large.push({m:L.length,L:sum(L),bits:n.toString(2).length,tailBits:tail.toString(2).length,ms:Date.now()-t,first16:n.toString().slice(0,16),last16:n.toString().slice(-16)});
}
const L=Array(47).fill(6),n=count(L),r=n/2n,t=Date.now();const w=rankPath(L,r);check(rankPath(L,0n,w)===r,"47x6 rank roundtrip");const first=L.map((_,i)=>w.indexOf(i)),last=L.map((_,i)=>w.lastIndexOf(i));check(first.every((x,i)=>!i||first[i-1]<x)&&last.every((x,i)=>!i||last[i-1]<x)&&L.every((x,i)=>w.filter(j=>j===i).length===x),"47x6 word");
return {tuples,states,words,large,rankRoundtrip:{m:47,L:282,ms:Date.now()-t},elapsedMs:Date.now()-t0};
}
console.log("HOST_V32_INSERTION_DP="+JSON.stringify(suite()));
