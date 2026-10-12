import {
  bootstrapMonster,createMonsterContext,LegacyPositiveOnlyGateQuestionAdapter,
  Discovery15PositiveSideGateHandler,discoverLegacyPositiveGate,
  Patch14WideChoiceDispatcher,MonsterStageError,MonsterValidationError,
  calendarDateSpaghetti,DISCOVERY15_FOUNDATION_DAY
} from "../src/index.ts";
import {
  FOUNDATION_DAY as F,NormativeOracle,STONES,workCounts,
  buildHiddenDrops,buildVisibleDrops,initialBowls,
  sauce,askBowl,chooseRank
} from "./normativeOracle.ts";
function check(x:boolean,msg:string):void{if(!x)throw Error(msg);}
function rejects(fn:()=>unknown,type:typeof MonsterStageError|typeof MonsterValidationError):boolean{
 try{fn();}catch(e){return e instanceof type;}return false;
}
function fixture(n:bigint){
 const w=workCounts(F,F+n);
 return Object.freeze({visible:buildVisibleDrops(w,STONES,buildHiddenDrops(w,STONES)),
   stones:STONES,startBowls:initialBowls(w)});
}
function questions(n:number){return Array.from({length:n},(_,i)=>fixture(BigInt(i+1)));}
const oracle=new NormativeOracle();
check(DISCOVERY15_FOUNDATION_DAY===F,"true Foundation anchor");
let signed=0,positive=0,negative=0,wrong=0,good=0,questionsRun=0,writes=0;
const contexts=new Set<object>();
for(const k of [1n,2n,3n,4n,-1n,-2n,-3n,-4n]){
 const values=questions(Number(k<0n?-k:k));
 const initialBowls=values.map(q=>[...q.startBowls]);
 const out=discoverLegacyPositiveGate(k,values);
 const expected=oracle.gateDay(k);
 if(out.historicalGateDay!==expected)wrong++;else good++;
 if(k>0n)positive++;else negative++;
 check(out.gateIndex===k&&out.questionCount===values.length&&
   out.actualPredecessorCalls===values.length&&
   out.predecessorSharedWrites===BigInt(values.length)*58n&&
   out.negativeWrongSideQuestions===(k<0n?values.length:0)&&
   out.askedPositiveSideForNegative===(k<0n)&&
   out.gaps.length===values.length&&
   out.context.status==="DISCOVERY_15_RECORDED"&&
   out.context.branchTrace.join(",")=== [
    "BOOTSTRAP_VALIDATE","DISCOVERY_15_FULL_PATCH14_GATE_GAP_CHAIN",
    "DISCOVERY_15_LEGACY_FOUNDATION_PLUS_ABS",
    k<0n?"DISCOVERY_15_NEGATIVE_GATE_ASKS_WRONG_POSITIVE_SIDE":
          "DISCOVERY_15_POSITIVE_GATE_ASKS_CORRECT_SIDE"
   ].join(",")&&
   out.context.metrics.get("discovery15.calls")===1n&&
   out.context.metrics.get("discovery15.actual_legacy_method_calls")===BigInt(values.length)&&
   out.context.metrics.get("discovery15.predecessor_58_write_total")===
    BigInt(values.length)*58n&&
   !contexts.has(out.context)&&Object.isFrozen(out)&&
   Object.isFrozen(out.gaps),"correct lifecycle and preserved historical question ledger");
 contexts.add(out.context);
 let total=0n;
 for(let i=0;i<values.length;i++){
  const gap=out.gaps[i]!,magnitude=BigInt(i+1);
  const stream=askBowl(sauce(F,F+magnitude),1,1n);
  const rank=chooseRank(stream,922n);
  check(gap.gateIndex===(k<0n?-magnitude:magnitude)&&
    gap.askedTargetDay===F+magnitude&&
    gap.normativeTargetDay===F+(k<0n?-magnitude:magnitude)&&
    gap.historicalRank===rank&&gap.historicalGap===41n+rank&&
    gap.preceding.correctedRank===rank&&
    gap.preceding.selectionMode==="SHORT_LEGACY"&&
    gap.preceding.predecessorSharedWrites===58&&
    gap.preceding.preceding.legacyShortOnlyCalls===1&&
    gap.preceding.preceding.preceding.correctedRank===rank&&
    gap.preceding.preceding.preceding.preceding.legacyModuloCalls===1&&
    gap.preceding.preceding.preceding.preceding.preceding.latchCaptures===1&&
    gap.preceding.preceding.preceding.preceding.preceding.historical.latestSource==="STIR_12"&&
    gap.preceding.context!==out.context&&
    Object.isFrozen(gap)&&values[i]!.startBowls.every((v,j)=>v===initialBowls[i]![j]),
    "genuine Stage29 predecessor and canonical positive-side computed question");
  total+=gap.historicalGap;
  questionsRun++;writes+=58;
 }
 check(out.historicalGateDay===(k<0n?F-total:F+total),
   "historical gate day adds/subtracts all positive-side gaps");
 if(k>0n)check(out.historicalGateDay===expected,"positive gate matches normative");
 else if(k===-1n||k===-2n)
   check(out.historicalGateDay!==expected,"negative -1 and -2 must expose the historical error");
 signed++;
}
check(signed===8&&positive===4&&negative===4&&wrong>=2&&
  good===positive&&contexts.size===8&&questionsRun===20&&writes===1160,
  "real sign asymmetry and complete 58-write gaps");

const old=new LegacyPositiveOnlyGateQuestionAdapter(),handler=new Discovery15PositiveSideGateHandler();
for(const k of [-1000n,-2n,-1n,1n,2n,1000n])
 check(old.oldQuestionDay(k)===F+(k<0n?-k:k),"old method uses abs on both signs");
for(const k of [0n,0,null,1 as unknown as bigint] as unknown[])
 check(rejects(()=>old.oldQuestionDay(k as bigint),MonsterValidationError),"bad old gate argument");
const ctx0=createMonsterContext(F,F-2n);
check(rejects(()=>handler.run(ctx0,-2n,questions(2)),MonsterStageError)&&
 ctx0.branchTrace.length===0&&ctx0.metrics.size===0,"invalid lifecycle");
const ready=bootstrapMonster(F,F-2n);
for(const [gate,qs] of [
 [0n,[]],[-1n,questions(2)],[-2n,questions(1)],
 [-2n,questions(3)],[2n,questions(2)],[2 as unknown as bigint,questions(2)]
] as const)
 check(rejects(()=>handler.run(ready,gate as bigint,qs),MonsterValidationError),
   "context binding and query-count validation");
for(const v of [
 {visible:[],stones:STONES,startBowls:fixture(1n).startBowls},
 {visible:fixture(1n).visible,stones:[],startBowls:fixture(1n).startBowls},
 {visible:fixture(1n).visible,stones:STONES,startBowls:[1n]}
 ]){
 const q=[fixture(1n),v];
 check(rejects(()=>handler.run(ready,-2n,q),MonsterValidationError)&&
  ready.branchTrace.join(",")==="BOOTSTRAP_VALIDATE"&&
  ready.status==="VALIDATED"&&ready.metrics.size===1,
  "preflight validates even the second query without partial commit");
}
handler.run(ready,-2n,questions(2));
check(rejects(()=>handler.run(ready,-2n,questions(2)),MonsterStageError),"single use");

const oldFn=LegacyPositiveOnlyGateQuestionAdapter.prototype.oldQuestionDay;
const dispatchFn=Patch14WideChoiceDispatcher.prototype.dispatch;
let physicalOld=0,physicalDispatch=0;
try {
 LegacyPositiveOnlyGateQuestionAdapter.prototype.oldQuestionDay=function(...args){
  physicalOld++;return oldFn.apply(this,args);
 };
 Patch14WideChoiceDispatcher.prototype.dispatch=function(...args){
  physicalDispatch++;return dispatchFn.apply(this,args);
 };
 discoverLegacyPositiveGate(-2n,questions(2));
 check(physicalOld===2&&physicalDispatch===2,
   "two actual old day questions and two full Patch14 dispatches");
}finally{
 LegacyPositiveOnlyGateQuestionAdapter.prototype.oldQuestionDay=oldFn;
 Patch14WideChoiceDispatcher.prototype.dispatch=dispatchFn;
}
let faults=0;
for(const place of ["before","after_one","inside_second"] as const){
 const ctx=bootstrapMonster(F,F-2n),qs=questions(2);
 let calls=0;
 try{
  if(place==="before"||place==="after_one"){
   LegacyPositiveOnlyGateQuestionAdapter.prototype.oldQuestionDay=function(...args){
    calls++;
    if(place==="before"||calls===2)throw Error("GATE15_INJECT_"+place);
    return oldFn.apply(this,args);
   };
  }else{
   Patch14WideChoiceDispatcher.prototype.dispatch=function(...args){
    calls++;
    if(calls===2)throw Error("GATE15_INJECT_"+place);
    return dispatchFn.apply(this,args);
   };
  }
  try{handler.run(ctx,-2n,qs);throw Error("injection absent");}
  catch(e){check(e instanceof Error&&e.message==="GATE15_INJECT_"+place,
    "injected error propagated at exact point");}
  check(ctx.status==="VALIDATED"&&ctx.metrics.size===1&&
    ctx.branchTrace.join(",")==="BOOTSTRAP_VALIDATE"&&qs[0]!.visible.length===47,
    "fault leaves outer state and caller inputs unchanged");
  faults++;
 }finally{
  LegacyPositiveOnlyGateQuestionAdapter.prototype.oldQuestionDay=oldFn;
  Patch14WideChoiceDispatcher.prototype.dispatch=dispatchFn;
 }
 const retried=handler.run(ctx,-2n,qs);
 check(retried.historicalGateDay===discoverLegacyPositiveGate(-2n,qs).historicalGateDay,
   "same-context deterministic retry");
}
const a=discoverLegacyPositiveGate(-1n,questions(1)),
      b=discoverLegacyPositiveGate(-1n,questions(1));
a.context.metrics.set("private",23n);a.context.logs.push("डावा");
check(a.context!==b.context&&a.gaps!==b.gaps&&
 a.gaps[0]!==b.gaps[0]&&!b.context.metrics.has("private")&&b.context.logs.length===0,
 "reentrancy isolation");
check(rejects(()=>calendarDateSpaghetti(F,F),MonsterStageError),"Stage54 calendar barrier");
console.log("STAGE_30_DISCOVERY_15_GUARDS_PASS signed="+signed+
 " positive="+positive+" negative="+negative+" oldWrong="+wrong+
 " oldMatches="+good+" actualQuestions="+questionsRun+" sharedWrites="+writes+
 " oldMethodCalls="+physicalOld+" dispatchCalls="+physicalDispatch+
 " injectedFailures="+faults);
