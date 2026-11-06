import { MonsterValidationError } from "../src/monsterBase.ts";
import { createProductionSignedGatePrefix } from "../src/postStage55SignedGatePrefix.ts";
import { Patch11OrderLatchHandler } from "../src/patch11OrderLatch.ts";
import { FOUNDATION_DAY } from "./normativeOracle.ts";

/**
 * Test-only fault in the NEGATIVE physical gate, after a successful
 * positive gate. Both mid-stream write 46 and final write 58 are checked. No synthetic Native replacement or production changes.
 */
function requireTrue(value: unknown, message: string): asserts value {
  if (!value) throw new Error("POST_STAGE55_NEGATIVE_THROW: " + message);
}
const originalRun = Patch11OrderLatchHandler.prototype.run;
function runNegativeFaultCase(injectedWrite: 46 | 58): void {
  const fault = new Error("QA_ONLY_NEGATIVE_WRITE_" + injectedWrite);
  let entries = 0;
  let completions = 0;
  let completedWrites = 0n;
  let faultWrites = 0;
  
  function counts(): Readonly<{
    entries: number; completions: number; completedWrites: bigint; faultWrites: number
  }> {
    return { entries, completions, completedWrites, faultWrites };
  }
  Patch11OrderLatchHandler.prototype.run = function (...args: Parameters<typeof originalRun>) {
    entries++;
    if (entries === 2) {
      const handler = new Patch11OrderLatchHandler(writeIndex => {
        faultWrites++;
        if (writeIndex === injectedWrite) throw fault;
      });
      return originalRun.apply(handler, args);
    }
    const result = originalRun.apply(this, args);
    requireTrue(result.sharedMemoryWrites === 58 &&
      result.historical.memoryWrites === 58,
      "each completed physical Patch11 call must write 58 times");
    completions++;
    completedWrites += 58n;
    return result;
  };
  
  const day = FOUNDATION_DAY - 100000n;
  let propagated = false;
  let recovered = false;
  try {
    let thrown: unknown = null;
    try { createProductionSignedGatePrefix(day, day, 1); }
    catch (error) { thrown = error; }
    const first = counts();
    propagated = thrown === fault;
    requireTrue(propagated && first.entries === 2 &&
      first.completions === 1 && first.completedWrites === 58n &&
      first.faultWrites === injectedWrite,
      "positive 58-write completion followed by fault at requested negative write");
  
    let retryFailure: unknown = null;
    try { createProductionSignedGatePrefix(day, day, 1); }
    catch (error) { retryFailure = error; }
    const after = counts();
    // One negative step advances at most 963 days, but day is 100000
    // below FOUNDATION and the request adds a 5782-day neighbourhood.
    // The one-step budget must reject before a second negative entry.
    recovered = retryFailure instanceof MonsterValidationError &&
      after.entries - first.entries === 2 &&
      after.completions - first.completions === 2 &&
      after.completedWrites - first.completedWrites === 116n &&
      after.faultWrites === injectedWrite;
    requireTrue(recovered, "fresh retry must perform two complete gates and reject budget");
  } finally {
    Patch11OrderLatchHandler.prototype.run = originalRun;
  }
  const finalCounts = counts();
  requireTrue(finalCounts.entries === 4 && finalCounts.completions === 3 &&
    finalCounts.completedWrites === 174n && finalCounts.faultWrites === injectedWrite &&
    Patch11OrderLatchHandler.prototype.run === originalRun,
    "exact cumulative Native accounting and prototype restoration required");
  if (injectedWrite === 46) {
    console.log("POST_STAGE55_NEGATIVE_NATIVE_THROW_RECOVERY_PASS injectedWrite=46 firstPositive=1 faultNegative=1 faultWrites=46 retryPositive=1 retryNegative=1 totalEntries=4 totalCompletions=3 completedWrites=174 propagated=1 recovered=1 restored=1");
  } else {
    console.log("POST_STAGE55_NEGATIVE_FINAL_WRITE_THROW_RECOVERY_PASS injectedWrite=58 firstPositive=1 faultNegative=1 faultWrites=58 retryPositive=1 retryNegative=1 totalEntries=4 totalCompletions=3 completedWrites=174 propagated=1 recovered=1 restored=1");
  }
}

runNegativeFaultCase(46);
runNegativeFaultCase(58);
