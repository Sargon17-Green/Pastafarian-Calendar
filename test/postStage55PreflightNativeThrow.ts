import { MonsterValidationError } from "../src/monsterBase.ts";
import { createProductionSignedGatePrefix } from "../src/postStage55SignedGatePrefix.ts";
import { Patch11OrderLatchHandler } from "../src/patch11OrderLatch.ts";
import { FOUNDATION_DAY } from "./normativeOracle.ts";

/** Test-only fault at the forty-sixth REAL Patch11 shared-memory write. */
function requireTrue(value: unknown, message: string): asserts value {
  if (!value) throw new Error("POST_STAGE55_NATIVE_THROW: " + message);
}

const originalRun = Patch11OrderLatchHandler.prototype.run;
const injectedFault = new Error("QA_ONLY_WRITE_46_FAULT");
let armed = true;
let nativeEntries = 0;
let nativeCompletions = 0;
let observedFaultWrites = 0;
let propagated = false;
let recovered = false;

Patch11OrderLatchHandler.prototype.run = function (...args: Parameters<typeof originalRun>) {
  nativeEntries++;
  if (armed) {
    armed = false;
    // Use the production handler, not a synthetic stand-in. Its after-write
    // callback fires only after the actual physical legacy shared write.
    const faultedHandler = new Patch11OrderLatchHandler(writeIndex => {
      observedFaultWrites++;
      if (writeIndex === 46) throw injectedFault;
    });
    return originalRun.apply(faultedHandler, args);
  }
  const result = originalRun.apply(this, args);
  requireTrue(result.sharedMemoryWrites === 58 && result.historical.memoryWrites === 58,
    "successful clean Native retry must perform all 58 real writes");
  nativeCompletions++;
  return result;
};

try {
  let failure: unknown;
  try {
    createProductionSignedGatePrefix(FOUNDATION_DAY + 1n, FOUNDATION_DAY + 1n, 1);
  } catch (error) { failure = error; }
  propagated = failure === injectedFault;
  requireTrue(propagated && nativeEntries === 1 && nativeCompletions === 0 &&
    observedFaultWrites === 46, "fault must propagate after exactly 46 physical writes and no completion");

  let retryError: unknown;
  try {
    createProductionSignedGatePrefix(FOUNDATION_DAY + 1n, FOUNDATION_DAY + 1n, 1);
  } catch (error) { retryError = error; }
  // One real gap is at most 963 days, less than the required 5782-day
  // radius; retry therefore runs once and exhausts its one-step budget.
  recovered = retryError instanceof MonsterValidationError && nativeEntries === 2 &&
    nativeCompletions === 1 && observedFaultWrites === 46;
  requireTrue(recovered, "clean retry must complete one fresh Native call, then reject budget");
} finally {
  Patch11OrderLatchHandler.prototype.run = originalRun;
}
requireTrue(Patch11OrderLatchHandler.prototype.run === originalRun,
  "Patch11 prototype must be restored even after fault");
console.log("POST_STAGE55_PREFLIGHT_NATIVE_THROW_RECOVERY_PASS injectedWrite=46 faultEntries=1 faultCompletions=0 faultWrites=46 retryEntries=1 retryCompletions=1 retryWrites=58 propagated=1 recovered=1 restored=1");
