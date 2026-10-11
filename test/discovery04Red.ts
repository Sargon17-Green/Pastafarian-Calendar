import { discoverLegacyStoneMutation } from "../src/index.ts";
import { FOUNDATION_DAY as F, STONES } from "./normativeOracle.ts";

const previous = STONES[1]!;
const next = STONES[2]!;
const legacy = discoverLegacyStoneMutation(F,F,2n,previous);
let mismatches=0, matches=0;
for(let k=0;k<5;k++){
  const actual=legacy.legacyStone[k];
  const expected=next[k];
  console.log(`DISCOVERY_04_WITNESS stone=${k+1} actual=${actual} expected=${expected}`);
  if(actual===expected)matches++;else mismatches++;
}
if(mismatches===4 && matches===1){
  throw new Error("DISCOVERY_04_EXPECTED_RED mismatches=4 matches=1");
}
throw new Error(`DISCOVERY_04_INVALID_RED mismatches=${mismatches} matches=${matches}`);
