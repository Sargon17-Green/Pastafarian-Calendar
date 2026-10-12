import { BaseMetricsManager, bootstrapMonster, MonsterStageError, MonsterValidationError } from "./monsterBase.ts";
import type { MonsterContext } from "./monsterBase.ts";
import { LegacyFixedBowlPoursAdapter } from "./discovery09LegacyFixedPours.ts";
import { patch08Permutation } from "./patch08Permutation.ts";

// PATCH 09: मूळ fixed-ID helper बदलत नाही. त्याला temporary alias-view देतो.
// bowlAlias[position] = order[position]; index 0 निष्प्रभावी sentinel आहे.
export type BowlAliasMap = readonly number[];
export type Patch09PoursObservation = Readonly<{
  dropIndex: number;
  dropValue: bigint;
  order: readonly number[];
  bowlAlias: BowlAliasMap;
  legacyPositionBowlView: readonly bigint[];
  originalBowls: readonly bigint[];
  inputStone: readonly bigint[];
  historicalPours: readonly bigint[];
  correctedPours: readonly bigint[];
  historicalCalls: number;
  aliasCalls: number;
  context: MonsterContext;
}>;

export class LegacyBowlAliasAdapter {
  installOrderAliases(order: readonly number[]): BowlAliasMap {
    if (!Array.isArray(order) || order.length !== 6 ||
        order.some(id => !Number.isInteger(id) || id < 1 || id > 6) ||
        new Set(order).size !== 6) {
      throw new MonsterValidationError("सहा स्वतंत्र वाट्यांचा वैध क्रम हवा");
    }
    return Object.freeze([0, ...order]);
  }

  bowlByLegacyPosition(
    bowls: readonly bigint[], alias: BowlAliasMap, position: number
  ): bigint {
    if (!Number.isInteger(position) || position < 1 || position > 6 ||
        !Array.isArray(bowls) || bowls.length !== 6 ||
        Array.from({length:6},(_,k)=>typeof bowls[k] !== "bigint").some(Boolean) ||
        !Array.isArray(alias) || alias.length !== 7 || alias[0] !== 0 ||
        alias.slice(1).some(x=>!Number.isInteger(x) || x < 1 || x > 6) ||
        new Set(alias.slice(1)).size !== 6) {
      throw new MonsterValidationError("alias position आणि मूळ bowl store वैध हवेत");
    }
    return bowls[alias[position]! - 1]!;
  }

  // एकावेळच्या जुन्या legacy call साठी क्रम-position प्रमाणे virtual bowls.
  // stage20 मध्ये in-place stir आहे; इथे bowl store मध्ये writes अजिबात नाहीत.
  installLegacyPositionView(bowls:readonly bigint[],alias:BowlAliasMap):readonly bigint[] {
    return Object.freeze(Array.from({length:6},(_,k)=>
      this.bowlByLegacyPosition(bowls,alias,k+1)));
  }
}

export class Patch09BowlAliasHandler {
  private readonly old = new LegacyFixedBowlPoursAdapter();
  private readonly alias = new LegacyBowlAliasAdapter();
  private readonly metrics = new BaseMetricsManager();

  run(ctx:MonsterContext,dropIndex:number,dropValue:bigint,
      oldBowls:readonly bigint[],stone:readonly bigint[]):Patch09PoursObservation {
    if(ctx.phase !== "READY" || ctx.status !== "VALIDATED"){
      throw new MonsterStageError("वाटी alias दुरुस्तीपूर्वी तयार context आवश्यक");
    }
    if(typeof ctx.calculationDay !== "bigint" || typeof ctx.targetDay !== "bigint" ||
       !Number.isInteger(dropIndex) || dropIndex < 1 || dropIndex > 46 ||
       typeof dropValue !== "bigint" ||
       !Array.isArray(oldBowls) || oldBowls.length !== 6 ||
       Array.from({length:6},(_,k)=>typeof oldBowls[k] !== "bigint").some(Boolean) ||
       !Array.isArray(stone) || stone.length !== 5 ||
       Array.from({length:5},(_,k)=>typeof stone[k] !== "bigint").some(Boolean)){
      throw new MonsterValidationError("valid bigint, drop index, सहा वाट्या व पाच दगड आवश्यक");
    }

    const order=patch08Permutation(ctx.calculationDay,ctx.targetDay,dropValue).order;
    const bowlAlias=this.alias.installOrderAliases(order);
    const legacyPositionBowlView=this.alias.installLegacyPositionView(oldBowls,bowlAlias);
    // जुना दोष निदानासाठी raw input वर चालतो. तोच helper corrected view वर
    // पुन्हा चालतो. मूळ helper code / historical regression जसाच तसा राहतो.
    const historicalPours=this.old.legacyFixedPours(
      ctx.calculationDay,ctx.targetDay,dropIndex,dropValue,oldBowls,stone);
    const correctedPours=this.old.legacyFixedPours(
      ctx.calculationDay,ctx.targetDay,dropIndex,dropValue,legacyPositionBowlView,stone);
    const originalBowls=Object.freeze([...oldBowls]);
    const inputStone=Object.freeze([...stone]);

    ctx.branchTrace.push("PATCH_09_INSTALL_ORDER_ALIASES");
    ctx.branchTrace.push("PATCH_09_VIRTUAL_BOWL_POSITION_READS");
    ctx.branchTrace.push("PATCH_09_REUSE_FIXED_LEGACY_POURS_WITH_ALIASES");
    this.metrics.bump(ctx,"patch09.calls");
    this.metrics.bump(ctx,"patch09.historical_calls");
    this.metrics.bump(ctx,"patch09.aliased_legacy_calls");
    for(let k=1;k<=6;k++)this.metrics.bump(ctx,"patch09.position_alias_reads");
    for(let k=0;k<3;k++){
      this.metrics.bump(ctx,bowlAlias[k+1]===k+1 ?
        "patch09.accidental_matches_preserved":"patch09.fixed_id_reads_repaired");
    }
    ctx.status="PATCH_09_APPLIED";
    return Object.freeze({dropIndex,dropValue,order,bowlAlias,
      legacyPositionBowlView,originalBowls,inputStone,historicalPours,
      correctedPours,historicalCalls:1,aliasCalls:1,context:ctx});
  }
}

export function patch09Pours(c:bigint,t:bigint,i:number,d:bigint,
 b:readonly bigint[],s:readonly bigint[]):Patch09PoursObservation {
  return new Patch09BowlAliasHandler().run(bootstrapMonster(c,t),i,d,b,s);
}
