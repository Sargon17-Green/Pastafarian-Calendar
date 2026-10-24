import {LegacyAllMonthLengthWays,LegacyMonthListLimit}
 from "../src/index.ts";
import {boundedCompositionFamily} from "./normativeOracle.ts";
const old=new LegacyAllMonthLengthWays();
const L=211n,m=47,lower=old.demonstrableLowerBound(L,m);
const trueN=boundedCompositionFamily(L,m,4n,123n).count();
let blocked=false;
try{old.oldAllWays(L,m);}
catch(e){blocked=e instanceof LegacyMonthListLimit&&
 e.observedRows===0&&e.lowerBound===lower;}
if(blocked&&lower>100000n&&trueN>=lower)
 throw Error("DISCOVERY_23_EXPECTED_RED oldExplicitAllMonthWays=blocked hugeFamily=1 virtualPatch=not_applied");
throw Error("DISCOVERY_23_WITNESS_DRIFT");
