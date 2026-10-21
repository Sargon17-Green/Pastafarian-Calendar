import {
 Patch21FilteredPositiveCompositions,Patch21ExactGateHandler,
 Patch21CutletHandler,patch21CutletPartition,Patch21PartitionSelection,
 Discovery21LegacyCutletHandler,Patch20StructureSauceHandler,
 Discovery20StructureSauceHandler,Patch19YearCacheHandler,
 LegacyPositiveCompositions,oldHasPrefixBoundary,
 Patch14WideChoiceHandler,bootstrapMonster,createMonsterContext,
 MonsterStageError,MonsterValidationError,calendarDateSpaghetti
} from "../src/index.ts";
import {FOUNDATION_DAY as F,NormativeOracle,sauce} from "./normativeOracle.ts";
import {findTrueHistoricalBoundaryMiss,buildStage41CompatibleLegacyFixture,
 assert,anyPrefix} from "./discovery21Fixtures.ts";
function rejected(fn:()=>unknown,cls:typeof MonsterStageError|typeof MonsterValidationError):boolean{
 try{fn();}catch(e){return e instanceof cls;}return false;
}
const dp=new Patch21FilteredPositiveCompositions();
const old=new LegacyPositiveCompositions();
let tested=0,retained=0,skipped=0;
for(let G=6n;G<=17n;G++){
 for(let K=2;K<=Math.min(Number(G),7);K++){
  const family=Array.from(old.legacyPositiveCompositions(G,K));
  for(let wanted=1n;wanted<G;wanted++){
   const truth=family.filter(row=>anyPrefix(row,wanted));
   assert(dp.count(G,K,wanted)===BigInt(truth.length),
    "exact filtered DP count equals exhaustive independent lex family");
   for(let i=0;i<truth.length;i++){
    const got=dp.unrank(G,K,wanted,BigInt(i+1));
    assert(got.join(",")===truth[i]!.join(",")&&oldHasPrefixBoundary(got,wanted),
     "exact filtered lex 1-based unrank equals independently filtered exhaustive list");
    retained++;
   }
   skipped+=family.length-truth.length;tested++;
  }
  assert(dp.count(G,K,null)===old.oldCount(G,K)&&
   dp.unrank(G,K,null,1n).join(",")===
    old.oldUnrank(G,K,1n).join(","),
   "no required gate = the exact historical family");
 }
}
assert(tested>100&&retained>500&&skipped>100,
 "broad exhaustive positive partitions exercise both admitted and vetoed rows");
assert(dp.countState(10n,4,0n,false,4n)===dp.count(10n,4,4n)&&
 dp.countState(5n,2,4n,true,4n)===4n&&
 dp.countState(5n,2,6n,false,4n)===0n,
 "Count(G,K,cumulative,hit) reflects exact needed boundary and post-hit state");
for(const [G,K,b] of [[5n,6,2n],[8n,3,0n],[8n,3,8n]] as const){
 assert(rejected(()=>dp.count(G,K,b),MonsterValidationError),
  "invalid empty/outer-gate inputs fail closed");
}
assert(rejected(()=>dp.unrank(6n,3,3n,0n),MonsterValidationError)&&
 rejected(()=>dp.unrank(6n,3,3n,100n),MonsterValidationError),
 "invalid filtered 1-based rank blocked");

const source=findTrueHistoricalBoundaryMiss();
const actual=new Patch21ExactGateHandler().run(
 source.request.historical.yearQuestion.calculationDay,
 source.index,source.request.historical.yearQuestion.positive,
 source.request.historical.yearQuestion.negative,
 source.request.historical.yearQuestion.trueYearQuestion,
 source.request.firstDaySauceQuestion!);
const reference=new NormativeOracle().chooseCutletPartition(
 source.request.historical.yearQuestion.calculationDay,
 sauce(source.request.historical.yearQuestion.calculationDay,
   source.year.openGateDay+1n),
 source.year,source.K);
assert(actual.source==="TRUE_STAGE37_SIGNED_GATE_AND_NATIVE_FIRST_DAY_SAUCE"&&
 actual.historical.actuallyMissedRequiredGate&&
 !oldHasPrefixBoundary(actual.historical.oldPartition,source.required)&&
 actual.corrected.requiredBoundary===source.required&&
 actual.corrected.historicalPartition.join(",")===source.oldPartition.join(",")&&
 actual.corrected.filteredCount>0n&&
 actual.corrected.filteredCount<actual.corrected.historicalCount&&
 actual.corrected.correctedExtraSelectorCalls===1&&
 actual.corrected.correctedSeal21?.seal===21n&&
 actual.corrected.correctedSeal21.queriedBowlId===2&&
 actual.corrected.correctedSeal21.familySize===actual.corrected.filteredCount&&
 actual.corrected.correctedPartition.join(",")===reference.join(",")&&
 actual.corrected.correctedPartition.join(",")===source.correctPartition.join(",")&&
 actual.corrected.historicalWrong&&
 oldHasPrefixBoundary(actual.corrected.correctedPartition,source.required)&&
 actual.nativeSharedWrites===BigInt(actual.realNativeSauceCalls)*58n&&
 actual.realNativeSauceCalls===actual.historical.realNativeSauceCalls+1,
 "real exact action gate old wrong archived, actual new seal21 filtered rank yields normative partition");

const full=buildStage41CompatibleLegacyFixture();
const make=()=>new Patch21CutletHandler(
 new Discovery21LegacyCutletHandler(
  new Patch20StructureSauceHandler(new Discovery20StructureSauceHandler(
   new Patch19YearCacheHandler()))));
const handler=make();
const choice=Patch14WideChoiceHandler.prototype.run;
let old20=0,old21=0;
try{
 Patch14WideChoiceHandler.prototype.run=function(...args){
  if(args[5]===20n)old20++;
  if(args[5]===21n)old21++;
  return choice.apply(this,args);
 };
 const out=patch21CutletPartition(handler,full.request);
 assert(out.context.status==="PATCH_21_APPLIED"&&
  out.historical.context.status==="DISCOVERY_21_RECORDED"&&
  out.historical.requiredBoundary===null&&
  out.corrected.requiredBoundary===null&&
  out.corrected.correctedExtraSelectorCalls===0&&
  out.corrected.correctedSeal21===null&&
  out.corrected.correctedRank===out.corrected.historicalRank&&
  out.corrected.correctedPartition===out.historical.historicalPartition&&
  out.corrected.filteredCount===out.historical.historicalUnfilteredCount&&
  out.realPredecessorCalls===out.historical.realPredecessorCalls&&
  out.realSharedWrites===out.historical.realSharedWrites&&
  out.realSharedWrites===BigInt(out.realPredecessorCalls)*58n&&
  old20===1&&old21===1&&
  out.context.branchTrace.includes("PATCH_21_NO_EXACT_GATE_IDENTICAL_LEX_FAMILY_REUSE"),
  "full genuine Stage41 route has no exact internal gate and reuses physically old family without extra selector");
}finally{Patch14WideChoiceHandler.prototype.run=choice;}

const noReady=createMonsterContext(full.cDay,full.request.historical.yearQuestion.targetDay);
assert(rejected(()=>handler.run(noReady,full.request),MonsterStageError)&&
 noReady.branchTrace.length===0,"no non-ready semantic caller");
const ready=bootstrapMonster(full.cDay,full.request.historical.yearQuestion.targetDay);
assert(rejected(()=>handler.run(ready,{
  ...full.request,
  historical:{...full.request.historical,
   yearQuestion:{...full.request.historical.yearQuestion,
      targetDay:full.request.historical.yearQuestion.targetDay+1n}}
}),MonsterStageError)&&
 ready.status==="VALIDATED"&&ready.metrics.size===1,
 "wrong request cannot affect semantic state");
const done=handler.run(ready,full.request);
assert(rejected(()=>handler.run(ready,full.request),MonsterStageError)&&
 done.context===ready,"semantic owner is single-use");
assert(rejected(()=>calendarDateSpaghetti(F,F),MonsterStageError),
 "Stage54 integrated calendar entry remains unavailable");
console.log("STAGE_43_PATCH_21_GUARDS_PASS exhaustiveFamilies="+tested+
 " exhaustiveRetained="+retained+" exhaustiveRejected="+skipped+
 " exactRealGateCases=1 legacyGateMisses=1 correctedWrong=0"+
 " realSeal20=1 realSeal21Old=1 realSeal21Corrected=1"+
 " fullStage41NoGateCases=1 noGateExtraSeal21=0"+
 " exactNativePredecessors="+actual.realNativeSauceCalls+
 " fullStage41Predecessors="+done.realPredecessorCalls+
 " fullSharedWrites="+(Number(actual.nativeSharedWrites)+Number(done.realSharedWrites)));
