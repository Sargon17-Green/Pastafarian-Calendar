// Twentieth intentionally failing full Stage39 predecessor + oldStructureSauce.
// Do NOT make this test GREEN by invoking Stage41's first-day sauce in production.
import {
  Patch19YearCacheHandler,Discovery20StructureSauceHandler,
  discoverLegacyStructureSauce
} from "../src/index.ts";
import {sauce} from "./normativeOracle.ts";
import {buildDiscovery19Fixture,question} from "./discovery19Fixtures.ts";
const f=buildDiscovery19Fixture();
const q={yearQuestion:f.first,
 originalSauceQuestion:question(f.first.calculationDay,f.first.targetDay)};
const out=discoverLegacyStructureSauce(
 new Discovery20StructureSauceHandler(new Patch19YearCacheHandler()),q);
const correct=sauce(f.first.calculationDay,f.firstSeed.openGateDay+1n);
const oldMatchesCorrect=out.oldSauce.bowls.every((v,i)=>v===correct.bowls[i])&&
 out.oldSauce.orderAtDrop46.join(",")===correct.orderAtDrop46.join(",");
if(!oldMatchesCorrect&&out.historicalWrongTarget&&
 out.oldSauce.originalTargetDay!==out.chosenYearFirstDay&&
 out.oldSauce.oldStructureSauceCalls===1&&
 out.oldSauce.sharedMemoryWrites===58&&
 out.oldSauce.preceding.historical.latestSource==="STIR_12"&&
 out.fullStage39.context.status==="PATCH_19_APPLIED"&&
 out.fullStage39.originalWrongHistory.preceding.authoritative.gateProvenance===
  "PHYSICALLY_RECOMPUTED_SIGNED_GATES"&&
 !out.correctedStructureSauceComputed&&
 !out.authoritativeStructureSauceReady)
 throw Error("DISCOVERY_20_EXPECTED_RED wrongSauce=1 correctSauce=0 oldTarget=original firstDaySubstitution=absent");
throw Error("DISCOVERY_20_WITNESS_DRIFT oldMatchesCorrect="+oldMatchesCorrect+
 " wrongTarget="+out.historicalWrongTarget);
