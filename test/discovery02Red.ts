import { discoverLegacyDayTags, LEGACY_FOUNDATION_DAY } from "../src/index.ts";
import { dayCount } from "./normativeOracle.ts";

const F = LEGACY_FOUNDATION_DAY;
let mismatches = 0;
let matches = 0;
for (const d of [F - 2n, F - 1n, F, F + 1n, F + 2n]) {
  const actual = discoverLegacyDayTags(d, d).legacyActionTag;
  const expected = dayCount(d);
  console.log(`DISCOVERY_02_WITNESS day=${d} actual=${actual} expected=${expected}`);
  if (actual === expected) matches++; else mismatches++;
}
if (mismatches === 3 && matches === 2) {
  throw new Error("DISCOVERY_02_EXPECTED_RED mismatches=3 matches=2");
}
throw new Error(`DISCOVERY_02_INVALID_RED mismatches=${mismatches} matches=${matches}`);
