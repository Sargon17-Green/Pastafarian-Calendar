import {
 BaseMetricsManager, bootstrapMonster, MonsterStageError, MonsterValidationError
} from "./monsterBase.ts";
import type {MonsterContext} from "./monsterBase.ts";
import {Patch26FullHandler, patch26MonthEnd} from "./patch26MonthEnd.ts";
import type {Patch26FullObservation} from "./patch26MonthEnd.ts";
import type {Patch20StructureRequest} from "./patch20StructureSauce.ts";

// DISCOVERY27 deliberately probes a synthetic contiguous-span legacy hypothesis.
// No direct-membership oracle or date correction is used in this implementation.
export type LegacySpanMembershipResult=Readonly<{
 monthId:number; probeYearDay:number; firstYearDay:number|null;
 lastYearDay:number|null; guessedMonthMembership:boolean;
 historicalAlgorithm:"oldContiguousMonthMembershipGuess";
 actualDirectMembershipOracleApplied:false;
}>;
export class LegacyMonthSpanMembershipGuess{
 guess(weaving:readonly number[],monthId:number,probeYearDay:number):LegacySpanMembershipResult{
  if(!Array.isArray(weaving)||weaving.length<1||weaving.length>5778||
     weaving.some(v=>!Number.isSafeInteger(v)||v<1||v>47)||
     !Number.isSafeInteger(monthId)||monthId<1||monthId>47||
     !Number.isSafeInteger(probeYearDay)||probeYearDay<1||probeYearDay>weaving.length)
   throw new MonsterValidationError("वैध महिना-विणकाम, महिना आणि वर्षदिवस आवश्यक");
  const first=weaving.indexOf(monthId),last=weaving.lastIndexOf(monthId);
  return Object.freeze({
   monthId,probeYearDay,firstYearDay:first<0?null:first+1,
   lastYearDay:last<0?null:last+1,
   guessedMonthMembership:first>=0&&probeYearDay>=first+1&&probeYearDay<=last+1,
   historicalAlgorithm:"oldContiguousMonthMembershipGuess" as const,
   actualDirectMembershipOracleApplied:false as const
  });
 }
}
export type Discovery27FullObservation=Readonly<{
 historical:Patch26FullObservation;
 guessed:LegacySpanMembershipResult;
 actualPredecessorCalls:number;
 actualSharedWrites:bigint;
 additionalNativeQueries:0;
 context:MonsterContext;
 source:"FULL_STAGE53_DISCOVERY27_LEGACY_SPAN_DIAGNOSTIC";
}>;
export class Discovery27FullHandler{
 readonly preceding:Patch26FullHandler;
 private readonly guesser:LegacyMonthSpanMembershipGuess;
 private readonly metrics=new BaseMetricsManager();
 constructor(preceding:Patch26FullHandler,
  guesser:LegacyMonthSpanMembershipGuess=new LegacyMonthSpanMembershipGuess()){
  this.preceding=preceding;this.guesser=guesser;
 }
 run(ctx:MonsterContext,q:Patch20StructureRequest,
  monthId:number,probeYearDay:number):Discovery27FullObservation{
  if(ctx.phase!=="READY"||ctx.status!=="VALIDATED"||
     !q?.historical?.yearQuestion||
     ctx.calculationDay!==q.historical.yearQuestion.calculationDay||
     ctx.targetDay!==q.historical.yearQuestion.targetDay)
   throw new MonsterStageError("DISCOVERY27 साठी स्वतंत्र READY owner आवश्यक");
  if(!Number.isSafeInteger(monthId)||monthId<1||monthId>47||
     !Number.isSafeInteger(probeYearDay)||probeYearDay<1||probeYearDay>5778)
   throw new MonsterValidationError("DISCOVERY27 चाचणी प्रश्न अवैध");
  // The entire Stage53 chain runs in a separate owner: exceptions leave ctx intact.
  const previous=patch26MonthEnd(this.preceding,q);
  if(previous.context.status!=="PATCH_26_APPLIED"||
     previous.historical.context.status!=="DISCOVERY_26_RECORDED"||
     previous.historical.historical.context.status!=="PATCH_25_APPLIED"||
     !previous.corrected.actualSuffixOccurrenceCorrectionApplied||
     previous.additionalNativeQueries!==0||
     previous.actualSharedWrites!==BigInt(previous.actualPredecessorCalls)*58n)
   throw new MonsterStageError("Stage53 ची पूर्ण ऐतिहासिक Native साखळी आवश्यक");
  const weaving=previous.historical.historical.historical.historical.corrected.legalWeaving;
  const guessed=this.guesser.guess(weaving,monthId,probeYearDay);
  const result=Object.freeze({
   historical:previous,guessed,
   actualPredecessorCalls:previous.actualPredecessorCalls,
   actualSharedWrites:previous.actualSharedWrites,
   additionalNativeQueries:0 as const,context:ctx,
   source:"FULL_STAGE53_DISCOVERY27_LEGACY_SPAN_DIAGNOSTIC" as const
  });
  ctx.branchTrace.push("DISCOVERY_27_FULL_STAGE53_PREDECESSOR_ACTUALLY_RUN");
  ctx.branchTrace.push("DISCOVERY_27_SYNTHETIC_SPAN_GUESS_ONLY");
  ctx.branchTrace.push("DISCOVERY_27_DIRECT_MEMBERSHIP_ORACLE_NOT_APPLIED");
  this.metrics.bump(ctx,"discovery27.calls");
  this.metrics.bump(ctx,"discovery27.synthetic_span_guesses");
  ctx.metrics.set("discovery27.additional_native_queries",0n);
  ctx.status="DISCOVERY_27_RECORDED";
  return result;
 }
}
export function discoverLegacyMonthSpan(
 handler:Discovery27FullHandler,q:Patch20StructureRequest,
 monthId:number,probeYearDay:number):Discovery27FullObservation{
 if(!(handler instanceof Discovery27FullHandler)||!q?.historical?.yearQuestion)
  throw new MonsterValidationError("DISCOVERY27 handler आणि प्रश्न आवश्यक");
 const year=q.historical.yearQuestion;
 return handler.run(bootstrapMonster(year.calculationDay,year.targetDay),
  q,monthId,probeYearDay);
}
