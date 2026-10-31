import {MonsterStageError,MonsterValidationError} from "./monsterBase.ts";
import {cutletNameByCanonicalIndex} from "./sourceLanguageCatalog.ts";

// Gate C: a cutlet partition describes GATE GAPS, not calendar days.
// The gate-day array must come from the measured production signed gate window.
// A distinct canonical name index at each position comes from Stage22/PATCH22.
export type ProductionCutletProjection=Readonly<{
  yearNumber:bigint;
  cutletName:string;
  dayInCutlet:bigint;
  cutletPosition:number;
  canonicalIndex:number;
  firstDay:bigint;
  lastDay:bigint;
  source:"POST_STAGE55_MEASURED_GATE_CUTLET_PROJECTION";
}>;

/** Pure projection of accepted upstream Gate/Stage21/Stage22 observations.
 * Does not construct those observations and makes zero additional Native calls.
 * In particular, do NOT sum gate-gap counts as though they were day lengths.
 */
export function projectProductionCutletFromGateDays(
  yearNumber:bigint,targetDay:bigint,
  measuredGateDays:readonly bigint[],
  correctedGateGapPartition:readonly bigint[],
  correctedCanonicalNameIndices:readonly number[]
):ProductionCutletProjection {
  if(typeof yearNumber!=="bigint"||typeof targetDay!=="bigint"||
     !Array.isArray(measuredGateDays)||
     !Array.isArray(correctedGateGapPartition)||
     !Array.isArray(correctedCanonicalNameIndices))
    throw new MonsterValidationError("वर्ष, दिवस, खरी द्वारे आणि कटलेट यादी आवश्यक");
  const G=measuredGateDays.length-1;
  const K=correctedGateGapPartition.length;
  if(G<3||G>5778||K<3||K>17||K>G||
     correctedCanonicalNameIndices.length!==K||
     measuredGateDays.some(g=>typeof g!=="bigint")||
     correctedGateGapPartition.some(g=>typeof g!=="bigint"||g<1n)||
     correctedCanonicalNameIndices.some(i=>!Number.isSafeInteger(i)||i<1||i>17)||
     new Set(correctedCanonicalNameIndices).size!==K)
    throw new MonsterValidationError("Stage21/22 चे काटेकोर positive/distinct पुरावे आवश्यक");
  let length=0n;
  for(let i=0;i<G;i++){
    const gap=measuredGateDays[i+1]!-measuredGateDays[i]!;
    // Signed gate gaps are 41 + one exact rank in [1, 922].
    if(gap<42n||gap>963n)
      throw new MonsterValidationError("खरे सलग signed gate दिवस आवश्यक");
    length+=gap;
  }
  if(length>5778n||
     targetDay<=measuredGateDays[0]!||
     targetDay>measuredGateDays[G]!)
    throw new MonsterValidationError("लक्ष्य दिवस या वास्तविक वर्षात नाही");
  if(correctedGateGapPartition.reduce((a,b)=>a+b,0n)!==BigInt(G))
    throw new MonsterValidationError("Stage21 कटलेट भागांची बेरीज gate gaps शी जुळत नाही");

  let left=0;
  for(let k=0;k<K;k++){
    const next=left+Number(correctedGateGapPartition[k]!);
    if(!Number.isSafeInteger(next)||next>G)
      throw new MonsterStageError("कटलेटचा gate boundary वर्षाबाहेर");
    const open=measuredGateDays[left]!,close=measuredGateDays[next]!;
    if(targetDay>open&&targetDay<=close){
      const canonicalIndex=correctedCanonicalNameIndices[k]!;
      return Object.freeze({
        yearNumber,cutletName:cutletNameByCanonicalIndex(canonicalIndex),
        dayInCutlet:targetDay-open,
        cutletPosition:k+1,canonicalIndex,
        firstDay:open+1n,lastDay:close,
        source:"POST_STAGE55_MEASURED_GATE_CUTLET_PROJECTION" as const
      });
    }
    left=next;
  }
  throw new MonsterStageError("प्रमाणित वर्षात लक्ष्य कटलेट सापडली नाही");
}
