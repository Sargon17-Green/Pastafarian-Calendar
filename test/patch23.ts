import {
 VirtualLegacyList,Patch23MonthLengthSelector,Patch23FullHandler,
 Discovery23FullHandler,LegacyAllMonthLengthWays,
 Patch22FullHandler,Discovery22FullHandler,Patch21CutletHandler,
 Discovery21LegacyCutletHandler,Patch20StructureSauceHandler,
 Discovery20StructureSauceHandler,Patch19YearCacheHandler,
 Patch14WideChoiceHandler,bootstrapMonster,MonsterStageError,
 MonsterValidationError,calendarDateSpaghetti,patch23MonthLengths
} from "../src/index.ts";
import {
 FOUNDATION_DAY as F,NormativeOracle,sauce,askBowl,chooseRank,
 boundedCompositionFamily
} from "./normativeOracle.ts";
import {buildStage41CompatibleLegacyFixture,assert} from "./discovery21Fixtures.ts";

const rejects=(f:()=>unknown,T:typeof MonsterStageError|typeof MonsterValidationError)=>{
 try{f();}catch(e){return e instanceof T;}return false;
};
const old=new LegacyAllMonthLengthWays();
let exhaustiveRows=0;
for(let m=3;m<=5;m++){
 for(let extra=0;extra<=11;extra++){
  const L=4n*BigInt(m)+BigInt(extra);
  const virtual=new VirtualLegacyList(L,m);
  const nativeOld=old.oldAllWays(L,m);
  const oracle=boundedCompositionFamily(L,m,4n,123n);
  assert(virtual.count()===BigInt(nativeOld.length)&&
   virtual.count()===oracle.count(),"लहान family exact count");
  for(let i=1n;i<=virtual.count();i++){
   const actual=virtual.itemAt1(i);
   assert(actual.join(",")===nativeOld[Number(i-1n)]!.join(",")&&
      actual.join(",")===oracle.unrank1(i).join(","),
    "पूर्ण physical old lex आणि स्वतंत्र normative unrank");
   exhaustiveRows++;
  }
 }
}
const huge=new VirtualLegacyList(5349n,44);
const expectedHuge=956989856157389440798554542400n;
const hugeOracle=boundedCompositionFamily(5349n,44,4n,123n);
assert(huge.count()===expectedHuge&&huge.count()===hugeOracle.count(),
 "वास्तविक प्रचंड वर्षाच्या family ची स्वतंत्र exact count");
let hugeRanks=0;
for(const r of [1n,2n,(expectedHuge+1n)/2n,expectedHuge-1n,expectedHuge]){
 const item=huge.itemAt1(r);
 assert(item.join(",")===hugeOracle.unrank1(r).join(",")&&
  item.length===44&&item.reduce((a,b)=>a+b,0n)===5349n,
  "वर्षाच्या boundary/mid lex ranks अचूक");
 hugeRanks++;
}
assert(rejects(()=>new VirtualLegacyList(10n,3),MonsterValidationError)&&
 rejects(()=>huge.itemAt1(0n),MonsterValidationError)&&
 rejects(()=>huge.itemAt1(expectedHuge+1n),MonsterValidationError),
 "अवैध कुटुंब/rank अस्वीकार");
const f=buildStage41CompatibleLegacyFixture();
const previous=()=>new Discovery23FullHandler(new Patch22FullHandler(
 new Discovery22FullHandler(new Patch21CutletHandler(
 new Discovery21LegacyCutletHandler(new Patch20StructureSauceHandler(
 new Discovery20StructureSauceHandler(new Patch19YearCacheHandler())))))));
const maker=()=>new Patch23FullHandler(previous());
const full=patch23MonthLengths(maker(),f.request);
const c=f.cDay;
const L=f.oracleYear.closeGateDay-f.oracleYear.openGateDay;
const s=f.request.firstDaySauceQuestion!;
const oracleSauce=sauce(c,s.targetDay);
const normative=new NormativeOracle();
const m=normative.chooseMonthCount(oracleSauce,f.oracleYear);
const wanted=normative.chooseMonthLengths(oracleSauce,f.oracleYear,m);
const exactCount=boundedCompositionFamily(L,m,4n,123n).count();
const rank=chooseRank(askBowl(oracleSauce,3,31n),exactCount);
assert(full.source==="FULL_STAGE46_PATCH23_VIRTUAL_MONTH_LENGTHS"&&
 full.historical.context.status==="DISCOVERY_23_RECORDED"&&
 full.context.status==="PATCH_23_APPLIED"&&
 full.historical.months.historicalListAttempted&&
 full.historical.months.listBlocked&&
 full.corrected.correctedNativeSeal31.seal===31n&&
 full.corrected.correctedNativeSeal31.queriedBowlId===3&&
 full.corrected.correctedNativeSeal31.predecessorSharedWrites===58&&
 full.corrected.correctFamilySize===exactCount&&
 full.corrected.correctedRank===rank&&
 full.corrected.correctedLengths.join(",")===wanted.join(",")&&
 !full.corrected.historicalResultReused&&
 full.actualPredecessorCalls===full.historical.realPredecessorCalls+1&&
 full.actualSharedWrites===BigInt(full.actualPredecessorCalls)*58n,
 "Full Stage46 old path आणि खरा normative Seal31 correct");
const smallL=252n,smallM=3;
const smallFamily=new VirtualLegacyList(smallL,smallM);
assert(smallFamily.count()>0n,"वैध 252-day परिवार");
const ready=bootstrapMonster(c,f.request.historical.yearQuestion.targetDay);
const run=Patch14WideChoiceHandler.prototype.run;
let faults=0;
try{
 Patch14WideChoiceHandler.prototype.run=function(...args){
  if(args[5]===31n)throw Error("PATCH23_CORRECTED_SEAL31_FAULT");
  return run.apply(this,args);
 };
 try{maker().run(ready,f.request);throw Error("fault absent");}
 catch(e){assert(e instanceof Error&&e.message==="PATCH23_CORRECTED_SEAL31_FAULT",
  "deep native fault propagated");}
 assert(ready.status==="VALIDATED"&&
   ready.branchTrace.join(",")==="BOOTSTRAP_VALIDATE"&&
   ready.metrics.size===1,
   "late native fault does not change caller");
 faults++;
}finally{Patch14WideChoiceHandler.prototype.run=run;}
const retried=maker().run(ready,f.request);
assert(retried.context===ready&&
 rejects(()=>maker().run(ready,f.request),MonsterStageError)&&
 rejects(()=>calendarDateSpaghetti(F,F),MonsterStageError),
 "rollback/retry आणि Stage54 barrier");
const other=patch23MonthLengths(maker(),f.request);
assert(other.context!==full.context&&other.corrected!==full.corrected,
 "भिन्न semantic owners");
console.log("STAGE_47_PATCH_23_GUARDS_PASS"+
 " exhaustiveLexRows="+exhaustiveRows+" hugeRankSamples="+hugeRanks+
 " actualYearLength="+L+" monthCount="+m+" exactCount="+exactCount+
 " fullStage46=1 oldBlocked=1 correctedSeal31=1"+
 " rankWrong=0 chosenWrong=0 faultRecovery="+faults+
 " predecessorCalls="+full.actualPredecessorCalls+
 " sharedWrites="+full.actualSharedWrites+" stage54Blocked=1"+
 " archivedExpectedReds=23");
