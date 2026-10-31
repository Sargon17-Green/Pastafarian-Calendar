import { MonsterStageError, MonsterValidationError } from "./monsterBase.ts";
import { DISCOVERY15_FOUNDATION_DAY as FOUNDATION } from "./discovery15LegacyPositiveGate.ts";
import { LEGACY_YEAR_MAX } from "./discovery16LegacyYearMax.ts";
import { patch14WideChoice } from "./patch14WideChoice.ts";
import { createProductionPatch18Question } from "./postStage55NativeQuestion.ts";
import type { Patch18Question,Patch18VerifiedGateWindow } from "./patch18YearWalk.ts";

export type ProductionSignedGatePrefix = Readonly<{
  calculationDay: bigint;
  targetDay: bigint;
  positive: readonly Patch18Question[];
  negative: readonly Patch18Question[];
  positiveGateDays: readonly bigint[];
  negativeGateDays: readonly bigint[];
  signedAnchorIndex: bigint | null;
  verifiedWindow:Patch18VerifiedGateWindow;
  actualNativeCalls: number;
  actualSharedWrites: bigint;
  fullyCoversRequestedNeighbourhood: true;
  provenance: "PRODUCTION_NATIVE_SIGNED_GATE_PREFIX";
}>;

/** maxPerSide, when supplied, is an execution budget. With no budget the
 * algorithm advances until the actual Native gate sequence covers c,t.
 * There is no fixed 128-step restriction on the signed bigint domain.
 */
export function createProductionSignedGatePrefix(
  calculationDay: bigint, targetDay: bigint,
  maxPerSide?: number
): ProductionSignedGatePrefix {
  if (typeof calculationDay !== "bigint" || typeof targetDay !== "bigint" ||
      (maxPerSide!==undefined&&(!Number.isSafeInteger(maxPerSide)||maxPerSide<1)))
    throw new MonsterValidationError("bigint दिवस आणि सुरक्षित gate budget आवश्यक");

  const radius=LEGACY_YEAR_MAX+1n;
  const lower = (calculationDay < targetDay ? calculationDay : targetDay)-radius;
  const upper = (calculationDay > targetDay ? calculationDay : targetDay)+radius;
  const positive: Patch18Question[] = [], negative: Patch18Question[] = [];
  const positiveDays: bigint[] = [], negativeDays: bigint[] = [];
  let day = FOUNDATION;
  let anchor: bigint | null = null;
  for (let i = 1; ; i++) {
    if(!Number.isSafeInteger(i)||(maxPerSide!==undefined&&i>maxPerSide))
      throw new MonsterValidationError("positive signed gate execution budget संपला");
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

  day = FOUNDATION;
  for (let i = 1; ; i++) {
    if(!Number.isSafeInteger(i)||(maxPerSide!==undefined&&i>maxPerSide))
      throw new MonsterValidationError("negative signed gate execution budget संपला");
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

  const calls = positive.length + negative.length;
  const map=new Map<bigint,bigint>([[0n,FOUNDATION]]);
  for(let i=0;i<positiveDays.length;i++)map.set(BigInt(i+1),positiveDays[i]!);
  for(let i=0;i<negativeDays.length;i++)map.set(-BigInt(i+1),negativeDays[i]!);
  const min=-BigInt(negative.length),max=BigInt(positive.length);
  const readonlyMap:ReadonlyMap<bigint,bigint>=Object.freeze({
    get:(k:bigint)=>map.get(k),
    has:(k:bigint)=>map.has(k),
    entries:()=>map.entries(),
    keys:()=>map.keys(),
    values:()=>map.values(),
    forEach:(fn:(value:bigint,key:bigint,map:ReadonlyMap<bigint,bigint>)=>void)=>
      map.forEach((v,k)=>fn(v,k,readonlyMap)),
    [Symbol.iterator]:()=>map.entries(),
    get size(){return map.size;}
  });
  const verifiedWindow:Patch18VerifiedGateWindow=Object.freeze({
    byIndex:readonlyMap,minimumIndex:min,maximumIndex:max,
    minimumDay:map.get(min)!,maximumDay:map.get(max)!,
    realGapQuestions:calls,realPredecessorWrites:BigInt(calls)*58n,
    provenance:"PHYSICALLY_RECOMPUTED_SIGNED_GATES" as const
  });
  return Object.freeze({
    calculationDay, targetDay,
    positive: Object.freeze(positive), negative: Object.freeze(negative),
    positiveGateDays: Object.freeze(positiveDays),
    negativeGateDays: Object.freeze(negativeDays),
    signedAnchorIndex: anchor,verifiedWindow,
    actualNativeCalls: calls, actualSharedWrites: BigInt(calls) * 58n,
    fullyCoversRequestedNeighbourhood: true as const,
    provenance: "PRODUCTION_NATIVE_SIGNED_GATE_PREFIX" as const
  });
}
