// PC-BRANCH-COBOL-SIMPLIFIED-CHINESE; direct INT-02 rank Native differential.
import assert from 'node:assert/strict';
import {spawnSync} from 'node:child_process';
const M=170141183460469231731687303715884105727n;
const fmt=x=>String(x).padStart(39,'0');
const cases=[];
const add=(a,d,n)=>{
 const valid=/^\d{39}$/.test(a)&&/^\d{39}$/.test(d)&&n>=1&&n<=19600&&BigInt(a)>=1n&&BigInt(a)<=M&&BigInt(d)>=1n&&BigInt(d)<=M;
 let rank=0;
 if(valid){
  const k=BigInt(n),x=BigInt(a),y=BigInt(d);
  // Independent closed-form equal-size bucket population.
  const cutoff=(M/k)*k;
  rank=Number(x<=cutoff?((x-1n)%k)+1n:(y%2n===1n?1n:k));
 }
 cases.push({a,d,n,expected:[valid?0:22,rank]});
};
for(let n=1;n<=19600;n++){
 const k=BigInt(n),cutoff=(M/k)*k;
 for(const x of [1n,k,cutoff-1n,cutoff,cutoff<M?cutoff+1n:M])
  for(const d of [M,M-1n])add(fmt(x),fmt(d),n);
}
for(const [a,d,n] of [[fmt(0n),fmt(1n),1],[fmt(M+1n),fmt(1n),7],[fmt(1n),fmt(0n),7],[fmt(1n),fmt(M+1n),7],['X'+fmt(1n).slice(1),fmt(1n),7],[fmt(1n),'X'+fmt(1n).slice(1),7],[fmt(1n),fmt(1n),0],[fmt(1n),fmt(1n),19601],[fmt(1n),fmt(1n),-1]])add(a,d,n);
assert.equal(cases.length,196009);
const exe=process.argv[2];
assert.ok(exe,'executable required');
const input=String(cases.length).padStart(6,'0')+'\n'+cases.map(c=>[c.a,c.d,c.n].join('\n')).join('\n')+'\n';
const p=spawnSync(exe,[],{input,encoding:'utf8',timeout:120000,maxBuffer:16*1024*1024});
if(p.error||p.status!==0)throw Error(JSON.stringify({error:String(p.error),status:p.status,stderr:p.stderr}));
const lines=p.stdout.trimEnd().split(/\r?\n/);
assert.equal(lines.length,cases.length);
let rejectedTail=0,invalid=0;
for(let i=0;i<cases.length;i++){
 const c=cases[i];
 assert.match(lines[i],/^\s*\d+\s+[+-]?\d+\s*$/,'malformed row '+i);
 assert.deepEqual(lines[i].trim().split(/\s+/).map(Number),c.expected,JSON.stringify({i,...c}));
 if(c.expected[0]===22)invalid++;
 else if(BigInt(c.a)>(M/BigInt(c.n))*BigInt(c.n))rejectedTail++;
}
console.log('INT02_SHORT_RANK_CASES='+cases.length+' INVALID='+invalid+' REJECTED_TAIL='+rejectedTail+' GATE=MATCH_NATIVE_RANK_ONLY');
