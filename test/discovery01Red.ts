import { discoverLegacyRemainder, LEGACY_MODULUS } from "../src/index.ts";
import { FOUNDATION_DAY, SAVE } from "./normativeOracle.ts";

const witnesses = [LEGACY_MODULUS, 2n * LEGACY_MODULUS, 3n * LEGACY_MODULUS, LEGACY_MODULUS + 1n];
let mismatches = 0;
for (const value of witnesses) {
  const actual = discoverLegacyRemainder(FOUNDATION_DAY, FOUNDATION_DAY, value).legacyValue;
  const expected = SAVE(value);
  console.log(`DISCOVERY_01_WITNESS input=${value} expected=${expected} actual=${actual}`);
  if (actual !== expected) mismatches += 1;
}
if (mismatches === 3) {
  throw new Error("DISCOVERY_01_EXPECTED_RED mismatches=3 matches=1");
}
console.log(`DISCOVERY_01_UNEXPECTED_RESULT mismatches=${mismatches}`);
