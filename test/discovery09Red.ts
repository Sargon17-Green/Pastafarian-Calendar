import { discoverLegacyFixedPours } from "../src/index.ts";
import { FOUNDATION_DAY as F } from "./normativeOracle.ts";
import { normativeThreePours } from "./discovery09Reference.ts";
const b=[101n,211n,307n,401n,503n,601n],s=[2n,3n,5n,7n,11n];
const drops=[1n,2n,120n,121n,240n,359n,719n,720n] as const;
let mismatches=0,matches=0;
for(const d of drops){
  const old=discoverLegacyFixedPours(F,F,7,d,b,s);
  const ref=normativeThreePours(7,d,b,s);
  for(let p=0;p<3;p++){
    console.log(`DISCOVERY_09_WITNESS drop=${d} position=${p+1} legacyBowl=${p+1} realBowl=${old.order[p]} got=${old.legacyPours[p]} expected=${ref[p]}`);
    if(old.legacyPours[p]===ref[p])matches++;else mismatches++;
  }
}
if(mismatches===16&&matches===8)throw new Error("DISCOVERY_09_EXPECTED_RED mismatches=16 matches=8 witnesses=8 cells=24");
throw new Error(`DISCOVERY_09_INVALID_RED mismatches=${mismatches} matches=${matches}`);
