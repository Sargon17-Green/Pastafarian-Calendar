import {
 BaseMetricsManager,bootstrapMonster,MonsterStageError,MonsterValidationError
} from "./monsterBase.ts";
import type {MonsterContext} from "./monsterBase.ts";
import {
 Discovery25FullHandler,discoverLegacyContiguousMonthDay
} from "./discovery25LegacyContiguousMonthDay.ts";
import type {
 Discovery25FullObservation,OldContiguousMonthDayResult
} from "./discovery25LegacyContiguousMonthDay.ts";
import type {Patch20StructureRequest} from "./patch20StructureSauce.ts";

// PATCH25: मोजलेल्या महिन्याचे वर्षाच्या पहिल्या दिवसापासून
// लक्ष्य दिवसापर्यंतचे वास्तविक occurrences. जुन्या सलग-span तर्काला स्पर्श नाही.
export type Patch25MonthDayResult=Readonly<{
 monthId:number;
 targetYearDay:number;
 correctedDayInMonth:number;
 historical:OldContiguousMonthDayResult;
 historicalEqualsCorrect:boolean;
 actualPrefixOccurrenceCorrectionApplied:true;
}>;
export class Patch25PrefixOccurrenceCounter{
 count(weaving:readonly number[],yearDay:number):number{
  if(!Array.isArray(weaving)||weaving.length<1||weaving.length>5778||
     !Number.isSafeInteger(yearDay)||yearDay<1||yearDay>weaving.length||
     weaving.some(v=>!Number.isSafeInteger(v)||v<1||v>47))
   throw new MonsterValidationError("वैध वर्षातील महिना-विणकाम आणि दिवस आवश्यक");
  const month=weaving[yearDay-1]!;
  let occurrences=0;
  for(let i=0;i<yearDay;i++)if(weaving[i]===month)occurrences++;
  if(occurrences<1)throw new MonsterStageError("लक्ष्य महिन्याचा दिवस सापडला नाही");
  return occurrences;
 }
 correct(weaving:readonly number[],old:OldContiguousMonthDayResult):Patch25MonthDayResult{
  if(!old||old.historicalAlgorithm!=="oldContiguousMonthDayGuess"||
     old.actualPrefixOccurrenceCorrectionApplied!==false||
     old.monthId!==weaving?.[old.targetYearDay-1])
   throw new MonsterValidationError("Stage50 ची खरी ऐतिहासिक निवड आवश्यक");
  const correctedDayInMonth=this.count(weaving,old.targetYearDay);
  if(correctedDayInMonth>old.guessedDayInMonth||
     old.guessedDayInMonth<1||old.guessedDayInMonth>weaving.length)
   throw new MonsterStageError("जुन्या span पेक्षा occurrences जास्त असू शकत नाहीत");
  return Object.freeze({
   monthId:old.monthId,targetYearDay:old.targetYearDay,
   correctedDayInMonth,historical:old,
   historicalEqualsCorrect:correctedDayInMonth===old.guessedDayInMonth,
   actualPrefixOccurrenceCorrectionApplied:true as const
  });
 }
}
export type Patch25FullObservation=Readonly<{
 historical:Discovery25FullObservation;
 corrected:Patch25MonthDayResult;
 actualPredecessorCalls:number;
 actualSharedWrites:bigint;
 additionalNativeQueries:0;
 context:MonsterContext;
 source:"FULL_STAGE50_PATCH25_PREFIX_OCCURRENCES";
}>;
export class Patch25FullHandler{
 readonly preceding:Discovery25FullHandler;
 private readonly counter:Patch25PrefixOccurrenceCounter;
 private readonly metrics=new BaseMetricsManager();
 constructor(preceding:Discovery25FullHandler,
  counter:Patch25PrefixOccurrenceCounter=new Patch25PrefixOccurrenceCounter()){
  this.preceding=preceding;this.counter=counter;
 }
 run(ctx:MonsterContext,q:Patch20StructureRequest):Patch25FullObservation{
  if(ctx.phase!=="READY"||ctx.status!=="VALIDATED"||
     !q?.historical?.yearQuestion||
     q.historical.yearQuestion.calculationDay!==ctx.calculationDay||
     q.historical.yearQuestion.targetDay!==ctx.targetDay)
   throw new MonsterStageError("PATCH25 साठी स्वतंत्र READY owner आवश्यक");
  // Stage50 त्याच्या स्वतंत्र owner मध्ये पूर्ण चालते. खोल अपयशावर caller अपरिवर्तित.
  const previous=discoverLegacyContiguousMonthDay(this.preceding,q);
  if(previous.context.status!=="DISCOVERY_25_RECORDED"||
     previous.historical.context.status!=="PATCH_24_APPLIED"||
     !previous.historical.corrected.historicalDailyGhostExecuted||
     previous.historical.corrected.correctedNativeSeal32.seal!==32n||
     previous.historical.corrected.correctedNativeSeal32.predecessorSharedWrites!==58||
     previous.actualSharedWrites!==BigInt(previous.actualPredecessorCalls)*58n)
   throw new MonsterStageError("Stage50 पूर्ण native historical predecessor आवश्यक");
  const weaving=previous.historical.corrected.legalWeaving;
  const corrected=this.counter.correct(weaving,previous.guessed);
  const out=Object.freeze({
   historical:previous,corrected,
   actualPredecessorCalls:previous.actualPredecessorCalls,
   actualSharedWrites:previous.actualSharedWrites,
   additionalNativeQueries:0 as const,context:ctx,
   source:"FULL_STAGE50_PATCH25_PREFIX_OCCURRENCES" as const
  });
  ctx.branchTrace.push("PATCH_25_ACTUAL_FULL_STAGE50_HISTORICAL_GUESS");
  ctx.branchTrace.push("PATCH_25_COUNT_REAL_MONTH_PREFIX_OCCURRENCES");
  ctx.branchTrace.push(corrected.historicalEqualsCorrect?
   "PATCH_25_REUSE_ONLY_EQUAL_OLD_DAY":"PATCH_25_REPLACE_WRONG_OLD_DAY");
  this.metrics.bump(ctx,"patch25.calls");
  this.metrics.bump(ctx,corrected.historicalEqualsCorrect?
   "patch25.equal_legacy":"patch25.corrected_legacy");
  ctx.metrics.set("patch25.corrected_month_day",BigInt(corrected.correctedDayInMonth));
  ctx.metrics.set("patch25.additional_native_queries",0n);
  ctx.status="PATCH_25_APPLIED";
  return out;
 }
}
export function patch25MonthDay(handler:Patch25FullHandler,
 q:Patch20StructureRequest):Patch25FullObservation{
 if(!(handler instanceof Patch25FullHandler)||!q?.historical?.yearQuestion)
  throw new MonsterValidationError("PATCH25 handler आणि प्रश्न आवश्यक");
 const year=q.historical.yearQuestion;
 return handler.run(bootstrapMonster(year.calculationDay,year.targetDay),q);
}
