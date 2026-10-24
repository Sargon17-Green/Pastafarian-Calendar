import {Discovery23MonthLengthSelector,LegacyAllMonthLengthWays}
 from "../src/index.ts";
import {FOUNDATION_DAY as F,STONES,NormativeOracle,workCounts,
 buildHiddenDrops,buildVisibleDrops,initialBowls,applyVisibleDropsToBowls,
 postStir12,bowlOrderFromDrop,askBowl,chooseRank,
 boundedCompositionFamily} from "./normativeOracle.ts";
import {buildStage41CompatibleLegacyFixture,assert} from "./discovery21Fixtures.ts";
const fixture=buildStage41CompatibleLegacyFixture();
const c=fixture.cDay,year=fixture.oracleYear;
const L=year.closeGateDay-year.openGateDay;
const src=fixture.request.firstDaySauceQuestion!;
const w=workCounts(c,src.targetDay);
const visibleOriginal=buildVisibleDrops(w,STONES,buildHiddenDrops(w,STONES));
const bowls=initialBowls(w),selector=new Discovery23MonthLengthSelector();
const max=Math.min(47,Number(L/4n)),min=Number((L+122n)/123n);
const seen=new Set<string>();
const knownCount=new Map<number,bigint>();
let realCountSeal30=0,realLengthSeal31=0,blocked=0,small=0;
let wrongCount=0,wrongLength=0,writes=0;
for(let index=1n;index<=720n;index++){
 const visible=[...visibleOriginal];visible[46]=index;
 const after=applyVisibleDropsToBowls(
  [...bowls] as [bigint,bigint,bigint,bigint,bigint,bigint],visible,STONES);
 const final=postStir12(
  [...after.bowls] as [bigint,bigint,bigint,bigint,bigint,bigint]);
 const order=bowlOrderFromDrop(index);
 const independentMonthRank=chooseRank(askBowl({bowls:final,
  orderAtDrop46:order},3,30n),BigInt(max-min+1));
 const expectedMonthCount=min+Number(independentMonthRank-1n);
 const source={targetDay:src.targetDay,visible,
  stones:src.stones,startBowls:src.startBowls};
 const result=selector.select(c,source,L);
 if(result.selectedMonthCount!==expectedMonthCount)wrongCount++;
 assert(result.monthCountChoice.seal===30n&&
  result.monthCountChoice.predecessorSharedWrites===58&&
  result.historicalListAttempted&&result.historicalPhysicalEnumeration,
  "real native month count and old all-month listing attempt");
 realCountSeal30++;writes+=58;
 if(result.listBlocked){
  blocked++;
  assert(result.originalRows===null&&
   result.historicalMonthLengthChoice===null&&result.oldSeal31ActualCalls===0,
   "cannot select giant historical list");
 }else{
  small++;realLengthSeal31++;writes+=58;
  let N=knownCount.get(result.selectedMonthCount);
  if(N===undefined){
   N=boundedCompositionFamily(L,result.selectedMonthCount,4n,123n).count();
   knownCount.set(result.selectedMonthCount,N);
  }
  const expectedRank=chooseRank(askBowl({bowls:final,
   orderAtDrop46:order},3,31n),N);
  const expected=boundedCompositionFamily(
   L,result.selectedMonthCount,4n,123n).unrank1(expectedRank);
  if(result.historicalMonthLengthChoice?.correctedRank!==expectedRank||
   result.historicalChosenLengths?.join(",")!==expected.join(","))wrongLength++;
  assert(result.oldSeal31ActualCalls===1&&
   result.historicalMonthLengthChoice?.predecessorSharedWrites===58,
   "physically materialized historical list needs actual seal31");
 }
 seen.add(order.join(","));
}
assert(seen.size===720&&wrongCount===0&&wrongLength===0&&
 blocked>0&&writes===58*(720+realLengthSeal31),
 "720 distinct altered DROP46 orders, true selector, bounded materialization");
console.log("STAGE_46_DISCOVERY_23_PROPERTIES_PASS"+
 " distinctDrop46="+seen.size+" nativeSeal30="+realCountSeal30+
 " nativeSeal31="+realLengthSeal31+" blockedLists="+blocked+
 " smallCompleteLists="+small+" countWrong="+wrongCount+
 " smallListSelectionWrong="+wrongLength+" realSharedWrites="+writes);
