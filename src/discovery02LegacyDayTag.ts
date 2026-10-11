import { BaseMetricsManager, bootstrapMonster, MonsterStageError, MonsterValidationError } from "./monsterBase.ts";
import type { MonsterContext } from "./monsterBase.ts";

// DISCOVERY 02: ऐतिहासिक दिवस-चिन्हात पाया-दिवशी आणि त्यापुढे +1 हरवलेले आहे.
// पुढील PATCH 02 येईपर्यंत oldDayTag तंतोतंत सदोष ठेवायचे.
export const LEGACY_FOUNDATION_DAY = -15_055_671n;

export type Discovery02Observation = Readonly<{
  calculationDay: bigint;
  targetDay: bigint;
  legacyActionTag: bigint;
  legacyTargetTag: bigint;
  context: MonsterContext;
}>;

export class LegacyDayTagAdapter {
  oldDayTag(day: bigint): bigint {
    if (typeof day !== "bigint") throw new MonsterValidationError("दिवस bigint असला पाहिजे");
    const difference = day - LEGACY_FOUNDATION_DAY;
    return 2n * (difference < 0n ? -difference : difference);
  }
}

export class Discovery02DayTagHandler {
  private readonly legacy = new LegacyDayTagAdapter();
  private readonly metrics = new BaseMetricsManager();

  run(ctx: MonsterContext): Discovery02Observation {
    if (ctx.phase !== "READY" || ctx.status !== "VALIDATED") {
      throw new MonsterStageError("दिवस-शोधापूर्वी वैध संदर्भ-अवस्था आवश्यक आहे");
    }
    if (typeof ctx.calculationDay !== "bigint" || typeof ctx.targetDay !== "bigint") {
      throw new MonsterValidationError("दोन्ही दिवस bigint असले पाहिजेत");
    }
    const legacyActionTag = this.legacy.oldDayTag(ctx.calculationDay);
    const legacyTargetTag = this.legacy.oldDayTag(ctx.targetDay);
    ctx.branchTrace.push("DISCOVERY_02_LEGACY_DAY_TAG");
    this.metrics.bump(ctx, "discovery02.calls");
    this.metrics.bump(ctx, "discovery02.days");
    this.metrics.bump(ctx, "discovery02.days");
    ctx.status = "DISCOVERY_02_RECORDED";
    return Object.freeze({
      calculationDay: ctx.calculationDay,
      targetDay: ctx.targetDay,
      legacyActionTag,
      legacyTargetTag,
      context: ctx
    });
  }
}

export function discoverLegacyDayTags(calculationDay: bigint, targetDay: bigint): Discovery02Observation {
  const ctx = bootstrapMonster(calculationDay, targetDay);
  return new Discovery02DayTagHandler().run(ctx);
}
