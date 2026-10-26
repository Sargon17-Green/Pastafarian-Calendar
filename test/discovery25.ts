import {
 OldContiguousMonthDayGuess,Discovery25FullHandler,
 Patch24ScalableFullHandler,Discovery24FullHandler,Patch23FullHandler,
 Discovery23FullHandler,Patch22FullHandler,Discovery22FullHandler,
 Patch21CutletHandler,Discovery21LegacyCutletHandler,
 Patch20StructureSauceHandler,Discovery20StructureSauceHandler,
 Patch19YearCacheHandler,bootstrapMonster,
 MonsterStageError,MonsterValidationError,
 calendarDateSpaghetti,discoverLegacyContiguousMonthDay
} from "../src/index.ts";
import {FOUNDATION_DAY as F} from "./normativeOracle.ts";
import {assert,buildStage41CompatibleLegacyFixture}
 from "./discovery21Fixtures.ts";
const guesser=new OldContiguousMonthDayGuess();
const normative=(word:readonly number[],day:number)=>{
 const month=word[day-1]!;
 return word.slice(0,day).filter(v=>v===month).length;
};
const legal=[1,2,1,2,1,2,1,3,2,3,3,3,3];
assert(legal.length===13&&
 [1,2,3].every((j,i)=>legal.filter(x=>x===j).length===[4,4,5][i]),
 "small legal weaving multiplicities");
let witnessed=0,sampled=0;
for(let day=1;day<=legal.length;day++){
 const old=guesser.oldContiguousMonthDayGuess(legal,day);
 const correct=normative(legal,day);
 assert(old.monthId===legal[day-1]&&old.guessedDayInMonth>=correct&&
  !old.actualPrefixOccurrenceCorrectionApplied,
  "old guess reports actual month without applying future correction");
 if(old.guessedDayInMonth>correct)witnessed++;
 sampled++;
}
assert(witnessed>0&&
 guesser.oldContiguousMonthDayGuess(legal,13).guessedDayInMonth===6&&
 normative(legal,13)===5&&
 guesser.oldContiguousMonthDayGuess(legal,9).guessedDayInMonth===8&&
 normative(legal,9)===4,
 "last month and separated older month show real contiguous-span defect");
let rejected=0;
for(const f of [
 ()=>guesser.oldContiguousMonthDayGuess(legal,0),
 ()=>guesser.oldContiguousMonthDayGuess(legal,14),
 ()=>guesser.oldContiguousMonthDayGuess([],1),
 ()=>guesser.oldContiguousMonthDayGuess([1,48],2)
]){
 try{f();}catch(e){if(e instanceof MonsterValidationError)rejected++;}
}
assert(rejected===4,"bounds and invalid month IDs guarded");
const fixture=buildStage41CompatibleLegacyFixture();
const chain=()=>new Patch24ScalableFullHandler(new Discovery24FullHandler(
 new Patch23FullHandler(new Discovery23FullHandler(
 new Patch22FullHandler(new Discovery22FullHandler(
 new Patch21CutletHandler(new Discovery21LegacyCutletHandler(
 new Patch20StructureSauceHandler(
 new Discovery20StructureSauceHandler(new Patch19YearCacheHandler())
)))))))));
const maker=()=>new Discovery25FullHandler(chain());
const full=discoverLegacyContiguousMonthDay(maker(),fixture.request);
const correctWord=full.historical.corrected.legalWeaving;
const actualCorrect=normative(correctWord,correctWord.length);
const actualWrong=full.guessed.guessedDayInMonth;
assert(full.context.status==="DISCOVERY_25_RECORDED"&&
 full.historical.context.status==="PATCH_24_APPLIED"&&
 full.historical.historical.context.status==="DISCOVERY_24_RECORDED"&&
 full.historical.historical.historical.context.status==="PATCH_23_APPLIED"&&
 full.source==="FULL_STAGE49_HISTORICAL_CONTIGUOUS_MONTH_DAY_GUESS"&&
 correctWord.length===5349&&
 full.guessed.targetYearDay===5349&&
 full.guessed.monthId===44&&
 actualCorrect===Number(full.historical.corrected.historical.lengths[43])&&
 actualWrong>actualCorrect&&
 full.guessed.historicalAlgorithm==="oldContiguousMonthDayGuess"&&
 full.actualPredecessorCalls===full.historical.realPredecessorCalls&&
 full.actualSharedWrites===full.historical.realSharedWrites&&
 full.actualPredecessorCalls===61&&full.actualSharedWrites===3538n,
 "real 5349/44 fully-native corrected weaving exposes wrong historical guess");
const independentSamples=[1,2,3,4,16,100,267,1037,2625,4200,5349];
let independentWitnesses=0;
for(const day of independentSamples){
 const old=guesser.oldContiguousMonthDayGuess(correctWord,day);
 const actual=normative(correctWord,day);
 assert(old.guessedDayInMonth>=actual,"no false smaller contiguous-span guess");
 if(old.guessedDayInMonth!==actual)independentWitnesses++;
}
assert(independentWitnesses>0,"real-year dispersed month occurrences occur");
const badReady=bootstrapMonster(fixture.cDay,
 fixture.request.historical.yearQuestion.targetDay+1n);
let invalidOwner=false;
try{maker().run(badReady,fixture.request);}
catch(e){invalidOwner=e instanceof MonsterStageError;}
let notIntegrated=false;
try{calendarDateSpaghetti(F,F);}catch(e){notIntegrated=e instanceof MonsterStageError;}
assert(invalidOwner&&badReady.status==="VALIDATED"&&
 badReady.branchTrace.join(",")==="BOOTSTRAP_VALIDATE"&&
 notIntegrated,"invalid owner rejection without mutation; stage54 blocked");
console.log("STAGE_50_DISCOVERY_25_GUARDS_PASS"+
 " smallLegalDays="+sampled+" smallWrongDays="+witnessed+
 " realYearDays="+correctWord.length+" realMonthCount=44"+
 " realLastMonthCorrect="+actualCorrect+
 " realLastMonthLegacy="+actualWrong+
 " realIndependentDispersed="+independentWitnesses+
 " actualPredecessorCalls="+full.actualPredecessorCalls+
 " realSharedWrites="+full.actualSharedWrites+
 " previousStage49=1 additionalSauceCalls=0"+
 " patch25Applied=0 archivedExpectedReds=24 stage54Blocked=1");
