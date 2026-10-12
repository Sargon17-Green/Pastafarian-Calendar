// थेट ऐतिहासिक modulo निवडीचे तीन सिद्ध प्रतिवाद: हा test मुद्दाम FAIL होतो.
import { LegacyBiasedModuloRankAdapter } from "../src/index.ts";
import { M,chooseRank } from "./normativeOracle.ts";
const old=new LegacyBiasedModuloRankAdapter();
let mismatches=0,matches=0;
for(const n of [2n,3n,5n]){
 const legacy=old.oldChooseModulo(M,n);
 const canonical=chooseRank({first:M,directionStep:-1n},n);
 if(legacy===canonical)matches++;else mismatches++;
}
if(mismatches===3&&matches===0)
 throw Error("DISCOVERY_13_EXPECTED_RED mismatches=3 matches=0 sizes=2,3,5 first=M");
throw Error("DISCOVERY_13_RED_WITNESS_DRIFT mismatches="+mismatches+" matches="+matches);
