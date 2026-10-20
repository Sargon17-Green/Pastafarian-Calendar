// Twenty-first deliberately RED: true signed action gate is internal to
// normative Year5000, but the unfiltered original old lex partition skips it.
import {
  Discovery21LegacyCutletHandler,discoverLegacyCutletPartition,
  Patch20StructureSauceHandler,Discovery20StructureSauceHandler,
  Patch19YearCacheHandler
} from "../src/index.ts";
import {findTrueHistoricalBoundaryMiss,anyPrefix} from "./discovery21Fixtures.ts";
const f=findTrueHistoricalBoundaryMiss();
const h=new Discovery21LegacyCutletHandler(
 new Patch20StructureSauceHandler(new Discovery20StructureSauceHandler(
  new Patch19YearCacheHandler())));
const out=discoverLegacyCutletPartition(h,f.request);
if(out.historicalMissesRequiredGate&&out.requiredBoundary!==null&&
 out.exactActionGateIndex===f.index&&
 out.historicalPartition.join(",")===f.oldPartition.join(",")&&
 !anyPrefix(out.historicalPartition,out.requiredBoundary)&&
 anyPrefix(f.correctPartition,out.requiredBoundary)&&
 out.historicalPrefixConstraintApplied===false&&
 out.realSharedWrites===BigInt(out.realPredecessorCalls)*58n&&
 out.preceding.context.status==="PATCH_20_APPLIED")
 throw Error("DISCOVERY_21_EXPECTED_RED wrongBoundary=1 matches=0 trueActionGate=1 oldFilter=absent");
throw Error("DISCOVERY_21_WITNESS_DRIFT oldWrong="+out.historicalMissesRequiredGate);
