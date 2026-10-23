import {
 Patch22DistinctNameFamily,Patch22ExactGateHandler,Patch22FullHandler,
 Patch22NameSelection,Discovery22RepeatedNameSelector,Discovery22FullHandler,
 Patch21CutletHandler,Discovery21LegacyCutletHandler,Patch20StructureSauceHandler,
 Discovery20StructureSauceHandler,Patch19YearCacheHandler,Patch14WideChoiceHandler,
 patch22CutletNames,bootstrapMonster,MonsterStageError,MonsterValidationError,
 calendarDateSpaghetti
} from "../src/index.ts";
import {FOUNDATION_DAY as F,NormativeOracle,sauce,askBowl,chooseRank,
 fallingFactorial,unrankDistinctIndices} from "./normativeOracle.ts";
import {findTrueHistoricalBoundaryMiss,buildStage41CompatibleLegacyFixture,
 assert} from "./discovery21Fixtures.ts";
function rejected(fn:()=>unknown,cls:typeof MonsterValidationError|typeof MonsterStageError){
 try{fn();}catch(e){return e instanceof cls;}return false;
}
const family=new Patch22DistinctNameFamily();
assert(family.count(1)===17n&&family.count(2)===272n&&
 family.count(17)===fallingFactorial(17,17)&&
 family.unrank(2,1n).join(",")==="1,2"&&
 family.unrank(2,16n).join(",")==="1,17"&&
 family.unrank(2,17n).join(",")==="2,1"&&
 family.unrank(2,272n).join(",")==="17,16"&&
 family.unrank(17,1n).join(",")===Array.from({length:17},(_,i)=>i+1).join(",")&&
 family.unrank(17,family.count(17)).join(",")===
 Array.from({length:17},(_,i)=>17-i).join(","),
 "distinct lex partial-permutation bounds and exact BigInt counts");
assert(rejected(()=>family.count(0),MonsterValidationError)&&
 rejected(()=>family.unrank(17,0n),MonsterValidationError)&&
 rejected(()=>family.unrank(2,273n),MonsterValidationError),
 "K/rank bounds rejected");
const probe=findTrueHistoricalBoundaryMiss();
const c=probe.request.historical.yearQuestion.calculationDay;
const first=probe.request.firstDaySauceQuestion!;
const genuine=new Patch22ExactGateHandler().run(c,probe.index,
 probe.request.historical.yearQuestion.positive,
 probe.request.historical.yearQuestion.negative,
 probe.request.historical.yearQuestion.trueYearQuestion,first);
const K=probe.K,expected=new NormativeOracle().chooseCutletNames(
 sauce(c,first.targetDay),K);
const actualRank=chooseRank(askBowl(sauce(c,first.targetDay),5,22n),
 fallingFactorial(17,K));
assert(genuine.source==="REAL_STAGE37_GATE_PATCH22_DISTINCT_NAMES"&&
 genuine.historical.names.legacyHasRepeatedNames&&
 genuine.corrected.correctedRank===actualRank&&
 genuine.corrected.correctedNameIndices.join(",")===expected.join(",")&&
 genuine.corrected.correctedNameIndices.join(",")===
 unrankDistinctIndices(17,K,actualRank).join(",")&&
 new Set(genuine.corrected.correctedNameIndices).size===K&&
 !genuine.corrected.historicalResultReused&&
 genuine.corrected.correctedNativeSeal22.predecessorSharedWrites===58&&
 genuine.actualNativeSauceCalls===genuine.historical.actualSauceCalls+1&&
 genuine.actualSharedWrites===BigInt(genuine.actualNativeSauceCalls)*58n,
 "true action-day internal-gate Stage44 and corrected independent names");
const f=buildStage41CompatibleLegacyFixture();
const maker=()=>new Patch22FullHandler(new Discovery22FullHandler(
 new Patch21CutletHandler(new Discovery21LegacyCutletHandler(
 new Patch20StructureSauceHandler(new Discovery20StructureSauceHandler(
 new Patch19YearCacheHandler()))))));
let seal22=0;
const run=Patch14WideChoiceHandler.prototype.run;
let full!:ReturnType<typeof patch22CutletNames>;
try{
 Patch14WideChoiceHandler.prototype.run=function(...args){
  if(args[5]===22n)seal22++;
  return run.apply(this,args);
 };
 full=patch22CutletNames(maker(),f.request);
}finally{Patch14WideChoiceHandler.prototype.run=run;}
const source=f.request.firstDaySauceQuestion!;
const reference=new NormativeOracle().chooseCutletNames(
 sauce(f.cDay,source.targetDay),full.corrected.K);
assert(full.historical.context.status==="DISCOVERY_22_RECORDED"&&
 full.context.status==="PATCH_22_APPLIED"&&
 full.historical.historical.corrected.requiredBoundary===null&&
 seal22===2&&
 full.corrected.correctedNameIndices.join(",")===reference.join(",")&&
 new Set(full.corrected.correctedNameIndices).size===full.corrected.K&&
 full.actualPredecessorCalls===full.historical.actualPredecessorCalls+1&&
 full.actualSharedWrites===BigInt(full.actualPredecessorCalls)*58n&&
 full.context.metrics.get("patch22.calls")===1n,
 "complete real Stage44 history plus second full native corrected seal22");
const names=new Patch22NameSelection();
const onlyOne=new Discovery22RepeatedNameSelector().select(f.cDay,source,1);
const same=names.select(f.cDay,source,onlyOne);
assert(same.historicalResultReused&&same.legacyEqualsCorrect&&
 same.correctedNameIndices===onlyOne.legacyNameIndices&&
 same.correctFamilySize===17n,"only exact equality permits historical reuse");
const ready=bootstrapMonster(f.cDay,f.request.historical.yearQuestion.targetDay);
let nativeFaults=0;
try{
 let ordinal=0;
 Patch14WideChoiceHandler.prototype.run=function(...args){
  if(args[5]===22n&&++ordinal===2)
   throw Error("STAGE45_CORRECTED_SEAL22_FAULT");
  return run.apply(this,args);
 };
 try{maker().run(ready,f.request);throw Error("fault not injected");}
 catch(e){assert(e instanceof Error&&
  e.message==="STAGE45_CORRECTED_SEAL22_FAULT","late fault propagated");}
 assert(ready.status==="VALIDATED"&&
  ready.branchTrace.join(",")==="BOOTSTRAP_VALIDATE"&&
  ready.metrics.size===1,
  "late corrected seal22 fault leaves original owner untouched");
 nativeFaults++;
}finally{Patch14WideChoiceHandler.prototype.run=run;}
assert(maker().run(ready,f.request).context===ready&&
 rejected(()=>maker().run(ready,f.request),MonsterStageError),
 "retry commits once and second call rejects");
const a=patch22CutletNames(maker(),f.request);
assert(a.context!==full.context&&a.corrected!==full.corrected,
 "independent invocation owners");
assert(rejected(()=>calendarDateSpaghetti(F,F),MonsterStageError),
 "Stage54 full date tuple remains closed");
console.log("STAGE_45_PATCH_22_GUARDS_PASS"+
 " exactNativeGate=1 correctedRankMismatch=0 fullStage44=1"+
 " fullSeal22Calls="+seal22+" lateFaults="+nativeFaults+
 " exactSauceCalls="+genuine.actualNativeSauceCalls+
 " fullSauceCalls="+full.actualPredecessorCalls+
 " historicalDuplicatesPreserved=1 distinctOutput=1"+
 " archivedExpectedReds=22 stage54Blocked=1");
