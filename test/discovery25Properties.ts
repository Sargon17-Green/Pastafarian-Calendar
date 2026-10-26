import {OldContiguousMonthDayGuess} from "../src/index.ts";
import {weavingFamily} from "./normativeOracle.ts";
import {assert} from "./discovery21Fixtures.ts";
const old=new OldContiguousMonthDayGuess();
let smallFamilies=0,allRows=0,allDays=0,witnesses=0,legalBad=0;
for(const lengths of [
 [4n,4n,4n],[4n,4n,5n],[4n,5n,4n],[5n,4n,4n],
 [4n,4n,6n],[4n,5n,5n],[5n,4n,4n,4n]
]){
 const f=weavingFamily(lengths),N=f.count();
 const samples=N<=3500n
  ?Array.from({length:Number(N)},(_,i)=>BigInt(i+1))
  :[1n,2n,3n,4n,5n,11n,23n,N/2n,N-1n,N];
 for(const rank of samples){
  if(rank<1n||rank>N)continue;
  const word=f.unrank1(rank);
  const seen=Array<number>(lengths.length).fill(0);
  for(let d=1;d<=word.length;d++){
   const month=word[d-1]!;
   seen[month-1]!++;
   const result=old.oldContiguousMonthDayGuess(word,d);
   if(result.monthId!==month||result.guessedDayInMonth<seen[month-1]!)
    legalBad++;
   if(result.guessedDayInMonth!==seen[month-1])witnesses++;
   allDays++;
  }
  assert(seen.every((v,i)=>v===Number(lengths[i])),
   "test-only legal normative length conservation");
  allRows++;
 }
 smallFamilies++;
}
assert(smallFamilies===7&&allRows>3500&&allDays>40000&&
 witnesses>0&&legalBad===0,
 "historical month span mismatch independently witnessed across legal families");
console.log("STAGE_50_DISCOVERY_25_PROPERTIES_PASS"+
 " legalFamilies="+smallFamilies+" legalRows="+allRows+
 " auditedDays="+allDays+" dispersedDayMismatch="+witnesses+
 " oldBelowActual=0 correctionApplied=0 stage51Blocked=1");
