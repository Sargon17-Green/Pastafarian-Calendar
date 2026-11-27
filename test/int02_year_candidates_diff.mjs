// INT-02 bounded candidate enumeration differential; original oracle is immutable.
import fs from 'node:fs';
import vm from 'node:vm';
import crypto from 'node:crypto';
import assert from 'node:assert/strict';
import {spawnSync} from 'node:child_process';
const raw=fs.readFileSync(new URL('./int02_source_gate_year_oracle.mjs',import.meta.url));
const blob=crypto.createHash('sha1').update('blob '+raw.length+'\0').update(raw).digest('hex');
assert.equal(blob,'63cb9905c7a26d876255711256e84d3a217b2a74');
const original=raw.toString('utf8');
const needle='rank,year,scope:';
assert.equal(original.split(needle).length,2);
let model;
vm.runInNewContext(original.replace(needle,'rank,year,window,ordered:candidates,scope:'),{console:{log:s=>{model=JSON.parse(s)}}},{timeout:60000});
assert.equal(model.checks,5041);
assert.equal(model.ordered.length,43);
assert.equal(model.rank,'15');
const executable=process.argv[2];
if(!executable) throw Error('Usage: node test/int02_year_candidates_diff.mjs ./int02-year-driver');
let tests=0;
function call(action,gates,rank,status,expected,selection=[0,0]){
 const r=spawnSync(executable,{input:[action,gates.length,rank,...gates].join('\n')+'\n',encoding:'utf8',timeout:30000,maxBuffer:4*1024*1024});
 if(r.error)throw r.error;
 assert.equal(r.status,0,r.stderr);assert.equal(r.stderr,'');
 const lines=r.stdout.trim().split(/\r?\n/);
 const parse=(line,prefix,n)=>{const t=line.trim().split(/\s+/);assert.equal(t.shift(),prefix);assert.equal(t.length,n);assert(t.every(x=>/^[+-]?\d+$/.test(x)));return t.map(Number)};
 assert.deepEqual(parse(lines.shift(),'STATUS',1),[status]);
 assert.deepEqual(parse(lines.shift(),'COUNT',1),[expected.length]);
 assert.deepEqual(parse(lines.shift(),'SELECT',2),selection);
 assert.deepEqual(lines.map(l=>parse(l,'C',2)),expected);
 tests++;
}
const a=Number(model.action),g=model.window.map(Number),pairs=model.ordered.map(p=>p.map(Number));
call(a,g,0,0,pairs);
for(let k=1;k<=pairs.length;k++)call(a,g,k,0,pairs,pairs[k-1]);
call(a,g,-1,23,pairs);call(a,g,pairs.length+1,23,pairs);
call(a,g.slice(1),0,22,[]);call(a,g.slice(0,-1),0,22,[]);
const bad=g.slice();bad[1]=bad[0];call(a,bad,0,22,[]);
call(a+20001,g,0,22,[]);
for(const extreme of [-2147483648,2147483647]){const gs=g.slice();gs[1]=extreme;call(a,gs,0,22,[])}
function brute(a,g){const p=[];for(let i=0;i<g.length;i++)for(let j=i+6;j<g.length;j++){const l=g[j]-g[i];if(g[i]<a&&a<=g[j]&&l>=252&&l<=5778)p.push([g[i],g[j]])}return p.sort((x,y)=>(x[1]-x[0])-(y[1]-y[0])||x[0]-y[0])}
for(const step of [42,963]){
 const gs=[a];while(gs[0]>a-5778)gs.unshift(gs[0]-step);while(gs.at(-1)<a+5778)gs.push(gs.at(-1)+step);
 const p=brute(a,gs);
 call(a,gs,0,0,p);
 if(p.length){call(a,gs,1,0,p,p[0]);call(a,gs,p.length,0,p,p.at(-1))}
}
console.log('INT02_YEAR_CANDIDATES_CASES='+tests+' GATE=PASS_BOUNDED_CANDIDATES_ONLY');
