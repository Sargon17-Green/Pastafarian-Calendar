import {
 BaseMetricsManager,bootstrapMonster,MonsterStageError,MonsterValidationError
} from "./monsterBase.ts";
import type {MonsterContext} from "./monsterBase.ts";
import {Patch25FullHandler,patch25MonthDay} from "./patch25MonthDay.ts";
import type {Patch25FullObservation} from "./patch25MonthDay.ts";
import type {Patch20StructureRequest} from "./patch20StructureSauce.ts";

// DISCOVERY26: केवळ निदानासाठी मुद्दाम चुकीचा पुढचा-दिवस legacy अंदाज.
// हा production मधील आढळलेला दोष नाही; suffix oracle फक्त चाचण्यांत आहे.
export type LegacyNextDayMonthEndResult=Readonly<{
 monthId:number;
 targetYearDay:number;
 guessedLastMonthOccurrence:boolean;
 historicalAlgorithm:"oldNextDayMonthEndGuess";
 actualSuffixOracleApplied:false;
}>;
export class LegacyNextDayMonthEndGuess{
 guess(weaving:readonly number[],yearDay:number):LegacyNextDayMonthEndResult{
  if(!Array.isArray(weaving)||weaving.length<1||weaving.length>5778||
     !Number.isSafeInteger(yearDay)||yearDay<1||yearDay>weaving.length||
     weaving.some(v=>!Number.isSafeInteger(v)||v<1||v>47))
   throw new MonsterValidationError("वैध महिना-विणकाम आणि वर्षदिवस आवश्यक");
  const monthId=weaving[yearDay-1]!;
  // Intentional legacy bug: a future separated occurrence is not examined.
  const guessedLastMonthOccurrence=yearDay===weaving.length||
   weaving[yearDay]!==monthId;
  return Object.freeze({
   monthId,targetYearDay:yearDay,guessedLastMonthOccurrence,
   historicalAlgorithm:"oldNextDayMonthEndGuess" as const,
   actualSuffixOracleApplied:false as const
  });
 }
}
export type Discovery26FullObservation=Readonly<{
 historical:Patch25FullObservation;
 guessed:LegacyNextDayMonthEndResult;
 actualPredecessorCalls:number;
 actualSharedWrites:bigint;
 additionalNativeQueries:0;
 context:MonsterContext;
 source:"FULL_STAGE51_DISCOVERY26_LEGACY_MONTH_END_DIAGNOSTIC";
}>;
export class Discovery26FullHandler{
 readonly preceding:Patch25FullHandler;
 private readonly guesser:LegacyNextDayMonthEndGuess;
 private readonly metrics=new BaseMetricsManager();
 constructor(preceding:Patch25FullHandler,
  guesser:LegacyNextDayMonthEndGuess=new LegacyNextDayMonthEndGuess()){
  this.preceding=preceding;this.guesser=guesser;
 }
 run(ctx:MonsterContext,q:Patch20StructureRequest):Discovery26FullObservation{
  if(ctx.phase!=="READY"||ctx.status!=="VALIDATED"||
     !q?.historical?.yearQuestion||
     ctx.calculationDay!==q.historical.yearQuestion.calculationDay||
     ctx.targetDay!==q.historical.yearQuestion.targetDay)
   throw new MonsterStageError("DISCOVERY26 साठी स्वतंत्र READY owner आवश्यक");
  // Predecessor executes under its own owner; failures cannot mutate caller.
  const previous=patch25MonthDay(this.preceding,q);
  if(previous.context.status!=="PATCH_25_APPLIED"||
     previous.historical.context.status!=="DISCOVERY_25_RECORDED"||
     previous.historical.historical.context.status!=="PATCH_24_APPLIED"||
     !previous.corrected.actualPrefixOccurrenceCorrectionApplied||
     previous.additionalNativeQueries!==0||
     previous.actualSharedWrites!==BigInt(previous.actualPredecessorCalls)*58n)
   throw new MonsterStageError("Stage51 ची पूर्ण साखळी आवश्यक");
  const weaving=previous.historical.historical.corrected.legalWeaving;
  const guessed=this.guesser.guess(weaving,previous.corrected.targetYearDay);
  if(guessed.monthId!==previous.corrected.monthId)
   throw new MonsterStageError("Stage51 आणि legacy महिन्याची ओळख भिन्न");
  const out=Object.freeze({
   historical:previous,guessed,
   actualPredecessorCalls:previous.actualPredecessorCalls,
   actualSharedWrites:previous.actualSharedWrites,
   additionalNativeQueries:0 as const,context:ctx,
   source:"FULL_STAGE51_DISCOVERY26_LEGACY_MONTH_END_DIAGNOSTIC" as const
  });
  ctx.branchTrace.push("DISCOVERY_26_FULL_STAGE51_PREDECESSOR_ACTUALLY_RUN");
  ctx.branchTrace.push("DISCOVERY_26_OLD_NEXT_DAY_MONTH_END_GUESS_ONLY");
  ctx.branchTrace.push("DISCOVERY_26_SUFFIX_ORACLE_NOT_APPLIED");
  this.metrics.bump(ctx,"discovery26.calls");
  this.metrics.bump(ctx,"discovery26.legacy_month_end_guesses");
  ctx.metrics.set("discovery26.guessed_last_month_occurrence",
   guessed.guessedLastMonthOccurrence?1n:0n);
  ctx.metrics.set("discovery26.additional_native_queries",0n);
  ctx.status="DISCOVERY_26_RECORDED";
  return out;
 }
}
export function discoverLegacyMonthEnd(
 handler:Discovery26FullHandler,q:Patch20StructureRequest
):Discovery26FullObservation{
 if(!(handler instanceof Discovery26FullHandler)||!q?.historical?.yearQuestion)
  throw new MonsterValidationError("DISCOVERY26 handler आणि प्रश्न आवश्यक");
 const year=q.historical.yearQuestion;
 return handler.run(bootstrapMonster(year.calculationDay,year.targetDay),q);
}
