import {
  countOldPositiveCompositions,LegacyPositiveCompositions,
  oldHasPrefixBoundary,Discovery21LegacyCutletHandler,
  discoverLegacyCutletPartition,
  Patch20StructureSauceHandler,Discovery20StructureSauceHandler,
  Patch19YearCacheHandler,Patch14WideChoiceHandler,
  bootstrapMonster,createMonsterContext,MonsterStageError,
  MonsterValidationError,calendarDateSpaghetti
} from "../src/index.ts";
import {FOUNDATION_DAY as F} from "./normativeOracle.ts";
import {findTrueHistoricalBoundaryMiss,assert} from "./discovery21Fixtures.ts";
function rejected(f:()=>unknown,t:typeof MonsterValidationError|typeof MonsterStageError){
 try{f();}catch(e){return e instanceof t;}return false;
}
const old=new LegacyPositiveCompositions();
assert(countOldPositiveCompositions(6n,3)===10n&&
 old.oldCount(6n,3)===10n,"6 into 3 has exactly 10 ordered positive partitions");
const lex=[...old.legacyPositiveCompositions(6n,3)].map(a=>a.join(","));
assert(lex.length===10&&new Set(lex).size===10&&
 lex[0]==="1,1,4"&&lex[1]==="1,2,3"&&
 lex[2]==="1,3,2"&&lex[3]==="1,4,1"&&
 lex[9]==="4,1,1"&&
 lex.every((x,i)=>old.oldUnrank(6n,3,BigInt(i+1)).join(",")===x),
 "old generator enumerates all and unranking is exact lexicographic");
assert(!oldHasPrefixBoundary([2n,2n,2n],3n)&&
 oldHasPrefixBoundary([1n,2n,3n],3n),
 "historical positive family does not force an internal gate boundary");
for(const bad of [[4n,6],[6n,0],[1n,18]] as const)
 assert(rejected(()=>old.oldCount(...bad),MonsterValidationError),
  "invalid number of gate gaps or cutlets rejected");
assert(rejected(()=>old.oldUnrank(6n,3,11n),MonsterValidationError),
 "old rank outside exact lex family rejected");

const f=findTrueHistoricalBoundaryMiss();
assert(f.index!==0n&&f.required>0n&&f.G>=BigInt(f.K)&&
 f.oldPartition.length===f.K&&f.correctPartition.length===f.K&&
 !oldHasPrefixBoundary(f.oldPartition,f.required)&&
 oldHasPrefixBoundary(f.correctPartition,f.required),
 "test-only oracle independently finds true internal gate with missing old cutlet boundary");
const make=()=>new Discovery21LegacyCutletHandler(
 new Patch20StructureSauceHandler(
  new Discovery20StructureSauceHandler(new Patch19YearCacheHandler())));
const handler=make();
const orig=LegacyPositiveCompositions.prototype.oldUnrank;
const count=LegacyPositiveCompositions.prototype.oldCount;
const native=Patch14WideChoiceHandler.prototype.run;
let realOldUnrank=0,realOldCount=0,realSeal20=0,realSeal21=0;
let out!:ReturnType<typeof discoverLegacyCutletPartition>;
try{
 LegacyPositiveCompositions.prototype.oldUnrank=function(...args){
  realOldUnrank++;return orig.apply(this,args);
 };
 LegacyPositiveCompositions.prototype.oldCount=function(...args){
  realOldCount++;return count.apply(this,args);
 };
 Patch14WideChoiceHandler.prototype.run=function(...args){
  if(args[5]===20n)realSeal20++;
  if(args[5]===21n)realSeal21++;
  return native.apply(this,args);
 };
 out=discoverLegacyCutletPartition(handler,f.request);
}finally{
 LegacyPositiveCompositions.prototype.oldUnrank=orig;
 LegacyPositiveCompositions.prototype.oldCount=count;
 Patch14WideChoiceHandler.prototype.run=native;
}
assert(realOldUnrank===1&&realOldCount>=2&&realSeal20===1&&realSeal21===1,
 "physically executed original lex unrank and real Bowl2 seals 20/21");
assert(out.context.status==="DISCOVERY_21_RECORDED"&&
 out.preceding.context.status==="PATCH_20_APPLIED"&&
 out.preceding.historical.context.status==="DISCOVERY_20_RECORDED"&&
 out.preceding.historical.fullStage39.context.status==="PATCH_19_APPLIED"&&
 out.G===f.G&&out.selectedK===f.K&&out.historicalUnfilteredCount===f.legacyFamily&&
 out.historicalRank===f.legacyRank&&
 out.historicalPartition.join(",")===f.oldPartition.join(",")&&
 out.yearOpenGateIndex===f.year.openGateIndex&&
 out.yearCloseGateIndex===f.year.closeGateIndex&&
 out.exactActionGateIndex===f.index&&out.requiredBoundary===f.required&&
 out.historicalMissesRequiredGate&&
 out.historicalPrefixConstraintApplied===false&&
 out.historicalActualGeneratorCalls===1&&
 out.eligibleK.length>0&&out.eligibleK[0]===6&&
 out.realGateQuestions===f.gateQuestions&&
 out.legacyCutletCountSelection.queriedBowlId===2&&
 out.legacyCutletCountSelection.seal===20n&&
 out.legacyPartitionSelection.queriedBowlId===2&&
 out.legacyPartitionSelection.seal===21n&&
 out.legacyCutletCountSelection.predecessorSharedWrites===58&&
 out.legacyPartitionSelection.predecessorSharedWrites===58&&
 out.realPredecessorCalls===out.preceding.totalRealPredecessorCalls+
  f.gateQuestions+2&&
 out.realSharedWrites===BigInt(out.realPredecessorCalls)*58n&&
 out.context.metrics.get("discovery21.old_generator_calls")===1n&&
 out.context.metrics.get("discovery21.missed_required_gate")===1n&&
 Object.isFrozen(out)&&Object.isFrozen(out.historicalPartition),
 "true signed calendar-year route and archived unfiltered wrong prefix physically selected");

const owner=bootstrapMonster(
 f.request.historical.yearQuestion.calculationDay,
 f.request.historical.yearQuestion.targetDay);
const unready=createMonsterContext(owner.calculationDay,owner.targetDay);
assert(rejected(()=>handler.run(unready,f.request),MonsterStageError)&&
 unready.branchTrace.length===0&&unready.metrics.size===0,
 "non-ready context fails before all predecessor calls");
let faultCount=0;
for(const kind of ["SEAL_20","SEAL_21","LEGACY_UNRANK"] as const){
 const h=make(),ctx=bootstrapMonster(owner.calculationDay,owner.targetDay);
 const marker="STAGE42_INJECT_"+kind;
 try{
  if(kind==="LEGACY_UNRANK")
   LegacyPositiveCompositions.prototype.oldUnrank=function():never{throw Error(marker);};
  else
   Patch14WideChoiceHandler.prototype.run=function(...args){
    if(args[5]===(kind==="SEAL_20"?20n:21n))throw Error(marker);
    return native.apply(this,args);
   };
  try{h.run(ctx,f.request);throw Error("fault not thrown");}
  catch(e){assert(e instanceof Error&&e.message===marker,
   "Stage42 late physical helper fault propagated");}
  assert(ctx.status==="VALIDATED"&&ctx.metrics.size===1&&
   ctx.branchTrace.join(",")==="BOOTSTRAP_VALIDATE",
   "Stage42 outer caller state rolled back on late failure");
  faultCount++;
 }finally{
  LegacyPositiveCompositions.prototype.oldUnrank=orig;
  Patch14WideChoiceHandler.prototype.run=native;
 }
 const recovered=h.run(ctx,f.request);
 assert(recovered.historicalMissesRequiredGate&&
  recovered.context.status==="DISCOVERY_21_RECORDED",
  "retry after deep failure reproducibly executes wrong old partition");
}
const committed=handler.run(owner,f.request);
assert(rejected(()=>handler.run(owner,f.request),MonsterStageError)&&
 committed.context===owner,"caller owner single-use after success");
const second=discoverLegacyCutletPartition(make(),f.request);
out.context.metrics.set("private",44n);
assert(!second.context.metrics.has("private")&&
 out.context!==second.context&&out.preceding!==second.preceding,
 "separate instances own independent native Sauce and composition state");
assert(rejected(()=>calendarDateSpaghetti(F,F),MonsterStageError),
 "Stage54 integrated date remains disabled");
console.log("STAGE_42_DISCOVERY_21_GUARDS_PASS directLex=10 trueActionGate=1"+
 " originalWrongBoundary=1 correctedOracleBoundary=1"+
 " realOldGeneratorCalls="+realOldUnrank+" realOldCountCalls="+realOldCount+
 " realSeal20="+realSeal20+" realSeal21="+realSeal21+
 " cutlets="+f.K+" gaps="+f.G+" oldFamily="+f.legacyFamily+
 " actionGateIndex="+f.index+
 " realGateQuestions="+f.gateQuestions+" predecessorCalls="+out.realPredecessorCalls+
 " sharedWrites="+out.realSharedWrites+" deepFaults="+faultCount);
