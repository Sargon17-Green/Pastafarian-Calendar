import {
 BaseMetricsManager,bootstrapMonster,MonsterStageError,MonsterValidationError
} from "./monsterBase.ts";
import type {MonsterContext} from "./monsterBase.ts";
import {
 Discovery27FullHandler,discoverLegacyMonthSpan
} from "./discovery27LegacySpanMembership.ts";
import type {
 Discovery27FullObservation,LegacySpanMembershipResult
} from "./discovery27LegacySpanMembership.ts";
import type {Patch20StructureRequest} from "./patch20StructureSauce.ts";

// PATCH27 is a derived membership predicate over existing legal weaving.
// Preserve the deliberately flawed Stage54 span diagnostic as immutable history.
export type Patch27MembershipResult=Readonly<{
 monthId:number;
 probeYearDay:number;
 correctedMonthMembership:boolean;
 historical:LegacySpanMembershipResult;
 historicalEqualsCorrect:boolean;
 actualDirectMembershipCorrectionApplied:true;
}>;
export class Patch27DirectMembershipChecker{
 isMember(weaving:readonly number[],monthId:number,day:number):boolean{
  if(!Array.isArray(weaving)||weaving.length<1||weaving.length>5778||
     weaving.some(m=>!Number.isSafeInteger(m)||m<1||m>47)||
     !Number.isSafeInteger(monthId)||monthId<1||monthId>47||
     !Number.isSafeInteger(day)||day<1||day>weaving.length)
   throw new MonsterValidationError("वैध विणकाम, महिना आणि वर्षदिवस आवश्यक");
  return weaving[day-1]===monthId;
 }
 correct(weaving:readonly number[],old:LegacySpanMembershipResult):Patch27MembershipResult{
  if(!old||old.historicalAlgorithm!=="oldContiguousMonthMembershipGuess"||
     old.actualDirectMembershipOracleApplied!==false)
   throw new MonsterValidationError("Stage54 ची खरी ऐतिहासिक नोंद आवश्यक");
  const truth=this.isMember(weaving,old.monthId,old.probeYearDay);
  // Check complete diagnostic provenance; reject forged or stale interval fields.
  const first=weaving.indexOf(old.monthId),last=weaving.lastIndexOf(old.monthId);
  const firstDay=first<0?null:first+1,lastDay=last<0?null:last+1;
  const span=first>=0&&old.probeYearDay>=first+1&&old.probeYearDay<=last+1;
  if(old.firstYearDay!==firstDay||old.lastYearDay!==lastDay||
     old.guessedMonthMembership!==span)
   throw new MonsterValidationError("Stage54 ची कालबाह्य किंवा बनावट span नोंद");
  if(truth&&!span)
   throw new MonsterStageError("प्रत्यक्ष सदस्य span च्या बाहेर अशक्य");
  return Object.freeze({
   monthId:old.monthId,probeYearDay:old.probeYearDay,
   correctedMonthMembership:truth,historical:old,
   historicalEqualsCorrect:truth===old.guessedMonthMembership,
   actualDirectMembershipCorrectionApplied:true as const
  });
 }
}
export type Patch27FullObservation=Readonly<{
 historical:Discovery27FullObservation;
 corrected:Patch27MembershipResult;
 actualPredecessorCalls:number;
 actualSharedWrites:bigint;
 additionalNativeQueries:0;
 context:MonsterContext;
 source:"FULL_STAGE54_PATCH27_DIRECT_MONTH_MEMBERSHIP";
}>;
export class Patch27FullHandler{
 readonly preceding:Discovery27FullHandler;
 private readonly checker:Patch27DirectMembershipChecker;
 private readonly metrics=new BaseMetricsManager();
 constructor(preceding:Discovery27FullHandler,
  checker:Patch27DirectMembershipChecker=new Patch27DirectMembershipChecker()){
  this.preceding=preceding;this.checker=checker;
 }
 run(ctx:MonsterContext,q:Patch20StructureRequest,monthId:number,
  day:number):Patch27FullObservation{
  if(ctx.phase!=="READY"||ctx.status!=="VALIDATED"||
     !q?.historical?.yearQuestion||
     ctx.calculationDay!==q.historical.yearQuestion.calculationDay||
     ctx.targetDay!==q.historical.yearQuestion.targetDay)
   throw new MonsterStageError("PATCH27 साठी स्वतंत्र READY owner आवश्यक");
  if(!Number.isSafeInteger(monthId)||monthId<1||monthId>47||
     !Number.isSafeInteger(day)||day<1||day>5778)
   throw new MonsterValidationError("PATCH27 चाचणी प्रश्न अवैध");
  // Full Stage54 chain executes under a separate owner; failure cannot mutate ctx.
  const previous=discoverLegacyMonthSpan(this.preceding,q,monthId,day);
  if(previous.context.status!=="DISCOVERY_27_RECORDED"||
     previous.historical.context.status!=="PATCH_26_APPLIED"||
     previous.historical.historical.context.status!=="DISCOVERY_26_RECORDED"||
     previous.historical.historical.historical.context.status!=="PATCH_25_APPLIED"||
     previous.guessed.actualDirectMembershipOracleApplied!==false||
     previous.guessed.monthId!==monthId||previous.guessed.probeYearDay!==day||
     previous.additionalNativeQueries!==0||
     previous.actualSharedWrites!==BigInt(previous.actualPredecessorCalls)*58n)
   throw new MonsterStageError("Stage54 ची पूर्ण Native साखळी आवश्यक");
  const weaving=
   previous.historical.historical.historical.historical.historical.corrected.legalWeaving;
  const corrected=this.checker.correct(weaving,previous.guessed);
  const result=Object.freeze({
   historical:previous,corrected,
   actualPredecessorCalls:previous.actualPredecessorCalls,
   actualSharedWrites:previous.actualSharedWrites,
   additionalNativeQueries:0 as const,context:ctx,
   source:"FULL_STAGE54_PATCH27_DIRECT_MONTH_MEMBERSHIP" as const
  });
  ctx.branchTrace.push("PATCH_27_FULL_STAGE54_PREDECESSOR_ACTUALLY_RUN");
  ctx.branchTrace.push("PATCH_27_DIRECT_WEAVING_MEMBERSHIP");
  ctx.branchTrace.push(corrected.historicalEqualsCorrect?
   "PATCH_27_REUSE_EQUAL_SPAN":"PATCH_27_REJECT_FALSE_SPAN_MEMBERSHIP");
  this.metrics.bump(ctx,"patch27.calls");
  this.metrics.bump(ctx,corrected.historicalEqualsCorrect?
   "patch27.equal_legacy":"patch27.corrected_legacy");
  ctx.metrics.set("patch27.actual_membership",
   corrected.correctedMonthMembership?1n:0n);
  ctx.metrics.set("patch27.additional_native_queries",0n);
  ctx.status="PATCH_27_APPLIED";
  return result;
 }
}
export function patch27MonthMembership(
 handler:Patch27FullHandler,q:Patch20StructureRequest,
 monthId:number,day:number):Patch27FullObservation{
 if(!(handler instanceof Patch27FullHandler)||!q?.historical?.yearQuestion)
  throw new MonsterValidationError("PATCH27 handler आणि प्रश्न आवश्यक");
 const year=q.historical.yearQuestion;
 return handler.run(bootstrapMonster(year.calculationDay,year.targetDay),
  q,monthId,day);
}
