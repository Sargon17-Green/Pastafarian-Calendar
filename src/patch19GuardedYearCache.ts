import {
  BaseMetricsManager,bootstrapMonster,MonsterStageError,MonsterValidationError
} from "./monsterBase.ts";
import type {MonsterContext} from "./monsterBase.ts";
import {
  LegacyYearNumberOnlyCache,Discovery19YearNumberCacheHandler,
  discoverLegacyYearNumberCache
} from "./discovery19LegacyYearCache.ts";
import type {
  Discovery19Request,Discovery19YearValue,Discovery19CacheObservation
} from "./discovery19LegacyYearCache.ts";

// PATCH19: जुन्या year.number-only Map चे oldGet/oldPut बदलू नका.
// HIT अधिकृत ठरवण्यासाठी cDay, openGate व closeGate हे तिन्ही guards
// स्वतंत्रपणे तपासा; चुकले तर जुन्याच key वर oldPut करून refresh.
export function exactCalculationDayFingerprint(day:bigint):string {
  if(typeof day!=="bigint")
    throw new MonsterValidationError("calculationDay पूर्ण bigint असावा");
  // Reversible canonical encoding: NO hash collisions, including signed
  // integers >32768 bits. This value is not an approximation.
  return day.toString(16);
}
export type Patch19GuardedYearEntry=Readonly<{
  calculationDayFingerprint:string;
  openGate:bigint;closeGate:bigint;value:Discovery19YearValue;
}>;
export type Patch19GuardDecision=Readonly<{
  key:bigint;
  oldResult:Discovery19YearValue|undefined;
  oldLookupCalls:1;
  oldInsertCalls:0|1;
  storedGuard:Patch19GuardedYearEntry|undefined;
  fingerprintMatched:boolean;
  openGateMatched:boolean;
  closeGateMatched:boolean;
  oldValueCoherent:boolean;
  correctedHit:boolean;
  correctedMiss:boolean;
  correctedServed:Discovery19YearValue;
  oldWouldServeWrong:boolean;
  repaired:boolean;
}>;
function copyValue(value:Discovery19YearValue):Discovery19YearValue {
  if(!value||typeof value!=="object"||
    typeof value.calculationDay!=="bigint"||
    !value.year||typeof value.year!=="object"||
    typeof value.year.number!=="bigint"||
    typeof value.year.openGateDay!=="bigint"||
    typeof value.year.closeGateDay!=="bigint"||
    typeof value.year.openGateIndex!=="bigint"||
    typeof value.year.closeGateIndex!=="bigint"||
    value.year.openGateIndex>=value.year.closeGateIndex||
    value.year.openGateDay>=value.year.closeGateDay||
    value.source!=="ACTUAL_STAGE37_YEAR_WALK")
    throw new MonsterValidationError("पूर्ण normative fresh year value आवश्यक");
  return Object.freeze({
    calculationDay:value.calculationDay,
    year:Object.freeze({...value.year}),
    source:"ACTUAL_STAGE37_YEAR_WALK" as const
  });
}
function sameValue(a:Discovery19YearValue,b:Discovery19YearValue):boolean {
  return a.calculationDay===b.calculationDay&&
    a.year.number===b.year.number&&
    a.year.openGateIndex===b.year.openGateIndex&&
    a.year.closeGateIndex===b.year.closeGateIndex&&
    a.year.openGateDay===b.year.openGateDay&&
    a.year.closeGateDay===b.year.closeGateDay&&
    a.source===b.source;
}
export class Patch19GuardedYearNumberCache {
  // Same historical Map and exactly the same year-number key in production.
  readonly legacyCache:LegacyYearNumberOnlyCache;
  private readonly guarded=new Map<bigint,Patch19GuardedYearEntry>();
  private correctedHits=0;
  private correctedMisses=0;
  constructor(legacyCache:LegacyYearNumberOnlyCache=
    new LegacyYearNumberOnlyCache()) {
    this.legacyCache=legacyCache;
  }
  resolve(freshInput:Discovery19YearValue):Patch19GuardDecision {
    const fresh=copyValue(freshInput);
    const key=fresh.year.number;
    // Always physically ask the original WRONG number-only oldGet.
    const oldResult=this.legacyCache.oldGet(key);
    const saved=this.guarded.get(key);
    const fingerprintMatched=saved!==undefined&&
      saved.calculationDayFingerprint===
        exactCalculationDayFingerprint(fresh.calculationDay);
    const openGateMatched=saved!==undefined&&
      saved.openGate===fresh.year.openGateDay;
    const closeGateMatched=saved!==undefined&&
      saved.closeGate===fresh.year.closeGateDay;
    // Reject external mutation of the old Map or a value that does not
    // actually match the metadata written by this repaired adapter.
    const oldValueCoherent=saved!==undefined&&oldResult!==undefined&&
      sameValue(saved.value,oldResult);
    const hit=oldValueCoherent&&fingerprintMatched&&
      openGateMatched&&closeGateMatched;
    const oldWouldServeWrong=oldResult!==undefined&&
      !sameValue(oldResult,fresh);
    // Diagnostic snapshot of what the historical cache WOULD have served.
    const result:Patch19GuardDecision=Object.freeze({
      key,oldResult,oldLookupCalls:1 as const,
      oldInsertCalls:hit?0 as const:1 as const,
      storedGuard:saved,fingerprintMatched,openGateMatched,
      closeGateMatched,oldValueCoherent,
      correctedHit:hit,correctedMiss:!hit,
      correctedServed:hit?saved!.value:fresh,
      oldWouldServeWrong,repaired:!hit
    });
    if(!hit){
      // Old put writes the SAME Map<year.number, value>. No compound key.
      // Publish the guard entry ONLY after the original oldPut succeeds;
      // a thrown oldGet/oldPut never publishes a false corrected HIT.
      this.legacyCache.oldPut(key,fresh);
      this.guarded.set(key,Object.freeze({
        calculationDayFingerprint:exactCalculationDayFingerprint(fresh.calculationDay),
        openGate:fresh.year.openGateDay,closeGate:fresh.year.closeGateDay,
        value:fresh
      }));
      this.correctedMisses++;
    }else this.correctedHits++;
    return result;
  }
  inspect():Readonly<{
    hits:number;misses:number;entries:number;
    historical:ReturnType<LegacyYearNumberOnlyCache["inspect"]>;
    guards:readonly Patch19GuardedYearEntry[];
  }> {
    return Object.freeze({
      hits:this.correctedHits,misses:this.correctedMisses,
      entries:this.guarded.size,historical:this.legacyCache.inspect(),
      guards:Object.freeze([...this.guarded.values()])
    });
  }
}
export type Patch19CacheObservation=Readonly<{
  calculationDay:bigint;targetDay:bigint;yearNumber:bigint;
  originalWrongHistory:Discovery19CacheObservation;
  fresh:Discovery19YearValue;
  historicalServed:Discovery19YearValue;
  correctedServed:Discovery19YearValue;
  correctedHit:boolean;correctedMiss:boolean;
  oldWouldServeWrong:boolean;historicalWrongHit:boolean;
  fingerprintMatched:boolean;
  openGateMatched:boolean;closeGateMatched:boolean;
  originalOldGetResult:Discovery19YearValue|undefined;
  originalOldLookupCalls:1;
  originalOldPutCalls:0|1;
  trueYearPredecessorCalls:number;
  predecessorSharedWrites:bigint;
  cacheKeyKind:"YEAR_NUMBER_ONLY";
  correctedGuardsApplied:true;
  result:Patch19GuardDecision;
  context:MonsterContext;
}>;

export class Patch19YearCacheHandler {
  private readonly metrics=new BaseMetricsManager();
  readonly historical:Discovery19YearNumberCacheHandler;
  readonly corrected:Patch19GuardedYearNumberCache;
  constructor(
    historical:Discovery19YearNumberCacheHandler=
      new Discovery19YearNumberCacheHandler(),
    corrected:Patch19GuardedYearNumberCache=
      new Patch19GuardedYearNumberCache()
  ){
    this.historical=historical;
    this.corrected=corrected;
  }
  run(ctx:MonsterContext,q:Discovery19Request):Patch19CacheObservation {
    if(ctx.phase!=="READY"||ctx.status!=="VALIDATED")
      throw new MonsterStageError("PATCH19 पूर्वी READY/VALIDATED context आवश्यक");
    if(!q||typeof q!=="object"||
       typeof q.calculationDay!=="bigint"||
       typeof q.targetDay!=="bigint"||
       q.calculationDay!==ctx.calculationDay||
       q.targetDay!==ctx.targetDay)
      throw new MonsterValidationError("cDay/tDay संदर्भ आणि request जुळायला हवेत");
    // Full true Stage37 physical producer AND Stage38 original wrong cache
    // both run. Stage38's cached wrong served value remains uncorrected.
    const predecessor=discoverLegacyYearNumberCache(this.historical,q);
    if(predecessor.context.status!=="DISCOVERY_19_RECORDED"||
       predecessor.preceding.context.status!=="PATCH_18_APPLIED"||
       predecessor.preceding.authoritative.gateProvenance!==
          "PHYSICALLY_RECOMPUTED_SIGNED_GATES")
      throw new MonsterStageError("Stage38 full वास्तविक Year5000 पूर्ववर्ती आवश्यक");
    // Real protected HIT is a separate decision on the SAME bad key.
    // We never substitute the historical served value for the real fresh.
    const decision=this.corrected.resolve(predecessor.fresh);
    if(!sameValue(decision.correctedServed,predecessor.fresh))
      throw new MonsterStageError("stale cache पुन्हा authoritative बनू नये");
    const output:Patch19CacheObservation=Object.freeze({
      calculationDay:ctx.calculationDay,targetDay:ctx.targetDay,
      yearNumber:predecessor.yearNumber,
      originalWrongHistory:predecessor,
      fresh:predecessor.fresh,
      historicalServed:predecessor.served,
      correctedServed:decision.correctedServed,
      correctedHit:decision.correctedHit,
      correctedMiss:decision.correctedMiss,
      oldWouldServeWrong:decision.oldWouldServeWrong,
      historicalWrongHit:predecessor.oldWrongHit,
      fingerprintMatched:decision.fingerprintMatched,
      openGateMatched:decision.openGateMatched,
      closeGateMatched:decision.closeGateMatched,
      originalOldGetResult:decision.oldResult,
      originalOldLookupCalls:decision.oldLookupCalls,
      originalOldPutCalls:decision.oldInsertCalls,
      trueYearPredecessorCalls:predecessor.predecessorCallCount,
      predecessorSharedWrites:predecessor.predecessorSharedWrites,
      cacheKeyKind:"YEAR_NUMBER_ONLY" as const,
      correctedGuardsApplied:true as const,result:decision,context:ctx
    });
    // Commit caller context only after all predecessor & cache calls.
    ctx.branchTrace.push("PATCH_19_FULL_STAGE38_REAL_HISTORIC_WRONG_CACHE");
    ctx.branchTrace.push("PATCH_19_PHYSICAL_OLD_GET_YEAR_NUMBER_ONLY");
    ctx.branchTrace.push("PATCH_19_VALIDATE_ALL_THREE_STORED_GUARDS");
    ctx.branchTrace.push(decision.correctedHit?
      "PATCH_19_ACCEPT_TRUE_TRIPLE_GUARD_HIT":
      "PATCH_19_REPAIR_MISS_VIA_ORIGINAL_OLD_PUT");
    this.metrics.bump(ctx,"patch19.calls");
    ctx.metrics.set("patch19.fingerprint_matched",
      decision.fingerprintMatched?1n:0n);
    ctx.metrics.set("patch19.open_gate_matched",
      decision.openGateMatched?1n:0n);
    ctx.metrics.set("patch19.close_gate_matched",
      decision.closeGateMatched?1n:0n);
    ctx.metrics.set("patch19.old_would_serve_wrong",
      decision.oldWouldServeWrong?1n:0n);
    ctx.metrics.set("patch19.corrected_cache_hits",
      decision.correctedHit?1n:0n);
    ctx.metrics.set("patch19.corrected_cache_misses",
      decision.correctedMiss?1n:0n);
    ctx.metrics.set("patch19.predecessor_58_write_sequences",
      BigInt(predecessor.predecessorCallCount));
    ctx.status="PATCH_19_APPLIED";
    return output;
  }
}
export function patch19GuardedYearCache(
 handler:Patch19YearCacheHandler,q:Discovery19Request
):Patch19CacheObservation {
 if(!(handler instanceof Patch19YearCacheHandler)||
    !q||typeof q.calculationDay!=="bigint"||
    typeof q.targetDay!=="bigint")
  throw new MonsterValidationError("पूर्ण PATCH19 handler आणि प्रश्न आवश्यक");
 return handler.run(bootstrapMonster(q.calculationDay,q.targetDay),q);
}
