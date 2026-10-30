import {
 BaseMetricsManager,bootstrapMonster,MonsterStageError,MonsterValidationError
} from "./monsterBase.ts";
import type {MonsterContext} from "./monsterBase.ts";
import {
 Discovery26FullHandler,discoverLegacyMonthEnd
} from "./discovery26LegacyMonthEnd.ts";
import type {
 Discovery26FullObservation,LegacyNextDayMonthEndResult
} from "./discovery26LegacyMonthEnd.ts";
import type {Patch20StructureRequest} from "./patch20StructureSauce.ts";

// PATCH26: the final occurrence of the chosen month may not be adjacent.
// This is a derived predicate, not another canonical date component.
export type Patch26MonthEndResult=Readonly<{
 monthId:number;
 targetYearDay:number;
 correctedLastMonthOccurrence:boolean;
 historical:LegacyNextDayMonthEndResult;
 historicalEqualsCorrect:boolean;
 actualSuffixOccurrenceCorrectionApplied:true;
}>;
export class Patch26SuffixOccurrenceChecker{
 isLast(weaving:readonly number[],yearDay:number):boolean{
  if(!Array.isArray(weaving)||weaving.length<1||weaving.length>5778||
     !Number.isSafeInteger(yearDay)||yearDay<1||yearDay>weaving.length||
     weaving.some(v=>!Number.isSafeInteger(v)||v<1||v>47))
   throw new MonsterValidationError("वैध महिना-विणकाम आणि वर्षदिवस आवश्यक");
  const month=weaving[yearDay-1]!;
  for(let i=yearDay;i<weaving.length;i++)
   if(weaving[i]===month)return false;
  return true;
 }
 correct(weaving:readonly number[],old:LegacyNextDayMonthEndResult):Patch26MonthEndResult{
  if(!old||old.historicalAlgorithm!=="oldNextDayMonthEndGuess"||
     old.actualSuffixOracleApplied!==false||
     !Number.isSafeInteger(old.targetYearDay)||
     old.monthId!==weaving?.[old.targetYearDay-1])
   throw new MonsterValidationError("Stage52 ची खरी ऐतिहासिक निवड आवश्यक");
  const correctedLastMonthOccurrence=this.isLast(weaving,old.targetYearDay);
  if(!old.guessedLastMonthOccurrence&&correctedLastMonthOccurrence)
   throw new MonsterStageError("पुढचा दिवस त्याच महिन्याचा असताना अखेर अशक्य");
  return Object.freeze({
   monthId:old.monthId,targetYearDay:old.targetYearDay,
   correctedLastMonthOccurrence,historical:old,
   historicalEqualsCorrect:correctedLastMonthOccurrence===old.guessedLastMonthOccurrence,
   actualSuffixOccurrenceCorrectionApplied:true as const
  });
 }
}
export type Patch26FullObservation=Readonly<{
 historical:Discovery26FullObservation;
 corrected:Patch26MonthEndResult;
 actualPredecessorCalls:number;
 actualSharedWrites:bigint;
 additionalNativeQueries:0;
 context:MonsterContext;
 source:"FULL_STAGE52_PATCH26_SUFFIX_OCCURRENCES";
}>;
export class Patch26FullHandler{
 readonly preceding:Discovery26FullHandler;
 private readonly checker:Patch26SuffixOccurrenceChecker;
 private readonly metrics=new BaseMetricsManager();
 constructor(preceding:Discovery26FullHandler,
  checker:Patch26SuffixOccurrenceChecker=new Patch26SuffixOccurrenceChecker()){
  this.preceding=preceding;this.checker=checker;
 }
 run(ctx:MonsterContext,q:Patch20StructureRequest):Patch26FullObservation{
  if(ctx.phase!=="READY"||ctx.status!=="VALIDATED"||
     !q?.historical?.yearQuestion||
     ctx.calculationDay!==q.historical.yearQuestion.calculationDay||
     ctx.targetDay!==q.historical.yearQuestion.targetDay)
   throw new MonsterStageError("PATCH26 साठी स्वतंत्र READY owner आवश्यक");
  // Execute complete Stage52 history under its own owner; caller remains untouched on fault.
  const previous=discoverLegacyMonthEnd(this.preceding,q);
  if(previous.context.status!=="DISCOVERY_26_RECORDED"||
     previous.historical.context.status!=="PATCH_25_APPLIED"||
     previous.historical.historical.context.status!=="DISCOVERY_25_RECORDED"||
     !previous.historical.corrected.actualPrefixOccurrenceCorrectionApplied||
     previous.additionalNativeQueries!==0||
     previous.actualSharedWrites!==BigInt(previous.actualPredecessorCalls)*58n)
   throw new MonsterStageError("Stage52 पूर्ण native historical predecessor आवश्यक");
  const weaving=previous.historical.historical.historical.corrected.legalWeaving;
  const corrected=this.checker.correct(weaving,previous.guessed);
  const out=Object.freeze({
   historical:previous,corrected,
   actualPredecessorCalls:previous.actualPredecessorCalls,
   actualSharedWrites:previous.actualSharedWrites,
   additionalNativeQueries:0 as const,context:ctx,
   source:"FULL_STAGE52_PATCH26_SUFFIX_OCCURRENCES" as const
  });
  ctx.branchTrace.push("PATCH_26_ACTUAL_FULL_STAGE52_HISTORICAL_GUESS");
  ctx.branchTrace.push("PATCH_26_CHECK_TRUE_MONTH_SUFFIX_OCCURRENCES");
  ctx.branchTrace.push(corrected.historicalEqualsCorrect?
   "PATCH_26_REUSE_ONLY_EQUAL_OLD_FLAG":"PATCH_26_REPLACE_WRONG_OLD_FLAG");
  this.metrics.bump(ctx,"patch26.calls");
  this.metrics.bump(ctx,corrected.historicalEqualsCorrect?
   "patch26.equal_legacy":"patch26.corrected_legacy");
  ctx.metrics.set("patch26.corrected_month_end",
   corrected.correctedLastMonthOccurrence?1n:0n);
  ctx.metrics.set("patch26.additional_native_queries",0n);
  ctx.status="PATCH_26_APPLIED";
  return out;
 }
}
export function patch26MonthEnd(handler:Patch26FullHandler,
 q:Patch20StructureRequest):Patch26FullObservation{
 if(!(handler instanceof Patch26FullHandler)||!q?.historical?.yearQuestion)
  throw new MonsterValidationError("PATCH26 handler आणि प्रश्न आवश्यक");
 const year=q.historical.yearQuestion;
 return handler.run(bootstrapMonster(year.calculationDay,year.targetDay),q);
}
