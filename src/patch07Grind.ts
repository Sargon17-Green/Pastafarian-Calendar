import { BaseMetricsManager, bootstrapMonster, MonsterStageError, MonsterValidationError } from "./monsterBase.ts";
import type { MonsterContext } from "./monsterBase.ts";
import { LEGACY_GRIND_TABLE, LegacyGrindTableAdapter } from "./discovery07LegacyGrind.ts";
import type { LegacyGrindRow } from "./discovery07LegacyGrind.ts";
import { patch01Save } from "./patch01Save.ts";

// PATCH 07: मूळ sentinel-विरहित table आणि त्यातील table[g] दोष बदललेला नाही.
// वेगळ्या टेबलमध्ये 0 क्रमांकावर एकच निष्प्रभावी, परंतु कायम राहणारा sentinel.
// यानंतर जुनाच one-based g हा थेट array index म्हणून वापरला जातो.
export type SentinelGrindRow = readonly [0n, 0n, 0n, 0n, "NONE"];
export const GRIND_SENTINEL: SentinelGrindRow = Object.freeze([0n, 0n, 0n, 0n, "NONE"] as const);
export const GRIND_TABLE_WITH_SENTINEL: readonly (LegacyGrindRow | SentinelGrindRow)[] =
  Object.freeze([GRIND_SENTINEL, ...LEGACY_GRIND_TABLE]);

export type Patch07GrindObservation = Readonly<{
  grind: number;
  indexUsed: number;
  actualRow: LegacyGrindRow;
  historicalRow: LegacyGrindRow | undefined;
  historicalRowMissing: boolean;
  legacyReadOccurred: boolean;
  correctedValue: bigint;
  inputX: bigint;
  prior1: bigint;
  prior3: bigint;
  prior7: bigint;
  inputStone: readonly bigint[];
  context: MonsterContext;
}>;

export class Patch07GrindHandler {
  private readonly historical = new LegacyGrindTableAdapter();
  private readonly metrics = new BaseMetricsManager();

  // इंडेक्स-सूत्र न बदलता फक्त sentinel असलेल्या जुन्या-शैलीच्या टेबलचा वापर.
  oneBasedRow(grind: number): LegacyGrindRow {
    if (!Number.isInteger(grind) || grind < 1 || grind > 11) {
      throw new MonsterValidationError("ग्राइंड क्रम 1 ते 11 पूर्णांक असणे आवश्यक");
    }
    const row = GRIND_TABLE_WITH_SENTINEL[grind];
    if (row === undefined || typeof row[4] !== "number") {
      throw new MonsterStageError("प्रत्यक्ष ग्राइंडची sentinel नसलेली ओळ आवश्यक");
    }
    return row as LegacyGrindRow;
  }

  run(
    ctx: MonsterContext, grind: number,
    x: bigint, p1: bigint, p3: bigint, p7: bigint,
    stone: readonly bigint[]
  ): Patch07GrindObservation {
    if (ctx.phase !== "READY" || ctx.status !== "VALIDATED") {
      throw new MonsterStageError("ग्राइंड दुरुस्तीपूर्वी तयार संदर्भ हवा");
    }
    if (typeof ctx.calculationDay !== "bigint" || typeof ctx.targetDay !== "bigint") {
      throw new MonsterValidationError("दोन्ही दिवस अचूक bigint आवश्यक");
    }
    if (!Number.isInteger(grind) || grind < 1 || grind > 11 ||
        [x,p1,p3,p7].some(v => typeof v !== "bigint") ||
        !Array.isArray(stone) || stone.length !== 5 ||
        Array.from({length: 5}, (_,j) => typeof stone[j] !== "bigint").some(Boolean)) {
      throw new MonsterValidationError("ग्राइंड, चार bigint इतिहास-मूल्ये व पाच bigint दगड वैध असावेत");
    }

    // जुने चुकीचे indexing helper खऱ्या आवाहनातून नोंदवले जाते, परंतु
    // उत्तरासाठी त्याच्या shifted किंवा missing row ची निवड केली जात नाही.
    const historicalRow = this.historical.legacyRow(grind);
    const actualRow = this.oneBasedRow(grind);
    const correctedValue = patch01Save(
      ctx.calculationDay,ctx.targetDay,
      x*x + actualRow[0]*x + actualRow[1]*p1 + actualRow[2]*p3 +
      actualRow[3]*p7 + stone[actualRow[4]]!
    ).savedValue;
    const inputStone = Object.freeze(Array.from({length:5},(_,j)=>stone[j]!));

    ctx.branchTrace.push("PATCH_07_REAL_LEGACY_ROW_READ");
    ctx.branchTrace.push("PATCH_07_SENTINEL_INDEX_G");
    ctx.branchTrace.push(historicalRow === undefined ?
      "PATCH_07_REPAIRED_MISSING_11" : "PATCH_07_REPAIRED_SHIFTED_ROW");
    this.metrics.bump(ctx,"patch07.calls");
    this.metrics.bump(ctx,"patch07.historical_reads");
    this.metrics.bump(ctx,historicalRow === undefined ?
      "patch07.missing_row_repairs" : "patch07.shifted_row_repairs");
    ctx.status = "PATCH_07_APPLIED";

    return Object.freeze({
      grind,indexUsed:grind,actualRow,historicalRow,
      historicalRowMissing:historicalRow === undefined,
      legacyReadOccurred:true,correctedValue,
      inputX:x,prior1:p1,prior3:p3,prior7:p7,
      inputStone,context:ctx
    });
  }
}

export function patch07Grind(
  calculationDay: bigint,targetDay: bigint,grind: number,
  x: bigint,p1: bigint,p3: bigint,p7: bigint,stone: readonly bigint[]
): Patch07GrindObservation {
  return new Patch07GrindHandler().run(
    bootstrapMonster(calculationDay,targetDay),grind,x,p1,p3,p7,stone
  );
}
