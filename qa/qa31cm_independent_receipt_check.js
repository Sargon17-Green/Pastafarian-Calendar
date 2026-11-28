// QA31CM independent arithmetic receipt check; not a Native execution or source proof.
// Node.js: node qa/qa31cm_independent_receipt_check.js
function audit(raw, fixture) {
  const need=(condition,message)=>{if(!condition)throw Error(message)};
  const M=(1n<<127n)-1n, origin=15055671n;
  const abs=n=>n<0n?-n:n;
  const residue=n=>1n+((n-1n)%M+M)%M;
  const count=n=>{const h=n+origin;return h<0n?-2n*h:2n*h+1n};
  const atom=s=>{s=s.trim();need(/^\d+(?:\*\*\d+)?(?:-\d+)?$/.test(s),"unsupported fixture expression");const [base,sub]=s.split("-"), [b,e]=base.split("**");return (e===undefined?BigInt(b):BigInt(b)**BigInt(e))-BigInt(sub||0)};
  const cases=new Map();
  const block=fixture.match(/^CASES=\[([\s\S]*?)^\]/m);
  need(block,"fixture block missing");
  for(const m of block[1].matchAll(/^\s*\("([^"]+)",\s*\(([^)]*)\),\s*(True|False)\),/gm)){
    need(!cases.has(m[1]),"duplicate fixture"); const f=m[2].split(",").map(atom);
    need(f.length===4,"fixture width");cases.set(m[1],{f,valid:m[3]==="True"});
  }
  need(cases.size===17,"fixture case count");
  // Preserve exact integer tokens rather than letting JSON.parse round 127-bit values.
  const lossless=raw.replace(/("output"\s*:\s*\[)([\s\S]*?)(\])/g,(_,a,b,c)=>a+b.replace(/-?\d+/g,s=>JSON.stringify(s))+c);
  const data=JSON.parse(lossless);
  need(data.source_git_blob==="560d6aa5807a7f766213a33835cce85eab0fa40c"&&data.normative_counts==="f941efc793c9eee4accf5d03873f8ed029b16725"&&data.normative_save==="7b5e79aa6e2bfb636717cb018a3db6a13fb2bb44","reported source pins");
  function validate(rows,total){
    need(rows.length===cases.size,"case count");
    const seen=new Set(); let sum=0,fields=0;
    for(const row of rows){
      need(cases.has(row.case)&&!seen.has(row.case),"case identity");seen.add(row.case);
      const {f,valid:declared}=cases.get(row.case),[a,b,c,d]=f;
      const valid=(a===0n||a===1n)&&(c===0n||c===1n)&&b>=a&&d>=c;
      need(valid===declared&&valid===row.valid,"validity");
      const x=a===1n?-b:b,y=c===1n?-d:d;
      const expected=valid?[count(x),count(y),abs(y-x)+1n,count(x)+count(y),x===y?2n:x<y?3n:1n,residue(x),residue(y)]:Array(7).fill(-1n);
      need(row.output.length===7&&row.output.every((v,i)=>typeof v==="string"&&/^-?\d+$/.test(v)&&BigInt(v)===expected[i]),"field mismatch "+row.case);
      const n=b>d?b:d, digits=n===0n?0:n.toString().length;
      need(row.steps===2326*digits+(valid?6134:6010),"step count "+row.case);
      sum+=row.steps;fields+=7;
    }
    need(sum===total,"step total");
    return {cases:seen.size,fields,steps:sum};
  }
  const original=validate(data.native_cases,data.native_steps_from_first_gate);
  let rejected=0;
  const hostile=mutate=>{const rows=JSON.parse(JSON.stringify(data.native_cases));let failed=false;try{mutate(rows);validate(rows,data.native_steps_from_first_gate)}catch(e){failed=true}need(failed,"hostile accepted");rejected++};
  for(let i=0;i<17;i++){
    for(let j=0;j<7;j++)hostile(rows=>{rows[i].output[j]=(BigInt(rows[i].output[j])+1n).toString()});
    hostile(rows=>{rows[i].steps++});
    hostile(rows=>{rows[i].valid=!rows[i].valid});
  }
  hostile(rows=>rows.pop());hostile(rows=>{rows[1].case=rows[0].case});
  return {...original,hostile_rejected:rejected,new_native_runs:0,stage1_accepted:false};
}
const fs=require('node:fs');
console.log(JSON.stringify(audit(fs.readFileSync('qa/qa31cm_results.json','utf8'),fs.readFileSync('qa/stage1_native_diverse_geometry.py','utf8')),null,2));
