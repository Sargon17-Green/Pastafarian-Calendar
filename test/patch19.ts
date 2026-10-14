import {
 Patch19GuardedYearNumberCache,Patch19YearCacheHandler,
 patch19GuardedYearCache,exactCalculationDayFingerprint,
 LegacyYearNumberOnlyCache,Discovery19YearNumberCacheHandler,
 Patch18OneYearWalker,MonsterValidationError,MonsterStageError,
 bootstrapMonster,createMonsterContext,calendarDateSpaghetti
} from "../src/index.ts";
import {FOUNDATION_DAY as F} from "./normativeOracle.ts";
import {buildDiscovery19Fixture,assert} from "./discovery19Fixtures.ts";
function rejects(fn:()=>unknown,error:typeof MonsterStageError|typeof MonsterValidationError){
 try{fn();}catch(e){return e instanceof error;}return false;
}
const make=(c:bigint,open:bigint,close:bigint,number=5000n)=>
 Object.freeze({calculationDay:c,
  year:Object.freeze({number,openGateIndex:0n,closeGateIndex:6n,
    openGateDay:open,closeGateDay:close}),
  source:"ACTUAL_STAGE37_YEAR_WALK" as const});
assert(exactCalculationDayFingerprint(0n)==="0"&&
 exactCalculationDayFingerprint(-1n)==="-1"&&
 exactCalculationDayFingerprint(0x1234n)==="1234"&&
 exactCalculationDayFingerprint(-(1n<<32768n))!==
 exactCalculationDayFingerprint(1n<<32768n)&&
 rejects(()=>exactCalculationDayFingerprint("bad" as never),MonsterValidationError),
 "reversible, collision-free signed bigint fingerprint, including 32768 bits");
const raw=new LegacyYearNumberOnlyCache();
const corrected=new Patch19GuardedYearNumberCache(raw);
const original=make(F,F,F+1000n);
const first=corrected.resolve(original);
assert(first.correctedMiss&&!first.correctedHit&&
 first.oldResult===undefined&&first.oldInsertCalls===1&&
 !first.fingerprintMatched&&!first.openGateMatched&&!first.closeGateMatched&&
 corrected.inspect().entries===1&&
 corrected.inspect().historical.size===1&&
 corrected.inspect().historical.writes===1,
 "empty original oldGet and actual oldPut on same year-number key");
const hit=corrected.resolve(original);
assert(hit.correctedHit&&!hit.correctedMiss&&
 hit.oldInsertCalls===0&&hit.fingerprintMatched&&
 hit.openGateMatched&&hit.closeGateMatched&&hit.oldValueCoherent&&
 !hit.oldWouldServeWrong&&
 hit.correctedServed.calculationDay===F&&
 hit.correctedServed.year.openGateDay===F,
 "all three guards and original oldGet coherence permit real cache HIT");

const onlyAction=make(F+1n,F,F+1000n);
const d=corrected.resolve(onlyAction);
assert(d.correctedMiss&&!d.fingerprintMatched&&d.openGateMatched&&
 d.closeGateMatched&&d.oldWouldServeWrong&&d.oldInsertCalls===1&&
 d.oldResult?.calculationDay===F&&d.correctedServed.calculationDay===F+1n,
 "cDay-only mismatch repairs despite identical year boundaries");

const onlyOpening=make(F+1n,F-1n,F+1000n);
const o=corrected.resolve(onlyOpening);
assert(o.correctedMiss&&o.fingerprintMatched&&
 !o.openGateMatched&&o.closeGateMatched&&o.oldWouldServeWrong&&
 o.correctedServed.year.openGateDay===F-1n&&
 o.oldResult?.year.openGateDay===F,
 "openGate-only mismatch repairs despite matching fingerprint and closeGate");

const onlyClosing=make(F+1n,F-1n,F+1001n);
const e=corrected.resolve(onlyClosing);
assert(e.correctedMiss&&e.fingerprintMatched&&e.openGateMatched&&
 !e.closeGateMatched&&e.oldWouldServeWrong&&
 e.correctedServed.year.closeGateDay===F+1001n,
 "closeGate-only mismatch repairs despite matching fingerprint and openGate");

const combined=make(F+3n,F-100n,F+1100n);
const all=corrected.resolve(combined);
assert(all.correctedMiss&&!all.fingerprintMatched&&
 !all.openGateMatched&&!all.closeGateMatched&&all.oldWouldServeWrong&&
 corrected.inspect().entries===1&&corrected.inspect().historical.size===1&&
 corrected.inspect().hits===1&&corrected.inspect().misses===5&&
 raw.inspect().reads===6&&raw.inspect().writes===5,
 "triple mismatched cDay/open/close preserved original year-number map");

const tampered=make(F+99n,F-999n,F+999n);
raw.oldPut(5000n,tampered); // external old-only write, metadata unchanged
const incoherent=corrected.resolve(combined);
assert(incoherent.fingerprintMatched&&incoherent.openGateMatched&&
 incoherent.closeGateMatched&&!incoherent.oldValueCoherent&&
 !incoherent.correctedHit&&incoherent.correctedMiss&&
 incoherent.correctedServed.calculationDay===F+3n,
 "old underlying number-only Map external mutation cannot bypass guards");
const preloaded=new LegacyYearNumberOnlyCache();
preloaded.oldPut(5000n,original);
const independent=new Patch19GuardedYearNumberCache(preloaded);
const bootstrap=independent.resolve(original);
assert(bootstrap.correctedMiss&&!bootstrap.correctedHit&&
 bootstrap.oldResult?.calculationDay===F&&
 bootstrap.storedGuard===undefined,
 "pre-existing unguarded historical cache entry never authorizes HIT");
assert(rejects(()=>corrected.resolve({
 ...original,year:{...original.year,openGateDay:F+300n,closeGateDay:F+200n}
}),MonsterValidationError),"malformed invalid-year input rejected");

const base=buildDiscovery19Fixture();
const shadow=new Discovery19YearNumberCacheHandler();
const protectedCache=new Patch19GuardedYearNumberCache();
const handler=new Patch19YearCacheHandler(shadow,protectedCache);
const oldGet=LegacyYearNumberOnlyCache.prototype.oldGet;
const oldPut=LegacyYearNumberOnlyCache.prototype.oldPut;
const oldWalk=Patch18OneYearWalker.prototype.walk;
let spyGet=0,spyPut=0,spyWalk=0;
let p1!:ReturnType<typeof patch19GuardedYearCache>;
let p2!:ReturnType<typeof patch19GuardedYearCache>;
let p3!:ReturnType<typeof patch19GuardedYearCache>;
let p4!:ReturnType<typeof patch19GuardedYearCache>;
try{
 LegacyYearNumberOnlyCache.prototype.oldGet=function(...args){
  spyGet++;return oldGet.apply(this,args);
 };
 LegacyYearNumberOnlyCache.prototype.oldPut=function(...args){
  spyPut++;return oldPut.apply(this,args);
 };
 Patch18OneYearWalker.prototype.walk=function(...args){
  spyWalk++;return oldWalk.apply(this,args);
 };
 p1=patch19GuardedYearCache(handler,base.first);
 p2=patch19GuardedYearCache(handler,base.second);
 p3=patch19GuardedYearCache(handler,base.first);
 p4=patch19GuardedYearCache(handler,base.first);
}finally{
 LegacyYearNumberOnlyCache.prototype.oldGet=oldGet;
 LegacyYearNumberOnlyCache.prototype.oldPut=oldPut;
 Patch18OneYearWalker.prototype.walk=oldWalk;
}
function match(x:typeof p1.correctedServed.year,y:typeof p1.correctedServed.year):boolean {
 return x.number===y.number&&
 x.openGateIndex===y.openGateIndex&&x.closeGateIndex===y.closeGateIndex&&
 x.openGateDay===y.openGateDay&&x.closeGateDay===y.closeGateDay;
}
assert(spyGet===8&&spyPut===4&&spyWalk===4,
 "old historical getter/writer physically executed both inside preserved Stage38 and guarded path");
assert(p1.correctedMiss&&!p1.correctedHit&&
 p1.originalWrongHistory.oldHit===false&&
 match(p1.correctedServed.year,base.firstSeed)&&
 match(p1.fresh.year,base.firstSeed)&&
 p1.result.oldResult===undefined&&p1.result.oldInsertCalls===1,
 "first genuine real Year5000(c-2) MISS with original year-number key");
assert(p2.correctedMiss&&!p2.correctedHit&&
 p2.historicalWrongHit&&
 p2.originalWrongHistory.served.calculationDay===base.first.calculationDay&&
 p2.originalWrongHistory.oldWrongHit&&
 p2.originalWrongHistory.correctedCacheGuardsApplied===false&&
 p2.oldWouldServeWrong&&
 !p2.fingerprintMatched&&
 (!p2.openGateMatched||!p2.closeGateMatched)&&
 match(p2.correctedServed.year,base.secondSeed)&&
 match(p2.fresh.year,base.secondSeed)&&
 !match(p2.historicalServed.year,base.secondSeed)&&
 p2.originalOldGetResult?.calculationDay===base.first.calculationDay,
 "historical Stage38 STILL returns stale wrong year but PATCH19 repairs the real second year");
assert(p3.correctedMiss&&p3.oldWouldServeWrong&&
 match(p3.correctedServed.year,base.firstSeed)&&
 p3.originalWrongHistory.oldHit&&!p3.originalWrongHistory.oldWrongHit&&
 p3.result.oldInsertCalls===1,
 "long-lived corrected cache repairs reverse action-day collision on same year-number slot");
assert(p4.correctedHit&&!p4.correctedMiss&&
 p4.fingerprintMatched&&p4.openGateMatched&&p4.closeGateMatched&&
 p4.result.oldInsertCalls===0&&
 match(p4.correctedServed.year,base.firstSeed)&&
 p4.context.status==="PATCH_19_APPLIED"&&
 p4.context.metrics.get("patch19.corrected_cache_hits")===1n,
 "subsequent identical true Year5000 query produces genuine triple-verified HIT");
assert(protectedCache.inspect().entries===1&&
 protectedCache.inspect().historical.size===1&&
 protectedCache.inspect().historical.reads===4&&
 protectedCache.inspect().historical.writes===3&&
 protectedCache.inspect().hits===1&&protectedCache.inspect().misses===3&&
 shadow.legacyCache.inspect().reads===4&&shadow.legacyCache.inspect().writes===1,
 "corrected Map retains old bad year-number key while Stage38 keeps independent historical ledger");
let allPredecessors=0,allWrites=0;
for(const obs of [p1,p2,p3,p4]){
 allPredecessors+=obs.trueYearPredecessorCalls;
 allWrites+=Number(obs.predecessorSharedWrites);
 assert(obs.predecessorSharedWrites===BigInt(obs.trueYearPredecessorCalls)*58n&&
  obs.originalWrongHistory.preceding.authoritative.gateProvenance===
    "PHYSICALLY_RECOMPUTED_SIGNED_GATES"&&
  obs.correctedGuardsApplied&&
  obs.cacheKeyKind==="YEAR_NUMBER_ONLY"&&
  obs.context!==obs.originalWrongHistory.context&&
  obs.context.branchTrace.join(",")=== [
   "BOOTSTRAP_VALIDATE",
   "PATCH_19_FULL_STAGE38_REAL_HISTORIC_WRONG_CACHE",
   "PATCH_19_PHYSICAL_OLD_GET_YEAR_NUMBER_ONLY",
   "PATCH_19_VALIDATE_ALL_THREE_STORED_GUARDS",
   obs.correctedHit?"PATCH_19_ACCEPT_TRUE_TRIPLE_GUARD_HIT":
    "PATCH_19_REPAIR_MISS_VIA_ORIGINAL_OLD_PUT"
  ].join(",")&&
  Object.isFrozen(obs)&&Object.isFrozen(obs.correctedServed)&&
  Object.isFrozen(obs.correctedServed.year),
  "Stage38 full Sauces and cache were physical and caller ownership separated");
}
assert(allWrites===allPredecessors*58,"all true predecessor shared memory writes accounted");

const unready=createMonsterContext(base.first.calculationDay,base.first.targetDay);
const newHandler=new Patch19YearCacheHandler();
assert(rejects(()=>newHandler.run(unready,base.first),MonsterStageError)&&
 unready.metrics.size===0&&unready.branchTrace.length===0,
 "non-ready ctx rejected without cache or semantic mutation");
const owner=bootstrapMonster(base.first.calculationDay,base.first.targetDay);
assert(rejects(()=>newHandler.run(owner,{...base.first,
 targetDay:base.first.targetDay+1n}),MonsterValidationError)&&
 newHandler.corrected.inspect().entries===0&&owner.metrics.size===1,
 "invalid request preflight does not mutate caches");
assert(rejects(()=>newHandler.run(owner,{...base.first,maximumSteps:-1}),
 MonsterValidationError)&&newHandler.corrected.inspect().entries===0&&
 owner.branchTrace.join(",")==="BOOTSTRAP_VALIDATE",
 "true Stage37 failure leaves repaired cache and owner unchanged");

let failureCases=0;
for(const step of ["PATCH19_GET","PATCH19_PUT"] as const){
 const h=new Patch19YearCacheHandler();
 const ctx=bootstrapMonster(base.first.calculationDay,base.first.targetDay);
 const mark="PATCH19_INJECT_"+step;let invoked=0;
 try{
  if(step==="PATCH19_GET")
   LegacyYearNumberOnlyCache.prototype.oldGet=function(...args){
    invoked++;if(invoked===2)throw Error(mark);
    return oldGet.apply(this,args);
   };
  else
   LegacyYearNumberOnlyCache.prototype.oldPut=function(...args){
    invoked++;if(invoked===2)throw Error(mark);
    return oldPut.apply(this,args);
   };
  try{h.run(ctx,base.first);throw Error("failure was not injected");}
  catch(e){assert(e instanceof Error&&e.message===mark,
   "fault at corrected oldGet/oldPut propagated without fake success");}
  assert(ctx.status==="VALIDATED"&&ctx.branchTrace.join(",")==="BOOTSTRAP_VALIDATE"&&
   ctx.metrics.size===1&&h.corrected.inspect().entries===0&&
   h.corrected.inspect().hits===0,
   "late corrected cache fault creates no guard and no outer semantic writes");
  failureCases++;
 }finally{
  LegacyYearNumberOnlyCache.prototype.oldGet=oldGet;
  LegacyYearNumberOnlyCache.prototype.oldPut=oldPut;
 }
 const retry=h.run(ctx,base.first);
 assert(retry.correctedMiss&&
  match(retry.correctedServed.year,base.firstSeed)&&
  h.corrected.inspect().entries===1,
  "same context retries after late cache fault and repairs old slot");
}
const committed=newHandler.run(owner,base.first);
assert(committed.correctedMiss&&
 rejects(()=>newHandler.run(owner,base.first),MonsterStageError),
 "one semantic context cannot be committed twice");
p1.context.metrics.set("private",99n);
assert(!p2.context.metrics.has("private")&&
 !p3.context.metrics.has("private")&&
 p1.context!==p2.context&&p1.fresh!==p2.fresh,
 "fresh requests are independently owned");
assert(rejects(()=>calendarDateSpaghetti(F,F),MonsterStageError),
 "Stage54 full calendar remains unintegrated");
console.log("STAGE_39_PATCH_19_GUARDS_PASS"+
 " directMisses=5 directHits=1 individualGuards=3"+
 " externalTamperMiss=1 preloadedNoGuardMiss=1"+
 " actualYear5000Queries=4 correctedMisses=3 correctedHits=1"+
 " staleHistoricalStage38StillServed=1"+
 " oldGetSpy="+spyGet+" oldPutSpy="+spyPut+" stage37WalkSpy="+spyWalk+
 " truePredecessors="+allPredecessors+" sharedWrites="+allWrites+
 " lateFaultCases="+failureCases+" rankWrong=0");
