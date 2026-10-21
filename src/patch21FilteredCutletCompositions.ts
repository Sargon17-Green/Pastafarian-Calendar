import {
  BaseMetricsManager,bootstrapMonster,MonsterStageError,MonsterValidationError
} from "./monsterBase.ts";
import type {MonsterContext} from "./monsterBase.ts";
import {
  LegacyPositiveCompositions,oldHasPrefixBoundary,
  Discovery21LegacyCutletHandler,Discovery21ExactGateProbeHandler,
  discoverLegacyCutletPartition
} from "./discovery21LegacyCutletCompositions.ts";
import type {
  Discovery21LegacyCutletObservation,Discovery21ExactGateProbe
} from "./discovery21LegacyCutletCompositions.ts";
import type {Patch20StructureRequest} from "./patch20StructureSauce.ts";
import type {Patch18Question} from "./patch18YearWalk.ts";
import {patch14WideChoice} from "./patch14WideChoice.ts";
import type {Patch14WideChoiceObservation} from "./patch14WideChoice.ts";

// PATCH21 — मूळ lex-positive रचना आणि जुने seal21 उत्तर जसेच्या तसे;
// फक्त प्रत्यक्ष आतील calculation-day gate असेल तर शुद्ध फिल्टर केलेला
// exact Count(G,K,cumulative,hit) + एक-आधारित lex unrank.
function choose(n:bigint,k:number):bigint {
 if(n<0n||!Number.isSafeInteger(k)||k<0||n<BigInt(k))return 0n;
 if(k===0)return 1n;
 let v=1n;
 for(let i=1;i<=k;i++)v=v*(n-BigInt(i)+1n)/BigInt(i);
 return v;
}
export class Patch21FilteredPositiveCompositions {
 private readonly old=new LegacyPositiveCompositions();
 private validate(G:bigint,K:number,required:bigint|null):void {
  this.old.oldCount(G,K);
  if(required!==null&&(typeof required!=="bigint"||
      required<=0n||required>=G))
   throw new MonsterValidationError("कृती-दिवसाची gate सीमा वर्षाच्या आत असावी");
 }
 // Exact DP state, closed combinatorial evaluation of all positive suffixes.
 // Counting all possible j avoids loops proportional to huge G.
 countState(remaining:bigint,k:number,cumulative:bigint,
    hit:boolean,required:bigint|null):bigint {
  if(typeof remaining!=="bigint"||remaining<0n||
     !Number.isSafeInteger(k)||k<1||k>17||
     typeof cumulative!=="bigint"||cumulative<0n||
     typeof hit!=="boolean"||
     (required!==null&&(typeof required!=="bigint"||required<=0n)))
   throw new MonsterValidationError("अचूक DP अवस्था आवश्यक");
  const all=choose(remaining-1n,k-1);
  if(all===0n||hit||required===null)return all;
  const D=required-cumulative;
  if(D<=0n||D>=remaining||k===1)return 0n;
  let total=0n;
  for(let j=1;j<k;j++){
   total+=choose(D-1n,j-1)*choose(remaining-D-1n,k-j-1);
  }
  return total;
 }
 count(G:bigint,K:number,required:bigint|null):bigint {
  this.validate(G,K,required);
  return this.countState(G,K,0n,false,required);
 }
 private cumulativeBlocks(rem:bigint,k:number,c:bigint,
   hit:boolean,required:bigint|null,x:bigint):bigint {
  const max=rem-BigInt(k-1);
  const cap=x<0n?0n:x>max?max:x;
  if(cap===0n)return 0n;
  if(hit||required===null){
   return choose(rem-1n,k-1)-choose(rem-cap-1n,k-1);
  }
  const D=required-c;
  if(D<=0n||D>=rem)return 0n;
  let total=0n;
  for(let j=1;j<k;j++){
   // #positive j-part prefixes of sum D with first element <=cap,
   // times #positive suffixes after the REQUIRED prefix sum.
   const prefixes=choose(D-1n,j-1)-choose(D-cap-1n,j-1);
   total+=prefixes*choose(rem-D-1n,k-j-1);
  }
  return total;
 }
 unrank(G:bigint,K:number,required:bigint|null,rank:bigint):readonly bigint[]{
  const total=this.count(G,K,required);
  if(typeof rank!=="bigint"||rank<1n||rank>total||total===0n)
   throw new MonsterValidationError("फिल्टर झालेली lex rank अवैध आहे");
  if(required===null)return this.old.oldUnrank(G,K,rank);
  let rem=G,k=K,c=0n,hit=false,r=rank;
  const parts:bigint[]=[];
  while(k>1){
   let lo=1n,hi=rem-BigInt(k-1);
   while(lo<hi){
    const mid=(lo+hi)/2n;
    if(this.cumulativeBlocks(rem,k,c,hit,required,mid)>=r)hi=mid;
    else lo=mid+1n;
   }
   const part=lo;
   r-=this.cumulativeBlocks(rem,k,c,hit,required,part-1n);
   parts.push(part);
   c+=part;rem-=part;k--;
   if(c===required)hit=true;
  }
  parts.push(rem);
  const result=Object.freeze(parts);
  if(!oldHasPrefixBoundary(result,required)||
     result.reduce((a,b)=>a+b,0n)!==G||
     result.length!==K||result.some(x=>x<1n)||r!==1n)
   throw new MonsterStageError("अचूक filtered lex DP ने अवैध भाग निवडले");
  return result;
 }
}
export type Patch21Selection=Readonly<{
 G:bigint;K:number;requiredBoundary:bigint|null;
 historicalCount:bigint;filteredCount:bigint;
 historicalRank:bigint;historicalPartition:readonly bigint[];
 correctedRank:bigint;correctedPartition:readonly bigint[];
 correctedSeal21:Patch14WideChoiceObservation|null;
 correctedExtraSelectorCalls:0|1;
 filteredBoundaryPresent:boolean;
 historicalWrong:boolean;
}>;
export class Patch21PartitionSelection {
 private readonly dp=new Patch21FilteredPositiveCompositions();
 select(c:bigint,firstDayQuestion:Patch18Question,
  G:bigint,K:number,required:bigint|null,
  historicalCount:bigint,historicalRank:bigint,
  historicalPartition:readonly bigint[]):Patch21Selection {
  if(typeof c!=="bigint"||!firstDayQuestion||
     typeof firstDayQuestion.targetDay!=="bigint")
   throw new MonsterValidationError("पूर्ण first-day प्रश्न आवश्यक");
  const expectedOriginal=new LegacyPositiveCompositions().oldCount(G,K);
  if(historicalCount!==expectedOriginal||
     typeof historicalRank!=="bigint"||
     historicalRank<1n||historicalRank>historicalCount||
     historicalPartition.length!==K||
     historicalPartition.reduce((a,b)=>a+b,0n)!==G)
   throw new MonsterStageError("Stage42 चे मूळ रचनेचे पुरावे विसंगत");
  const filteredCount=this.dp.count(G,K,required);
  if(filteredCount<1n)throw new MonsterStageError("वैध filtered cutlet family रिकामी");
  const extra=required!==null;
  const correctedSeal=extra?patch14WideChoice(c,firstDayQuestion.targetDay,
   firstDayQuestion.visible,firstDayQuestion.stones,
   firstDayQuestion.startBowls,2,21n,filteredCount):null;
  const rank=correctedSeal?.correctedRank??historicalRank;
  const partition=extra?this.dp.unrank(G,K,required,rank):historicalPartition;
  if(required!==null&&!oldHasPrefixBoundary(partition,required))
   throw new MonsterStageError("कटलेट विभागणीतील अट पूर्ण झाली नाही");
  return Object.freeze({
   G,K,requiredBoundary:required,historicalCount,filteredCount,
   historicalRank,historicalPartition,
   correctedRank:rank,correctedPartition:partition,correctedSeal21:correctedSeal,
   correctedExtraSelectorCalls:extra?1 as const:0 as const,
   filteredBoundaryPresent:required!==null,
   historicalWrong:required!==null&&
     !oldHasPrefixBoundary(historicalPartition,required)
  });
 }
}
export type Patch21FullObservation=Readonly<{
 historical:Discovery21LegacyCutletObservation;
 corrected:Patch21Selection;additionalNativeCalls:0|1;
 realPredecessorCalls:number;realSharedWrites:bigint;
 context:MonsterContext;
}>;
export class Patch21CutletHandler {
 private readonly choice=new Patch21PartitionSelection();
 private readonly metrics=new BaseMetricsManager();
 readonly predecessor:Discovery21LegacyCutletHandler;
 constructor(predecessor:Discovery21LegacyCutletHandler){this.predecessor=predecessor;}
 run(ctx:MonsterContext,q:Patch20StructureRequest):Patch21FullObservation {
  if(ctx.phase!=="READY"||ctx.status!=="VALIDATED"||
     !q?.historical?.yearQuestion||
     ctx.calculationDay!==q.historical.yearQuestion.calculationDay||
     ctx.targetDay!==q.historical.yearQuestion.targetDay)
   throw new MonsterStageError("PATCH21 साठी Stage42 वैध संदर्भ आवश्यक");
  const old=discoverLegacyCutletPartition(this.predecessor,q);
  if(old.context.status!=="DISCOVERY_21_RECORDED"||
     old.historicalPrefixConstraintApplied||old.historicalActualGeneratorCalls!==1)
   throw new MonsterStageError("जुनी पूर्ण lex-positive रचना प्रत्यक्ष हवी");
  const first=old.preceding.trueYearFirstDay;
  const source=q.firstDaySauceQuestion??
    (first===ctx.targetDay?q.historical.originalSauceQuestion:undefined);
  if(!source||source.targetDay!==first)
   throw new MonsterValidationError("अधिकृत first-day प्रश्न आवश्यक");
  const corrected=this.choice.select(ctx.calculationDay,source,
   old.G,old.selectedK,old.requiredBoundary,
   old.historicalUnfilteredCount,old.historicalRank,old.historicalPartition);
  const calls=old.realPredecessorCalls+corrected.correctedExtraSelectorCalls;
  const result=Object.freeze({
    historical:old,corrected,
    additionalNativeCalls:corrected.correctedExtraSelectorCalls,
    realPredecessorCalls:calls,realSharedWrites:BigInt(calls)*58n,
    context:ctx
  });
  ctx.branchTrace.push("PATCH_21_FULL_STAGE42_OLD_UNFILTERED_LEX_PREDECESSOR");
  ctx.branchTrace.push(corrected.filteredBoundaryPresent?
    "PATCH_21_EXACT_FILTERED_DP_AND_REAL_BOWL2_SEAL21":
    "PATCH_21_NO_EXACT_GATE_IDENTICAL_LEX_FAMILY_REUSE");
  this.metrics.bump(ctx,"patch21.calls");
  ctx.metrics.set("patch21.filtered_family_size",corrected.filteredCount);
  ctx.metrics.set("patch21.extra_seal21_calls",BigInt(result.additionalNativeCalls));
  ctx.status="PATCH_21_APPLIED";
  return result;
 }
}
export function patch21CutletPartition(handler:Patch21CutletHandler,
 q:Patch20StructureRequest):Patch21FullObservation {
 if(!(handler instanceof Patch21CutletHandler)||!q?.historical?.yearQuestion)
  throw new MonsterValidationError("पूर्ण PATCH21 handler व प्रश्न आवश्यक");
 const a=q.historical.yearQuestion;
 return handler.run(bootstrapMonster(a.calculationDay,a.targetDay),q);
}
export type Patch21ExactGateObservation=Readonly<{
 historical:Discovery21ExactGateProbe;
 corrected:Patch21Selection;
 realNativeSauceCalls:number;
 nativeSharedWrites:bigint;
 source:"TRUE_STAGE37_SIGNED_GATE_AND_NATIVE_FIRST_DAY_SAUCE";
}>;
export class Patch21ExactGateHandler {
 private readonly old=new Discovery21ExactGateProbeHandler();
 private readonly choice=new Patch21PartitionSelection();
 run(c:bigint,actionGateIndex:bigint,
   positive:readonly Patch18Question[],negative:readonly Patch18Question[],
   yearQuestion:Patch18Question,firstDayQuestion:Patch18Question
 ):Patch21ExactGateObservation {
  const old=this.old.run(c,actionGateIndex,
   positive,negative,yearQuestion,firstDayQuestion);
  if(old.historicalPrefixConstraintApplied||
     old.source!=="PHYSICALLY_RECOMPUTED_SIGNED_GATES_AND_FIRST_DAY_NATIVE_SAUCE")
   throw new MonsterStageError("पूर्ण खरा Stage42 exact gate पुरावा आवश्यक");
  const corrected=this.choice.select(c,firstDayQuestion,old.G,old.K,
   old.requiredBoundary,old.oldUnfilteredFamilySize,
   old.oldRank,old.oldPartition);
  const calls=old.realNativeSauceCalls+corrected.correctedExtraSelectorCalls;
  return Object.freeze({
   historical:old,corrected,realNativeSauceCalls:calls,
   nativeSharedWrites:BigInt(calls)*58n,
   source:"TRUE_STAGE37_SIGNED_GATE_AND_NATIVE_FIRST_DAY_SAUCE" as const
  });
 }
}
