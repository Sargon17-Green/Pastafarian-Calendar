import {Patch25PrefixOccurrenceCounter,OldContiguousMonthDayGuess} from "../src/index.ts";
import {assert} from "./discovery21Fixtures.ts";
const corrected=new Patch25PrefixOccurrenceCounter(),legacy=new OldContiguousMonthDayGuess();
let families=0,days=0,differences=0,equal=0,roundtrip=0;
// Deterministic bounded dispersed weaving families with exact month multiplicities.
for(let seed=0;seed<512;seed++){
 let state=(seed+1)>>>0;
 const word:number[]=[];
 for(let i=0;i<47;i++)word.push(1+(i%5));
 for(let i=word.length-1;i>0;i--){
  state=(Math.imul(state,1664525)+1013904223)>>>0;
  const j=state%(i+1);
  [word[i],word[j]]=[word[j]!,word[i]!];
 }
 const prior=Array<number>(6).fill(0);
 for(let i=0;i<word.length;i++){
  const month=word[i]!;
  prior[month]!++;
  const out=corrected.correct(word,legacy.oldContiguousMonthDayGuess(word,i+1));
  assert(out.correctedDayInMonth===prior[month]&&
   out.correctedDayInMonth<=out.historical.guessedDayInMonth,
   "streaming independent occurrence reference");
  if(out.historicalEqualsCorrect)equal++;else differences++;
  days++;
 }
 assert(prior.slice(1).reduce((a,b)=>a+b,0)===47,
  "every day occurs in one month");
 roundtrip+=prior.slice(1).reduce((a,b)=>a+b,0);
 families++;
}
assert(families===512&&days===24064&&roundtrip===days&&
 differences>0&&equal>0,"dispersed and contiguous paths both covered");
console.log("STAGE_51_PATCH_25_PROPERTIES_PASS families="+families+
 " days="+days+" repaired="+differences+" equal="+equal+
 " independentRankedDays="+roundtrip+" mismatches=0");
