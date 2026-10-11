import { BaseMetricsManager, bootstrapMonster, MonsterStageError, MonsterValidationError } from "./monsterBase.ts";
import type { MonsterContext } from "./monsterBase.ts";
import { LEGACY_MODULUS, LegacyRemainderAdapter } from "./discovery01LegacyRemainder.ts";

// PATCH 01: ऐतिहासिक शेष-वर्ग 0..M-1 ऐवजी नियमाधारित SAVE श्रेणी 1..M.
// ऐतिहासिक adapter न बदलता, फक्त शून्य हा अवशेष M मध्ये रूपांतरित करतो.
// पुढील ऐतिहासिक दोषांचे कोणतेही पूर्वकालीन निराकरण येथे केलेले नाही.
export type Patch01SaveObservation = Readonly<{
  input: bigint;
  legacyValue: bigint;
  savedValue: bigint;
  repairedZero: boolean;
  context: MonsterContext;
}>;

export class Patch01SaveHandler {
  private readonly legacyAdapter = new LegacyRemainderAdapter();
  private readonly metrics = new BaseMetricsManager();

  run(ctx: MonsterContext, value: bigint): Patch01SaveObservation {
    if (ctx.phase !== "READY" || ctx.status !== "VALIDATED") {
      throw new MonsterStageError("SAVE दुरुस्तीपूर्वी मूलभूत पडताळणी आवश्यक आहे");
    }
    if (typeof value !== "bigint") {
      throw new MonsterValidationError("SAVE साठी अचूक bigint आवश्यक आहे");
    }
    ctx.branchTrace.push("PATCH_01_LEGACY_REMAINDER");
    const legacyValue = this.legacyAdapter.regularRemainder(value);
    const repairedZero = legacyValue === 0n;
    const savedValue = repairedZero ? LEGACY_MODULUS : legacyValue;
    ctx.branchTrace.push(repairedZero ? "PATCH_01_ZERO_TO_M" : "PATCH_01_UNCHANGED");
    this.metrics.bump(ctx, "patch01.calls");
    if (repairedZero) this.metrics.bump(ctx, "patch01.zero_repaired");
    ctx.status = "PATCH_01_APPLIED";
    return Object.freeze({ input: value, legacyValue, savedValue, repairedZero, context: ctx });
  }
}

export function patch01Save(
  calculationDay: bigint,
  targetDay: bigint,
  value: bigint
): Patch01SaveObservation {
  const ctx = bootstrapMonster(calculationDay, targetDay);
  return new Patch01SaveHandler().run(ctx, value);
}
