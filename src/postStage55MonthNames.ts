import {MonsterStageError,MonsterValidationError} from "./monsterBase.ts";
import {patch14WideChoice} from "./patch14WideChoice.ts";
import type {Patch14WideChoiceObservation} from "./patch14WideChoice.ts";
import type {Patch18Question} from "./patch18YearWalk.ts";
import {monthNameByCanonicalIndex} from "./sourceLanguageCatalog.ts";

// Gate C: production month-name assignment, Bowl 5 / Seal 33.
// This selection is not interchangeable with the month position ID.
export type ProductionMonthNamesSelection=Readonly<{
  monthCount:number;
  familySize:bigint;
  correctedRank:bigint;
  correctedNameIndices:readonly number[];
  canonicalNames:readonly string[];
  actualNativeCalls:1;
  actualSharedWrites:58n;
  nativeSelection:Patch14WideChoiceObservation;
  source:"PRODUCTION_NATIVE_SEAL33_DISTINCT_MONTH_NAMES";
}>;

function falling47(m:number):bigint {
  let n=1n;
  for(let i=0;i<m;i++)n*=BigInt(47-i);
  return n;
}
function unrankDistinct47(m:number,rank:bigint):readonly number[] {
  const family=falling47(m);
  if(rank<1n||rank>family)
    throw new MonsterValidationError("महिन्यांच्या नावांचा lex rank वैध नाही");
  let r=rank-1n;
  const remaining=Array.from({length:47},(_,i)=>i+1);
  const indices:number[]=[];
  for(let i=0;i<m;i++){
    let block=1n;
    for(let j=0;j<m-i-1;j++)block*=BigInt(46-i-j);
    const position=Number(r/block);
    if(!Number.isSafeInteger(position)||position<0||position>=remaining.length)
      throw new MonsterStageError("महिन्यांच्या नावांचे distinct unrank अपूर्ण");
    const chosen=remaining.splice(position,1)[0];
    if(chosen===undefined)throw new MonsterStageError("नावांच्या यादीत स्थान नाही");
    indices.push(chosen);
    r%=block;
  }
  if(r!==0n)throw new MonsterStageError("नावांची शिल्लक rank शून्य नाही");
  return Object.freeze(indices);
}

/** Requires the actual production first-day Sauce question and verified month count.
 * Runs exactly one physical PATCH14 predecessor. The numerical month position
 * is mapped to the corresponding distinct canonical name only after selection.
 */
export function selectProductionMonthNames(
  calculationDay:bigint,firstDayQuestion:Patch18Question,monthCount:number
):ProductionMonthNamesSelection {
  if(typeof calculationDay!=="bigint"||!firstDayQuestion||
     firstDayQuestion.calculationDay!==calculationDay||
     typeof firstDayQuestion.targetDay!=="bigint"||
     !Number.isSafeInteger(monthCount)||monthCount<3||monthCount>47)
    throw new MonsterValidationError("पूर्ण first-day Sauce आणि 3..47 महिने आवश्यक");
  const familySize=falling47(monthCount);
  const native=patch14WideChoice(
    calculationDay,firstDayQuestion.targetDay,
    firstDayQuestion.visible,firstDayQuestion.stones,
    firstDayQuestion.startBowls,5,33n,familySize
  );
  if(native.queriedBowlId!==5||native.seal!==33n||
     native.familySize!==familySize||native.predecessorSharedWrites!==58||
     native.realLegacyCalls!==1||
     native.context.calculationDay!==calculationDay||
     native.context.targetDay!==firstDayQuestion.targetDay)
    throw new MonsterStageError("खरा Bowl5 Seal33 Native predecessor अपूर्ण");
  const correctedNameIndices=unrankDistinct47(monthCount,native.correctedRank);
  const canonicalNames=Object.freeze(correctedNameIndices.map(monthNameByCanonicalIndex));
  if(new Set(correctedNameIndices).size!==monthCount)
    throw new MonsterStageError("महिन्यांची canonical नावे भिन्न नाहीत");
  return Object.freeze({
    monthCount,familySize,correctedRank:native.correctedRank,
    correctedNameIndices,canonicalNames,
    actualNativeCalls:1 as const,actualSharedWrites:58n as const,
    nativeSelection:native,
    source:"PRODUCTION_NATIVE_SEAL33_DISTINCT_MONTH_NAMES" as const
  });
}
