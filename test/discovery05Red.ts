import { discoverLegacyHiddenStorage } from "../src/index.ts";
import { FOUNDATION_DAY as F, buildHiddenDrops, workCounts, STONES } from "./normativeOracle.ts";

const canonical = buildHiddenDrops(workCounts(F,F), STONES);
const source = Array.from({length:7},(_,k)=>canonical[k+1]!);
const observation = discoverLegacyHiddenStorage(F,F,source);
let mismatches=0, matches=0;
for(let k=1;k<=7;k++){
  const actual=observation.legacyReads[k-1]!;
  const expected=source[k-1]!;
  console.log(`DISCOVERY_05_WITNESS hidden=${k} actual=${actual} expected=${expected}`);
  if(actual===expected)matches++;else mismatches++;
}
if(mismatches===6 && matches===1){
  throw new Error("DISCOVERY_05_EXPECTED_RED mismatches=6 matches=1");
}
throw new Error(`DISCOVERY_05_INVALID_RED mismatches=${mismatches} matches=${matches}`);
