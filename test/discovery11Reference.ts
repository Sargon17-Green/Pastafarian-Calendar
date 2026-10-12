import { SAVE,bowlOrderFromNumber,regularMod } from "./normativeOracle.ts";
// Independent test-only 12-stir oracle, including each intermediate order.
// All six reads per stir come from the *same old snapshot*.
export function normativePostStirLedger(initial:readonly bigint[]){
  if(initial.length!==6||initial.some(v=>typeof v!=="bigint")){
    throw new RangeError("सहा वैध वाट्या हव्यात");
  }
  let bowls:readonly bigint[]=[...initial];
  const orders:(readonly number[])[]=[];
  const bowlHistory:(readonly bigint[])[]=[];
  for(let stir=1;stir<=12;stir++){
    const old=[...bowls];
    const savedSum=SAVE(old.reduce((sum,v)=>sum+v,0n)+149n*BigInt(stir));
    const rank=regularMod(savedSum-1n,720n)+1n;
    const order=bowlOrderFromNumber(rank);
    const staged=[...old];
    for(let pos=1;pos<=6;pos++){
      const id=order[pos-1]!;
      const prev=order[(pos+4)%6]!,next=order[pos%6]!;
      const mixed=old[id-1]!+3n*old[prev-1]!+5n*old[next-1]!+
        savedSum+BigInt(stir)+BigInt(pos*pos);
      staged[id-1]=SAVE(mixed*mixed+7n*old[prev-1]!*old[next-1]!);
    }
    bowls=Object.freeze(staged);
    orders.push(Object.freeze([...order]));
    bowlHistory.push(bowls);
  }
  return Object.freeze({orders:Object.freeze(orders),history:Object.freeze(bowlHistory),
    finalBowls:bowls,finalOrder:orders[11]!});
}
