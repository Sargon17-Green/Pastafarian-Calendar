import {spawnSync} from 'node:child_process';
import assert from 'node:assert/strict';
const exe=process.argv[2];
if (!exe) throw Error('Usage: node test/int02_gap_composition_diff.mjs DRIVER');
let cases=0;
function call(op,r,k,g,rank=0n,vec=[]){
  const input=[op,r,k,g,rank,...Array.from({length:17},(_,i)=>vec[i]??0)].join('\n')+'\n';
  const p=spawnSync(exe,[],{input,encoding:'utf8',timeout:10000,maxBuffer:65536});
  assert.equal(p.error,undefined);
  assert.equal(p.status,0,p.stderr);
  const lines=p.stdout.trim().split(/\r?\n/);
  assert.equal(lines.length,18);
  const [status,value]=lines[0].trim().split(/\s+/);
  cases++;
  return {status:Number(status),value:BigInt(value),vec:lines.slice(1).map(Number)};
}
function choose(n,k){
  if(k<0||k>n||n<0)return 0n;
  let c=1n; for(let i=1;i<=k;i++)c=c*BigInt(n-i+1)/BigInt(i);
  return c;
}
function count(r,k,g){
  if(!g||g===r)return choose(r-1,k-1);
  let t=0n;for(let j=1;j<k;j++)t+=choose(g-1,j-1)*choose(r-g-1,k-j-1);
  return t;
}
function enumerate(r,k,g){
  const out=[];
  function go(left,p,vec){
    if(p===0){
      if(left===0 && (!g||g===r||vec.some((_,i)=>vec.slice(0,i+1).reduce((a,b)=>a+b,0)===g)))out.push(vec);
      return;
    }
    for(let v=1;v<=left-p+1;v++)go(left-v,p-1,[...vec,v]);
  }
  go(r,k,[]);return out;
}
for(const [r,k,g] of [[6,6,0],[8,6,1],[8,6,4],[9,6,8],[9,7,9],[10,6,5]]){
  const list=enumerate(r,k,g);
  const c=call('C',r,k,g);
  assert.equal(c.status,0);assert.equal(c.value,BigInt(list.length));
  for(let i=0;i<list.length;i++){
    const u=call('U',r,k,g,BigInt(i+1));assert.equal(u.status,0);
    assert.deepEqual(u.vec.slice(0,k),list[i]);assert.ok(u.vec.slice(k).every(x=>x===0));
    const a=call('R',r,k,g,0n,list[i]);assert.equal(a.status,0);assert.equal(a.value,BigInt(i+1));
  }
}
for(const [r,k,g] of [[137,17,0],[137,17,1],[137,17,68],[137,17,136],[137,17,137],[137,6,69]]){
  const c=count(r,k,g);const q=call('C',r,k,g);
  assert.equal(q.status,0);assert.equal(q.value,c);
  for(const rank of [1n,c/2n,c]){
    const u=call('U',r,k,g,rank);assert.equal(u.status,0);
    const v=u.vec.slice(0,k);
    assert.equal(v.reduce((a,b)=>a+b,0),r);
    assert.ok(v.every(x=>x>=1));
    if(g>0&&g<r)assert.ok(v.some((_,i)=>v.slice(0,i+1).reduce((a,b)=>a+b,0)===g));
    const a=call('R',r,k,g,0n,v);assert.equal(a.status,0);assert.equal(a.value,rank);
  }
}
for(const [op,r,k,g,rank,vec] of [
 ['C',5,6,0,0n,[]],['C',137,18,0,0n,[]],['C',10,6,11,0n,[]],
 ['U',8,6,0,0n,[]],['U',8,6,0,22n,[]],['U',8,6,0,10n**900n,[]],
 ['R',8,6,2,0n,[3,1,1,1,1,1]],['R',8,6,0,0n,[3,1,1,1,1,1,1]],
 ['R',8,6,0,0n,[1,1,1,1,1,1]]]){
  const a=call(op,r,k,g,rank,vec);assert.equal(a.status,22);assert.equal(a.value,0n);assert.ok(a.vec.every(x=>x===0));
}
console.log(JSON.stringify({gate:'INT02_GAP_COMPOSITION',cases,verdict:'MATCH_NATIVE_GAP_COMPOSITION_ONLY'}));
