"use strict";
// QA31CM independent receipt consistency audit. Synthetic controls are not Native evidence.
// Scope: exact receipt schema/order/blob, owner classes and snapshot union cardinality.
// Does not prove identity, old-space values or completeness of put interception.
const specs={
  "base_context": [
    4,
    false,
    "6376aa99e42b4a2ec108ed5ce3e339ee2c587fe3"
  ],
  "bootstrap": [
    1,
    true,
    "6da65824962ed32e0980a1cf9fd6be981fbd82b6"
  ],
  "base_validator": [
    1,
    false,
    "8ae28bc67505975cbfd997866f51cb5335cd2b3d"
  ],
  "interleaved_day_save": [
    2,
    true,
    "4da7c9af6d5b52a42f3fc7679c42eec0e51fc6dc"
  ],
  "metrics_shell": [
    2,
    false,
    "312166a72f865b5bfe0d1ed7dafaf39d7f580c00"
  ],
  "day_count": [
    1,
    true,
    "4f25f514f7b6362105dfff77db6f36769efe36c3"
  ],
  "error_wrapper": [
    1,
    false,
    "8d8f440eb3e5f024009872b8abfa7536a1e53c02"
  ],
  "save": [
    1,
    true,
    "dd6f10aa196e3a9523ee786e4ba41a91f303d199"
  ],
  "runtime_contract": [
    1,
    false,
    "5ef55c10ade3b74d70db022e996d89f83a753bf8"
  ],
  "logging_shell": [
    2,
    false,
    "312166a72f865b5bfe0d1ed7dafaf39d7f580c00"
  ],
  "interleaved_work_counts": [
    7,
    true,
    "560d6aa5807a7f766213a33835cce85eab0fa40c"
  ]
};
const seq=[["base_context",""],["bootstrap","10"],["base_validator","1 0"],["interleaved_day_save","1 15055672"],["metrics_shell","42 7"],["day_count","0 0"],["error_wrapper","1 42"],["save","1 1"],["runtime_contract",""],["logging_shell","42 7"],["interleaved_work_counts","0 0 0 1"],["day_count","1 0"],["interleaved_day_save","0 0"],["save","0 0"],["base_context",""]];
const base=[[0,0],[5,0],[10,49],[500,1500],[100,500],[1528,2014]];
function audit(rows) {
 const fail=(s)=>{throw Error(s)};
 const equal=(a,b)=>JSON.stringify(a)===JSON.stringify(b);
 const cmp=(a,b)=>a[0]-b[0]||a[1]-b[1];
 const key=p=>p.join(",");
 if(!Array.isArray(rows)||rows.length!==seq.length)fail("count");
 let previous=base.length, fields=0, writers=0;
 for(let i=0;i<seq.length;i++){
  const r=rows[i], [n,input]=seq[i], [width,writer,blob]=specs[n];
  if(!r||r.path!==`src/${n}.b98`||r.input!==input+"\n"||r.source_blob!==blob)fail("source/order/input "+i);
  if(!Array.isArray(r.output)||r.output.length!==width||!r.output.every(v=>typeof v==="string"&&/^(0|-?[1-9][0-9]*)$/.test(v))||!equal(r.output,r.native_fresh_cli))fail("output parity/width "+i);
  const w=r.written_addresses;
  if(!Array.isArray(w)||w.some(p=>!Array.isArray(p)||p.length!==2||!p.every(Number.isSafeInteger))||w.some((p,j)=>j>0&&cmp(w[j-1],p)>=0)||Boolean(w.length)!==writer)fail("writer/address "+i);
  const retained=new Set([...base,...w].map(key)).size;
  if(r.previous_addresses_checked!==previous||r.retained_addresses!==retained)fail("snapshot count "+i);
  previous=retained;fields+=width;writers+=Number(writer);
  if(n==="base_context"&&!equal(r.output,["1","0","0","0"]))fail("context oracle");
  if(["metrics_shell","logging_shell"].includes(n)&&!equal(r.output,["42","8"]))fail("shell oracle");
  if(n==="interleaved_work_counts"&&!equal(r.output,["30111343","30111345","2","60222688","3","170141183460469231731687303715884105727","1"]))fail("work-count oracle");
 }
 return {rows:rows.length,fields,writer_executions:writers,distinct_sources:new Set(seq.map(x=>x[0])).size,scope:"receipt consistency only; not Native or Stage1 acceptance"};
}
function selftest(){
 const rows=seq.map(([n,input],i)=>{const [width,writer,blob]=specs[n];let output=Array(width).fill("0");if(n==="base_context")output=["1","0","0","0"];if(["metrics_shell","logging_shell"].includes(n))output=["42","8"];if(n==="interleaved_work_counts")output=["30111343","30111345","2","60222688","3","170141183460469231731687303715884105727","1"];return {path:`src/${n}.b98`,input:input+"\n",source_blob:blob,output,native_fresh_cli:[...output],written_addresses:writer?[[0,0],[42,42]]:[],retained_addresses:writer?7:6,previous_addresses_checked:i&&specs[seq[i-1][0]][1]?7:6}});
 const positive=audit(rows);
 const mutations=[r=>r.pop(),r=>r.reverse(),r=>r[0].source_blob="0",r=>r[1].input="11\n",r=>r[1].written_addresses=[],r=>r[0].written_addresses=[[42,42]],r=>r[1].written_addresses.reverse(),r=>r[1].written_addresses.push([42,42]),r=>r[1].written_addresses[1]=[1.5,2],r=>r[1].retained_addresses++,r=>r[2].previous_addresses_checked--,r=>r[0].output.pop(),r=>r[2].output[0]="01",r=>r[2].native_fresh_cli[0]="1",r=>{r[10].output[0]="0";r[10].native_fresh_cli[0]="0"},r=>{r[4].output[0]="0";r[4].native_fresh_cli[0]="0"}];
 let rejected=0;for(const mutate of mutations){const r=JSON.parse(JSON.stringify(rows));mutate(r);try{audit(r)}catch(e){rejected++}}
 if(rejected!==mutations.length)throw Error("hostile control escaped");return {synthetic:true,positive,rejected,total:mutations.length};
}
if(require.main===module){const arg=process.argv[2];if(!arg)throw Error("usage: node qa/qa31cm_reset_receipt_audit.js --selftest|entrypoints.json");console.log(JSON.stringify(arg==="--selftest"?selftest():audit(JSON.parse(require("fs").readFileSync(arg,"utf8"))),null,2));}
