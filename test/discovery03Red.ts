import {discoverLegacyDistance} from "../src/index.ts";
import {FOUNDATION_DAY as F,workCounts} from "./normativeOracle.ts";
const positions=[[0n,0n],[-1n,0n],[-2n,2n],[1n,1n],[1n,2n]] as const;
let mismatches=0,matches=0;
for(const [a,b] of positions){
  const actual=discoverLegacyDistance(F+a,F+b).legacyDistance;
  const expected=workCounts(F+a,F+b).distance;
  console.log(`DISCOVERY_03_WITNESS c=${F+a} t=${F+b} actual=${actual} expected=${expected}`);
  if(actual===expected) matches++; else mismatches++;
}
if(mismatches===4 && matches===1) throw Error("DISCOVERY_03_EXPECTED_RED mismatches=4 matches=1");
throw Error(`DISCOVERY_03_INVALID_RED mismatches=${mismatches} matches=${matches}`);
