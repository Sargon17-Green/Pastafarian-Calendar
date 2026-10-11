import { BaseMetricsManager, bootstrapMonster, MonsterStageError, MonsterValidationError } from "./monsterBase.ts";
import type { MonsterContext } from "./monsterBase.ts";
import { oldDistance } from "./discovery03LegacyDistance.ts";

// PATCH 03: जुना tag-अंतर मार्ग जसाच्या तसा ठेवून फक्त आवश्यक
// कालक्रमानुसार दुरुस्ती व शेवटचा +1 येथे लागू होतात.
export type Patch03DistanceObservation = Readonly<{
  calculationDay: bigint;
  targetDay: bigint;
  legacyDistance: bigint;
  chronologicalDistance: bigint;
  correctedDistanceBeforeOne: bigint;
  distance: bigint;
  legacyOverridden: boolean;
  context: MonsterContext;
}>;

export class Patch03DistanceHandler {
  private readonly metrics = new BaseMetricsManager();

  run(ctx: MonsterContext): Patch03DistanceObservation {
    if (ctx.phase !== "READY" || ctx.status !== "VALIDATED") {
      throw new MonsterStageError("अंतर दुरुस्त करण्यासाठी वैध संदर्भ आवश्यक आहे");
    }
    if (typeof ctx.calculationDay !== "bigint" || typeof ctx.targetDay !== "bigint") {
      throw new MonsterValidationError("दोन्ही दिवस अचूक bigint असले पाहिजेत");
    }

    const legacyDistance = oldDistance(ctx.calculationDay, ctx.targetDay);
    const difference = ctx.targetDay - ctx.calculationDay;
    const chronologicalDistance = difference < 0n ? -difference : difference;

    let correctedDistanceBeforeOne = legacyDistance;
    const legacyOverridden = legacyDistance !== chronologicalDistance;
    if (legacyDistance !== chronologicalDistance) {
      correctedDistanceBeforeOne = chronologicalDistance;
    }
    const distance = correctedDistanceBeforeOne + 1n;

    // सर्व पूर्वगणना यशस्वी झाल्यावरच बाहेरून दिसणारी संदर्भ-अवस्था बदला.
    ctx.branchTrace.push("PATCH_03_LEGACY_TAG_DISTANCE");
    ctx.branchTrace.push(
      legacyOverridden ? "PATCH_03_USE_CHRONOLOGICAL" : "PATCH_03_KEEP_LEGACY"
    );
    ctx.branchTrace.push("PATCH_03_PLUS_ONE");
    this.metrics.bump(ctx, "patch03.calls");
    if (legacyOverridden) this.metrics.bump(ctx, "patch03.legacy_overridden");
    else this.metrics.bump(ctx, "patch03.legacy_preserved");
    ctx.status = "PATCH_03_APPLIED";

    return Object.freeze({
      calculationDay: ctx.calculationDay,
      targetDay: ctx.targetDay,
      legacyDistance,
      chronologicalDistance,
      correctedDistanceBeforeOne,
      distance,
      legacyOverridden,
      context: ctx
    });
  }
}

export function patch03Distance(calculationDay: bigint, targetDay: bigint): Patch03DistanceObservation {
  return new Patch03DistanceHandler().run(bootstrapMonster(calculationDay, targetDay));
}
