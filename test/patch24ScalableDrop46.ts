import {
 Discovery24LegacySelector,Patch24ScalableSelector,
 ScalableLegalWeavingCounter,auditLegacyWeaving
} from "../src/index.ts";
import {
 STONES,workCounts,buildHiddenDrops,buildVisibleDrops,
 initialBowls,applyVisibleDropsToBowls,postStir12,
 bowlOrderFromDrop,askBowl,chooseRank,weavingFamily
} from "./normativeOracle.ts";
import {buildStage41CompatibleLegacyFixture,assert}
 from "./discovery21Fixtures.ts";
// ७२० वेगवेगळे DROP46 स्रोत: जुना आणि नवीन Bowl4/Seal32
// खरोखर स्वतंत्रपणे ५८ writes करतात. बनावट ghost repair मान्य नाही.
const f=buildStage41CompatibleLegacyFixture();
const c=f.cDay,first=f.request.firstDaySauceQuestion!;
const lengths=[4n,4n,5n];
const w=workCounts(c,first.targetDay);
const visible0=buildVisibleDrops(w,STONES,buildHiddenDrops(w,STONES));
const start=initialBowls(w);
const old=new Discovery24LegacySelector(),fix=new Patch24ScalableSelector();
const family=weavingFamily(lengths),N=family.count();
assert(N===3101n&&N===new ScalableLegalWeavingCounter(lengths).count(),
 "independent small oracle count and production count agree");
let wrongRank=0,wrongWeave=0,wrongArchive=0,oldInvalid=0,nativeWrites=0;
const orders=new Set<string>(),ranks=new Set<string>();
for(let i=1n;i<=720n;i++){
 const visible=[...visible0];visible[46]=i;
 const after=applyVisibleDropsToBowls(
  [...start] as [bigint,bigint,bigint,bigint,bigint,bigint],visible,STONES);
 const bowls=postStir12(
  [...after.bowls] as [bigint,bigint,bigint,bigint,bigint,bigint]);
 const order=bowlOrderFromDrop(i);
 const input={targetDay:first.targetDay,visible,
  stones:first.stones,startBowls:first.startBowls};
 const history=old.select(c,input,lengths);
 const result=fix.select(c,input,history);
 const answer={bowls,orderAtDrop46:order};
 const historicalRank=chooseRank(askBowl(answer,4,32n),3n);
 const correctRank=chooseRank(askBowl(answer,4,32n),N);
 const normative=family.unrank1(correctRank);
 if(history.historicalMonthIdChoice.correctedRank!==historicalRank||
    history.historicalMonthIdChoice.predecessorSharedWrites!==58||
    !result.historicalDailyGhostExecuted||
    result.historical!==history)wrongArchive++;
 if(result.correctedRank!==correctRank||
    result.correctedNativeSeal32.familySize!==N||
    result.correctedNativeSeal32.predecessorSharedWrites!==58||
    result.correctedNativeSeal32.seal!==32n||
    result.correctedNativeSeal32.queriedBowlId!==4)wrongRank++;
 if(result.legalWeaving.join(",")!==normative.join(",")||
    !auditLegacyWeaving(lengths,result.legalWeaving).legal||
    result.oldGhostReused)wrongWeave++;
 if(!history.audit.legal)oldInvalid++;
 nativeWrites+=history.realSharedWrites+
    result.correctedNativeSeal32.predecessorSharedWrites;
 orders.add(order.join(","));ranks.add(correctRank.toString());
}
assert(orders.size===720&&ranks.size>10&&
 oldInvalid===720&&wrongRank===0&&wrongWeave===0&&
 wrongArchive===0&&nativeWrites===83520,
 "७२० अस्सल Bowl4-32 दुहेरी निवडी, independent oracle व ८३५२० writes");
console.log("STAGE_49_SCALABLE_DROP46_PASS"+
 " distinctDrop46="+orders.size+
 " distinctCorrectRanks="+ranks.size+
 " actualOldSeal32=720 actualCorrectedSeal32=720"+
 " oldInvalid="+oldInvalid+
 " rankWrong="+wrongRank+" weaveWrong="+wrongWeave+
 " oldArchiveWrong="+wrongArchive+
 " realSharedWrites="+nativeWrites+
 " archivedExpectedReds=24 stage50Blocked=1");
