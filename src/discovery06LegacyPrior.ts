import { BaseMetricsManager, bootstrapMonster, MonsterStageError, MonsterValidationError } from "./monsterBase.ts";
import type { MonsterContext } from "./monsterBase.ts";

// DISCOVERY 06: जुना history reader फक्त visible dropStore[i-back] वाचतो.
// slot <= 0 असताना मागचे hidden1..hidden7 त्याला मुळीच समजत नाहीत.
// Stage 13 मध्येच hidden fallback; येथे कोणतीही दुरुस्ती नाही.
export type Discovery06PriorObservation = Readonly<{
  dropIndex: number;
  back: 1 | 3 | 7;
  historySlot: number;
  legacyValue: bigint | undefined;
  legacyFound: boolean;
  inputVisibleStore: readonly (bigint | undefined)[];
  context: MonsterContext;
}>;

export class LegacyVisiblePriorAdapter {
  legacyPrior(
    dropStore: readonly (bigint | undefined)[],
    i: number,
    back: 1 | 3 | 7
  ): bigint | undefined {
    if (!Array.isArray(dropStore) || !Number.isInteger(i) || i < 1 || i > 46 ||
        (back !== 1 && back !== 3 && back !== 7)) {
      throw new MonsterValidationError("visible drop क्रम 1..46 आणि मागे 1/3/7 आवश्यक आहे");
    }
    // मूळ ऐतिहासिक expression: negative/zero slots साठी कोणताही hidden branch नाही.
    return dropStore[i - back];
  }
}

export class Discovery06PriorHandler {
  private readonly legacy = new LegacyVisiblePriorAdapter();
  private readonly metrics = new BaseMetricsManager();

  run(ctx: MonsterContext, dropStore: readonly (bigint | undefined)[],
      i: number, back: 1 | 3 | 7): Discovery06PriorObservation {
    if (ctx.phase !== "READY" || ctx.status !== "VALIDATED") {
      throw new MonsterStageError("पूर्वीच्या थेंबाचा शोध घेण्यासाठी वैध संदर्भ आवश्यक आहे");
    }
    if (typeof ctx.calculationDay !== "bigint" || typeof ctx.targetDay !== "bigint") {
      throw new MonsterValidationError("दोन्ही दिवस bigint असले पाहिजेत");
    }
    if (!Array.isArray(dropStore) || !Number.isInteger(i) || i < 1 || i > 46 ||
        (back !== 1 && back !== 3 && back !== 7)) {
      throw new MonsterValidationError("visible history input किंवा back अवैध आहे");
    }
    const historySlot = i - back;
    const legacyValue = this.legacy.legacyPrior(dropStore,i,back);
    if (legacyValue !== undefined && typeof legacyValue !== "bigint") {
      throw new MonsterValidationError("जुन्या history slot मध्ये गैर-bigint मूल्य आहे");
    }
    if (historySlot >= 1 && typeof legacyValue !== "bigint") {
      throw new MonsterValidationError("मागील visible slot मध्ये bigint आवश्यक आहे");
    }

    const inputVisibleStore = Object.freeze(
      Array.from({length: dropStore.length},(_,index)=>dropStore[index])
    );
    ctx.branchTrace.push("DISCOVERY_06_LEGACY_PRIOR_VISIBLE_ONLY");
    ctx.branchTrace.push(
      historySlot < 1 ? "DISCOVERY_06_MISSING_HIDDEN_HISTORY" : "DISCOVERY_06_VISIBLE_HISTORY_FOUND"
    );
    this.metrics.bump(ctx,"discovery06.calls");
    if (historySlot < 1) this.metrics.bump(ctx,"discovery06.hidden_slots_not_supported");
    else this.metrics.bump(ctx,"discovery06.visible_slots_supported");
    ctx.status="DISCOVERY_06_RECORDED";
    return Object.freeze({
      dropIndex:i,back,historySlot,legacyValue,legacyFound:legacyValue!==undefined,
      inputVisibleStore,context:ctx
    });
  }
}

export function discoverLegacyPrior(
  calculationDay:bigint,targetDay:bigint,
  dropStore:readonly (bigint | undefined)[], i:number,back:1|3|7
):Discovery06PriorObservation {
  return new Discovery06PriorHandler().run(bootstrapMonster(calculationDay,targetDay),dropStore,i,back);
}
