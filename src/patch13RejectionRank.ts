import {
  BaseMetricsManager, bootstrapMonster, MonsterStageError, MonsterValidationError
} from "./monsterBase.ts";
import type { MonsterContext } from "./monsterBase.ts";
import { LEGACY_MODULUS } from "./discovery01LegacyRemainder.ts";
import { discoverLegacyBiasedModulo } from "./discovery13LegacyBiasedModulo.ts";
import type { Discovery13BiasedModuloObservation } from "./discovery13LegacyBiasedModulo.ts";

// PATCH 13: M=2^127-1. The original biased selector remains in Discovery13.
// A rejection scan advances by +1 or -1 on a finite cyclic interval.
// The first acceptable candidate can therefore be computed EXACTLY,
// without enumerating up to M rejected answers.
export type Patch13AnswerStream=Readonly<{ first:bigint; directionStep:1n|-1n }>;
export type Patch13RankSelection=Readonly<{
  rank:bigint;
  mode:"SHORT"|"WIDE";
  familySize:bigint;
  sampleSpace:bigint;
  acceptanceLimit:bigint;
  firstCandidate:bigint;
  acceptedCandidate:bigint;
  rejectedCandidates:bigint;
  digitCount:number;
  answerDigits:readonly bigint[];
  directionStep:1n|-1n;
}>;

export class Patch13RejectionRankAdapter {
  private readonly M=LEGACY_MODULUS;

  private answerAt(stream:Patch13AnswerStream,k:bigint):bigint {
    const raw=(stream.first-1n+stream.directionStep*k)%this.M;
    return 1n+(raw<0n?raw+this.M:raw);
  }

  choose(stream:Patch13AnswerStream,N:bigint):Patch13RankSelection {
    if(typeof stream!=="object"||stream===null||
       typeof stream.first!=="bigint"||stream.first<1n||stream.first>this.M||
       (stream.directionStep!==1n&&stream.directionStep!==-1n)||
       typeof N!=="bigint"||N<1n)
      throw new MonsterValidationError("वैध उत्तरप्रवाह (1..M; दिशा ±1) आणि N>=1 आवश्यक");

    let space=this.M;
    let digits=1;
    const isWide=N>this.M;
    if(isWide){
      while(space<N){
        space*=this.M;
        digits++;
      }
    }

    // One-based, little-endian M-adic digits are consecutive real answers.
    const answers:bigint[]=[];
    let firstCandidate=1n,weight=1n;
    for(let j=0;j<digits;j++){
      const answer=this.answerAt(stream,BigInt(j));
      answers.push(answer);
      firstCandidate+=(answer-1n)*weight;
      weight*=this.M;
    }
    const limit=(space/N)*N;
    let accepted=firstCandidate;
    let rejected=0n;
    if(firstCandidate>limit){
      if(stream.directionStep===-1n){
        // Descend to the acceptance boundary; every intervening element
        // is >limit and hence rejected.
        accepted=limit;
        rejected=firstCandidate-limit;
      }else{
        // Ascend through space and wrap to the first accepted element.
        accepted=1n;
        rejected=space-firstCandidate+1n;
      }
    }
    const rank=1n+((accepted-1n)%N);
    if(accepted<1n||accepted>limit||rank<1n||rank>N)
      throw new MonsterStageError("नियमाधारित rejection rank अवैध");
    return Object.freeze({
      rank,mode:isWide?"WIDE" as const:"SHORT" as const,familySize:N,
      sampleSpace:space,acceptanceLimit:limit,firstCandidate,
      acceptedCandidate:accepted,rejectedCandidates:rejected,
      digitCount:digits,answerDigits:Object.freeze(answers),directionStep:stream.directionStep
    });
  }
}

export type Patch13RankObservation=Readonly<{
  queriedBowlId:number;
  seal:bigint;
  familySize:bigint;
  firstAnswer:bigint;
  directionStep:1n|-1n;
  legacyBiasedRank:bigint;
  correctedRank:bigint;
  historicalMismatch:boolean;
  selection:Patch13RankSelection;
  preceding:Discovery13BiasedModuloObservation;
  legacySelectorCalls:1;
  correctedSelectorCalls:1;
  predecessorSharedMemoryWrites:58;
  context:MonsterContext;
}>;

export class Patch13RejectionRankHandler {
  private readonly corrected=new Patch13RejectionRankAdapter();
  private readonly metrics=new BaseMetricsManager();

  run(ctx:MonsterContext,visible:readonly bigint[],
      stones:readonly (readonly bigint[])[],startBowls:readonly bigint[],
      queriedId:number,seal:bigint,familySize:bigint):Patch13RankObservation {
    if(ctx.phase!=="READY"||ctx.status!=="VALIDATED")
      throw new MonsterStageError("PATCH13 पूर्वी READY आणि VALIDATED context आवश्यक");
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
      throw new MonsterValidationError("46 drops, 46 stones, सहा bowls, ID, seal व सकारात्मक N हवेत");

    // Actual Stage26 production executes all Stage25 shared writes and
    // ACTUALLY calls the historical oldChooseModulo once on a child context.
    const preceding=discoverLegacyBiasedModulo(ctx.calculationDay,ctx.targetDay,
      visible,stones,startBowls,queriedId,seal,familySize);
    if(preceding.predecessorSharedMemoryWrites!==58||
       preceding.legacyModuloCalls!==1||
       preceding.preceding.latchCaptures!==1||
       preceding.preceding.preceding.historical.latestSource!=="STIR_12"||
       preceding.answerStream.first!==preceding.firstAnswer||
       preceding.answerStream.directionStep!==preceding.directionStep)
      throw new MonsterStageError("मागील 58 writes आणि जुना modulo call आवश्यक");
    const selection=this.corrected.choose(preceding.answerStream,familySize);
    const result=Object.freeze({
      queriedBowlId:queriedId,seal,familySize,
      firstAnswer:preceding.firstAnswer,directionStep:preceding.directionStep,
      legacyBiasedRank:preceding.biasedRank,correctedRank:selection.rank,
      historicalMismatch:preceding.biasedRank!==selection.rank,
      selection,preceding,legacySelectorCalls:1 as const,
      correctedSelectorCalls:1 as const,
      predecessorSharedMemoryWrites:58 as const,context:ctx
    });
    // A failed legacy/selector call leaves the outer context and arrays intact.
    ctx.branchTrace.push("PATCH_13_REAL_DISCOVERY13_LEGACY_SELECTOR_AND_58_WRITES");
    ctx.branchTrace.push("PATCH_13_REJECTION_ON_CANONICAL_STREAM");
    ctx.branchTrace.push(selection.mode==="WIDE"?
      "PATCH_13_MULTI_DIGIT_WIDE_RANK":"PATCH_13_SHORT_RANK");
    this.metrics.bump(ctx,"patch13.calls");
    this.metrics.bump(ctx,"patch13.legacy_selector_calls");
    this.metrics.bump(ctx,"patch13.corrected_selector_calls");
    this.metrics.bump(ctx,"patch13.predecessor_58_write_sequences");
    if(result.historicalMismatch)this.metrics.bump(ctx,"patch13.historical_mismatches");
    ctx.status="PATCH_13_APPLIED";
    return result;
  }
}

export function patch13RejectionRank(c:bigint,t:bigint,visible:readonly bigint[],
  stones:readonly (readonly bigint[])[],startBowls:readonly bigint[],
  queriedId:number,seal:bigint,familySize:bigint):Patch13RankObservation {
  return new Patch13RejectionRankHandler().run(
    bootstrapMonster(c,t),visible,stones,startBowls,queriedId,seal,familySize);
}
