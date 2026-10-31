import {
 Discovery27FullHandler,Patch26FullHandler,Discovery26FullHandler,
 Patch25FullHandler,Discovery25FullHandler,Patch24ScalableFullHandler,
 Discovery24FullHandler,Patch23FullHandler,Discovery23FullHandler,
 Patch22FullHandler,Discovery22FullHandler,Patch21CutletHandler,
 Discovery21LegacyCutletHandler,Patch20StructureSauceHandler,
 Discovery20StructureSauceHandler,Patch19YearCacheHandler,
 discoverLegacyMonthSpan,LegacyMonthSpanMembershipGuess
} from "../src/index.ts";
import {buildStage41CompatibleLegacyFixture} from "./discovery21Fixtures.ts";
const fixture=buildStage41CompatibleLegacyFixture();
const chain=new Patch24ScalableFullHandler(new Discovery24FullHandler(
 new Patch23FullHandler(new Discovery23FullHandler(
 new Patch22FullHandler(new Discovery22FullHandler(
 new Patch21CutletHandler(new Discovery21LegacyCutletHandler(
 new Patch20StructureSauceHandler(
 new Discovery20StructureSauceHandler(new Patch19YearCacheHandler())
)))))))));
const handler=new Discovery27FullHandler(new Patch26FullHandler(
 new Discovery26FullHandler(new Patch25FullHandler(new Discovery25FullHandler(chain)))));
const full=discoverLegacyMonthSpan(handler,fixture.request,44,5349);
const word=full.historical.historical.historical.historical.historical.corrected.legalWeaving;
const month=44,guess=new LegacyMonthSpanMembershipGuess();
const start=word.indexOf(month),end=word.lastIndexOf(month);
if(word.length!==5349||start<0||end<0||full.additionalNativeQueries!==0)
 throw Error("DISCOVERY27_NATIVE_WITNESS_INVALID");
for(let day=start+1;day<=end+1;day++){
 if(word[day-1]!==month&&guess.guess(word,month,day).guessedMonthMembership){
  throw Error("DISCOVERY27_NATIVE_EXPECTED_RED realYear5000=1 month="+month+
   " day="+day+" nativeCalls="+full.actualPredecessorCalls);
 }
}
throw Error("DISCOVERY27_NATIVE_NO_REAL_GAP_OBSERVED");
