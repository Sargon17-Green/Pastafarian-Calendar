import {
 BaseMetricsManager,bootstrapMonster,MonsterStageError,MonsterValidationError
} from "./monsterBase.ts";
import type {MonsterContext} from "./monsterBase.ts";
import {Patch21CutletHandler,patch21CutletPartition,Patch21ExactGateHandler} from "./patch21FilteredCutletCompositions.ts";
import type {Patch21FullObservation,Patch21ExactGateObservation} from "./patch21FilteredCutletCompositions.ts";
import type {Patch20StructureRequest} from "./patch20StructureSauce.ts";
import type {Patch18Question} from "./patch18YearWalk.ts";
import {patch14WideChoice} from "./patch14WideChoice.ts";
import type {Patch14WideChoiceObservation} from "./patch14WideChoice.ts";

// DISCOVERY22: जुनी नावे पुनरावृत्तीसह, क्रमाने 17^K;
// वेगवेगळ्या नावांची अट मुद्दाम येथे लावू नये.
// Stage45 मध्येच partial-permutation unrank करावयाचा आहे.
export class LegacyRepeatingCutletNames {
 oldCount(K:number):bigint {
  if(!Number.isSafeInteger(K)||K<1||K>17)
   throw new MonsterValidationError("नावांसाठी 1<=K<=17 आवश्यक");
  return 17n**BigInt(K);
 }
 oldUnrank(K:number,rank:bigint):readonly number[] {
  const N=this.oldCount(K);
  if(typeof rank!=="bigint"||rank<1n||rank>N)
   throw new MonsterValidationError("नावांची जुनी lex rank अवैध");
  const out=Array<number>(K);
  let r=rank-1n;
  for(let i=K-1;i>=0;i--){
   out[i]=Number(r%17n)+1;r/=17n;
  }
  if(r!==0n)throw new MonsterStageError("जुन्या lex नावांना सीमा चूक");
  return Object.freeze(out);
 }
 *oldRows(K:number):Generator<readonly number[]> {
  const N=this.oldCount(K);
  if(N>10000n)
   throw new MonsterValidationError("भौतिक जुन्या generator साठी आकार मर्यादा");
  for(let r=1n;r<=N;r++)yield this.oldUnrank(K,r);
 }
}
export type Discovery22NamesSelection=Readonly<{
 K:number;legacyFamilySize:bigint;legacyRank:bigint;
 legacyNameIndices:readonly number[];
 legacyHasRepeatedNames:boolean;legacyRepeatedPositions:number;
 oldActualUnrankCalls:1;noDistinctnessFilterApplied:true;
 nativeSeal22:Patch14WideChoiceObservation;
 additionalRealSauceCalls:1;
}>;
export class Discovery22RepeatedNameSelector {
 private readonly old=new LegacyRepeatingCutletNames();
 select(c:bigint,source:Patch18Question,K:number):Discovery22NamesSelection {
  if(typeof c!=="bigint"||!source||
    typeof source.targetDay!=="bigint"||!Array.isArray(source.visible)||
    !Array.isArray(source.stones)||!Array.isArray(source.startBowls))
   throw new MonsterValidationError("खरी first-year-day Sauce source आवश्यक");
  const N=this.old.oldCount(K);
  // ACTUAL Bowl5 SEAL22 and the same full historical 58 shared writes.
  // No import of the independent test-only canonical reference.
  const selected=patch14WideChoice(c,source.targetDay,
   source.visible,source.stones,source.startBowls,5,22n,N);
  if(selected.predecessorSharedWrites!==58||
    selected.queriedBowlId!==5||selected.seal!==22n||
    selected.familySize!==N)
   throw new MonsterStageError("जुन्या नावांसाठी पूर्ण native Seal22 आवश्यक");
  const names=this.old.oldUnrank(K,selected.correctedRank);
  const duplicated=names.length-new Set(names).size;
  return Object.freeze({
    K,legacyFamilySize:N,legacyRank:selected.correctedRank,
    legacyNameIndices:names,legacyHasRepeatedNames:duplicated>0,
    legacyRepeatedPositions:duplicated,
    oldActualUnrankCalls:1 as const,
    noDistinctnessFilterApplied:true as const,
    nativeSeal22:selected,additionalRealSauceCalls:1 as const
  });
 }
}
export type Discovery22ExactGateObservation=Readonly<{
 historical:Patch21ExactGateObservation;names:Discovery22NamesSelection;
 actualSauceCalls:number;actualSharedWrites:bigint;
 source:"REAL_STAGE37_GATE_AND_FIRST_DAY_SEAL22";
}>;
export class Discovery22ExactGateHandler {
 private readonly preceding=new Patch21ExactGateHandler();
 private readonly selector=new Discovery22RepeatedNameSelector();
 run(c:bigint,actionGateIndex:bigint,
   positive:readonly Patch18Question[],negative:readonly Patch18Question[],
   yearQuestion:Patch18Question,firstDayQuestion:Patch18Question
 ):Discovery22ExactGateObservation {
  const previous=this.preceding.run(c,actionGateIndex,positive,negative,
   yearQuestion,firstDayQuestion);
  if(previous.source!=="TRUE_STAGE37_SIGNED_GATE_AND_NATIVE_FIRST_DAY_SAUCE"||
   previous.historical.calculationDay!==c)
   throw new MonsterStageError("Stage43 चा पूर्ण native gate इतिहास आवश्यक");
  const names=this.selector.select(c,firstDayQuestion,previous.corrected.K);
  const calls=previous.realNativeSauceCalls+1;
  return Object.freeze({
   historical:previous,names,actualSauceCalls:calls,
   actualSharedWrites:BigInt(calls)*58n,
   source:"REAL_STAGE37_GATE_AND_FIRST_DAY_SEAL22" as const
  });
 }
}
export type Discovery22FullObservation=Readonly<{
 historical:Patch21FullObservation;names:Discovery22NamesSelection;
 actualPredecessorCalls:number;actualSharedWrites:bigint;
 source:"FULL_STAGE43_GATE_PLUS_ONE";
 context:MonsterContext;
}>;
export class Discovery22FullHandler {
 readonly preceding:Patch21CutletHandler;
 private readonly selector=new Discovery22RepeatedNameSelector();
 private readonly metrics=new BaseMetricsManager();
 constructor(preceding:Patch21CutletHandler){this.preceding=preceding;}
 run(ctx:MonsterContext,q:Patch20StructureRequest):Discovery22FullObservation {
  if(ctx.phase!=="READY"||ctx.status!=="VALIDATED"||
   !q?.historical?.yearQuestion||
   q.historical.yearQuestion.calculationDay!==ctx.calculationDay||
   q.historical.yearQuestion.targetDay!==ctx.targetDay)
   throw new MonsterStageError("Stage44 साठी सत्यापित Stage43 संदर्भ हवा");
  const previous=patch21CutletPartition(this.preceding,q);
  if(previous.context.status!=="PATCH_21_APPLIED")
   throw new MonsterStageError("Stage43 पूर्ण precursor आवश्यक");
  const first=previous.historical.preceding.trueYearFirstDay;
  const src=q.firstDaySauceQuestion??
   (first===ctx.targetDay?q.historical.originalSauceQuestion:undefined);
  if(!src||src.targetDay!==first)
   throw new MonsterValidationError("मूळ वर्षाच्या पहिल्या दिवसाचे उत्तर हवे");
  const names=this.selector.select(ctx.calculationDay,src,previous.corrected.K);
  const calls=previous.realPredecessorCalls+1;
  const result=Object.freeze({
   historical:previous,names,actualPredecessorCalls:calls,
   actualSharedWrites:BigInt(calls)*58n,
   source:"FULL_STAGE43_GATE_PLUS_ONE" as const,context:ctx
  });
  ctx.branchTrace.push("DISCOVERY_22_FULL_STAGE43_CUTLET_PREDECESSOR");
  ctx.branchTrace.push("DISCOVERY_22_ACTUAL_OLD_17_POWER_K_REPEATING_NAMES");
  ctx.branchTrace.push("DISCOVERY_22_REAL_BOWL5_SEAL22");
  this.metrics.bump(ctx,"discovery22.calls");
  ctx.metrics.set("discovery22.old_duplicate_count",BigInt(names.legacyRepeatedPositions));
  ctx.metrics.set("discovery22.predecessor_58_write_sequences",BigInt(calls));
  ctx.status="DISCOVERY_22_RECORDED";
  return result;
 }
}
export function discoverLegacyCutletNames(handler:Discovery22FullHandler,
 q:Patch20StructureRequest):Discovery22FullObservation {
 if(!(handler instanceof Discovery22FullHandler)||!q?.historical?.yearQuestion)
  throw new MonsterValidationError("Stage44 handler आणि प्रश्न आवश्यक");
 const a=q.historical.yearQuestion;
 return handler.run(bootstrapMonster(a.calculationDay,a.targetDay),q);
}
