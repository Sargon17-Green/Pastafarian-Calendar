import { BaseMetricsManager, bootstrapMonster, MonsterStageError, MonsterValidationError } from "./monsterBase.ts";
import type { MonsterContext } from "./monsterBase.ts";
import { patch01Save } from "./patch01Save.ts";
import { patch08Permutation } from "./patch08Permutation.ts";
// जुन्या तीन pours मध्ये position 1..3 म्हणजे कायम bowls 1..3.
export class LegacyFixedBowlPoursAdapter {
  legacyFixedPours(c:bigint,t:bigint,i:number,d:bigint,b:readonly bigint[],s:readonly bigint[]):readonly bigint[]{
    const weights=[3n,5n,7n] as const;
    return Object.freeze(weights.map((w,k)=>
      patch01Save(c,t,d*d+s[k]!*b[k]!+w*BigInt(i)).savedValue));
  }
}
export class Discovery09FixedPoursHandler {
  private readonly legacy=new LegacyFixedBowlPoursAdapter();
  private readonly metrics=new BaseMetricsManager();
  run(ctx:MonsterContext,i:number,d:bigint,b:readonly bigint[],s:readonly bigint[]){
    if(ctx.phase!=="READY"||ctx.status!=="VALIDATED")throw new MonsterStageError("तयार context आवश्यक");
    if(typeof ctx.calculationDay!=="bigint"||typeof ctx.targetDay!=="bigint"||
       !Number.isInteger(i)||i<1||i>46||typeof d!=="bigint"||
       !Array.isArray(b)||b.length!==6||Array.from({length:6},(_,k)=>typeof b[k]!=="bigint").some(Boolean)||
       !Array.isArray(s)||s.length!==5||Array.from({length:5},(_,k)=>typeof s[k]!=="bigint").some(Boolean))
      throw new MonsterValidationError("वैध index, bigint थेंब, bowls व stones आवश्यक");
    const order=patch08Permutation(ctx.calculationDay,ctx.targetDay,d).order;
    const legacyPours=this.legacy.legacyFixedPours(ctx.calculationDay,ctx.targetDay,i,d,b,s);
    const inputBowls=Object.freeze([...b]),inputStone=Object.freeze([...s]);
    ctx.branchTrace.push("DISCOVERY_09_CORRECT_ORDER_OBSERVED","DISCOVERY_09_FIXED_1_2_3");
    this.metrics.bump(ctx,"discovery09.calls");
    for(let k=0;k<3;k++)this.metrics.bump(ctx,order[k]===k+1?"discovery09.matches":"discovery09.conflicts");
    ctx.status="DISCOVERY_09_RECORDED";
    return Object.freeze({dropIndex:i,dropValue:d,order,legacyPours,
      fixedBowlIds:Object.freeze([1,2,3]),inputBowls,inputStone,context:ctx});
  }
}
export function discoverLegacyFixedPours(c:bigint,t:bigint,i:number,d:bigint,
 b:readonly bigint[],s:readonly bigint[]){
  return new Discovery09FixedPoursHandler().run(bootstrapMonster(c,t),i,d,b,s);
}
