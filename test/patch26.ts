import {
 Patch26SuffixOccurrenceChecker,Patch26FullHandler,Discovery26FullHandler,
 LegacyNextDayMonthEndGuess,Patch25FullHandler,Discovery25FullHandler,
 Patch24ScalableFullHandler,Discovery24FullHandler,Patch23FullHandler,
 Discovery23FullHandler,Patch22FullHandler,Discovery22FullHandler,
 Patch21CutletHandler,Discovery21LegacyCutletHandler,Patch20StructureSauceHandler,
 Discovery20StructureSauceHandler,Patch19YearCacheHandler,Patch14WideChoiceHandler,
 bootstrapMonster,MonsterValidationError,MonsterStageError,patch26MonthEnd,
 calendarDateSpaghetti
} from "../src/index.ts";
import {FOUNDATION_DAY as F} from "./normativeOracle.ts";
import {assert,buildStage41CompatibleLegacyFixture} from "./discovery21Fixtures.ts";
const checker=new Patch26SuffixOccurrenceChecker();
const legacy=new LegacyNextDayMonthEndGuess();
const word=[1,2,1,2,1,2,1,3,2,3,3,3,3];
const oracle=(d:number)=>!word.slice(d).includes(word[d-1]!);
let repaired=0,equal=0,last=0;
for(let day=1;day<=word.length;day++){
 const old=legacy.guess(word,day);
 const corrected=checker.correct(word,old);
 assert(corrected.correctedLastMonthOccurrence===oracle(day)&&
  corrected.monthId===word[day-1]&&corrected.historical===old&&
  corrected.actualSuffixOccurrenceCorrectionApplied&&Object.isFrozen(corrected),
  "independent suffix oracle and immutable historical provenance");
 if(corrected.historicalEqualsCorrect)equal++;else repaired++;
 if(corrected.correctedLastMonthOccurrence)last++;
}
assert(repaired===7&&equal===6&&last===3&&checker.isLast(word,7)&&
 checker.isLast(word,9)&&checker.isLast(word,13)&&!checker.isLast(word,8),
 "noncontiguous month-end corrected without changing legacy");
let invalid=0;
for(const f of [
 ()=>checker.isLast([],1),()=>checker.isLast(word,0),
 ()=>checker.isLast(word,14),()=>checker.isLast([1,48],2),
 ()=>checker.isLast([0,1],1),()=>checker.isLast(word,1.5),
 ()=>checker.correct(word,{...legacy.guess(word,1),monthId:47})
]){
 try{f();}catch(e){if(e instanceof MonsterValidationError)invalid++;}
}
assert(invalid===7,"bad bounds and forged history rejected");
const fixture=buildStage41CompatibleLegacyFixture();
const chain=()=>new Patch24ScalableFullHandler(new Discovery24FullHandler(
 new Patch23FullHandler(new Discovery23FullHandler(
 new Patch22FullHandler(new Discovery22FullHandler(
 new Patch21CutletHandler(new Discovery21LegacyCutletHandler(
 new Patch20StructureSauceHandler(
 new Discovery20StructureSauceHandler(new Patch19YearCacheHandler())
)))))))));
const maker=()=>new Patch26FullHandler(new Discovery26FullHandler(
 new Patch25FullHandler(new Discovery25FullHandler(chain()))));
const full=patch26MonthEnd(maker(),fixture.request);
const legal=full.historical.historical.historical.historical.corrected.legalWeaving;
const actual=legal.filter(v=>v===full.corrected.monthId).length;
assert(full.context.status==="PATCH_26_APPLIED"&&
 full.historical.context.status==="DISCOVERY_26_RECORDED"&&
 full.historical.historical.context.status==="PATCH_25_APPLIED"&&
 full.historical.historical.historical.context.status==="DISCOVERY_25_RECORDED"&&
 full.source==="FULL_STAGE52_PATCH26_SUFFIX_OCCURRENCES"&&
 legal.length===5349&&full.corrected.monthId===44&&
 full.corrected.targetYearDay===5349&&
 full.corrected.correctedLastMonthOccurrence&&
 full.corrected.historicalEqualsCorrect&&
 actual===123&&full.historical.historical.corrected.correctedDayInMonth===actual&&
 full.actualPredecessorCalls===61&&full.actualSharedWrites===3538n&&
 full.additionalNativeQueries===0&&
 full.context.metrics.get("patch26.additional_native_queries")===0n,
 "full Stage52 Native chain and correct final month occurrence");
const ready=bootstrapMonster(fixture.cDay,
 fixture.request.historical.yearQuestion.targetDay);
const real=Patch14WideChoiceHandler.prototype.run;
let calls=0,faults=0;
try{
 Patch14WideChoiceHandler.prototype.run=function(...args){
  if(args[5]===32n&&++calls===2)throw Error("PATCH26_SECOND_SEAL32_FAULT");
  return real.apply(this,args);
 };
 try{maker().run(ready,fixture.request);throw Error("fault not triggered");}
 catch(e){assert(e instanceof Error&&e.message==="PATCH26_SECOND_SEAL32_FAULT",
  "true native fault propagated");}
 assert(calls===2&&ready.status==="VALIDATED"&&
  ready.branchTrace.join(",")==="BOOTSTRAP_VALIDATE"&&ready.metrics.size===1,
  "rollback keeps external owner pristine");
 faults++;
}finally{Patch14WideChoiceHandler.prototype.run=real;}
assert(maker().run(ready,fixture.request).context===ready&&
 ready.status==="PATCH_26_APPLIED","retry finishes exactly once");
let duplicate=false,finalBlocked=false;
try{maker().run(ready,fixture.request);}catch(e){duplicate=e instanceof MonsterStageError;}
try{calendarDateSpaghetti(F,F);}catch(e){finalBlocked=e instanceof MonsterStageError;}
assert(duplicate&&finalBlocked,"duplicate owner and final date barrier");
console.log("STAGE_53_PATCH_26_GUARDS_PASS days="+word.length+
 " repaired="+repaired+" equal="+equal+" invalid="+invalid+
 " realYearDays="+legal.length+" realMonthLastCount="+actual+
 " nativeCalls="+full.actualPredecessorCalls+
 " sharedWrites="+full.actualSharedWrites+
 " additionalNative=0 deepFaults="+faults+" finalBlocked=1");
