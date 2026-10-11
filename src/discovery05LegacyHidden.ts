import { BaseMetricsManager, bootstrapMonster, MonsterStageError, MonsterValidationError } from "./monsterBase.ts";
import type { MonsterContext } from "./monsterBase.ts";

// DISCOVERY 05: hidden7,hidden6,...,hidden1 हे जुने storage कायम आहे.
// Stage 11 पूर्वी index=8-k ची दुरुस्ती किंवा storage उलटवून सरळ करणे नाही.
export type Discovery05HiddenObservation = Readonly<{
  calculationDay: bigint;
  targetDay: bigint;
  sourceInCanonicalOrder: readonly bigint[];
  backwardStored: readonly bigint[];
  legacyReads: readonly bigint[];
  context: MonsterContext;
}>;

function assertSevenBigints(values: readonly bigint[]): void {
  if (!Array.isArray(values) || values.length !== 7) {
    throw new MonsterValidationError("नेमक्या सात लपवलेल्या bigint थेंबांची यादी आवश्यक आहे");
  }
  for (let j = 0; j < 7; j += 1) {
    if (typeof values[j] !== "bigint") {
      throw new MonsterValidationError("प्रत्येक लपवलेला थेंब bigint असला पाहिजे");
    }
  }
}

export class LegacyBackwardHiddenAdapter {
  storeBackward(canonicalHidden: readonly bigint[]): readonly bigint[] {
    assertSevenBigints(canonicalHidden);
    const backward: bigint[] = [];
    for (let k = 7; k >= 1; k -= 1) backward.push(canonicalHidden[k - 1]!);
    return Object.freeze(backward);
  }

  // ऐतिहासिक चूक: storage आधीच उलटे असतानाही सामान्य k-1 slot वापरला जातो.
  oldHiddenAt(stored: readonly bigint[], hiddenK: number): bigint {
    assertSevenBigints(stored);
    if (!Number.isInteger(hiddenK) || hiddenK < 1 || hiddenK > 7) {
      throw new MonsterValidationError("hidden k हा 1 ते 7 दरम्यान पूर्णांक हवा");
    }
    return stored[hiddenK - 1]!;
  }
}

export class Discovery05HiddenHandler {
  private readonly legacy = new LegacyBackwardHiddenAdapter();
  private readonly metrics = new BaseMetricsManager();

  run(ctx: MonsterContext, hiddenCanonical: readonly bigint[]): Discovery05HiddenObservation {
    if (ctx.phase !== "READY" || ctx.status !== "VALIDATED") {
      throw new MonsterStageError("लपवलेले थेंब पाहण्यापूर्वी वैध संदर्भ आवश्यक आहे");
    }
    if (typeof ctx.calculationDay !== "bigint" || typeof ctx.targetDay !== "bigint") {
      throw new MonsterValidationError("दोन्ही दिवस अचूक bigint असले पाहिजेत");
    }
    assertSevenBigints(hiddenCanonical);

    const sourceInCanonicalOrder = Object.freeze([...hiddenCanonical]);
    // जुने उलटे storage खऱ्या adapter नेच तयार करणे आवश्यक.
    const backwardStored = this.legacy.storeBackward(sourceInCanonicalOrder);
    const legacyReads = Object.freeze(
      Array.from({ length: 7 }, (_, j) => this.legacy.oldHiddenAt(backwardStored, j + 1))
    );

    // सगळ्या गणना यशस्वी झाल्यानंतरच context बदलतो.
    ctx.branchTrace.push("DISCOVERY_05_STORE_HIDDEN_7_TO_1");
    ctx.branchTrace.push("DISCOVERY_05_READ_UNCORRECTED_SLOTS");
    this.metrics.bump(ctx, "discovery05.calls");
    for (let k = 0; k < 7; k += 1) {
      this.metrics.bump(ctx, "discovery05.hidden_stored");
      this.metrics.bump(ctx, "discovery05.legacy_reads");
    }
    ctx.status = "DISCOVERY_05_RECORDED";
    return Object.freeze({
      calculationDay: ctx.calculationDay, targetDay: ctx.targetDay,
      sourceInCanonicalOrder, backwardStored, legacyReads, context: ctx
    });
  }
}

export function discoverLegacyHiddenStorage(
  calculationDay: bigint, targetDay: bigint, canonicalHidden: readonly bigint[]
): Discovery05HiddenObservation {
  return new Discovery05HiddenHandler().run(
    bootstrapMonster(calculationDay, targetDay), canonicalHidden
  );
}
