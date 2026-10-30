import {
 Patch25PrefixOccurrenceCounter,Patch25FullHandler,Discovery25FullHandler,
 OldContiguousMonthDayGuess,Patch24ScalableFullHandler,Discovery24FullHandler,
 Patch23FullHandler,Discovery23FullHandler,Patch22FullHandler,
 Discovery22FullHandler,Patch21CutletHandler,Discovery21LegacyCutletHandler,
 Patch20StructureSauceHandler,Discovery20StructureSauceHandler,
 Patch19YearCacheHandler,Patch14WideChoiceHandler,bootstrapMonster,
 MonsterValidationError,MonsterStageError,patch25MonthDay,calendarDateSpaghetti
} from "../src/index.ts";
import {FOUNDATION_DAY as F} from "./normativeOracle.ts";
import {assert,buildStage41CompatibleLegacyFixture} from "./discovery21Fixtures.ts";
const counter=new Patch25PrefixOccurrenceCounter(),old=new OldContiguousMonthDayGuess();
const weaving=[1,2,1,2,1,2,1,3,2,3,3,3,3];
let repaired=0,equal=0;
for(let day=1;day<=weaving.length;day++){
 const result=counter.correct(weaving,old.oldContiguousMonthDayGuess(weaving,day));
 const oracle=weaving.slice(0,day).filter(x=>x===weaving[day-1]).length;
 assert(result.correctedDayInMonth===oracle&&result.monthId===weaving[day-1]&&
  result.actualPrefixOccurrenceCorrectionApplied&&
  Object.isFrozen(result)&&result.historical.historicalAlgorithm==="oldContiguousMonthDayGuess",
  "independent prefix oracle, immutable corrected result and legacy provenance");
 if(result.historicalEqualsCorrect)equal++;else repaired++;
}
assert(repaired>0&&equal>0&&
 counter.count(weaving,13)===5&&
 counter.count(weaving,9)===4&&
 old.oldContiguousMonthDayGuess(weaving,13).guessedDayInMonth===6,
 "noncontiguous month day corrected, legacy remains wrong");
let rejected=0;
for(const f of [
 ()=>counter.count(weaving,0),
 ()=>counter.count(weaving,weaving.length+1),
 ()=>counter.count([],1),
 ()=>counter.count([1,48],2),
 ()=>counter.correct(weaving,old.oldContiguousMonthDayGuess(weaving,1) as never
  && ({...old.oldContiguousMonthDayGuess(weaving,1),monthId:47} as never))
]){
 try{f();}catch(e){if(e instanceof MonsterValidationError)rejected++;}
}
assert(rejected===5,"invalid bounds/identity rejected");
const fixture=buildStage41CompatibleLegacyFixture();
const chain=()=>new Patch24ScalableFullHandler(new Discovery24FullHandler(
 new Patch23FullHandler(new Discovery23FullHandler(
 new Patch22FullHandler(new Discovery22FullHandler(
 new Patch21CutletHandler(new Discovery21LegacyCutletHandler(
 new Patch20StructureSauceHandler(
 new Discovery20StructureSauceHandler(new Patch19YearCacheHandler())
)))))))));
const maker=()=>new Patch25FullHandler(new Discovery25FullHandler(chain()));
const result=patch25MonthDay(maker(),fixture.request);
const legal=result.historical.historical.corrected.legalWeaving;
const selected=result.corrected;
const oracle=legal.filter(v=>v===selected.monthId).length;
assert(result.context.status==="PATCH_25_APPLIED"&&
 result.historical.context.status==="DISCOVERY_25_RECORDED"&&
 result.historical.historical.context.status==="PATCH_24_APPLIED"&&
 result.source==="FULL_STAGE50_PATCH25_PREFIX_OCCURRENCES"&&
 legal.length===5349&&selected.monthId===44&&
 selected.targetYearDay===5349&&
 selected.correctedDayInMonth===oracle&&
 selected.correctedDayInMonth===
  Number(result.historical.historical.corrected.historical.lengths[43])&&
 selected.correctedDayInMonth<selected.historical.guessedDayInMonth&&
 result.actualPredecessorCalls===61&&
 result.actualSharedWrites===3538n&&result.additionalNativeQueries===0,
 "real full Stage50 native chain and actual prefix correction");
const ready=bootstrapMonster(fixture.cDay,
 fixture.request.historical.yearQuestion.targetDay);
const real=Patch14WideChoiceHandler.prototype.run;
let called=0,faults=0;
try{
 Patch14WideChoiceHandler.prototype.run=function(...args){
  if(args[5]===32n&&++called===2)
   throw Error("PATCH25_DEEP_NATIVE_FAULT");
  return real.apply(this,args);
 };
 try{maker().run(ready,fixture.request);throw Error("fault not triggered");}
 catch(e){assert(e instanceof Error&&e.message==="PATCH25_DEEP_NATIVE_FAULT",
  "second real Seal32 fault propagates");}
 assert(called===2&&ready.status==="VALIDATED"&&
  ready.branchTrace.join(",")==="BOOTSTRAP_VALIDATE"&&ready.metrics.size===1,
  "caller isolated from predecessor failure");
 faults++;
}finally{Patch14WideChoiceHandler.prototype.run=real;}
assert(maker().run(ready,fixture.request).context===ready&&
 ready.status==="PATCH_25_APPLIED","retry commits exactly once");
let duplicated=false,stage54Blocked=false;
try{maker().run(ready,fixture.request);}catch(e){duplicated=e instanceof MonsterStageError;}
try{calendarDateSpaghetti(F,F);}catch(e){stage54Blocked=e instanceof MonsterStageError;}
assert(duplicated&&stage54Blocked,"single-use owner and Stage54 barrier retained");
console.log("STAGE_51_PATCH_25_GUARDS_PASS"+
 " days="+weaving.length+" repaired="+repaired+" equal="+equal+
 " invalid="+rejected+" realYearDays="+legal.length+
 " actual="+selected.correctedDayInMonth+
 " old="+selected.historical.guessedDayInMonth+
 " realNativeCalls="+result.actualPredecessorCalls+
 " sharedWrites="+result.actualSharedWrites+
 " additionalNative=0 deepFaults="+faults+" stage54Blocked=1");
