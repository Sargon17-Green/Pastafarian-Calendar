import {
 Discovery27FullHandler,LegacyMonthSpanMembershipGuess,Patch26FullHandler,
 Discovery26FullHandler,Patch25FullHandler,Discovery25FullHandler,
 Patch24ScalableFullHandler,Discovery24FullHandler,Patch23FullHandler,
 Discovery23FullHandler,Patch22FullHandler,Discovery22FullHandler,
 Patch21CutletHandler,Discovery21LegacyCutletHandler,
 Patch20StructureSauceHandler,Discovery20StructureSauceHandler,
 Patch19YearCacheHandler,Patch14WideChoiceHandler,MonsterValidationError,
 MonsterStageError,bootstrapMonster,calendarDateSpaghetti,discoverLegacyMonthSpan
} from "../src/index.ts";
import {assert,buildStage41CompatibleLegacyFixture} from "./discovery21Fixtures.ts";
import {FOUNDATION_DAY as F} from "./normativeOracle.ts";
const fixture=buildStage41CompatibleLegacyFixture();
const chain=()=>new Patch24ScalableFullHandler(new Discovery24FullHandler(
 new Patch23FullHandler(new Discovery23FullHandler(
 new Patch22FullHandler(new Discovery22FullHandler(
 new Patch21CutletHandler(new Discovery21LegacyCutletHandler(
 new Patch20StructureSauceHandler(
 new Discovery20StructureSauceHandler(new Patch19YearCacheHandler())
)))))))));
const maker=()=>new Discovery27FullHandler(new Patch26FullHandler(
 new Discovery26FullHandler(new Patch25FullHandler(
 new Discovery25FullHandler(chain())))));
const guesser=new LegacyMonthSpanMembershipGuess();
const full=discoverLegacyMonthSpan(maker(),fixture.request,44,5349);
const legal=full.historical.historical.historical.historical.historical.corrected.legalWeaving;
assert(full.context.status==="DISCOVERY_27_RECORDED"&&
 full.historical.context.status==="PATCH_26_APPLIED"&&
 full.historical.historical.context.status==="DISCOVERY_26_RECORDED"&&
 full.historical.historical.historical.context.status==="PATCH_25_APPLIED"&&
 full.historical.corrected.actualSuffixOccurrenceCorrectionApplied&&
 full.source==="FULL_STAGE53_DISCOVERY27_LEGACY_SPAN_DIAGNOSTIC"&&
 legal.length===5349&&full.historical.corrected.monthId===44&&
 legal[5348]===44&&full.guessed.guessedMonthMembership&&
 full.guessed.actualDirectMembershipOracleApplied===false&&
 full.actualPredecessorCalls===61&&full.actualSharedWrites===3538n&&
 full.additionalNativeQueries===0&&
 full.context.metrics.get("discovery27.additional_native_queries")===0n,
 "complete Stage53 Native lineage, no additional queries");
let invalid=0;
for(const probe of [
 ()=>guesser.guess([],1,1),()=>guesser.guess([1,48],1,1),
 ()=>guesser.guess([0,1],1,1),()=>guesser.guess([1],0,1),
 ()=>guesser.guess([1],48,1),()=>guesser.guess([1],1,0),
 ()=>guesser.guess([1],1,2),()=>guesser.guess([1],1,1.5)
]){
 try{probe();}catch(e){if(e instanceof MonsterValidationError)invalid++;}
}
assert(invalid===8&&
 !guesser.guess([1,2,1],47,2).guessedMonthMembership&&
 guesser.guess([2,2,2],2,2).guessedMonthMembership,
 "absent, single-month and invalid query guards");
const month=44,first=legal.indexOf(month),last=legal.lastIndexOf(month);
let members=0,realGaps=0,realWrongReject=0,firstGap=0;
for(let d=1;d<=legal.length;d++){
 const direct=legal[d-1]===month; // independent oracle: equality only
 if(direct)members++;
 const span=d-1>=first&&d-1<=last&&first>=0;
 if(span&&!direct){realGaps++;if(firstGap===0)firstGap=d;}
 if(!span&&direct)realWrongReject++;
}
assert(members===123&&realWrongReject===0&&realGaps>0&&
 firstGap>first+1&&firstGap<last+1&&
 guesser.guess(legal,month,firstGap).guessedMonthMembership&&
 legal[firstGap-1]!==month,
 "observed real Year5000 internal month hole, no invented result");
const ready=bootstrapMonster(fixture.cDay,
 fixture.request.historical.yearQuestion.targetDay);
const original=Patch14WideChoiceHandler.prototype.run;
let calls=0,faults=0;
try{
 Patch14WideChoiceHandler.prototype.run=function(...args){
  if(args[5]===32n&&++calls===2)throw Error("DISCOVERY27_SECOND_SEAL32_FAULT");
  return original.apply(this,args);
 };
 try{maker().run(ready,fixture.request,44,5349);throw Error("not injected");}
 catch(e){assert(e instanceof Error&&e.message==="DISCOVERY27_SECOND_SEAL32_FAULT",
  "deep full-native failure propagated");}
 assert(calls===2&&ready.status==="VALIDATED"&&
  ready.branchTrace.join(",")==="BOOTSTRAP_VALIDATE"&&ready.metrics.size===1,
  "external owner unchanged by failed internal Native operation");
 faults++;
}finally{Patch14WideChoiceHandler.prototype.run=original;}
assert(maker().run(ready,fixture.request,44,5349).context===ready&&
 ready.status==="DISCOVERY_27_RECORDED","retry succeeds once");
let duplicate=false,finalBlocked=false;
try{maker().run(ready,fixture.request,44,5349);}
catch(e){duplicate=e instanceof MonsterStageError;}
try{calendarDateSpaghetti(F,F);}
catch(e){finalBlocked=e instanceof MonsterStageError;}
assert(duplicate&&finalBlocked,"duplicate owner and final date remain blocked");
console.log("STAGE_54_DISCOVERY_27_FULL_NATIVE_PASS realYearDays="+legal.length+
 " realMonth="+month+" realMembers="+members+" realInternalHoles="+realGaps+
 " realFirstHole="+firstGap+" realWrongReject="+realWrongReject+
 " nativeCalls="+full.actualPredecessorCalls+" sharedWrites="+full.actualSharedWrites+
 " additionalNative=0 invalid="+invalid+" deepFaults="+faults+" finalBlocked=1");
