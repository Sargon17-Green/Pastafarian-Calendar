import {
  createMonsterContext, bootstrapMonster, LegacyInPlaceBowlStirAdapter,
  Discovery10InPlaceStirHandler, discoverLegacyInPlaceStir, patch09Pours,
  MonsterStageError, MonsterValidationError, calendarDateSpaghetti
} from "../src/index.ts";
import { FOUNDATION_DAY as F, bowlOrderFromDrop } from "./normativeOracle.ts";
import { normativeSingleStir } from "./discovery10Reference.ts";
function check(ok:boolean,why:string){if(!ok)throw Error(why)}
function rejects(fn:()=>unknown,Cls:typeof MonsterValidationError|typeof MonsterStageError){
 try{fn()}catch(e){return e instanceof Cls}return false;
}
const b=Object.freeze([101n,211n,307n,401n,503n,601n]);
const stone=Object.freeze([2n,3n,5n,7n,11n]);
const drops=[-1n,0n,1n,2n,120n,121n,719n,720n] as const;
let witnesses=0,mismatches=0,matches=0,overwritten=0;
const contexts=new Set<object>();
for(const drop of drops){
  const obs=discoverLegacyInPlaceStir(F,F,7,drop,b,stone);
  const ref=normativeSingleStir(7,drop,b,stone);
  const patchedPour=patch09Pours(F,F,7,drop,b,stone);
  check(obs.dropIndex===7&&obs.dropValue===drop&&
    obs.order.join(",")===bowlOrderFromDrop(drop).join(",")&&
    obs.pour.slice(0,3).join(",")===patchedPour.correctedPours.join(",")&&
    obs.pour.slice(3).every(v=>v===0n),"stage19 corrected pours, stage20 stir defect separate");
  check(Object.isFrozen(obs)&&Object.isFrozen(obs.steps)&&
    Object.isFrozen(obs.inputBowls)&&Object.isFrozen(obs.inputStone)&&
    Object.isFrozen(obs.legacyBowls)&&Object.isFrozen(obs.pour)&&
    obs.steps.every(s=>Object.isFrozen(s)),"deeply immutable emitted evidence");
  check(obs.inputBowls!==b&&obs.inputStone!==stone&&
    obs.inputBowls.every((v,j)=>v===b[j])&&obs.inputStone.every((v,j)=>v===stone[j]),
    "caller state untouched and pre-execution snapshot");
  check(!contexts.has(obs.context)&&obs.context.status==="DISCOVERY_10_RECORDED"&&
    obs.context.phase==="READY","separate context");contexts.add(obs.context);
  check(obs.steps.length===6&&obs.overwrittenReadSlots===6&&
    obs.contaminatedPositions===5&&
    obs.steps[0]!.previousAlreadyWritten===false&&
    obs.steps[0]!.nextAlreadyWritten===false&&
    obs.steps[5]!.previousAlreadyWritten&&
    obs.steps[5]!.nextAlreadyWritten,"5 contaminated positions, 6 contaminated read slots");
  for(let pos=1;pos<=6;pos++){
    const step=obs.steps[pos-1]!;
    const order=obs.order;
    check(step.position===pos&&step.bowlId===order[pos-1]&&
      step.previousId===order[(pos+4)%6]&&step.nextId===order[pos%6]&&
      step.newlyWrittenValue===obs.legacyBowls[step.bowlId-1],
      "real in-place write trace");
    if(obs.legacyBowls[step.bowlId-1]===ref.expectedBowls[step.bowlId-1]){
      matches++;
      check(pos===1,"only first position can match");
    }else{
      mismatches++;
      check(pos>1,"later positions visibly differ");
    }
  }
  check(obs.context.branchTrace.join(",")=== [
    "BOOTSTRAP_VALIDATE","DISCOVERY_10_PATCH09_POURS_CORRECT",
    "DISCOVERY_10_OLD_IN_PLACE_STIR","DISCOVERY_10_LATER_READS_OBSERVE_WRITES"
  ].join(",")&&obs.context.metrics.get("bootstrap.calls")===1n&&
    obs.context.metrics.get("discovery10.calls")===1n&&
    obs.context.metrics.get("discovery10.immediate_writes")===6n&&
    obs.context.metrics.get("discovery10.overwritten_read_slots")===6n&&
    obs.context.metrics.get("discovery10.contaminated_positions")===5n,
    "metrics and actual history");
  witnesses++;overwritten+=obs.overwrittenReadSlots;
}
check(witnesses===8&&mismatches===40&&matches===8&&overwritten===48,
  "8 witnessed 6-bowl strokes: 40 wrong and 8 initial matches");

// Real historical helper must mutate its owned work array inside call.
const legacy=new LegacyInPlaceBowlStirAdapter();
const first=discoverLegacyInPlaceStir(F,F,7,120n,b,stone);
const localWork=[...b];
const steps=legacy.stirInPlace(F,F,7,120n,stone,first.order,first.pour,localWork);
check(localWork.join(",")===first.legacyBowls.join(",")&&
  localWork.some((v,j)=>v!==b[j])&&
  steps.length===6&&steps[1]!.previousAlreadyWritten&&
  b.every((v,j)=>v===[101n,211n,307n,401n,503n,601n][j]),
  "legacy method really mutates provided array, not user-owned input");
const original=LegacyInPlaceBowlStirAdapter.prototype.stirInPlace;
const calls:(readonly bigint[])[]=[];
try{
 LegacyInPlaceBowlStirAdapter.prototype.stirInPlace=function(...args){
   calls.push(args[6]);
   return original.apply(this,args);
 };
 const o=discoverLegacyInPlaceStir(F,F,2,120n,b,stone);
 check(calls.length===1&&calls[0]!==b&&
   calls[0]!.every((v,j)=>v===o.legacyBowls[j]),
   "production discovery actually invokes unchanged in-place helper");
}finally{LegacyInPlaceBowlStirAdapter.prototype.stirInPlace=original}

const handler=new Discovery10InPlaceStirHandler(),unready=createMonsterContext(F,F);
check(rejects(()=>handler.run(unready,1,1n,b,stone),MonsterStageError)&&
 unready.status==="NEW"&&!unready.metrics.size&&!unready.branchTrace.length,
 "not-ready context rejected before mutation");
const ready=bootstrapMonster(F,F);
for(const i of [0,-1,47,1.5,NaN,Infinity,"1" as unknown as number])
 check(rejects(()=>handler.run(ready,i,1n,b,stone),MonsterValidationError),"invalid drop ordinal");
for(const d of [1,"1",null,undefined,NaN] as unknown[])
 check(rejects(()=>handler.run(ready,1,d as bigint,b,stone),MonsterValidationError),"invalid drop bigint");
for(const bs of [[1n,2n],Object.assign(new Array<bigint>(6),{0:1n,1:2n,3:4n,4:5n,5:6n}),
 [1n,2n,3n,4n,5n,0 as unknown as bigint]])
 check(rejects(()=>handler.run(ready,1,1n,bs,stone),MonsterValidationError),"invalid bowls");
for(const ss of [[1n,2n],Object.assign(new Array<bigint>(5),{0:1n,1:2n,3:4n,4:5n}),
 [1n,2n,3n,4n,5 as unknown as bigint]])
 check(rejects(()=>handler.run(ready,1,1n,b,ss),MonsterValidationError),"invalid stones");
check(rejects(()=>handler.run({...ready,calculationDay:null as unknown as bigint},1,1n,b,stone),
 MonsterValidationError),"invalid context day");
check(ready.status==="VALIDATED"&&ready.metrics.size===1&&
 ready.branchTrace.join(",")==="BOOTSTRAP_VALIDATE","invalid calls leave context unchanged");
handler.run(ready,1,1n,b,stone);
check(rejects(()=>handler.run(ready,1,1n,b,stone),MonsterStageError),"context cannot be reused");
const a=discoverLegacyInPlaceStir(F,F,7,120n,b,stone);
const c=discoverLegacyInPlaceStir(F,F,7,120n,b,stone);
a.context.metrics.set("private",99n);a.context.logs.push("पहिला");
check(a.context!==c.context&&a.inputBowls!==c.inputBowls&&
 a.legacyBowls!==c.legacyBowls&&a.steps!==c.steps&&
 !c.context.metrics.has("private")&&!c.context.logs.length,"per-call ownership");
check(rejects(()=>calendarDateSpaghetti(F,F),MonsterStageError),"Stage54 route remains unavailable");
console.log(`STAGE_20_DISCOVERY_10_GUARDS_PASS witnesses=${witnesses} positions=48 mismatches=${mismatches} matches=${matches} overwrittenReads=${overwritten} contaminatedPositions=40`);
