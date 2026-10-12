import {
 LegacyShortOnlyWideSelectionAdapter,discoverLegacyShortOnlyWide,
 Patch13RejectionRankAdapter
} from "../src/index.ts";
import {
 FOUNDATION_DAY as F,M,STONES,workCounts,buildHiddenDrops,buildVisibleDrops,
 initialBowls,applyVisibleDropsToBowls,postStir12,bowlOrderFromDrop,
 askBowl,chooseRank
} from "./normativeOracle.ts";
function check(ok:boolean,msg:string):void{if(!ok)throw Error(msg);}
const old=new LegacyShortOnlyWideSelectionAdapter(),fixed=new Patch13RejectionRankAdapter();
let shortSizes=0,shortCases=0,shortWrong=0,shortRejected=0,shortWrap=0;
for(let N=1n;N<=256n;N++){
 for(const first of [1n,2n,M-2n,M-1n,M]){
  for(const directionStep of [-1n,1n] as const){
   const stream={first,directionStep};
   const historical=old.oldChooseShortOnly(stream,N);
   const correct=chooseRank(stream,N);
   if(historical.rank!==correct)shortWrong++;
   if(historical.shortSelection!.rejectedCandidates>0n){
    shortRejected++;
    if(directionStep===1n)shortWrap++;
   }
   check(!historical.blocked&&historical.rank===correct&&
     historical.shortSelection!==null&&
     historical.shortSelection.mode==="SHORT"&&
     historical.shortSelection.rank===fixed.choose(stream,N).rank&&
     historical.legacyAcceptanceLimit===(M/N)*N&&
     historical.shortSelectorCalls===1&&historical.wideSelectorCalls===0,
     "all short families preserve the true Stage27 selector");
   shortCases++;
  }
 }
 shortSizes++;
}
check(shortSizes===256&&shortCases===2560&&shortWrong===0&&
 shortRejected>0&&shortWrap>0,"256×5×2 all short selections correct");
const wideN=[M+1n,M+2n,M*M-1n,M*M,M*M+1n,
 M*M+M+1n,M*M*M-1n,M*M*M,M*M*M+1n,1n<<16384n];
let wideCases=0,wideInvalid=0,correctedWideWrong=0,largestDigits=0;
for(const N of wideN){
 for(const s of [
  {first:1n,directionStep:1n as const},
  {first:2n,directionStep:-1n as const},
  {first:M-1n,directionStep:-1n as const}
 ]){
  const oldResult=old.oldChooseShortOnly(s,N);
  const reference=chooseRank(s,N),actual=fixed.choose(s,N);
  if(actual.rank!==reference)correctedWideWrong++;
  if(oldResult.rank===0n&&oldResult.blocked)wideInvalid++;
  largestDigits=Math.max(largestDigits,actual.digitCount);
  check(oldResult.rank===0n&&oldResult.blocked&&
    oldResult.legacyAcceptanceLimit===0n&&
    oldResult.shortSelection===null&&oldResult.shortSelectorCalls===0&&
    oldResult.wideSelectorCalls===0&&
    actual.mode==="WIDE"&&actual.rank>=1n&&actual.rank<=N&&
    reference>=1n&&reference<=N,
    "old short-only blocked even though canonical wide rank exists");
  wideCases++;
 }
}
check(wideCases===30&&wideInvalid===30&&correctedWideWrong===0&&
 largestDigits>10,"wide M^k and 16K-bit boundaries all intentionally blocked");
const pairs:readonly (readonly [bigint,bigint])[]=[
 [F,F],[F-1n,F],[F+1n,F],[F,F-1n],[F,F+1n],
 [F-89n,F+273n],[F+273n,F-89n],[-278522n,-278522n],
 [-278522n,-268522n],[1n,1n],[100000n,-100000n],[-100000n,100000n]
];
const w=workCounts(F,F),hidden=buildHiddenDrops(w,STONES);
const baseline=buildVisibleDrops(w,STONES,hidden),start=initialBowls(w);
const families=[1n,2n,3n,5n,922n,M-1n,M,M+1n,M*M,M*M+1n] as const;
const contexts=new Set<object>(),uniqueOrders=new Set<string>();
let real=0,varied=0,giant=0,ranks=0,histories=0,writes=0;
let fullShort=0,fullWide=0,fullWrong=0,fullBlocked=0,fullStreamWrong=0;
function verify(c:bigint,t:bigint,visible:readonly bigint[],bowls:readonly bigint[],
 id:number,seal:bigint,N:bigint,family:"real"|"varied"|"giant"|"rank"):void{
 const before=[...bowls];
 const out=discoverLegacyShortOnlyWide(c,t,visible,STONES,bowls,id,seal,N);
 const afterDrops=applyVisibleDropsToBowls(
  [...bowls] as [bigint,bigint,bigint,bigint,bigint,bigint],visible,STONES);
 const final=postStir12(
  [...afterDrops.bowls] as [bigint,bigint,bigint,bigint,bigint,bigint]);
 const order=bowlOrderFromDrop(visible[46]!);
 const stream=askBowl({bowls:final,orderAtDrop46:order},id,seal);
 const expected=chooseRank(stream,N),wide=N>M;
 if(out.firstAnswer!==stream.first||out.directionStep!==stream.directionStep)fullStreamWrong++;
 if(out.correctedPredecessorRank!==expected)fullWrong++;
 if(wide){fullWide++;if(out.legacyShortOnlyRank===0n)fullBlocked++;}
 else{fullShort++;if(out.legacyShortOnlyRank!==expected)fullWrong++;}
 check(out.preceding.correctedRank===expected&&
  out.preceding.preceding.preceding.orderAt46Latch.join(",")===order.join(",")&&
  out.preceding.preceding.preceding.correctedNextBowlId===
    order[(order.indexOf(id)+1)%6]&&
  out.preceding.preceding.preceding.afterDropBowls.every((v,j)=>v===afterDrops.bowls[j])&&
  out.preceding.preceding.preceding.finalBowls.every((v,j)=>v===final[j])&&
  out.preceding.preceding.preceding.preceding.sharedMemoryWrites===58&&
  out.preceding.preceding.preceding.preceding.historical.latestSource==="STIR_12"&&
  out.preceding.preceding.legacyModuloCalls===1&&
  out.preceding.legacySelectorCalls===1&&out.preceding.correctedSelectorCalls===1&&
  out.blockedWideSelection===wide&&
  (wide?out.legacyShortOnlyRank===0n:out.legacyShortOnlyRank===expected)&&
  out.historicalMismatch===wide&&
  out.legacyShortOnlyCalls===1&&out.predecessorSharedMemoryWrites===58&&
  out.context.status==="DISCOVERY_14_RECORDED"&&
  out.context.metrics.get("discovery14.legacy_short_only_calls")===1n&&
  !contexts.has(out.context)&&out.context!==out.preceding.context&&
  Object.isFrozen(out)&&Object.isFrozen(out.oldResult)&&
  bowsUnchanged(bowls,before),"full original 58-write and correct upstream rank, old short-only behavior");
 contexts.add(out.context);histories++;writes+=58;
 if(family==="rank")uniqueOrders.add(out.preceding.preceding.preceding.orderAt46Latch.join(","));
}
function bowsUnchanged(a:readonly bigint[],b:readonly bigint[]):boolean{
 return a.length===b.length&&a.every((v,j)=>v===b[j]);
}
for(const [c,t] of pairs){
 const count=workCounts(c,t),h=buildHiddenDrops(count,STONES);
 verify(c,t,buildVisibleDrops(count,STONES,h),initialBowls(count),
  (real%6)+1,BigInt(real%33+1),families[real%families.length]!,"real");real++;
}
for(let j=0;j<64;j++){
 const v=[...baseline];v[1]=j%2===0?BigInt(j*149+1):-BigInt(j*137+3);
 v[46]=j%3===0?BigInt(j*721+2):-BigInt(j*719+11);
 verify(F+BigInt(j),F-BigInt(j),v,start,(j%6)+1,BigInt(j%33+1),
  families[j%families.length]!,"varied");varied++;
}
const huge=(1n<<8192n)+193n;
for(const d of [huge,-huge,huge*huge,-huge*huge,0n,720n,1n<<16384n,-(1n<<16384n)]){
 const v=[...baseline];v[1]=d;v[46]=-d+1n;
 const b=[huge+11n,-huge-13n,huge+17n,-huge-23n,huge+37n,-huge-41n];
 verify(F-huge,F+huge,v,b,(giant%6)+1,BigInt(giant+1),
  families[giant%families.length]!,"giant");giant++;
}
for(let rank=1n;rank<=720n;rank++){
 const v=[...baseline];v[46]=rank;
 verify(F,F,v,start,(Number(rank)%6)+1,BigInt(Number(rank)%33+1),
  families[Number(rank)%families.length]!,"rank");ranks++;
}
check(real===12&&varied===64&&giant===8&&ranks===720&&histories===804&&
 writes===46632&&uniqueOrders.size===720&&contexts.size===804&&
 fullShort>0&&fullWide>0&&fullWrong===0&&
 fullStreamWrong===0&&fullBlocked===fullWide,
 "804 complete histories, every wide fails old path, upstream is exact");
console.log("STAGE_28_DISCOVERY_14_PROPERTIES_PASS shortSizes="+shortSizes+
 " shortCases="+shortCases+" shortWrong="+shortWrong+
 " shortRejected="+shortRejected+" shortWrap="+shortWrap+
 " wideCases="+wideCases+" wideInvalid="+wideInvalid+
 " correctedWideWrong="+correctedWideWrong+" largestDigits="+largestDigits+
 " realPairs="+real+" varied="+varied+" giant="+giant+" ranks="+ranks+
 " unique="+uniqueOrders.size+" histories="+histories+" sharedWrites="+writes+
 " streamWrong="+fullStreamWrong+" upstreamWrong="+fullWrong+
 " fullShort="+fullShort+" fullWide="+fullWide+" fullBlocked="+fullBlocked);
