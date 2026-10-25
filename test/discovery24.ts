import {
 LegacyIndependentDailyMonthChooser,auditLegacyWeaving,
 Discovery24FullHandler,Patch23FullHandler,Discovery23FullHandler,
 Patch22FullHandler,Discovery22FullHandler,Patch21CutletHandler,
 Discovery21LegacyCutletHandler,Patch20StructureSauceHandler,
 Discovery20StructureSauceHandler,Patch19YearCacheHandler,
 Patch14WideChoiceHandler,bootstrapMonster,MonsterStageError,
 MonsterValidationError,calendarDateSpaghetti,
 discoverLegacyIndependentDailyMonths
} from "../src/index.ts";
import {FOUNDATION_DAY as F,sauce,askBowl,chooseRank,weavingFamily}
 from "./normativeOracle.ts";
import {assert,buildStage41CompatibleLegacyFixture}
 from "./discovery21Fixtures.ts";
const rejects=(f:()=>unknown,T:typeof MonsterStageError|typeof MonsterValidationError)=>{
 try{f();}catch(e){return e instanceof T;}return false;
};
const lengths=[4n,4n,5n],old=new LegacyIndependentDailyMonthChooser();
const oracle=weavingFamily(lengths);
const legalCount=oracle.count();
assert(legalCount>0n&&legalCount<100000n,"bounded normative weaving");
let legalChecked=0;
for(let r=1n;r<=legalCount;r++){
 assert(auditLegacyWeaving(lengths,oracle.unrank1(r)).legal,
  "every independent normative sequence must be legal");
 legalChecked++;
}
let historicalWrong=0;
for(let rank=1n;rank<=3n;rank++){
 const ghost=old.legacyChooseEachDaySeparately(lengths,rank);
 const audited=auditLegacyWeaving(lengths,ghost);
 assert(ghost.length===13&&!audited.legal,
  "historical independent daily month choice violates a legal invariant");
 historicalWrong++;
}
assert(rejects(()=>old.legacyChooseEachDaySeparately(lengths,0n),MonsterValidationError)&&
 rejects(()=>auditLegacyWeaving(lengths,[1,2]),MonsterValidationError),
 "wrong ghost arguments rejected");
const f=buildStage41CompatibleLegacyFixture();
const before=()=>new Patch23FullHandler(new Discovery23FullHandler(
 new Patch22FullHandler(new Discovery22FullHandler(new Patch21CutletHandler(
 new Discovery21LegacyCutletHandler(new Patch20StructureSauceHandler(
 new Discovery20StructureSauceHandler(new Patch19YearCacheHandler()))))))));
const maker=()=>new Discovery24FullHandler(before());
const full=discoverLegacyIndependentDailyMonths(maker(),f.request);
const c=f.cDay,first=f.request.firstDaySauceQuestion!;
const structure=sauce(c,first.targetDay);
const m=full.historical.corrected.correctedLengths.length;
const referenceRank=chooseRank(askBowl(structure,4,32n),BigInt(m));
const expected=old.legacyChooseEachDaySeparately(
 full.historical.corrected.correctedLengths,referenceRank);
assert(full.context.status==="DISCOVERY_24_RECORDED"&&
 full.historical.context.status==="PATCH_23_APPLIED"&&
 full.source==="FULL_STAGE47_LEGACY_INDEPENDENT_DAILY_MONTHS"&&
 full.historical.corrected.correctedNativeSeal31.seal===31n&&
 full.weaving.historicalMonthIdChoice.queriedBowlId===4&&
 full.weaving.historicalMonthIdChoice.seal===32n&&
 full.weaving.historicalMonthIdChoice.predecessorSharedWrites===58&&
 full.weaving.historicalMonthIdChoice.correctedRank===referenceRank&&
 full.weaving.ghost.join(",")===expected.join(",")&&
 full.weaving.historicalDailyDecisions===expected.length&&
 !full.weaving.audit.legal&&!full.weaving.correctedLegalWeavingApplied&&
 full.realPredecessorCalls===full.historical.actualPredecessorCalls+1&&
 full.realSharedWrites===BigInt(full.realPredecessorCalls)*58n,
 "real year, full Stage47 and genuine Bowl4 Seal32 wrong ghost");
const ready=bootstrapMonster(c,f.request.historical.yearQuestion.targetDay);
const original=Patch14WideChoiceHandler.prototype.run;
let faults=0;
try{
 Patch14WideChoiceHandler.prototype.run=function(...args){
  if(args[5]===32n)throw Error("DISCOVERY24_REAL_SEAL32_FAULT");
  return original.apply(this,args);
 };
 try{maker().run(ready,f.request);throw Error("no fault");}
 catch(e){assert(e instanceof Error&&e.message==="DISCOVERY24_REAL_SEAL32_FAULT",
 "deep native Bowl4 fault propagated");}
 assert(ready.status==="VALIDATED"&&ready.branchTrace.join(",")==="BOOTSTRAP_VALIDATE"&&
  ready.metrics.size===1,"caller owner rollback");faults++;
}finally{Patch14WideChoiceHandler.prototype.run=original;}
assert(maker().run(ready,f.request).context===ready&&
 rejects(()=>maker().run(ready,f.request),MonsterStageError)&&
 rejects(()=>calendarDateSpaghetti(F,F),MonsterStageError)&&
 discoverLegacyIndependentDailyMonths(maker(),f.request).context!==full.context,
 "retry, owner isolation, and Stage54 barrier");
console.log("STAGE_48_DISCOVERY_24_GUARDS_PASS"+
 " smallLegalRows="+legalChecked+" syntheticWrong="+historicalWrong+
 " realYearDays="+expected.length+" realYearMonthCount="+m+
 " realGhostWrong=1 nativeSeal32=1"+
 " realSharedWrites="+full.realSharedWrites+
 " fullStage47=1 deepFaults="+faults+" stage49FixApplied=0"+
 " archivedExpectedReds=23 stage54Blocked=1");
