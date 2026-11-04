import { MonsterValidationError } from "../src/monsterBase.ts";
import { calendarDateSpaghetti, observeProductionCalendarDate } from "../src/postStage55FinalDate.ts";
import { createProductionPatch20Request } from "../src/postStage55ProductionRequest.ts";
import { createProductionSignedGatePrefix } from "../src/postStage55SignedGatePrefix.ts";
import { Patch11OrderLatchHandler } from "../src/patch11OrderLatch.ts";
import { FOUNDATION_DAY } from "./normativeOracle.ts";

/** Post-Stage55 preflight QA only: no change to production or calendar rules. */
function ok(value: unknown, description: string): asserts value {
  if (!value) throw new Error("POST_STAGE55_PREFLIGHT: " + description);
}

type Rejection = Readonly<{ label: string; run: () => unknown }>;
const rejections: Rejection[] = [];
const badDays: readonly unknown[] = [
  0, NaN, Infinity, "0", null, undefined, {}, [], true
];
for (let i = 0; i < badDays.length; i++) {
  const day = badDays[i] as bigint;
  for (const [label, run] of [
    ["public-c", () => calendarDateSpaghetti(day, 0n)],
    ["public-t", () => calendarDateSpaghetti(0n, day)],
    ["observed-c", () => observeProductionCalendarDate(day, 0n)],
    ["observed-t", () => observeProductionCalendarDate(0n, day)],
    ["request-c", () => createProductionPatch20Request(day, 0n)],
    ["request-t", () => createProductionPatch20Request(0n, day)],
    ["prefix-c", () => createProductionSignedGatePrefix(day, 0n)],
    ["prefix-t", () => createProductionSignedGatePrefix(0n, day)]
  ] as const) rejections.push({ label: label + ":" + i, run });
}

const badBudgets: readonly unknown[] = [
  0, -1, 1.5, Number.MAX_SAFE_INTEGER + 1, NaN, Infinity, "1", null
];
for (let i = 0; i < badBudgets.length; i++) {
  const budget = badBudgets[i] as number;
  rejections.push({
    label: "prefix-budget:" + i,
    run: () => createProductionSignedGatePrefix(FOUNDATION_DAY + 1n, FOUNDATION_DAY + 1n, budget)
  });
  rejections.push({
    label: "request-gate-budget:" + i,
    run: () => createProductionPatch20Request(FOUNDATION_DAY + 1n, FOUNDATION_DAY + 1n, { maxGateSteps: budget })
  });
}
const badYearBudgets: readonly unknown[] = [
  // The year factory treats null as its documented nullish default.
  -1, 1.5, Number.MAX_SAFE_INTEGER + 1, NaN, Infinity, "1", true
];
for (let i = 0; i < badYearBudgets.length; i++) {
  const budget = badYearBudgets[i] as number;
  rejections.push({
    label: "request-year-budget:" + i,
    run: () => createProductionPatch20Request(FOUNDATION_DAY + 1n, FOUNDATION_DAY + 1n, { maximumYearSteps: budget })
  });
}
const hugeDay = 10n ** 500n;
rejections.push({
  label: "giant-positive-invalid-budget",
  run: () => createProductionPatch20Request(hugeDay, -hugeDay, { maxGateSteps: 0 })
});
rejections.push({
  label: "giant-negative-invalid-budget",
  run: () => createProductionSignedGatePrefix(-hugeDay, hugeDay, 0)
});
ok(rejections.length === 97, "explicit invalid-input matrix must contain 97 probes");

const originalRun = Patch11OrderLatchHandler.prototype.run;
let nativeCalls = 0;
let nativeWrites = 0n;
Patch11OrderLatchHandler.prototype.run = function (...args: Parameters<typeof originalRun>) {
  const result = originalRun.apply(this, args);
  ok(result.sharedMemoryWrites === 58 && result.historical.memoryWrites === 58 &&
     result.drops === 46 && result.postStirs === 12,
     "completed physical Native latch must execute 46+12 writes");
  nativeCalls++;
  nativeWrites += 58n;
  return result;
};

let rejected = 0;
let exhausted = false;
let positiveBudgetCalls = 0;
let negativeBudgetCalls = 0;
let budgetExhaustions = 0;
let oneStepCalls = 0;
let oneStepWrites = 0n;
try {
  for (const item of rejections) {
    let exception: unknown = null;
    try { item.run(); } catch (error) { exception = error; }
    ok(exception instanceof MonsterValidationError,
       item.label + ": expected MonsterValidationError before Native");
    ok(nativeCalls === 0 && nativeWrites === 0n,
       item.label + ": malformed input must not issue Native calls");
    rejected++;
  }

  // At most one physical gate gap (41 + rank, rank in [1,922]) is < 963.
  // The required radius is 5782 days: no one-step prefix can cover it.
  try {
    createProductionSignedGatePrefix(FOUNDATION_DAY + 1n, FOUNDATION_DAY + 1n, 1);
  } catch (error) {
    exhausted = error instanceof MonsterValidationError;
  }
  ok(exhausted && nativeCalls === 1 && nativeWrites === 58n,
     "one-step valid budget must stop before the second Native invocation");
  oneStepCalls = nativeCalls;
  oneStepWrites = nativeWrites;

  // Mathematical oracle: every signed gate gap is 41+rank <= 963 days,
  // while the required neighbourhood radius is 5782 days. Three gates
  // cannot cover it. A far-negative day makes the positive loop stop after
  // one real call, then exercises the *negative* per-side budget.
  for (const maxPerSide of [1, 2, 3] as const) {
    for (const side of ["positive", "negative"] as const) {
      const day = side === "positive" ? FOUNDATION_DAY + 1n
                                      : FOUNDATION_DAY - 100000n;
      const callsBefore = nativeCalls;
      const writesBefore = nativeWrites;
      let failure: unknown = null;
      try {
        createProductionSignedGatePrefix(day, day, maxPerSide);
      } catch (error) {
        failure = error;
      }
      const expectedCalls = maxPerSide + (side === "negative" ? 1 : 0);
      ok(failure instanceof MonsterValidationError,
         side + ":" + maxPerSide + ": must exhaust the per-side budget");
      ok(nativeCalls - callsBefore === expectedCalls &&
         nativeWrites - writesBefore === BigInt(expectedCalls) * 58n,
         side + ":" + maxPerSide + ": physical Patch11 budget exceeded/undercounted");
      if (side === "positive") positiveBudgetCalls += expectedCalls;
      else negativeBudgetCalls += expectedCalls;
      budgetExhaustions++;
    }
  }
  ok(budgetExhaustions === 6 && positiveBudgetCalls === 6 &&
     negativeBudgetCalls === 9,
     "six budget probes must account for exactly fifteen physical Native calls");
} finally {
  Patch11OrderLatchHandler.prototype.run = originalRun;
}
console.log("POST_STAGE55_PREFLIGHT_ATOMICITY_PASS malformedRejected=" + rejected +
  " preflightNativeCalls=0 boundedNativeCalls=" + oneStepCalls +
  " boundedSharedWrites=" + oneStepWrites + " budgetExhausted=1");

console.log("POST_STAGE55_SIGNED_BUDGET_SIDES_PASS probes=" + budgetExhaustions +
  " positiveCalls=" + positiveBudgetCalls + " negativeCalls=" + negativeBudgetCalls +
  " totalCalls=" + (positiveBudgetCalls + negativeBudgetCalls) +
  " totalSharedWrites=" + BigInt(positiveBudgetCalls + negativeBudgetCalls) * 58n +
  " budgetExhaustions=" + budgetExhaustions);
