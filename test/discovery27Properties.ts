import {LegacyMonthSpanMembershipGuess} from "../src/index.ts";
import {assert} from "./discovery21Fixtures.ts";
const guesser=new LegacyMonthSpanMembershipGuess();
let families=0,queries=0,falseAccept=0,falseReject=0,matches=0;
for(let seed=0;seed<256;seed++){
 let state=(seed+1)>>>0;
 const word=Array.from({length:47},(_,i)=>1+(i%5));
 for(let i=word.length-1;i>0;i--){
  state=(Math.imul(state,1664525)+1013904223)>>>0;
  const j=state%(i+1);
  [word[i],word[j]]=[word[j]!,word[i]!];
 }
 for(let month=1;month<=5;month++){
  let observedMembers=0;
  for(let day=1;day<=word.length;day++){
   const result=guesser.guess(word,month,day);
   const direct=word[day-1]===month;
   if(direct)observedMembers++;
   assert(result.monthId===month&&result.probeYearDay===day&&
    result.actualDirectMembershipOracleApplied===false&&Object.isFrozen(result),
    "provenance and immutable research diagnostic");
   if(result.guessedMonthMembership&&!direct)falseAccept++;
   else if(!result.guessedMonthMembership&&direct)falseReject++;
   else matches++;
   queries++;
  }
  assert(observedMembers===word.filter(m=>m===month).length,
   "direct-membership conservation");
 }
 families++;
}
assert(families===256&&queries===60160&&falseAccept===39124&&
 falseReject===0&&matches===21036,
 "independent direct-membership seed audit");
console.log("STAGE_54_DISCOVERY_27_FULL_PROPERTIES_PASS families="+families+
 " queries="+queries+" falseAccept="+falseAccept+
 " falseReject="+falseReject+" matches="+matches+" oracleMismatch=0");
