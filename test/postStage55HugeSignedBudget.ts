import { MonsterValidationError } from "../src/monsterBase.ts";
import { DISCOVERY15_FOUNDATION_DAY as FOUNDATION } from "../src/discovery15LegacyPositiveGate.ts";
import { createProductionSignedGatePrefix } from "../src/postStage55SignedGatePrefix.ts";
import { Patch11OrderLatchHandler } from "../src/patch11OrderLatch.ts";

/** Bounded real-Native QA for legitimate, very large signed bigint inputs. */
function requireTrue(value: unknown, message: string): asserts value {
  if (!value) throw new Error("POST_STAGE55_HUGE_SIGNED_BUDGET: " + message);
}
const enormousDay = 10n ** 500n;
// A physical gate advances by 41+rank, 1<=rank<=922. Both days are far
// outside a single physical gap and the 5,782-day requested neighbourhood.
requireTrue(FOUNDATION + 6745n < enormousDay && FOUNDATION - 6745n > -enormousDay,
  "large signed probes must lie beyond one physical gate + radius");
const originalRun = Patch11OrderLatchHandler.prototype.run;
let entries = 0;
let completions = 0;
let sharedWrites = 0n;
function snapshot(): Readonly<{ entries: number; completions: number; writes: bigint }> {
  return { entries, completions, writes: sharedWrites };
}
Patch11OrderLatchHandler.prototype.run = function (...args: Parameters<typeof originalRun>) {
  entries++;
  const observation = originalRun.apply(this, args);
  requireTrue(observation.sharedMemoryWrites === 58 && observation.historical.memoryWrites === 58,
    "physical Patch11 call must complete precisely 58 historical shared writes");
  completions++;
  sharedWrites += 58n;
  return observation;
};

let tested = 0;
let positiveEntries = 0;
let negativeEntries = 0;
function probe(label: string, day: bigint, expectedEntries: number): number {
  const before = snapshot();
  let thrown: unknown = null;
  try { createProductionSignedGatePrefix(day, day, 1); }
  catch (error) { thrown = error; }
  const after = snapshot();
  const actualEntries = after.entries - before.entries;
  requireTrue(thrown instanceof MonsterValidationError,
    label + ": valid budget must exhaust with MonsterValidationError");
  requireTrue(actualEntries === expectedEntries &&
    after.completions - before.completions === expectedEntries &&
    after.writes - before.writes === BigInt(expectedEntries) * 58n,
    label + ": physical entry/completion/write accounting mismatch");
  tested++;
  return actualEntries;
}
try {
  // Positive extreme: the positive walk cannot cover 10^500, so one
  // successful Native step is followed by a strict budget rejection.
  positiveEntries = probe("large-positive", enormousDay, 1);
  // Negative extreme: a single positive gate is already above the upper
  // neighbourhood. One negative step remains far above the lower bound.
  negativeEntries = probe("large-negative", -enormousDay, 2);
} finally {
  Patch11OrderLatchHandler.prototype.run = originalRun;
}
const observed = snapshot();
requireTrue(tested === 2 && positiveEntries === 1 && negativeEntries === 2 &&
  observed.entries === 3 && observed.completions === 3 && observed.writes === 174n &&
  Patch11OrderLatchHandler.prototype.run === originalRun,
  "extreme signed budget aggregate/restoration mismatch");
console.log("POST_STAGE55_HUGE_SIGNED_BUDGET_PASS probes=2 digits=501 positiveEntries=1 negativeEntries=2 completions=3 sharedWrites=174 restored=1");
