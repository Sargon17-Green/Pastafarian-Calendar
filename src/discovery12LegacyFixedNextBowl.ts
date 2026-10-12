import { BaseMetricsManager, bootstrapMonster, MonsterStageError, MonsterValidationError } from "./monsterBase.ts";
import type { MonsterContext } from "./monsterBase.ts";
import { patch11OrderLatch } from "./patch11OrderLatch.ts";
import type { Patch11OrderObservation } from "./patch11OrderLatch.ts";

// DISCOVERY 12: ऐतिहासिक पुढची वाटी नावाच्या स्थिर ID क्रमाने निवडतो.
// DROP_46 चा योग्य latch उपलब्ध असला तरी हा जुना successor तो वापरत नाही.
export class LegacyNextBowlFixedNameAdapter {
  oldNextBowlFixedName(queriedId:number):number {
    if(!Number.isInteger(queriedId)||queriedId<1||queriedId>6)
      throw new MonsterValidationError("विचारलेल्या वाटीचा ID 1 ते 6 असावा");
    return queriedId===6 ? 1 : queriedId+1;
  }
}

export type Discovery12FixedSuccessorObservation=Readonly<{
  queriedBowlId:number;
  legacyNextBowlId:number;
  orderAt46Latch:readonly number[];
  historicalOverwrittenOrder:readonly number[];
  actualDrop46Order:readonly number[];
  afterDropBowls:readonly bigint[];
  finalBowls:readonly bigint[];
  sharedMemoryWrites:58;
  latchCaptures:1;
  numericSuccessorCalls:1;
  preceding:Patch11OrderObservation;
  context:MonsterContext;
}>;

export class Discovery12FixedSuccessorHandler {
  private readonly legacy=new LegacyNextBowlFixedNameAdapter();
  private readonly metrics=new BaseMetricsManager();

  run(ctx:MonsterContext,visible:readonly bigint[],
      stones:readonly (readonly bigint[])[],startBowls:readonly bigint[],
      queriedId:number):Discovery12FixedSuccessorObservation {
    if(ctx.phase!=="READY"||ctx.status!=="VALIDATED")
      throw new MonsterStageError("स्थिर ID successor शोधापूर्वी तयार context आवश्यक");
    if(typeof ctx.calculationDay!=="bigint"||typeof ctx.targetDay!=="bigint"||
       !Number.isInteger(queriedId)||queriedId<1||queriedId>6||
       !Array.isArray(visible)||visible.length!==47||
       Array.from({length:46},(_,k)=>typeof visible[k+1]!=="bigint").some(Boolean)||
       !Array.isArray(stones)||stones.length!==47||
       Array.from({length:46},(_,k)=>stones[k+1]).some(row=>
         !Array.isArray(row)||row.length!==5||
         Array.from({length:5},(_,j)=>typeof row[j]!=="bigint").some(Boolean))||
       !Array.isArray(startBowls)||startBowls.length!==6||
       Array.from({length:6},(_,k)=>typeof startBowls[k]!=="bigint").some(Boolean))
      throw new MonsterValidationError("46 drops, 46 stone rows, सहा bowls आणि वैध ID हवेत");

    // आधीच्या stage 23 ची पूर्ण verified production chain, child context मध्ये.
    // Old numerical helper प्रत्यक्ष चालतो; या stage मध्ये successor patch नाही.
    const preceding=patch11OrderLatch(ctx.calculationDay,ctx.targetDay,
      visible,stones,startBowls);
    const legacyNextBowlId=this.legacy.oldNextBowlFixedName(queriedId);
    if(preceding.latchCaptures!==1||preceding.sharedMemoryWrites!==58||
       preceding.correctedQueryOrder.length!==6||
       !preceding.correctedQueryOrder.includes(queriedId)||
       preceding.historical.latestSource!=="STIR_12")
      throw new MonsterStageError("पूर्वीच्या DROP46 latch व जुन्या 58 writes आवश्यक");
    const result=Object.freeze({
      queriedBowlId:queriedId,
      legacyNextBowlId,
      orderAt46Latch:preceding.orderAt46Latch,
      historicalOverwrittenOrder:preceding.legacyQueryOrder,
      actualDrop46Order:preceding.correctedQueryOrder,
      afterDropBowls:preceding.afterDropBowls,
      finalBowls:preceding.finalBowls,
      sharedMemoryWrites:58 as const,
      latchCaptures:1 as const,
      numericSuccessorCalls:1 as const,
      preceding,context:ctx
    });

    ctx.branchTrace.push("DISCOVERY_12_REUSE_PATCH11_DROP46_LATCH");
    ctx.branchTrace.push("DISCOVERY_12_FIXED_NUMERIC_ID_SUCCESSOR");
    ctx.branchTrace.push("DISCOVERY_12_PERMUTATION_POSITION_IGNORED");
    this.metrics.bump(ctx,"discovery12.calls");
    this.metrics.bump(ctx,"discovery12.legacy_successor_calls");
    this.metrics.bump(ctx,"discovery12.preceding_latch_reads");
    this.metrics.bump(ctx,"discovery12.preceding_58_write_sequences");
    ctx.status="DISCOVERY_12_RECORDED";
    return result;
  }
}

export function discoverLegacyFixedNextBowl(c:bigint,t:bigint,
    visible:readonly bigint[],stones:readonly (readonly bigint[])[],
    startBowls:readonly bigint[],queriedId:number):Discovery12FixedSuccessorObservation {
  return new Discovery12FixedSuccessorHandler().run(
    bootstrapMonster(c,t),visible,stones,startBowls,queriedId);
}
