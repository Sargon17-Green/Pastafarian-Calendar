import { BaseMetricsManager, bootstrapMonster, MonsterStageError, MonsterValidationError } from "./monsterBase.ts";
import type { MonsterContext } from "./monsterBase.ts";
import { patch11OrderLatch } from "./patch11OrderLatch.ts";
import type { Patch11OrderObservation } from "./patch11OrderLatch.ts";
import { LegacyNextBowlFixedNameAdapter } from "./discovery12LegacyFixedNextBowl.ts";

// PATCH 12: सहा वाट्यांच्या निश्चित नावक्रमाऐवजी DROP_46 latch मधील cyclic स्थान.
// जुना चुकीचा numerical helper स्वतंत्रपणे प्रत्यक्ष चालवला जातो.
export class Patch12PermutationSuccessorAdapter {
  nextFromLatchedPermutation(order:readonly number[],queriedId:number):number {
    if(!Array.isArray(order)||order.length!==6||
       Array.from({length:6},(_,j)=>order[j]).some(v=>
         !Number.isInteger(v)||v===undefined||v<1||v>6)||
       new Set(order).size!==6||
       !Number.isInteger(queriedId)||queriedId<1||queriedId>6)
      throw new MonsterValidationError("सहा अद्वितीय वाट्यांचा DROP_46 क्रम आणि वैध ID आवश्यक");
    const position=order.indexOf(queriedId);
    if(position<0)throw new MonsterValidationError("वाटीचा ID जतन केलेल्या क्रमात नाही");
    return order[position===5?0:position+1]!;
  }
}
export type Patch12NextBowlObservation=Readonly<{
  queriedBowlId:number;
  correctedNextBowlId:number;
  legacyNextBowlId:number;
  historicalMismatch:boolean;
  orderAt46Latch:readonly number[];
  historicalOverwrittenOrder:readonly number[];
  actualDrop46Order:readonly number[];
  afterDropBowls:readonly bigint[];
  finalBowls:readonly bigint[];
  sharedMemoryWrites:58;
  latchCaptures:1;
  numericSuccessorCalls:1;
  positionalSuccessorCalls:1;
  preceding:Patch11OrderObservation;
  context:MonsterContext;
}>;

export class Patch12NextBowlHandler {
  private readonly metrics=new BaseMetricsManager();
  private readonly old=new LegacyNextBowlFixedNameAdapter();
  private readonly corrected=new Patch12PermutationSuccessorAdapter();

  run(ctx:MonsterContext,visible:readonly bigint[],
      stones:readonly (readonly bigint[])[],startBowls:readonly bigint[],
      queriedId:number):Patch12NextBowlObservation {
    if(ctx.phase!=="READY"||ctx.status!=="VALIDATED")
      throw new MonsterStageError("PATCH12 पूर्वी तयार context आवश्यक");
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
      throw new MonsterValidationError("46 drops, 46×5 stones, सहा bigint bowls आणि वैध ID आवश्यक");

    // पूर्ण Stage23 production मार्ग: 46 drops, 12 post-stirs, 58 जुने writes.
    // स्वतंत्र child context: exception नंतर caller context व inputs जसेच्या तसे.
    const preceding=patch11OrderLatch(ctx.calculationDay,ctx.targetDay,
      visible,stones,startBowls);
    if(preceding.latchCaptures!==1||preceding.sharedMemoryWrites!==58||
       preceding.correctedQueryOrder.length!==6||
       preceding.historical.latestSource!=="STIR_12"||
       preceding.historical.memoryWrites!==58||
       preceding.ledger[45]?.source!=="DROP_46"||
       preceding.ledger[57]?.source!=="STIR_12"||
       preceding.orderAt46Latch.join(",")!==preceding.correctedQueryOrder.join(","))
      throw new MonsterStageError("DROP_46 चा स्वतंत्र latch आणि सर्व 58 writes आवश्यक");

    // जाणीवपूर्वक चुकीची ऐतिहासिक पद्धत प्रत्यक्ष स्वतंत्रपणे call करा.
    const legacyNextBowlId=this.old.oldNextBowlFixedName(queriedId);
    // योग्य successor फक्त immutable DROP46 positional order वरून.
    const correctedNextBowlId=this.corrected.nextFromLatchedPermutation(
      preceding.orderAt46Latch,queriedId);
    const result=Object.freeze({
      queriedBowlId:queriedId,correctedNextBowlId,legacyNextBowlId,
      historicalMismatch:correctedNextBowlId!==legacyNextBowlId,
      orderAt46Latch:preceding.orderAt46Latch,
      historicalOverwrittenOrder:preceding.legacyQueryOrder,
      actualDrop46Order:preceding.correctedQueryOrder,
      afterDropBowls:preceding.afterDropBowls,finalBowls:preceding.finalBowls,
      sharedMemoryWrites:58 as const,latchCaptures:1 as const,
      numericSuccessorCalls:1 as const,positionalSuccessorCalls:1 as const,
      preceding,context:ctx
    });
    ctx.branchTrace.push("PATCH_12_REUSE_PATCH11_REAL_DROP46_LATCH");
    ctx.branchTrace.push("PATCH_12_RUN_LEGACY_FIXED_NUMERIC_SUCCESSOR");
    ctx.branchTrace.push("PATCH_12_CORRECT_SUCCESSOR_BY_FROZEN_POSITION");
    this.metrics.bump(ctx,"patch12.calls");
    this.metrics.bump(ctx,"patch12.legacy_numeric_calls");
    this.metrics.bump(ctx,"patch12.corrected_positional_calls");
    this.metrics.bump(ctx,"patch12.preceding_58_write_sequences");
    if(result.historicalMismatch)this.metrics.bump(ctx,"patch12.historical_mismatches");
    ctx.status="PATCH_12_APPLIED";
    return result;
  }
}
export function patch12NextBowl(c:bigint,t:bigint,visible:readonly bigint[],
  stones:readonly (readonly bigint[])[],startBowls:readonly bigint[],
  queriedId:number):Patch12NextBowlObservation {
  return new Patch12NextBowlHandler().run(
    bootstrapMonster(c,t),visible,stones,startBowls,queriedId);
}
