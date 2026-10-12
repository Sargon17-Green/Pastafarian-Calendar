import {
 LegacyYear5000LengthOnlySorter,Patch16YearLengthGuard,
 discoverLegacyYear5000Tie
} from "../src/index.ts";
import {
 FOUNDATION_DAY as F,STONES,NormativeOracle,workCounts,
 buildHiddenDrops,buildVisibleDrops,initialBowls,sauce,askBowl,chooseRank,
 applyVisibleDropsToBowls,postStir12,bowlOrderFromDrop
} from "./normativeOracle.ts";
function check(x:boolean,why:string):void{if(!x)throw Error(why);}
function source(c:bigint,t:bigint){
 const w=workCounts(c,t);return {
  visible:buildVisibleDrops(w,STONES,buildHiddenDrops(w,STONES)),
  stones:STONES,startBowls:initialBowls(w)
 };
}
function normalized<T extends {length:bigint;candidate:{openGateDay:bigint}}>(v:readonly T[]):T[]{
 return [...v].sort((a,b)=>{
  if(a.length!==b.length)return a.length<b.length?-1:1;
  return a.candidate.openGateDay<b.candidate.openGateDay?-1:
    a.candidate.openGateDay>b.candidate.openGateDay?1:0;
 });
}
function candidates(index:bigint,g:bigint,len:bigint=1000n){
 return [
  {openGateIndex:index,closeGateIndex:index+6n,
   openGateDay:g,closeGateDay:g+len},
  {openGateIndex:index-1n,closeGateIndex:index+6n,
   openGateDay:g-100n,closeGateDay:g-100n+len}
 ];
}
const guard=new Patch16YearLengthGuard(),old=new LegacyYear5000LengthOnlySorter();
let tieFamilies=0,tieWrong=0,cmpCalls=0;
for(let j=0;j<256;j++){
 const base=252n+BigInt(j);
 const entries=[
  ...candidates(1n,F,base),
  {openGateIndex:5n,closeGateIndex:12n,
   openGateDay:F-500n,closeGateDay:F-500n+base+1n}
 ];
 const filtered=guard.apply(entries);
 const observed=old.oldSortStable(filtered.corrected);
 const correct=normalized(filtered.corrected);
 if(observed.ordered[0]!==correct[0]||observed.ordered[1]!==correct[1])tieWrong++;
 check(observed.ordered.length===3&&observed.ordered[0]!.candidate.openGateDay===F&&
   observed.ordered[1]!.candidate.openGateDay===F-100n&&
   correct[0]!.candidate.openGateDay===F-100n&&
   correct[1]!.candidate.openGateDay===F&&
   observed.ordered[2]!.length===base+1n&&
   observed.comparatorCalls>=2&&
   observed.historicalSortCalls===1&&
   filtered.historicalFamilySize===3&&filtered.correctedFamilySize===3,
   "real old length-only sort leaves 256 equal-length reversed tie families");
 tieFamilies++;cmpCalls+=observed.comparatorCalls;
}
check(tieFamilies===256&&tieWrong===256&&cmpCalls>=512,
 "256 witnessed real old comparator calls and opposite normative order");

const oracle=new NormativeOracle(),contexts=new Set<object>();
let real=0,positive=0,negative=0,rankWrong=0,sortWrong=0;
let precedingGateCalls=0,realYearSelectors=0,predecessors=0,writes=0;
for(const side of [1n,-1n] as const){
 for(let n=1n;n<=6n;n++){
  const index=side*n,g=oracle.gateDay(index),c=g+1n;
  const hist=Array.from({length:Number(n)},(_,j)=>source(F,F+BigInt(j+1)));
  const signed=Array.from({length:Number(n)},(_,j)=>({
    ...source(F,F+side*BigInt(j+1)),targetDay:F+side*BigInt(j+1)
  }));
  const year=source(c,c);
  const anchor=[{openGateIndex:index,closeGateIndex:index+6n,
   openGateDay:g,closeGateDay:g+800n}];
  const pairs=candidates(index,g);
  const out=discoverLegacyYear5000Tie(c,index,hist,signed,year,anchor,pairs);
  const rank=chooseRank(askBowl(sauce(c,c),1,10n),2n);
  const right=normalized(out.filter.corrected)[Number(rank-1n)]!;
  if(out.oldSelectedRank!==rank)rankWrong++;
  if(out.oldSelected!==right)sortWrong++;
  check(out.signedAnchorDay===g&&out.preceding.anchorGateDay===g&&
    out.preceding.preceding.correctedGateDay===g&&
    out.filter.corrected.length===2&&
    out.filter.historical.kept.length===2&&
    out.filter.oldPredicateCalls===2&&
    out.filter.corrected.every(e=>e.length===1000n)&&
    out.oldSorted[0]!.candidate.openGateDay===g&&
    out.oldSorted[1]!.candidate.openGateDay===g-100n&&
    out.tiedDistinctOpeningDays&&out.lengthTieInversions===1&&
    out.oldSelected===out.oldSorted[Number(rank-1n)]&&
    out.yearSelection.correctedRank===rank&&
    out.yearSelection.familySize===2n&&
    out.preceding.yearSelection.familySize===1n&&
    out.predecessorCallCount===out.preceding.predecessorCallCount+1&&
    out.predecessorSharedWrites===BigInt(out.predecessorCallCount)*58n&&
    out.realYearSelectorCalls===2&&
    out.preceding.preceding.historicalMismatch===(side<0n)&&
    out.context.status==="DISCOVERY_17_RECORDED"&&
    !contexts.has(out.context)&&out.context!==out.preceding.context,
    "12 genuine signed anchors and two real selectors, old Year5000 tie remains wrong");
  contexts.add(out.context);
  precedingGateCalls+=Number(n)*(side<0n?2:1);
  realYearSelectors+=2;
  predecessors+=out.predecessorCallCount;
  writes+=Number(out.predecessorSharedWrites);
  real++;if(side>0n)positive++;else negative++;
 }
}
check(real===12&&positive===6&&negative===6&&
 rankWrong===0&&sortWrong===12&&contexts.size===12&&
 precedingGateCalls===63&&realYearSelectors===24&&
 predecessors===87&&writes===5046,"12 true gate anchor routes and 87 full 58-write predecessors");

// The multi-opening close gates below are specifically synthetic; the
// genuine Stage31 signed opening gate and all sauce-dependent paths are real.
const idx=1n,g=oracle.gateDay(idx),c=g+1n;
const hist=[source(F,F+1n)],signed=[{...source(F,F+1n),targetDay:F+1n}];
const anchor=[{openGateIndex:1n,closeGateIndex:7n,
 openGateDay:g,closeGateDay:g+800n}];
const multi=candidates(idx,g),baseline=source(c,c);
const seen=new Set<string>(),variantOwners=new Set<object>();
let varied=0,giants=0,ranks=0,variants=0,variantCalls=0,variantWrites=0;
let streamWrong=0,selectionWrong=0,wrongTieSeen=0;
function verifyInjected(v:readonly bigint[],bowls:readonly bigint[],kind:"varied"|"giant"|"rank"){
 const before=[...bowls];
 const out=discoverLegacyYear5000Tie(c,idx,hist,signed,
  {visible:v,stones:STONES,startBowls:bowls},anchor,multi);
 const after=applyVisibleDropsToBowls(
  [...bowls] as [bigint,bigint,bigint,bigint,bigint,bigint],v,STONES);
 const baked=postStir12(
  [...after.bowls] as [bigint,bigint,bigint,bigint,bigint,bigint]);
 const order=bowlOrderFromDrop(v[46]!);
 const stream=askBowl({bowls:baked,orderAtDrop46:order},1,10n);
 const expectedRank=chooseRank(stream,2n);
 const corrected=normalized(out.filter.corrected)[Number(expectedRank-1n)]!;
 if(out.yearSelection.preceding.firstAnswer!==stream.first||
    out.yearSelection.preceding.directionStep!==stream.directionStep)streamWrong++;
 if(out.oldSelectedRank!==expectedRank)selectionWrong++;
 if(out.oldSelected!==corrected)wrongTieSeen++;
 check(out.yearSelection.preceding.preceding.preceding.preceding.finalBowls.every((x,j)=>x===baked[j])&&
  out.yearSelection.preceding.preceding.preceding.preceding.afterDropBowls.every((x,j)=>x===after.bowls[j])&&
  out.yearSelection.preceding.preceding.preceding.preceding.orderAt46Latch.join(",")===order.join(",")&&
  out.yearSelection.preceding.preceding.preceding.preceding.sharedMemoryWrites===58&&
  out.yearSelection.preceding.preceding.preceding.preceding.preceding.historical.latestSource==="STIR_12"&&
  out.preceding.yearSelection.correctedRank===1n&&
  out.preceding.yearSelection.familySize===1n&&
  out.oldSorted[0]!.candidate.openGateDay===g&&
  out.oldSorted[1]!.candidate.openGateDay===g-100n&&
  out.lengthTieInversions===1&&
  out.yearSelection.correctedRank===expectedRank&&
  out.oldSelected===out.oldSorted[Number(expectedRank-1n)]&&
  out.predecessorCallCount===3&&out.predecessorSharedWrites===174n&&
  !variantOwners.has(out.context)&&Object.isFrozen(out.oldSorted)&&
  bowls.every((x,j)=>x===before[j]),
  "real entire 58-write history and independent seal10 with synthetic equal-length reverse tie");
 variantOwners.add(out.context);variants++;variantCalls+=3;variantWrites+=174;
 if(kind==="rank")
  seen.add(out.yearSelection.preceding.preceding.preceding.preceding.orderAt46Latch.join(","));
}
for(let j=0;j<64;j++){
 const v=[...baseline.visible];
 v[1]=j%2===0?BigInt(j*149+1):-BigInt(j*137+3);
 v[46]=j%3===0?BigInt(j*721+2):-BigInt(j*719+11);
 verifyInjected(v,baseline.startBowls,"varied");varied++;
}
const huge=(1n<<8192n)+193n;
for(const d of [huge,-huge,huge*huge,-huge*huge,0n,720n,
 1n<<16384n,-(1n<<16384n)]){
 const v=[...baseline.visible];v[1]=d;v[46]=-d+1n;
 const b=[huge+11n,-huge-13n,huge+17n,-huge-23n,huge+37n,-huge-41n];
 verifyInjected(v,b,"giant");giants++;
}
for(let rank=1n;rank<=720n;rank++){
 const v=[...baseline.visible];v[46]=rank;
 verifyInjected(v,baseline.startBowls,"rank");ranks++;
}
check(varied===64&&giants===8&&ranks===720&&variants===792&&
 variantOwners.size===792&&seen.size===720&&variantCalls===2376&&
 variantWrites===137808&&streamWrong===0&&selectionWrong===0&&
 wrongTieSeen===792,"792 injected source histories, all maintain same wrong tie despite correct independent rank");
console.log("STAGE_34_DISCOVERY_17_PROPERTIES_PASS directFamilies="+tieFamilies+
 " directOldWrong="+tieWrong+" directComparatorCalls="+cmpCalls+
 " realGates="+real+" positive="+positive+" negative="+negative+
 " realRankWrong="+rankWrong+" realTieWrong="+sortWrong+
 " originalGateCalls="+precedingGateCalls+" realYearSelectors="+realYearSelectors+
 " realPredecessors="+predecessors+" realWrites="+writes+
 " varied="+varied+" giants="+giants+" ranks="+ranks+
 " unique="+seen.size+" variants="+variants+
 " variantPredecessors="+variantCalls+" variantWrites="+variantWrites+
 " totalPredecessors="+(predecessors+variantCalls)+
 " totalWrites="+(writes+variantWrites)+
 " streamWrong="+streamWrong+" selectorWrong="+selectionWrong+
 " wrongTieWitnesses="+wrongTieSeen);
