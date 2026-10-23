// Historical RED number 22: actual earlier stages, natural native source,
// and real Bowl5/Seal22 choosing names with a duplicate (no Stage45 repair).
import {
 Discovery22ExactGateHandler,Discovery22FullHandler,
 Patch21CutletHandler,Discovery21LegacyCutletHandler,
 Patch20StructureSauceHandler,Discovery20StructureSauceHandler,
 Patch19YearCacheHandler,discoverLegacyCutletNames
} from "../src/index.ts";
import {
 findTrueHistoricalBoundaryMiss,buildStage41CompatibleLegacyFixture
} from "./discovery21Fixtures.ts";
const f=findTrueHistoricalBoundaryMiss();
const c=f.request.historical.yearQuestion.calculationDay;
const actual=new Discovery22ExactGateHandler().run(c,f.index,
 f.request.historical.yearQuestion.positive,
 f.request.historical.yearQuestion.negative,
 f.request.historical.yearQuestion.trueYearQuestion,
 f.request.firstDaySauceQuestion!);
const compatible=buildStage41CompatibleLegacyFixture();
const second=discoverLegacyCutletNames(new Discovery22FullHandler(
 new Patch21CutletHandler(new Discovery21LegacyCutletHandler(
  new Patch20StructureSauceHandler(new Discovery20StructureSauceHandler(
   new Patch19YearCacheHandler()))))),compatible.request);
const wrong=[actual.names.legacyHasRepeatedNames,second.names.legacyHasRepeatedNames];
if(wrong.some(Boolean)&&
 actual.names.nativeSeal22.seal===22n&&
 second.names.nativeSeal22.seal===22n&&
 actual.names.nativeSeal22.predecessorSharedWrites===58&&
 second.names.nativeSeal22.predecessorSharedWrites===58&&
 actual.historical.source==="TRUE_STAGE37_SIGNED_GATE_AND_NATIVE_FIRST_DAY_SAUCE"&&
 second.historical.context.status==="PATCH_21_APPLIED")
 throw Error("DISCOVERY_22_EXPECTED_RED duplicateNativeNames=1 correctedDistinctness=not_applied bowl=5 seal=22");
throw Error("DISCOVERY_22_WITNESS_DRIFT realExactRepeated="+wrong[0]+" realFullRepeated="+wrong[1]);
