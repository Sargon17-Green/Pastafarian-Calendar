import { SAVE, bowlOrderFromDrop } from "./normativeOracle.ts";
import { normativeThreePours } from "./discovery09Reference.ts";

// केवळ test-only स्वतंत्र normative सूत्र: प्रत्येक read मूळ सहा values मधून.
// Stage 21 production patch अद्याप नाही; येथे reference-only गणित आहे.
export function normativeSingleStir(i:number,d:bigint,b:readonly bigint[],stone:readonly bigint[]){
  if(!Number.isInteger(i)||i<1||i>46||typeof d!=="bigint"||
     !Array.isArray(b)||b.length!==6||
     Array.from({length:6},(_,k)=>typeof b[k]!=="bigint").some(Boolean)||
     !Array.isArray(stone)||stone.length!==5||
     Array.from({length:5},(_,k)=>typeof stone[k]!=="bigint").some(Boolean)){
    throw new RangeError("नियमाधारित stir साठी valid values हवेत");
  }
  const order=bowlOrderFromDrop(d);
  const initial:readonly bigint[] = b as readonly bigint[];
  const stoneValues:readonly bigint[] = stone as readonly bigint[];
  const pours=normativeThreePours(i,d,b,stone);
  const stoneKinds=[0,1,2,3,4,0] as const;
  const expected:bigint[]=[...initial];
  const expectedSteps:bigint[]=[];
  for(let pos=1;pos<=6;pos++){
    const id=order[pos-1]!;
    const prev=order[(pos+4)%6]!;
    const next=order[pos%6]!;
    const current:bigint=initial[id-1]!;
    const previous:bigint=initial[prev-1]!;
    const following:bigint=initial[next-1]!;
    const pour:bigint=pos<=3?pours[pos-1]!:0n;
    const ingredient:bigint=stoneValues[stoneKinds[pos-1]!]!;
    const stir:bigint=current+2n*previous+3n*following+pour+d+ingredient;
    const value:bigint=SAVE(stir*stir+5n*previous*following+BigInt(i*pos));
    expected[id-1]=value;
    expectedSteps.push(value);
  }
  return Object.freeze({order,expectedBowls:Object.freeze(expected),
    expectedSteps:Object.freeze(expectedSteps),pours});
}
