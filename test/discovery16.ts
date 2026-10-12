import {
  LegacyYearMaxEligibilityAdapter,LegacyYearMaxCandidateFilter,
  Discovery16YearMaxHandler,discoverLegacyYearMax,
  bootstrapMonster,createMonsterContext,LegacyPositiveOnlyGateQuestionAdapter,
  Patch15SignedGateQuestionAdapter,Patch14WideChoiceDispatcher,
  MonsterValidationError,MonsterStageError,calendarDateSpaghetti,
  LEGACY_YEAR_MAX
} from "../src/index.ts";
import {
  FOUNDATION_DAY as F,NormativeOracle,STONES,workCounts,
  buildHiddenDrops,buildVisibleDrops,initialBowls,sauce,askBowl,chooseRank
} from "./normativeOracle.ts";
function check(ok:boolean,msg:string):void{if(!ok)throw Error(msg);}
function rejects(fn:()=>unknown,type:typeof MonsterValidationError|typeof MonsterStageError):boolean{
 try{fn();}catch(e){return e instanceof type;}return false;
}
function question(c:bigint,t:bigint){
 const w=workCounts(c,t);
 return {visible:buildVisibleDrops(w,STONES,buildHiddenDrops(w,STONES)),
   stones:STONES,startBowls:initialBowls(w)};
}
function setup(anchorIndex:1n|-1n){
 const source=anchorIndex<0n?F-1n:F+1n;
 const trueGate=new NormativeOracle().gateDay(anchorIndex);
 const c=trueGate+1n;
 const historical=[question(F,F+1n)],correct=[{...question(F,source),targetDay:source}];
 return {source,c,gate:trueGate,historical,correct,year:question(c,c)};
}
function candidates(anchorIndex:bigint,gate:bigint,lengths:readonly bigint[]){
 return lengths.map((length,i)=>({
   openGateIndex:anchorIndex,closeGateIndex:anchorIndex+BigInt(i+6),
   openGateDay:gate,closeGateDay:gate+length
 }));
}
check(LEGACY_YEAR_MAX===5781n,"historical fixed 5781");
const old=new LegacyYearMaxEligibilityAdapter(),filter=new LegacyYearMaxCandidateFilter();
for(const [length,expected] of [
 [251n,false],[252n,true],[5777n,true],[5778n,true],
 [5779n,true],[5780n,true],[5781n,true],[5782n,false]
] as const){
 check(old.oldEligibleYear(length,6n)===expected,"true original <=5781 boundary");
 check(old.oldEligibleYear(length,5n)===false,"at least six gate gaps required");
}
for(const v of [0n,1n,6n,100n])
 check(old.oldEligibleYear(5781n,v)===(v>=6n),
 "all original gate-gap boundary classes");
for(const [length,gaps] of [[-1n,6n],[1n,-1n],[1 as unknown as bigint,6n]] as const)
 check(rejects(()=>old.oldEligibleYear(length,gaps),MonsterValidationError),
   "legacy predicate rejects malformed data");
let actualCalls=0;
const originalOld=LegacyYearMaxEligibilityAdapter.prototype.oldEligibleYear;
try{
 LegacyYearMaxEligibilityAdapter.prototype.oldEligibleYear=function(...args){
  actualCalls++;return originalOld.apply(this,args);
 };
 const listing=candidates(1n,F,[5781n,251n,5780n,5782n,5779n,5778n,252n]);
 const result=filter.filter(listing);
 check(actualCalls===7&&result.examined===7&&result.oldPredicateCalls===7&&
   result.kept.length===5&&result.rejected.length===2&&
   result.acceptedLongLengths.join(",")==="5779,5780,5781"&&
   result.kept.map(e=>e.length).join(",")==="252,5778,5779,5780,5781"&&
   result.rejected.map(e=>e.length).join(",")==="251,5782"&&
   Object.isFrozen(result)&&Object.isFrozen(result.kept)&&
   result.all.length===7,"legacy 5781 actually passed through old method and sort");
}finally{
 LegacyYearMaxEligibilityAdapter.prototype.oldEligibleYear=originalOld;
}
const signed=[1n,-1n] as const;
const contexts=new Set<object>();
let signedCases=0,cells=0,legacyLongKept=0,yearWrong=0,writes=0,
 oldPredicateCalls=0,selectorCalls=0;
for(const index of signed){
 const args=setup(index),lengths=[252n,5778n,5779n,5780n,5781n,5782n];
 const list=candidates(index,args.gate,lengths);
 const before=[...args.year.startBowls];
 const result=discoverLegacyYearMax(args.c,index,args.historical,args.correct,
   args.year,list);
 const rank=chooseRank(askBowl(sauce(args.c,args.c),1,10n),5n);
 const positive=index>0n;
 check(result.calculationDay===args.c&&result.anchorGateIndex===index&&
   result.anchorGateDay===args.gate&&
   result.preceding.correctedGateDay===args.gate&&
   result.preceding.historicalMismatch===!positive&&
   result.candidateSource==="INJECTED_CANDIDATE_BOUNDARIES"&&
   result.legacyYearMax===5781n&&
   result.filter.kept.map(x=>x.length).join(",")==="252,5778,5779,5780,5781"&&
   result.filter.rejected.map(x=>x.length).join(",")==="5782"&&
   result.filter.acceptedLongLengths.join(",")==="5779,5780,5781"&&
   result.filter.oldPredicateCalls===6&&
   result.selectedRank===rank&&result.selected===result.filter.kept[Number(rank-1n)]&&
   result.yearSelection.correctedRank===rank&&
   result.yearSelection.familySize===5n&&
   result.yearSelection.selectionMode==="SHORT_LEGACY"&&
   result.yearSelection.predecessorSharedWrites===58&&
   result.preceding.totalPredecessorCalls===(positive?1:2)&&
   result.predecessorCallCount===(positive?2:3)&&
   result.predecessorSharedWrites===BigInt(result.predecessorCallCount)*58n&&
   result.context.status==="DISCOVERY_16_RECORDED"&&
   result.context.metrics.get("discovery16.calls")===1n&&
   result.context.metrics.get("discovery16.old_predicate_calls")===6n&&
   result.context.metrics.get("discovery16.long_5779_to_5781_kept")===3n&&
   result.context.metrics.get("discovery16.real_predecessor_58_write_sequences")===
      BigInt(result.predecessorCallCount)&&
   result.context.branchTrace.join(",")=== [
    "BOOTSTRAP_VALIDATE","DISCOVERY_16_ACTUAL_PATCH15_SIGNED_GATE_ANCHOR",
    "DISCOVERY_16_REAL_LEGACY_5781_CANDIDATE_FILTER",
    "DISCOVERY_16_OLD_LENGTH_ONLY_SORT_AND_REAL_SEAL10_SELECTION"
   ].join(",")&&
   Object.isFrozen(result)&&!contexts.has(result.context)&&
   before.every((v,j)=>v===args.year.startBowls[j]),
   "real Stage31 predecessor and actual seal10 selection after old 5781 filter");
 contexts.add(result.context);
 writes+=Number(result.predecessorSharedWrites);
 if(result.selectedRank!==rank)yearWrong++;
 legacyLongKept+=result.filter.acceptedLongLengths.length;
 oldPredicateCalls+=result.filter.oldPredicateCalls;
 signedCases++;
 // These are INJECTED candidates; explicitly selecting 5781 via one-element
 // family is an actual production rank, but not a claim of a real gate at L=5781.
 const singleton=discoverLegacyYearMax(args.c,index,args.historical,args.correct,
   args.year,candidates(index,args.gate,[5781n]));
 check(singleton.filter.kept.length===1&&singleton.selected.length===5781n&&
   singleton.selectedRank===1n&&singleton.yearSelection.familySize===1n,
   "5781 really reaches production seal10 selector and wins injected singleton family");
 writes+=Number(singleton.predecessorSharedWrites);
 selectorCalls+=2;cells+=2;
}
check(signedCases===2&&cells===4&&contexts.size===2&&
 legacyLongKept===6&&yearWrong===0&&oldPredicateCalls===12&&
 selectorCalls===4&&writes===580,"both signed real gate anchors and full 58-write sequences");

for(const raw of [
 [],[{openGateIndex:0n,closeGateIndex:0n,openGateDay:F,closeGateDay:F+1000n}],
 [{openGateIndex:0n,closeGateIndex:6n,openGateDay:F,closeGateDay:F}],
 [{openGateIndex:0n,closeGateIndex:6n,openGateDay:F,closeGateDay:"bad" as unknown as bigint}]
 ]){
 check(rejects(()=>filter.filter(raw),MonsterValidationError),
  "invalid candidate pairs");
}
const args=setup(-1n),ok=candidates(-1n,args.gate,[5781n,5778n]);
const handler=new Discovery16YearMaxHandler();
const ctx=createMonsterContext(args.c,args.c);
check(rejects(()=>handler.run(ctx,-1n,args.historical,args.correct,args.year,ok),MonsterStageError)&&
 ctx.metrics.size===0&&ctx.branchTrace.length===0,"READY required");
const ready=bootstrapMonster(args.c,args.c);
for(const input of [
 [0n,args.year,ok],
 [1n,args.year,ok],
 [-1n,{visible:[],stones:STONES,startBowls:args.year.startBowls},ok],
 [-1n,args.year,candidates(-1n,args.gate,[5782n])],
 [-1n,args.year,candidates(1n,args.gate,[5781n])]
] as const){
 check(rejects(()=>handler.run(ready,input[0],
  args.historical,args.correct,input[1] as never,input[2]),MonsterValidationError),
  "invalid anchor, year inputs and no eligible pair rejected");
 check(ready.status==="VALIDATED"&&ready.metrics.size===1&&
   ready.branchTrace.join(",")==="BOOTSTRAP_VALIDATE","preflight never commits caller state");
}
const oldQuestion=LegacyPositiveOnlyGateQuestionAdapter.prototype.oldQuestionDay;
const signedMethod=Patch15SignedGateQuestionAdapter.prototype.correctedQuestionDay;
const dispatchMethod=Patch14WideChoiceDispatcher.prototype.dispatch;
let actualLegacy=0,actualSigned=0,actualDispatch=0;
try{
 LegacyPositiveOnlyGateQuestionAdapter.prototype.oldQuestionDay=function(...p){
  actualLegacy++;return oldQuestion.apply(this,p);
 };
 Patch15SignedGateQuestionAdapter.prototype.correctedQuestionDay=function(...p){
  actualSigned++;return signedMethod.apply(this,p);
 };
 Patch14WideChoiceDispatcher.prototype.dispatch=function(...p){
  actualDispatch++;return dispatchMethod.apply(this,p);
 };
 discoverLegacyYearMax(args.c,-1n,args.historical,args.correct,args.year,ok);
 check(actualLegacy===1&&actualSigned===1&&actualDispatch===3,
  "actual Stage30 old method, Stage31 signed method and Stage29 selector 3 calls");
}finally{
 LegacyPositiveOnlyGateQuestionAdapter.prototype.oldQuestionDay=oldQuestion;
 Patch15SignedGateQuestionAdapter.prototype.correctedQuestionDay=signedMethod;
 Patch14WideChoiceDispatcher.prototype.dispatch=dispatchMethod;
}
let faults=0;
for(const which of ["gate","year"] as const){
 const owner=bootstrapMonster(args.c,args.c),initial=[...args.year.startBowls];
 const label="STAGE32_INJECT_"+which;
 let invoked=0;
 try{
  Patch14WideChoiceDispatcher.prototype.dispatch=function(...p){
   invoked++;
   if(which==="gate"&&invoked===1||which==="year"&&invoked===3)
    throw Error(label);
   return dispatchMethod.apply(this,p);
  };
  try{handler.run(owner,-1n,args.historical,args.correct,args.year,ok);throw Error("absent injection");}
  catch(e){check(e instanceof Error&&e.message===label,"actual injected exception propagates");}
  check(owner.status==="VALIDATED"&&owner.metrics.size===1&&
    owner.branchTrace.join(",")==="BOOTSTRAP_VALIDATE"&&
    args.year.startBowls.every((v,j)=>v===initial[j]),"no partial outer mutation");
  faults++;
 }finally{Patch14WideChoiceDispatcher.prototype.dispatch=dispatchMethod;}
 check(handler.run(owner,-1n,args.historical,args.correct,args.year,ok).filter.kept.length===2,
   "retry unchanged inputs on same ready owner");
}
const committed=handler.run(ready,-1n,args.historical,args.correct,args.year,ok);
check(rejects(()=>handler.run(ready,-1n,args.historical,args.correct,args.year,ok),MonsterStageError)&&
 committed.context===ready,"no committed context double execution");
const x=discoverLegacyYearMax(args.c,-1n,args.historical,args.correct,args.year,ok);
const y=discoverLegacyYearMax(args.c,-1n,args.historical,args.correct,args.year,ok);
x.context.metrics.set("private",1n);x.context.logs.push("x");
check(x.context!==y.context&&!y.context.metrics.has("private")&&
 y.context.logs.length===0&&x.filter!==y.filter,"isolated reentrant owners");
check(rejects(()=>calendarDateSpaghetti(F,F),MonsterStageError),"Stage54 gate intact");
console.log("STAGE_32_DISCOVERY_16_GUARDS_PASS anchorSides="+signedCases+
 " actualCases="+cells+" legacyLongAccepted="+legacyLongKept+
 " selectorWrong="+yearWrong+" predicateCalls="+oldPredicateCalls+
 " selectorCalls="+selectorCalls+" fullWrites="+writes+
 " oldCalls="+actualLegacy+" signedCalls="+actualSigned+
 " dispatchCalls="+actualDispatch+" faultCases="+faults);
