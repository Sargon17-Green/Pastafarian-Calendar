import {
  LegacyShortOnlyWideSelectionAdapter,Patch13RejectionRankAdapter,
  patch14WideChoice
} from "../src/index.ts";
import {
  FOUNDATION_DAY as F,M,STONES,workCounts,buildHiddenDrops,buildVisibleDrops,
  initialBowls,applyVisibleDropsToBowls,postStir12,bowlOrderFromDrop,
  askBowl,chooseRank
} from "./normativeOracle.ts";
function check(ok:boolean,msg:string):void{if(!ok)throw Error(msg);}
const old=new LegacyShortOnlyWideSelectionAdapter(),patch13=new Patch13RejectionRankAdapter();
let shortCases=0,shortWrong=0,rejected=0,wrap=0;
for(let n=1n;n<=256n;n++){
 for(const first of [1n,2n,M-2n,M-1n,M]){
  for(const directionStep of [-1n,1n] as const){
   const stream={first,directionStep};
   const prev=old.oldChooseShortOnly(stream,n);
   const expected=chooseRank(stream,n);
   if(prev.rank!==expected)shortWrong++;
   if(prev.shortSelection!.rejectedCandidates>0n){
    rejected++;
    if(directionStep===1n)wrap++;
   }
   check(prev.rank===expected&&!prev.blocked&&
    prev.shortSelectorCalls===1&&prev.wideSelectorCalls===0&&
    prev.shortSelection?.mode==="SHORT"&&
    prev.shortSelection.rank===patch13.choose(stream,n).rank,
    "previous short selector is complete and trustworthy");
   shortCases++;
  }
 }
}
check(shortCases===2560&&shortWrong===0&&rejected>0&&wrap>0,
 "short surrogate grid complete");
const sizes=[M+1n,M+2n,M*M-1n,M*M,M*M+1n,M*M+M+1n,
 M*M*M-1n,M*M*M,M*M*M+1n,1n<<16384n] as const;
let directWide=0,blocked=0,wideWrong=0,wideDigits=0;
for(const N of sizes){
 for(const stream of [
  {first:1n,directionStep:1n as const},
  {first:2n,directionStep:-1n as const},
  {first:M-1n,directionStep:-1n as const}
 ]){
  const historic=old.oldChooseShortOnly(stream,N);
  const select=patch13.choose(stream,N),norm=chooseRank(stream,N);
  if(select.rank!==norm)wideWrong++;
  if(historic.blocked&&historic.rank===0n)blocked++;
  check(historic.blocked&&historic.rank===0n&&
   historic.legacyAcceptanceLimit===0n&&historic.shortSelection===null&&
   select.mode==="WIDE"&&select.rank===norm&&
   select.digitCount>=2&&select.digitCount===select.answerDigits.length&&
   select.acceptedCandidate>=1n&&select.acceptedCandidate<=select.acceptanceLimit,
   "full wide digit construction and old zero unchanged");
  wideDigits+=select.digitCount;
  directWide++;
 }
}
check(directWide===30&&blocked===30&&wideWrong===0&&wideDigits>100,
 "wide M^k/direct giant coverage");

const pairs:readonly (readonly [bigint,bigint])[]=[
 [F,F],[F-1n,F],[F+1n,F],[F,F-1n],[F,F+1n],
 [F-89n,F+273n],[F+273n,F-89n],[-278522n,-278522n],
 [-278522n,-268522n],[1n,1n],[100000n,-100000n],[-100000n,100000n]
];
const f=workCounts(F,F),baseline=buildVisibleDrops(f,STONES,buildHiddenDrops(f,STONES));
const start=initialBowls(f);
const families=[1n,2n,3n,5n,922n,M-1n,M,M+1n,M*M,M*M+1n] as const;
const contexts=new Set<object>(),orders=new Set<string>();
let real=0,varied=0,giant=0,ranks=0,histories=0,writes=0;
let realWrong=0,streamWrong=0,oldWrong=0,oldSame=0,short=0,wide=0;
let historicalWideBlocked=0,actualExtraWide=0;
function verify(c:bigint,t:bigint,visible:readonly bigint[],bowls:readonly bigint[],
 id:number,seal:bigint,N:bigint,kind:"real"|"varied"|"giant"|"rank"){
 const snapshot=[...bowls];
 const result=patch14WideChoice(c,t,visible,STONES,bowls,id,seal,N);
 const applied=applyVisibleDropsToBowls(
  [...bowls] as [bigint,bigint,bigint,bigint,bigint,bigint],visible,STONES);
 const baked=postStir12(
  [...applied.bowls] as [bigint,bigint,bigint,bigint,bigint,bigint]);
 const order=bowlOrderFromDrop(visible[46]!);
 const stream=askBowl({bowls:baked,orderAtDrop46:order},id,seal);
 const expected=chooseRank(stream,N),isWide=N>M;
 if(result.correctedRank!==expected)realWrong++;
 if(result.preceding.firstAnswer!==stream.first||
    result.preceding.directionStep!==stream.directionStep)streamWrong++;
 if(result.legacyShortOnlyRank===expected)oldSame++;else oldWrong++;
 if(isWide){wide++;if(result.preceding.oldResult.blocked)historicalWideBlocked++;
   actualExtraWide+=result.extraWideCalls;}
 else short++;
 check(result.selectionMode===(isWide?"WIDE_CHOICE":"SHORT_LEGACY")&&
  result.correctedRank===expected&&result.correctedRank===result.selection.rank&&
  result.correctedRank===result.preceding.correctedPredecessorRank&&
  result.preceding.preceding.correctedRank===expected&&
  result.preceding.preceding.preceding.preceding.orderAt46Latch.join(",")===order.join(",")&&
  result.preceding.preceding.preceding.preceding.correctedNextBowlId===
   order[(order.indexOf(id)+1)%6]&&
  result.preceding.preceding.preceding.preceding.afterDropBowls.every((v,j)=>v===applied.bowls[j])&&
  result.preceding.preceding.preceding.preceding.finalBowls.every((v,j)=>v===baked[j])&&
  result.preceding.preceding.preceding.preceding.preceding.sharedMemoryWrites===58&&
  result.preceding.preceding.preceding.preceding.preceding.historical.latestSource==="STIR_12"&&
  result.preceding.preceding.preceding.legacyModuloCalls===1&&
  result.preceding.preceding.legacySelectorCalls===1&&
  result.preceding.legacyShortOnlyCalls===1&&
  result.preceding.blockedWideSelection===isWide&&
  result.legacyShortOnlyRank===(isWide?0n:expected)&&
  result.historicalMismatch===isWide&&
  result.extraWideCalls===(isWide?1:0)&&
  result.selection.mode===(isWide?"WIDE":"SHORT")&&
  result.predecessorSharedWrites===58&&
  result.context.status==="PATCH_14_APPLIED"&&
  result.context.metrics.get("patch14.real_legacy_calls")===1n&&
  !contexts.has(result.context)&&result.context!==result.preceding.context&&
  Object.isFrozen(result.selection)&&
  bowls.length===snapshot.length&&bowls.every((v,j)=>v===snapshot[j]),
  "804 full, real inherited history, canonical selection, no input mutations");
 contexts.add(result.context);histories++;writes+=58;
 if(kind==="rank")orders.add(result.preceding.preceding.preceding.preceding.orderAt46Latch.join(","));
}
for(const [c,t] of pairs){
 const w=workCounts(c,t),v=buildVisibleDrops(w,STONES,buildHiddenDrops(w,STONES));
 verify(c,t,v,initialBowls(w),(real%6)+1,BigInt(real%33+1),
  families[real%families.length]!,"real");real++;
}
for(let j=0;j<64;j++){
 const v=[...baseline];v[1]=j%2===0?BigInt(j*149+1):-BigInt(j*137+3);
 v[46]=j%3===0?BigInt(j*721+2):-BigInt(j*719+11);
 verify(F+BigInt(j),F-BigInt(j),v,start,(j%6)+1,BigInt(j%33+1),
  families[j%families.length]!,"varied");varied++;
}
const large=(1n<<8192n)+193n;
for(const d of [large,-large,large*large,-large*large,0n,720n,
 1n<<16384n,-(1n<<16384n)]){
 const v=[...baseline];v[1]=d;v[46]=-d+1n;
 const b=[large+11n,-large-13n,large+17n,-large-23n,large+37n,-large-41n];
 verify(F-large,F+large,v,b,(giant%6)+1,BigInt(giant+1),
  families[giant%families.length]!,"giant");giant++;
}
for(let rank=1n;rank<=720n;rank++){
 const v=[...baseline];v[46]=rank;
 verify(F,F,v,start,(Number(rank)%6)+1,BigInt(Number(rank)%33+1),
  families[Number(rank)%families.length]!,"rank");ranks++;
}
check(real===12&&varied===64&&giant===8&&ranks===720&&histories===804&&
 writes===46632&&orders.size===720&&contexts.size===804&&
 realWrong===0&&streamWrong===0&&oldWrong===wide&&oldSame===short&&
 historicalWideBlocked===wide&&actualExtraWide===wide&&short+wide===histories,
 "all 804 corrected without losing archived historical scar");
console.log("STAGE_29_PATCH_14_PROPERTIES_PASS shortCases="+shortCases+
 " shortWrong="+shortWrong+" shortRejected="+rejected+" shortWrap="+wrap+
 " wideDirect="+directWide+" wideHistoricalBlocked="+blocked+
 " wideDirectWrong="+wideWrong+" wideDigits="+wideDigits+
 " realPairs="+real+" varied="+varied+" giant="+giant+" ranks="+ranks+
 " unique="+orders.size+" histories="+histories+" sharedWrites="+writes+
 " streamWrong="+streamWrong+" correctedWrong="+realWrong+
 " short="+short+" wide="+wide+" oldWrong="+oldWrong+
 " oldMatches="+oldSame+" actualExtraWide="+actualExtraWide);
