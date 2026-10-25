import {BaseMetricsManager,bootstrapMonster,MonsterStageError,MonsterValidationError} from "./monsterBase.ts";
import type {MonsterContext} from "./monsterBase.ts";
import {Discovery24FullHandler,discoverLegacyIndependentDailyMonths,
 LegacyIndependentDailyMonthChooser,auditLegacyWeaving} from "./discovery24LegacyDailyMonths.ts";
import type {Discovery24FullObservation,Discovery24LegacyObservation} from "./discovery24LegacyDailyMonths.ts";
import {ScalableLegalWeavingUnrank} from "./patch24ScalableUnrank.ts";
import {patch14WideChoice} from "./patch14WideChoice.ts";
import type {Patch14WideChoiceObservation} from "./patch14WideChoice.ts";
import type {Patch20StructureRequest} from "./patch20StructureSauce.ts";
import type {Patch18Question} from "./patch18YearWalk.ts";
// Independent native corrected Bowl4 Seal32 after actual Stage48 historical ghost.
export type Patch24ScalableSelection=Readonly<{
 historical:Discovery24LegacyObservation;
 exactFamilySize:bigint;correctedRank:bigint;
 legalWeaving:readonly number[];oldGhostReused:boolean;
 correctedNativeSeal32:Patch14WideChoiceObservation;
 historicalDailyGhostExecuted:true;additionalNativeCalls:1;
}>;
export class Patch24ScalableSelector{
 select(c:bigint,source:Patch18Question,old:Discovery24LegacyObservation):Patch24ScalableSelection{
  if(typeof c!=="bigint"||!source||
   typeof source.targetDay!=="bigint"||
   !Array.isArray(source.visible)||!Array.isArray(source.stones)||
   !Array.isArray(source.startBowls)||!old||
   old.historicalAlgorithm!=="legacyChooseEachDaySeparately"||
   old.historicalMonthIdChoice.queriedBowlId!==4||
   old.historicalMonthIdChoice.seal!==32n||
   old.historicalMonthIdChoice.predecessorSharedWrites!==58||
   old.historicalMonthIdChoice.context.calculationDay!==c||
   old.historicalMonthIdChoice.context.targetDay!==source.targetDay||
   old.historicalDailyDecisions!==old.ghost.length||
   old.correctedLegalWeavingApplied!==false)
   throw new MonsterValidationError("पूर्ण Stage48 जुना ghost व Bowl4 Seal32 आवश्यक");
  const oldAgain=new LegacyIndependentDailyMonthChooser()
   .legacyChooseEachDaySeparately(old.lengths,old.historicalMonthIdChoice.correctedRank);
  if(oldAgain.join(",")!==old.ghost.join(",")||
   old.audit.legal!==auditLegacyWeaving(old.lengths,old.ghost).legal)
   throw new MonsterStageError("Stage48 जुना ghost पुन्हा जुळला नाही");
  const virtual=new ScalableLegalWeavingUnrank(old.lengths),N=virtual.count();
  const selected=patch14WideChoice(c,source.targetDay,source.visible,
   source.stones,source.startBowls,4,32n,N);
  if(selected.queriedBowlId!==4||selected.seal!==32n||
   selected.familySize!==N||selected.predecessorSharedWrites!==58)
   throw new MonsterStageError("योग्य N वर स्वतंत्र पूर्ण Bowl4 Seal32 आवश्यक");
  const correct=virtual.itemAt1(selected.correctedRank);
  const equal=old.audit.legal&&old.ghost.length===correct.length&&
   old.ghost.every((j,i)=>j===correct[i]);
  return Object.freeze({
   historical:old,exactFamilySize:N,correctedRank:selected.correctedRank,
   legalWeaving:equal?old.ghost:correct,oldGhostReused:equal,
   correctedNativeSeal32:selected,historicalDailyGhostExecuted:true as const,
   additionalNativeCalls:1 as const
  });
 }
}
export type Patch24ScalableFullObservation=Readonly<{
 historical:Discovery24FullObservation;corrected:Patch24ScalableSelection;
 realPredecessorCalls:number;realSharedWrites:bigint;
 source:"FULL_STAGE48_SCALABLE_PATCH24_LEGAL_WEAVING";context:MonsterContext;
}>;
export class Patch24ScalableFullHandler{
 readonly preceding:Discovery24FullHandler;
 private readonly selector:Patch24ScalableSelector;
 private readonly metrics=new BaseMetricsManager();
 constructor(preceding:Discovery24FullHandler,
  selector:Patch24ScalableSelector=new Patch24ScalableSelector()){
  this.preceding=preceding;this.selector=selector;
 }
 run(ctx:MonsterContext,q:Patch20StructureRequest):Patch24ScalableFullObservation{
  if(ctx.phase!=="READY"||ctx.status!=="VALIDATED"||
   !q?.historical?.yearQuestion||
   q.historical.yearQuestion.calculationDay!==ctx.calculationDay||
   q.historical.yearQuestion.targetDay!==ctx.targetDay)
   throw new MonsterStageError("PATCH24 साठी READY semantic owner हवा");
  const historical=discoverLegacyIndependentDailyMonths(this.preceding,q);
  if(historical.context.status!=="DISCOVERY_24_RECORDED"||
   historical.weaving.actualNativeSeal32Calls!==1||
   historical.historical.corrected.correctedNativeSeal31.predecessorSharedWrites!==58)
   throw new MonsterStageError("पूर्ण Stage48 historical predecessor नाही");
  const first=historical.historical.historical.historical.historical.historical.preceding.trueYearFirstDay;
  const src=q.firstDaySauceQuestion??
   (first===ctx.targetDay?q.historical.originalSauceQuestion:undefined);
  if(!src||src.targetDay!==first)
   throw new MonsterValidationError("खरा वर्षाचा first-day Sauce हवा");
  const corrected=this.selector.select(ctx.calculationDay,src,historical.weaving);
  const calls=historical.realPredecessorCalls+1;
  const out=Object.freeze({historical,corrected,realPredecessorCalls:calls,
   realSharedWrites:BigInt(calls)*58n,
   source:"FULL_STAGE48_SCALABLE_PATCH24_LEGAL_WEAVING" as const,context:ctx});
  ctx.branchTrace.push("PATCH_24_ACTUAL_FULL_STAGE48_LEGACY_GHOST");
  ctx.branchTrace.push("PATCH_24_EXACT_SCALABLE_LEX_UNRANK");
  ctx.branchTrace.push("PATCH_24_INDEPENDENT_FULL_NATIVE_SEAL32_CORRECT_COUNT");
  ctx.branchTrace.push(corrected.oldGhostReused?
   "PATCH_24_REUSE_IDENTICAL_LEGAL_GHOST":"PATCH_24_CORRECT_WRONG_GHOST");
  this.metrics.bump(ctx,"patch24.scalable_calls");
  this.metrics.bump(ctx,"patch24.real_corrected_seal32");
  ctx.metrics.set("patch24.legal_weaving_size",corrected.exactFamilySize);
  ctx.metrics.set("patch24.predecessor_58_write_sequences",BigInt(calls));
  ctx.status="PATCH_24_APPLIED";
  return out;
 }
}
export function patch24ScalableLegalWeaving(handler:Patch24ScalableFullHandler,
 q:Patch20StructureRequest):Patch24ScalableFullObservation{
 if(!(handler instanceof Patch24ScalableFullHandler)||!q?.historical?.yearQuestion)
  throw new MonsterValidationError("PATCH24 handler व विनंती आवश्यक");
 const a=q.historical.yearQuestion;
 return handler.run(bootstrapMonster(a.calculationDay,a.targetDay),q);
}
