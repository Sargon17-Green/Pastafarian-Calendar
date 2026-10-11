import { BaseMetricsManager, bootstrapMonster, MonsterStageError, MonsterValidationError } from "./monsterBase.ts";
import type { MonsterContext } from "./monsterBase.ts";

// DISCOVERY 08: मूळ 0-based factoradic कर्ता फक्त 0..719 साठी वैध आहे.
// जुना caller थेंबाचे bigint मूल्य थेट rank0 मानत होता; 1-based
// आणि mod(720) दुरुस्ती Stage 17 पर्यंत लागू केलेली नाही.
export type LegacyPermutationObservation = Readonly<{
  readonly dropValue: bigint;
  readonly legacyRank0: bigint;
  readonly legacyAccepted: boolean;
  readonly legacyOrder: readonly number[] | null;
  readonly legacyRejection: "OUT_OF_RANGE" | null;
  readonly context: MonsterContext;
}>;

export class LegacyPermutationUnrankAdapter {
  oldPermutationUnrank0(rank0: bigint): readonly number[] {
    if (typeof rank0 !== "bigint" || rank0 < 0n || rank0 >= 720n) {
      throw new MonsterValidationError("जुन्या क्रमचयाचा शून्याधारित दर्जा 0..719 हवा");
    }
    const remaining = [1, 2, 3, 4, 5, 6];
    const permutation: number[] = [];
    let residual = rank0;
    // factoradic ही जुनी स्वतःची गणना; test-only oracle वापरलेला नाही.
    let placeFactorial = 120n; // 5!
    for (let slots = 6; slots >= 1; slots -= 1) {
      const position = Number(residual / placeFactorial);
      residual %= placeFactorial;
      permutation.push(remaining.splice(position, 1)[0]!);
      if (slots > 1) placeFactorial /= BigInt(slots - 1);
    }
    return Object.freeze(permutation);
  }
}

export class Discovery08PermutationHandler {
  private readonly legacy = new LegacyPermutationUnrankAdapter();
  private readonly metrics = new BaseMetricsManager();

  run(ctx: MonsterContext, dropValue: bigint): LegacyPermutationObservation {
    if (ctx.phase !== "READY" || ctx.status !== "VALIDATED") {
      throw new MonsterStageError("क्रमचय शोधापूर्वी तयार संदर्भ आवश्यक आहे");
    }
    if (typeof ctx.calculationDay !== "bigint" || typeof ctx.targetDay !== "bigint") {
      throw new MonsterValidationError("दोन्ही दिवस अचूक bigint असावेत");
    }
    if (typeof dropValue !== "bigint") {
      throw new MonsterValidationError("थेंब अचूक bigint असावा");
    }

    // ऐतिहासिक दोष: थेंब थेट rank0 आहे; 1-based normalization अजून नाही.
    const legacyRank0 = dropValue;
    let legacyOrder: readonly number[] | null = null;
    let legacyRejection: "OUT_OF_RANGE" | null = null;
    try {
      legacyOrder = this.legacy.oldPermutationUnrank0(legacyRank0);
    } catch (error) {
      if (!(error instanceof MonsterValidationError)) throw error;
      legacyRejection = "OUT_OF_RANGE";
    }
    ctx.branchTrace.push("DISCOVERY_08_DROP_AS_RAW_ZERO_BASED_RANK");
    ctx.branchTrace.push(legacyOrder === null ?
      "DISCOVERY_08_LEGACY_RANK_REJECTED" : "DISCOVERY_08_LEGACY_RANK_ACCEPTED");
    this.metrics.bump(ctx, "discovery08.calls");
    this.metrics.bump(ctx, legacyOrder === null ?
      "discovery08.legacy_rejections" : "discovery08.legacy_accepted");
    ctx.status = "DISCOVERY_08_RECORDED";

    return Object.freeze({
      dropValue, legacyRank0, legacyAccepted: legacyOrder !== null,
      legacyOrder, legacyRejection, context: ctx
    });
  }
}

export function discoverLegacyPermutation(
  calculationDay: bigint, targetDay: bigint, dropValue: bigint
): LegacyPermutationObservation {
  return new Discovery08PermutationHandler().run(
    bootstrapMonster(calculationDay, targetDay), dropValue
  );
}
