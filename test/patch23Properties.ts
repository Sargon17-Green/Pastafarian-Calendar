import {
 Patch23MonthLengthSelector,Discovery23MonthLengthSelector
} from "../src/index.ts";
import {
 STONES,workCounts,buildHiddenDrops,buildVisibleDrops,
 initialBowls,applyVisibleDropsToBowls,postStir12,
 bowlOrderFromDrop,askBowl,chooseRank,boundedCompositionFamily
} from "./normativeOracle.ts";
import {buildStage41CompatibleLegacyFixture,assert} from "./discovery21Fixtures.ts";
const f=buildStage41CompatibleLegacyFixture();
const c=f.cDay,source=f.request.firstDaySauceQuestion!;
const L=f.oracleYear.closeGateDay-f.oracleYear.openGateDay;
const w=workCounts(c,source.targetDay);
const visible0=buildVisibleDrops(w,STONES,buildHiddenDrops(w,STONES));
const start=initialBowls(w),old=new Discovery23MonthLengthSelector();
const patched=new Patch23MonthLengthSelector();
const cache=new Map<number,ReturnType<typeof boundedCompositionFamily>>();
const min=Number((L+122n)/123n),max=Math.min(47,Number(L/4n));
const seen=new Set<string>();
let nativeCorrected=0,oldBlocked=0,wrong=0,writes=0,reused=0;
for(let i=1n;i<=720n;i++){
 const visible=[...visible0];visible[46]=i;
 const after=applyVisibleDropsToBowls(
  [...start] as [bigint,bigint,bigint,bigint,bigint,bigint],visible,STONES);
 const bowls=postStir12(
  [...after.bowls] as [bigint,bigint,bigint,bigint,bigint,bigint]);
 const order=bowlOrderFromDrop(i);
 const input={targetDay:source.targetDay,visible,
  stones:source.stones,startBowls:source.startBowls};
 const hist=old.select(c,input,L);
 const m=min+Number(chooseRank(askBowl({bowls,orderAtDrop46:order},
  3,30n),BigInt(max-min+1))-1n);
 assert(hist.selectedMonthCount===m&&hist.monthCountChoice.seal===30n,
  "native old count選");
 let ref=cache.get(m);
 if(!ref){ref=boundedCompositionFamily(L,m,4n,123n);cache.set(m,ref);}
 const N=ref.count();
 const expectedRank=chooseRank(askBowl({bowls,orderAtDrop46:order},
  3,31n),N);
 const expected=ref.unrank1(expectedRank);
 const result=patched.select(c,input,hist);
 if(result.correctFamilySize!==N||
    result.correctedRank!==expectedRank||
    result.correctedLengths.join(",")!==expected.join(","))
  wrong++;
 if(result.historicalResultReused)reused++;
 if(hist.listBlocked)oldBlocked++;
 assert(result.correctedNativeSeal31.predecessorSharedWrites===58&&
  result.correctedNativeSeal31.seal===31n&&
  result.oldMaterializationActuallyAttempted&&
  result.correctedLengths.length===m&&
  new Set(result.correctedLengths).size>=1,
  "real Bowl3 seal31 and virtual lex result");
 nativeCorrected++;writes+=58*(hist.additionalNativeSauceCalls+1);
 seen.add(order.join(","));
}
assert(seen.size===720&&oldBlocked>0&&nativeCorrected===720&&
 wrong===0&&writes>=83520,
 "720 बदललेल्या DROP46 contexts आणि सर्व corrected seal31");
console.log("STAGE_47_PATCH_23_PROPERTIES_PASS"+
 " distinctDrop46="+seen.size+" correctedNativeSeal31="+nativeCorrected+
 " blockedHistoricalLists="+oldBlocked+" lexWrong="+wrong+
 " exactLegacyReused="+reused+" realSharedWrites="+writes);
