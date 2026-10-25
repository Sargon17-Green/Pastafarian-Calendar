import {
 LegacyIndependentDailyMonthChooser,Discovery24LegacySelector,
 Discovery23MonthLengthSelector,Patch23MonthLengthSelector
} from "../src/index.ts";
import {
 STONES,workCounts,buildHiddenDrops,buildVisibleDrops,initialBowls,
 applyVisibleDropsToBowls,postStir12,bowlOrderFromDrop,askBowl,chooseRank
} from "./normativeOracle.ts";
import {buildStage41CompatibleLegacyFixture,assert}
 from "./discovery21Fixtures.ts";
const f=buildStage41CompatibleLegacyFixture();
const c=f.cDay,source=f.request.firstDaySauceQuestion!;
const L=f.oracleYear.closeGateDay-f.oracleYear.openGateDay;
const w=workCounts(c,source.targetDay);
const visible0=buildVisibleDrops(w,STONES,buildHiddenDrops(w,STONES));
const bowls0=initialBowls(w),monthOld=new Discovery23MonthLengthSelector();
const monthFixed=new Patch23MonthLengthSelector(),weaveOld=new Discovery24LegacySelector();
const chooser=new LegacyIndependentDailyMonthChooser();
let calls=0,wrong=0,ghostWrong=0,oldBlocked=0,dayDecisions=0;
const orders=new Set<string>();
for(let d=1n;d<=720n;d++){
 const visible=[...visible0];visible[46]=d;
 const after=applyVisibleDropsToBowls(
  [...bowls0] as [bigint,bigint,bigint,bigint,bigint,bigint],visible,STONES);
 const bowls=postStir12(
  [...after.bowls] as [bigint,bigint,bigint,bigint,bigint,bigint]);
 const order=bowlOrderFromDrop(d);
 const input={targetDay:source.targetDay,visible,
  stones:source.stones,startBowls:source.startBowls};
 const historical=monthOld.select(c,input,L);
 const fixed=monthFixed.select(c,input,historical);
 const ghost=weaveOld.select(c,input,fixed.correctedLengths);
 const rank=chooseRank(askBowl({bowls,orderAtDrop46:order},
  4,32n),BigInt(fixed.correctedLengths.length));
 const expected=chooser.legacyChooseEachDaySeparately(fixed.correctedLengths,rank);
 if(ghost.historicalMonthIdChoice.correctedRank!==rank||
    ghost.historicalMonthIdChoice.seal!==32n||
    ghost.historicalMonthIdChoice.predecessorSharedWrites!==58||
    ghost.ghost.join(",")!==expected.join(","))wrong++;
 if(!ghost.audit.legal)ghostWrong++;
 if(historical.listBlocked)oldBlocked++;
 calls++;dayDecisions+=ghost.historicalDailyDecisions;orders.add(order.join(","));
}
assert(orders.size===720&&calls===720&&wrong===0&&ghostWrong>0&&oldBlocked>0,
 "720 distinct DROP46 variations with genuine seals and historical ghosts");
console.log("STAGE_48_DISCOVERY_24_PROPERTIES_PASS"+
 " distinctDrop46="+orders.size+" nativeSeal30="+calls+
 " nativeSeal31="+calls+" nativeSeal32="+calls+
 " historicalBlocked="+oldBlocked+" ghostInvalid="+ghostWrong+
 " ghostWrong="+wrong+" independentDailyDecisions="+dayDecisions+
 " realSharedWrites="+(calls*174));
