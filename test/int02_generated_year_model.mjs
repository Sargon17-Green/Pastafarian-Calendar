// QA-only reproducible model comparison, NOT Native.
import {readFileSync} from 'node:fs';
import assert from 'node:assert/strict';
const read=name=>readFileSync(new URL(name,import.meta.url),'utf8');
const s=read('./int02_normative_gap_vectors.mjs'),t=read('./int02_source_gate_year_oracle.mjs');
const offsets=[-20000,-10000,-5778,-1,0,1,5778,10000,20000];
const f=new Function(s.slice(0,s.indexOf(' const neg=[],pos=[]'))+`
 const cases=[];for(const offset of ${JSON.stringify(offsets)}){
 const a=E+BigInt(offset),lo=a-5778n,hi=a+5778n,all=[E];let p=E,q=E;
 for(let k=1;p<=hi;k++){p+=BigInt(gap(k));all.push(p)}
 for(let k=1;q>=lo;k++){q-=BigInt(gap(-k));all.unshift(q)}
 const first=all.findLastIndex(x=>x<lo),last=all.findIndex(x=>x>hi),window=all.slice(first,last+1);
 const pairs=[];for(let i=0;i<window.length;i++)for(let j=i+6;j<window.length;j++){const l=window[i],r=window[j];if(l<a&&a<=r&&r-l>=252n&&r-l<=5778n)pairs.push([l,r])}
 pairs.sort((p,q)=>Number((p[1]-p[0])-(q[1]-q[0]))||Number(p[0]-q[0]));
 const rank=query(sauce(a,a),10n,BigInt(pairs.length)).rank;
 cases.push({action:a,window,pairs,rank,year:pairs[Number(rank-1n)]});
 }return cases;}return normativeVectors();`);
const g=new Function(t.slice(0,t.indexOf(' let checks=0;'))+`
 return ${JSON.stringify(offsets)}.map(offset=>{let a=E+BigInt(offset),all=gateWindow(a),window=all.slice(all.findLastIndex(x=>x<a-5778n),all.findIndex(x=>x>a+5778n)+1),pairs=yearCandidates(a,window),rank=select(a,a,0,10n,BigInt(pairs.length));return {action:a,window,pairs,rank,year:pairs[Number(rank-1n)]}});}return int02();`);
const a=f(),b=g();assert.deepEqual(a,b);
assert.deepEqual(JSON.parse(JSON.stringify(a,(_,v)=>typeof v==='bigint'?Number(v):v)),JSON.parse(read('./int02_generated_year_vectors.json')));
const M=(1n<<127n)-1n;let checks=0;
for(let n=1;n<=19600;n++){const N=BigInt(n),limit=M-M%N;
 for(const x of [1n,limit,limit>1n?limit-1n:1n,limit<M?limit+1n:M,M])for(const dir of [0,1]){
 let rem=0;for(const d of x.toString().padStart(39,'0'))rem=(10*rem+Number(d))%n;
 let mrem=0;for(const d of M.toString().padStart(39,'0'))mrem=(10*mrem+Number(d))%n;
 const digits=M.toString().padStart(39,'0').split('').map(Number);let carry=mrem;
 for(let i=38;i>=0;i--){let v=digits[i]-carry%10;carry=Math.floor(carry/10);if(v<0){v+=10;carry++}digits[i]=v}
 const got=x.toString().padStart(39,'0')>digits.join('')?(dir?1:n):(rem||n);
 const expected=Number(((x>limit?(dir?1n:limit):x)-1n)%N+1n);
 assert.equal(got,expected);checks++;
 }}
console.log(JSON.stringify({scope:'MODEL_ONLY_NOT_NATIVE',windows:a.length,pairs:a.reduce((n,x)=>n+x.pairs.length,0),rankChecks:checks}));
