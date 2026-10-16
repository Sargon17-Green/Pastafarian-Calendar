import {
  LegacyStructureSauceAdapter,Discovery20StructureSauceHandler,
  discoverLegacyStructureSauce,Patch19YearCacheHandler,
  bootstrapMonster,createMonsterContext,MonsterStageError,
  MonsterValidationError,calendarDateSpaghetti
} from "../src/index.ts";
import {sauce,FOUNDATION_DAY as F} from "./normativeOracle.ts";
import {buildDiscovery19Fixture,question,assert} from "./discovery19Fixtures.ts";
function rejected(fn:()=>unknown,cls:typeof MonsterStageError|typeof MonsterValidationError){
 try{fn();}catch(e){return e instanceof cls;}return false;
}
function eq(a:readonly bigint[],b:readonly bigint[]):boolean{
 return a.length===b.length&&a.every((v,i)=>v===b[i]);
}
const f=buildDiscovery19Fixture();
const cache=new Patch19YearCacheHandler();
const handler=new Discovery20StructureSauceHandler(cache);
const q1={yearQuestion:f.first,originalSauceQuestion:
  question(f.first.calculationDay,f.first.targetDay)};
const q2={yearQuestion:f.second,originalSauceQuestion:
  question(f.second.calculationDay,f.second.targetDay)};
const adapter=LegacyStructureSauceAdapter.prototype.oldStructureSauce;
let actualOld=0;
let a!:ReturnType<typeof discoverLegacyStructureSauce>;
let b!:ReturnType<typeof discoverLegacyStructureSauce>;
try {
 LegacyStructureSauceAdapter.prototype.oldStructureSauce=function(...args){
  actualOld++;return adapter.apply(this,args);
 };
 a=discoverLegacyStructureSauce(handler,q1);
 b=discoverLegacyStructureSauce(handler,q2);
}finally{LegacyStructureSauceAdapter.prototype.oldStructureSauce=adapter;}
assert(actualOld===2,"the ORIGINAL oldStructureSauce method physically ran twice");
for(const [out,q,seed] of [[a,q1,f.firstSeed],[b,q2,f.secondSeed]] as const){
 const old=sauce(q.yearQuestion.calculationDay,q.yearQuestion.targetDay);
 const corrected=sauce(q.yearQuestion.calculationDay,seed.openGateDay+1n);
 assert(out.context.status==="DISCOVERY_20_RECORDED"&&
  out.fullStage39.context.status==="PATCH_19_APPLIED"&&
  out.fullStage39.originalWrongHistory.context.status===
   "DISCOVERY_19_RECORDED"&&
  out.fullStage39.correctedServed.year.number===5000n&&
  out.yearOpenGateDay===seed.openGateDay&&
  out.yearCloseGateDay===seed.closeGateDay&&
  out.yearNumber===5000n&&out.chosenYearFirstDay===seed.openGateDay+1n&&
  out.originalTargetDay===q.yearQuestion.targetDay&&
  out.originalTargetDay!==out.chosenYearFirstDay&&
  out.historicalWrongTarget&&out.oldSauceActuallyUsed&&
  !out.correctedStructureSauceComputed&&
  !out.authoritativeStructureSauceReady&&
  out.oldSauce.oldStructureSauceCalls===1&&
  out.oldSauce.sharedMemoryWrites===58&&
  out.oldSauce.preceding.drops===46&&
  out.oldSauce.preceding.postStirs===12&&
  out.oldSauce.preceding.historical.latestSource==="STIR_12"&&
  eq(out.oldSauce.bowls,old.bowls)&&
  out.oldSauce.orderAtDrop46.join(",")===old.orderAtDrop46.join(",")&&
  (!eq(out.oldSauce.bowls,corrected.bowls)||
   out.oldSauce.orderAtDrop46.join(",")!==corrected.orderAtDrop46.join(","))&&
  out.totalRealPredecessorCalls===out.trueYearPredecessorCalls+1&&
  out.totalSharedMemoryWrites===out.fullStage39.predecessorSharedWrites+58n&&
  out.totalSharedMemoryWrites===BigInt(out.totalRealPredecessorCalls)*58n&&
  out.context.metrics.get("discovery20.old_structure_sauce_calls")===1n&&
  out.context.metrics.get("discovery20.wrong_target_witness")===1n&&
  Object.isFrozen(out)&&Object.isFrozen(out.oldSauce)&&
  Object.isFrozen(out.oldSauce.bowls)&&Object.isFrozen(out.oldSauce.orderAtDrop46),
  "true signed Year5000 + old target-based full 58-write sauce differs from correct first-day sauce");
}
assert(a.fullStage39.correctedMiss&&b.fullStage39.correctedMiss&&
 a.fullStage39.historicalWrongHit===false&&
 b.fullStage39.historicalWrongHit===true&&
 a.fullStage39.context!==b.fullStage39.context&&a.context!==b.context,
 "original Stage38 bad cache HIT remains visible, while protected Stage39 cache repairs it");
const qAtStart={
 yearQuestion:{...f.first,targetDay:f.firstSeed.openGateDay+1n},
 originalSauceQuestion:question(f.first.calculationDay,f.firstSeed.openGateDay+1n)
};
const same=discoverLegacyStructureSauce(handler,qAtStart);
assert(!same.historicalWrongTarget&&
 same.oldSauce.originalTargetDay===same.chosenYearFirstDay&&
 eq(same.oldSauce.bowls,sauce(f.first.calculationDay,same.chosenYearFirstDay).bowls)&&
 same.context.metrics.get("discovery20.wrong_target_witness")===undefined,
 "legacy oldStructureSauce happens to match only when original target is already first day");

// Rejected caller/source must have no semantic or cache side effects.
const unready=createMonsterContext(f.first.calculationDay,f.first.targetDay);
assert(rejected(()=>handler.run(unready,q1),MonsterStageError)&&
 unready.metrics.size===0&&unready.branchTrace.length===0,
 "non-ready outer owner rejected before Stage39");
const ready=bootstrapMonster(f.first.calculationDay,f.first.targetDay);
const broken={
 yearQuestion:q1.yearQuestion,
 originalSauceQuestion:{...q1.originalSauceQuestion,targetDay:f.first.targetDay+1n}
};
assert(rejected(()=>handler.run(ready,broken),MonsterValidationError)&&
 ready.status==="VALIDATED"&&ready.metrics.size===1&&
 ready.branchTrace.join(",")==="BOOTSTRAP_VALIDATE",
 "inconsistent originalTarget source rejected before full predecessor");
let faults=0;
for(const depth of ["STAGE39_DEEP","OLD_STRUCTURE_SAUCE"] as const){
 const isolated=new Discovery20StructureSauceHandler(new Patch19YearCacheHandler());
 const outer=bootstrapMonster(f.first.calculationDay,f.first.targetDay);
 const mark="STAGE40_INJECT_"+depth;
 const original=LegacyStructureSauceAdapter.prototype.oldStructureSauce;
 try{
  if(depth==="OLD_STRUCTURE_SAUCE"){
   LegacyStructureSauceAdapter.prototype.oldStructureSauce=function():never{
    throw Error(mark);
   };
  }
  const qq=depth==="STAGE39_DEEP"?
    {...q1,yearQuestion:{...q1.yearQuestion,maximumSteps:-1}}:q1;
  try{
   isolated.run(outer,qq);
   throw Error("fault not injected");
  }catch(e){
   if(depth==="STAGE39_DEEP")
    assert(e instanceof MonsterValidationError,"deep Stage39 rejects invalid step budget");
   else assert(e instanceof Error&&e.message===mark,
    "old helper fault rethrown exactly after real year calculation");
  }
  assert(outer.status==="VALIDATED"&&
   outer.branchTrace.join(",")==="BOOTSTRAP_VALIDATE"&&
   outer.metrics.size===1,
   "failed stage leaves caller-owned context unchanged");
  faults++;
 }finally{
  LegacyStructureSauceAdapter.prototype.oldStructureSauce=original;
 }
 const retried=isolated.run(outer,q1);
 assert(retried.context===outer&&retried.oldSauce.sharedMemoryWrites===58&&
  retried.context.status==="DISCOVERY_20_RECORDED",
  "same context recoverable after original scar injection");
}
const ctx=bootstrapMonster(f.first.calculationDay,f.first.targetDay);
const finished=handler.run(ctx,q1);
assert(finished.context===ctx&&
 rejected(()=>handler.run(ctx,q1),MonsterStageError),
 "committed caller owner is single-use");
a.context.metrics.set("private",42n);
assert(!b.context.metrics.has("private")&&
 !same.context.metrics.has("private")&&a.oldSauce!==b.oldSauce,
 "interleaved handlers do not alias diagnostic source/result objects");
assert(rejected(()=>calendarDateSpaghetti(F,F),MonsterStageError),
 "Stage54 integrated calendar remains forbidden");
console.log("STAGE_40_DISCOVERY_20_GUARDS_PASS realYears=2"+
 " oldSauceCalls="+actualOld+" actualWrongTarget=2"+
 " originalWrongCacheHitPreserved=1 firstDayCoincidence=1"+
 " deepFaults="+faults+" outerRollback=2"+
 " separateRealSaucePaths=2 structureSharedWrites=116"+
 " correctedStructureSauceInvoked=0");
