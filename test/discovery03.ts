import {discoverLegacyDistance} from "../src/index.ts";
import {FOUNDATION_DAY as F,workCounts} from "./normativeOracle.ts";

const examples = [
  [0n,0n,0n,1n],[-1n,0n,1n,2n],[-2n,2n,1n,5n],
  [1n,1n,0n,1n],[1n,2n,2n,2n]
] as const;
let mismatches=0, matches=0;
for(const [a,b,wrong,correct] of examples){
  const r=discoverLegacyDistance(F+a,F+b);
  if(r.legacyDistance!==wrong || workCounts(F+a,F+b).distance!==correct) throw Error("खोटी ऐतिहासिक साक्ष");
  if(wrong===correct) matches++; else mismatches++;
}
if(mismatches!==4 || matches!==1) throw Error("साक्षी संख्या चुकली");
console.log("STAGE_06_DISCOVERY_03_GUARDS_PASS mismatches=4 matches=1");
