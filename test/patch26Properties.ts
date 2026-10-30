import {
 Patch26SuffixOccurrenceChecker,LegacyNextDayMonthEndGuess
} from "../src/index.ts";
import {assert} from "./discovery21Fixtures.ts";
const checker=new Patch26SuffixOccurrenceChecker(),legacy=new LegacyNextDayMonthEndGuess();
let families=0,days=0,repaired=0,equal=0,lastDays=0,unexpected=0;
for(let seed=0;seed<256;seed++){
 let state=(seed+1)>>>0;
 const word=Array.from({length:47},(_,i)=>1+(i%5));
 for(let i=word.length-1;i>0;i--){
  state=(Math.imul(state,1664525)+1013904223)>>>0;
  const j=state%(i+1);
  [word[i],word[j]]=[word[j]!,word[i]!];
 }
 const totals=new Map<number,number>();
 for(const m of word)totals.set(m,(totals.get(m)??0)+1);
 let actualLast=0;
 for(let day=1;day<=word.length;day++){
  const old=legacy.guess(word,day);
  const corrected=checker.correct(word,old);
  const independent=!word.slice(day).includes(word[day-1]!);
  if(corrected.correctedLastMonthOccurrence!==independent)unexpected++;
  assert(corrected.historical===old&&
   corrected.actualSuffixOccurrenceCorrectionApplied&&
   corrected.historicalEqualsCorrect===
    (old.guessedLastMonthOccurrence===independent),
   "provenance and independent suffix correctness");
  if(independent)actualLast++;
  if(corrected.historicalEqualsCorrect)equal++;else repaired++;
  days++;
 }
 assert(actualLast===totals.size&&totals.size===5,
  "one last occurrence for each nonempty month");
 lastDays+=actualLast;families++;
}
assert(families===256&&days===12032&&lastDays===1280&&
 repaired>0&&equal>0&&unexpected===0,
 "seeded dispersed families repaired without unexpected divergences");
console.log("STAGE_53_PATCH_26_PROPERTIES_PASS families="+families+
 " days="+days+" repaired="+repaired+" equal="+equal+
 " actualLastDays="+lastDays+" unexpected="+unexpected);
