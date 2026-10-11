import { discoverLegacyPermutation } from "../src/index.ts";
import { FOUNDATION_DAY as F, M, bowlOrderFromDrop } from "./normativeOracle.ts";

const witnesses=[-1n,0n,1n,2n,6n,719n,720n,721n,1440n,M] as const;
let mismatches=0,matches=0,rejected=0;
for(const drop of witnesses){
  const historical=discoverLegacyPermutation(F,F,drop);
  const expected=bowlOrderFromDrop(drop);
  const actual=historical.legacyOrder?.join(",")??"OUT_OF_RANGE";
  console.log(`DISCOVERY_08_WITNESS drop=${drop} rank0=${historical.legacyRank0} actual=${actual} expected=${expected.join(",")}`);
  if(!historical.legacyAccepted)rejected++;
  if(actual===expected.join(","))matches++;else mismatches++;
}
if(mismatches===10&&matches===0&&rejected===5)
  throw new Error("DISCOVERY_08_EXPECTED_RED mismatches=10 matches=0 rejected=5");
throw new Error(`DISCOVERY_08_INVALID_RED mismatches=${mismatches} matches=${matches} rejected=${rejected}`);
