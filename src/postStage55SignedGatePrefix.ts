import { MonsterStageError, MonsterValidationError } from "./monsterBase.ts";
import { DISCOVERY15_FOUNDATION_DAY as FOUNDATION } from "./discovery15LegacyPositiveGate.ts";
import { REAL_YEAR_MAX_PATCH } from "./patch16YearMax.ts";
import { patch14WideChoice } from "./patch14WideChoice.ts";
import { createProductionPatch18Question } from "./postStage55NativeQuestion.ts";
import type { Patch18Question } from "./patch18YearWalk.ts";

// This is production Native gate materialization, not a test-oracle fixture.
// It does not yet make a full Patch20 request or enable the final date API.
export type ProductionSignedGatePrefix = Readonly<{
  calculationDay: bigint;
  targetDay: bigint;
  positive: readonly Patch18Question[];
  negative: readonly Patch18Question[];
  positiveGateDays: readonly bigint[];
  negativeGateDays: readonly bigint[];
  signedAnchorIndex: bigint | null;
  actualNativeCalls: number;
  actualSharedWrites: bigint;
  fullyCoversRequestedNeighbourhood: true;
  provenance: "PRODUCTION_NATIVE_SIGNED_GATE_PREFIX";
}>;

/** Build physical signed gate questions and independently execute each
 * PATCH14 Native predecessor once. The historical Stage16 path requires
 * calculationDay == gate(anchor)+1; no anchor is fabricated for other c.
 *
 * This bounded internal precursor inherits Stage37's 128/side budget.
 * Arbitrarily distant public inputs require later unbounded-window work.
 */
export function createProductionSignedGatePrefix(
  calculationDay: bigint, targetDay: bigint, maxPerSide = 128
): ProductionSignedGatePrefix {
  if (typeof calculationDay !== "bigint" || typeof targetDay !== "bigint" ||
      !Number.isSafeInteger(maxPerSide) || maxPerSide < 1 || maxPerSide > 128)
    throw new MonsterValidationError("bigint दिवस आणि सुरक्षित gate budget आवश्यक");

  const lower = (calculationDay < targetDay ? calculationDay : targetDay)
    - REAL_YEAR_MAX_PATCH - 1n;
  const upper = (calculationDay > targetDay ? calculationDay : targetDay)
    + REAL_YEAR_MAX_PATCH + 1n;
  const positive: Patch18Question[] = [], negative: Patch18Question[] = [];
  const positiveDays: bigint[] = [], negativeDays: bigint[] = [];
  let day = FOUNDATION;
  let anchor: bigint | null = null;
  for (let i = 1; i <= maxPerSide; i++) {
    const q = createProductionPatch18Question(FOUNDATION, FOUNDATION + BigInt(i));
    const choice = patch14WideChoice(FOUNDATION, q.targetDay,
      q.visible, q.stones, q.startBowls, 1, 1n, 922n);
    if (choice.predecessorSharedWrites !== 58 || choice.realLegacyCalls !== 1 ||
        choice.correctedRank < 1n || choice.correctedRank > 922n)
      throw new MonsterStageError("positive signed gate Native predecessor अपूर्ण");
    day += 41n + choice.correctedRank;
    positive.push(q); positiveDays.push(day);
    if (day === calculationDay - 1n) anchor = BigInt(i);
    if (day > upper) break;
  }
  if (day <= upper)
    throw new MonsterValidationError("positive signed gate budget संपला");

  day = FOUNDATION;
  for (let i = 1; i <= maxPerSide; i++) {
    const q = createProductionPatch18Question(FOUNDATION, FOUNDATION - BigInt(i));
    const choice = patch14WideChoice(FOUNDATION, q.targetDay,
      q.visible, q.stones, q.startBowls, 1, 1n, 922n);
    if (choice.predecessorSharedWrites !== 58 || choice.realLegacyCalls !== 1 ||
        choice.correctedRank < 1n || choice.correctedRank > 922n)
      throw new MonsterStageError("negative signed gate Native predecessor अपूर्ण");
    day -= 41n + choice.correctedRank;
    negative.push(q); negativeDays.push(day);
    if (day === calculationDay - 1n) anchor = -BigInt(i);
    if (day < lower) break;
  }
  if (day >= lower)
    throw new MonsterValidationError("negative signed gate budget संपला");

  const calls = positive.length + negative.length;
  return Object.freeze({
    calculationDay, targetDay,
    positive: Object.freeze(positive), negative: Object.freeze(negative),
    positiveGateDays: Object.freeze(positiveDays),
    negativeGateDays: Object.freeze(negativeDays),
    signedAnchorIndex: anchor,
    actualNativeCalls: calls, actualSharedWrites: BigInt(calls) * 58n,
    fullyCoversRequestedNeighbourhood: true as const,
    provenance: "PRODUCTION_NATIVE_SIGNED_GATE_PREFIX" as const
  });
}
