import {OldContiguousMonthDayGuess} from "../src/index.ts";
const word=[1,2,1,2,1,2,1,3,2,3,3,3,3];
const guess=new OldContiguousMonthDayGuess().oldContiguousMonthDayGuess(word,13);
const reference=word.slice(0,13).filter(x=>x===3).length;
if(guess.monthId===3&&guess.guessedDayInMonth===6&&reference===5&&
 !guess.actualPrefixOccurrenceCorrectionApplied)
 throw Error("DISCOVERY_25_EXPECTED_RED oldContiguousMonthDayGuess=6 actualPrefixOccurrences=5 patch25=not_applied");
throw Error("DISCOVERY_25_WITNESS_DRIFT");
