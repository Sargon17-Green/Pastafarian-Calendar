import {
 OldContiguousMonthDayGuess,Discovery24LegacySelector,Patch24ScalableSelector
} from "../src/index.ts";
import {
 STONES,workCounts,buildHiddenDrops,buildVisibleDrops,initialBowls,
 applyVisibleDropsToBowls,postStir12,bowlOrderFromDrop,askBowl,chooseRank,
 weavingFamily
} from "./normativeOracle.ts";
import {buildStage41CompatibleLegacyFixture,assert}
 from "./discovery21Fixtures.ts";

const f=buildStage41CompatibleLegacyFixture(),c=f.cDay,src=f.request.firstDaySauceQuestion!;
const lengths=[4n,4n,5n],old=new Discovery24LegacySelector();
const fixed=new Patch24ScalableSelector(),guess=new OldContiguousMonthDayGuess();
const family=weavingFamily(lengths),N=family.count();
const work=workCounts(c,src.targetDay);
const sourceVisible=buildVisibleDrops(work,STONES,buildHiddenDrops(work,STONES));
const initial=initialBowls(work);
const orders=new Set<string>(),ranks=new Set<string>();
let oldWrong=0,exact=0,smaller=0,wrongMonth=0,wrongLegal=0,wrongRank=0,writes=0,fullDays=0;
for(let d=1n;d<=720n;d++){
 const visible=[...sourceVisible];visible[46]=d;
 const bottles=applyVisibleDropsToBowls(
  [...initial] as [bigint,bigint,bigint,bigint,bigint,bigint],visible,STONES);
 const bowls=postStir12(
  [...bottles.bowls] as [bigint,bigint,bigint,bigint,bigint,bigint]);
 const order=bowlOrderFromDrop(d);
 const question={targetDay:src.targetDay,visible,stones:src.stones,
  startBowls:src.startBowls};
 const historical=old.select(c,question,lengths);
 const repaired=fixed.select(c,question,historical);
 const independentRank=chooseRank(
  askBowl({bowls,orderAtDrop46:order},4,32n),N);
 const word=family.unrank1(independentRank);
 if(repaired.correctedRank!==independentRank)wrongRank++;
 if(repaired.legalWeaving.join(",")!==word.join(","))wrongLegal++;
 if(historical.historicalMonthIdChoice.predecessorSharedWrites!==58||
    repaired.correctedNativeSeal32.predecessorSharedWrites!==58)
  throw Error("full native Bowl4 Seal32 twice");
 const counts=Array<number>(3).fill(0);
 for(let day=1;day<=word.length;day++){
  const month=word[day-1]!;
  counts[month-1]!++;
  const result=guess.oldContiguousMonthDayGuess(repaired.legalWeaving,day);
  if(result.monthId!==month)wrongMonth++;
  const trueOrdinal=counts[month-1]!;
  if(result.guessedDayInMonth<trueOrdinal)smaller++;
  if(result.guessedDayInMonth===trueOrdinal)exact++;
  else oldWrong++;
  fullDays++;
 }
 assert(counts.join(",")==="4,4,5","legal length conservation");
 orders.add(order.join(","));ranks.add(independentRank.toString());
 writes+=116;
}
assert(orders.size===720&&ranks.size>10&&fullDays===720*13&&
 oldWrong>0&&exact>0&&smaller===0&&wrongMonth===0&&
 wrongLegal===0&&wrongRank===0&&writes===83520,
 "720 altered native Bowl4 seal32 pairs, exhaustive small month-prefix oracle");
console.log("STAGE_50_DISCOVERY_25_NATIVE_PROPERTIES_PASS"+
 " drop46Orders="+orders.size+" distinctCorrectedRanks="+ranks.size+
 " auditedDays="+fullDays+" oldContiguousOvercounts="+oldWrong+
 " exactlyCorrectByAccident="+exact+" oldUndercounts="+smaller+
 " monthWrong="+wrongMonth+" legalWordWrong="+wrongLegal+
 " seal32RankWrong="+wrongRank+" oldSeal32=720 correctedSeal32=720"+
 " nativeSharedWrites="+writes+" correctionNotApplied=1");
