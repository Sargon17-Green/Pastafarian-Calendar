import {
 LegacyRepeatingCutletNames,Discovery22RepeatedNameSelector,
 Discovery22ExactGateHandler,Discovery22FullHandler,
 Discovery21LegacyCutletHandler,Patch21CutletHandler,
 Patch20StructureSauceHandler,Discovery20StructureSauceHandler,
 Patch19YearCacheHandler,Patch14WideChoiceHandler,
 discoverLegacyCutletNames,bootstrapMonster,createMonsterContext,
 MonsterStageError,MonsterValidationError,calendarDateSpaghetti
} from "../src/index.ts";
import {FOUNDATION_DAY as F,NormativeOracle,sauce,askBowl,chooseRank}
 from "./normativeOracle.ts";
import {findTrueHistoricalBoundaryMiss,buildStage41CompatibleLegacyFixture,
 assert} from "./discovery21Fixtures.ts";
function rejected(fn:()=>unknown,cls:typeof MonsterValidationError|typeof MonsterStageError){
 try{fn();}catch(e){return e instanceof cls;}return false;
}
const old=new LegacyRepeatingCutletNames();
const rows=[...old.oldRows(2)].map(x=>x.join(","));
assert(rows.length===289&&new Set(rows).size===289&&
 rows[0]==="1,1"&&rows[1]==="1,2"&&
 rows[16]==="1,17"&&rows[17]==="2,1"&&rows[288]==="17,17"&&
 rows.every((x,j)=>old.oldUnrank(2,BigInt(j+1)).join(",")===x),
 "old name generator really lists all 17² repeated and nonrepeated rows in lex order");
assert(old.oldCount(6)===24137569n&&old.oldCount(17)===17n**17n&&
 old.oldUnrank(17,1n).every(x=>x===1)&&
 old.oldUnrank(17,17n**17n).every(x=>x===17),
 "historical repeated rows exact BigInt 17^K, no factorial substitution");
for(const bad of [0,18,-1,3.5,Number.POSITIVE_INFINITY]){
 assert(rejected(()=>old.oldCount(bad),MonsterValidationError),
 "invalid cutlet-count rejects");
}
for(const bad of [0n,290n]){
 assert(rejected(()=>old.oldUnrank(2,bad),MonsterValidationError),
 "invalid old 1-based lex rank");
}
assert(rejected(()=>[...old.oldRows(17)],MonsterValidationError),
 "huge historical full generator refuses materialization rather than silently truncate");

const probe=findTrueHistoricalBoundaryMiss();
const c=probe.request.historical.yearQuestion.calculationDay;
const first=probe.year.openGateDay+1n;
const nameStream=askBowl(sauce(c,first),5,22n);
const familySize=old.oldCount(probe.K);
const expectedRank=chooseRank(nameStream,familySize);
const expected=old.oldUnrank(probe.K,expectedRank);
const reference=new NormativeOracle().chooseCutletNames(sauce(c,first),probe.K);
const actual=new Discovery22ExactGateHandler().run(c,probe.index,
 probe.request.historical.yearQuestion.positive,
 probe.request.historical.yearQuestion.negative,
 probe.request.historical.yearQuestion.trueYearQuestion,
 probe.request.firstDaySauceQuestion!);
assert(actual.source==="REAL_STAGE37_GATE_AND_FIRST_DAY_SEAL22"&&
 actual.historical.corrected.K===probe.K&&
 actual.historical.corrected.correctedPartition.join(",")===probe.correctPartition.join(",")&&
 actual.names.nativeSeal22.seal===22n&&
 actual.names.nativeSeal22.queriedBowlId===5&&
 actual.names.nativeSeal22.predecessorSharedWrites===58&&
 actual.names.nativeSeal22.familySize===familySize&&
 actual.names.legacyRank===expectedRank&&
 actual.names.legacyNameIndices.join(",")===expected.join(",")&&
 actual.names.legacyRepeatedPositions===probe.K-new Set(expected).size&&
 actual.names.legacyHasRepeatedNames===(new Set(expected).size!==probe.K)&&
 actual.names.noDistinctnessFilterApplied===true&&
 actual.actualSauceCalls===actual.historical.realNativeSauceCalls+1&&
 actual.actualSharedWrites===BigInt(actual.actualSauceCalls)*58n&&
 reference.length===probe.K&&new Set(reference).size===probe.K,
 "genuine action-day exact gate and Year5000 structural first-day Sauce -> physical old Bowl5 seal22");
const whole=buildStage41CompatibleLegacyFixture();
const maker=()=>new Discovery22FullHandler(new Patch21CutletHandler(
 new Discovery21LegacyCutletHandler(
  new Patch20StructureSauceHandler(new Discovery20StructureSauceHandler(
   new Patch19YearCacheHandler())))));
const handler=maker();
let seal22=0;
const originalSelector=Patch14WideChoiceHandler.prototype.run;
let full!:ReturnType<typeof discoverLegacyCutletNames>;
try{
 Patch14WideChoiceHandler.prototype.run=function(...args){
  if(args[5]===22n)seal22++;
  return originalSelector.apply(this,args);
 };
 full=discoverLegacyCutletNames(handler,whole.request);
}finally{Patch14WideChoiceHandler.prototype.run=originalSelector;}
const src=whole.request.firstDaySauceQuestion!;
const fullRank=chooseRank(askBowl(sauce(whole.cDay,src.targetDay),5,22n),
 old.oldCount(full.historical.corrected.K));
assert(full.context.status==="DISCOVERY_22_RECORDED"&&
 full.historical.context.status==="PATCH_21_APPLIED"&&
 full.historical.corrected.requiredBoundary===null&&
 full.source==="FULL_STAGE43_GATE_PLUS_ONE"&&
 full.names.legacyRank===fullRank&&
 full.names.legacyNameIndices.join(",")===
 old.oldUnrank(full.historical.corrected.K,fullRank).join(",")&&
 full.names.legacyNameIndices.every(x=>x>=1&&x<=17)&&
 full.names.nativeSeal22.queriedBowlId===5&&seal22===1&&
 full.actualPredecessorCalls===full.historical.realPredecessorCalls+1&&
 full.actualSharedWrites===BigInt(full.actualPredecessorCalls)*58n&&
 full.context.metrics.get("discovery22.calls")===1n,
 "entire Stage43 archive physically executed and final repeated name seal22 correct");
const invalid=createMonsterContext(whole.cDay,whole.request.historical.yearQuestion.targetDay);
assert(rejected(()=>handler.run(invalid,whole.request),MonsterStageError)&&
 invalid.metrics.size===0,
 "non-ready semantic owner rejected");
const ready=bootstrapMonster(whole.cDay,whole.request.historical.yearQuestion.targetDay);
assert(rejected(()=>handler.run(ready,{
 ...whole.request,firstDaySauceQuestion:{
  ...whole.request.firstDaySauceQuestion!,
  targetDay:whole.request.firstDaySauceQuestion!.targetDay+1n
 }
}),MonsterValidationError)&&ready.status==="VALIDATED"&&
 ready.metrics.size===1&&ready.branchTrace.join(",")==="BOOTSTRAP_VALIDATE",
 "mismatched year-first-day rejected without partial owner mutations");
let failures=0;
try{
 Patch14WideChoiceHandler.prototype.run=function(...args){
  if(args[5]===22n)throw Error("STAGE44_SEAL22_FAULT");
  return originalSelector.apply(this,args);
 };
 try{handler.run(ready,whole.request);throw Error("missing injected failure");}
 catch(e){assert(e instanceof Error&&e.message==="STAGE44_SEAL22_FAULT",
 "exact late selector fault propagated");}
 assert(ready.status==="VALIDATED"&&ready.metrics.size===1&&
  ready.branchTrace.join(",")==="BOOTSTRAP_VALIDATE",
  "old handler does not mutate caller on late seal22 failure");
 failures++;
}finally{Patch14WideChoiceHandler.prototype.run=originalSelector;}
assert(handler.run(ready,whole.request).context===ready&&
 rejected(()=>handler.run(ready,whole.request),MonsterStageError),
 "same ready context recovers and commits once");
const other=discoverLegacyCutletNames(maker(),whole.request);
full.context.metrics.set("private",12n);
assert(other.context!==full.context&&!other.context.metrics.has("private")&&
 other.names!==full.names,
 "independent per-invocation state");
assert(rejected(()=>calendarDateSpaghetti(F,F),MonsterStageError),
 "Stage54 full date path remains closed");
console.log("STAGE_44_DISCOVERY_22_GUARDS_PASS"+
 " oldLexRows="+rows.length+" oldRepeatedRows=1"+
 " genuineExactGate=1 nativeSeal22=1 actualRepeated="+
 Number(actual.names.legacyHasRepeatedNames)+
 " independentReferenceDistinct="+Number(new Set(reference).size===probe.K)+
 " fullStage43=1 fullSelectorSpy="+seal22+
 " exactNativeCalls="+actual.actualSauceCalls+
 " exactNativeWrites="+actual.actualSharedWrites+
 " fullPredecessors="+full.actualPredecessorCalls+
 " fullWrites="+full.actualSharedWrites+
 " faultCases="+failures+" earlyPatchApplied=0");
