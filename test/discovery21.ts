import {
 countOldPositiveCompositions,LegacyPositiveCompositions,oldHasPrefixBoundary,
 Discovery21LegacyCutletHandler,Discovery21ExactGateProbeHandler,
 discoverLegacyCutletPartition,
 Patch20StructureSauceHandler,Discovery20StructureSauceHandler,
 Patch19YearCacheHandler,Patch14WideChoiceHandler,
 bootstrapMonster,createMonsterContext,MonsterStageError,
 MonsterValidationError,calendarDateSpaghetti
} from "../src/index.ts";
import {FOUNDATION_DAY as F,NormativeOracle,sauce} from "./normativeOracle.ts";
import {findTrueHistoricalBoundaryMiss,buildStage41CompatibleLegacyFixture,
  question,assert} from "./discovery21Fixtures.ts";
function rejected(f:()=>unknown,t:typeof MonsterValidationError|typeof MonsterStageError){
 try{f();}catch(e){return e instanceof t;}return false;
}
const generator=new LegacyPositiveCompositions();
assert(countOldPositiveCompositions(6n,3)===10n,
 "6 into 3 has exactly 10 ordered positive partitions");
const lex=[...generator.legacyPositiveCompositions(6n,3)].map(a=>a.join(","));
assert(lex.length===10&&new Set(lex).size===10&&
 lex[0]==="1,1,4"&&lex[1]==="1,2,3"&&lex[9]==="4,1,1"&&
 lex.every((v,i)=>generator.oldUnrank(6n,3,BigInt(i+1)).join(",")===v),
 "old enumerator and unrank true lex order");
assert(!oldHasPrefixBoundary([2n,2n,2n],3n)&&
 oldHasPrefixBoundary([1n,2n,3n],3n),"old family includes both boundary types");
for(const [g,k] of [[4n,6],[6n,0],[1n,18]] as const)
 assert(rejected(()=>generator.oldCount(g,k),MonsterValidationError),
  "invalid composition rejected");

const exact=findTrueHistoricalBoundaryMiss();
const real=new Discovery21ExactGateProbeHandler().run(
  exact.request.historical.yearQuestion.calculationDay,exact.index,
  exact.request.historical.yearQuestion.positive,
  exact.request.historical.yearQuestion.negative,
  exact.request.historical.yearQuestion.trueYearQuestion,
  exact.request.firstDaySauceQuestion!);
assert(real.source==="PHYSICALLY_RECOMPUTED_SIGNED_GATES_AND_FIRST_DAY_NATIVE_SAUCE"&&
 real.genuineYearNumber===5000n&&real.G===exact.G&&real.K===exact.K&&
 real.actionGateIndex===exact.index&&real.requiredBoundary===exact.required&&
 real.trueYearOpenGateIndex===exact.year.openGateIndex&&
 real.trueYearCloseGateIndex===exact.year.closeGateIndex&&
 real.oldRank===exact.legacyRank&&
 real.oldUnfilteredFamilySize===exact.legacyFamily&&
 real.oldPartition.join(",")===exact.oldPartition.join(",")&&
 real.actuallyMissedRequiredGate&&!oldHasPrefixBoundary(real.oldPartition,real.requiredBoundary)&&
 oldHasPrefixBoundary(exact.correctPartition,real.requiredBoundary)&&
 real.historicalPrefixConstraintApplied===false&&
 real.nativeSharedWrites===BigInt(real.realNativeSauceCalls)*58n&&
 real.fullNativeGateQuestions>0,
 "independent exact gate-day native Year5000 and real old composition reveal true wrong boundary");

const full=buildStage41CompatibleLegacyFixture();
const make=()=>new Discovery21LegacyCutletHandler(
 new Patch20StructureSauceHandler(new Discovery20StructureSauceHandler(
  new Patch19YearCacheHandler())));
const handler=make();
const orig=LegacyPositiveCompositions.prototype.oldUnrank;
const oldCount=LegacyPositiveCompositions.prototype.oldCount;
const native=Patch14WideChoiceHandler.prototype.run;
let oldUnranks=0,countCalls=0,seal20=0,seal21=0;
let out!:ReturnType<typeof discoverLegacyCutletPartition>;
try{
 LegacyPositiveCompositions.prototype.oldUnrank=function(...args){
  oldUnranks++;return orig.apply(this,args);
 };
 LegacyPositiveCompositions.prototype.oldCount=function(...args){
  countCalls++;return oldCount.apply(this,args);
 };
 Patch14WideChoiceHandler.prototype.run=function(...args){
  if(args[5]===20n)seal20++;
  if(args[5]===21n)seal21++;
  return native.apply(this,args);
 };
 out=discoverLegacyCutletPartition(handler,full.request);
}finally{
 LegacyPositiveCompositions.prototype.oldUnrank=orig;
 LegacyPositiveCompositions.prototype.oldCount=oldCount;
 Patch14WideChoiceHandler.prototype.run=native;
}
const oracle=new NormativeOracle();
const c=full.cDay,y=full.oracleYear;
const structure=sauce(c,y.openGateDay+1n);
const K=oracle.chooseCutletCount(structure,y);
assert(out.context.status==="DISCOVERY_21_RECORDED"&&
 out.preceding.context.status==="PATCH_20_APPLIED"&&
 out.preceding.historical.fullStage39.context.status==="PATCH_19_APPLIED"&&
 out.G===y.closeGateIndex-y.openGateIndex&&out.selectedK===K&&
 out.yearOpenGateIndex===y.openGateIndex&&
 out.yearCloseGateIndex===y.closeGateIndex&&
 out.exactActionGateIndex===null&&out.requiredBoundary===null&&
 !out.historicalMissesRequiredGate&&
 out.historicalPrefixConstraintApplied===false&&
 out.historicalActualGeneratorCalls===1&&
 out.historicalUnfilteredCount===generator.oldCount(out.G,K)&&
 out.historicalPartition.length===K&&
 out.historicalPartition.reduce((a,b)=>a+b,0n)===out.G&&
 out.legacyCutletCountSelection.seal===20n&&
 out.legacyPartitionSelection.seal===21n&&
 out.legacyCutletCountSelection.queriedBowlId===2&&
 out.legacyPartitionSelection.queriedBowlId===2&&
 out.realPredecessorCalls===out.preceding.totalRealPredecessorCalls+
 out.realGateQuestions+2&&
 out.realSharedWrites===BigInt(out.realPredecessorCalls)*58n&&
 oldUnranks===1&&countCalls>=2&&seal20===1&&seal21===1,
 "full Stage41 sealed predecessor is genuine; gate+1 is NOT falsely an exact gate");
const unready=createMonsterContext(c,full.request.historical.yearQuestion.targetDay);
assert(rejected(()=>handler.run(unready,full.request),MonsterStageError)&&
 unready.metrics.size===0,"unready context blocked");
let faults=0;
for(const which of ["SEAL20","SEAL21","OLD_UNRANK"] as const){
 const h=make(),ctx=bootstrapMonster(c,full.request.historical.yearQuestion.targetDay);
 const mark="STAGE42_"+which;
 try{
  if(which==="OLD_UNRANK")
   LegacyPositiveCompositions.prototype.oldUnrank=function():never{throw Error(mark)};
  else
   Patch14WideChoiceHandler.prototype.run=function(...args){
    if(args[5]===(which==="SEAL20"?20n:21n))throw Error(mark);
    return native.apply(this,args);
   };
  try{h.run(ctx,full.request);throw Error("missing injected failure");}
  catch(e){assert(e instanceof Error&&e.message===mark,"deep native/helper fault surfaced");}
  assert(ctx.status==="VALIDATED"&&ctx.metrics.size===1&&
    ctx.branchTrace.join(",")==="BOOTSTRAP_VALIDATE","outer context rolled back");
  faults++;
 }finally{
  LegacyPositiveCompositions.prototype.oldUnrank=orig;
  Patch14WideChoiceHandler.prototype.run=native;
 }
 const again=h.run(ctx,full.request);
 assert(again.context.status==="DISCOVERY_21_RECORDED"&&
  again.historicalPrefixConstraintApplied===false,"same owner recovery");
}
const owned=bootstrapMonster(c,full.request.historical.yearQuestion.targetDay);
handler.run(owned,full.request);
assert(rejected(()=>handler.run(owned,full.request),MonsterStageError),
 "outer owner single-use");
const second=discoverLegacyCutletPartition(make(),full.request);
out.context.metrics.set("private",5n);
assert(!second.context.metrics.has("private")&&
  second.context!==out.context,"no shared semantic context");
assert(rejected(()=>calendarDateSpaghetti(F,F),MonsterStageError),
 "Stage54 integration unopened");
console.log("STAGE_42_DISCOVERY_21_GUARDS_PASS directLex=10"+
 " exactGateNativeWrong=1 fullStage41Runs=1"+
 " fullStage41ActionGateNone=1 actualOldUnrank="+oldUnranks+
 " actualSeal20="+seal20+" actualSeal21="+seal21+
 " nativeExactPredecessors="+real.realNativeSauceCalls+
 " nativeExactWrites="+real.nativeSharedWrites+
 " fullPredecessors="+out.realPredecessorCalls+
 " fullWrites="+out.realSharedWrites+" deepFaults="+faults);
