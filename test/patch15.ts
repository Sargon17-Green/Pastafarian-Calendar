import {
 bootstrapMonster,createMonsterContext,
 Patch15SignedGateQuestionAdapter,Patch15SignedGateHandler,patch15SignedGate,
 LegacyPositiveOnlyGateQuestionAdapter,Patch14WideChoiceDispatcher,
 MonsterValidationError,MonsterStageError,calendarDateSpaghetti
} from "../src/index.ts";
import {
 FOUNDATION_DAY as F,NormativeOracle,STONES,workCounts,
 buildHiddenDrops,buildVisibleDrops,initialBowls,
 sauce,askBowl,chooseRank
} from "./normativeOracle.ts";
function check(ok:boolean,why:string):void{if(!ok)throw Error(why);}
function rejected(fn:()=>unknown,type:typeof MonsterValidationError|typeof MonsterStageError):boolean{
 try{fn();}catch(e){return e instanceof type;}return false;
}
function source(step:bigint){
 const w=workCounts(F,F+step);
 return Object.freeze({
  targetDay:F+step,
  visible:buildVisibleDrops(w,STONES,buildHiddenDrops(w,STONES)),
  stones:STONES,startBowls:initialBowls(w)
 });
}
function fixture(k:bigint){
 const n=Number(k<0n?-k:k),sgn=k<0n?-1n:1n;
 return {
  historical:Array.from({length:n},(_,i)=>source(BigInt(i+1))),
  correct:Array.from({length:n},(_,i)=>source(BigInt(i+1)*sgn))
 };
}
const oracle=new NormativeOracle(),adapter=new Patch15SignedGateQuestionAdapter();
for(const index of [-1000n,-2n,-1n,1n,2n,1000n])
 check(adapter.correctedQuestionDay(index)===F+index,
  "true signed day not positive magnitude");
for(const bad of [0n,0,null,1 as unknown as bigint] as unknown[])
 check(rejected(()=>adapter.correctedQuestionDay(bad as bigint),MonsterValidationError),
  "invalid signed step");
const contexts=new Set<object>();
let signed=0,positive=0,negative=0,correctedWrong=0,oldWrong=0,oldMatches=0;
let historicalQuestions=0,correctedQuestions=0,actualPredecessors=0,sharedWrites=0;
for(const k of [1n,2n,3n,4n,-1n,-2n,-3n,-4n]){
 const input=fixture(k),snapshots=input.correct.map(q=>[...q.startBowls]);
 const out=patch15SignedGate(k,input.historical,input.correct);
 const truth=oracle.gateDay(k),isNegative=k<0n;
 if(out.correctedGateDay!==truth)correctedWrong++;
 if(out.historicalGateDay!==truth)oldWrong++;else oldMatches++;
 if(isNegative)negative++;else positive++;
 check(out.gateIndex===k&&out.correctedGateDay===truth&&
  out.signedQuestionCalls===input.correct.length&&
  out.preceding.actualPredecessorCalls===input.correct.length&&
  out.historicalGateDay===out.preceding.historicalGateDay&&
  out.historicalMismatch===isNegative&&
  out.historicalWrongSideQuestions===(isNegative?input.correct.length:0)&&
  out.extraNegativePredecessorCalls===(isNegative?input.correct.length:0)&&
  out.totalPredecessorCalls===(isNegative?input.correct.length*2:input.correct.length)&&
  out.totalSharedWrites===BigInt(out.totalPredecessorCalls)*58n&&
  out.gaps.length===input.correct.length&&
  out.context.status==="PATCH_15_APPLIED"&&
  out.context.branchTrace.join(",")=== [
   "BOOTSTRAP_VALIDATE","PATCH_15_REAL_DISCOVERY15_LEGACY_GATE_PATH",
   isNegative?"PATCH_15_ACTUAL_NEGATIVE_SIDE_SAUCE":
              "PATCH_15_REUSE_POSITIVE_SIDE_SAUCE",
   "PATCH_15_CORRECT_GATE_DAY_COMMITTED"
  ].join(",")&&
  out.context.metrics.get("patch15.calls")===1n&&
  out.context.metrics.get("patch15.real_historical_gate_queries")===BigInt(input.correct.length)&&
  out.context.metrics.get("patch15.corrected_signed_queries")===BigInt(input.correct.length)&&
  out.context.metrics.get("patch15.additional_negative_sauce_calls")===
   BigInt(isNegative?input.correct.length:0)&&
  out.context.metrics.get("patch15.total_predecessor_58_write_sequences")===
   BigInt(out.totalPredecessorCalls)&&
  (out.context.metrics.get("patch15.historical_gate_mismatches")??0n)===(isNegative?1n:0n)&&
  !contexts.has(out.context)&&out.context!==out.preceding.context&&
  Object.isFrozen(out)&&Object.isFrozen(out.gaps),
  "signed gate lifecycle, correct vs historical evidence and metrics");
 contexts.add(out.context);
 let sum=0n;
 for(let j=0;j<input.correct.length;j++){
  const step=BigInt(j+1)*(isNegative?-1n:1n),entry=out.gaps[j]!;
  const expectedRank=chooseRank(askBowl(sauce(F,F+step),1,1n),922n);
  const originalRank=chooseRank(askBowl(sauce(F,F+BigInt(j+1)),1,1n),922n);
  check(entry.signedIndex===step&&entry.askedTargetDay===F+step&&
    entry.historicalAskedTargetDay===F+BigInt(j+1)&&
    entry.correctedRank===expectedRank&&
    entry.correctedGap===41n+expectedRank&&
    entry.historicalGap===41n+originalRank&&
    entry.correctedPredecessor.correctedRank===expectedRank&&
    entry.correctedPredecessor.selectionMode==="SHORT_LEGACY"&&
    entry.correctedPredecessor.predecessorSharedWrites===58&&
    entry.correctedPredecessor.realLegacyCalls===1&&
    entry.correctedPredecessor.preceding.preceding.preceding.legacyModuloCalls===1&&
    entry.correctedPredecessor.preceding.preceding.preceding.preceding.latchCaptures===1&&
    entry.correctedPredecessor.preceding.preceding.preceding.preceding.preceding.historical.latestSource==="STIR_12"&&
    entry.reusedPositiveHistorical===!isNegative&&
    entry.addedNegativeSideCalls===(isNegative?1:0)&&
    entry.actualCorrectedPredecessorCalls===1&&
    entry.sharedWritesForCorrected===58&&
    Object.isFrozen(entry)&&
    input.correct[j]!.startBowls.every((x,i)=>x===snapshots[j]![i]),
    "real corrected Sauce with true negative day and full real predecessor");
  if(!isNegative)
   check(entry.correctedPredecessor===out.preceding.gaps[j]!.preceding,
     "positive case reuses exact legacy production object");
  else
   check(entry.correctedPredecessor!==out.preceding.gaps[j]!.preceding,
     "negative case actually computes a different full predecessor");
  sum+=entry.correctedGap;
  historicalQuestions++;
  correctedQuestions++;
 }
 check(out.correctedGateDay===F+(isNegative?-sum:sum),
  "corrected gate day sums full signed ordered gaps");
 actualPredecessors+=out.totalPredecessorCalls;
 sharedWrites+=out.totalPredecessorCalls*58;
 signed++;
}
check(signed===8&&positive===4&&negative===4&&
 correctedWrong===0&&oldWrong===4&&oldMatches===4&&
 historicalQuestions===20&&correctedQuestions===20&&
 actualPredecessors===30&&sharedWrites===1740&&contexts.size===8,
 "8 real canonical signed gates + old 4 wrong and true predecessor writes");

const handler=new Patch15SignedGateHandler(),unready=createMonsterContext(F,F-2n);
const q2=fixture(-2n);
check(rejected(()=>handler.run(unready,-2n,q2.historical,q2.correct),MonsterStageError)&&
 unready.metrics.size===0&&unready.branchTrace.length===0,
 "unready context rejected before any execution");
const ready=bootstrapMonster(F,F-2n);
for(const [index,h,c] of [
 [0n,[],[]],[-1n,q2.historical,q2.correct],
 [-2n,q2.historical,q2.correct.slice(0,1)],
 [2n,q2.historical,q2.correct],
 [2 as unknown as bigint,q2.historical,q2.correct]
] as const)
 check(rejected(()=>handler.run(ready,index as bigint,h,c),MonsterValidationError),
  "incorrect gate index, wrong context binding or mismatched array lengths rejected");
for(const second of [
 {...q2.correct[1]!,targetDay:F+2n},
 {...q2.correct[1]!,visible:[]},
 {...q2.correct[1]!,stones:[]},
 {...q2.correct[1]!,startBowls:[1n]}
 ]){
 check(rejected(()=>handler.run(ready,-2n,q2.historical,[q2.correct[0]!,second]),
  MonsterValidationError)&&ready.status==="VALIDATED"&&
  ready.metrics.size===1&&ready.branchTrace.join(",")==="BOOTSTRAP_VALIDATE",
  "malformed second canonical negative query fails before any predecessor or outer writes");
}
const oldFn=LegacyPositiveOnlyGateQuestionAdapter.prototype.oldQuestionDay;
const signedFn=Patch15SignedGateQuestionAdapter.prototype.correctedQuestionDay;
const dispatchFn=Patch14WideChoiceDispatcher.prototype.dispatch;
let physicalOld=0,physicalSigned=0,physicalDispatch=0;
try{
 LegacyPositiveOnlyGateQuestionAdapter.prototype.oldQuestionDay=function(...args){
  physicalOld++;return oldFn.apply(this,args);
 };
 Patch15SignedGateQuestionAdapter.prototype.correctedQuestionDay=function(...args){
  physicalSigned++;return signedFn.apply(this,args);
 };
 Patch14WideChoiceDispatcher.prototype.dispatch=function(...args){
  physicalDispatch++;return dispatchFn.apply(this,args);
 };
 patch15SignedGate(-2n,q2.historical,q2.correct);
 patch15SignedGate(2n,fixture(2n).historical,fixture(2n).correct);
 check(physicalOld===4&&physicalSigned===4&&physicalDispatch===6,
  "true history old=4, signed questions=4, actual Sauce predecessor calls=6");
}finally{
 LegacyPositiveOnlyGateQuestionAdapter.prototype.oldQuestionDay=oldFn;
 Patch15SignedGateQuestionAdapter.prototype.correctedQuestionDay=signedFn;
 Patch14WideChoiceDispatcher.prototype.dispatch=dispatchFn;
}
let faults=0;
for(const place of ["historical_first","historical_second","corrected_first","corrected_second","signed_second"] as const){
 const ctx=bootstrapMonster(F,F-2n),sources=fixture(-2n);
 const before=sources.correct.map(q=>[...q.startBowls]);let calls=0;
 const fail="PATCH15_INJECT_"+place;
 try{
  if(place==="historical_first"||place==="historical_second")
   LegacyPositiveOnlyGateQuestionAdapter.prototype.oldQuestionDay=function(...args){
    calls++;
    if(calls===(place==="historical_first"?1:2))throw Error(fail);
    return oldFn.apply(this,args);
   };
  else if(place==="signed_second")
   Patch15SignedGateQuestionAdapter.prototype.correctedQuestionDay=function(...args){
    calls++;if(calls===2)throw Error(fail);
    return signedFn.apply(this,args);
   };
  else
   Patch14WideChoiceDispatcher.prototype.dispatch=function(...args){
    calls++;
    if(calls===(place==="corrected_first"?3:4))throw Error(fail);
    return dispatchFn.apply(this,args);
   };
  try{handler.run(ctx,-2n,sources.historical,sources.correct);throw Error("missing fault");}
  catch(e){check(e instanceof Error&&e.message===fail,"correct injected failure propagated");}
  check(ctx.status==="VALIDATED"&&ctx.metrics.size===1&&
    ctx.branchTrace.join(",")==="BOOTSTRAP_VALIDATE"&&
    sources.correct.every((q,i)=>q.startBowls.every((x,j)=>x===before[i]![j])),
    "no caller/outer partial mutation on deep failure");
  faults++;
 }finally{
  LegacyPositiveOnlyGateQuestionAdapter.prototype.oldQuestionDay=oldFn;
  Patch15SignedGateQuestionAdapter.prototype.correctedQuestionDay=signedFn;
  Patch14WideChoiceDispatcher.prototype.dispatch=dispatchFn;
 }
 check(handler.run(ctx,-2n,sources.historical,sources.correct).correctedGateDay===
   oracle.gateDay(-2n),"safe same context retry after error");
}
const success=handler.run(ready,-2n,q2.historical,q2.correct);
check(success.correctedGateDay===oracle.gateDay(-2n)&&
 rejected(()=>handler.run(ready,-2n,q2.historical,q2.correct),MonsterStageError),
 "single-use correct lifecycle");
const x=patch15SignedGate(-1n,fixture(-1n).historical,fixture(-1n).correct),
 y=patch15SignedGate(-1n,fixture(-1n).historical,fixture(-1n).correct);
x.context.metrics.set("private",11n);x.context.logs.push("डावा");
check(x.context!==y.context&&x.preceding!==y.preceding&&x.gaps!==y.gaps&&
 x.gaps[0]!==y.gaps[0]&&
 !y.context.metrics.has("private")&&y.context.logs.length===0,
 "separate returned semantic state and no alias bleed");
check(rejected(()=>calendarDateSpaghetti(F,F),MonsterStageError),
 "Stage54 calendar route still disabled");
console.log("STAGE_31_PATCH_15_GUARDS_PASS signed="+signed+
 " positive="+positive+" negative="+negative+" correctedWrong="+correctedWrong+
 " oldWrong="+oldWrong+" oldMatches="+oldMatches+" historicalQuestions="+historicalQuestions+
 " correctedQuestions="+correctedQuestions+" actualPredecessors="+actualPredecessors+
 " sharedWrites="+sharedWrites+" oldCalls="+physicalOld+" signedCalls="+physicalSigned+
 " dispatchCalls="+physicalDispatch+" injectedFailures="+faults);
