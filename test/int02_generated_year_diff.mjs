// PC-BRANCH-COBOL-SIMPLIFIED-CHINESE | INT-02 generated window native differential.
import {readFileSync} from 'node:fs';
import {spawnSync} from 'node:child_process';
import assert from 'node:assert/strict';
const cases=JSON.parse(readFileSync(new URL('./int02_generated_year_vectors.json',import.meta.url),'utf8'));
const executable=process.argv[2]; if(!executable)throw Error('executable required');
let checks=0;
for(const c of cases.concat([-15075672,-15035670].map(action=>({action,window:[],pairs:[],rank:0,year:[0,0],status:22})))){
 const p=spawnSync(executable,[],{input:String(c.action)+'\n',encoding:'utf8',timeout:300000,maxBuffer:1024*1024});
 if(p.error||p.status!==0)throw Error(JSON.stringify({action:c.action,error:String(p.error),status:p.status,stderr:p.stderr}));
 const lines=p.stdout.trim().split(/\r?\n/).map(l=>l.trim().split(/\s+/).map(Number));
 assert.deepEqual(lines[0],[c.status??0,c.window.length,c.pairs.length,c.rank,...c.year],String(c.action));
 assert.deepEqual(lines.slice(1,1+c.window.length).map(x=>x[0]),c.window);
 assert.deepEqual(lines.slice(1+c.window.length),c.pairs);
 checks++;console.log('ACTION='+c.action+' MATCH');
}
console.log('INT02_GENERATED_YEAR_CASES='+checks+' GATE=MATCH_NATIVE_BOUNDED_ONLY');
