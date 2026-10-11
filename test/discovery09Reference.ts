import { SAVE, bowlOrderFromDrop } from "./normativeOracle.ts";
// नियमाधारित तीन pours: position मधील actual bowl ID वापरतो; test-only.
export function normativeThreePours(i:number,d:bigint,b:readonly bigint[],s:readonly bigint[]):readonly bigint[]{
  if(!Number.isInteger(i)||i<1||i>46||typeof d!=="bigint"||
    !Array.isArray(b)||b.length!==6||Array.from({length:6},(_,k)=>typeof b[k]!=="bigint").some(Boolean)||
    !Array.isArray(s)||s.length!==5||Array.from({length:5},(_,k)=>typeof s[k]!=="bigint").some(Boolean)){
    throw new RangeError("अवैध pour input");
  }
  const order=bowlOrderFromDrop(d);
  const coefficients = [3n,5n,7n] as const;
  const result: bigint[] = [];
  for(let k=0;k<3;k++){
    const selectedBowlId: number = order[k]!;
    const stoneContribution: bigint = s[k]! * b[selectedBowlId-1]!;
    const ordinalContribution: bigint = coefficients[k]! * BigInt(i);
    result.push(SAVE(d*d + stoneContribution + ordinalContribution));
  }
  return Object.freeze(result);
}
