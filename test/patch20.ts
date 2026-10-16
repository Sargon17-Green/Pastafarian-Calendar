import {
 LegacyStructureSauceAdapter,Discovery20StructureSauceHandler,
 Patch20StructureSauceHandler,patch20StructureSauce,
 Patch19YearCacheHandler,Patch11OrderLatchHandler,
 bootstrapMonster,createMonsterContext,MonsterStageError,
 MonsterValidationError,calendarDateSpaghetti
} from "../src/index.ts";
import {sauce,FOUNDATION_DAY as F} from "./normativeOracle.ts";
import {buildDiscovery19Fixture,question,assert} from "./discovery19Fixtures.ts";
function eq(a:readonly bigint[],b:readonly bigint[]):boolean{
 return a.length===b.length&&a.every((v,j)=>v===b[j]);
}
function rejected(fn:()=>unknown,cls:typeof MonsterStageError|typeof MonsterValidationError){
 try{fn();}catch(e){return e instanceof cls;}return false;
}
const f=buildDiscovery19Fixture();
const outerCache=new Patch19YearCacheHandler();
const handler=new Patch20StructureSauceHandler(
 new Discovery20StructureSauceHandler(outerCache));
function request(q:typeof f.first,open:bigint){
 return {
  historical:{
   yearQuestion:q,
   originalSauceQuestion:question(q.calculationDay,q.targetDay)
  },
  firstDaySauceQuestion:question(q.calculationDay,open+1n)
 };
}
const q1=request(f.first,f.firstSeed.openGateDay);
const q2=request(f.second,f.secondSeed.openGateDay);
const original=LegacyStructureSauceAdapter.prototype.oldStructureSauce;
const actualNative=Patch11OrderLatchHandler.prototype.run;
let oldCalls=0,correctedFirstDayCalls=0;
let a!:ReturnType<typeof patch20StructureSauce>;
let b!:ReturnType<typeof patch20StructureSauce>;
try{
 LegacyStructureSauceAdapter.prototype.oldStructureSauce=function(...args){
  oldCalls++;return original.apply(this,args);
 };
 Patch11OrderLatchHandler.prototype.run=function(...args){
  const [ctx]=args;
  if((ctx.calculationDay===f.first.calculationDay&&
      ctx.targetDay===f.firstSeed.openGateDay+1n)||
     (ctx.calculationDay===f.second.calculationDay&&
      ctx.targetDay===f.secondSeed.openGateDay+1n))
     correctedFirstDayCalls++;
  return actualNative.apply(this,args);
 };
 a=patch20StructureSauce(handler,q1);
 b=patch20StructureSauce(handler,q2);
}finally{
 LegacyStructureSauceAdapter.prototype.oldStructureSauce=original;
 Patch11OrderLatchHandler.prototype.run=actualNative;
}
assert(oldCalls===2&&correctedFirstDayCalls===2,
 "oldStructureSauce and corrected first-day native patch11 physically run for each true year");
for(const [out,q,seed] of [[a,q1,f.firstSeed],[b,q2,f.secondSeed]] as const){
 const c=q.historical.yearQuestion.calculationDay;
 const t=q.historical.yearQuestion.targetDay;
 const oracle=sauce(c,seed.openGateDay+1n);
 const wrong=sauce(c,t);
 assert(out.context.status==="PATCH_20_APPLIED"&&
  out.historical.context.status==="DISCOVERY_20_RECORDED"&&
  out.historical.fullStage39.context.status==="PATCH_19_APPLIED"&&
  out.historical.fullStage39.correctedServed.year.openGateDay===seed.openGateDay&&
  out.historical.fullStage39.correctedServed.year.closeGateDay===seed.closeGateDay&&
  out.historical.oldSauceActuallyUsed&&
  out.historical.correctedStructureSauceComputed===false&&
  out.historical.historicalWrongTarget&&out.historicalGhostWasWrongTarget&&
  out.historical.oldSauce.sharedMemoryWrites===58&&
  out.trueYearNumber===5000n&&out.trueYearFirstDay===seed.openGateDay+1n&&
  out.requiredFirstDaySubstitution&&out.firstDaySauceCalls===1&&
  out.oldSauceCalls===1&&out.realStructureSauceCalls===2&&
  out.newFirstDaySauce!==null&&
  out.newFirstDaySauce.sharedMemoryWrites===58&&
  out.newFirstDaySauce.latchCaptures===1&&
  out.newFirstDaySauce.drops===46&&
  out.newFirstDaySauce.postStirs===12&&
  out.newFirstDaySauce.historical.latestSource==="STIR_12"&&
  eq(out.authoritativeBowls,oracle.bowls)&&
  out.authoritativeOrderAtDrop46.join(",")===oracle.orderAtDrop46.join(",")&&
  eq(out.historical.oldSauce.bowls,wrong.bowls)&&
  out.historical.oldSauce.orderAtDrop46.join(",")===wrong.orderAtDrop46.join(",")&&
  (!eq(out.authoritativeBowls,out.historical.oldSauce.bowls)||
   out.authoritativeOrderAtDrop46.join(",")!==
    out.historical.oldSauce.orderAtDrop46.join(","))&&
  out.totalRealPredecessorCalls===out.historical.totalRealPredecessorCalls+1&&
  out.totalSharedMemoryWrites===out.historical.totalSharedMemoryWrites+58n&&
  out.totalSharedMemoryWrites===BigInt(out.totalRealPredecessorCalls)*58n&&
  out.context.metrics.get("patch20.new_first_day_sauce_calls")===1n&&
  out.context.metrics.get("patch20.old_structure_sauce_calls")===1n&&
  out.context.branchTrace.join(",")=== [
   "BOOTSTRAP_VALIDATE",
   "PATCH_20_FULL_STAGE40_OLD_TARGET_SAUCE_ACTUALLY_EXECUTED",
   "PATCH_20_FIRST_DAY_CORRECTED_58_WRITE_NATIVE_SAUCE",
   "PATCH_20_STRUCTURE_SAUCE_AUTHORITATIVE"
  ].join(",")&&
  Object.isFrozen(out)&&Object.isFrozen(out.authoritativeBowls)&&
  Object.isFrozen(out.authoritativeOrderAtDrop46)&&
  Object.isFrozen(out.historical.oldSauce),
  "two independent true Year5000 first-day Sauces correct and old ghost preserved");
}
assert(b.historical.fullStage39.historicalWrongHit,
 "archived Stage38 wrong number-only cached HIT still occurred under true Stage39 protection");

// Exact first-day case: still physically execute Stage40 old helper but
// never execute a second 58-write Sauce.
const firstQ={
 ...f.first,targetDay:f.firstSeed.openGateDay+1n
};
const equalCase={
 historical:{
  yearQuestion:firstQ,
  originalSauceQuestion:question(f.first.calculationDay,firstQ.targetDay)
 }
};
let newFirstCallCount=0,oldPhysicalCalls=0;
try{
 LegacyStructureSauceAdapter.prototype.oldStructureSauce=function(...args){
  oldPhysicalCalls++;return original.apply(this,args);
 };
 Patch11OrderLatchHandler.prototype.run=function(...args){
  const [ctx]=args;
  if(ctx.calculationDay===f.first.calculationDay&&
     ctx.targetDay===firstQ.targetDay)newFirstCallCount++;
  return actualNative.apply(this,args);
 };
 const same=patch20StructureSauce(handler,equalCase);
 assert(!same.requiredFirstDaySubstitution&&
  same.firstDaySauceCalls===0&&same.newFirstDaySauce===null&&
  same.realStructureSauceCalls===1&&
  same.totalRealPredecessorCalls===same.historical.totalRealPredecessorCalls&&
  same.totalSharedMemoryWrites===same.historical.totalSharedMemoryWrites&&
  eq(same.authoritativeBowls,sauce(f.first.calculationDay,firstQ.targetDay).bowls)&&
  same.authoritativeOrderAtDrop46.join(",")===
    sauce(f.first.calculationDay,firstQ.targetDay).orderAtDrop46.join(",")&&
  oldPhysicalCalls===1&&newFirstCallCount===1&&
  same.context.metrics.get("patch20.new_first_day_sauce_calls")===0n,
  "first day reuses physically computed ghost, no separate second Sauce invocation");
}finally{
 LegacyStructureSauceAdapter.prototype.oldStructureSauce=original;
 Patch11OrderLatchHandler.prototype.run=actualNative;
}

// Validation & late faults must not commit caller context.
const unready=createMonsterContext(f.first.calculationDay,f.first.targetDay);
assert(rejected(()=>handler.run(unready,q1),MonsterStageError)&&
 unready.metrics.size===0&&unready.branchTrace.length===0,
 "unready ctx blocked before predecessor");
const ready=bootstrapMonster(f.first.calculationDay,f.first.targetDay);
assert(rejected(()=>handler.run(ready,{...q1,historical:{
 ...q1.historical,yearQuestion:{...f.first,targetDay:f.first.targetDay+1n}
}}),MonsterValidationError)&&
 ready.status==="VALIDATED"&&ready.metrics.size===1,
 "mismatched historical request blocked");
const broken={...q1,firstDaySauceQuestion:{
 ...q1.firstDaySauceQuestion,targetDay:f.firstSeed.openGateDay+2n
}};
assert(rejected(()=>handler.run(ready,broken),MonsterValidationError)&&
 ready.status==="VALIDATED"&&ready.metrics.size===1&&
 ready.branchTrace.join(",")==="BOOTSTRAP_VALIDATE",
 "wrong first-day source rejected even after true Stage40 predecessor");
let faults=0;
for(const depth of ["OLD_GHOST","NEW_FIRST_DAY"] as const){
 const isolated=new Patch20StructureSauceHandler(
  new Discovery20StructureSauceHandler(new Patch19YearCacheHandler()));
 const ctx=bootstrapMonster(f.first.calculationDay,f.first.targetDay);
 const msg="STAGE41_INJECT_"+depth;
 try{
  if(depth==="OLD_GHOST"){
   LegacyStructureSauceAdapter.prototype.oldStructureSauce=function():never{
    throw Error(msg);
   };
  }else{
   Patch11OrderLatchHandler.prototype.run=function(...args){
    const [s]=args;
    if(s.calculationDay===f.first.calculationDay&&
       s.targetDay===f.firstSeed.openGateDay+1n)throw Error(msg);
    return actualNative.apply(this,args);
   };
  }
  try{isolated.run(ctx,q1);throw Error("fault not injected");}
  catch(e){assert(e instanceof Error&&e.message===msg,
    "fault propagated on original ghost / corrected full 58-write chain");}
  assert(ctx.status==="VALIDATED"&&ctx.metrics.size===1&&
   ctx.branchTrace.join(",")==="BOOTSTRAP_VALIDATE",
   "caller context rollback after old or new Sauce failure");
  faults++;
 }finally{
  LegacyStructureSauceAdapter.prototype.oldStructureSauce=original;
  Patch11OrderLatchHandler.prototype.run=actualNative;
 }
 const again=isolated.run(ctx,q1);
 assert(again.context===ctx&&again.context.status==="PATCH_20_APPLIED"&&
  again.firstDaySauceCalls===1,"retry after injected fault");
}
const committed=handler.run(ready,q1);
assert(committed.context===ready&&
 rejected(()=>handler.run(ready,q1),MonsterStageError),
 "caller owner single-use after success");
a.context.metrics.set("private",33n);
assert(!b.context.metrics.has("private")&&
 a.newFirstDaySauce!==b.newFirstDaySauce&&a.context!==b.context,
 "independent result ownership");
assert(rejected(()=>calendarDateSpaghetti(F,F),MonsterStageError),
 "Stage54 date API remains unopened");
console.log("STAGE_41_PATCH_20_GUARDS_PASS realYears=2 oldSauceCalls="+oldCalls+
 " correctedFirstDayCalls="+correctedFirstDayCalls+
 " correctedWrong=0 ghostPreserved=2"+
 " oldWrongCacheHITPreserved=1 exactFirstDayReuse=1"+
 " exactFirstDayNewCalls=0 deepFaults="+faults+
 " correctedSauceSharedWrites=116"+
 " realPredecessors="+(a.totalRealPredecessorCalls+b.totalRealPredecessorCalls)+
 " realWrites="+(a.totalSharedMemoryWrites+b.totalSharedMemoryWrites));
