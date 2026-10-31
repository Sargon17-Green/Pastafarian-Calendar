import {MonsterStageError,MonsterValidationError} from "./monsterBase.ts";
import {projectProductionCutletFromGateDays} from "./postStage55CutletProjection.ts";
import {Patch25PrefixOccurrenceCounter} from "./patch25MonthDay.ts";
import {Patch27DirectMembershipChecker} from "./patch27MonthMembership.ts";
import {monthNameByCanonicalIndex} from "./sourceLanguageCatalog.ts";

// Gate C pure assembler: all arguments must be VERIFIED production observations.
// This does not manufacture a Sauce request, call Native or enable calendarDateSpaghetti.
export type ProductionFivePartDate=readonly [
  yearNumber:bigint,cutletName:string,dayInCutlet:bigint,
  monthName:string,monthOccurrenceOrdinal:bigint
];

export function projectProductionFivePartDate(
  yearNumber:bigint,targetDay:bigint,
  measuredGateDays:readonly bigint[],
  correctedGateGapPartition:readonly bigint[],
  correctedCutletCanonicalIndices:readonly number[],
  correctedMonthLengths:readonly bigint[],
  correctedLegalWeaving:readonly number[],
  correctedMonthCanonicalIndices:readonly number[]
):ProductionFivePartDate {
  // Validates measured gate gaps, partition, unique cutlet names and target bounds.
  const cutlet=projectProductionCutletFromGateDays(
    yearNumber,targetDay,measuredGateDays,
    correctedGateGapPartition,correctedCutletCanonicalIndices
  );
  if(!Array.isArray(correctedMonthLengths)||
     !Array.isArray(correctedLegalWeaving)||
     !Array.isArray(correctedMonthCanonicalIndices))
    throw new MonsterValidationError("Stage23/24/Seal33 महिन्यांची खरी यादी आवश्यक");
  const monthCount=correctedMonthLengths.length;
  if(monthCount<3||monthCount>47||
     correctedMonthCanonicalIndices.length!==monthCount||
     correctedMonthLengths.some(n=>typeof n!=="bigint"||n<4n||n>123n)||
     correctedMonthCanonicalIndices.some(n=>!Number.isSafeInteger(n)||n<1||n>47)||
     new Set(correctedMonthCanonicalIndices).size!==monthCount)
    throw new MonsterValidationError("3..47 महिने, 4..123 दिवस आणि वेगळी नावे आवश्यक");
  const yearLength=measuredGateDays[measuredGateDays.length-1]!-measuredGateDays[0]!;
  if(yearLength<1n||yearLength>5778n||
     correctedLegalWeaving.length!==Number(yearLength)||
     correctedMonthLengths.reduce((a,b)=>a+b,0n)!==yearLength)
    throw new MonsterValidationError("पूर्ण वर्ष आणि Stage23 महिना-लांबी विसंगत");
  const occurrences=Array<number>(monthCount).fill(0);
  const lastDay=Array<number>(monthCount).fill(-1);
  let highestOpened=0;
  for(let i=0;i<correctedLegalWeaving.length;i++){
    const month=correctedLegalWeaving[i]!;
    if(!Number.isSafeInteger(month)||month<1||month>monthCount)
      throw new MonsterValidationError("Stage24 कायदेशीर विणकामात अवैध महिना");
    if(occurrences[month-1]===0){
      if(month!==highestOpened+1)
        throw new MonsterValidationError("Stage24 महिन्यांचा आरंभक्रम अवैध");
      highestOpened=month;
    }
    occurrences[month-1]!++;
    lastDay[month-1]=i;
  }
  if(highestOpened!==monthCount||
     occurrences.some((count,i)=>BigInt(count)!==correctedMonthLengths[i])||
     lastDay.some((at,i)=>i>0&&at<=lastDay[i-1]!))
    throw new MonsterValidationError("Stage23/24 सदस्यसंख्या किंवा समाप्तिक्रम अवैध");
  // Safe numeric conversion follows proved year-local [1,5778] bounds.
  const yearDay=Number(targetDay-measuredGateDays[0]!);
  const monthId=correctedLegalWeaving[yearDay-1]!;
  if(!new Patch27DirectMembershipChecker().isMember(
       correctedLegalWeaving,monthId,yearDay))
    throw new MonsterStageError("Stage55 लक्ष्य महिन्याची सदस्यता अपूर्ण");
  const ordinal=BigInt(new Patch25PrefixOccurrenceCounter().count(
    correctedLegalWeaving,yearDay));
  if(ordinal<1n||ordinal>correctedMonthLengths[monthId-1]!)
    throw new MonsterStageError("Stage51 prefix ordinal महिन्याबाहेर");
  const monthName=monthNameByCanonicalIndex(correctedMonthCanonicalIndices[monthId-1]!);
  return Object.freeze([
    cutlet.yearNumber,cutlet.cutletName,cutlet.dayInCutlet,
    monthName,ordinal
  ] as const);
}
