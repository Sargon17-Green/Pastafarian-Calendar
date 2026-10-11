import { discoverLegacyPrior } from "../src/index.ts";
import { FOUNDATION_DAY as F, STONES, buildHiddenDrops, buildVisibleDrops, workCounts } from "./normativeOracle.ts";

const counts=workCounts(F,F);
const hidden=buildHiddenDrops(counts,STONES);
const visible=buildVisibleDrops(counts,STONES,hidden);
const witnesses:readonly (readonly [number,1|3|7])[]=[
  [1,1],[1,3],[1,7],[2,3],[2,7],[3,3],[3,7],
  [4,7],[5,7],[6,7],[7,7],
  [2,1],[4,3],[8,7],[8,1]
];
let mismatches=0,matches=0;
for(const [i,back] of witnesses) {
  const slot=i-back;
  const actual=discoverLegacyPrior(F,F,visible,i,back).legacyValue;
  const expected=slot>=1?visible[slot]!:hidden[1-slot]!;
  console.log(`DISCOVERY_06_WITNESS i=${i} back=${back} slot=${slot} actual=${String(actual)} expected=${expected}`);
  if(actual===expected)matches++;else mismatches++;
}
if(mismatches===11 && matches===4)
  throw new Error("DISCOVERY_06_EXPECTED_RED mismatches=11 matches=4");
throw new Error(`DISCOVERY_06_INVALID_RED mismatches=${mismatches} matches=${matches}`);
