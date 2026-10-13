// The eighteenth intentionally failing witness keeps a physically executed
// Stage35 signed-gate/real seal10 path and the old /365 ghost.
import {discoverLegacyJumpGuess} from "../src/index.ts";
import {FOUNDATION_DAY as F,STONES,NormativeOracle,workCounts,
 buildHiddenDrops,buildVisibleDrops,initialBowls,sauce,askBowl,chooseRank
} from "./normativeOracle.ts";
function source(c:bigint,t:bigint){
 const w=workCounts(c,t);return {
  visible:buildVisibleDrops(w,STONES,buildHiddenDrops(w,STONES)),
  stones:STONES,startBowls:initialBowls(w)
 };
}
const gate=new NormativeOracle().gateDay(1n),c=gate+1n;
const year=source(c,c);
const rank=chooseRank(askBowl(sauce(c,c),1,10n),2n);
const open=rank===1n?gate-100n:gate;
const lastDay=open+1000n;
const out=discoverLegacyJumpGuess(c,lastDay,1n,
 [source(F,F+1n)],[{...source(F,F+1n),targetDay:F+1n}],year,
 [{openGateIndex:1n,closeGateIndex:7n,
   openGateDay:gate,closeGateDay:gate+800n}],
 [{openGateIndex:1n,closeGateIndex:7n,
   openGateDay:gate,closeGateDay:gate+1000n},
  {openGateIndex:0n,closeGateIndex:6n,
   openGateDay:gate-100n,closeGateDay:gate+900n}]);
if(out.ghostYearNumber===5002n&&out.anchorYearNumber===5000n&&
 out.selectedAnchor.lastDay===lastDay&&
 out.guess.knownAnchorMismatch===true&&
 out.preceding.correctedRank===rank&&
 out.predecessorCallCount===4&&
 out.guess.role==="TELEMETRY_ONLY"&&!out.authoritativeTargetYearResolved)
 throw Error("DISCOVERY_18_EXPECTED_RED mismatches=1 matches=0 oldGuess=5002 anchorYear=5000 divisor=365");
throw Error("DISCOVERY_18_WITNESS_DRIFT oldGuess="+out.ghostYearNumber);
