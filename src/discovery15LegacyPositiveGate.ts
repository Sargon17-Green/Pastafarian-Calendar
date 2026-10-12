import {
  BaseMetricsManager,bootstrapMonster,MonsterStageError,MonsterValidationError
} from "./monsterBase.ts";
import type { MonsterContext } from "./monsterBase.ts";
import { patch14WideChoice } from "./patch14WideChoice.ts";
import type { Patch14WideChoiceObservation } from "./patch14WideChoice.ts";

// DISCOVERY 15: जुना gate प्रश्न दोन्ही बाजूंना FOUNDATION+abs(n) विचारतो.
// नियमाधारित ऋण बाजू FOUNDATION-n असते; तिची दुरुस्ती Stage31 मध्येच.
// Production मधील आधीचा PATCH14 मार्ग प्रत्यक्ष चालवला जातो.
export const DISCOVERY15_FOUNDATION_DAY=-15055671n;
export type Discovery15GateQuestion=Readonly<{
  visible:readonly bigint[];
  stones:readonly (readonly bigint[])[];
  startBowls:readonly bigint[];
}>;
export type Discovery15GateGap=Readonly<{
  gateIndex:bigint;
  askedTargetDay:bigint;
  normativeTargetDay:bigint;
  historicalGap:bigint;
  historicalRank:bigint;
  preceding:Patch14WideChoiceObservation;
  predecessorWrites:58;
}>;
export type Discovery15GateObservation=Readonly<{
  gateIndex:bigint;
  historicalGateDay:bigint;
  questionCount:number;
  negativeWrongSideQuestions:number;
  askedPositiveSideForNegative:boolean;
  gaps:readonly Discovery15GateGap[];
  actualPredecessorCalls:number;
  predecessorSharedWrites:bigint;
  context:MonsterContext;
}>;

// Explicit historical method (retain unchanged when implementing Stage31).
// This calculates only the *queried day*, never a corrected day.
export class LegacyPositiveOnlyGateQuestionAdapter {
  oldQuestionDay(step:bigint):bigint {
    if(typeof step!=="bigint"||step===0n)
      throw new MonsterValidationError("शून्य नसलेला पूर्णांक gate index आवश्यक");
    return DISCOVERY15_FOUNDATION_DAY+(step<0n?-step:step);
  }
}

export class Discovery15PositiveSideGateHandler {
  private readonly old=new LegacyPositiveOnlyGateQuestionAdapter();
  private readonly metrics=new BaseMetricsManager();

  run(ctx:MonsterContext,gateIndex:bigint,
      questions:readonly Discovery15GateQuestion[]):Discovery15GateObservation {
    if(ctx.phase!=="READY"||ctx.status!=="VALIDATED")
      throw new MonsterStageError("DISCOVERY15 पूर्वी READY/VALIDATED state आवश्यक");
    if(typeof ctx.calculationDay!=="bigint"||
       ctx.calculationDay!==DISCOVERY15_FOUNDATION_DAY||
       typeof gateIndex!=="bigint"||gateIndex===0n||
       typeof ctx.targetDay!=="bigint"||
       ctx.targetDay!==DISCOVERY15_FOUNDATION_DAY+gateIndex||
       !Array.isArray(questions)||
       BigInt(questions.length)!==(gateIndex<0n?-gateIndex:gateIndex))
      throw new MonsterValidationError("Foundation, signed gate index आणि पूर्ण प्रश्न-मालिका आवश्यक");

    // Preflight validates *every* query before running any predecessor,
    // preventing partial work when any later query is malformed.
    for(const q of questions){
      if(typeof q!=="object"||q===null||
         !Array.isArray(q.visible)||q.visible.length!==47||
         Array.from({length:46},(_,i)=>typeof q.visible[i+1]!=="bigint").some(Boolean)||
         !Array.isArray(q.stones)||q.stones.length!==47||
         Array.from({length:46},(_,i)=>q.stones[i+1]).some(row=>
           !Array.isArray(row)||row.length!==5||
           Array.from({length:5},(_,j)=>typeof row[j]!=="bigint").some(Boolean))||
         !Array.isArray(q.startBowls)||q.startBowls.length!==6||
         q.startBowls.some((x:unknown)=>typeof x!=="bigint"))
        throw new MonsterValidationError("प्रत्येक gate प्रश्नासाठी 46 drops/stones आणि सहा वाट्या आवश्यक");
    }

    const outputs:Discovery15GateGap[]=[];
    let sum=0n;
    const negative=gateIndex<0n;
    for(let j=1;j<=questions.length;j++){
      const magnitude=BigInt(j);
      const signed=negative?-magnitude:magnitude;
      const actualTarget=this.old.oldQuestionDay(signed); // actual historic call
      const normativeTarget=DISCOVERY15_FOUNDATION_DAY+signed;
      if(actualTarget!==DISCOVERY15_FOUNDATION_DAY+magnitude)
        throw new MonsterStageError("जुना प्रश्न positive side वापरला नाही");
      const q=questions[j-1]!;
      const preceding=patch14WideChoice(DISCOVERY15_FOUNDATION_DAY,actualTarget,
        q.visible,q.stones,q.startBowls,1,1n,922n);
      if(preceding.predecessorSharedWrites!==58||
         preceding.realLegacyCalls!==1||preceding.extraWideCalls!==0||
         preceding.selectionMode!=="SHORT_LEGACY"||
         preceding.preceding.preceding.preceding.legacyModuloCalls!==1||
         preceding.preceding.preceding.preceding.preceding.preceding.latchCaptures!==1||
         preceding.preceding.preceding.preceding.preceding.preceding.preceding.historical.latestSource!=="STIR_12")
        throw new MonsterStageError("Stage29 ची पूर्ण 58-write chain आवश्यक");
      const rank=preceding.correctedRank;
      if(rank<1n||rank>922n)
        throw new MonsterStageError("gate gap निवडीचा नियमबाह्य rank");
      const gap=41n+rank;
      if(gap<42n||gap>963n)throw new MonsterStageError("gate gap 42..963 अपेक्षित");
      sum+=gap;
      outputs.push(Object.freeze({
        gateIndex:signed,askedTargetDay:actualTarget,normativeTargetDay:normativeTarget,
        historicalGap:gap,historicalRank:rank,preceding,predecessorWrites:58 as const
      }));
    }
    const historicalGateDay=negative?
      DISCOVERY15_FOUNDATION_DAY-sum:DISCOVERY15_FOUNDATION_DAY+sum;
    const result=Object.freeze({
      gateIndex,historicalGateDay,questionCount:questions.length,
      negativeWrongSideQuestions:negative?questions.length:0,
      askedPositiveSideForNegative:negative,
      gaps:Object.freeze(outputs),
      actualPredecessorCalls:questions.length,
      predecessorSharedWrites:BigInt(questions.length)*58n,context:ctx
    });

    ctx.branchTrace.push("DISCOVERY_15_FULL_PATCH14_GATE_GAP_CHAIN");
    ctx.branchTrace.push("DISCOVERY_15_LEGACY_FOUNDATION_PLUS_ABS");
    ctx.branchTrace.push(negative?
      "DISCOVERY_15_NEGATIVE_GATE_ASKS_WRONG_POSITIVE_SIDE":
      "DISCOVERY_15_POSITIVE_GATE_ASKS_CORRECT_SIDE");
    this.metrics.bump(ctx,"discovery15.calls");
    this.metrics.bump(ctx,"discovery15.actual_legacy_question_sequences");
    ctx.metrics.set("discovery15.actual_legacy_method_calls",BigInt(questions.length));
    ctx.metrics.set("discovery15.predecessor_58_write_total",BigInt(questions.length)*58n);
    if(negative)ctx.metrics.set("discovery15.negative_wrong_side_questions",
      BigInt(questions.length));
    ctx.status="DISCOVERY_15_RECORDED";
    return result;
  }
}
export function discoverLegacyPositiveGate(gateIndex:bigint,
  questions:readonly Discovery15GateQuestion[]):Discovery15GateObservation {
  return new Discovery15PositiveSideGateHandler().run(
    bootstrapMonster(DISCOVERY15_FOUNDATION_DAY,
      DISCOVERY15_FOUNDATION_DAY+gateIndex),gateIndex,questions);
}
