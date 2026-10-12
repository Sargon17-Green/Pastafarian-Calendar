// Stage30 intentionally failing negative gate sides; a standalone witness.
import {discoverLegacyPositiveGate} from "../src/index.ts";
import {FOUNDATION_DAY as F,NormativeOracle,STONES,workCounts,
 buildHiddenDrops,buildVisibleDrops,initialBowls} from "./normativeOracle.ts";
function q(n:bigint){const w=workCounts(F,F+n);return {
 visible:buildVisibleDrops(w,STONES,buildHiddenDrops(w,STONES)),
 stones:STONES,startBowls:initialBowls(w)
};}
const o=new NormativeOracle();
const minus1=discoverLegacyPositiveGate(-1n,[q(1n)]);
const minus2=discoverLegacyPositiveGate(-2n,[q(1n),q(2n)]);
let mismatches=0,matches=0;
for(const [observed,actual] of [[minus1.historicalGateDay,o.gateDay(-1n)],
  [minus2.historicalGateDay,o.gateDay(-2n)] ]){
 if(observed!==actual)mismatches++;else matches++;
}
if(mismatches===2&&matches===0&&
 minus1.gaps[0]!.askedTargetDay===F+1n&&
 minus2.gaps[1]!.askedTargetDay===F+2n)
 throw Error("DISCOVERY_15_EXPECTED_RED mismatches=2 matches=0 gates=-1,-2 asked=FOUNDATION+abs");
throw Error("DISCOVERY_15_WITNESS_DRIFT mismatches="+mismatches+" matches="+matches);
