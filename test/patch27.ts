import {
 Patch27DirectMembershipChecker,Patch27FullHandler,Discovery27FullHandler,
 LegacyMonthSpanMembershipGuess,Patch26FullHandler,Discovery26FullHandler,
 Patch25FullHandler,Discovery25FullHandler,Patch24ScalableFullHandler,
 Discovery24FullHandler,Patch23FullHandler,Discovery23FullHandler,
 Patch22FullHandler,Discovery22FullHandler,Patch21CutletHandler,
 Discovery21LegacyCutletHandler,Patch20StructureSauceHandler,
 Discovery20StructureSauceHandler,Patch19YearCacheHandler,
 Patch14WideChoiceHandler,bootstrapMonster,MonsterStageError,
 MonsterValidationError,calendarDateSpaghetti,patch27MonthMembership
} from "../src/index.ts";
import {assert,buildStage41CompatibleLegacyFixture} from "./discovery21Fixtures.ts";
import {FOUNDATION_DAY as F} from "./normativeOracle.ts";

const checker=new Patch27DirectMembershipChecker();
const guesser=new LegacyMonthSpanMembershipGuess();
const word=[1,2,1,2,1,2,1,3,2,3,3,3,3];
let repaired=0,equal=0,members=0,wrongReject=0;
for(let month=1;month<=3;month++)
 for(let day=1;day<=word.length;day++){
  const old=guesser.guess(word,month,day);
  const correct=checker.correct(word,old);
  const oracle=word[day-1]===month;
  assert(correct.correctedMonthMembership===oracle&&
   correct.historical===old&&correct.actualDirectMembershipCorrectionApplied&&
   correct.historicalEqualsCorrect===(old.guessedMonthMembership===oracle)&&
   Object.isFrozen(correct)&&old.actualDirectMembershipOracleApplied===false,
   "independent direct oracle and immutable legacy provenance");
  if(oracle)members++;
  if(!old.guessedMonthMembership&&oracle)wrongReject++;
  if(correct.historicalEqualsCorrect)equal++;else repaired++;
 }
assert(repaired===8&&equal===31&&members===word.length&&wrongReject===0&&
 !checker.isMember(word,1,2)&&checker.isMember(word,1,3)&&
 !checker.isMember(word,47,3),"13-day dispersed membership witness");
let invalid=0;
const valid=guesser.guess(word,1,2);
for(const probe of [
 ()=>checker.isMember([],1,1),
 ()=>checker.isMember([1,48],1,1),
 ()=>checker.isMember([0,1],1,1),
 ()=>checker.isMember(word,0,1),
 ()=>checker.isMember(word,48,1),
 ()=>checker.isMember(word,1,0),
 ()=>checker.isMember(word,1,14),
 ()=>checker.isMember(word,1,1.5),
 ()=>checker.correct(word,{...valid,firstYearDay:2}),
 ()=>checker.correct(word,{...valid,guessedMonthMembership:false}),
 ()=>checker.correct(word,{...valid,actualDirectMembershipOracleApplied:true as unknown as false})
]){
 try{probe();}catch(e){if(e instanceof MonsterValidationError)invalid++;}
}
assert(invalid===11,"invalid ranges and forged Stage54 history rejected");

const fixture=buildStage41CompatibleLegacyFixture();
const chain=()=>new Patch24ScalableFullHandler(new Discovery24FullHandler(
 new Patch23FullHandler(new Discovery23FullHandler(
 new Patch22FullHandler(new Discovery22FullHandler(
 new Patch21CutletHandler(new Discovery21LegacyCutletHandler(
 new Patch20StructureSauceHandler(
 new Discovery20StructureSauceHandler(new Patch19YearCacheHandler())
 )))))))));
const maker=()=>new Patch27FullHandler(new Discovery27FullHandler(
 new Patch26FullHandler(new Discovery26FullHandler(
 new Patch25FullHandler(new Discovery25FullHandler(chain()))))));
const full=patch27MonthMembership(maker(),fixture.request,44,239);
const legal=
 full.historical.historical.historical.historical.historical.historical.corrected.legalWeaving;
const first=legal.indexOf(44)+1,last=legal.lastIndexOf(44)+1;
let realMembers=0,holes=0,wrongRejectReal=0;
for(let day=1;day<=legal.length;day++){
 const direct=legal[day-1]===44;
 const span=day>=first&&day<=last;
 if(direct)realMembers++;
 if(span&&!direct)holes++;
 if(!span&&direct)wrongRejectReal++;
}
assert(full.context.status==="PATCH_27_APPLIED"&&
 full.historical.context.status==="DISCOVERY_27_RECORDED"&&
 full.historical.historical.context.status==="PATCH_26_APPLIED"&&
 full.historical.historical.historical.context.status==="DISCOVERY_26_RECORDED"&&
 full.historical.guessed.guessedMonthMembership&&
 !full.corrected.correctedMonthMembership&&
 !full.corrected.historicalEqualsCorrect&&
 full.corrected.actualDirectMembershipCorrectionApplied&&
 full.corrected.historical===full.historical.guessed&&
 legal.length===5349&&legal[238]!==44&&realMembers===123&&
 holes===4989&&wrongRejectReal===0&&
 checker.isMember(legal,44,5349)&&
 full.actualPredecessorCalls===61&&full.actualSharedWrites===3538n&&
 full.additionalNativeQueries===0&&
 full.context.metrics.get("patch27.additional_native_queries")===0n&&
 full.source==="FULL_STAGE54_PATCH27_DIRECT_MONTH_MEMBERSHIP",
 "real Year5000 gap repaired on full historical Native chain");
const ready=bootstrapMonster(fixture.cDay,
 fixture.request.historical.yearQuestion.targetDay);
const original=Patch14WideChoiceHandler.prototype.run;
let calls=0,faults=0;
try{
 Patch14WideChoiceHandler.prototype.run=function(...args){
  if(args[5]===32n&&++calls===2)throw Error("PATCH27_SECOND_SEAL32_FAULT");
  return original.apply(this,args);
 };
 try{maker().run(ready,fixture.request,44,239);throw Error("fault not injected");}
 catch(e){assert(e instanceof Error&&e.message==="PATCH27_SECOND_SEAL32_FAULT",
  "deep fault must propagate");}
 assert(calls===2&&ready.status==="VALIDATED"&&
  ready.branchTrace.join(",")==="BOOTSTRAP_VALIDATE"&&ready.metrics.size===1,
  "failed historical Native chain leaves external owner pristine");
 faults++;
}finally{Patch14WideChoiceHandler.prototype.run=original;}
assert(maker().run(ready,fixture.request,44,239).context===ready&&
 ready.status==="PATCH_27_APPLIED","retry on original owner succeeds");
let duplicate=false,finalBlocked=false;
try{maker().run(ready,fixture.request,44,239);}
catch(e){duplicate=e instanceof MonsterStageError;}
try{calendarDateSpaghetti(F,F);}
catch(e){finalBlocked=e instanceof MonsterStageError;}
assert(duplicate&&finalBlocked,"duplicate owner and final-date barrier");
console.log("STAGE_55_PATCH_27_GUARDS_PASS syntheticCases="+(repaired+equal)+
 " syntheticRepaired="+repaired+" syntheticEqual="+equal+
 " invalid="+invalid+" realYearDays="+legal.length+
 " realMembers="+realMembers+" realHoles="+holes+
 " realWrongReject="+wrongRejectReal+
 " nativeCalls="+full.actualPredecessorCalls+
 " sharedWrites="+full.actualSharedWrites+
 " additionalNative=0 deepFaults="+faults+" finalBlocked=1");
