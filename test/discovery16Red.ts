import {discoverLegacyYearMax} from "../src/index.ts";
import {FOUNDATION_DAY as F,STONES,NormativeOracle,
 workCounts,buildHiddenDrops,buildVisibleDrops,initialBowls} from "./normativeOracle.ts";
function source(c:bigint,t:bigint){
 const w=workCounts(c,t);return {visible:buildVisibleDrops(w,STONES,buildHiddenDrops(w,STONES)),
 stones:STONES,startBowls:initialBowls(w)};
}
const g=new NormativeOracle().gateDay(1n),c=g+1n;
const v=discoverLegacyYearMax(c,1n,[source(F,F+1n)],
 [{...source(F,F+1n),targetDay:F+1n}],source(c,c),
 [5779n,5780n,5781n].map((L,i)=>({
  openGateIndex:1n,closeGateIndex:BigInt(i+7),
  openGateDay:g,closeGateDay:g+L
 })));
const wrong=v.filter.kept.filter(e=>e.length>5778n).length;
const matches=v.filter.kept.length-wrong;
if(wrong===3&&matches===0&&v.yearSelection.familySize===3n&&
 v.filter.acceptedLongLengths.join(",")==="5779,5780,5781")
 throw Error("DISCOVERY_16_EXPECTED_RED mismatches=3 matches=0 oldMax=5781 realMax=5778");
throw Error("DISCOVERY_16_WITNESS_DRIFT mismatches="+wrong+" matches="+matches);
