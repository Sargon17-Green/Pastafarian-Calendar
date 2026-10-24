import {
 LegacyAllMonthLengthWays,LegacyMonthListLimit,
 Discovery23FullHandler,Discovery23MonthLengthSelector,
 Discovery22FullHandler,Patch22FullHandler,
 Patch21CutletHandler,Discovery21LegacyCutletHandler,
 Patch20StructureSauceHandler,Discovery20StructureSauceHandler,
 Patch19YearCacheHandler,Patch14WideChoiceHandler,
 discoverLegacyMonthLengthList,bootstrapMonster,MonsterStageError,
 MonsterValidationError,calendarDateSpaghetti
} from "../src/index.ts";
import {FOUNDATION_DAY as F,NormativeOracle,sauce,askBowl,
 chooseRank,boundedCompositionFamily} from "./normativeOracle.ts";
import {buildStage41CompatibleLegacyFixture,assert} from "./discovery21Fixtures.ts";
function rejected(f:()=>unknown,T:typeof MonsterStageError|typeof MonsterValidationError){
 try{f();}catch(e){return e instanceof T;}return false;
}
const old=new LegacyAllMonthLengthWays();
const simple=old.oldAllWays(15n,3);
const normative=boundedCompositionFamily(15n,3,4n,123n);
assert(simple.length===10&&normative.count()===10n&&
 simple.every((r,i)=>r.join(",")===normative.unrank1(BigInt(i+1)).join(","))&&
 simple[0]!.join(",")==="4,4,7"&&
 simple[9]!.join(",")==="7,4,4",
 "खरा oldAllWays 10 rows lex ordered independent canonical family");
const giganticL=211n,giganticM=47;
const lower=old.demonstrableLowerBound(giganticL,giganticM);
let prevented=0;
try{old.oldAllWays(giganticL,giganticM);}
catch(e){
 assert(e instanceof LegacyMonthListLimit&&
  e.observedRows===0&&e.lowerBound===lower&&
  e.minimallyRequiredBytes===lower*376n,
  "oversized original explicit list blocked BEFORE allocation");prevented++;
}
assert(prevented===1&&lower>100000n&&
 boundedCompositionFamily(giganticL,giganticM,4n,123n).count()>=lower,
 "mathematical enormous-family proof is a valid actual subset");
assert(rejected(()=>old.oldAllWays(10n,3),MonsterValidationError)&&
 rejected(()=>new LegacyAllMonthLengthWays(-1),MonsterValidationError),
 "invalid legacy bounds rejected");
const f=buildStage41CompatibleLegacyFixture();
const maker=()=>new Discovery23FullHandler(new Patch22FullHandler(
 new Discovery22FullHandler(new Patch21CutletHandler(
 new Discovery21LegacyCutletHandler(new Patch20StructureSauceHandler(
 new Discovery20StructureSauceHandler(new Patch19YearCacheHandler()))))));
const full=discoverLegacyMonthLengthList(maker(),f.request);
const c=f.cDay;
const L=f.oracleYear.closeGateDay-f.oracleYear.openGateDay;
const first=f.request.firstDaySauceQuestion!;
const refSauce=sauce(c,first.targetDay);
const mRef=new NormativeOracle().chooseMonthCount(refSauce,f.oracleYear);
const bounded=boundedCompositionFamily(L,mRef,4n,123n);
const exactN=bounded.count();
assert(full.source==="FULL_STAGE45_LEGACY_MONTH_LENGTH_LIST"&&
 full.context.status==="DISCOVERY_23_RECORDED"&&
 full.historical.context.status==="PATCH_22_APPLIED"&&
 full.months.L===L&&
 full.months.selectedMonthCount===mRef&&
 full.months.monthCountChoice.seal===30n&&
 full.months.monthCountChoice.queriedBowlId===3&&
 full.months.monthCountChoice.predecessorSharedWrites===58&&
 full.months.historicalListAttempted&&
 full.months.historicalPhysicalEnumeration&&
 full.months.demonstrableLowerBound<=exactN&&
 full.months.listBlocked===(exactN>BigInt(full.months.safeMaxRows))&&
 full.realPredecessorCalls===full.historical.actualPredecessorCalls+
   full.months.additionalNativeSauceCalls&&
 full.realSharedWrites===BigInt(full.realPredecessorCalls)*58n,
 "true full Stage45 history and real Bowl3 month count + physical old listing");
if(full.months.listBlocked){
 assert(full.months.originalRows===null&&
  full.months.historicalMonthLengthChoice===null&&
  full.months.oldSeal31ActualCalls===0&&
  full.months.blockReason!==null,
  "original huge-list failure remains visible, not normalized to fake rank");
}else{
 const rows=full.months.originalRows!;
 const rank=chooseRank(askBowl(refSauce,3,31n),BigInt(rows.length));
 assert(full.months.oldSeal31ActualCalls===1&&
  full.months.historicalMonthLengthChoice!.correctedRank===rank&&
  full.months.historicalChosenLengths!.join(",")===
   bounded.unrank1(rank).join(","),
  "small true month-length list selects native Bowl3 seal31");
}
const ready=bootstrapMonster(c,f.request.historical.yearQuestion.targetDay);
const oldRun=Patch14WideChoiceHandler.prototype.run;
let faulted=0;
try{
 Patch14WideChoiceHandler.prototype.run=function(...args){
  if(args[5]===30n)throw Error("DISCOVERY23_REAL_SEAL30_FAULT");
  return oldRun.apply(this,args);
 };
 try{maker().run(ready,f.request);throw Error("no fault");}
 catch(e){assert(e instanceof Error&&e.message==="DISCOVERY23_REAL_SEAL30_FAULT",
  "late fault propagated");}
 assert(ready.status==="VALIDATED"&&
  ready.branchTrace.join(",")==="BOOTSTRAP_VALIDATE"&&ready.metrics.size===1,
  "late failure retains caller semantic state");faulted++;
}finally{Patch14WideChoiceHandler.prototype.run=oldRun;}
assert(maker().run(ready,f.request).context===ready&&
 rejected(()=>maker().run(ready,f.request),MonsterStageError)&&
 rejected(()=>calendarDateSpaghetti(F,F),MonsterStageError),
 "retry commits exactly once; Stage54 remains inaccessible");
console.log("STAGE_46_DISCOVERY_23_GUARDS_PASS"+
 " smallLexRows="+simple.length+" syntheticHugeLowerBound="+lower+
 " preflightBlocked="+prevented+" nativeFullStage45=1"+
 " yearLength="+L+" monthCount="+mRef+
 " oldCountFromTestOracle="+exactN+
 " realOldListBlocked="+Number(full.months.listBlocked)+
 " lateFaults="+faulted+" stage47VirtualFixApplied=0");
