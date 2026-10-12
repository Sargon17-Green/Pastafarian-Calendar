import {
  REAL_YEAR_MAX_PATCH,LEGACY_YEAR_MAX,
  LegacyYearMaxEligibilityAdapter,LegacyYearMaxCandidateFilter,
  Patch16YearLengthGuard,Patch16YearMaxHandler,patch16YearMax,
  bootstrapMonster,createMonsterContext,
  Patch14WideChoiceDispatcher,Patch15SignedGateQuestionAdapter,
  MonsterValidationError,MonsterStageError,calendarDateSpaghetti
} from "../src/index.ts";
import {
  FOUNDATION_DAY as F,YEAR_MIN_DAYS,YEAR_MAX_DAYS,
  STONES,NormativeOracle,workCounts,buildHiddenDrops,buildVisibleDrops,
  initialBowls,sauce,askBowl,chooseRank
} from "./normativeOracle.ts";
function check(ok:boolean,why:string):void{if(!ok)throw Error(why);}
function rejects(fn:()=>unknown,cls:typeof MonsterValidationError|typeof MonsterStageError):boolean{
 try{fn();}catch(e){return e instanceof cls;}return false;
}
function source(c:bigint,t:bigint){
 const counts=workCounts(c,t);
 return {visible:buildVisibleDrops(counts,STONES,buildHiddenDrops(counts,STONES)),
  stones:STONES,startBowls:initialBowls(counts)};
}
const oracle=new NormativeOracle();
function fixture(idx:bigint){
 const g=oracle.gateDay(idx),c=g+1n,n=Number(idx<0n?-idx:idx),dir=idx<0n?-1n:1n;
 return {idx,g,c,
  historical:Array.from({length:n},(_,i)=>source(F,F+BigInt(i+1))),
  signed:Array.from({length:n},(_,i)=>({
    ...source(F,F+dir*BigInt(i+1)),targetDay:F+dir*BigInt(i+1)
  })),
  year:source(c,c)};
}
function candidates(idx:bigint,day:bigint,lengths:readonly bigint[]){
 return lengths.map((length,i)=>({
  openGateIndex:idx,closeGateIndex:idx+BigInt(i+6),
  openGateDay:day,closeGateDay:day+length
 }));
}
check(REAL_YEAR_MAX_PATCH===YEAR_MAX_DAYS&&REAL_YEAR_MAX_PATCH===5778n&&
 LEGACY_YEAR_MAX===5781n&&YEAR_MIN_DAYS===252n,"actual canonical vs original scar");
const legacy=new LegacyYearMaxEligibilityAdapter(),historic=new LegacyYearMaxCandidateFilter();
const patched=new Patch16YearLengthGuard();
let edges=0;
for(const [length,oldOk,newOk] of [
 [251n,false,false],[252n,true,true],[5777n,true,true],
 [5778n,true,true],[5779n,true,false],[5780n,true,false],
 [5781n,true,false],[5782n,false,false]
] as const){
 const s=candidates(1n,F,[length])[0]!;
 const filter=patched.apply([s]);
 check(filter.historical.kept.length===(oldOk?1:0)&&
    filter.correctedFamilySize===(newOk?1:0)&&
    filter.excludedLong.length===(oldOk&&!newOk?1:0)&&
    filter.oldPredicateCalls===1&&filter.appliedCeiling===5778n&&
    filter.historicalSortCalls===1&&filter.correctedSortCalls===1&&
    legacy.oldEligibleYear(length,6n)===oldOk,
    "each 252,5778,5779,5780,5781,5782 exact boundary");
 edges++;
}
for(const L of [252n,5778n,5779n,5781n,5782n])
 check(!legacy.oldEligibleYear(L,5n)&&
  patched.apply([{
   openGateIndex:1n,closeGateIndex:6n,openGateDay:F,closeGateDay:F+L
  }]).correctedFamilySize===0,"five gates not enough even for valid length");
const g=patched.apply(candidates(1n,F,
 [5781n,251n,5780n,5782n,5779n,5778n,252n]));
check(g.historical.kept.map(e=>e.length).join(",")==="252,5778,5779,5780,5781"&&
 g.historical.rejected.map(e=>e.length).join(",")==="251,5782"&&
 g.corrected.map(e=>e.length).join(",")==="252,5778"&&
 g.excludedLong.map(e=>e.length).join(",")==="5781,5780,5779"&&
 g.historicalFamilySize===5&&g.correctedFamilySize===2&&
 Object.isFrozen(g)&&Object.isFrozen(g.historical)&&
 Object.isFrozen(g.corrected)&&Object.isFrozen(g.excludedLong)&&
 g.corrected.every(e=>Object.isFrozen(e)&&Object.isFrozen(e.candidate)),
 "old predicate invoked and old ledger retained; new correct sorted family only");
const tied=patched.apply(candidates(1n,F,[5778n,252n,5778n,5781n]));
check(tied.corrected.map(x=>x.originalPosition).join(",")==="1,0,2"&&
 tied.historical.kept.map(x=>x.originalPosition).join(",")==="1,0,2,3",
 "stable length-only ties unchanged; do NOT implement Stage35");
let oldMethodCalls=0;
const oldFn=LegacyYearMaxEligibilityAdapter.prototype.oldEligibleYear;
try{
 LegacyYearMaxEligibilityAdapter.prototype.oldEligibleYear=function(...args){
  oldMethodCalls++;return oldFn.apply(this,args);
 };
 const result=patched.apply(candidates(1n,F,[5778n,5779n,5780n,5781n,5782n]));
 check(oldMethodCalls===5&&result.oldPredicateCalls===5&&
  result.correctedFamilySize===1&&result.historicalFamilySize===4,
  "actual original adapter called once per candidate, even rejected 5782");
}finally{LegacyYearMaxEligibilityAdapter.prototype.oldEligibleYear=oldFn;}

const contexts=new Set<object>();
let anchors=0,short=0,negative=0,oldKept=0,filteredLong=0,wrong=0;
let preds=0,writes=0,originalSelectedWrong=0;
for(const idx of [1n,-1n,2n,-2n]){
 const q=fixture(idx),list=candidates(idx,q.g,
  [5781n,251n,5780n,5782n,5779n,5778n,252n]);
 const bowls=[...q.year.startBowls];
 const res=patch16YearMax(q.c,idx,q.historical,q.signed,q.year,list);
 const expected=chooseRank(askBowl(sauce(q.c,q.c),1,10n),2n);
 if(res.selectedRank!==expected)wrong++;
 if(res.selected.length>5778n)originalSelectedWrong++;
 check(res.calculationDay===q.c&&res.anchorGateDay===q.g&&
  res.preceding.correctedGateDay===q.g&&
  res.yearMax===5778n&&res.originalOldYearMax===5781n&&
  res.candidateSource==="INJECTED_CANDIDATE_BOUNDARIES"&&
  res.filter.source==="INJECTED_CANDIDATE_BOUNDARIES"&&
  res.filter.historical.kept.length===5&&
  res.filter.correctedFamilySize===2&&
  res.filter.excludedLong.length===3&&
  res.filter.corrected.map(e=>e.length).join(",")==="252,5778"&&
  res.filter.historical.acceptedLongLengths.join(",")==="5779,5780,5781"&&
  res.selected===res.filter.corrected[Number(expected-1n)]&&
  res.selectedRank===expected&&res.yearSelection.correctedRank===expected&&
  res.yearSelection.familySize===2n&&
  res.yearSelection.predecessorSharedWrites===58&&
  res.realYearSelectorCalls===1&&res.realOldPredicateCalls===7&&
  res.predecessorCallCount===res.preceding.totalPredecessorCalls+1&&
  res.predecessorSharedWrites===BigInt(res.predecessorCallCount)*58n&&
  res.context.status==="PATCH_16_APPLIED"&&
  res.context.branchTrace.join(",")=== [
   "BOOTSTRAP_VALIDATE","PATCH_16_ACTUAL_PATCH15_SIGNED_GATE_ANCHOR",
   "PATCH_16_REAL_5781_HISTORICAL_PREDICATE",
   "PATCH_16_FILTER_ABOVE_5778_BEFORE_CORRECTED_SORT",
   "PATCH_16_REAL_SEAL10_ON_CORRECTED_FAMILY"
  ].join(",")&&
  res.context.metrics.get("patch16.real_old_predicate_calls")===7n&&
  res.context.metrics.get("patch16.historical_kept")===5n&&
  res.context.metrics.get("patch16.corrected_kept")===2n&&
  res.context.metrics.get("patch16.long_rejected")===3n&&
  res.context.metrics.get("patch16.real_predecessor_58_write_sequences")===
    BigInt(res.predecessorCallCount)&&
  Object.isFrozen(res)&&Object.isFrozen(res.filter.corrected)&&
  !contexts.has(res.context)&&res.context!==res.preceding.context&&
  bowls.every((v,j)=>v===q.year.startBowls[j]),
  "genuine signed-gate anchor and real seal10 on corrected family");
 contexts.add(res.context);
 // N=1 legitimate boundary: old 5781 is present, never reaches selector.
 const one=patch16YearMax(q.c,idx,q.historical,q.signed,q.year,
  candidates(idx,q.g,[5781n,5778n]));
 check(one.filter.historicalFamilySize===2&&one.filter.correctedFamilySize===1&&
  one.filter.excludedLong[0]!.length===5781n&&
  one.selected.length===5778n&&one.selectedRank===1n&&
  one.yearSelection.familySize===1n,"corrected singleton selects 5778, not 5781");
 anchors++;oldKept+=res.filter.historicalFamilySize;
 filteredLong+=res.filter.excludedLong.length;
 preds+=res.predecessorCallCount+one.predecessorCallCount;
 writes+=Number(res.predecessorSharedWrites+one.predecessorSharedWrites);
 if(idx<0n)negative++;else short++;
}
check(anchors===4&&short===2&&negative===2&&oldKept===20&&
 filteredLong===12&&wrong===0&&originalSelectedWrong===0&&
 contexts.size===4&&preds===26&&writes===1508,
 "four signed anchors plus singleton actual real producers, no >5778");

const q=fixture(-1n),handler=new Patch16YearMaxHandler();
const ready=bootstrapMonster(q.c,q.c),legacyOnly=candidates(-1n,q.g,[5781n]);
const dispatchFn=Patch14WideChoiceDispatcher.prototype.dispatch;
let forbiddenSelectCalls=0;
try{
 Patch14WideChoiceDispatcher.prototype.dispatch=function(...args){
  forbiddenSelectCalls++;return dispatchFn.apply(this,args);
 };
 check(rejects(()=>handler.run(ready,-1n,q.historical,q.signed,q.year,legacyOnly),
   MonsterValidationError)&&forbiddenSelectCalls===0&&
   ready.status==="VALIDATED"&&ready.metrics.size===1&&
   ready.branchTrace.join(",")==="BOOTSTRAP_VALIDATE",
   "5781-only family rejected before ANY year selector or earlier Sauces");
}finally{Patch14WideChoiceDispatcher.prototype.dispatch=dispatchFn;}

const unready=createMonsterContext(q.c,q.c);
check(rejects(()=>handler.run(unready,-1n,q.historical,q.signed,q.year,
 candidates(-1n,q.g,[5778n])),MonsterStageError)&&
 unready.metrics.size===0&&!unready.branchTrace.length,"unready rejected");
for(const inputs of [
  {idx:0n,year:q.year,cs:candidates(-1n,q.g,[5778n])},
  {idx:1n,year:q.year,cs:candidates(-1n,q.g,[5778n])},
  {idx:-1n,year:{...q.year,visible:[]},cs:candidates(-1n,q.g,[5778n])},
  {idx:-1n,year:q.year,cs:candidates(1n,q.g,[5778n])},
  {idx:-1n,year:q.year,cs:candidates(-1n,q.g,[5782n])}
]){
 check(rejects(()=>handler.run(ready,inputs.idx,q.historical,q.signed,
  inputs.year as never,inputs.cs),MonsterValidationError)&&
  ready.status==="VALIDATED"&&ready.metrics.size===1&&
  ready.branchTrace.join(",")==="BOOTSTRAP_VALIDATE",
  "invalid/empty/misbound candidate input cannot commit");
}
const oldSigned=Patch15SignedGateQuestionAdapter.prototype.correctedQuestionDay;
let predicateActual=0,signedActual=0,selectorActual=0;
try{
 LegacyYearMaxEligibilityAdapter.prototype.oldEligibleYear=function(...args){
  predicateActual++;return oldFn.apply(this,args);
 };
 Patch15SignedGateQuestionAdapter.prototype.correctedQuestionDay=function(...args){
  signedActual++;return oldSigned.apply(this,args);
 };
 Patch14WideChoiceDispatcher.prototype.dispatch=function(...args){
  selectorActual++;return dispatchFn.apply(this,args);
 };
 handler.run(ready,-1n,q.historical,q.signed,q.year,
  candidates(-1n,q.g,[5781n,5778n,252n]));
 check(predicateActual===3&&signedActual===1&&selectorActual===3,
  "physical old 5781 predicate and complete signed + real year Sauce");
}finally{
 LegacyYearMaxEligibilityAdapter.prototype.oldEligibleYear=oldFn;
 Patch15SignedGateQuestionAdapter.prototype.correctedQuestionDay=oldSigned;
 Patch14WideChoiceDispatcher.prototype.dispatch=dispatchFn;
}
check(rejects(()=>handler.run(ready,-1n,q.historical,q.signed,q.year,
 candidates(-1n,q.g,[5778n])),MonsterStageError),"single-use owner");

let faults=0;
for(const point of ["old_predicate","signed_gate","year_select"] as const){
 const context=bootstrapMonster(q.c,q.c),counted=[...q.year.startBowls];
 let count=0;
 const marker="STAGE33_INJECT_"+point;
 try{
  if(point==="old_predicate"){
   LegacyYearMaxEligibilityAdapter.prototype.oldEligibleYear=function(...args){
    count++;if(count===2)throw Error(marker);
    return oldFn.apply(this,args);
   };
  }else{
   Patch14WideChoiceDispatcher.prototype.dispatch=function(...args){
    count++;
    if(point==="signed_gate"&&count===2||
       point==="year_select"&&count===3)throw Error(marker);
    return dispatchFn.apply(this,args);
   };
  }
  try{handler.run(context,-1n,q.historical,q.signed,q.year,
    candidates(-1n,q.g,[5778n,5781n,252n]));throw Error("no failure");}
  catch(e){check(e instanceof Error&&e.message===marker,
    "correct fault point propagated");}
  check(context.status==="VALIDATED"&&context.metrics.size===1&&
    context.branchTrace.join(",")==="BOOTSTRAP_VALIDATE"&&
    q.year.startBowls.every((v,j)=>v===counted[j]),
    "no partial outer context on injected failure");
  faults++;
 }finally{
  LegacyYearMaxEligibilityAdapter.prototype.oldEligibleYear=oldFn;
  Patch14WideChoiceDispatcher.prototype.dispatch=dispatchFn;
 }
 check(handler.run(context,-1n,q.historical,q.signed,q.year,
  candidates(-1n,q.g,[5778n,5781n,252n])).selected.length<=5778n,
  "same owner deterministic retry after fault");
}
const a=patch16YearMax(q.c,-1n,q.historical,q.signed,q.year,
 candidates(-1n,q.g,[5778n,5781n]));
const b=patch16YearMax(q.c,-1n,q.historical,q.signed,q.year,
 candidates(-1n,q.g,[5778n,5781n]));
a.context.metrics.set("private",6n);a.context.logs.push("डावा");
check(a.context!==b.context&&a.filter!==b.filter&&
 !b.context.metrics.has("private")&&b.context.logs.length===0,
 "private per-invocation ownership");
check(rejects(()=>calendarDateSpaghetti(F,F),MonsterStageError),
 "Stage54 calendar route still unavailable");
console.log("STAGE_33_PATCH_16_GUARDS_PASS boundary="+edges+
 " signedAnchors="+anchors+" positive="+short+" negative="+negative+
 " oldAccepted="+oldKept+" removedLong="+filteredLong+
 " correctedWrong="+wrong+" wrongSelected="+originalSelectedWrong+
 " predecessorCalls="+preds+" sharedWrites="+writes+
 " oldPredicateSpy="+predicateActual+" signedSpy="+signedActual+
 " selectorSpy="+selectorActual+" emptySelectorCalls="+forbiddenSelectCalls+
 " faults="+faults);
