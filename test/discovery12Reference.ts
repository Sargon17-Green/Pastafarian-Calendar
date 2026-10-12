// स्वतंत्र test-only canonical successor: queried bowl ID शोधून त्या
// permutation-position नंतरचा cyclic element; numeric bowl ID increment नाही.
export function canonicalNextBowl(order:readonly number[],queriedId:number):number {
  if(!Array.isArray(order)||order.length!==6||
     order.some(v=>!Number.isInteger(v)||v<1||v>6)||
     new Set(order).size!==6||
     !Number.isInteger(queriedId)||queriedId<1||queriedId>6)
    throw new RangeError("वैध 6-bowl order व queried bowl ID आवश्यक");
  const position=order.indexOf(queriedId);
  if(position<0)throw new RangeError("queried bowl ID permutation मध्ये नाही");
  return order[(position+1)%order.length]!;
}
