import {
 Patch17EqualLengthRunSorter,Patch16YearLengthGuard,
 patch17Year5000Tie
} from "../src/index.ts";
import {
 FOUNDATION_DAY as F,STONES,NormativeOracle,workCounts,
 buildHiddenDrops,buildVisibleDrops,initialBowls,sauce,askBowl,chooseRank,
 applyVisibleDropsToBowls,postStir12,bowlOrderFromDrop
} from "./normativeOracle.ts";
function check(b:boolean,msg:string):void{if(!b)throw Error(msg);}
function source(c:bigint,t:bigint){
 const w=workCounts(c,t);
 return {visible:buildVisibleDrops(w,STONES,buildHiddenDrops(w,STONES)),
  stones:STONES,startBowls:initialBowls(w)};
}
function raw(openIndex:bigint,openDay:bigint,length:bigint){
 return {openGateIndex:openIndex,closeGateIndex:openIndex+6n,
  openGateDay:openDay,closeGateDay:openDay+length};
}
function normative<T extends {length:bigint;candidate:{openGateDay:bigint}}>(entries:readonly T[]):T[]{
 return [...entries].sort((a,b)=>{
  if(a.length!==b.length)return a.length<b.length?-1:1;
  return a.candidate.openGateDay<b.candidate.openGateDay?-1:
   a.candidate.openGateDay>b.candidate.openGateDay?1:0;
 });
}
const guard=new Patch16YearLengthGuard(),patch=new Patch17EqualLengthRunSorter();
let direct=0,totalRuns=0,correctedWrong=0,oldWrong=0;
let oldComparator=0,moved=0,tied=0;
for(let i=0;i<256;i++){
 const day=F+BigInt(i*19),length=252n+BigInt(i);
 const seq=[
  raw(10n,day+100n,length),
  raw(11n,day+40n,length+1n),
  raw(12n,day-100n,length),
  raw(13n,day-40n,length+1n),
  raw(14n,day+60n,length),
  raw(15n,day-80n,length)
 ];
 const input=guard.apply(seq).corrected;
 const out=patch.sortAfterHistorical(input),expected=normative(input);
 if(out.corrected.some((e,j)=>e!==expected[j]))correctedWrong++;
 if(out.historical.some((e,j)=>e!==expected[j]))oldWrong++;
 check(out.corrected.every((e,j)=>e===expected[j])&&
  out.historical.map(e=>e.originalPosition).join(",")==="0,2,4,5,1,3"&&
  out.corrected.map(e=>e.originalPosition).join(",")==="2,5,4,0,3,1"&&
  out.tieRunCount===2&&out.tiedRuns[0]!.start===0&&
  out.tiedRuns[0]!.exclusiveEnd===4&&
  out.tiedRuns[1]!.start===4&&out.tiedRuns[1]!.exclusiveEnd===6&&
  out.tiedRuns[0]!.length===length&&
  out.tiedRuns[1]!.length===length+1n&&
  out.movedMembers===6&&out.tieMemberCount===6&&
  out.oldComparatorCalls>=5&&out.runSortCalls===2&&
  out.historical.every((e,j)=>e.length===out.corrected[j]!.length),
  "256 independent disjoint maximal runs preserve historical outer length ordering");
 totalRuns+=out.tieRunCount;
 oldComparator+=out.oldComparatorCalls;
 moved+=out.movedMembers;tied+=out.tieMemberCount;direct++;
}
check(direct===256&&correctedWrong===0&&oldWrong===256&&
 totalRuns===512&&moved===1536&&tied===1536&&oldComparator>=1280,
 "all 256 paired-run sequences corrected only inside maximal ties");
let giants=0;
const large=1n<<16384n;
for(const L of [252n,5778n]){
 for(const days of [[large,-large],[-large,large],[large+7n,large],[0n,large]]){
  const o=patch.sortAfterHistorical(guard.apply([
   raw(1n,days[0]!,L),raw(2n,days[1]!,L)
  ]).corrected);
  check(o.corrected[0]!.candidate.openGateDay===
   (days[0]!<days[1]!?days[0]!:days[1]!)&&
   o.corrected.every((e,j)=>e===normative(o.historical)[j])&&
   o.corrected.every(e=>e.length===L),
   "huge signed opening gate days are ordered without 64-bit truncation");
  giants++;
 }
}
const oracle=new NormativeOracle(),owners=new Set<object>();
let real=0,positive=0,negative=0,canonicalWrong=0,oldTieWrong=0,rankWrong=0;
let realSelectorCalls=0,oldStableSortCalls=0,realPred=0,realWrites=0,realGateCalls=0;
for(const side of [1n,-1n] as const){
 for(let n=1n;n<=6n;n++){
  const ix=side*n,g=oracle.gateDay(ix),c=g+1n;
  const historical=Array.from({length:Number(n)},(_,j)=>source(F,F+BigInt(j+1)));
  const signed=Array.from({length:Number(n)},(_,j)=>({
   ...source(F,F+side*BigInt(j+1)),targetDay:F+side*BigInt(j+1)
  }));
  const year=source(c,c);
  const anchor=[raw(ix,g,800n)];
  const tied=[raw(ix,g,1000n),raw(ix-1n,g-100n,1000n)];
  const out=patch17Year5000Tie(c,ix,historical,signed,year,anchor,tied);
  const rank=chooseRank(askBowl(sauce(c,c),1,10n),2n);
  const expected=normative(out.preceding.filter.corrected)[Number(rank-1n)]!;
  if(out.correctedSelected!==expected)canonicalWrong++;
  if(out.oldSelected!==expected)oldTieWrong++;
  if(out.correctedRank!==rank||out.oldRank!==rank)rankWrong++;
  check(out.signedAnchorDay===g&&out.preceding.signedAnchorDay===g&&
   out.preceding.preceding.anchorGateDay===g&&
   out.preceding.preceding.preceding.correctedGateDay===g&&
   out.preceding.lengthTieInversions===1&&
   out.sorted.historical.length===2&&out.sorted.corrected.length===2&&
   out.sorted.historical[0]!.candidate.openGateDay===g&&
   out.sorted.corrected[0]!.candidate.openGateDay===g-100n&&
   out.sorted.tieRunCount===1&&out.sorted.movedMembers===2&&
   out.oldSelected===out.preceding.oldSelected&&
   out.oldSelected!==out.correctedSelected&&
   out.correctedSelected===out.sorted.corrected[Number(rank-1n)]&&
   out.correctedYearSelection.correctedRank===rank&&
   out.correctedYearSelection.familySize===2n&&
   out.preceding.yearSelection.correctedRank===rank&&
   out.preceding.preceding.yearSelection.correctedRank===1n&&
   out.predecessorCallCount===out.preceding.predecessorCallCount+1&&
   out.predecessorSharedWrites===BigInt(out.predecessorCallCount)*58n&&
   out.realYearSelectorCalls===3&&
   out.preceding.preceding.filter.correctedFamilySize===1&&
   out.preceding.preceding.filter.historicalFamilySize===1&&
   out.context.status==="PATCH_17_APPLIED"&&
   Object.isFrozen(out)&&Object.isFrozen(out.sorted)&&
   !owners.has(out.context)&&out.context!==out.preceding.context,
   "12 truly computed signed gate anchors and three real seal10 selectors on canonical ordering");
  owners.add(out.context);real++;if(side>0n)positive++;else negative++;
  realPred+=out.predecessorCallCount;
  realWrites+=Number(out.predecessorSharedWrites);
  realSelectorCalls+=out.realYearSelectorCalls;
  oldStableSortCalls+=out.sorted.oldHistoricalSortCalls+
    out.preceding.oldStableSortCalls;
  realGateCalls+=Number(n)*(side<0n?2:1);
 }
}
check(real===12&&positive===6&&negative===6&&canonicalWrong===0&&
 oldTieWrong===12&&rankWrong===0&&owners.size===12&&
 realPred===99&&realWrites===5742&&realSelectorCalls===36&&
 oldStableSortCalls===24&&realGateCalls===63,
 "12 real signed gate histories with 99 genuine 58-write runs");

// Explicit noncanonical source vectors only for testing the complete producer
// and 720 distinct DROP46 orders. Candidate close-gate boundaries remain injected.
const ix=1n,g=oracle.gateDay(ix),c=g+1n;
const hist=[source(F,F+1n)],signed=[{...source(F,F+1n),targetDay:F+1n}];
const anchor=[raw(ix,g,800n)],ties=[raw(ix,g,1000n),raw(0n,g-100n,1000n)];
const baseline=source(c,c);
const seen=new Set<string>(),variantOwners=new Set<object>();
let varied=0,giantSources=0,ranks=0,variants=0,variantPred=0,variantWrites=0;
let streamWrong=0,selectorWrong=0,correctWrong=0,oldWrongInVariants=0;
function verifyInjected(v:readonly bigint[],bowls:readonly bigint[],kind:"varied"|"giant"|"rank"){
 const snapshot=[...bowls];
 const out=patch17Year5000Tie(c,ix,hist,signed,{visible:v,stones:STONES,startBowls:bowls},
  anchor,ties);
 const after=applyVisibleDropsToBowls(
  [...bowls] as [bigint,bigint,bigint,bigint,bigint,bigint],v,STONES);
 const final=postStir12([...after.bowls] as [bigint,bigint,bigint,bigint,bigint,bigint]);
 const order=bowlOrderFromDrop(v[46]!);
 const stream=askBowl({bowls:final,orderAtDrop46:order},1,10n);
 const expectedRank=chooseRank(stream,2n);
 const expected=normative(out.preceding.filter.corrected)[Number(expectedRank-1n)]!;
 if(out.correctedYearSelection.preceding.firstAnswer!==stream.first||
    out.correctedYearSelection.preceding.directionStep!==stream.directionStep)streamWrong++;
 if(out.correctedRank!==expectedRank||out.preceding.oldSelectedRank!==expectedRank)
   selectorWrong++;
 if(out.correctedSelected!==expected)correctWrong++;
 if(out.oldSelected!==expected)oldWrongInVariants++;
 check(out.correctedYearSelection.preceding.preceding.preceding.preceding.finalBowls.every((x,j)=>x===final[j])&&
  out.correctedYearSelection.preceding.preceding.preceding.preceding.afterDropBowls.every((x,j)=>x===after.bowls[j])&&
  out.correctedYearSelection.preceding.preceding.preceding.preceding.orderAt46Latch.join(",")===order.join(",")&&
  out.correctedYearSelection.preceding.preceding.preceding.preceding.sharedMemoryWrites===58&&
  out.correctedYearSelection.preceding.preceding.preceding.preceding.preceding.historical.latestSource==="STIR_12"&&
  out.correctedYearSelection.correctedRank===expectedRank&&
  out.preceding.yearSelection.correctedRank===expectedRank&&
  out.preceding.preceding.yearSelection.correctedRank===1n&&
  out.oldSelected!==out.correctedSelected&&
  out.sorted.movedMembers===2&&out.sorted.tieRunCount===1&&
  out.correctedSelected===expected&&out.correctedRank===expectedRank&&
  out.predecessorCallCount===4&&out.predecessorSharedWrites===232n&&
  !variantOwners.has(out.context)&&Object.isFrozen(out.sorted)&&
  bowls.every((x,j)=>x===snapshot[j]),
  "full Stage35 real predecessor and independent test-only replay for corrected seal10");
 variants++;variantOwners.add(out.context);variantPred+=4;variantWrites+=232;
 if(kind==="rank")seen.add(out.correctedYearSelection.preceding.preceding.preceding.preceding.orderAt46Latch.join(","));
}
for(let j=0;j<64;j++){
 const v=[...baseline.visible];v[1]=j%2===0?BigInt(j*149+1):-BigInt(j*137+3);
 v[46]=j%3===0?BigInt(j*721+2):-BigInt(j*719+11);
 verifyInjected(v,baseline.startBowls,"varied");varied++;
}
const huge=(1n<<8192n)+193n;
for(const d of [huge,-huge,huge*huge,-huge*huge,0n,720n,
 1n<<16384n,-(1n<<16384n)]){
 const v=[...baseline.visible];v[1]=d;v[46]=-d+1n;
 const b=[huge+11n,-huge-13n,huge+17n,-huge-23n,huge+37n,-huge-41n];
 verifyInjected(v,b,"giant");giantSources++;
}
for(let rank=1n;rank<=720n;rank++){
 const v=[...baseline.visible];v[46]=rank;
 verifyInjected(v,baseline.startBowls,"rank");ranks++;
}
check(varied===64&&giantSources===8&&ranks===720&&variants===792&&
 variantOwners.size===792&&seen.size===720&&
 variantPred===3168&&variantWrites===183744&&
 streamWrong===0&&selectorWrong===0&&correctWrong===0&&
 oldWrongInVariants===792,
 "792 injected source histories all select corrected Year5000 candidate");
console.log("STAGE_35_PATCH_17_PROPERTIES_PASS directFamilies="+direct+
 " directOldWrong="+oldWrong+" directCorrectedWrong="+correctedWrong+
 " directRuns="+totalRuns+" directMoved="+moved+
 " directTieMembers="+tied+" directOldComparatorCalls="+oldComparator+
 " giantOpenDays="+giants+" realGates="+real+" positive="+positive+
 " negative="+negative+" canonicalWrong="+canonicalWrong+" historicWrong="+oldTieWrong+
 " rankWrong="+rankWrong+" originalGateCalls="+realGateCalls+
 " realYearSelectors="+realSelectorCalls+" historicalSortCalls="+oldStableSortCalls+
 " realPredecessors="+realPred+" realWrites="+realWrites+
 " varied="+varied+" giantSources="+giantSources+" ranks="+ranks+
 " unique="+seen.size+" variants="+variants+
 " variantPredecessors="+variantPred+" variantWrites="+variantWrites+
 " totalPredecessors="+(realPred+variantPred)+
 " totalWrites="+(realWrites+variantWrites)+
 " streamWrong="+streamWrong+" selectorWrong="+selectorWrong+
 " correctedWrong="+correctWrong+" oldWrong="+oldWrongInVariants);
