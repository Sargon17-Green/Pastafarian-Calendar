import { BaseMetricsManager, bootstrapMonster, MonsterStageError, MonsterValidationError } from "./monsterBase.ts";
import type { MonsterContext } from "./monsterBase.ts";
import { patch01Save } from "./patch01Save.ts";

export type MutableLegacyStone = [bigint, bigint, bigint, bigint, bigint];
export type LegacyStoneObservation = Readonly<{
  stoneIndex: bigint;
  inputStone: readonly bigint[];
  legacyStone: readonly bigint[];
  context: MonsterContext;
}>;

// DISCOVERY 04: पाच दगडांची ऐतिहासिक in-place mutation.
// नवीन w लगेच b मध्ये, नवीन b लगेच s मध्ये इत्यादी वापरला जातो.
// Stage 09 च्या snapshot-आधारित दुरुस्तीचा येथे समावेश नाही.
export class LegacySequentialStoneAdapter {
  mutateStonesWrong(
    index: bigint,
    stone: MutableLegacyStone,
    calculationDay: bigint,
    targetDay: bigint
  ): MutableLegacyStone {
    if (typeof index !== "bigint" || index < 2n || index > 46n) {
      throw new MonsterValidationError("दगड क्रमांक 2 ते 46 मधील bigint असला पाहिजे");
    }
    if (!Array.isArray(stone) || stone.length !== 5 || stone.some(v => typeof v !== "bigint")) {
      throw new MonsterValidationError("पाच अचूक bigint दगड मूल्ये आवश्यक आहेत");
    }
    if (typeof calculationDay !== "bigint" || typeof targetDay !== "bigint") {
      throw new MonsterValidationError("दोन्ही काल-दिवस अचूक bigint असले पाहिजेत");
    }

    const save = (value: bigint): bigint => patch01Save(calculationDay, targetDay, value).savedValue;
    stone[0] = save(stone[0] * stone[0] + 3n * stone[1] + index);
    stone[1] = save(stone[1] * stone[1] + 5n * stone[2] + stone[0]);
    stone[2] = save(stone[2] * stone[2] + 7n * stone[3] + stone[1]);
    stone[3] = save(stone[3] * stone[3] + 11n * stone[4] + stone[2]);
    stone[4] = save(stone[4] * stone[4] + 13n * stone[0] + stone[3]);
    return stone;
  }
}

export class Discovery04StoneHandler {
  private readonly legacy = new LegacySequentialStoneAdapter();
  private readonly metrics = new BaseMetricsManager();

  run(ctx: MonsterContext, index: bigint, inputStone: readonly bigint[]): LegacyStoneObservation {
    if (ctx.phase !== "READY" || ctx.status !== "VALIDATED") {
      throw new MonsterStageError("दगड-शोधासाठी पडताळलेला संदर्भ आवश्यक आहे");
    }
    if (typeof index !== "bigint" || index < 2n || index > 46n ||
        !Array.isArray(inputStone) || inputStone.length !== 5 ||
        inputStone.some(v => typeof v !== "bigint")) {
      throw new MonsterValidationError("अवैध दगड क्रमांक किंवा पाच मूल्यांची यादी");
    }
    const old = Object.freeze([...inputStone]);
    const clone = [...inputStone] as MutableLegacyStone;
    const legacyStone = Object.freeze([
      ...this.legacy.mutateStonesWrong(index, clone, ctx.calculationDay, ctx.targetDay)
    ]);
    ctx.branchTrace.push("DISCOVERY_04_SEQUENTIAL_STONE_MUTATION");
    this.metrics.bump(ctx, "discovery04.calls");
    this.metrics.bump(ctx, "discovery04.stones_written");
    this.metrics.bump(ctx, "discovery04.stones_written");
    this.metrics.bump(ctx, "discovery04.stones_written");
    this.metrics.bump(ctx, "discovery04.stones_written");
    this.metrics.bump(ctx, "discovery04.stones_written");
    ctx.status = "DISCOVERY_04_RECORDED";
    return Object.freeze({ stoneIndex: index, inputStone: old, legacyStone, context: ctx });
  }
}

export function discoverLegacyStoneMutation(
  calculationDay: bigint, targetDay: bigint, index: bigint, inputStone: readonly bigint[]
): LegacyStoneObservation {
  return new Discovery04StoneHandler().run(bootstrapMonster(calculationDay, targetDay), index, inputStone);
}
