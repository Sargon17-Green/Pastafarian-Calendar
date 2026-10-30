import {
 LegacyNextDayMonthEndGuess,Discovery26FullHandler,Patch25FullHandler,
 Discovery25FullHandler,Patch24ScalableFullHandler,Discovery24FullHandler,
 Patch23FullHandler,Discovery23FullHandler,Patch22FullHandler,
 Discovery22FullHandler,Patch21CutletHandler,Discovery21LegacyCutletHandler,
 Patch20StructureSauceHandler,Discovery20StructureSauceHandler,
 Patch19YearCacheHandler,Patch14WideChoiceHandler,MonsterValidationError,
 MonsterStageError,bootstrapMonster,calendarDateSpaghetti,discoverLegacyMonthEnd
} from "../src/index.ts";
import {assert,buildStage41CompatibleLegacyFixture} from "./discovery21Fixtures.ts";
import {FOUNDATION_DAY as F} from "./normativeOracle.ts";
const legacy=new LegacyNextDayMonthEndGuess();
const weaving=[1,2,1,2,1,2,1,3,2,3,3,3,3];
const suffixOracle=(word:readonly number[],d:number)=>
 !word.slice(d).includes(word[d-1]!);
let wrong=0,controls=0;
for(const day of [1,2,8]){
 const out=legacy.guess(weaving,day);
 assert(out.guessedLastMonthOccurrence&&!suffixOracle(weaving,day)&&
  out.monthId===weaving[day-1]&&
  out.historicalAlgorithm==="oldNextDayMonthEndGuess"&&
  out.actualSuffixOracleApplied===false&&Object.isFrozen(out),
  "three declared legacy witnesses");
 wrong++;
}
for(const day of [7,13]){
 const out=legacy.guess(weaving,day);
 assert(out.guessedLastMonthOccurrence&&suffixOracle(weaving,day),
  "two independent correct controls");
 controls++;
}
assert(weaving.length===13&&wrong===3&&controls===2,
 "witness and control counts");
let rejected=0;
for(const f of [
 ()=>legacy.guess([],1),()=>legacy.guess(weaving,0),
 ()=>legacy.guess(weaving,14),()=>legacy.guess([1,48],2),
 ()=>legacy.guess([0,1],1),()=>legacy.guess([1,2],1.5)
]){
 try{f();}catch(e){if(e instanceof MonsterValidationError)rejected++;}
}
assert(rejected===6,"invalid weaving and bounds rejected");
assert([1,2,3,4].every(day=>legacy.guess([3,3,3,3],day)
 .guessedLastMonthOccurrence===(day===4)),"single-month boundary");
const irregular=[2,1,2,3,1,3,2];
assert(irregular.every((_,i)=>legacy.guess(irregular,i+1)
 .guessedLastMonthOccurrence===(i===irregular.length-1||
 irregular[i+1]!==irregular[i])),"irregular next-day diagnostic");
const fixture=buildStage41CompatibleLegacyFixture();
const chain=()=>new Patch24ScalableFullHandler(new Discovery24FullHandler(
 new Patch23FullHandler(new Discovery23FullHandler(
 new Patch22FullHandler(new Discovery22FullHandler(
 new Patch21CutletHandler(new Discovery21LegacyCutletHandler(
 new Patch20StructureSauceHandler(
 new Discovery20StructureSauceHandler(new Patch19YearCacheHandler())
)))))))));
const maker=()=>new Discovery26FullHandler(
 new Patch25FullHandler(new Discovery25FullHandler(chain())));
const full=discoverLegacyMonthEnd(maker(),fixture.request);
const legal=full.historical.historical.historical.corrected.legalWeaving;
assert(full.context.status==="DISCOVERY_26_RECORDED"&&
 full.historical.context.status==="PATCH_25_APPLIED"&&
 full.historical.historical.context.status==="DISCOVERY_25_RECORDED"&&
 full.historical.historical.historical.context.status==="PATCH_24_APPLIED"&&
 full.source==="FULL_STAGE51_DISCOVERY26_LEGACY_MONTH_END_DIAGNOSTIC"&&
 legal.length===5349&&
 full.guessed.targetYearDay===5349&&full.guessed.monthId===44&&
 full.guessed.guessedLastMonthOccurrence&&suffixOracle(legal,5349)&&
 full.historical.corrected.correctedDayInMonth===5&&
 full.actualPredecessorCalls===61&&
 full.actualSharedWrites===3538n&&full.additionalNativeQueries===0&&
 full.context.metrics.get("discovery26.additional_native_queries")===0n,
 "full Stage51 Native predecessor and last-day observation");
const ready=bootstrapMonster(fixture.cDay,
 fixture.request.historical.yearQuestion.targetDay);
const real=Patch14WideChoiceHandler.prototype.run;
let calls=0,faults=0;
try{
 Patch14WideChoiceHandler.prototype.run=function(...args){
  if(args[5]===32n&&++calls===2)
   throw Error("DISCOVERY26_SECOND_SEAL32_FAULT");
  return real.apply(this,args);
 };
 try{maker().run(ready,fixture.request);throw Error("fault not triggered");}
 catch(e){assert(e instanceof Error&&e.message==="DISCOVERY26_SECOND_SEAL32_FAULT",
  "injected full-chain fault propagated");}
 assert(calls===2&&ready.status==="VALIDATED"&&
  ready.branchTrace.join(",")==="BOOTSTRAP_VALIDATE"&&ready.metrics.size===1,
  "rollback leaves caller owner untouched");
 faults++;
}finally{Patch14WideChoiceHandler.prototype.run=real;}
assert(maker().run(ready,fixture.request).context===ready&&
 ready.status==="DISCOVERY_26_RECORDED",
 "retry with new chain succeeds");
let duplicate=false,finalBlocked=false;
try{maker().run(ready,fixture.request);}catch(e){duplicate=e instanceof MonsterStageError;}
try{calendarDateSpaghetti(F,F);}catch(e){finalBlocked=e instanceof MonsterStageError;}
assert(duplicate&&finalBlocked,"duplicate owner and final-date barrier");
console.log("STAGE_52_DISCOVERY_26_GUARDS_PASS declaredRed="+wrong+
 " controls="+controls+" invalid="+rejected+" realYearDays="+legal.length+
 " nativeCalls="+full.actualPredecessorCalls+
 " sharedWrites="+full.actualSharedWrites+
 " additionalNative=0 deepFaults="+faults+" finalBlocked=1");
