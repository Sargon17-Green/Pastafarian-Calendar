import { bootstrapMonster,createMonsterContext,discoverLegacyFixedPours,
  Discovery09FixedPoursHandler,LegacyFixedBowlPoursAdapter,MonsterStageError,
  MonsterValidationError,patch08Permutation,calendarDateSpaghetti } from "../src/index.ts";
import { FOUNDATION_DAY as F,bowlOrderFromDrop } from "./normativeOracle.ts";
import { normativeThreePours } from "./discovery09Reference.ts";
function check(ok:boolean,why:string){if(!ok)throw Error(why)}
function rejects(f:()=>unknown,Cls:typeof MonsterStageError|typeof MonsterValidationError){
  try{f()}catch(e){return e instanceof Cls}return false;
}
const b=Object.freeze([101n,211n,307n,401n,503n,601n]);
const s=Object.freeze([2n,3n,5n,7n,11n]);
const ds=[1n,2n,120n,121n,240n,359n,719n,720n];
let mismatches=0,matches=0;
const contexts=new Set<object>();
for(const d of ds){
  const o=discoverLegacyFixedPours(F,F,7,d,b,s);
  const expected=normativeThreePours(7,d,b,s);
  const order=bowlOrderFromDrop(d);
  check(o.order.join(",")===order.join(",")&&
    o.order.join(",")===patch08Permutation(F,F,d).order.join(",")&&
    o.fixedBowlIds.join(",")==="1,2,3","correct order observed but fixed IDs");
  check(Object.isFrozen(o)&&Object.isFrozen(o.legacyPours)&&
    Object.isFrozen(o.inputBowls)&&Object.isFrozen(o.inputStone)&&
    o.inputBowls!==b&&o.inputStone!==s,"snapshots");
  check(!contexts.has(o.context),"independent context");contexts.add(o.context);
  let coincidences=0,conflicts=0;
  for(let p=0;p<3;p++){
    if(order[p]===p+1){
      matches++;coincidences++;
      check(o.legacyPours[p]===expected[p],"matching fixed position");
    }else{
      mismatches++;conflicts++;
      check(o.legacyPours[p]!==expected[p],"actual numeric difference");
    }
  }
  check(o.context.status==="DISCOVERY_09_RECORDED"&&
    o.context.branchTrace.join(",")===[
      "BOOTSTRAP_VALIDATE","DISCOVERY_09_CORRECT_ORDER_OBSERVED","DISCOVERY_09_FIXED_1_2_3"
    ].join(",")&&o.context.metrics.get("discovery09.calls")===1n&&
    (o.context.metrics.get("discovery09.matches")??0n)===BigInt(coincidences)&&
    (o.context.metrics.get("discovery09.conflicts")??0n)===BigInt(conflicts),
    "metrics and trace");
}
check(mismatches===16&&matches===8,"8 witnesses 24 positions");
const orig=LegacyFixedBowlPoursAdapter.prototype.legacyFixedPours;
let calls=0;
try{
  LegacyFixedBowlPoursAdapter.prototype.legacyFixedPours=function(...args){
    calls++;return orig.apply(this,args);
  };
  discoverLegacyFixedPours(F,F,1,1n,b,s);
  discoverLegacyFixedPours(F,F,46,720n,b,s);
  check(calls===2,"real legacy calls");
}finally{LegacyFixedBowlPoursAdapter.prototype.legacyFixedPours=orig}
const handler=new Discovery09FixedPoursHandler(),raw=createMonsterContext(F,F);
check(rejects(()=>handler.run(raw,1,1n,b,s),MonsterStageError)&&
  !raw.branchTrace.length&&raw.metrics.size===0,"unready context");
const ready=bootstrapMonster(F,F);
for(const i of [0,-1,47,1.5,NaN,Infinity,"1" as unknown as number])
  check(rejects(()=>handler.run(ready,i,1n,b,s),MonsterValidationError),"bad index");
for(const d of [1,"1",null,undefined,NaN] as unknown[])
  check(rejects(()=>handler.run(ready,1,d as bigint,b,s),MonsterValidationError),"bad drop");
for(const bs of [[1n,2n],Object.assign(new Array<bigint>(6),{0:1n,1:2n,3:4n,4:5n,5:6n}),
  [1n,2n,3n,4n,5n,0 as unknown as bigint]])
  check(rejects(()=>handler.run(ready,1,1n,bs,s),MonsterValidationError),"bad bowls");
for(const ss of [[1n,2n],Object.assign(new Array<bigint>(5),{0:1n,1:2n,3:4n,4:5n}),
  [1n,2n,3n,4n,5 as unknown as bigint]])
  check(rejects(()=>handler.run(ready,1,1n,b,ss),MonsterValidationError),"bad stones");
check(ready.status==="VALIDATED"&&ready.metrics.size===1&&
  ready.branchTrace.join(",")==="BOOTSTRAP_VALIDATE","preflight nonmutation");
handler.run(ready,1,1n,b,s);
check(rejects(()=>handler.run(ready,1,1n,b,s),MonsterStageError),"no reuse");
const left=discoverLegacyFixedPours(F,F,7,240n,b,s),right=discoverLegacyFixedPours(F,F,7,240n,b,s);
left.context.logs.push("first");left.context.metrics.set("private",7n);
check(left.context!==right.context&&left.inputBowls!==right.inputBowls&&
  left.legacyPours!==right.legacyPours&&!right.context.logs.length&&
  !right.context.metrics.has("private"),"ownership");
check(rejects(()=>calendarDateSpaghetti(F,F),MonsterStageError),"Stage54 boundary");
console.log(`STAGE_18_DISCOVERY_09_GUARDS_PASS witnesses=8 cells=24 mismatches=${mismatches} matches=${matches}`);
