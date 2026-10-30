import {LegacyNextDayMonthEndGuess} from "../src/index.ts";
const w=[1,2,1,2,1,2,1,3,2,3,3,3,3];
const guess=new LegacyNextDayMonthEndGuess();
const oracle=(d:number)=>!w.slice(d).includes(w[d-1]!);
const red=[1,2,8].filter(d=>guess.guess(w,d).guessedLastMonthOccurrence&&!oracle(d));
const green=[7,13].filter(d=>guess.guess(w,d).guessedLastMonthOccurrence&&oracle(d));
if(red.join(",")==="1,2,8"&&green.join(",")==="7,13")
 throw Error("DISCOVERY_26_EXPECTED_RED mismatchDays=1,2,8 controls=7,13 model=nextDayOnly");
throw Error("DISCOVERY_26_WITNESS_DRIFT");
