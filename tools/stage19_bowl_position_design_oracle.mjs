// Stage19 independent design oracle for normative op53 / production op36.
// Node.js 20+. No FALSE source, production code, or fixture-generator imports.
import fs from "node:fs";
function permutationsLex() {
  const out = [];
  function visit(prefix, remaining) {
    if (!remaining.length) { out.push(prefix); return; }
    for (let i = 0; i < remaining.length; i++)
      visit([...prefix, remaining[i]], [...remaining.slice(0,i), ...remaining.slice(i+1)]);
  }
  visit([], [1,2,3,4,5,6]); return out;
}
// op53 stops on the first equality: duplicate values resolve to the first position.
function position(order, bowlId) {
  if (!Array.isArray(order) || order.length !== 6) throw new Error("six values required");
  for (let i=0;i<6;i++) if (order[i] === bowlId) return i+1;
  return 0;
}
const all=permutationsLex();
if(all.length!==720||new Set(all.map(x=>x.join(","))).size!==720)throw Error("permutation enumeration");
let exhaustive=0,inverseChecks=0;
for(const order of all){
  const positions=[1,2,3,4,5,6].map(id=>position(order,id));
  if(positions.some(p=>p<1||p>6)||new Set(positions).size!==6)throw Error("not bijective");
  for(let id=1;id<=6;id++){const p=position(order,id);if(order[p-1]!==id)throw Error("inverse property");exhaustive++;inverseChecks++;}
}
const probes=[
{label:"identity-first",order:[1,2,3,4,5,6],bowl_id:1,expected:1},
{label:"identity-last",order:[1,2,3,4,5,6],bowl_id:6,expected:6},
{label:"reverse-first",order:[6,5,4,3,2,1],bowl_id:1,expected:6},
{label:"reverse-last",order:[6,5,4,3,2,1],bowl_id:6,expected:1},
{label:"rotation-wrap",order:[2,3,4,5,6,1],bowl_id:1,expected:6},
{label:"duplicate-first-match",order:[1,2,1,4,5,6],bowl_id:1,expected:1},
{label:"duplicate-missing",order:[1,2,1,4,5,6],bowl_id:3,expected:0},
{label:"negative-value",order:[0,-2,7,9,4,5],bowl_id:-2,expected:2},
{label:"noncanonical-positive",order:[0,-2,7,9,4,5],bowl_id:7,expected:3},
{label:"not-found",order:[0,-2,7,9,4,5],bowl_id:8,expected:0},
{label:"all-duplicates-first",order:[6,6,6,6,6,6],bowl_id:6,expected:1},
{label:"all-duplicates-absent",order:[6,6,6,6,6,6],bowl_id:1,expected:0}
];
for(const p of probes)if(position(p.order,p.bowl_id)!==p.expected)throw Error("probe "+p.label);
const mutants={
zero_based:{order:[1,2,3,4,5,6],bowl_id:1,wrong:0,expected:1},
last_match:{order:[1,2,1,4,5,6],bowl_id:1,wrong:3,expected:1},
always_zero:{order:[6,5,4,3,2,1],bowl_id:1,wrong:0,expected:6},
scan_five:{order:[1,2,3,4,5,6],bowl_id:6,wrong:0,expected:6}
};
for(const [name,m] of Object.entries(mutants))if(m.wrong===m.expected||position(m.order,m.bowl_id)!==m.expected)throw Error("mutant witness "+name);
const vectors={project_id:"PC-BRANCH-FALSE-ARABIC",stage:19,scope:"DESIGN_ONLY",normative_operation:53,planned_production_operation:36,reference_git_blob:"3e9acc012bedf83294a6ec3cccb081a069556b5b",input:"allocated two-cell tuple [directOrderTable,bowlId]; directOrderTable=[6,v1,...,v6]",output:"greatest 1-based position i in 1..6 where vi===bowlId, or 0 when absent",probes};
const summary={project_id:"PC-BRANCH-FALSE-ARABIC",stage:19,scope:"DESIGN_ONLY",normative_operation:53,planned_production_operation:36,reference_git_blob:"3e9acc012bedf83294a6ec3cccb081a069556b5b",algorithm:"linear scan positions 1..6; return immediately on first equality; default 0",independent_permutation_generator:"recursive lexical enumeration in JavaScript",permutations:all.length,exhaustive_position_cases:exhaustive,inverse_property_checks:inverseChecks,probe_cases:probes.length,mutant_witnesses:Object.fromEntries(Object.entries(mutants).map(([k,v])=>[k,{order:v.order,bowl_id:v.bowl_id,wrong:v.wrong,expected:v.expected}])),native_run:false,stage19_accepted:false,physical_pointer_safety_assessed:false};
fs.mkdirSync("evidence",{recursive:true});fs.mkdirSync("test",{recursive:true});
fs.writeFileSync("test/stage19_bowl_position_design_vectors.json",JSON.stringify(vectors,null,2)+"\n");
fs.writeFileSync("evidence/stage19_bowl_position_design_oracle_2026-11-21.json",JSON.stringify(summary,null,2)+"\n");
process.stdout.write(JSON.stringify(summary,null,2)+"\n");
