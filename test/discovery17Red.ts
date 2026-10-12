// Stage34 deliberately RED: genuine Stage33 predecessor + real seal10,
// but synthetic equal-length multi-opening year pairs in reversed open-day order.
import {discoverLegacyYear5000Tie} from "../src/index.ts";
import {FOUNDATION_DAY as F,STONES,NormativeOracle,workCounts,
 buildHiddenDrops,buildVisibleDrops,initialBowls} from "./normativeOracle.ts";
function q(c:bigint,t:bigint){
 const w=workCounts(c,t);return {
 visible:buildVisibleDrops(w,STONES,buildHiddenDrops(w,STONES)),
 stones:STONES,startBowls:initialBowls(w)
 };
}
const g=new NormativeOracle().gateDay(1n),c=g+1n;
const found=discoverLegacyYear5000Tie(c,1n,
 [q(F,F+1n)],[{...q(F,F+1n),targetDay:F+1n}],q(c,c),
 [{openGateIndex:1n,closeGateIndex:7n,openGateDay:g,closeGateDay:g+800n}],
 [{openGateIndex:1n,closeGateIndex:7n,
   openGateDay:g,closeGateDay:g+1000n},
  {openGateIndex:0n,closeGateIndex:6n,
   openGateDay:g-100n,closeGateDay:g+900n}]);
const expected=[...found.filter.corrected].sort((a,b)=>{
 if(a.length!==b.length)return a.length<b.length?-1:1;
 return a.candidate.openGateDay<b.candidate.openGateDay?-1:
  a.candidate.openGateDay>b.candidate.openGateDay?1:0;
});
let mismatches=0,matches=0;
for(let k=0;k<expected.length;k++){
 if(found.oldSorted[k]!==expected[k])mismatches++;else matches++;
}
if(mismatches===2&&matches===0&&found.lengthTieInversions===1&&
 found.predecessorCallCount===3&&
 found.yearSelection.correctedRank===found.oldSelectedRank)
 throw Error("DISCOVERY_17_EXPECTED_RED mismatches=2 matches=0 length=1000 tie=opening-gate");
throw Error("DISCOVERY_17_WITNESS_DRIFT mismatches="+mismatches+" matches="+matches);
