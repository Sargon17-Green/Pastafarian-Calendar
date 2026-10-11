import {bootstrapMonster,discoverLegacyDistance,MonsterValidationError} from "../src/index.ts";
import {FOUNDATION_DAY as F} from "./normativeOracle.ts";
function invalid(fn:()=>unknown):boolean{
  try{fn()}catch(e){return e instanceof MonsterValidationError}
  return false;
}
if(!invalid(()=>discoverLegacyDistance(2 as unknown as bigint,F)))throw Error("गणना-दिवस पडताळणी");
if(!invalid(()=>discoverLegacyDistance(F,null as unknown as bigint)))throw Error("लक्ष्य-दिवस पडताळणी");
const a=discoverLegacyDistance(F,F+1n);
if(a.context.phase!=="READY"||a.context.branchTrace.join(",")!=="BOOTSTRAP_VALIDATE,DISCOVERY_03_TAG_DISTANCE")throw Error("संदर्भ-मागोवा");
if(a.context.metrics.get("bootstrap.calls")!==1n)throw Error("मूळ मापन");
bootstrapMonster(F,F);
console.log("STAGE_06_DISCOVERY_03_ERRORS_PASS");
