import {BaseMetricsManager,bootstrapMonster,MonsterStageError,MonsterValidationError} from "./monsterBase.ts";
import type {MonsterContext} from "./monsterBase.ts";
import {Patch23FullHandler,patch23MonthLengths} from "./patch23VirtualMonthLengths.ts";
import type {Patch23FullObservation} from "./patch23VirtualMonthLengths.ts";
import {patch14WideChoice} from "./patch14WideChoice.ts";
import type {Patch14WideChoiceObservation} from "./patch14WideChoice.ts";
import type {Patch20StructureRequest} from "./patch20StructureSauce.ts";
import type {Patch18Question} from "./patch18YearWalk.ts";

// DISCOVERY24: मूळ दोष. प्रत्येक दिवसाचा month-ID स्वतंत्रपणे निवडला जातो.
// Stage49 चा legal weaving DP/unrank हा सुधार येथे आणायचा नाही.
export class LegacyIndependentDailyMonthChooser{
 legacyChooseEachDaySeparately(lengths:readonly bigint[],rank:bigint):readonly number[]{
  if(!Array.isArray(lengths)||lengths.length<2||lengths.length>47||
     lengths.some(x=>typeof x!=="bigint"||x<1n||x>123n))
   throw new MonsterValidationError("जुन्या रोजच्या निवडीच्या महिना-लांबी अवैध");
  const L=lengths.reduce((a,b)=>a+b,0n),m=lengths.length;
  if(L<1n||L>5778n||typeof rank!=="bigint"||rank<1n||rank>BigInt(m))
   throw new MonsterValidationError("जुन्या निवडीचा सुरक्षित दिवस/rank अवैध");
  const ghost:number[]=[];
  for(let day=0;day<Number(L);day++)
   ghost.push(Number((rank-1n+BigInt(day))%BigInt(m))+1);
  return Object.freeze(ghost);
 }
}
export type LegacyWeavingAudit=Readonly<{
 totalDays:number;monthCount:number;
 requiredCounts:readonly number[];observedCounts:readonly number[];
 firstAppearance:readonly number[];lastAppearance:readonly number[];
 multiplicityValid:boolean;firstOrderValid:boolean;lastOrderValid:boolean;legal:boolean;
}>;
export function auditLegacyWeaving(lengths:readonly bigint[],ghost:readonly number[]):LegacyWeavingAudit{
 if(!Array.isArray(lengths)||lengths.length<2||lengths.length>47||
  lengths.some(x=>typeof x!=="bigint"||x<1n||x>123n)||
  !Array.isArray(ghost)||ghost.length>5778)
  throw new MonsterValidationError("ghost audit मर्यादा");
 const required=lengths.map(x=>Number(x));
 const total=required.reduce((a,b)=>a+b,0);
 if(total!==ghost.length)throw new MonsterValidationError("ghost एकूण दिवस चुकीचे");
 const m=required.length,seen=Array<number>(m).fill(0),last=Array<number>(m).fill(-1);
 const first:number[]=[];
 for(let d=0;d<ghost.length;d++){
  const id=ghost[d]!;
  if(!Number.isSafeInteger(id)||id<1||id>m)
   throw new MonsterValidationError("ghost month ID चुकीचा");
  if(seen[id-1]===0)first.push(id);
  seen[id-1]!++;last[id-1]=d;
 }
 const expected=Array.from({length:m},(_,j)=>j+1);
 const ending=expected.filter(j=>last[j-1]!==-1)
  .sort((a,b)=>last[a-1]!-last[b-1]!);
 const multiplicity=seen.every((n,j)=>n===required[j]);
 const firstOk=first.join(",")===expected.join(",");
 const lastOk=ending.join(",")===expected.join(",");
 return Object.freeze({
  totalDays:total,monthCount:m,
  requiredCounts:Object.freeze(required),observedCounts:Object.freeze(seen),
  firstAppearance:Object.freeze(first),lastAppearance:Object.freeze(ending),
  multiplicityValid:multiplicity,firstOrderValid:firstOk,lastOrderValid:lastOk,
  legal:multiplicity&&firstOk&&lastOk
 });
}
export type Discovery24LegacyObservation=Readonly<{
 lengths:readonly bigint[];ghost:readonly number[];
 historicalMonthIdChoice:Patch14WideChoiceObservation;
 audit:LegacyWeavingAudit;historicalDailyDecisions:number;
 historicalAlgorithm:"legacyChooseEachDaySeparately";
 actualNativeSeal32Calls:1;realSharedWrites:58;
 correctedLegalWeavingApplied:false;
}>;
export class Discovery24LegacySelector{
 private readonly original=new LegacyIndependentDailyMonthChooser();
 select(c:bigint,source:Patch18Question,lengths:readonly bigint[]):Discovery24LegacyObservation{
  if(typeof c!=="bigint"||!source||typeof source.targetDay!=="bigint"||
     !Array.isArray(source.visible)||!Array.isArray(source.stones)||
     !Array.isArray(source.startBowls)||!Array.isArray(lengths)||
     lengths.length<3||lengths.length>47||
     lengths.some(x=>typeof x!=="bigint"||x<4n||x>123n))
   throw new MonsterValidationError("पूर्ण पहिल्या दिवसाची Sauce व महिने आवश्यक");
  const pick=patch14WideChoice(c,source.targetDay,
   source.visible,source.stones,source.startBowls,4,32n,BigInt(lengths.length));
  if(pick.queriedBowlId!==4||pick.seal!==32n||
     pick.predecessorSharedWrites!==58||
     pick.context.calculationDay!==c||pick.context.targetDay!==source.targetDay)
   throw new MonsterStageError("मूळ Bowl4 Seal32 Native 58-write प्रश्न आवश्यक");
  const ghost=this.original.legacyChooseEachDaySeparately(lengths,pick.correctedRank);
  return Object.freeze({
   lengths,ghost,historicalMonthIdChoice:pick,
   audit:auditLegacyWeaving(lengths,ghost),
   historicalDailyDecisions:ghost.length,
   historicalAlgorithm:"legacyChooseEachDaySeparately" as const,
   actualNativeSeal32Calls:1 as const,realSharedWrites:58 as const,
   correctedLegalWeavingApplied:false as const
  });
 }
}
export type Discovery24FullObservation=Readonly<{
 historical:Patch23FullObservation;weaving:Discovery24LegacyObservation;
 realPredecessorCalls:number;realSharedWrites:bigint;context:MonsterContext;
 source:"FULL_STAGE47_LEGACY_INDEPENDENT_DAILY_MONTHS";
}>;
export class Discovery24FullHandler{
 readonly preceding:Patch23FullHandler;
 private readonly selector:Discovery24LegacySelector;
 private readonly metrics=new BaseMetricsManager();
 constructor(preceding:Patch23FullHandler,
  selector:Discovery24LegacySelector=new Discovery24LegacySelector()){
  this.preceding=preceding;this.selector=selector;
 }
 run(ctx:MonsterContext,q:Patch20StructureRequest):Discovery24FullObservation{
  if(ctx.phase!=="READY"||ctx.status!=="VALIDATED"||
     !q?.historical?.yearQuestion||
     q.historical.yearQuestion.calculationDay!==ctx.calculationDay||
     q.historical.yearQuestion.targetDay!==ctx.targetDay)
   throw new MonsterStageError("DISCOVERY24 साठी READY owner आवश्यक");
  const previous=patch23MonthLengths(this.preceding,q);
  if(previous.context.status!=="PATCH_23_APPLIED"||
     previous.corrected.correctedNativeSeal31.predecessorSharedWrites!==58||
     previous.historical.months.monthCountChoice.predecessorSharedWrites!==58)
   throw new MonsterStageError("Stage47 पूर्ण predecessor आवश्यक");
  const stage41=previous.historical.historical.historical.historical.historical.preceding;
  const firstDay=stage41.trueYearFirstDay;
  const source=q.firstDaySauceQuestion??
   (firstDay===ctx.targetDay?q.historical.originalSauceQuestion:undefined);
  if(!source||source.targetDay!==firstDay)
   throw new MonsterValidationError("वर्षाच्या पहिल्या दिवसाची Sauce आवश्यक");
  const weaving=this.selector.select(ctx.calculationDay,source,
   previous.corrected.correctedLengths);
  const calls=previous.actualPredecessorCalls+weaving.actualNativeSeal32Calls;
  const out=Object.freeze({
   historical:previous,weaving,realPredecessorCalls:calls,
   realSharedWrites:BigInt(calls)*58n,context:ctx,
   source:"FULL_STAGE47_LEGACY_INDEPENDENT_DAILY_MONTHS" as const
  });
  ctx.branchTrace.push("DISCOVERY_24_REAL_FULL_STAGE47_PREDECESSOR");
  ctx.branchTrace.push("DISCOVERY_24_NATIVE_BOWL4_SEAL32_58_WRITES");
  ctx.branchTrace.push("DISCOVERY_24_ACTUAL_LEGACY_DAY_BY_DAY_GHOST");
  ctx.branchTrace.push(weaving.audit.legal?
   "DISCOVERY_24_GHOST_ACCIDENTALLY_LEGAL":"DISCOVERY_24_GHOST_WRONG");
  this.metrics.bump(ctx,"discovery24.calls");
  this.metrics.bump(ctx,"discovery24.real_seal32_calls");
  ctx.metrics.set("discovery24.legacy_daily_decisions",BigInt(weaving.historicalDailyDecisions));
  ctx.metrics.set("discovery24.real_shared_writes",BigInt(calls)*58n);
  ctx.status="DISCOVERY_24_RECORDED";
  return out;
 }
}
export function discoverLegacyIndependentDailyMonths(
 handler:Discovery24FullHandler,q:Patch20StructureRequest
):Discovery24FullObservation{
 if(!(handler instanceof Discovery24FullHandler)||!q?.historical?.yearQuestion)
  throw new MonsterValidationError("DISCOVERY24 handler व प्रश्न आवश्यक");
 const year=q.historical.yearQuestion;
 return handler.run(bootstrapMonster(year.calculationDay,year.targetDay),q);
}
