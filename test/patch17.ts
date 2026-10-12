import {
  Patch17EqualLengthRunSorter,Patch17Year5000TieHandler,patch17Year5000Tie,
  LegacyYear5000LengthOnlySorter,LegacyYearMaxEligibilityAdapter,
  Patch14WideChoiceDispatcher,
  Patch16YearLengthGuard,bootstrapMonster,createMonsterContext,
  MonsterStageError,MonsterValidationError,calendarDateSpaghetti
} from "../src/index.ts";
import {
  FOUNDATION_DAY as F,STONES,NormativeOracle,workCounts,
  buildHiddenDrops,buildVisibleDrops,initialBowls,sauce,askBowl,chooseRank
} from "./normativeOracle.ts";
function check(b:boolean,m:string):void{if(!b)throw Error(m);}
function rejected(f:()=>unknown,t:typeof MonsterStageError|typeof MonsterValidationError):boolean{
 try{f();}catch(e){return e instanceof t;}return false;
}
function source(c:bigint,t:bigint){
 const w=workCounts(c,t);
 return {visible:buildVisibleDrops(w,STONES,buildHiddenDrops(w,STONES)),
  stones:STONES,startBowls:initialBowls(w)};
}
const oracle=new NormativeOracle();
function fixture(index:bigint){
 const g=oracle.gateDay(index),day=g+1n;
 const sign=index<0n?-1n:1n,n=Number(index<0n?-index:index);
 const historical=Array.from({length:n},(_,i)=>source(F,F+BigInt(i+1)));
 const signed=Array.from({length:n},(_,i)=>({
  ...source(F,F+sign*BigInt(i+1)),targetDay:F+sign*BigInt(i+1)
 }));
 return {index,gate:g,day,historical,signed,year:source(day,day),
  anchor:[{openGateIndex:index,closeGateIndex:index+6n,
   openGateDay:g,closeGateDay:g+800n}],
  multi:[
   {openGateIndex:index,closeGateIndex:index+6n,
    openGateDay:g,closeGateDay:g+1000n},
   {openGateIndex:index-1n,closeGateIndex:index+6n,
    openGateDay:g-100n,closeGateDay:g+900n}
  ]};
}
function canonical<T extends {length:bigint;candidate:{openGateDay:bigint}}>(items:readonly T[]):T[]{
 return [...items].sort((a,b)=>{
  if(a.length!==b.length)return a.length<b.length?-1:1;
  return a.candidate.openGateDay<b.candidate.openGateDay?-1:
    a.candidate.openGateDay>b.candidate.openGateDay?1:0;
 });
}
function pair(index:bigint,start:bigint,length:bigint){
 return {openGateIndex:index,closeGateIndex:index+6n,
  openGateDay:start,closeGateDay:start+length};
}
const lengthLimit=new Patch16YearLengthGuard();
const runSorter=new Patch17EqualLengthRunSorter();
const many=[
 pair(1n,F+50n,400n),pair(2n,F+30n,300n),
 pair(3n,F-10n,400n),pair(4n,F-50n,300n),
 pair(5n,F+100n,500n),pair(6n,F-10n,400n),
 pair(7n,F-10n,400n)
];
const accepted=lengthLimit.apply(many);
const sorted=runSorter.sortAfterHistorical(accepted.corrected);
const normative=canonical(accepted.corrected);
check(sorted.historical.map(x=>x.originalPosition).join(",")==="1,3,0,2,5,6,4"&&
 sorted.corrected.map(x=>x.originalPosition).join(",")==="3,1,2,5,6,0,4"&&
 sorted.corrected.every((x,j)=>x===normative[j])&&
 sorted.tieRunCount===2&&sorted.tiedRuns.length===2&&
 sorted.tiedRuns[0]!.start===0&&sorted.tiedRuns[0]!.exclusiveEnd===2&&
 sorted.tiedRuns[1]!.start===2&&sorted.tiedRuns[1]!.exclusiveEnd===6&&
 sorted.tiedRuns[0]!.length===300n&&sorted.tiedRuns[1]!.length===400n&&
 sorted.tiedRuns[0]!.movedMembers===2&&
 sorted.tiedRuns[1]!.movedMembers===4&&
 sorted.movedMembers===6&&sorted.tieMemberCount===6&&
 sorted.runSortCalls===2&&sorted.oldHistoricalSortCalls===1&&
 sorted.oldComparatorCalls>=6&&sorted.openedDayTieComparisons>=4&&
 Object.isFrozen(sorted)&&Object.isFrozen(sorted.corrected)&&
 Object.isFrozen(sorted.historical)&&Object.isFrozen(sorted.tiedRuns),
 "only the 300/400 tied runs rearranged, equal opening dates remain stably ordered");
const untied=runSorter.sortAfterHistorical(lengthLimit.apply([
 pair(1n,F,1000n),pair(2n,F+1n,800n),
 pair(3n,F+2n,900n)
]).corrected);
check(untied.tieRunCount===0&&untied.movedMembers===0&&
 untied.corrected.every((x,j)=>x===untied.historical[j])&&
 untied.corrected.map(e=>e.length).join(",")==="800,900,1000",
 "unequal lengths unchanged by tie-run repair");
const sameGate=runSorter.sortAfterHistorical(lengthLimit.apply([
 pair(1n,F,1000n),pair(2n,F,1000n),pair(3n,F,1000n)
]).corrected);
check(sameGate.tieRunCount===1&&sameGate.movedMembers===0&&
 sameGate.corrected.map(e=>e.originalPosition).join(",")==="0,1,2",
 "equal opening days preserve stable original-position order");
for(const invalid of [null,[],[{length:1n}],["broken"]] as unknown[]){
 check(rejected(()=>runSorter.sortAfterHistorical(invalid as never),MonsterValidationError),
  "malformed input rejected by original stable comparator");
}
const huge=1n<<16384n;
const hugeSort=runSorter.sortAfterHistorical(lengthLimit.apply([
 pair(1n,huge,1000n),pair(2n,-huge,1000n)
]).corrected);
check(hugeSort.corrected[0]!.candidate.openGateDay===-huge&&
 hugeSort.historical[0]!.candidate.openGateDay===huge,
 "arbitrary-width opening-gate comparison is exact");

let actualOldComparator=0,actualOldSort=0;
const cmp=LegacyYear5000LengthOnlySorter.prototype.oldLengthCompare;
const oldSort=LegacyYear5000LengthOnlySorter.prototype.oldSortStable;
try{
 LegacyYear5000LengthOnlySorter.prototype.oldLengthCompare=function(...args){
  actualOldComparator++;return cmp.apply(this,args);
 };
 LegacyYear5000LengthOnlySorter.prototype.oldSortStable=function(...args){
  actualOldSort++;return oldSort.apply(this,args);
 };
 runSorter.sortAfterHistorical(accepted.corrected);
 check(actualOldComparator>=6&&actualOldSort===1,
  "Stage35 explicitly invokes unchanged old historical comparator and sort");
}finally{
 LegacyYear5000LengthOnlySorter.prototype.oldLengthCompare=cmp;
 LegacyYear5000LengthOnlySorter.prototype.oldSortStable=oldSort;
}

const contexts=new Set<object>();
let signed=0,positive=0,negative=0,correctWrong=0,oldWrong=0,rankWrong=0;
let fullCalls=0,fullWrites=0,priorCalls=0,priorComparatorCalls=0;
for(const index of [1n,-1n,2n,-2n]){
 const f=fixture(index),original=[...f.year.startBowls];
 const out=patch17Year5000Tie(f.day,index,f.historical,f.signed,f.year,f.anchor,f.multi);
 const rank=chooseRank(askBowl(sauce(f.day,f.day),1,10n),2n);
 const desired=canonical(out.preceding.filter.corrected)[Number(rank-1n)]!;
 if(out.correctedSelected!==desired)correctWrong++;
 if(out.oldSelected===desired)oldWrong++;
 if(out.correctedRank!==rank||out.oldRank!==rank)rankWrong++;
 check(out.signedAnchorDay===f.gate&&
  out.preceding.signedAnchorDay===f.gate&&
  out.preceding.preceding.anchorGateDay===f.gate&&
  out.candidateProvenance==="INJECTED_MULTI_OPENING_GATE_BOUNDARIES"&&
  out.sorted.tieRunCount===1&&out.sorted.tieMemberCount===2&&
  out.sorted.movedMembers===2&&out.sorted.runSortCalls===1&&
  out.sorted.historical[0]===out.preceding.oldSorted[0]&&
  out.sorted.historical[1]===out.preceding.oldSorted[1]&&
  out.sorted.corrected[0]!.candidate.openGateDay===f.gate-100n&&
  out.sorted.corrected[1]!.candidate.openGateDay===f.gate&&
  out.oldSelected===out.preceding.oldSelected&&
  out.oldSelected!==out.correctedSelected&&
  out.legacyTieMismatch===true&&
  out.correctedSelected===out.sorted.corrected[Number(rank-1n)]&&
  out.correctedRank===out.oldRank&&out.correctedRank===rank&&
  out.correctedYearSelection.correctedRank===rank&&
  out.correctedYearSelection.familySize===2n&&
  out.correctedYearSelection.predecessorSharedWrites===58&&
  out.realYearSelectorCalls===3&&
  out.predecessorCallCount===out.preceding.predecessorCallCount+1&&
  out.predecessorSharedWrites===BigInt(out.predecessorCallCount)*58n&&
  out.context.status==="PATCH_17_APPLIED"&&
  out.context.branchTrace.join(",")=== [
   "BOOTSTRAP_VALIDATE","PATCH_17_FULL_DISCOVERY17_HISTORICAL_PREDECESSOR",
   "PATCH_17_OLD_STABLE_LENGTH_ONLY_SORT_ACTUALLY_CALLED",
   "PATCH_17_ONLY_EQUAL_LENGTH_RUNS_SORT_BY_EARLIER_GATE",
   "PATCH_17_REAL_SEAL10_CORRECTED_ORDER"
  ].join(",")&&
  out.context.metrics.get("patch17.calls")===1n&&
  out.context.metrics.get("patch17.equal_length_runs")===1n&&
  out.context.metrics.get("patch17.changed_positions")===2n&&
  out.context.metrics.get("patch17.legacy_mismatches")===1n&&
  out.context.metrics.get("patch17.predecessor_58_write_sequences")===
   BigInt(out.predecessorCallCount)&&
  !contexts.has(out.context)&&
  out.context!==out.preceding.context&&
  Object.isFrozen(out)&&Object.isFrozen(out.sorted)&&
  original.every((v,j)=>v===f.year.startBowls[j]),
  "real Stage34 history, physical corrected seal10 and canonical tie-run selection");
 contexts.add(out.context);signed++;if(index>0n)positive++;else negative++;
 fullCalls+=out.predecessorCallCount;
 fullWrites+=Number(out.predecessorSharedWrites);
 priorCalls+=out.actualStage34PredecessorCalls;
 priorComparatorCalls+=out.preceding.realComparatorCalls;
}
check(signed===4&&positive===2&&negative===2&&correctWrong===0&&
 oldWrong===0&&rankWrong===0&&contexts.size===4&&
 priorCalls===17&&fullCalls===21&&fullWrites===1218&&priorComparatorCalls>=4,
 "four real signed gate anchors, zero corrected differences and 21 real predecessors");

const dispatch=Patch14WideChoiceDispatcher.prototype.dispatch;
const pred=LegacyYearMaxEligibilityAdapter.prototype.oldEligibleYear;
const f=fixture(-1n);
let realOldSort=0,realOldComparisons=0,realSelectionCalls=0,realPredicateCalls=0;
try{
 LegacyYear5000LengthOnlySorter.prototype.oldSortStable=function(...args){
  realOldSort++;return oldSort.apply(this,args);
 };
 LegacyYear5000LengthOnlySorter.prototype.oldLengthCompare=function(...args){
  realOldComparisons++;return cmp.apply(this,args);
 };
 Patch14WideChoiceDispatcher.prototype.dispatch=function(...args){
  realSelectionCalls++;return dispatch.apply(this,args);
 };
 LegacyYearMaxEligibilityAdapter.prototype.oldEligibleYear=function(...args){
  realPredicateCalls++;return pred.apply(this,args);
 };
 patch17Year5000Tie(f.day,-1n,f.historical,f.signed,f.year,f.anchor,f.multi);
 check(realOldSort===2&&realOldComparisons>=2&&
  realSelectionCalls===4&&realPredicateCalls===3,
  "Stage34 old + Stage35 additional historical sorter and four actual full selectors");
}finally{
 LegacyYear5000LengthOnlySorter.prototype.oldSortStable=oldSort;
 LegacyYear5000LengthOnlySorter.prototype.oldLengthCompare=cmp;
 Patch14WideChoiceDispatcher.prototype.dispatch=dispatch;
 LegacyYearMaxEligibilityAdapter.prototype.oldEligibleYear=pred;
}

const handler=new Patch17Year5000TieHandler(),unready=createMonsterContext(f.day,f.day);
check(rejected(()=>handler.run(unready,-1n,f.historical,f.signed,
 f.year,f.anchor,f.multi),MonsterStageError)&&
 unready.branchTrace.length===0&&unready.metrics.size===0,
 "non-ready outer context blocked");
const ready=bootstrapMonster(f.day,f.day);
check(rejected(()=>handler.run(ready,0n,f.historical,f.signed,
 f.year,f.anchor,f.multi),MonsterValidationError)&&
 ready.status==="VALIDATED"&&
 ready.branchTrace.join(",")==="BOOTSTRAP_VALIDATE",
 "invalid gate index blocked without mutation");
let failures=0;
for(const where of ["old_predicate","signed_gate","old_sort","second_old_sort","corrected_year"] as const){
 const owner=bootstrapMonster(f.day,f.day);
 const mark="STAGE35_INJECT_"+where;
 let calls=0;
 try{
  if(where==="old_predicate")
   LegacyYearMaxEligibilityAdapter.prototype.oldEligibleYear=function(...args){
    calls++;if(calls===2)throw Error(mark);
    return pred.apply(this,args);
   };
  else if(where==="old_sort"||where==="second_old_sort")
   LegacyYear5000LengthOnlySorter.prototype.oldSortStable=function(...args){
    calls++;if(calls===(where==="old_sort"?1:2))throw Error(mark);
    return oldSort.apply(this,args);
   };
  else
   Patch14WideChoiceDispatcher.prototype.dispatch=function(...args){
    calls++;
    if(calls===(where==="signed_gate"?2:4))throw Error(mark);
    return dispatch.apply(this,args);
   };
  try{
   handler.run(owner,-1n,f.historical,f.signed,f.year,f.anchor,f.multi);
   throw Error("fault not injected");
  }catch(e){
   check(e instanceof Error&&e.message===mark,"fault propagated at requested depth");
  }
  check(owner.status==="VALIDATED"&&owner.metrics.size===1&&
   owner.branchTrace.join(",")==="BOOTSTRAP_VALIDATE",
   "no partial semantic writes on thrown old/helper/selector path");
  failures++;
 }finally{
  LegacyYearMaxEligibilityAdapter.prototype.oldEligibleYear=pred;
  LegacyYear5000LengthOnlySorter.prototype.oldSortStable=oldSort;
  Patch14WideChoiceDispatcher.prototype.dispatch=dispatch;
 }
 const retried=handler.run(owner,-1n,f.historical,f.signed,f.year,f.anchor,f.multi);
 check(retried.correctedSelected.candidate.openGateDay===
  (retried.correctedRank===1n?f.gate-100n:f.gate)&&
  retried.legacyTieMismatch&&retried.predecessorCallCount===5,
  "same ready owner deterministically recovers complete corrected result");
}
const committed=handler.run(ready,-1n,f.historical,f.signed,f.year,f.anchor,f.multi);
check(rejected(()=>handler.run(ready,-1n,f.historical,f.signed,
 f.year,f.anchor,f.multi),MonsterStageError)&&
 committed.context===ready,"single-use caller owner");
const a=patch17Year5000Tie(f.day,-1n,f.historical,f.signed,f.year,f.anchor,f.multi);
const b=patch17Year5000Tie(f.day,-1n,f.historical,f.signed,f.year,f.anchor,f.multi);
a.context.metrics.set("private",24n);a.context.logs.push("डावा");
check(a.context!==b.context&&a.preceding!==b.preceding&&
 a.sorted!==b.sorted&&!b.context.metrics.has("private")&&b.context.logs.length===0,
 "reentrant independent audit and ordered families");
check(rejected(()=>calendarDateSpaghetti(F,F),MonsterStageError),
 "Stage54 calendar integration remains disabled");
console.log("STAGE_35_PATCH_17_GUARDS_PASS multiRuns=2 tiedMembers=6"+
 " moved=6 oldSortSpy="+actualOldSort+" oldComparatorSpy="+actualOldComparator+
 " signedAnchors="+signed+" positive="+positive+" negative="+negative+
 " correctedWrong="+correctWrong+" oldWrong="+oldWrong+" rankWrong="+rankWrong+
 " precedingCalls="+priorCalls+" fullCalls="+fullCalls+
 " sharedWrites="+fullWrites+" historicalSortCalls="+realOldSort+
 " historicalComparatorCalls="+realOldComparisons+
 " actualSelectors="+realSelectionCalls+" originalPredicateCalls="+realPredicateCalls+
 " faultCases="+failures);
