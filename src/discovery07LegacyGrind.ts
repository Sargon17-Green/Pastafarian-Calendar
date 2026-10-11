import { BaseMetricsManager, bootstrapMonster, MonsterStageError, MonsterValidationError } from "./monsterBase.ts";
import type { MonsterContext } from "./monsterBase.ts";
import { patch01Save } from "./patch01Save.ts";

// DISCOVERY 07: नियमाधारित 11 टेबल-ओळी इथे 0..10 स्थानांवर आहेत.
// जुन्या ग्राइंड-अनुक्रमात g = 1..11 असतानाही legacyTable[g] घेतले जाते.
// पहिली ओळ वगळली जाते; शेवटची grind 11 मध्ये row मिळत नाही.
// Stage 15 मध्येच sentinel row (index 0) जोडायची; आत्ता नाही.
export type LegacyGrindRow = readonly [bigint, bigint, bigint, bigint, number];

export const LEGACY_GRIND_TABLE: readonly LegacyGrindRow[] = Object.freeze([
  Object.freeze([3n, 5n, 7n, 11n, 0] as const),
  Object.freeze([5n, 7n, 11n, 13n, 1] as const),
  Object.freeze([7n, 11n, 13n, 17n, 2] as const),
  Object.freeze([11n, 13n, 17n, 19n, 3] as const),
  Object.freeze([13n, 17n, 19n, 23n, 4] as const),
  Object.freeze([17n, 19n, 23n, 29n, 0] as const),
  Object.freeze([19n, 23n, 29n, 31n, 1] as const),
  Object.freeze([23n, 29n, 31n, 37n, 2] as const),
  Object.freeze([29n, 31n, 37n, 41n, 3] as const),
  Object.freeze([31n, 37n, 41n, 43n, 4] as const),
  Object.freeze([37n, 41n, 43n, 47n, 0] as const)
]);

export type Discovery07GrindObservation = Readonly<{
  grind: number;
  legacyTableIndex: number;
  rowPresent: boolean;
  legacyRow: LegacyGrindRow | undefined;
  legacyValue: bigint | undefined;
  inputX: bigint;
  prior1: bigint;
  prior3: bigint;
  prior7: bigint;
  inputStone: readonly bigint[];
  context: MonsterContext;
}>;

export class LegacyGrindTableAdapter {
  legacyRow(grind: number): LegacyGrindRow | undefined {
    if (!Number.isInteger(grind) || grind < 1 || grind > 11) {
      throw new MonsterValidationError("ग्राइंड क्रम 1..11 मधील पूर्णांक आवश्यक");
    }
    // हा नेमका ऐतिहासिक 1-based/0-based गोंधळ; तो दुरुस्त करू नका.
    return LEGACY_GRIND_TABLE[grind];
  }
}

export class Discovery07GrindHandler {
  private readonly historical = new LegacyGrindTableAdapter();
  private readonly metrics = new BaseMetricsManager();

  run(
    ctx: MonsterContext, grind: number,
    x: bigint, p1: bigint, p3: bigint, p7: bigint,
    stone: readonly bigint[]
  ): Discovery07GrindObservation {
    if (ctx.phase !== "READY" || ctx.status !== "VALIDATED") {
      throw new MonsterStageError("ग्राइंड शोधासाठी तयार संदर्भ आवश्यक आहे");
    }
    if (typeof ctx.calculationDay !== "bigint" || typeof ctx.targetDay !== "bigint") {
      throw new MonsterValidationError("दिवस अचूक bigint असले पाहिजेत");
    }
    if (!Number.isInteger(grind) || grind < 1 || grind > 11 ||
        [x,p1,p3,p7].some(v=>typeof v!=="bigint") ||
        !Array.isArray(stone) || stone.length!==5 ||
        Array.from({length:5},(_,j)=>typeof stone[j]!=="bigint").some(Boolean)) {
      throw new MonsterValidationError("ग्राइंड क्रम, bigint इतिहास व पाच मूल्ये अचूक हवीत");
    }

    const legacyRow=this.historical.legacyRow(grind);
    // missing last row ला कल्पित zero/इतर मूल्य देत नाही; ऐतिहासिक दोष नोंदतो.
    const legacyValue=legacyRow===undefined ? undefined : patch01Save(
      ctx.calculationDay,ctx.targetDay,
      x*x + legacyRow[0]*x + legacyRow[1]*p1 + legacyRow[2]*p3 +
      legacyRow[3]*p7 + stone[legacyRow[4]]!
    ).savedValue;
    const inputStone=Object.freeze(Array.from({length:5},(_,j)=>stone[j]!));

    ctx.branchTrace.push("DISCOVERY_07_LEGACY_GRIND_INDEX_G");
    ctx.branchTrace.push(legacyRow===undefined ?
      "DISCOVERY_07_MISSING_GRIND_11" : "DISCOVERY_07_SHIFTED_GRIND_ROW");
    this.metrics.bump(ctx,"discovery07.calls");
    this.metrics.bump(ctx,legacyRow===undefined?"discovery07.missing_rows":"discovery07.shifted_rows");
    ctx.status="DISCOVERY_07_RECORDED";
    return Object.freeze({
      grind,legacyTableIndex:grind,rowPresent:legacyRow!==undefined,
      legacyRow,legacyValue,inputX:x,prior1:p1,prior3:p3,prior7:p7,
      inputStone,context:ctx
    });
  }
}

export function discoverLegacyGrind(
  calculationDay: bigint,targetDay: bigint,grind: number,
  x: bigint,p1: bigint,p3: bigint,p7: bigint,stone: readonly bigint[]
): Discovery07GrindObservation {
  return new Discovery07GrindHandler().run(
    bootstrapMonster(calculationDay,targetDay),grind,x,p1,p3,p7,stone
  );
}
