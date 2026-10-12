import { BaseMetricsManager, bootstrapMonster, MonsterStageError, MonsterValidationError } from "./monsterBase.ts";
import type { MonsterContext } from "./monsterBase.ts";
import { patch01Save } from "./patch01Save.ts";
import { patch08Permutation } from "./patch08Permutation.ts";
import { patch10Stir } from "./patch10SnapshotStir.ts";

// DISCOVERY 11: एकाच सामान्य order-memory वर 46 drops नंतर 12 stirs लिहितात.
// ऐतिहासिक query हा 58 वा (STIR_12) order वाचतो; drop46 latch या stage मध्ये नाही.
export type LegacyOrderWrite = Readonly<{
  index: number;
  source: string;
  order: readonly number[];
}>;
export type Discovery11MemoryObservation = Readonly<{
  initialBowls: readonly bigint[];
  afterDropBowls: readonly bigint[];
  finalBowls: readonly bigint[];
  latestOrder: readonly number[];
  legacyQueryOrder: readonly number[];
  latestSource: string;
  ledger: readonly LegacyOrderWrite[];
  memoryWrites: number;
  dropRounds: number;
  postStirRounds: number;
  queryReads: number;
  context: MonsterContext;
}>;

export class LegacySharedOrderMemoryAdapter {
  // deliberately one overwritable six-cell order buffer; no drop46 latch.
  private readonly sharedOrder: number[] = [1, 2, 3, 4, 5, 6];
  private readonly history: LegacyOrderWrite[] = [];
  private queryCount=0;

  write(source:string, order:readonly number[]):LegacyOrderWrite {
    if(!/^DROP_(?:[1-9]|[1-3][0-9]|4[0-6])$|^STIR_(?:[1-9]|1[0-2])$/.test(source)||
       !Array.isArray(order)||order.length!==6||
       order.some(v=>!Number.isInteger(v)||v<1||v>6)||
       new Set(order).size!==6){
      throw new MonsterValidationError("सामान्य order memory साठी वैध source आणि permutation हवी");
    }
    // तसाच shared buffer लिहिला जातो; पूर्वीचे value जतन करणारा semantic latch नाही.
    for(let k=0;k<6;k++)this.sharedOrder[k]=order[k]!;
    const entry=Object.freeze({index:this.history.length+1,source,
      order:Object.freeze([...this.sharedOrder])});
    this.history.push(entry); // diagnostic पुरावा; query कधीही या ledger मधून वाचत नाही
    return entry;
  }

  queryLegacyOrder():readonly number[] {
    this.queryCount++;
    return Object.freeze([...this.sharedOrder]);
  }
  get writes():number{return this.history.length;}
  get queries():number{return this.queryCount;}
  get latestSource():string{return this.history[this.history.length-1]?.source??"NONE";}
  get writeLedger():readonly LegacyOrderWrite[]{return Object.freeze([...this.history]);}
  get memoryIdentity():object{return this.sharedOrder;}
}

export class Discovery11OverwrittenOrderHandler {
  private readonly metrics=new BaseMetricsManager();
  private readonly afterWrite?: (writeIndex:number)=>void;
  constructor(afterWrite?: (writeIndex:number)=>void){this.afterWrite=afterWrite;}

  run(ctx:MonsterContext,visible:readonly bigint[],
      stoneRows:readonly (readonly bigint[])[],startBowls:readonly bigint[]
  ):Discovery11MemoryObservation{
    if(ctx.phase!=="READY"||ctx.status!=="VALIDATED"){
      throw new MonsterStageError("सामायिक क्रम-स्मृती शोधासाठी तयार context आवश्यक");
    }
    if(typeof ctx.calculationDay!=="bigint"||typeof ctx.targetDay!=="bigint"||
       !Array.isArray(visible)||visible.length!==47||
       Array.from({length:46},(_,k)=>typeof visible[k+1]!=="bigint").some(Boolean)||
       !Array.isArray(stoneRows)||stoneRows.length!==47||
       Array.from({length:46},(_,k)=>stoneRows[k+1]).some(stone=>
         !Array.isArray(stone)||stone.length!==5||
         Array.from({length:5},(_,j)=>typeof stone[j]!=="bigint").some(Boolean))||
       !Array.isArray(startBowls)||startBowls.length!==6||
       Array.from({length:6},(_,k)=>typeof startBowls[k]!=="bigint").some(Boolean)){
      throw new MonsterValidationError("46 visible drops, 46 × 5 stones, सहा bigint bowls आवश्यक");
    }

    // memory/local bowls हे फक्त या invocation चे. अपवाद आल्यास context/input अविकृत.
    const memory=new LegacySharedOrderMemoryAdapter();
    let bowls:readonly bigint[]=[...startBowls];
    for(let i=1;i<=46;i++){
      const step=patch10Stir(ctx.calculationDay,ctx.targetDay,
        i,visible[i]!,bowls,stoneRows[i]!);
      bowls=step.correctedBowls; // Patch10 patched shadow, never historical in-place
      memory.write("DROP_"+i,step.order);
      this.afterWrite?.(memory.writes);
    }
    const afterDropBowls=Object.freeze([...bowls]);

    // Stage21 snapshot semantics जपून canonical 12 post-stirs.
    for(let stir=1;stir<=12;stir++){
      const old=Object.freeze([...bowls]);
      const saved=patch01Save(ctx.calculationDay,ctx.targetDay,
        old.reduce((sum,v)=>sum+v,0n)+149n*BigInt(stir)).savedValue;
      const order=patch08Permutation(ctx.calculationDay,ctx.targetDay,saved).order;
      const pending=[...old];
      for(let pos=1;pos<=6;pos++){
        const id=order[pos-1]!;
        const prev=order[(pos+4)%6]!;
        const next=order[pos%6]!;
        const mix:bigint=old[id-1]!+3n*old[prev-1]!+5n*old[next-1]!+
          saved+BigInt(stir)+BigInt(pos*pos);
        pending[id-1]=patch01Save(ctx.calculationDay,ctx.targetDay,
          mix*mix+7n*old[prev-1]!*old[next-1]!).savedValue;
      }
      bowls=Object.freeze(pending);
      memory.write("STIR_"+stir,order); // त्याच जुन्या order buffer ला overwrite
      this.afterWrite?.(memory.writes);
    }
    const latestOrder=memory.queryLegacyOrder(); // query ledger[46] नाही!
    if(memory.writes!==58||memory.queries!==1||memory.latestSource!=="STIR_12"){
      throw new MonsterStageError("58 वेळा लिहिलेली सामायिक स्मृती आवश्यक");
    }
    const result=Object.freeze({
      initialBowls:Object.freeze([...startBowls]),afterDropBowls,
      finalBowls:Object.freeze([...bowls]),latestOrder,
      legacyQueryOrder:latestOrder,latestSource:memory.latestSource,
      ledger:memory.writeLedger,memoryWrites:memory.writes,
      dropRounds:46,postStirRounds:12,queryReads:memory.queries,context:ctx
    });
    ctx.branchTrace.push("DISCOVERY_11_46_PATCH10_BOWL_ROUNDS");
    ctx.branchTrace.push("DISCOVERY_11_12_POST_STIR_ROUNDS");
    ctx.branchTrace.push("DISCOVERY_11_ONE_OVERWRITABLE_ORDER_MEMORY");
    ctx.branchTrace.push("DISCOVERY_11_QUERY_READS_LAST_STIR");
    this.metrics.bump(ctx,"discovery11.calls");
    for(let n=0;n<46;n++)this.metrics.bump(ctx,"discovery11.drop_rounds");
    for(let n=0;n<12;n++)this.metrics.bump(ctx,"discovery11.post_stirs");
    for(let n=0;n<58;n++)this.metrics.bump(ctx,"discovery11.shared_order_writes");
    this.metrics.bump(ctx,"discovery11.legacy_query_reads");
    ctx.status="DISCOVERY_11_RECORDED";
    return result;
  }
}

export function discoverLegacyOrderMemory(c:bigint,t:bigint,visible:readonly bigint[],
  stoneRows:readonly (readonly bigint[])[],startBowls:readonly bigint[]
):Discovery11MemoryObservation{
  return new Discovery11OverwrittenOrderHandler().run(
    bootstrapMonster(c,t),visible,stoneRows,startBowls);
}
