import {
 BaseMetricsManager,bootstrapMonster,MonsterStageError,MonsterValidationError
} from "./monsterBase.ts";
import type {MonsterContext} from "./monsterBase.ts";
import {
 Patch24ScalableFullHandler,patch24ScalableLegalWeaving
} from "./patch24ScalableNativeWeaving.ts";
import type {Patch24ScalableFullObservation}
 from "./patch24ScalableNativeWeaving.ts";
import type {Patch20StructureRequest} from "./patch20StructureSauce.ts";

// DISCOVERY25 इतिहास. महिन्याच्या विखुरलेल्या occurrences असतानाही
// पहिल्या occurrence पासून सततचे दिवसच month-day मानण्याचा चुकीचा तर्क.
// योग्य prefix-occurrence counter फक्त Stage51 PATCH25 मध्ये येईल.
export type OldContiguousMonthDayResult=Readonly<{
 monthId:number;
 targetYearDay:number;
 assumedMonthStartYearDay:number;
 guessedDayInMonth:number;
 historicalAlgorithm:"oldContiguousMonthDayGuess";
 actualPrefixOccurrenceCorrectionApplied:false;
}>;
export class OldContiguousMonthDayGuess{
 oldContiguousMonthDayGuess(weaving:readonly number[],yearDay:number):
  OldContiguousMonthDayResult{
  if(!Array.isArray(weaving)||weaving.length<1||weaving.length>5778||
     !Number.isSafeInteger(yearDay)||yearDay<1||yearDay>weaving.length||
     weaving.some(v=>!Number.isSafeInteger(v)||v<1||v>47))
   throw new MonsterValidationError("जुन्या महिना-दिवसासाठी वैध weaving आणि वर्षदिवस आवश्यक");
  const month=weaving[yearDay-1]!;
  const first=weaving.indexOf(month)+1;
  if(first<1||first>yearDay)throw new MonsterStageError("जुन्या सलग महिन्याची सुरुवात सापडली नाही");
  return Object.freeze({
   monthId:month,targetYearDay:yearDay,assumedMonthStartYearDay:first,
   guessedDayInMonth:yearDay-first+1,
   historicalAlgorithm:"oldContiguousMonthDayGuess" as const,
   actualPrefixOccurrenceCorrectionApplied:false as const
  });
 }
}
export type Discovery25FullObservation=Readonly<{
 historical:Patch24ScalableFullObservation;
 guessed:OldContiguousMonthDayResult;
 actualPredecessorCalls:number;
 actualSharedWrites:bigint;
 context:MonsterContext;
 source:"FULL_STAGE49_HISTORICAL_CONTIGUOUS_MONTH_DAY_GUESS";
}>;
export class Discovery25FullHandler{
 readonly preceding:Patch24ScalableFullHandler;
 private readonly guesser:OldContiguousMonthDayGuess;
 private readonly metrics=new BaseMetricsManager();
 constructor(preceding:Patch24ScalableFullHandler,
  guesser:OldContiguousMonthDayGuess=new OldContiguousMonthDayGuess()){
  this.preceding=preceding;this.guesser=guesser;
 }
 run(ctx:MonsterContext,q:Patch20StructureRequest):Discovery25FullObservation{
  if(ctx.phase!=="READY"||ctx.status!=="VALIDATED"||
    !q?.historical?.yearQuestion||
    ctx.calculationDay!==q.historical.yearQuestion.calculationDay||
    ctx.targetDay!==q.historical.yearQuestion.targetDay)
   throw new MonsterStageError("DISCOVERY25 साठी योग्य READY owner हवा");
  // पूर्ण Stage49 corrected weaving आणि Stage48 मूळ ghost प्रत्यक्ष चालतात.
  const previous=patch24ScalableLegalWeaving(this.preceding,q);
  if(previous.context.status!=="PATCH_24_APPLIED"||
     previous.historical.context.status!=="DISCOVERY_24_RECORDED"||
     previous.historical.historical.context.status!=="PATCH_23_APPLIED"||
     previous.corrected.correctedNativeSeal32.queriedBowlId!==4||
     previous.corrected.correctedNativeSeal32.seal!==32n||
     previous.corrected.correctedNativeSeal32.predecessorSharedWrites!==58||
     !previous.corrected.historicalDailyGhostExecuted)
   throw new MonsterStageError("Stage49 पूर्ण native corrected predecessor आवश्यक");
  const firstDay=previous.historical.historical.historical.historical.historical.historical.historical.preceding.trueYearFirstDay;
  const ordinal=ctx.targetDay-firstDay+1n;
  const weaving=previous.corrected.legalWeaving;
  if(ordinal<1n||ordinal>BigInt(weaving.length))
   throw new MonsterValidationError("वर्षाबाहेरचा लक्ष्य दिवस चुकीचा");
  const guessed=this.guesser.oldContiguousMonthDayGuess(weaving,Number(ordinal));
  const out=Object.freeze({
   historical:previous,guessed,
   actualPredecessorCalls:previous.realPredecessorCalls,
   actualSharedWrites:previous.realSharedWrites,
   context:ctx,
   source:"FULL_STAGE49_HISTORICAL_CONTIGUOUS_MONTH_DAY_GUESS" as const
  });
  ctx.branchTrace.push("DISCOVERY_25_FULL_STAGE49_PREDECESSOR_ACTUALLY_RUN");
  ctx.branchTrace.push("DISCOVERY_25_OLD_CONTIGUOUS_MONTH_DAY_GUESS_ACTUALLY_RUN");
  ctx.branchTrace.push("DISCOVERY_25_CORRECT_OCCURRENCE_PREFIX_NOT_APPLIED");
  this.metrics.bump(ctx,"discovery25.calls");
  this.metrics.bump(ctx,"discovery25.historical_contiguous_guesses");
  ctx.metrics.set("discovery25.guessed_month_day",BigInt(guessed.guessedDayInMonth));
  ctx.metrics.set("discovery25.additional_native_queries",0n);
  ctx.status="DISCOVERY_25_RECORDED";
  return out;
 }
}
export function discoverLegacyContiguousMonthDay(
 handler:Discovery25FullHandler,q:Patch20StructureRequest
):Discovery25FullObservation{
 if(!(handler instanceof Discovery25FullHandler)||!q?.historical?.yearQuestion)
  throw new MonsterValidationError("DISCOVERY25 handler व प्रश्न आवश्यक");
 const year=q.historical.yearQuestion;
 return handler.run(bootstrapMonster(year.calculationDay,year.targetDay),q);
}
