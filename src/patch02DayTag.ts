import { BaseMetricsManager, bootstrapMonster, MonsterStageError, MonsterValidationError } from "./monsterBase.ts";
import type { MonsterContext } from "./monsterBase.ts";
import { LEGACY_FOUNDATION_DAY, LegacyDayTagAdapter } from "./discovery02LegacyDayTag.ts";

// PATCH 02: जुन्या oldDayTag सूत्राला न बदलता दोन ऐतिहासिक सुधारणा-अटी लागू करा.
// दुसरी अट गणितानुसार निष्प्रभावी आहे, तरी ती बंधनकारक ऐतिहासिक scar आहे.
export type Patch02DayEvidence = Readonly<{
  inputDay: bigint;
  legacyTag: bigint;
  correctedTag: bigint;
  incremented: boolean;
  foundationScarChecked: boolean;
  foundationScarForced: boolean;
}>;

export type Patch02DayTagObservation = Readonly<{
  calculationDay: bigint;
  targetDay: bigint;
  action: Patch02DayEvidence;
  target: Patch02DayEvidence;
  context: MonsterContext;
}>;

export class Patch02DayTagHandler {
  private readonly legacy = new LegacyDayTagAdapter();
  private readonly metrics = new BaseMetricsManager();

  private repair(day: bigint): Patch02DayEvidence {
    const legacyTag = this.legacy.oldDayTag(day);
    let n = legacyTag;
    const incremented = day >= LEGACY_FOUNDATION_DAY;
    if (day >= LEGACY_FOUNDATION_DAY) n += 1n;

    const foundationScarChecked = day === LEGACY_FOUNDATION_DAY;
    let foundationScarForced = false;
    if (day === LEGACY_FOUNDATION_DAY && n !== 1n) {
      n = 1n;
      foundationScarForced = true;
    }
    return Object.freeze({
      inputDay: day, legacyTag, correctedTag: n,
      incremented, foundationScarChecked, foundationScarForced
    });
  }

  private recordDay(ctx: MonsterContext, role: "ACTION" | "TARGET", day: Patch02DayEvidence): void {
    ctx.branchTrace.push(`PATCH_02_${role}_${day.incremented ? "PLUS_ONE" : "UNCHANGED"}`);
    this.metrics.bump(ctx, "patch02.days_evaluated");
    if (day.incremented) this.metrics.bump(ctx, "patch02.plus_one");
    if (day.foundationScarChecked) {
      ctx.branchTrace.push(`PATCH_02_${role}_FOUNDATION_SCAR_CHECK`);
      this.metrics.bump(ctx, "patch02.scar_checked");
    }
    if (day.foundationScarForced) this.metrics.bump(ctx, "patch02.scar_forced");
  }

  run(ctx: MonsterContext): Patch02DayTagObservation {
    if (ctx.phase !== "READY" || ctx.status !== "VALIDATED") {
      throw new MonsterStageError("दिवस-चिन्ह दुरुस्तीपूर्वी वैध संदर्भ-अवस्था आवश्यक आहे");
    }
    if (typeof ctx.calculationDay !== "bigint" || typeof ctx.targetDay !== "bigint") {
      throw new MonsterValidationError("दोन्ही दिवस अचूक bigint असले पाहिजेत");
    }
    const action = this.repair(ctx.calculationDay);
    const target = this.repair(ctx.targetDay);
    ctx.branchTrace.push("PATCH_02_LEGACY_DAY_TAG");
    this.recordDay(ctx, "ACTION", action);
    this.recordDay(ctx, "TARGET", target);
    this.metrics.bump(ctx, "patch02.calls");
    ctx.status = "PATCH_02_APPLIED";
    return Object.freeze({
      calculationDay: ctx.calculationDay, targetDay: ctx.targetDay,
      action, target, context: ctx
    });
  }
}

export function patch02DayTags(calculationDay: bigint, targetDay: bigint): Patch02DayTagObservation {
  return new Patch02DayTagHandler().run(bootstrapMonster(calculationDay, targetDay));
}
