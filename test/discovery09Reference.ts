import { SAVE, bowlOrderFromDrop } from "./normativeOracle.ts";
// Test-only normative fixed-position comparison using actual permutation bowl IDs.
export function normativeThreePours(i:number,d:bigint,b:readonly bigint[],s:readonly bigint[]):readonly bigint[]{
  if(!Number.isInteger(i)||i<1||i>46||typeof d!=="bigint"||
     b.length!==6||s.length!==5||
     Array.from({length:6},(_,j)=>typeof b[j]!=="bigint").some(Boolean)||
     Array.from({length:5},(_,j)=>typeof s[j]!=="bigint").some(Boolean)){
    throw new RangeError("अवैध pour input");
  }
  const order=bowlOrderFromDrop(d);
  const weights=[3n,5n,7n] as const;
  const out:bigint[]=[];
  for(let p=0;p<3;p++){
    const bowlId=order[p]!;
    const product:bigint=s[p]! * b[bowlId-1]!;
    out.push(SAVE(d*d+product+weights[p]!*BigInt(i)));
  }
  return Object.freeze(out);
}
