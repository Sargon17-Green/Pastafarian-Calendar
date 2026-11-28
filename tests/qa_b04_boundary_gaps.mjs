// PC-BRANCH-WAT-SPANISH: QA aislada B04, sin modificar el selector original.
// Node.js >= 18. Uso: node tests/qa_b04_boundary_gaps.mjs --oracle-only
// Generar: node tests/qa_b04_boundary_gaps.mjs --generate tests/normative_selector.wat /tmp/b04-gaps.wat
// Compilar: wat2wasm /tmp/b04-gaps.wat -o /tmp/b04-gaps.wasm
// Probar: node tests/qa_b04_boundary_gaps.mjs --check /tmp/b04-gaps.wasm C1|C2|C3|C4|C5C6
// Native WasmKit no se ejecuta con este script.
import {readFileSync,writeFileSync} from 'node:fs';
import {createHash} from 'node:crypto';
import assert from 'node:assert/strict';
const SOURCE_SHA256='18e2c15a142b3a262ff38a1e084d86bdc1a139ce030b0318f279dbcdb23f8980';
const SOURCE_BLOB='e23f013ab96b498b0ac365dbb1b25273c845e790';
function cases() {
  const M=(1n<<127n)-1n;
  const specs=[["C1",M,M,-1],["C2",M+1n,M,-1],["C3",2n*M,1n,-1],["C4",3n*M,1n,-1],["C5",2n*M,M-1n,1],["C6",3n*M,M-1n,1]];
  const step=(v,s,size)=>((v-1n+BigInt(s)+size)%size)+1n;
  return specs.map(([id,n,first,s])=>{
    let space=1n,k=0; while(space<n){space*=M;k++;}
    let x=1n,weight=1n,a=first;
    for(let j=0;j<k;j++){x+=(a-1n)*weight;weight*=M;a=step(a,s,M);}
    const limit=space/n*n;
    let accepted=x,rejections=0;
    while(accepted>limit){if(rejections===2)throw Error("unexpected rejection bound "+id);accepted=step(accepted,s,space);rejections++;}
    return {id,n,first,s,k,space,x,limit,accepted,rejections,rank:(accepted-1n)%n+1n};
  });
}
const rows=cases();
const M=(1n<<127n)-1n,U=M*M;
const expected=[[M,M,0],[2n,U-1n,0],[2n*M,U-M,1],[3n*M,U-M,1],[1n,U-M,2],[1n,U-M,2]];
for(let i=0;i<rows.length;i++) {
  assert.deepEqual([rows[i].rank,rows[i].limit,rows[i].rejections],expected[i]);
}
const json=(v)=>JSON.stringify(v,(_,x)=>typeof x==='bigint'?String(x):x);
const B=1n<<30n;
function limbs(x){const out=[];while(x>0n){out.push(Number(x%B));x/=B;}return out;}
function put(p,v) {
  const a=limbs(v);
  return ['(i32.store (global.get $'+p+') (i32.const '+a.length+'))',...a.map((x,i)=>'(i32.store offset='+((i+1)*4)+' (global.get $'+p+') (i32.const '+x+'))')].join('\n    ');
}
function exact(p,v){
  const a=limbs(v);
  return ['(if (i32.ne (i32.load (global.get $'+p+')) (i32.const '+a.length+')) (then (return (i32.const 0))))',...a.map((x,i)=>'(if (i32.ne (i32.load offset='+((i+1)*4)+' (global.get $'+p+')) (i32.const '+x+')) (then (return (i32.const 0))))')].join('\n    ');
}
function wrapper(row){
  return ['(call $init_constants)',put('FIRST',row.first),put('N',row.n),
    // Poison output lengths before invocation so stale cells cannot pass.
    ...['RESULT','LIMIT','SPACE'].map(p=>'(i32.store (global.get $'+p+') (i32.const 0))'),
    '(call $choose (global.get $FIRST) (i32.const '+row.s+') (global.get $N) (global.get $RESULT))',
    exact('RESULT',row.rank),exact('LIMIT',row.limit),...(row.k===2?[exact('SPACE',row.space)]:[])].join('\n    ');
}
const groups=[...rows.slice(0,4).map(r=>[r.id,[r]]),['C5C6',rows.slice(4)]];
const prefix='qa_b04_gap_';
function generate(original){
  const digest=createHash('sha256').update(original).digest('hex');
  const blob=createHash('sha1').update('blob '+original.length+'\0').update(original).digest('hex');
  assert.equal(digest,SOURCE_SHA256,'source SHA-256 mismatch');
  assert.equal(blob,SOURCE_BLOB,'Git blob mismatch');
  const text=original.toString('utf8').trimEnd();
  assert(text.endsWith(')')&&!text.includes(prefix),'unexpected source shape');
  // Only add QA functions inside the module; all original source instructions unchanged.
  const funcs=groups.map(([id,rs])=>'(func (export "'+prefix+id+'") (result i32)\n    '+rs.map(wrapper).join('\n    ')+'\n    (i32.const 1))').join('\n  ');
  return text.slice(0,-1)+'\n  '+funcs+'\n)\n';
}
const [mode,a,b]=process.argv.slice(2);
if(mode==='--oracle-only'&&!a){
  console.log(json({project_id:'PC-BRANCH-WAT-SPANISH',mode:'BigInt oracle only',cases:rows,native:'NOT_RUN'}));
}else if(mode==='--generate'&&a&&b){
  writeFileSync(b,generate(readFileSync(a)),{flag:'wx'});
  console.log(json({source_sha256:SOURCE_SHA256,source_blob:SOURCE_BLOB,output:b,units:5,cases:6,native:'NOT_RUN'}));
}else if(mode==='--check'&&a&&groups.some(([id])=>id===b)){
  const bytes=readFileSync(a);
  const {instance}=await WebAssembly.instantiate(bytes);
  const actual=instance.exports[prefix+b]();
  console.log(json({engine:'Node WebAssembly',unit:b,actual,wasm_sha256:createHash('sha256').update(bytes).digest('hex')}));
  assert.equal(actual,1);
}else{throw Error('usage: --oracle-only | --generate INPUT OUTPUT | --check WASM C1/C2/C3/C4/C5C6');}
