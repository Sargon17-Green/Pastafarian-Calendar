import assert from 'node:assert/strict';
import {spawnSync} from 'node:child_process';
const exe=process.argv[2];
if(!exe) throw Error('Usage: node test/int02_month_composition_diff.mjs DRIVER|--oracle-only');
let requests=0, oracleChecks=0;
const choose=(n,k)=>{
  if(n<0||k<0||k>n)return 0n;
  let b=1n; for(let i=1;i<=k;i++)b=b*BigInt(n-i+1)/BigInt(i);
  return b;
};
// Independent inclusion-exclusion, not the production sliding-window recurrence.
function count(y,m){
  if(m===0)return y===0?1n:0n;
  const t=y-4*m;
  if(t<0||y>123*m)return 0n;
  let b=0n;
  for(let j=0;j<=Math.min(m,Math.floor(t/120));j++){
    const v=choose(m,j)*choose(t-120*j+m-1,m-1);
    b+=j%2?-v:v;
  }
  return b;
}
function rank(y,m,vec){
  let r=1n;
  for(const v of vec){
    for(let c=4;c<v;c++)r+=count(y-c,m-1);
    y-=v;m--;
  }
  assert.equal(y,0);assert.equal(m,0);return r;
}
function unrank(y,m,r){
  const v=[];
  while(m){
    let chosen=false;
    for(let c=4;c<=Math.min(123,y-4*(m-1));c++){
      const w=count(y-c,m-1);
      if(r>w){r-=w;continue;}
      v.push(c);y-=c;m--;chosen=true;break;
    }
    assert.ok(chosen);
  }
  assert.equal(y,0);assert.equal(r,1n);return v;
}
function call(op,y,m,r=0n,v=[]){
  const input=[op,y,m,r,...Array.from({length:47},(_,i)=>v[i]??0)].join('\n')+'\n';
  const proc=spawnSync(exe,[],{input,encoding:'utf8',timeout:60000,maxBuffer:65536});
  assert.equal(proc.error,undefined);
  assert.equal(proc.status,0,proc.stderr);
  const lines=proc.stdout.trim().split(/\r?\n/);
  assert.equal(lines.length,48,proc.stdout);
  const [status,value]=lines[0].trim().split(/\s+/);
  requests++;
  return {status:Number(status),value:BigInt(value),vec:lines.slice(1).map(Number)};
}
function check(y,m,r,v){
  assert.equal(rank(y,m,v),r);
  assert.deepEqual(unrank(y,m,r),v);oracleChecks+=2;
  if(exe==='--oracle-only')return;
  const u=call('U',y,m,r);
  assert.equal(u.status,0);assert.equal(u.value,0n);
  assert.deepEqual(u.vec.slice(0,m),v);assert.ok(u.vec.slice(m).every(x=>x===0));
  const q=call('R',y,m,0n,v);
  assert.equal(q.status,0);assert.equal(q.value,r);assert.ok(q.vec.every(x=>x===0));
}
for(const [y,m] of [[369,3],[368,3],[367,3],[252,3],[252,47],[5778,47],[2984,47],[3000,25]]){
  const n=count(y,m);assert.ok(n>0n);oracleChecks++;
  if(y===2984)assert.equal(n,88188610661218998730479348148499174290556866510515790050322945205040359156522439817076486280000n);
  if(exe!=='--oracle-only'){
    const a=call('C',y,m);assert.equal(a.status,0);assert.equal(a.value,n);
    assert.ok(a.vec.every(x=>x===0));
  }
  const rr=n<=6n?Array.from({length:Number(n)},(_,i)=>BigInt(i+1)):[1n,(n+1n)/2n,n];
  for(const r of rr)check(y,m,r,unrank(y,m,r));
}
// Explicit enumeration of all vectors at the three-month upper boundary.
const tiny=[];
for(let a=121;a<=123;a++)for(let b=121;b<=123;b++){
  const c=367-a-b;if(c>=4&&c<=123)tiny.push([a,b,c]);
}
assert.equal(BigInt(tiny.length),count(367,3));
for(let i=0;i<tiny.length;i++)assert.deepEqual(unrank(367,3,BigInt(i+1)),tiny[i]);
oracleChecks+=1+tiny.length;
if(exe!=='--oracle-only'){
  for(const [op,y,m,r,v] of [
    ['C',251,3,0n,[]],['C',5779,47,0n,[]],['C',252,2,0n,[]],
    ['C',252,48,0n,[]],['U',369,3,0n,[]],['U',369,3,2n,[]],
    ['U',369,3,10n**100n,[]],['R',369,3,0n,[123,123,122]],
    ['R',369,3,0n,[123,123,123,1]],['R',369,3,0n,[124,123,122]]
  ]){
    const a=call(op,y,m,r,v);assert.equal(a.status,22);assert.equal(a.value,0n);
    assert.ok(a.vec.every(x=>x===0));
  }
}
console.log(JSON.stringify({gate:'INT02_MONTH_COMPOSITION',oracleChecks,requests,verdict:exe==='--oracle-only'?'ORACLE_ONLY_NOT_NATIVE':'MATCH_NATIVE_MONTH_COMPOSITION_ONLY'}));
