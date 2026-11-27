// INT-02 unsigned wide expression arithmetic. BigInt is the independent expected-value oracle.
import assert from 'node:assert/strict';
import {spawnSync} from 'node:child_process';
const W=96,B=10000,L=24,limit=10n**96n,zero='0'.repeat(W);
const pad=x=>x.toString().padStart(W,'0');
function oracle(op,a,b){
 if(!['+','*'].includes(op)||!/^\d{96}$/.test(a)||!/^\d{96}$/.test(b))return [22,zero];
 const v=op==='+'?BigInt(a)+BigInt(b):BigInt(a)*BigInt(b);
 return v>=limit?[24,zero]:[0,pad(v)];
}
function model(op,a,b){
 if(!['+','*'].includes(op)||!/^\d{96}$/.test(a)||!/^\d{96}$/.test(b))return [22,zero];
 const parts=s=>Array.from({length:L},(_,i)=>Number(s.slice(W-4*(i+1),W-4*i)));
 const x=parts(a),y=parts(b),c=Array(48).fill(0);
 for(let i=0;i<L;i++)if(op==='+')c[i]=x[i]+y[i];else for(let j=0;j<L;j++)c[i+j]+=x[i]*y[j];
 for(let i=0;i<47;i++){c[i+1]+=Math.floor(c[i]/B);c[i]%=B;}
 return c.slice(L).some(Boolean)?[24,zero]:[0,c.slice(0,L).reverse().map(x=>String(x).padStart(4,'0')).join('')];
}
const M=(1n<<127n)-1n;
const cases=[];
for(const op of ['+','*'])for(const [a,b] of [[0n,0n],[0n,limit-1n],[1n,limit-1n],[limit-1n,limit-1n],[9999n,1n],[9999n,9999n],[M,M],[M,197n],[10n**48n,10n**48n-1n],[10n**48n,10n**48n],[limit-2n,1n],[limit-2n,2n]])cases.push([op,pad(a),pad(b)]);
cases.push(['?',zero,zero],['+','X'+zero.slice(1),zero],['*',zero,zero.slice(1)+'X']);
let seed=0x52a17c9b;function next(){seed=(Math.imul(seed,1664525)+1013904223)>>>0;return seed}
function digits(n){return Array.from({length:n},()=>String(next()%10)).join('').padStart(W,'0')}
for(let i=0;i<512;i++){const a=digits(1+next()%96),b=digits(1+next()%96);cases.push(['+',a,b],['*',a,b])}
const exe=process.argv[2];let n=0;const statusCounts={};
for(const [op,a,b] of cases){
 const expected=oracle(op,a,b);
 assert.deepEqual(model(op,a,b),expected,'model case '+n);
 if(exe){
  const r=spawnSync(exe,{input:[op,a,b].join('\n')+'\n',encoding:'utf8',timeout:2000,maxBuffer:65536});
  if(r.error)throw r.error;assert.equal(r.status,0,'exit case '+n);assert.equal(r.stderr,'');
  const m=r.stdout.trim().match(/^(\d+) (\d{96})$/);
  assert(m,'output case '+n);assert.deepEqual([Number(m[1]),m[2]],expected,'native case '+n);
 }
 statusCounts[expected[0]]=(statusCounts[expected[0]]||0)+1;n++;
}
console.log(JSON.stringify({cases:n,statusCounts,scope:exe?'NATIVE_WIDE_ONLY':'MODEL_ONLY_NOT_NATIVE',gate:'MATCH'}));
