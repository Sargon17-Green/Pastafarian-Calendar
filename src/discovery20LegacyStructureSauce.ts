import {
  BaseMetricsManager,bootstrapMonster,MonsterStageError,MonsterValidationError
} from "./monsterBase.ts";
import type {MonsterContext} from "./monsterBase.ts";
import {patch11OrderLatch} from "./patch11OrderLatch.ts";
import type {Patch11OrderObservation} from "./patch11OrderLatch.ts";
import {patch19GuardedYearCache} from "./patch19GuardedYearCache.ts";
import type {
  Patch19YearCacheHandler,Patch19CacheObservation
} from "./patch19GuardedYearCache.ts";
import type {Discovery19Request} from "./discovery19LegacyYearCache.ts";
import type {Patch18Question} from "./patch18YearWalk.ts";

// DISCOVERY20 — जुन्या रचनेचा sauce मूळ targetDay वरच चालतो.
// वर्ष निवडल्यानंतर पहिल्या दिवसावर target बदलणे हा Stage41 चा PATCH आहे.
// येथे तो अजिबात वापरलेला नाही: फक्त forensic तुलना करण्यासाठी नोंदतो.
export type Discovery20LegacySauce=Readonly<{
  calculationDay:bigint;
  originalTargetDay:bigint;
  bowls:readonly bigint[];
  orderAtDrop46:readonly number[];
  sharedMemoryWrites:58;
  oldStructureSauceCalls:1;
  preceding:Patch11OrderObservation;
}>;
export class LegacyStructureSauceAdapter {
  oldStructureSauce(cDay:bigint,originalTargetDay:bigint,
      source:Patch18Question):Discovery20LegacySauce {
    if(typeof cDay!=="bigint"||typeof originalTargetDay!=="bigint"||
       !source||typeof source!=="object"||
       source.targetDay!==originalTargetDay)
      throw new MonsterValidationError("मूळ targetDay चे 46-drop source आवश्यक");
    // The physical old chain: genuine 46 drop rounds + twelve post-stirs,
    // all 58 historical shared writes, and the correct DROP46 order latch.
    // It is invoked with ORIGINAL t, even after Year5000 is selected.
    const preceding=patch11OrderLatch(cDay,originalTargetDay,
      source.visible,source.stones,source.startBowls);
    if(preceding.sharedMemoryWrites!==58||preceding.latchCaptures!==1||
       preceding.drops!==46||preceding.postStirs!==12||
       preceding.historical.latestSource!=="STIR_12")
      throw new MonsterStageError("जुन्या structure sauce चा 58-write मार्ग अपूर्ण");
    return Object.freeze({
      calculationDay:cDay,originalTargetDay,
      bowls:Object.freeze([...preceding.finalBowls]),
      orderAtDrop46:Object.freeze([...preceding.orderAt46Latch]),
      sharedMemoryWrites:58 as const,oldStructureSauceCalls:1 as const,
      preceding
    });
  }
}
export type Discovery20StructureRequest=Readonly<{
  yearQuestion:Discovery19Request;
  originalSauceQuestion:Patch18Question;
}>;
export type Discovery20StructureObservation=Readonly<{
  calculationDay:bigint;
  originalTargetDay:bigint;
  chosenYearFirstDay:bigint;
  yearNumber:bigint;
  yearOpenGateDay:bigint;
  yearCloseGateDay:bigint;
  historicalWrongTarget:boolean;
  oldSauce:Discovery20LegacySauce;
  oldSauceActuallyUsed:true;
  correctedStructureSauceComputed:false;
  authoritativeStructureSauceReady:false;
  fullStage39:Patch19CacheObservation;
  trueYearPredecessorCalls:number;
  realSaucePredecessorCalls:number;
  totalRealPredecessorCalls:number;
  totalSharedMemoryWrites:bigint;
  context:MonsterContext;
}>;
export class Discovery20StructureSauceHandler {
  private readonly metrics=new BaseMetricsManager();
  private readonly old=new LegacyStructureSauceAdapter();
  readonly cacheHandler:Patch19YearCacheHandler;
  constructor(cacheHandler:Patch19YearCacheHandler){
    this.cacheHandler=cacheHandler;
  }
  run(ctx:MonsterContext,q:Discovery20StructureRequest):Discovery20StructureObservation {
    if(ctx.phase!=="READY"||ctx.status!=="VALIDATED")
      throw new MonsterStageError("DISCOVERY20 साठी READY/VALIDATED owner आवश्यक");
    if(!q||!q.yearQuestion||!q.originalSauceQuestion||
       q.yearQuestion.calculationDay!==ctx.calculationDay||
       q.yearQuestion.targetDay!==ctx.targetDay||
       q.originalSauceQuestion.targetDay!==ctx.targetDay)
      throw new MonsterValidationError("Stage39 वर्ष-प्रश्न व मूळ t sauce-प्रश्न जुळावा");
    // The whole REAL Stage39 path is physically executed first.
    // It contains original Stage38 wrong number-only cache and the new
    // three-guard corrected cache, plus the full Stage37 true year walk.
    const earlier=patch19GuardedYearCache(this.cacheHandler,q.yearQuestion);
    if(earlier.context.status!=="PATCH_19_APPLIED"||
       !earlier.correctedGuardsApplied||
       earlier.originalWrongHistory.preceding.authoritative.gateProvenance!==
          "PHYSICALLY_RECOMPUTED_SIGNED_GATES")
      throw new MonsterStageError("Stage39 चा संपूर्ण खरा predecessor हवा");
    const chosen=earlier.correctedServed.year;
    if(!(chosen.openGateDay<ctx.targetDay&&ctx.targetDay<=chosen.closeGateDay))
      throw new MonsterStageError("निवडलेले वर्ष मूळ targetDay धरत नाही");
    const firstDay=chosen.openGateDay+1n;
    // Deliberately old, erroneous t. DO NOT run sauce(c, firstDay).
    const oldSauce=this.old.oldStructureSauce(
      ctx.calculationDay,ctx.targetDay,q.originalSauceQuestion);
    const out=Object.freeze({
      calculationDay:ctx.calculationDay,originalTargetDay:ctx.targetDay,
      chosenYearFirstDay:firstDay,yearNumber:chosen.number,
      yearOpenGateDay:chosen.openGateDay,yearCloseGateDay:chosen.closeGateDay,
      historicalWrongTarget:ctx.targetDay!==firstDay,
      oldSauce,oldSauceActuallyUsed:true as const,
      correctedStructureSauceComputed:false as const,
      authoritativeStructureSauceReady:false as const,
      fullStage39:earlier,
      trueYearPredecessorCalls:earlier.trueYearPredecessorCalls,
      realSaucePredecessorCalls:1,
      totalRealPredecessorCalls:earlier.trueYearPredecessorCalls+1,
      totalSharedMemoryWrites:earlier.predecessorSharedWrites+58n,
      context:ctx
    });
    ctx.branchTrace.push("DISCOVERY_20_FULL_PATCH19_TRUE_YEAR_AND_GUARDED_CACHE");
    ctx.branchTrace.push("DISCOVERY_20_REAL_OLD_STRUCTURE_SAUCE_ORIGINAL_TARGET");
    ctx.branchTrace.push("DISCOVERY_20_NO_FIRST_DAY_SUBSTITUTION");
    this.metrics.bump(ctx,"discovery20.calls");
    this.metrics.bump(ctx,"discovery20.old_structure_sauce_calls");
    this.metrics.bump(ctx,"discovery20.old_58_write_sequences");
    if(out.historicalWrongTarget)
      this.metrics.bump(ctx,"discovery20.wrong_target_witness");
    ctx.status="DISCOVERY_20_RECORDED";
    return out;
  }
}
export function discoverLegacyStructureSauce(
  handler:Discovery20StructureSauceHandler,
  request:Discovery20StructureRequest):Discovery20StructureObservation {
  if(!(handler instanceof Discovery20StructureSauceHandler)||
     !request?.yearQuestion||
     typeof request.yearQuestion.calculationDay!=="bigint"||
     typeof request.yearQuestion.targetDay!=="bigint")
    throw new MonsterValidationError("पूर्ण Stage40 source आणि handler आवश्यक");
  return handler.run(bootstrapMonster(
    request.yearQuestion.calculationDay,request.yearQuestion.targetDay),request);
}
