import { BaseMetricsManager, bootstrapMonster, MonsterStageError, MonsterValidationError } from "./monsterBase.ts";
import type { MonsterContext } from "./monsterBase.ts";
import { patch08Permutation } from "./patch08Permutation.ts";
import { Discovery11OverwrittenOrderHandler } from "./discovery11LegacyOrderMemory.ts";
import type { Discovery11MemoryObservation } from "./discovery11LegacyOrderMemory.ts";

// PATCH 11: DROP_46 च्या खऱ्या shared write नंतर एकदाच स्वतंत्र latch.
// जुना shared buffer 58 वेळा overwrite होतोच; त्याचा legacy query अपरिवर्तित.
export class Patch11Drop46LatchAdapter {
  private saved:readonly number[]|null=null;
  private captureCount=0;
  private queryCount=0;
  captureAfterWrite(writeIndex:number,order:readonly number[]):void {
    if(writeIndex!==46||this.saved!==null||!Array.isArray(order)||order.length!==6||
       order.some(v=>!Number.isInteger(v)||v<1||v>6)||new Set(order).size!==6)
      throw new MonsterValidationError("DROP_46 नंतर एकदाच स्वतंत्र सहा-ID latch आवश्यक");
    this.saved=Object.freeze([...order]);
    this.captureCount++;
  }
  queryOrder():readonly number[] {
    if(this.saved===null||this.captureCount!==1)
      throw new MonsterStageError("DROP_46 latch शिवाय semantic query नको");
    this.queryCount++;
    return Object.freeze([...this.saved]);
  }
  get latchOrder():readonly number[]|null{return this.saved;}
  get captures():number{return this.captureCount;}
  get queries():number{return this.queryCount;}
}
export type Patch11OrderObservation=Readonly<{
  orderAt46Latch:readonly number[];
  correctedQueryOrder:readonly number[];
  legacyQueryOrder:readonly number[];
  initialBowls:readonly bigint[];
  afterDropBowls:readonly bigint[];
  finalBowls:readonly bigint[];
  ledger:Discovery11MemoryObservation["ledger"];
  historical:Discovery11MemoryObservation;
  latchCaptures:1;
  latchWriteIndex:46;
  correctedQueryReads:1;
  legacyQueryReads:1;
  sharedMemoryWrites:58;
  drops:46;
  postStirs:12;
  context:MonsterContext;
}>;
export class Patch11OrderLatchHandler {
  private readonly metrics=new BaseMetricsManager();
  private readonly afterWrite?: (writeIndex:number)=>void;
  constructor(afterWrite?: (writeIndex:number)=>void){this.afterWrite=afterWrite;}
  run(ctx:MonsterContext,visible:readonly bigint[],
      stones:readonly (readonly bigint[])[],startBowls:readonly bigint[]):Patch11OrderObservation{
    if(ctx.phase!=="READY"||ctx.status!=="VALIDATED")
      throw new MonsterStageError("latch लावण्यापूर्वी तयार context आवश्यक");
    if(typeof ctx.calculationDay!=="bigint"||typeof ctx.targetDay!=="bigint"||
       !Array.isArray(visible)||visible.length!==47||
       Array.from({length:46},(_,k)=>typeof visible[k+1]!=="bigint").some(Boolean)||
       !Array.isArray(stones)||stones.length!==47||
       Array.from({length:46},(_,k)=>stones[k+1]).some(row=>
         !Array.isArray(row)||row.length!==5||
         Array.from({length:5},(_,j)=>typeof row[j]!=="bigint").some(Boolean))||
       !Array.isArray(startBowls)||startBowls.length!==6||
       Array.from({length:6},(_,k)=>typeof startBowls[k]!=="bigint").some(Boolean))
      throw new MonsterValidationError("46 drops, 46×5 stones व सहा bigint bowls आवश्यक");

    const latch=new Patch11Drop46LatchAdapter();
    let observedWrites=0,capturedAt=0;
    // Stage22 original handler: खरे 46 Stage21 bowl rounds, 12 canonical
    // post-stirs, 58 writes आणि जुनी STIR_12 query सगळे चालतात.
    const old=new Discovery11OverwrittenOrderHandler(writeIndex=>{
      observedWrites++;
      if(writeIndex!==observedWrites)
        throw new MonsterStageError("shared order writes मध्ये gap नको");
      if(writeIndex===46){
        // वास्तविक DROP_46 write *झाल्यावर* Stage17 production computation
        // पुन्हा वाचून independent clone; forensic ledger हा source नाही.
        const computed=patch08Permutation(
          ctx.calculationDay,ctx.targetDay,visible[46]!).order;
        latch.captureAfterWrite(writeIndex,computed);
        capturedAt=writeIndex;
      }
      this.afterWrite?.(writeIndex);
    });
    // स्वतंत्र child context: मध्यात fault आल्यास बाहेरचा ctx unchanged.
    const historical=old.run(
      bootstrapMonster(ctx.calculationDay,ctx.targetDay),visible,stones,startBowls);
    if(observedWrites!==58||historical.memoryWrites!==58||
       historical.queryReads!==1||historical.latestSource!=="STIR_12"||
       historical.ledger[45]?.source!=="DROP_46"||
       historical.ledger[57]?.source!=="STIR_12"||
       latch.captures!==1||capturedAt!==46||latch.latchOrder===null||
       historical.ledger[45]!.order.join(",")!==latch.latchOrder.join(","))
      throw new MonsterStageError("DROP_46 latch एकदाच व जुन्या 58 writes पूर्ण हव्यात");

    const correctedQueryOrder=latch.queryOrder();
    const orderAt46Latch=latch.latchOrder;
    if(orderAt46Latch===null||latch.queries!==1)
      throw new MonsterStageError("एक query केवळ latch मधून");
    ctx.branchTrace.push("PATCH_11_REAL_46_DROP_ROUNDS");
    ctx.branchTrace.push("PATCH_11_LATCH_ONCE_AFTER_DROP_46");
    ctx.branchTrace.push("PATCH_11_PRESERVE_12_POST_STIR_OVERWRITES");
    ctx.branchTrace.push("PATCH_11_CORRECTED_QUERY_FROM_INDEPENDENT_LATCH");
    this.metrics.bump(ctx,"patch11.calls");
    this.metrics.bump(ctx,"patch11.latch_writes");
    this.metrics.bump(ctx,"patch11.semantic_queries");
    this.metrics.bump(ctx,"patch11.legacy_queries");
    for(let n=0;n<58;n++)this.metrics.bump(ctx,"patch11.shared_memory_writes");
    for(let n=0;n<46;n++)this.metrics.bump(ctx,"patch11.drop_rounds");
    for(let n=0;n<12;n++)this.metrics.bump(ctx,"patch11.post_stirs");
    ctx.status="PATCH_11_APPLIED";
    return Object.freeze({
      orderAt46Latch,correctedQueryOrder,legacyQueryOrder:historical.legacyQueryOrder,
      initialBowls:historical.initialBowls,afterDropBowls:historical.afterDropBowls,
      finalBowls:historical.finalBowls,ledger:historical.ledger,historical,
      latchCaptures:1 as const,latchWriteIndex:46 as const,
      correctedQueryReads:1 as const,legacyQueryReads:1 as const,
      sharedMemoryWrites:58 as const,drops:46 as const,postStirs:12 as const,
      context:ctx
    });
  }
}
export function patch11OrderLatch(c:bigint,t:bigint,visible:readonly bigint[],
  stones:readonly (readonly bigint[])[],startBowls:readonly bigint[]):Patch11OrderObservation{
  return new Patch11OrderLatchHandler().run(
    bootstrapMonster(c,t),visible,stones,startBowls);
}
