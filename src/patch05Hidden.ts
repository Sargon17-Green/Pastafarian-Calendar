import { BaseMetricsManager, bootstrapMonster, MonsterStageError, MonsterValidationError } from "./monsterBase.ts";
import type { MonsterContext } from "./monsterBase.ts";
import { LegacyBackwardHiddenAdapter } from "./discovery05LegacyHidden.ts";

export type Patch05HiddenObservation = Readonly<{
  calculationDay: bigint;
  targetDay: bigint;
  sourceInCanonicalOrder: readonly bigint[];
  backwardStored: readonly bigint[];
  legacyReads: readonly bigint[];
  correctedReads: readonly bigint[];
  correctedSlotsOneBased: readonly number[];
  mismatchesRepaired: number;
  context: MonsterContext;
}>;

// PATCH 05: जुने hidden7..hidden1 storage जसाच्या तसे राहते.
// corrected hidden k हा उलट्या storage मधील zero-based 7-k क्रमांकावर आहे.
// जुना oldHiddenAt प्रत्यक्ष चालवून त्याचा चुकीचा पुरावाही जतन करतो.
export class Patch05HiddenHandler {
  private readonly historical = new LegacyBackwardHiddenAdapter();
  private readonly metrics = new BaseMetricsManager();

  correctedHiddenAt(backwardStored: readonly bigint[], hiddenK: number): bigint {
    if (!Array.isArray(backwardStored) || backwardStored.length !== 7 ||
        Array.from({length:7}, (_,j) => typeof backwardStored[j] !== "bigint").some(Boolean)) {
      throw new MonsterValidationError("सात अचूक bigint थेंबांचे उलटे storage आवश्यक आहे");
    }
    if (!Number.isInteger(hiddenK) || hiddenK < 1 || hiddenK > 7) {
      throw new MonsterValidationError("hidden k हा 1 ते 7 मधील पूर्णांक आवश्यक आहे");
    }
    return backwardStored[7 - hiddenK]!;
  }

  run(ctx: MonsterContext, canonicalHidden: readonly bigint[]): Patch05HiddenObservation {
    if (ctx.phase !== "READY" || ctx.status !== "VALIDATED") {
      throw new MonsterStageError("लपलेले थेंब दुरुस्त करण्यापूर्वी वैध संदर्भ आवश्यक आहे");
    }
    if (typeof ctx.calculationDay !== "bigint" || typeof ctx.targetDay !== "bigint") {
      throw new MonsterValidationError("दोन्ही दिवस अचूक bigint असले पाहिजेत");
    }
    if (!Array.isArray(canonicalHidden) || canonicalHidden.length !== 7 ||
        Array.from({length:7}, (_,j) => typeof canonicalHidden[j] !== "bigint").some(Boolean)) {
      throw new MonsterValidationError("नेमके सात bigint लपलेले थेंब आवश्यक आहेत");
    }

    const sourceInCanonicalOrder = Object.freeze([...canonicalHidden]);
    // Legacy storage आणि प्रत्येक जुने वाचन खऱ्या इतिहासातील adapter वरून.
    const backwardStored = this.historical.storeBackward(sourceInCanonicalOrder);
    const legacyReads = Object.freeze(
      Array.from({length: 7}, (_, j) => this.historical.oldHiddenAt(backwardStored, j + 1))
    );
    const correctedReads = Object.freeze(
      Array.from({length: 7}, (_, j) => this.correctedHiddenAt(backwardStored, j + 1))
    );
    const correctedSlotsOneBased = Object.freeze(
      Array.from({length: 7}, (_, j) => 7 - j)
    );
    let mismatchesRepaired = 0;
    for (let k = 0; k < 7; k++) {
      if (legacyReads[k] !== correctedReads[k]) mismatchesRepaired++;
    }

    // फक्त यशस्वी मोजणीनंतर observable context बदलायचा.
    ctx.branchTrace.push("PATCH_05_LEGACY_STORE_HIDDEN_7_TO_1");
    ctx.branchTrace.push("PATCH_05_REAL_LEGACY_READS");
    ctx.branchTrace.push("PATCH_05_CORRECTED_SLOT_8_MINUS_K");
    this.metrics.bump(ctx, "patch05.calls");
    for (let k = 0; k < 7; k++) {
      this.metrics.bump(ctx, "patch05.legacy_reads");
      this.metrics.bump(ctx, "patch05.corrected_reads");
    }
    for (let k = 0; k < mismatchesRepaired; k++) {
      this.metrics.bump(ctx, "patch05.legacy_mismatches");
    }
    ctx.status = "PATCH_05_APPLIED";

    return Object.freeze({
      calculationDay: ctx.calculationDay, targetDay: ctx.targetDay,
      sourceInCanonicalOrder, backwardStored, legacyReads, correctedReads,
      correctedSlotsOneBased, mismatchesRepaired, context: ctx
    });
  }
}

export function patch05HiddenDrops(
  calculationDay: bigint, targetDay: bigint, canonicalHidden: readonly bigint[]
): Patch05HiddenObservation {
  return new Patch05HiddenHandler().run(
    bootstrapMonster(calculationDay, targetDay), canonicalHidden
  );
}
