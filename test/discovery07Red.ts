import { discoverLegacyGrind } from "../src/index.ts";
import { FOUNDATION_DAY as F } from "./normativeOracle.ts";
import { normativeGrindStep } from "./discovery07Fixtures.ts";

const stone=Object.freeze([101n,103n,107n,109n,113n]);
let mismatches=0,matches=0,missing=0;
for(let g=1;g<=11;g++) {
  const result=discoverLegacyGrind(F,F,g,17n,29n,43n,71n,stone);
  const expected=normativeGrindStep(g,17n,29n,43n,71n,stone);
  console.log(`DISCOVERY_07_WITNESS g=${g} tableIndex=${result.legacyTableIndex} expected=${expected} actual=${String(result.legacyValue)}`);
  if(result.legacyValue===undefined)missing++;
  if(result.legacyValue===expected)matches++;else mismatches++;
}
if(mismatches===11 && matches===0 && missing===1)
  throw new Error("DISCOVERY_07_EXPECTED_RED mismatches=11 matches=0 missing=1");
throw new Error(`DISCOVERY_07_INVALID_RED mismatches=${mismatches} matches=${matches} missing=${missing}`);
