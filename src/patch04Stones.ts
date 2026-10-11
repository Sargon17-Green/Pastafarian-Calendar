import { BaseMetricsManager, bootstrapMonster, MonsterStageError, MonsterValidationError } from "./monsterBase.ts";
import type { MonsterContext } from "./monsterBase.ts";
import { LegacySequentialStoneAdapter } from "./discovery04LegacyStones.ts";
import type { MutableLegacyStone } from "./discovery04LegacyStones.ts";
import { patch01Save } from "./patch01Save.ts";

// PATCH 04: जुनी sequential mutation न पुसता तिची प्रत्यक्ष clone वर
// अंमलबजावणी आणि garbage पुरावा कायम ठेवतो. सर्व योग्य मूल्ये old वरूनच.
export type Patch04StoneObservation = Readonly<{
  stoneIndex: bigint;
  inputStone: readonly bigint[];
  legacyGarbage: readonly bigint[];
  correctedStone: readonly bigint[];
  legacyCalledOnClone: true;
  overwrittenCells: number;
  context: MonsterContext;
}>;

export class Patch04StoneHandler {
  private readonly legacy = new LegacySequentialStoneAdapter();
  private readonly metrics = new BaseMetricsManager();

  run(ctx: MonsterContext, index: bigint, inputStone: readonly bigint[]): Patch04StoneObservation {
    if (ctx.phase !== "READY" || ctx.status !== "VALIDATED") {
      throw new MonsterStageError("दगड सुधारण्यापूर्वी वैध संदर्भ आवश्यक आहे");
    }
    if (typeof ctx.calculationDay !== "bigint" || typeof ctx.targetDay !== "bigint") {
      throw new MonsterValidationError("दोन्ही दिवस bigint असले पाहिजेत");
    }
    if (typeof index !== "bigint" || index < 2n || index > 46n ||
        !Array.isArray(inputStone) || inputStone.length !== 5 ||
        inputStone.some(value => typeof value !== "bigint")) {
      throw new MonsterValidationError("दगड क्रमांक 2..46 आणि पाच bigint मूल्ये आवश्यक आहेत");
    }

    // मूळ input न बदलता old snapshot व legacy mutation साठी स्वतंत्र clone.
    const old = Object.freeze([...inputStone]) as readonly bigint[];
    const clone = [...old] as MutableLegacyStone;
    const returnedLegacy = this.legacy.mutateStonesWrong(
      index, clone, ctx.calculationDay, ctx.targetDay
    );
    if (returnedLegacy !== clone) {
      throw new MonsterStageError("ऐतिहासिक in-place mutation ने clone परत दिला नाही");
    }
    const legacyGarbage = Object.freeze([...clone]);

    // इथून पुढे कोणत्याही नवीन दगडाचे मूल्य इतर नवीन दगडांवर अवलंबत नाही.
    const save = (value: bigint): bigint => patch01Save(
      ctx.calculationDay, ctx.targetDay, value
    ).savedValue;
    const correctedStone = Object.freeze([
      save(old[0]! * old[0]! + 3n * old[1]! + index),
      save(old[1]! * old[1]! + 5n * old[2]! + old[0]!),
      save(old[2]! * old[2]! + 7n * old[3]! + old[1]!),
      save(old[3]! * old[3]! + 11n * old[4]! + old[2]!),
      save(old[4]! * old[4]! + 13n * old[0]! + old[3]!)
    ]);
    let overwrittenCells = 0;
    for (let k = 0; k < 5; k += 1) {
      if (legacyGarbage[k] !== correctedStone[k]) overwrittenCells += 1;
    }

    // दोन्ही गणना पूर्ण झाल्यानंतरच निरीक्षणीय संदर्भ-अवस्था बदलते.
    ctx.branchTrace.push("PATCH_04_SNAPSHOT_OLD");
    ctx.branchTrace.push("PATCH_04_REAL_LEGACY_ON_CLONE");
    ctx.branchTrace.push("PATCH_04_OVERWRITE_ALL_FROM_OLD");
    this.metrics.bump(ctx, "patch04.calls");
    this.metrics.bump(ctx, "patch04.legacy_invocations");
    for (let k = 0; k < 5; k += 1) this.metrics.bump(ctx, "patch04.cells_computed");
    for (let k = 0; k < overwrittenCells; k += 1) this.metrics.bump(ctx, "patch04.cells_changed_from_garbage");
    ctx.status = "PATCH_04_APPLIED";

    return Object.freeze({
      stoneIndex: index,
      inputStone: old,
      legacyGarbage,
      correctedStone,
      legacyCalledOnClone: true as const,
      overwrittenCells,
      context: ctx
    });
  }
}

export function patch04Stones(
  calculationDay: bigint, targetDay: bigint, index: bigint, inputStone: readonly bigint[]
): Patch04StoneObservation {
  return new Patch04StoneHandler().run(bootstrapMonster(calculationDay, targetDay), index, inputStone);
}
