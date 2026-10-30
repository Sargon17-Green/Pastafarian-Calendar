import {LegacyNextDayMonthEndGuess} from "../src/index.ts";
import {assert} from "./discovery21Fixtures.ts";
const legacy=new LegacyNextDayMonthEndGuess();
let families=0,days=0,mismatches=0,agreement=0,lastDays=0;
for(let seed=0;seed<256;seed++){
 let state=(seed+1)>>>0;
 const word=Array.from({length:47},(_,i)=>1+(i%5));
 for(let i=word.length-1;i>0;i--){
  state=(Math.imul(state,1664525)+1013904223)>>>0;
  const j=state%(i+1);
  [word[i],word[j]]=[word[j]!,word[i]!];
 }
 const totals=new Map<number,number>();
 for(const month of word)totals.set(month,(totals.get(month)??0)+1);
 for(let d=1;d<=word.length;d++){
  const result=legacy.guess(word,d);
  const actual=!word.slice(d).includes(word[d-1]!); // independent suffix oracle
  const immediate=d===word.length||word[d]!==word[d-1];
  assert(result.guessedLastMonthOccurrence===immediate&&
   result.monthId===word[d-1]&&
   result.actualSuffixOracleApplied===false,
   "production guess remains next-day-only");
  if(result.guessedLastMonthOccurrence===actual)agreement++;else mismatches++;
  if(actual)lastDays++;
  days++;
 }
 assert(Array.from(totals.values()).reduce((a,b)=>a+b,0)===word.length,
  "all months conserved");
 families++;
}
assert(families===256&&days===12032&&lastDays===families*5&&
 mismatches>0&&agreement>0,
 "seeded dispersed families and last-occurrence oracle");
console.log("STAGE_52_DISCOVERY_26_PROPERTIES_PASS families="+families+
 " days="+days+" diagnosticMismatches="+mismatches+
 " agreements="+agreement+" actualLastDays="+lastDays+
 " unexpected=0");
