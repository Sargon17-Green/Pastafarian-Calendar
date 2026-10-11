import { BaseMetricsManager, bootstrapMonster, MonsterStageError, MonsterValidationError } from "./monsterBase.ts";
import type { MonsterContext } from "./monsterBase.ts";
import { LegacyVisiblePriorAdapter } from "./discovery06LegacyPrior.ts";
import { Patch05HiddenHandler } from "./patch05Hidden.ts";

// PATCH 06: जुना visible इतिहास वाचक कायम आहे. 1-based slot सकारात्मक असेल
// तर त्यालाच प्रत्यक्ष call; slot शून्य/ऋण असेल तर Stage 11 चे corrected
// backward hidden storage वाचन. पुढील टप्प्यांची दुरुस्ती येथे नाही.
export type Patch06PriorObservation = Readonly<{
  dropIndex: number;
  back: 1 | 3 | 7;
  historySlot: number;
  source: "VISIBLE_LEGACY" | "HIDDEN_CORRECTED";
  hiddenK: number | null;
  hiddenStorageIndexZeroBased: number | null;
  legacyCalled: boolean;
  legacyValue: bigint | undefined;
  correctedValue: bigint;
  inputVisibleStore: readonly (bigint | undefined)[];
  inputBackwardStored: readonly bigint[];
  context: MonsterContext;
}>;

export class Patch06PriorHandler {
  private readonly legacy = new LegacyVisiblePriorAdapter();
  private readonly hiddenReader = new Patch05HiddenHandler();
  private readonly metrics = new BaseMetricsManager();

  run(
    ctx: MonsterContext,
    dropStore: readonly (bigint | undefined)[],
    backwardStored: readonly bigint[],
    i: number,
    back: 1 | 3 | 7
  ): Patch06PriorObservation {
    if (ctx.phase !== "READY" || ctx.status !== "VALIDATED") {
      throw new MonsterStageError("इतिहास दुरुस्त करण्यासाठी तयार संदर्भ आवश्यक आहे");
    }
    if (typeof ctx.calculationDay !== "bigint" || typeof ctx.targetDay !== "bigint") {
      throw new MonsterValidationError("दोनही दिवस अचूक bigint असले पाहिजेत");
    }
    if (!Array.isArray(dropStore) || !Number.isInteger(i) || i < 1 || i > 46 ||
        (back !== 1 && back !== 3 && back !== 7)) {
      throw new MonsterValidationError("visible इतिहास, क्रम 1..46 आणि अंतर 1/3/7 वैध हवे");
    }
    if (!Array.isArray(backwardStored) || backwardStored.length !== 7 ||
        Array.from({ length: 7 }, (_, j) => typeof backwardStored[j] !== "bigint").some(Boolean)) {
      throw new MonsterValidationError("hidden7..hidden1 हे सात पूर्ण bigint असले पाहिजेत");
    }

    const historySlot = i - back;
    const source = historySlot >= 1 ? "VISIBLE_LEGACY" : "HIDDEN_CORRECTED";
    const hiddenK = historySlot <= 0 ? 1 - historySlot : null;
    const hiddenStorageIndexZeroBased = hiddenK === null ? null : 7 - hiddenK;
    let legacyValue: bigint | undefined;
    let correctedValue: bigint;

    if (historySlot >= 1) {
      // पूर्ण सकारात्मक history साठी जुनी प्रत्यक्ष call सोडून देता येत नाही.
      legacyValue = this.legacy.legacyPrior(dropStore, i, back);
      if (typeof legacyValue !== "bigint") {
        throw new MonsterValidationError("सकारात्मक visible इतिहासात अचूक bigint आवश्यक आहे");
      }
      correctedValue = legacyValue;
    } else {
      // जुना visible reader मुद्दाम न बोलावता stage 11 ची 8-k दुरुस्ती वापरतो.
      correctedValue = this.hiddenReader.correctedHiddenAt(backwardStored, hiddenK!);
    }

    // input/branch वाचताना अपवाद आला तरी mutable context बदलणार नाही.
    const inputVisibleStore = Object.freeze(Array.from(
      { length: dropStore.length }, (_, j) => dropStore[j]
    ));
    const inputBackwardStored = Object.freeze(
      Array.from({ length: 7 }, (_, j) => backwardStored[j]!)
    );

    ctx.branchTrace.push("PATCH_06_SELECT_HISTORY");
    ctx.branchTrace.push(historySlot >= 1 ?
      "PATCH_06_REAL_LEGACY_VISIBLE" : "PATCH_06_STAGE11_CORRECTED_HIDDEN");
    this.metrics.bump(ctx, "patch06.calls");
    this.metrics.bump(ctx, historySlot >= 1 ?
      "patch06.visible_legacy_calls" : "patch06.hidden_fallbacks");
    ctx.status = "PATCH_06_APPLIED";

    return Object.freeze({
      dropIndex: i, back, historySlot, source, hiddenK, hiddenStorageIndexZeroBased,
      legacyCalled: historySlot >= 1, legacyValue, correctedValue,
      inputVisibleStore, inputBackwardStored, context: ctx
    });
  }
}

export function patch06Prior(
  calculationDay: bigint, targetDay: bigint,
  dropStore: readonly (bigint | undefined)[], backwardStored: readonly bigint[],
  i: number, back: 1 | 3 | 7
): Patch06PriorObservation {
  return new Patch06PriorHandler().run(
    bootstrapMonster(calculationDay, targetDay), dropStore, backwardStored, i, back
  );
}
