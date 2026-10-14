import {
 LegacyYearNumberOnlyCache,Discovery19YearNumberCacheHandler,
 discoverLegacyYearNumberCache,Patch18OneYearWalker,bootstrapMonster,
 createMonsterContext,MonsterStageError,MonsterValidationError,
 calendarDateSpaghetti
} from "../src/index.ts";
import {FOUNDATION_DAY as F} from "./normativeOracle.ts";
import {assert,buildDiscovery19Fixture} from "./discovery19Fixtures.ts";
function rejects(fn:()=>unknown,error:typeof MonsterStageError|typeof MonsterValidationError){
 try{fn();}catch(e){return e instanceof error;}return false;
}
const make=(c:bigint,n:bigint,open:bigint,close:bigint)=>
 Object.freeze({calculationDay:c,
  year:Object.freeze({number:n,openGateIndex:0n,closeGateIndex:6n,
   openGateDay:open,closeGateDay:close}),
  source:"ACTUAL_STAGE37_YEAR_WALK" as const});
const direct=new LegacyYearNumberOnlyCache();
assert(direct.oldGet(5000n)===undefined&&direct.inspect().reads===1,
 "empty real old lookup by year number");
const x=make(F,5000n,F,F+1000n);
direct.oldPut(5000n,x);
assert(direct.oldGet(5000n)!==x&&
 direct.oldGet(5000n)?.year.openGateDay===F&&
 direct.inspect().size===1&&direct.inspect().writes===1,
 "old cache physically writes immutable owned copy by year number only");
const clashing=make(F+500n,5000n,F+1n,F+900n);
assert(direct.oldGet(clashing.year.number)!.calculationDay!==clashing.calculationDay&&
 direct.oldGet(clashing.year.number)!.year.openGateDay!==clashing.year.openGateDay,
 "cache ignores both action and year gate boundaries by design");
direct.oldPut(-1n,make(F,-1n,F,F+800n));
assert(direct.oldGet(-1n)?.year.number===-1n&&
 direct.inspect().keys.join(",")==="5000,-1",
 "historical map really keys by signed year number");
for(const bad of [null,12n,"5000"] as unknown[]){
 if(bad===null||typeof bad!=="bigint")
  assert(rejects(()=>direct.oldGet(bad as never),MonsterValidationError),
   "old helper must reject malformed key");
}
assert(rejects(()=>direct.oldPut(5001n,x),MonsterValidationError),
 "old writer rejects year/key disagreement but not stale context");

const f=buildDiscovery19Fixture();
const cache=new LegacyYearNumberOnlyCache();
const handler=new Discovery19YearNumberCacheHandler(cache);
const oldGet=LegacyYearNumberOnlyCache.prototype.oldGet;
const oldPut=LegacyYearNumberOnlyCache.prototype.oldPut;
const fullWalk=Patch18OneYearWalker.prototype.walk;
let getSpy=0,putSpy=0,walkSpy=0;
let first!:ReturnType<typeof discoverLegacyYearNumberCache>;
let second!:ReturnType<typeof discoverLegacyYearNumberCache>;
let third!:ReturnType<typeof discoverLegacyYearNumberCache>;
try{
 LegacyYearNumberOnlyCache.prototype.oldGet=function(...args){
  getSpy++;return oldGet.apply(this,args);
 };
 LegacyYearNumberOnlyCache.prototype.oldPut=function(...args){
  putSpy++;return oldPut.apply(this,args);
 };
 Patch18OneYearWalker.prototype.walk=function(...args){
  walkSpy++;return fullWalk.apply(this,args);
 };
 first=discoverLegacyYearNumberCache(handler,f.first);
 second=discoverLegacyYearNumberCache(handler,f.second);
 third=discoverLegacyYearNumberCache(handler,f.first);
}finally{
 LegacyYearNumberOnlyCache.prototype.oldGet=oldGet;
 LegacyYearNumberOnlyCache.prototype.oldPut=oldPut;
 Patch18OneYearWalker.prototype.walk=fullWalk;
}
assert(getSpy===3&&putSpy===1&&walkSpy===3,
 "on HIT full Stage37 remains physically invoked and old get/put genuinely called");
const equ=(x:typeof first.fresh.year,y:typeof first.fresh.year)=>
 x.number===y.number&&x.openGateDay===y.openGateDay&&
 x.closeGateDay===y.closeGateDay&&x.openGateIndex===y.openGateIndex&&
 x.closeGateIndex===y.closeGateIndex;
assert(equ(first.fresh.year,f.firstSeed)&&equ(second.fresh.year,f.secondSeed)&&
 !equ(first.fresh.year,second.fresh.year),
 "separate real signed Year5000 selections match independent oracle and differ");
assert(!first.oldHit&&!first.oldWrongHit&&first.oldInsertCalls===1&&
 first.served===first.fresh&&first.context.status==="DISCOVERY_19_RECORDED"&&
 first.yearNumber===5000n,
 "first full production year insert");
assert(second.oldHit&&second.oldWrongHit&&
 second.staleCalculationDay&&(second.staleOpeningGate||second.staleClosingGate)&&
 second.served.calculationDay===f.first.calculationDay&&
 equ(second.served.year,f.firstSeed)&&
 !equ(second.served.year,f.secondSeed)&&
 second.incorrectOldValueActuallyServed&&
 !second.correctedCacheGuardsApplied&&second.oldLookupCalls===1&&
 second.oldInsertCalls===0&&second.cacheKeyKind==="YEAR_NUMBER_ONLY"&&
 second.preceding.authoritative.gateProvenance===
 "PHYSICALLY_RECOMPUTED_SIGNED_GATES"&&
 second.predecessorCallCount===second.preceding.predecessorCallCount&&
 second.predecessorSharedWrites===second.preceding.predecessorSharedWrites&&
 second.context.status==="DISCOVERY_19_RECORDED",
 "PHYSICAL historical wrong cache HIT overwrote distinct genuinely computed Year5000");
assert(third.oldHit&&!third.oldWrongHit&&third.served.calculationDay===f.first.calculationDay&&
 equ(third.fresh.year,third.served.year)&&cache.inspect().size===1,
 "same calculation and true boundaries coincidentally safe even with bad cache");
assert(first.context!==second.context&&first.context!==third.context&&
 second.context.metrics.get("discovery19.wrong_old_hits")===1n&&
 first.context.metrics.get("discovery19.wrong_old_hits")===0n&&
 third.context.metrics.get("discovery19.wrong_old_hits")===0n&&
 Object.isFrozen(second)&&Object.isFrozen(second.fresh)&&
 Object.isFrozen(second.served)&&Object.isFrozen(second.served.year)&&
 second.context.branchTrace.join(",")===
 "BOOTSTRAP_VALIDATE,DISCOVERY_19_FULL_STAGE37_REAL_YEAR_WALK,DISCOVERY_19_ACTUAL_OLD_GET_BY_NUMBER_ONLY,DISCOVERY_19_HISTORICAL_HIT_WITHOUT_ANY_GUARDS",
 "real wrong hit is recorded only after true Stage37 and state remains owned");
first.context.metrics.set("private_owner",77n);
assert(!second.context.metrics.has("private_owner")&&
 !third.context.metrics.has("private_owner"),
 "reentrant caller state isolated");

const freshHandler=new Discovery19YearNumberCacheHandler(),owner=bootstrapMonster(
 f.first.calculationDay,f.first.targetDay);
const unready=createMonsterContext(f.first.calculationDay,f.first.targetDay);
assert(rejects(()=>freshHandler.run(unready,f.first),MonsterStageError)&&
 unready.branchTrace.length===0&&unready.metrics.size===0,
 "not READY ctx no full traversal");
assert(rejects(()=>freshHandler.run(owner,{...f.first,targetDay:f.first.targetDay+1n}),
 MonsterValidationError)&&freshHandler.legacyCache.inspect().size===0&&
 owner.status==="VALIDATED"&&owner.metrics.size===1,
 "invalid request c/t rejected before cache");
const broken={...f.first,maximumSteps:-1};
assert(rejects(()=>freshHandler.run(owner,broken),MonsterValidationError)&&
 freshHandler.legacyCache.inspect().size===0&&owner.status==="VALIDATED"&&
 owner.branchTrace.join(",")==="BOOTSTRAP_VALIDATE",
 "deep Stage37 failure does not mutate outer state or cache");
let failures=0;
for(const which of ["READ","WRITE"] as const){
 const h=new Discovery19YearNumberCacheHandler();
 const ctx=bootstrapMonster(f.first.calculationDay,f.first.targetDay);
 const msg="STAGE38_INJECT_"+which;
 try{
  if(which==="READ")
   LegacyYearNumberOnlyCache.prototype.oldGet=function():never{throw Error(msg);};
  else LegacyYearNumberOnlyCache.prototype.oldPut=function():never{throw Error(msg);};
  try{h.run(ctx,f.first);throw Error("fault not raised");}
  catch(e){assert(e instanceof Error&&e.message===msg,
   "deep cache fault propagated "+which);}
  assert(h.legacyCache.inspect().size===0&&
   ctx.status==="VALIDATED"&&ctx.metrics.size===1&&
   ctx.branchTrace.join(",")==="BOOTSTRAP_VALIDATE",
   "cache fault did not commit outer state or stale value");
  failures++;
 }finally{
  LegacyYearNumberOnlyCache.prototype.oldGet=oldGet;
  LegacyYearNumberOnlyCache.prototype.oldPut=oldPut;
 }
 const retry=h.run(ctx,f.first);
 assert(!retry.oldHit&&!retry.oldWrongHit&&h.legacyCache.inspect().size===1,
  "failure recovery on same owned context");
}
const committed=freshHandler.run(owner,f.first);
assert(!committed.oldHit&&
 rejects(()=>freshHandler.run(owner,f.first),MonsterStageError),
 "outer context cannot commit twice");
assert(rejects(()=>calendarDateSpaghetti(F,F),MonsterStageError),
 "Stage54 integrated date remains unavailable");

console.log("STAGE_38_DISCOVERY_19_GUARDS_PASS"+
 " fullWalks="+walkSpy+" physicalOldGet="+getSpy+
 " physicalOldPut="+putSpy+" wrongHits=1 trueYear5000Different=1"+
 " realGateQuestionsPerWalk="+f.actualGateQuestions+
 " allRealPredecessors="+
 (first.predecessorCallCount+second.predecessorCallCount+third.predecessorCallCount)+
 " allRealWrites="+
 (first.predecessorSharedWrites+second.predecessorSharedWrites+third.predecessorSharedWrites)+
 " faultCases="+failures+" noGuardFix=1");
