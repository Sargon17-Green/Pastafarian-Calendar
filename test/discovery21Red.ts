// Twenty-first deliberately RED historical case: an actual exact gate
// calculationDay, true recomputed Year5000, actual full native first-day
// Sauce + seals 20/21, but unfiltered old positive composition omits gate.
// Stage17 legacy full route disallows cDay exactly at gate, so the independent
// Stage37 authoritative year route is used here; no lineage is fabricated.
import {Discovery21ExactGateProbeHandler} from "../src/index.ts";
import {findTrueHistoricalBoundaryMiss,anyPrefix} from "./discovery21Fixtures.ts";
const f=findTrueHistoricalBoundaryMiss();
const out=new Discovery21ExactGateProbeHandler().run(
 f.request.historical.yearQuestion.calculationDay,
 f.index,
 f.request.historical.yearQuestion.positive,
 f.request.historical.yearQuestion.negative,
 f.request.historical.yearQuestion.trueYearQuestion,
 f.request.firstDaySauceQuestion!);
if(out.actuallyMissedRequiredGate&&
 out.actionGateIndex===f.index&&
 out.genuineYearNumber===5000n&&
 out.trueYearOpenGateIndex===f.year.openGateIndex&&
 out.trueYearCloseGateIndex===f.year.closeGateIndex&&
 out.oldPartition.join(",")===f.oldPartition.join(",")&&
 !anyPrefix(out.oldPartition,out.requiredBoundary)&&
 anyPrefix(f.correctPartition,out.requiredBoundary)&&
 out.historicalPrefixConstraintApplied===false&&
 out.nativeSharedWrites===BigInt(out.realNativeSauceCalls)*58n)
 throw Error("DISCOVERY_21_EXPECTED_RED wrongBoundary=1 matches=0 trueActionGate=1 oldFilter=absent");
throw Error("DISCOVERY_21_WITNESS_DRIFT oldWrong="+out.actuallyMissedRequiredGate);
