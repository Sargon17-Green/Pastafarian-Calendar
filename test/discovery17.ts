import {
  LegacyYear5000LengthOnlySorter,Discovery17Year5000TieHandler,
  discoverLegacyYear5000Tie,Patch16YearLengthGuard,
  bootstrapMonster,createMonsterContext,MonsterStageError,MonsterValidationError,
  LegacyYearMaxEligibilityAdapter,Patch14WideChoiceDispatcher,
  calendarDateSpaghetti
} from "../src/index.ts";
import {
  FOUNDATION_DAY as F,STONES,NormativeOracle,workCounts,
  buildHiddenDrops,buildVisibleDrops,initialBowls,sauce,askBowl,chooseRank
} from "./normativeOracle.ts";
function check(b:boolean,msg:string):void{if(!b)throw Error(msg);}
function rejects(f:()=>unknown,cls:typeof MonsterStageError|typeof MonsterValidationError):boolean{
 try{f();}catch(e){return e instanceof cls;}return false;
}
function source(c:bigint,t:bigint){
 const w=workCounts(c,t);
 return {visible:buildVisibleDrops(w,STONES,buildHiddenDrops(w,STONES)),
  stones:STONES,startBowls:initialBowls(w)};
}
const oracle=new NormativeOracle();
function fixture(index:bigint){
 const gate=oracle.gateDay(index),day=gate+1n;
 const dir=index<0n?-1n:1n,n=Number(index<0n?-index:index);
 const historical=Array.from({length:n},(_,j)=>source(F,F+BigInt(j+1)));
 const signed=Array.from({length:n},(_,j)=>({
  ...source(F,F+dir*BigInt(j+1)),targetDay:F+dir*BigInt(j+1)
 }));
 const year=source(day,day);
 const anchor=[{openGateIndex:index,closeGateIndex:index+6n,
  openGateDay:gate,closeGateDay:gate+800n}];
 const multi=[
  {openGateIndex:index,closeGateIndex:index+6n,
   openGateDay:gate,closeGateDay:gate+1000n},
  {openGateIndex:index-1n,closeGateIndex:index+6n,
   openGateDay:gate-100n,closeGateDay:gate+900n}
 ];
 return {index,gate,day,historical,signed,year,anchor,multi};
}
function canonicalSorted<T extends {length:bigint;candidate:{openGateDay:bigint}}>(entries:readonly T[]):T[]{
 return [...entries].sort((a,b)=>{
  if(a.length!==b.length)return a.length<b.length?-1:1;
  return a.candidate.openGateDay<b.candidate.openGateDay?-1:
    a.candidate.openGateDay>b.candidate.openGateDay?1:0;
 });
}
const old=new LegacyYear5000LengthOnlySorter(),limit=new Patch16YearLengthGuard();
const sample=fixture(1n);
const filt=limit.apply(sample.multi);
const sorted=old.oldSortStable(filt.corrected);
check(sorted.ordered.length===2&&sorted.historicalSortCalls===1&&sorted.comparatorCalls>=1&&
 sorted.ordered[0]!.candidate.openGateDay===sample.gate&&
 sorted.ordered[1]!.candidate.openGateDay===sample.gate-100n,
 "historical stable length-only comparator actually leaves inverted tie");
check(canonicalSorted(sorted.ordered)[0]!.candidate.openGateDay===sample.gate-100n,
 "canonical Year5000 independently sorts same-length years by earlier open day");
for(const v of [null,[],[{length:1n}],["bad"]] as unknown[])
 check(rejects(()=>old.oldSortStable(v as never),MonsterValidationError),
  "bad old sort input rejected");
check(rejects(()=>old.oldLengthCompare({length:"bad"} as never,
 {length:1n} as never),MonsterValidationError),"malformed legacy comparator");

let anchors=0,positive=0,negative=0,wrongSelected=0,correctedRankWrong=0;
let oldInversions=0,predecessors=0,writes=0,oldPredicateCalls=0;
const contexts=new Set<object>();
for(const idx of [1n,-1n,2n,-2n]){
 const q=fixture(idx),original=[...q.year.startBowls];
 const out=discoverLegacyYear5000Tie(q.day,idx,q.historical,q.signed,
  q.year,q.anchor,q.multi);
 const rank=chooseRank(askBowl(sauce(q.day,q.day),1,10n),2n);
 const correct=canonicalSorted(out.filter.corrected)[Number(rank-1n)]!;
 if(out.oldSelected!==correct)wrongSelected++;
 if(out.oldSelectedRank!==rank)correctedRankWrong++;
 check(out.calculationDay===q.day&&out.signedAnchorDay===q.gate&&
  out.signedAnchorIndex===idx&&
  out.provenance==="INJECTED_MULTI_OPENING_GATE_BOUNDARIES"&&
  out.preceding.anchorGateDay===q.gate&&
  out.preceding.selected.length===800n&&
  out.preceding.yearSelection.familySize===1n&&
  out.filter.historicalFamilySize===2&&out.filter.correctedFamilySize===2&&
  out.filter.oldPredicateCalls===2&&
  out.filter.corrected.every(e=>e.length===1000n)&&
  out.oldSorted[0]!.candidate.openGateDay===q.gate&&
  out.oldSorted[1]!.candidate.openGateDay===q.gate-100n&&
  out.oldSorted[Number(rank-1n)]===out.oldSelected&&
  out.lengthTieInversions===1&&out.tiedDistinctOpeningDays&&
  out.oldStableSortCalls===1&&out.realComparatorCalls>=1&&
  out.yearSelection.correctedRank===rank&&
  out.yearSelection.familySize===2n&&
  out.yearSelection.predecessorSharedWrites===58&&
  out.realYearSelectorCalls===2&&
  out.predecessorCallCount===out.preceding.predecessorCallCount+1&&
  out.predecessorSharedWrites===BigInt(out.predecessorCallCount)*58n&&
  out.context.status==="DISCOVERY_17_RECORDED"&&
  out.context.branchTrace.join(",")=== [
   "BOOTSTRAP_VALIDATE","DISCOVERY_17_FULL_PATCH16_REAL_GATE_AND_YEAR",
   "DISCOVERY_17_OLD_STABLE_LENGTH_ONLY_COMPARATOR",
   "DISCOVERY_17_REAL_SEAL10_UNCORRECTED_TIE_SELECTION"
  ].join(",")&&
  out.context.metrics.get("discovery17.calls")===1n&&
  out.context.metrics.get("discovery17.extra_legacy_predicate_calls")===2n&&
  out.context.metrics.get("discovery17.uncorrected_tie_inversions")===1n&&
  out.context.metrics.get("discovery17.predecessor_58_write_sequences")===
   BigInt(out.predecessorCallCount)&&
  !contexts.has(out.context)&&out.context!==out.preceding.context&&
  Object.isFrozen(out)&&Object.isFrozen(out.oldSorted)&&
  original.every((v,j)=>v===q.year.startBowls[j]),
  "full Stage33 predecessor and genuine old sorted wrong selection");
 contexts.add(out.context);anchors++;
 oldInversions+=out.lengthTieInversions;
 predecessors+=out.predecessorCallCount;
 writes+=Number(out.predecessorSharedWrites);
 oldPredicateCalls+=out.filter.oldPredicateCalls+
  out.preceding.realOldPredicateCalls;
 if(idx>0n)positive++;else negative++;
}
check(anchors===4&&positive===2&&negative===2&&
 wrongSelected===4&&correctedRankWrong===0&&
 oldInversions===4&&contexts.size===4&&
 predecessors===17&&writes===986&&oldPredicateCalls===12,
 "four real gate anchored wrong tie decisions and 17 predecessor calls");

let methodSpies=0,sortSpies=0,selectorSpies=0,predicateSpies=0;
const cmp=LegacyYear5000LengthOnlySorter.prototype.oldLengthCompare;
const sorter=LegacyYear5000LengthOnlySorter.prototype.oldSortStable;
const dispatch=Patch14WideChoiceDispatcher.prototype.dispatch;
const pred=LegacyYearMaxEligibilityAdapter.prototype.oldEligibleYear;
try{
 LegacyYear5000LengthOnlySorter.prototype.oldLengthCompare=function(...args){
  methodSpies++;return cmp.apply(this,args);
 };
 LegacyYear5000LengthOnlySorter.prototype.oldSortStable=function(...args){
  sortSpies++;return sorter.apply(this,args);
 };
 Patch14WideChoiceDispatcher.prototype.dispatch=function(...args){
  selectorSpies++;return dispatch.apply(this,args);
 };
 LegacyYearMaxEligibilityAdapter.prototype.oldEligibleYear=function(...args){
  predicateSpies++;return pred.apply(this,args);
 };
 discoverLegacyYear5000Tie(sample.day,1n,sample.historical,sample.signed,
  sample.year,sample.anchor,sample.multi);
 check(methodSpies>0&&sortSpies===1&&selectorSpies===3&&
  predicateSpies===3,"old comparator, old 5781 predicate, and three real selectors called");
}finally{
 LegacyYear5000LengthOnlySorter.prototype.oldLengthCompare=cmp;
 LegacyYear5000LengthOnlySorter.prototype.oldSortStable=sorter;
 Patch14WideChoiceDispatcher.prototype.dispatch=dispatch;
 LegacyYearMaxEligibilityAdapter.prototype.oldEligibleYear=pred;
}

const handler=new Discovery17Year5000TieHandler(),q=fixture(-1n);
const unready=createMonsterContext(q.day,q.day);
check(rejects(()=>handler.run(unready,-1n,q.historical,q.signed,
 q.year,q.anchor,q.multi),MonsterStageError)&&
 unready.branchTrace.length===0&&unready.metrics.size===0,"unready stage blocked");
const owner=bootstrapMonster(q.day,q.day);
const invalid=[
 [] as typeof q.multi,
 [{...q.multi[0]!,closeGateDay:q.gate+5779n},q.multi[1]!],
 [q.multi[0]!,{...q.multi[1]!,openGateDay:q.day}],
 [q.multi[0]!,{...q.multi[1]!,openGateIndex:q.multi[1]!.closeGateIndex}],
 [{...q.multi[0]!,closeGateDay:q.gate+251n},q.multi[1]!]
];
for(const entries of invalid){
 // Last 251 case still has one valid pair; only require failure for first four.
 if(entries===invalid[4])continue;
 check(rejects(()=>handler.run(owner,-1n,q.historical,q.signed,
  q.year,q.anchor,entries),MonsterValidationError)&&
  owner.status==="VALIDATED"&&owner.branchTrace.join(",")==="BOOTSTRAP_VALIDATE"&&
  owner.metrics.size===1,"preflight invalid candidates leave outer state untouched");
}

let faults=0;
for(const place of ["old_predicate","signed_predecessor","old_comparator","final_year_selector"] as const){
 const ctx=bootstrapMonster(q.day,q.day),message="DISCOVERY17_INJECT_"+place;
 let predicateCount=0,dispatchCount=0;
 try{
  if(place==="old_predicate")
   LegacyYearMaxEligibilityAdapter.prototype.oldEligibleYear=function(...args){
    predicateCount++;if(predicateCount===2)throw Error(message);
    return pred.apply(this,args);
   };
  else if(place==="old_comparator")
   LegacyYear5000LengthOnlySorter.prototype.oldLengthCompare=function():never{
    throw Error(message);
   };
  else
   Patch14WideChoiceDispatcher.prototype.dispatch=function(...args){
    dispatchCount++;
    if(place==="signed_predecessor"&&dispatchCount===2||
       place==="final_year_selector"&&dispatchCount===4)throw Error(message);
    return dispatch.apply(this,args);
   };
  try{
   handler.run(ctx,-1n,q.historical,q.signed,q.year,q.anchor,q.multi);
   throw Error("missing injected fault");
  }catch(e){
   check(e instanceof Error&&e.message===message,
    "deep stage34 fault propagated unchanged: "+place);
  }
  check(ctx.status==="VALIDATED"&&ctx.metrics.size===1&&
   ctx.branchTrace.join(",")==="BOOTSTRAP_VALIDATE",
   "outer context never partially committed on failure");
  faults++;
 }finally{
  LegacyYearMaxEligibilityAdapter.prototype.oldEligibleYear=pred;
  LegacyYear5000LengthOnlySorter.prototype.oldLengthCompare=cmp;
  Patch14WideChoiceDispatcher.prototype.dispatch=dispatch;
 }
 check(handler.run(ctx,-1n,q.historical,q.signed,q.year,q.anchor,q.multi).
   lengthTieInversions===1,"same-context deterministic retry");
}
const success=handler.run(owner,-1n,q.historical,q.signed,q.year,q.anchor,q.multi);
check(rejects(()=>handler.run(owner,-1n,q.historical,q.signed,
 q.year,q.anchor,q.multi),MonsterStageError)&&
 success.context===owner,"single-use commit");
const a=discoverLegacyYear5000Tie(q.day,-1n,q.historical,q.signed,
 q.year,q.anchor,q.multi);
const b=discoverLegacyYear5000Tie(q.day,-1n,q.historical,q.signed,
 q.year,q.anchor,q.multi);
a.context.metrics.set("private",44n);a.context.logs.push("left");
check(a.context!==b.context&&a.oldSorted!==b.oldSorted&&
 a.preceding!==b.preceding&&!b.context.metrics.has("private")&&
 b.context.logs.length===0,"reentrant state and old ledger ownership");
check(rejects(()=>calendarDateSpaghetti(F,F),MonsterStageError),"Stage54 integration still blocked");
console.log("STAGE_34_DISCOVERY_17_GUARDS_PASS anchors="+anchors+
 " positive="+positive+" negative="+negative+" wrongSelections="+wrongSelected+
 " rankWrong="+correctedRankWrong+" tieInversions="+oldInversions+
 " realPredecessors="+predecessors+" sharedWrites="+writes+
 " originalPredicateCalls="+oldPredicateCalls+" comparatorSpy="+methodSpies+
 " stableSortSpy="+sortSpies+" selectorSpy="+selectorSpies+
 " predicateSpy="+predicateSpies+" faults="+faults);
