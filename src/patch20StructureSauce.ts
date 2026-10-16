import {
  BaseMetricsManager,bootstrapMonster,MonsterStageError,MonsterValidationError
} from "./monsterBase.ts";
import type {MonsterContext} from "./monsterBase.ts";
import {
  Discovery20StructureSauceHandler,discoverLegacyStructureSauce
} from "./discovery20LegacyStructureSauce.ts";
import type {
  Discovery20StructureObservation,Discovery20StructureRequest
} from "./discovery20LegacyStructureSauce.ts";
import {patch11OrderLatch} from "./patch11OrderLatch.ts";
import type {Patch11OrderObservation} from "./patch11OrderLatch.ts";
import type {Patch18Question} from "./patch18YearWalk.ts";

// PATCH20 — जुना target वरचा चुकीचा sauce प्रत्यक्ष चालूच राहतो.
// खरे वर्ष मिळाल्यावरच त्याच्या पहिल्या दिवसावर दुसरा sauce चालवा;
// target आधीच पहिला दिवस असल्यास पुन्हा 58 shared writes करू नका.
export type Patch20StructureRequest=Readonly<{
  historical:Discovery20StructureRequest;
  firstDaySauceQuestion?:Patch18Question;
}>;
export type Patch20StructureObservation=Readonly<{
  calculationDay:bigint;
  originalTargetDay:bigint;
  trueYearFirstDay:bigint;
  trueYearNumber:bigint;
  historical:Discovery20StructureObservation;
  historicalOldSauceActuallyCalled:true;
  historicalGhostWasWrongTarget:boolean;
  requiredFirstDaySubstitution:boolean;
  newFirstDaySauce:Patch11OrderObservation|null;
  authoritativeBowls:readonly bigint[];
  authoritativeOrderAtDrop46:readonly number[];
  authoritativeFirstDay:bigint;
  firstDaySauceCalls:0|1;
  oldSauceCalls:1;
  structureSauceReady:true;
  trueYearPredecessorCalls:number;
  realStructureSauceCalls:1|2;
  totalRealPredecessorCalls:number;
  totalSharedMemoryWrites:bigint;
  context:MonsterContext;
}>;

export class Patch20StructureSauceHandler {
  private readonly metrics=new BaseMetricsManager();
  readonly preceding:Discovery20StructureSauceHandler;
  constructor(preceding:Discovery20StructureSauceHandler){
    this.preceding=preceding;
  }
  run(ctx:MonsterContext,q:Patch20StructureRequest):Patch20StructureObservation {
    if(ctx.phase!=="READY"||ctx.status!=="VALIDATED")
      throw new MonsterStageError("PATCH20 साठी READY/VALIDATED बाहेरचा संदर्भ आवश्यक");
    if(!q||!q.historical||!q.historical.yearQuestion||
       q.historical.yearQuestion.calculationDay!==ctx.calculationDay||
       q.historical.yearQuestion.targetDay!==ctx.targetDay)
      throw new MonsterValidationError("Stage40 मूळ प्रश्न संदर्भाशी जुळावा");
    // Entire Stage40 chain is actually invoked, including original bad
    // target-day sauce and its actual 46 drops/12 post-stirs/58 writes.
    const history=discoverLegacyStructureSauce(this.preceding,q.historical);
    if(history.context.status!=="DISCOVERY_20_RECORDED"||
       !history.oldSauceActuallyUsed||
       history.correctedStructureSauceComputed||
       history.oldSauce.sharedMemoryWrites!==58||
       history.fullStage39.context.status!=="PATCH_19_APPLIED")
      throw new MonsterStageError("संपूर्ण Stage40 जुन्या sauce ची पुरावा साखळी हवी");
    const firstDay=history.chosenYearFirstDay;
    if(firstDay!==history.yearOpenGateDay+1n||
       !(history.yearOpenGateDay<ctx.targetDay&&
         ctx.targetDay<=history.yearCloseGateDay))
      throw new MonsterStageError("खरा वर्षाचा पहिला दिवस आणि containment जुळत नाही");
    const needsPatch=ctx.targetDay!==firstDay;
    let corrected:Patch11OrderObservation|null=null;
    if(needsPatch){
      const source=q.firstDaySauceQuestion;
      if(!source||typeof source!=="object"||source.targetDay!==firstDay)
        throw new MonsterValidationError("खऱ्या पहिल्या दिवसासाठी स्वतंत्र 46-drop प्रश्न आवश्यक");
      corrected=patch11OrderLatch(ctx.calculationDay,firstDay,
        source.visible,source.stones,source.startBowls);
      if(corrected.sharedMemoryWrites!==58||corrected.latchCaptures!==1||
         corrected.drops!==46||corrected.postStirs!==12||
         corrected.historical.latestSource!=="STIR_12")
        throw new MonsterStageError("नवीन first-day native Sauce ची पूर्ण 58-write साखळी हवी");
    }
    const bowls=corrected?.finalBowls??history.oldSauce.bowls;
    const order=corrected?.orderAt46Latch??history.oldSauce.orderAtDrop46;
    if(bowls.length!==6||order.length!==6||new Set(order).size!==6)
      throw new MonsterStageError("structure sauce मधील सहा bowls/order अपूर्ण");
    const out:Patch20StructureObservation=Object.freeze({
      calculationDay:ctx.calculationDay,originalTargetDay:ctx.targetDay,
      trueYearFirstDay:firstDay,trueYearNumber:history.yearNumber,
      historical:history,historicalOldSauceActuallyCalled:true as const,
      historicalGhostWasWrongTarget:history.historicalWrongTarget,
      requiredFirstDaySubstitution:needsPatch,
      newFirstDaySauce:corrected,
      authoritativeBowls:Object.freeze([...bowls]),
      authoritativeOrderAtDrop46:Object.freeze([...order]),
      authoritativeFirstDay:firstDay,
      firstDaySauceCalls:needsPatch?1 as const:0 as const,
      oldSauceCalls:1 as const,structureSauceReady:true as const,
      trueYearPredecessorCalls:history.trueYearPredecessorCalls,
      realStructureSauceCalls:needsPatch?2 as const:1 as const,
      totalRealPredecessorCalls:history.totalRealPredecessorCalls+(needsPatch?1:0),
      totalSharedMemoryWrites:history.totalSharedMemoryWrites+
        (needsPatch?58n:0n),
      context:ctx
    });
    ctx.branchTrace.push("PATCH_20_FULL_STAGE40_OLD_TARGET_SAUCE_ACTUALLY_EXECUTED");
    ctx.branchTrace.push(needsPatch?
      "PATCH_20_FIRST_DAY_CORRECTED_58_WRITE_NATIVE_SAUCE":
      "PATCH_20_FIRST_DAY_EQUALS_TARGET_REUSE_GHOST");
    ctx.branchTrace.push("PATCH_20_STRUCTURE_SAUCE_AUTHORITATIVE");
    this.metrics.bump(ctx,"patch20.calls");
    this.metrics.bump(ctx,"patch20.old_structure_sauce_calls");
    ctx.metrics.set("patch20.new_first_day_sauce_calls",needsPatch?1n:0n);
    ctx.metrics.set("patch20.total_real_predecessor_calls",
      BigInt(out.totalRealPredecessorCalls));
    ctx.metrics.set("patch20.total_shared_memory_writes",out.totalSharedMemoryWrites);
    ctx.status="PATCH_20_APPLIED";
    return out;
  }
}
export function patch20StructureSauce(
 handler:Patch20StructureSauceHandler,
 q:Patch20StructureRequest
):Patch20StructureObservation {
  if(!(handler instanceof Patch20StructureSauceHandler)||
     !q?.historical?.yearQuestion||
     typeof q.historical.yearQuestion.calculationDay!=="bigint"||
     typeof q.historical.yearQuestion.targetDay!=="bigint")
    throw new MonsterValidationError("पूर्ण Stage41 handler/request आवश्यक");
  const orig=q.historical.yearQuestion;
  return handler.run(
    bootstrapMonster(orig.calculationDay,orig.targetDay),q);
}
