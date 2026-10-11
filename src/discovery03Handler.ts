import { BaseMetricsManager, bootstrapMonster, MonsterStageError, MonsterValidationError } from "./monsterBase.ts";
import type { MonsterContext } from "./monsterBase.ts";
import { oldDistance } from "./discovery03LegacyDistance.ts";

export type Discovery03DistanceObservation = Readonly<{
  calculationDay: bigint;
  targetDay: bigint;
  legacyDistance: bigint;
  context: MonsterContext;
}>;

// ऐतिहासिक दोषाचा पुरावा अपरिवर्तित: फक्त संदर्भ-अवस्थेची सुरक्षा.
export class Discovery03DistanceHandler {
  private readonly metrics = new BaseMetricsManager();

  run(ctx: MonsterContext): Discovery03DistanceObservation {
    if (ctx.phase !== "READY" || ctx.status !== "VALIDATED") {
      throw new MonsterStageError("अंतर-शोधापूर्वी वैध संदर्भ-अवस्था आवश्यक आहे");
    }
    if (typeof ctx.calculationDay !== "bigint" || typeof ctx.targetDay !== "bigint") {
      throw new MonsterValidationError("दोन्ही दिवस अचूक bigint असले पाहिजेत");
    }
    const legacyDistance = oldDistance(ctx.calculationDay, ctx.targetDay);
    ctx.branchTrace.push("DISCOVERY_03_TAG_DISTANCE");
    this.metrics.bump(ctx, "discovery03.calls");
    ctx.status = "DISCOVERY_03_RECORDED";
    return Object.freeze({
      calculationDay: ctx.calculationDay,
      targetDay: ctx.targetDay,
      legacyDistance,
      context: ctx
    });
  }
}

export function discoverLegacyDistance(calculationDay: bigint, targetDay: bigint): Discovery03DistanceObservation {
  return new Discovery03DistanceHandler().run(bootstrapMonster(calculationDay, targetDay));
}
