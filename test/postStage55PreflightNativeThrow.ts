import { MonsterValidationError } from "../src/monsterBase.ts";
import { createProductionSignedGatePrefix } from "../src/postStage55SignedGatePrefix.ts";
import { Patch11OrderLatchHandler } from "../src/patch11OrderLatch.ts";
import { FOUNDATION_DAY } from "./normativeOracle.ts";

/**
 * Test-only failure at the 46th AND final (58th) real Patch11
 * positive-gate after-write callbacks; no production or synthetic handler changes.
 */
function requireTrue(value: unknown, message: string): asserts value {
  if (!value) throw new Error("POST_STAGE55_NATIVE_THROW: " + message);
}

const originalRun = Patch11OrderLatchHandler.prototype.run;

function checkPositiveWriteFailure(injectedWrite: 46 | 58): void {
  const fault = new Error("QA_ONLY_POSITIVE_WRITE_" + injectedWrite);
  let nativeEntries = 0;
  let nativeCompletions = 0;
  let observedFaultWrites = 0;
  let completedWrites = 0;

  // A callback mutates the counters. Snapshot prevents stale TypeScript
  // control-flow narrowing and distinguishes an attempted from a completed call.
  function counts(): Readonly<{
    entries: number; completions: number; faultWrites: number; completedWrites: number
  }> {
    return {
      entries: nativeEntries, completions: nativeCompletions,
      faultWrites: observedFaultWrites, completedWrites
    };
  }

  Patch11OrderLatchHandler.prototype.run = function (...args: Parameters<typeof originalRun>) {
    nativeEntries++;
    if (nativeEntries === 1) {
      const handler = new Patch11OrderLatchHandler(writeIndex => {
        observedFaultWrites++;
        if (writeIndex === injectedWrite) throw fault;
      });
      return originalRun.apply(handler, args);
    }
    const result = originalRun.apply(this, args);
    requireTrue(result.sharedMemoryWrites === 58 && result.historical.memoryWrites === 58,
      "clean physical retry must report exactly 58 actual writes");
    nativeCompletions++;
    completedWrites += 58;
    return result;
  };

  let propagated = false;
  let recovered = false;
  try {
    let thrown: unknown = null;
    try {
      createProductionSignedGatePrefix(FOUNDATION_DAY + 1n, FOUNDATION_DAY + 1n, 1);
    } catch (error) {
      thrown = error;
    }
    const first = counts();
    propagated = thrown === fault;
    requireTrue(propagated &&
      first.entries === 1 && first.completions === 0 &&
      first.completedWrites === 0 && first.faultWrites === injectedWrite,
      "original sentinel must propagate after exact physical write without completed Native return");

    let retryError: unknown = null;
    try {
      createProductionSignedGatePrefix(FOUNDATION_DAY + 1n, FOUNDATION_DAY + 1n, 1);
    } catch (error) {
      retryError = error;
    }
    const after = counts();
    // A Patch11 gate advances at most 41+922=963 days. The requested
    // upper neighbourhood radius is 5782, so budget=1 rejects before
    // a second physical Native entry.
    recovered = retryError instanceof MonsterValidationError &&
      after.entries - first.entries === 1 &&
      after.completions - first.completions === 1 &&
      after.completedWrites - first.completedWrites === 58 &&
      after.faultWrites === injectedWrite;
    requireTrue(recovered, "clean retry must finish one gate and reject budget before next entry");
  } finally {
    Patch11OrderLatchHandler.prototype.run = originalRun;
  }

  const last = counts();
  requireTrue(last.entries === 2 && last.completions === 1 &&
    last.faultWrites === injectedWrite && last.completedWrites === 58 &&
    Patch11OrderLatchHandler.prototype.run === originalRun,
    "exact cumulative Native counts and prototype restoration");

  const marker = injectedWrite === 46
    ? "POST_STAGE55_PREFLIGHT_NATIVE_THROW_RECOVERY_PASS"
    : "POST_STAGE55_PREFLIGHT_FINAL_WRITE_THROW_RECOVERY_PASS";
  console.log(marker +
    " injectedWrite=" + injectedWrite +
    " faultEntries=1 faultCompletions=0 faultWrites=" + injectedWrite +
    " retryEntries=1 retryCompletions=1 retryWrites=58 propagated=" + Number(propagated) +
    " recovered=" + Number(recovered) + " restored=1");
}

checkPositiveWriteFailure(46);
checkPositiveWriteFailure(58);
