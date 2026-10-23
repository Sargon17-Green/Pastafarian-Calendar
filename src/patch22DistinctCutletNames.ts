import {
 BaseMetricsManager,bootstrapMonster,MonsterStageError,MonsterValidationError
} from "./monsterBase.ts";
import type {MonsterContext} from "./monsterBase.ts";
import {LegacyRepeatingCutletNames,Discovery22RepeatedNameSelector,
 Discovery22ExactGateHandler,Discovery22FullHandler,discoverLegacyCutletNames
} from "./discovery22LegacyCutletNames.ts";
import type {Discovery22NamesSelection,Discovery22ExactGateObservation,
 Discovery22FullObservation} from "./discovery22LegacyCutletNames.ts";
import type {Patch20StructureRequest} from "./patch20StructureSauce.ts";
import type {Patch18Question} from "./patch18YearWalk.ts";
import {patch14WideChoice} from "./patch14WideChoice.ts";
import type {Patch14WideChoiceObservation} from "./patch14WideChoice.ts";

// PATCH22: मूळ 17^K lex मार्ग बदलू नका; वेगळ्या नावांसाठी
// फक्त canonicalIndex 1..17 चा नेमका partial-permutation क्रम.
export class Patch22DistinctNameFamily {
 private readonly legacy=new LegacyRepeatingCutletNames();
 count(K:number):bigint {
  this.legacy.oldCount(K);
  let size=1n;
  for(let i=0;i<K;i++)size*=BigInt(17-i);
  return size;
 }
 unrank(K:number,rank:bigint):readonly number[] {
  const total=this.count(K);
  if(typeof rank!=="bigint"||rank<1n||rank>total)
   throw new MonsterValidationError("वेगळ्या नावांची lex rank अवैध");
  let r=rank-1n;
  const remaining=Array.from({length:17},(_,i)=>i+1);
  const out:number[]=[];
  for(let i=0;i<K;i++){
   let block=1n;
   for(let j=0;j<K-i-1;j++)block*=BigInt(16-i-j);
   const index=Number(r/block);
   if(!Number.isSafeInteger(index)||index<0||index>=remaining.length)
    throw new MonsterStageError("partial-permutation क्रम मर्यादेबाहेर");
   const value=remaining.splice(index,1)[0];
   if(value===undefined)throw new MonsterStageError("नामस्थान रिकामे");
   out.push(value);
   r%=block;
  }
  if(r!==0n||out.length!==K||new Set(out).size!==K)
   throw new MonsterStageError("अद्वितीय नामक्रमात चूक");
  return Object.freeze(out);
 }
}
export type Patch22NamesSelection=Readonly<{
 K:number;historical:Discovery22NamesSelection;
 correctFamilySize:bigint;correctedRank:bigint;
 calculatedCorrectNames:readonly number[];correctedNameIndices:readonly number[];
 legacyEqualsCorrect:boolean;historicalResultReused:boolean;
 historicalUnrankReplayed:true;correctedSelectorCalls:1;
 correctedNativeSeal22:Patch14WideChoiceObservation;
 extraNativeSauceCalls:1;
}>;
export class Patch22NameSelection {
 private readonly family=new Patch22DistinctNameFamily();
 private readonly old=new LegacyRepeatingCutletNames();
 select(c:bigint,firstDayQuestion:Patch18Question,
  historical:Discovery22NamesSelection):Patch22NamesSelection {
  if(typeof c!=="bigint"||!firstDayQuestion||
     typeof firstDayQuestion.targetDay!=="bigint"||
     !historical||historical.nativeSeal22.queriedBowlId!==5||
     historical.nativeSeal22.seal!==22n||
     historical.nativeSeal22.predecessorSharedWrites!==58||
     historical.nativeSeal22.context.calculationDay!==c||
     historical.nativeSeal22.context.targetDay!==firstDayQuestion.targetDay)
   throw new MonsterValidationError("पूर्ण ऐतिहासिक Bowl5 seal22 पुरावा आवश्यक");
  const K=historical.K,originalCount=this.old.oldCount(K);
  if(historical.legacyFamilySize!==originalCount||
     historical.nativeSeal22.familySize!==originalCount||
     historical.oldActualUnrankCalls!==1||
     historical.legacyNameIndices.join(",")!==
       this.old.oldUnrank(K,historical.legacyRank).join(","))
   throw new MonsterStageError("मूळ 17^K lex निवड प्रत्यक्ष जतन होणे आवश्यक");
  const N=this.family.count(K);
  const actual=patch14WideChoice(c,firstDayQuestion.targetDay,
   firstDayQuestion.visible,firstDayQuestion.stones,
   firstDayQuestion.startBowls,5,22n,N);
  if(actual.predecessorSharedWrites!==58||
     actual.queriedBowlId!==5||actual.seal!==22n||
     actual.familySize!==N)
   throw new MonsterStageError("दुरुस्त Bowl5 seal22 चे 58 writes आवश्यक");
  const correct=this.family.unrank(K,actual.correctedRank);
  const equal=historical.legacyNameIndices.length===correct.length&&
   historical.legacyNameIndices.every((v,i)=>v===correct[i]);
  const served=equal?historical.legacyNameIndices:correct;
  if(new Set(served).size!==K||served.some(v=>v<1||v>17))
   throw new MonsterStageError("दुरुस्त नावांची स्वतंत्रता अनिवार्य");
  return Object.freeze({
   K,historical,correctFamilySize:N,correctedRank:actual.correctedRank,
   calculatedCorrectNames:correct,correctedNameIndices:served,
   legacyEqualsCorrect:equal,historicalResultReused:equal,
   historicalUnrankReplayed:true as const,correctedSelectorCalls:1 as const,
   correctedNativeSeal22:actual,extraNativeSauceCalls:1 as const
  });
 }
}
export type Patch22ExactGateObservation=Readonly<{
 historical:Discovery22ExactGateObservation;corrected:Patch22NamesSelection;
 actualNativeSauceCalls:number;actualSharedWrites:bigint;
 source:"REAL_STAGE37_GATE_PATCH22_DISTINCT_NAMES";
}>;
export class Patch22ExactGateHandler {
 private readonly preceding=new Discovery22ExactGateHandler();
 private readonly selector=new Patch22NameSelection();
 run(c:bigint,actionGateIndex:bigint,
  positive:readonly Patch18Question[],negative:readonly Patch18Question[],
  yearQuestion:Patch18Question,firstDayQuestion:Patch18Question
 ):Patch22ExactGateObservation {
  const previous=this.preceding.run(c,actionGateIndex,positive,negative,
   yearQuestion,firstDayQuestion);
  if(previous.source!=="REAL_STAGE37_GATE_AND_FIRST_DAY_SEAL22")
   throw new MonsterStageError("Stage44 native exact gate आवश्यक");
  const corrected=this.selector.select(c,firstDayQuestion,previous.names);
  const calls=previous.actualSauceCalls+1;
  return Object.freeze({
   historical:previous,corrected,actualNativeSauceCalls:calls,
   actualSharedWrites:BigInt(calls)*58n,
   source:"REAL_STAGE37_GATE_PATCH22_DISTINCT_NAMES" as const
  });
 }
}
export type Patch22FullObservation=Readonly<{
 historical:Discovery22FullObservation;corrected:Patch22NamesSelection;
 actualPredecessorCalls:number;actualSharedWrites:bigint;
 source:"FULL_STAGE44_GATE_PLUS_ONE_PATCH22";context:MonsterContext;
}>;
export class Patch22FullHandler {
 readonly preceding:Discovery22FullHandler;
 private readonly selector=new Patch22NameSelection();
 private readonly metrics=new BaseMetricsManager();
 constructor(preceding:Discovery22FullHandler){this.preceding=preceding;}
 run(ctx:MonsterContext,q:Patch20StructureRequest):Patch22FullObservation {
  if(ctx.phase!=="READY"||ctx.status!=="VALIDATED"||
     !q?.historical?.yearQuestion||
     q.historical.yearQuestion.calculationDay!==ctx.calculationDay||
     q.historical.yearQuestion.targetDay!==ctx.targetDay)
   throw new MonsterStageError("PATCH22 साठी वैध READY संदर्भ हवा");
  // मूळ Stage44 स्वतंत्र संदर्भात; उशिरा चूक आली तरी caller न बदलणे.
  const previous=discoverLegacyCutletNames(this.preceding,q);
  if(previous.context.status!=="DISCOVERY_22_RECORDED")
   throw new MonsterStageError("Stage44 पूर्ण historical पूर्ववर्ती आवश्यक");
  const first=previous.historical.historical.preceding.trueYearFirstDay;
  const source=q.firstDaySauceQuestion??
   (first===ctx.targetDay?q.historical.originalSauceQuestion:undefined);
  if(!source||source.targetDay!==first)
   throw new MonsterValidationError("वर्षाच्या पहिल्या दिवसाचा खरा स्रोत हवा");
  const corrected=this.selector.select(ctx.calculationDay,source,previous.names);
  if(corrected.K!==previous.historical.corrected.K)
   throw new MonsterStageError("कटलेट संख्या पूर्ववर्तीशी विसंगत");
  const calls=previous.actualPredecessorCalls+1;
  const result=Object.freeze({
   historical:previous,corrected,actualPredecessorCalls:calls,
   actualSharedWrites:BigInt(calls)*58n,
   source:"FULL_STAGE44_GATE_PLUS_ONE_PATCH22" as const,context:ctx
  });
  ctx.branchTrace.push("PATCH_22_RUN_ACTUAL_DISCOVERY22_OLD_REPEAT_CHOICES");
  ctx.branchTrace.push("PATCH_22_RUN_REAL_BOWL5_SEAL22_CORRECT_COUNT");
  ctx.branchTrace.push(corrected.historicalResultReused?
   "PATCH_22_REUSE_ONLY_EXACT_EQUAL":"PATCH_22_REPLACE_WRONG_LEGACY_NAMES");
  this.metrics.bump(ctx,"patch22.calls");
  this.metrics.bump(ctx,"patch22.corrected_seal22");
  this.metrics.bump(ctx,corrected.historicalResultReused?
   "patch22.legacy_equal":"patch22.legacy_replaced");
  ctx.metrics.set("patch22.native_58_write_sequences",BigInt(calls));
  ctx.status="PATCH_22_APPLIED";
  return result;
 }
}
export function patch22CutletNames(handler:Patch22FullHandler,
 q:Patch20StructureRequest):Patch22FullObservation {
 if(!(handler instanceof Patch22FullHandler)||!q?.historical?.yearQuestion)
  throw new MonsterValidationError("PATCH22 handler आणि प्रश्न आवश्यक");
 const a=q.historical.yearQuestion;
 return handler.run(bootstrapMonster(a.calculationDay,a.targetDay),q);
}
