import {
 Patch27DirectMembershipChecker,LegacyMonthSpanMembershipGuess
} from "../src/index.ts";
import {assert} from "./discovery21Fixtures.ts";
const checker=new Patch27DirectMembershipChecker();
const guesser=new LegacyMonthSpanMembershipGuess();
let families=0,queries=0,repaired=0,equal=0,falseAccept=0,falseReject=0;
let unexpected=0,correctedMembers=0;
for(let seed=0;seed<256;seed++){
 let state=(seed+1)>>>0;
 const word=Array.from({length:47},(_,i)=>1+(i%5));
 for(let i=word.length-1;i>0;i--){
  state=(Math.imul(state,1664525)+1013904223)>>>0;
  const j=state%(i+1);
  [word[i],word[j]]=[word[j]!,word[i]!];
 }
 for(let month=1;month<=5;month++){
  let oracleMembers=0;
  for(let day=1;day<=word.length;day++){
   const old=guesser.guess(word,month,day);
   const corrected=checker.correct(word,old);
   const direct=word[day-1]===month;
   if(direct){oracleMembers++;correctedMembers++;}
   if(corrected.correctedMonthMembership!==direct)unexpected++;
   if(old.guessedMonthMembership&&!direct)falseAccept++;
   if(!old.guessedMonthMembership&&direct)falseReject++;
   if(corrected.historicalEqualsCorrect)equal++;else repaired++;
   assert(corrected.historical===old&&Object.isFrozen(corrected)&&
    corrected.actualDirectMembershipCorrectionApplied&&
    corrected.historicalEqualsCorrect===
      (old.guessedMonthMembership===direct),
    "independent equality oracle, immutable history");
   queries++;
  }
  assert(oracleMembers===word.filter(m=>m===month).length,
   "direct-member conservation for each month");
 }
 families++;
}
assert(families===256&&queries===60160&&
 repaired===39124&&equal===21036&&
 falseAccept===39124&&falseReject===0&&
 correctedMembers===12032&&unexpected===0,
 "all dispersed-member false accepts repaired, no false rejects");
console.log("STAGE_55_PATCH_27_PROPERTIES_PASS families="+families+
 " queries="+queries+" repaired="+repaired+" equal="+equal+
 " correctedMembers="+correctedMembers+" falseAccept="+falseAccept+
 " falseReject="+falseReject+" unexpected="+unexpected);
