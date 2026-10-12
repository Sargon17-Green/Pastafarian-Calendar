import {
  BaseMetricsManager,bootstrapMonster,MonsterStageError,MonsterValidationError
} from "./monsterBase.ts";
import type {MonsterContext} from "./monsterBase.ts";
import {
  DISCOVERY15_FOUNDATION_DAY,discoverLegacyPositiveGate
} from "./discovery15LegacyPositiveGate.ts";
import type {
  Discovery15GateObservation,Discovery15GateQuestion
} from "./discovery15LegacyPositiveGate.ts";
import {patch14WideChoice} from "./patch14WideChoice.ts";
import type {Patch14WideChoiceObservation} from "./patch14WideChoice.ts";

// PATCH 15: ऋण gate साठी F-n ची खरी Sauce चौकशी. Stage30 चा
// FOUNDATION+abs(n) जुना प्रश्न अपरिवर्तित आणि प्रत्यक्ष चालू ठेवावा.
export type Patch15SignedQuestion=Discovery15GateQuestion&Readonly<{
  targetDay:bigint;
}>;

export class Patch15SignedGateQuestionAdapter {
  correctedQuestionDay(signedStep:bigint):bigint {
    if(typeof signedStep!=="bigint"||signedStep===0n)
      throw new MonsterValidationError("शून्य नसलेला signed gate step अपेक्षित");
    return DISCOVERY15_FOUNDATION_DAY+signedStep;
  }
}
export type Patch15GateGap=Readonly<{
  signedIndex:bigint;
  askedTargetDay:bigint;
  historicalAskedTargetDay:bigint;
  correctedGap:bigint;
  historicalGap:bigint;
  correctedRank:bigint;
  correctedPredecessor:Patch14WideChoiceObservation;
  reusedPositiveHistorical:boolean;
  actualCorrectedPredecessorCalls:1;
  addedNegativeSideCalls:0|1;
  sharedWritesForCorrected:58;
}>;
export type Patch15SignedGateObservation=Readonly<{
  gateIndex:bigint;
  correctedGateDay:bigint;
  historicalGateDay:bigint;
  historicalMismatch:boolean;
  signedQuestionCalls:number;
  historicalWrongSideQuestions:number;
  extraNegativePredecessorCalls:number;
  totalPredecessorCalls:number;
  totalSharedWrites:bigint;
  gaps:readonly Patch15GateGap[];
  preceding:Discovery15GateObservation;
  context:MonsterContext;
}>;

export class Patch15SignedGateHandler {
  private readonly corrected=new Patch15SignedGateQuestionAdapter();
  private readonly metrics=new BaseMetricsManager();

  run(ctx:MonsterContext,index:bigint,
    historicalPositive:readonly Discovery15GateQuestion[],
    correctSigned:readonly Patch15SignedQuestion[]
  ):Patch15SignedGateObservation {
    if(ctx.phase!=="READY"||ctx.status!=="VALIDATED")
      throw new MonsterStageError("PATCH15 पूर्वी READY आणि VALIDATED context आवश्यक");
    if(typeof index!=="bigint"||index===0n||
       ctx.calculationDay!==DISCOVERY15_FOUNDATION_DAY||
       ctx.targetDay!==DISCOVERY15_FOUNDATION_DAY+index||
       !Array.isArray(historicalPositive)||!Array.isArray(correctSigned)||
       BigInt(historicalPositive.length)!==(index<0n?-index:index)||
       historicalPositive.length!==correctSigned.length)
      throw new MonsterValidationError("signed gate index व historical/correct प्रश्न-जोड्या हव्यात");
    const negative=index<0n;
    // Validate every later query BEFORE any real predecessor calls:
    // if question 2 is damaged, do not mutate the outer semantic state.
    for(let i=0;i<correctSigned.length;i++){
      const q:Patch15SignedQuestion=correctSigned[i]!;
      const step=negative?-BigInt(i+1):BigInt(i+1);
      if(!q||typeof q!=="object"||
         typeof q.targetDay!=="bigint"||
         q.targetDay!==DISCOVERY15_FOUNDATION_DAY+step||
         !Array.isArray(q.visible)||q.visible.length!==47||
         Array.from({length:46},(_,j)=>typeof q.visible[j+1]!=="bigint").some(Boolean)||
         !Array.isArray(q.stones)||q.stones.length!==47||
         Array.from({length:46},(_,j)=>q.stones[j+1]).some(row=>
          !Array.isArray(row)||row.length!==5||
          Array.from({length:5},(_,k)=>typeof row[k]!=="bigint").some(Boolean))||
         !Array.isArray(q.startBowls)||q.startBowls.length!==6||
         q.startBowls.some(v=>typeof v!=="bigint"))
        throw new MonsterValidationError("प्रत्येक योग्य signed दिवसाची खरी 46/12 स्रोत-सामग्री आवश्यक");
    }

    // This REALLY calls Stage30's old F+abs(n) method and the entire
    // Stage29 predecessor pipeline for every original historical question.
    const preceding=discoverLegacyPositiveGate(index,historicalPositive);
    if(preceding.gateIndex!==index||preceding.gaps.length!==correctSigned.length||
       preceding.actualPredecessorCalls!==correctSigned.length||
       preceding.predecessorSharedWrites!==BigInt(correctSigned.length)*58n)
      throw new MonsterStageError("पूर्ण जुनी gate साखळी चालली नाही");

    let correctedSum=0n;
    let extra=0;
    const ledger:Patch15GateGap[]=[];
    for(let i=0;i<correctSigned.length;i++){
      const step=negative?-BigInt(i+1):BigInt(i+1);
      const wanted=this.corrected.correctedQuestionDay(step); // true method call
      const q=correctSigned[i]!;
      const old=preceding.gaps[i]!;
      if(q.targetDay!==wanted||
         old.askedTargetDay!==DISCOVERY15_FOUNDATION_DAY+BigInt(i+1)||
         old.normativeTargetDay!==wanted)
        throw new MonsterStageError("signed day आणि जुना day provenance विसंगत");
      let correctedPredecessor:Patch14WideChoiceObservation;
      if(negative){
        // Crucially: physically execute Sauce(F,F-n), not simply flip
        // the sign of the old positive gap or use an oracle value.
        correctedPredecessor=patch14WideChoice(
          DISCOVERY15_FOUNDATION_DAY,wanted,q.visible,q.stones,
          q.startBowls,1,1n,922n);
        extra++;
      }else{
        // Historical method is already correct for positive gate indices;
        // reuse the exact real Stage29 result (and its 58 actual writes).
        correctedPredecessor=old.preceding;
      }
      if(correctedPredecessor.predecessorSharedWrites!==58||
         correctedPredecessor.realLegacyCalls!==1||
         correctedPredecessor.selectionMode!=="SHORT_LEGACY"||
         correctedPredecessor.extraWideCalls!==0||
         correctedPredecessor.correctedRank<1n||
         correctedPredecessor.correctedRank>922n)
        throw new MonsterStageError("नियमाधारित gate gap आणि 58-write predecessor अयोग्य");
      const rank=correctedPredecessor.correctedRank;
      const gap=41n+rank;
      if(gap<42n||gap>963n)
        throw new MonsterStageError("gate gap 42..963 बाहेर आहे");
      correctedSum+=gap;
      ledger.push(Object.freeze({
        signedIndex:step,askedTargetDay:wanted,
        historicalAskedTargetDay:old.askedTargetDay,
        correctedGap:gap,historicalGap:old.historicalGap,
        correctedRank:rank,correctedPredecessor,
        reusedPositiveHistorical:!negative,
        actualCorrectedPredecessorCalls:1 as const,
        addedNegativeSideCalls:negative?1 as const:0 as const,
        sharedWritesForCorrected:58 as const
      }));
    }
    const correctedGateDay=DISCOVERY15_FOUNDATION_DAY+
      (negative?-correctedSum:correctedSum);
    const historicalGateDay=preceding.historicalGateDay;
    const out=Object.freeze({
      gateIndex:index,correctedGateDay,historicalGateDay,
      historicalMismatch:correctedGateDay!==historicalGateDay,
      signedQuestionCalls:correctSigned.length,
      historicalWrongSideQuestions:preceding.negativeWrongSideQuestions,
      extraNegativePredecessorCalls:extra,
      totalPredecessorCalls:preceding.actualPredecessorCalls+extra,
      totalSharedWrites:BigInt(preceding.actualPredecessorCalls+extra)*58n,
      gaps:Object.freeze(ledger),preceding,context:ctx
    });
    // Transactional outer owner: child calls may fail without a partial
    // commit, so same-context retry is deterministic and safe.
    ctx.branchTrace.push("PATCH_15_REAL_DISCOVERY15_LEGACY_GATE_PATH");
    ctx.branchTrace.push(negative?
      "PATCH_15_ACTUAL_NEGATIVE_SIDE_SAUCE":"PATCH_15_REUSE_POSITIVE_SIDE_SAUCE");
    ctx.branchTrace.push("PATCH_15_CORRECT_GATE_DAY_COMMITTED");
    this.metrics.bump(ctx,"patch15.calls");
    ctx.metrics.set("patch15.real_historical_gate_queries",
      BigInt(preceding.actualPredecessorCalls));
    ctx.metrics.set("patch15.corrected_signed_queries",BigInt(correctSigned.length));
    ctx.metrics.set("patch15.additional_negative_sauce_calls",BigInt(extra));
    ctx.metrics.set("patch15.total_predecessor_58_write_sequences",
      BigInt(preceding.actualPredecessorCalls+extra));
    if(out.historicalMismatch)this.metrics.bump(ctx,"patch15.historical_gate_mismatches");
    ctx.status="PATCH_15_APPLIED";
    return out;
  }
}
export function patch15SignedGate(index:bigint,
  historicalPositive:readonly Discovery15GateQuestion[],
  correctSigned:readonly Patch15SignedQuestion[]
):Patch15SignedGateObservation {
  return new Patch15SignedGateHandler().run(
    bootstrapMonster(DISCOVERY15_FOUNDATION_DAY,
      DISCOVERY15_FOUNDATION_DAY+index),index,historicalPositive,correctSigned);
}
