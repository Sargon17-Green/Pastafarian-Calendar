import {LegacyIndependentDailyMonthChooser,auditLegacyWeaving} from "../src/index.ts";
import {weavingFamily} from "./normativeOracle.ts";
const lengths=[4n,4n,5n];
const old=new LegacyIndependentDailyMonthChooser();
const ghost=old.legacyChooseEachDaySeparately(lengths,1n);
const audit=auditLegacyWeaving(lengths,ghost);
const correct=weavingFamily(lengths).unrank1(1n);
if(!audit.legal&&ghost.length===correct.length&&
 audit.requiredCounts.join(",")==="4,4,5"&&
 audit.observedCounts.join(",")==="5,4,4")
 throw Error("DISCOVERY_24_EXPECTED_RED independentDailyWrong=1 required=4,4,5 observed=5,4,4 patch24=not_applied");
throw Error("DISCOVERY_24_WITNESS_DRIFT");
