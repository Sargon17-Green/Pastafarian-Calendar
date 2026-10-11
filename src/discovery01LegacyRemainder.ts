import { BaseMetricsManager, bootstrapMonster, MonsterStageError, MonsterValidationError } from "./monsterBase.ts";
import type { MonsterContext } from "./monsterBase.ts";

// ऐतिहासिक फॉर्म्युला: 1..M या जतन-श्रेणीऐवजी 0..M-1 या नेहमीच्या शेष-श्रेणीचा वापर.
// हा दोष पुढील PATCH 01 पर्यंत मुद्दाम जतन केला आहे; या फाइलमध्ये दुरुस्ती नाही.
export const LEGACY_MODULUS = (1n << 127n) - 1n;

export type Discovery01Observation = Readonly<{
  input: bigint;
  legacyValue: bigint;
  context: MonsterContext;
}>;

export class LegacyRemainderAdapter {
  regularRemainder(value: bigint): bigint {
    if (typeof value !== "bigint") {
      throw new MonsterValidationError("ऐतिहासिक शेषासाठी अचूक bigint आवश्यक आहे");
    }
    const remainder = value % LEGACY_MODULUS;
    return remainder < 0n ? remainder + LEGACY_MODULUS : remainder;
  }
}

export class Discovery01RemainderHandler {
  run(ctx: MonsterContext, value: bigint): Discovery01Observation {
    if (ctx.phase !== "READY" || ctx.status !== "VALIDATED") {
      throw new MonsterStageError("शेष-शोधापूर्वी मूलभूत पडताळणी पूर्ण झाली पाहिजे");
    }
    if (typeof value !== "bigint") {
      throw new MonsterValidationError("शेष-शोधासाठी अचूक bigint आवश्यक आहे");
    }
    ctx.branchTrace.push("DISCOVERY_01_LEGACY_REMAINDER");
    const legacyValue = new LegacyRemainderAdapter().regularRemainder(value);
    new BaseMetricsManager().bump(ctx, "discovery01.calls");
    ctx.status = "DISCOVERY_01_RECORDED";
    return Object.freeze({ input: value, legacyValue, context: ctx });
  }
}

export function discoverLegacyRemainder(
  calculationDay: bigint,
  targetDay: bigint,
  value: bigint
): Discovery01Observation {
  const ctx = bootstrapMonster(calculationDay, targetDay);
  return new Discovery01RemainderHandler().run(ctx, value);
}
