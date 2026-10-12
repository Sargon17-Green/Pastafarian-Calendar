import { BaseMetricsManager,bootstrapMonster,MonsterStageError,MonsterValidationError } from "./monsterBase.ts";
import type { MonsterContext } from "./monsterBase.ts";
import { LEGACY_MODULUS } from "./discovery01LegacyRemainder.ts";
import { Patch13RejectionRankAdapter,patch13RejectionRank } from "./patch13RejectionRank.ts";
import type { Patch13RankObservation,Patch13AnswerStream,Patch13RankSelection } from "./patch13RejectionRank.ts";

// DISCOVERY 14: हा जाणूनबुजून चुकीचा जुना short-only मार्ग आहे.
// N>M असताना threshold=floor(M/N)*N=0; अमर्याद rejection-loop न करता
// जुन्या मार्गाची blocked अवस्था आणि अवैध zero-rank जतन केली जाते.
// Stage29 Wide Choice चा dispatcher येथे जोडलेला नाही.
export type LegacyShortOnlyRank=Readonly<{
  familySize:bigint;
  rank:bigint;
  blocked:boolean;
  legacyAcceptanceLimit:bigint;
  shortSelection:Patch13RankSelection|null;
  shortSelectorCalls:0|1;
  wideSelectorCalls:0;
}>;

export class LegacyShortOnlyWideSelectionAdapter {
  private readonly shortSelector=new Patch13RejectionRankAdapter();

  oldChooseShortOnly(stream:Patch13AnswerStream,N:bigint):LegacyShortOnlyRank {
    if(typeof stream!=="object"||stream===null||
      typeof stream.first!=="bigint"||stream.first<1n||stream.first>LEGACY_MODULUS||
      (stream.directionStep!==1n&&stream.directionStep!==-1n)||
      typeof N!=="bigint"||N<1n)
      throw new MonsterValidationError("1..M उत्तरप्रवाह, दिशा ±1 व सकारात्मक N आवश्यक");

    const threshold=(LEGACY_MODULUS/N)*N;
    if(N>LEGACY_MODULUS){
      // जुना short-only पथ: Wide Choice नाही; अवैध शून्य परत.
      if(threshold!==0n)throw new MonsterStageError("N>M साठी शून्य threshold अपेक्षित");
      return Object.freeze({
        familySize:N,rank:0n,blocked:true,legacyAcceptanceLimit:0n,
        shortSelection:null,shortSelectorCalls:0 as const,wideSelectorCalls:0 as const
      });
    }
    // आधीची verified PATCH13 short selection खरी invoke करतो.
    const shortSelection=this.shortSelector.choose(stream,N);
    if(shortSelection.mode!=="SHORT"||shortSelection.acceptanceLimit!==threshold)
      throw new MonsterStageError("जुन्या short मार्गात PATCH13 ची लहान निवडच आवश्यक");
    return Object.freeze({
      familySize:N,rank:shortSelection.rank,blocked:false,
      legacyAcceptanceLimit:threshold,shortSelection,
      shortSelectorCalls:1 as const,wideSelectorCalls:0 as const
    });
  }
}

export type Discovery14ShortOnlyObservation=Readonly<{
  queriedBowlId:number;
  seal:bigint;
  familySize:bigint;
  firstAnswer:bigint;
  directionStep:1n|-1n;
  legacyShortOnlyRank:bigint;
  blockedWideSelection:boolean;
  correctedPredecessorRank:bigint;
  historicalMismatch:boolean;
  legacyShortOnlyCalls:1;
  predecessorSharedMemoryWrites:58;
  oldResult:LegacyShortOnlyRank;
  preceding:Patch13RankObservation;
  context:MonsterContext;
}>;

export class Discovery14ShortOnlyWideHandler {
  private readonly historical=new LegacyShortOnlyWideSelectionAdapter();
  private readonly metrics=new BaseMetricsManager();

  run(ctx:MonsterContext,visible:readonly bigint[],
      stones:readonly (readonly bigint[])[],startBowls:readonly bigint[],
      queriedId:number,seal:bigint,familySize:bigint):Discovery14ShortOnlyObservation {
    if(ctx.phase!=="READY"||ctx.status!=="VALIDATED")
      throw new MonsterStageError("DISCOVERY14 पूर्वी वैध READY context आवश्यक");
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
      throw new MonsterValidationError("46 थेंब, 46 दगड, सहा वाट्या, ID, seal व आकार आवश्यक");

    // Complete and already verified PATCH13 production chain, child context.
    const preceding=patch13RejectionRank(ctx.calculationDay,ctx.targetDay,
      visible,stones,startBowls,queriedId,seal,familySize);
    if(preceding.predecessorSharedMemoryWrites!==58||
      preceding.preceding.legacyModuloCalls!==1||
      preceding.preceding.preceding.latchCaptures!==1||
      preceding.preceding.preceding.preceding.historical.latestSource!=="STIR_12"||
      preceding.correctedRank<1n||preceding.correctedRank>familySize)
      throw new MonsterStageError("आधीची सत्यापित PATCH13 पूर्ण 58-write साखळी आवश्यक");

    // Explicit actual old method call, independent of corrected rank.
    const oldResult=this.historical.oldChooseShortOnly(
      Object.freeze({first:preceding.firstAnswer,directionStep:preceding.directionStep}),
      familySize);
    if(oldResult.blocked!==(familySize>LEGACY_MODULUS)||
      (oldResult.blocked&&(oldResult.rank!==0n||oldResult.shortSelectorCalls!==0))||
      (!oldResult.blocked&&(oldResult.rank<1n||oldResult.rank>familySize||
        oldResult.shortSelectorCalls!==1)))
      throw new MonsterStageError("जुन्या short-only निरीक्षणात अनपेक्षित बदल");
    const result=Object.freeze({
      queriedBowlId:queriedId,seal,familySize,
      firstAnswer:preceding.firstAnswer,directionStep:preceding.directionStep,
      legacyShortOnlyRank:oldResult.rank,blockedWideSelection:oldResult.blocked,
      correctedPredecessorRank:preceding.correctedRank,
      historicalMismatch:oldResult.rank!==preceding.correctedRank,
      legacyShortOnlyCalls:1 as const,predecessorSharedMemoryWrites:58 as const,
      oldResult,preceding,context:ctx
    });

    ctx.branchTrace.push("DISCOVERY_14_REAL_PATCH13_58_WRITE_CHAIN");
    ctx.branchTrace.push("DISCOVERY_14_REAL_LEGACY_SHORT_ONLY_CALL");
    ctx.branchTrace.push(oldResult.blocked?
      "DISCOVERY_14_WIDE_N_GT_M_BLOCKED_ZERO":"DISCOVERY_14_SHORT_N_LE_M_PRESERVED");
    this.metrics.bump(ctx,"discovery14.calls");
    this.metrics.bump(ctx,"discovery14.legacy_short_only_calls");
    this.metrics.bump(ctx,"discovery14.preceding_58_write_sequences");
    if(oldResult.blocked)this.metrics.bump(ctx,"discovery14.wide_blocked");
    else this.metrics.bump(ctx,"discovery14.short_successes");
    if(result.historicalMismatch)this.metrics.bump(ctx,"discovery14.historical_mismatches");
    ctx.status="DISCOVERY_14_RECORDED";
    return result;
  }
}

export function discoverLegacyShortOnlyWide(c:bigint,t:bigint,
  visible:readonly bigint[],stones:readonly (readonly bigint[])[],
  startBowls:readonly bigint[],queriedId:number,seal:bigint,
  familySize:bigint):Discovery14ShortOnlyObservation {
  return new Discovery14ShortOnlyWideHandler().run(
    bootstrapMonster(c,t),visible,stones,startBowls,queriedId,seal,familySize);
}
