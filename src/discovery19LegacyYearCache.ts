import {
  BaseMetricsManager,bootstrapMonster,MonsterStageError,MonsterValidationError
} from "./monsterBase.ts";
import type {MonsterContext} from "./monsterBase.ts";
import {patch18WalkYear} from "./patch18YearWalk.ts";
import type {
  Patch18Year,Patch18YearWalkObservation,Patch18Question,
  Patch18TransitionQuestionFactory
} from "./patch18YearWalk.ts";
import type {Discovery15GateQuestion} from "./discovery15LegacyPositiveGate.ts";
import type {Patch15SignedQuestion} from "./patch15SignedGate.ts";
import type {LegacyYearCandidate} from "./discovery16LegacyYearMax.ts";

// DISCOVERY19: ऐतिहासिक cache ची एकमेव key year.number आहे.
// जुना get आणि put प्रत्यक्ष चालतात; cDay/open/close guards नाहीत.
// Stage39 मध्येच तीन वेगळे guards जोडायचे आहेत.
export type Discovery19YearValue=Readonly<{
  calculationDay:bigint;
  year:Patch18Year;
  source:"ACTUAL_STAGE37_YEAR_WALK";
}>;
export type Discovery19CacheInspection=Readonly<{
  reads:number;writes:number;size:number;keys:readonly bigint[];
}>;
export class LegacyYearNumberOnlyCache {
  private readonly byYearNumber=new Map<bigint,Discovery19YearValue>();
  private reads=0;
  private writes=0;

  oldGet(yearNumber:bigint):Discovery19YearValue|undefined {
    if(typeof yearNumber!=="bigint")
      throw new MonsterValidationError("जुन्या cache key साठी bigint वर्ष क्रमांक आवश्यक");
    this.reads++;
    // THIS IS THE HISTORICAL ERROR. No guards at all.
    return this.byYearNumber.get(yearNumber);
  }

  oldPut(yearNumber:bigint,value:Discovery19YearValue):void {
    if(typeof yearNumber!=="bigint"||
       !value||typeof value!=="object"||
       typeof value.calculationDay!=="bigint"||
       !value.year||typeof value.year!=="object"||
       value.year.number!==yearNumber||
       typeof value.year.openGateIndex!=="bigint"||
       typeof value.year.closeGateIndex!=="bigint"||
       typeof value.year.openGateDay!=="bigint"||
       typeof value.year.closeGateDay!=="bigint"||
       value.year.openGateIndex>=value.year.closeGateIndex||
       value.year.openGateDay>=value.year.closeGateDay||
       value.source!=="ACTUAL_STAGE37_YEAR_WALK")
      throw new MonsterValidationError("पूर्ण cached year value आवश्यक");
    const cloned=Object.freeze({
      calculationDay:value.calculationDay,
      year:Object.freeze({...value.year}),
      source:"ACTUAL_STAGE37_YEAR_WALK" as const
    });
    this.byYearNumber.set(yearNumber,cloned);
    this.writes++;
  }
  inspect():Discovery19CacheInspection {
    return Object.freeze({
      reads:this.reads,writes:this.writes,size:this.byYearNumber.size,
      keys:Object.freeze([...this.byYearNumber.keys()])
    });
  }
}

export type Discovery19Request=Readonly<{
  calculationDay:bigint;targetDay:bigint;anchorGateIndex:bigint;
  historicalPositive:readonly Discovery15GateQuestion[];
  signedQuestions:readonly Patch15SignedQuestion[];
  oldYearQuestion:Discovery15GateQuestion;
  oldAnchorCandidates:readonly LegacyYearCandidate[];
  oldMultiCandidates:readonly LegacyYearCandidate[];
  positive:readonly Patch18Question[];
  negative:readonly Patch18Question[];
  trueYearQuestion:Patch18Question;
  transitionQuestion:Patch18TransitionQuestionFactory;
  maximumSteps:number;
}>;
export type Discovery19CacheObservation=Readonly<{
  calculationDay:bigint;targetDay:bigint;yearNumber:bigint;
  fresh:Discovery19YearValue;
  served:Discovery19YearValue;
  oldHit:boolean;
  oldWrongHit:boolean;
  staleCalculationDay:boolean;
  staleOpeningGate:boolean;
  staleClosingGate:boolean;
  oldLookupCalls:1;
  oldInsertCalls:0|1;
  cacheKeyKind:"YEAR_NUMBER_ONLY";
  incorrectOldValueActuallyServed:boolean;
  correctedCacheGuardsApplied:false;
  preceding:Patch18YearWalkObservation;
  predecessorCallCount:number;predecessorSharedWrites:bigint;
  context:MonsterContext;
}>;
export class Discovery19YearNumberCacheHandler {
  private readonly metrics=new BaseMetricsManager();
  readonly legacyCache:LegacyYearNumberOnlyCache;
  constructor(legacyCache:LegacyYearNumberOnlyCache=
    new LegacyYearNumberOnlyCache()){
    this.legacyCache=legacyCache;
  }

  run(ctx:MonsterContext,q:Discovery19Request):Discovery19CacheObservation {
    if(ctx.phase!=="READY"||ctx.status!=="VALIDATED")
      throw new MonsterStageError("DISCOVERY19 पूर्वी READY/VALIDATED context आवश्यक");
    if(!q||typeof q!=="object"||
       typeof q.calculationDay!=="bigint"||
       typeof q.targetDay!=="bigint"||
       q.calculationDay!==ctx.calculationDay||
       q.targetDay!==ctx.targetDay)
      throw new MonsterValidationError("cache प्रश्नाचे cDay/tDay मूळ संदर्भाशी जुळावे");
    // Stage37 is ACTUALLY recomputed for every query, even on legacy HIT,
    // so the older value and fresh normative year can be compared honestly.
    const preceding=patch18WalkYear(
      q.calculationDay,q.targetDay,q.anchorGateIndex,
      q.historicalPositive,q.signedQuestions,q.oldYearQuestion,
      q.oldAnchorCandidates,q.oldMultiCandidates,
      q.positive,q.negative,q.trueYearQuestion,
      q.transitionQuestion,q.maximumSteps);
    if(preceding.context.status!=="PATCH_18_APPLIED"||
       preceding.authoritative.gateProvenance!=="PHYSICALLY_RECOMPUTED_SIGNED_GATES"||
       !preceding.authoritative.targetContained||
       preceding.authoritative.legacyGuessUsedForNavigation)
      throw new MonsterStageError("Stage37 चा पूर्ण खरा वर्ष predecessor अनिवार्य");
    const fresh:Discovery19YearValue=Object.freeze({
      calculationDay:ctx.calculationDay,
      year:Object.freeze({...preceding.authoritativeYear}),
      source:"ACTUAL_STAGE37_YEAR_WALK" as const
    });
    // Deliberately WRONG historical cache lookup: ONLY year number.
    const old=this.legacyCache.oldGet(fresh.year.number);
    if(old===undefined)this.legacyCache.oldPut(fresh.year.number,fresh);
    const served=old===undefined?
      // Match actual stored snapshot, but do not apply any cDay/gate guard.
      fresh:old;
    const staleCalculationDay=served.calculationDay!==fresh.calculationDay;
    const staleOpeningGate=served.year.openGateDay!==fresh.year.openGateDay;
    const staleClosingGate=served.year.closeGateDay!==fresh.year.closeGateDay;
    const wrong=(staleCalculationDay||staleOpeningGate||staleClosingGate);
    // These discrepancies are diagnostic ONLY and cannot alter served.
    // Stage39 adds the real conditional guards.
    const output=Object.freeze({
      calculationDay:ctx.calculationDay,targetDay:ctx.targetDay,
      yearNumber:fresh.year.number,
      fresh,served,oldHit:old!==undefined,oldWrongHit:old!==undefined&&wrong,
      staleCalculationDay,staleOpeningGate,staleClosingGate,
      oldLookupCalls:1 as const,oldInsertCalls:old===undefined?1 as const:0 as const,
      cacheKeyKind:"YEAR_NUMBER_ONLY" as const,
      incorrectOldValueActuallyServed:old!==undefined&&wrong,
      correctedCacheGuardsApplied:false as const,
      preceding,
      predecessorCallCount:preceding.predecessorCallCount,
      predecessorSharedWrites:preceding.predecessorSharedWrites,
      context:ctx
    });
    ctx.branchTrace.push("DISCOVERY_19_FULL_STAGE37_REAL_YEAR_WALK");
    ctx.branchTrace.push("DISCOVERY_19_ACTUAL_OLD_GET_BY_NUMBER_ONLY");
    ctx.branchTrace.push(old===undefined?
      "DISCOVERY_19_ACTUAL_OLD_INSERT_BY_NUMBER":
      "DISCOVERY_19_HISTORICAL_HIT_WITHOUT_ANY_GUARDS");
    this.metrics.bump(ctx,"discovery19.calls");
    ctx.metrics.set("discovery19.old_cache_reads",1n);
    ctx.metrics.set("discovery19.old_cache_writes",old===undefined?1n:0n);
    ctx.metrics.set("discovery19.wrong_old_hits",old!==undefined&&wrong?1n:0n);
    ctx.metrics.set("discovery19.predecessor_58_write_sequences",
      BigInt(preceding.predecessorCallCount));
    ctx.status="DISCOVERY_19_RECORDED";
    return output;
  }
}
export function discoverLegacyYearNumberCache(
  handler:Discovery19YearNumberCacheHandler,
  q:Discovery19Request):Discovery19CacheObservation {
  if(!(handler instanceof Discovery19YearNumberCacheHandler))
    throw new MonsterValidationError("पूर्ण ऐतिहासिक cache handler आवश्यक");
  return handler.run(bootstrapMonster(q.calculationDay,q.targetDay),q);
}
