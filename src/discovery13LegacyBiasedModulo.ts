import { BaseMetricsManager, bootstrapMonster, MonsterStageError, MonsterValidationError } from "./monsterBase.ts";
import type { MonsterContext } from "./monsterBase.ts";
import { LEGACY_MODULUS } from "./discovery01LegacyRemainder.ts";
import { patch01Save } from "./patch01Save.ts";
import { patch12NextBowl } from "./patch12NextBowl.ts";
import type { Patch12NextBowlObservation } from "./patch12NextBowl.ts";

// DISCOVERY 13: जुनी modulo निवड जाणीवपूर्वक दुरुस्त करायची नाही.
// ती पहिल्याच 1..M उत्तरावर modulo लावते: rejection किंवा wide answer नाही.
export class LegacyBiasedModuloRankAdapter {
  oldChooseModulo(firstAnswer:bigint,familySize:bigint):bigint {
    if(typeof firstAnswer!=="bigint"||firstAnswer<1n||firstAnswer>LEGACY_MODULUS||
       typeof familySize!=="bigint"||familySize<1n)
      throw new MonsterValidationError("पहिले उत्तर 1..M मध्ये व कुटुंबाचा आकार >=1 हवा");
    return 1n+(firstAnswer-1n)%familySize;
  }
}

export type Discovery13BiasedModuloObservation=Readonly<{
  queriedBowlId:number;
  seal:bigint;
  familySize:bigint;
  firstAnswer:bigint;
  directionStep:1n|-1n;
  biasedRank:bigint;
  answerStream:Readonly<{first:bigint;directionStep:1n|-1n}>;
  preceding:Patch12NextBowlObservation;
  actualNextBowlId:number;
  legacyModuloCalls:1;
  predecessorSharedMemoryWrites:58;
  context:MonsterContext;
}>;

export class Discovery13BiasedModuloHandler {
  private readonly old=new LegacyBiasedModuloRankAdapter();
  private readonly metrics=new BaseMetricsManager();

  run(ctx:MonsterContext,visible:readonly bigint[],
      stones:readonly (readonly bigint[])[],startBowls:readonly bigint[],
      queriedId:number,seal:bigint,familySize:bigint):Discovery13BiasedModuloObservation {
    if(ctx.phase!=="READY"||ctx.status!=="VALIDATED")
      throw new MonsterStageError("DISCOVERY13 पूर्वी READY आणि VALIDATED context आवश्यक");
    if(typeof ctx.calculationDay!=="bigint"||typeof ctx.targetDay!=="bigint"||
       !Number.isInteger(queriedId)||queriedId<1||queriedId>6||
       typeof seal!=="bigint"||typeof familySize!=="bigint"||familySize<1n||
       !Array.isArray(visible)||visible.length!==47||
       Array.from({length:46},(_,k)=>typeof visible[k+1]!=="bigint").some(Boolean)||
       !Array.isArray(stones)||stones.length!==47||
       Array.from({length:46},(_,k)=>stones[k+1]).some(row=>
         !Array.isArray(row)||row.length!==5||
         Array.from({length:5},(_,j)=>typeof row[j]!=="bigint").some(Boolean))||
       !Array.isArray(startBowls)||startBowls.length!==6||
       Array.from({length:6},(_,k)=>typeof startBowls[k]!=="bigint").some(Boolean))
      throw new MonsterValidationError("46 drops, stones, सहा bowls, वैध ID, seal व सकारात्मक bigint आकार हवेत");

    // Stage25 ची खरोखर अंमलात आणलेली successor chain; स्वतंत्र child context.
    const preceding=patch12NextBowl(ctx.calculationDay,ctx.targetDay,
      visible,stones,startBowls,queriedId);
    if(preceding.sharedMemoryWrites!==58||preceding.latchCaptures!==1||
       preceding.preceding.historical.latestSource!=="STIR_12")
      throw new MonsterStageError("संपूर्ण Stage25 चा DROP46 latch आणि 58 writes आवश्यक");
    const bowls=preceding.finalBowls;
    const actualNextBowlId=preceding.correctedNextBowlId;
    const queried=bowls[queriedId-1]!;
    const next=bowls[actualNextBowlId-1]!;
    // नियमाधारित question/stream हे Stage1 च्या production SAVE द्वारे तयार.
    // पण त्यातील rank निवड मात्र खालील historical चुकीचे moduloच आहे.
    const firstAnswer=patch01Save(ctx.calculationDay,ctx.targetDay,
      (queried+seal+181n)**2n+179n*next+seal).savedValue;
    const directionNumber=patch01Save(ctx.calculationDay,ctx.targetDay,
      (firstAnswer+seal+1n+193n)**2n+193n*firstAnswer+197n*bowls[5]!).savedValue;
    const directionStep:1n|-1n=directionNumber%2n===1n?1n:-1n;
    const biasedRank=this.old.oldChooseModulo(firstAnswer,familySize);
    const answerStream=Object.freeze({first:firstAnswer,directionStep});
    const result=Object.freeze({
      queriedBowlId:queriedId,seal,familySize,firstAnswer,directionStep,
      biasedRank,answerStream,preceding,actualNextBowlId,
      legacyModuloCalls:1 as const,predecessorSharedMemoryWrites:58 as const,
      context:ctx
    });
    ctx.branchTrace.push("DISCOVERY_13_REAL_PATCH12_SUCCESSOR_AND_58_WRITES");
    ctx.branchTrace.push("DISCOVERY_13_PRODUCTION_BOWL_ANSWER_STREAM");
    ctx.branchTrace.push("DISCOVERY_13_BIASED_FIRST_ANSWER_MODULO_NO_REJECTION");
    this.metrics.bump(ctx,"discovery13.calls");
    this.metrics.bump(ctx,"discovery13.patch12_routes");
    this.metrics.bump(ctx,"discovery13.answer_streams");
    this.metrics.bump(ctx,"discovery13.actual_legacy_modulo_calls");
    this.metrics.bump(ctx,"discovery13.predecessor_58_write_sequences");
    ctx.status="DISCOVERY_13_RECORDED";
    return result;
  }
}

export function discoverLegacyBiasedModulo(c:bigint,t:bigint,visible:readonly bigint[],
    stones:readonly (readonly bigint[])[],startBowls:readonly bigint[],
    queriedId:number,seal:bigint,familySize:bigint):Discovery13BiasedModuloObservation {
  return new Discovery13BiasedModuloHandler().run(
    bootstrapMonster(c,t),visible,stones,startBowls,queriedId,seal,familySize);
}
