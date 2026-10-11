import { BaseMetricsManager, bootstrapMonster, MonsterStageError, MonsterValidationError } from "./monsterBase.ts";
import type { MonsterContext } from "./monsterBase.ts";
import { LegacyPermutationUnrankAdapter } from "./discovery08LegacyPermutation.ts";

// PATCH 08: ऐतिहासिक तीन पायऱ्या मुद्दाम वेगळ्या ठेवल्या आहेत.
// (1) oneBased=regularMod(drop-1,720)+1, (2) legacyRank0=oneBased-1,
// (3) जुन्याच oldPermutationUnrank0(legacyRank0) helper ला खरी call.
// जुन्या raw-drop caller ला स्पर्श नाही; Stage 18 च्या bowl alias ला स्पर्श नाही.
export type Patch08PermutationObservation = Readonly<{
  dropValue: bigint;
  oneBased: bigint;
  legacyRank0: bigint;
  order: readonly number[];
  legacyCalled: true;
  rawLegacyWouldReject: boolean;
  context: MonsterContext;
}>;

export class Patch08PermutationHandler {
  private readonly legacy = new LegacyPermutationUnrankAdapter();
  private readonly metrics = new BaseMetricsManager();

  private regularMod(value: bigint, divisor: bigint): bigint {
    const r = value % divisor;
    return r < 0n ? r + divisor : r;
  }

  run(ctx: MonsterContext, dropValue: bigint): Patch08PermutationObservation {
    if (ctx.phase !== "READY" || ctx.status !== "VALIDATED") {
      throw new MonsterStageError("क्रमचय दुरुस्तीपूर्वी तयार संदर्भ आवश्यक आहे");
    }
    if (typeof ctx.calculationDay !== "bigint" || typeof ctx.targetDay !== "bigint") {
      throw new MonsterValidationError("दोन्ही दिवस bigint असणे आवश्यक");
    }
    if (typeof dropValue !== "bigint") {
      throw new MonsterValidationError("थेंब bigint असणे आवश्यक");
    }

    // एकावर आधारित क्रम वेगळा मोजला जातो, zero-based शॉर्टकट नाही.
    const oneBased = this.regularMod(dropValue - 1n, 720n) + 1n;
    const legacyRank0 = oneBased - 1n;
    const order = this.legacy.oldPermutationUnrank0(legacyRank0);
    const rawLegacyWouldReject = dropValue < 0n || dropValue >= 720n;

    // अपवादाशिवाय वाचन पूर्ण झाल्यावरच संदर्भामध्ये दृश्यमान बदल.
    ctx.branchTrace.push("PATCH_08_ONE_BASED_MOD_720");
    this.metrics.bump(ctx, "patch08.one_based_normalizations");
    ctx.branchTrace.push("PATCH_08_SUBTRACT_ONE_FOR_LEGACY");
    this.metrics.bump(ctx, "patch08.rank0_conversions");
    ctx.branchTrace.push("PATCH_08_REAL_OLD_PERMUTATION_UNRANK0");
    this.metrics.bump(ctx, "patch08.legacy_calls");
    this.metrics.bump(ctx, "patch08.calls");
    this.metrics.bump(ctx, rawLegacyWouldReject ?
      "patch08.raw_legacy_rejections_avoided" : "patch08.raw_legacy_shift_fixed");
    ctx.status = "PATCH_08_APPLIED";

    return Object.freeze({
      dropValue, oneBased, legacyRank0, order,
      legacyCalled: true, rawLegacyWouldReject, context: ctx
    });
  }
}

export function patch08Permutation(
  calculationDay: bigint, targetDay: bigint, dropValue: bigint
): Patch08PermutationObservation {
  return new Patch08PermutationHandler().run(
    bootstrapMonster(calculationDay, targetDay), dropValue
  );
}
