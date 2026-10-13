import {
  LEGACY_JUMP_AVERAGE_DAYS,YEAR_5000_ANCHOR_NUMBER,
  legacyFloorDivPositive,Legacy365JumpGuessAdapter,Legacy365JumpDiagnostic,
  Discovery18JumpHandler,discoverLegacyJumpGuess,
  LegacyYearMaxEligibilityAdapter,Patch14WideChoiceDispatcher,
  createMonsterContext,bootstrapMonster,
  MonsterStageError,MonsterValidationError,calendarDateSpaghetti
} from "../src/index.ts";
import {
  FOUNDATION_DAY as F,STONES,NormativeOracle,
  workCounts,buildHiddenDrops,buildVisibleDrops,initialBowls,
  sauce,askBowl,chooseRank
} from "./normativeOracle.ts";
function check(b:boolean,m:string):void{if(!b)throw Error(m);}
function rejects(fn:()=>unknown,type:typeof MonsterStageError|typeof MonsterValidationError):boolean{
 try{fn();}catch(e){return e instanceof type;}return false;
}
function source(c:bigint,t:bigint){
 const w=workCounts(c,t);
 return {visible:buildVisibleDrops(w,STONES,buildHiddenDrops(w,STONES)),
  stones:STONES,startBowls:initialBowls(w)};
}
const oracle=new NormativeOracle();
function fixture(index:bigint){
 const gate=oracle.gateDay(index),day=gate+1n;
 const sign=index<0n?-1n:1n,n=Number(index<0n?-index:index);
 return {index,gate,day,
  old:Array.from({length:n},(_,j)=>source(F,F+BigInt(j+1))),
  signed:Array.from({length:n},(_,j)=>({
   ...source(F,F+sign*BigInt(j+1)),targetDay:F+sign*BigInt(j+1)
  })),
  year:source(day,day),
  anchor:[{openGateIndex:index,closeGateIndex:index+6n,
   openGateDay:gate,closeGateDay:gate+800n}],
  tie:[
   {openGateIndex:index,closeGateIndex:index+6n,
    openGateDay:gate,closeGateDay:gate+1000n},
   {openGateIndex:index-1n,closeGateIndex:index+6n,
    openGateDay:gate-100n,closeGateDay:gate+900n}
  ]};
}
const adapter=new Legacy365JumpGuessAdapter(),diag=new Legacy365JumpDiagnostic();
check(LEGACY_JUMP_AVERAGE_DAYS===365n&&YEAR_5000_ANCHOR_NUMBER===5000n,
 "historical 365-day divisor and year5000 number unchanged");
const fixed=Object.freeze({number:5000n,firstDay:1000n,lastDay:1999n});
const exact:[bigint,bigint][]=[
 [-731n,4997n],[-730n,4998n],[-366n,4998n],
 [-365n,4999n],[-364n,4999n],[-1n,4999n],
 [0n,5000n],[1n,5000n],[364n,5000n],
 [365n,5001n],[729n,5001n],[730n,5002n],
 [999n,5002n],[1000n,5002n]
];
for(const [delta,expected] of exact){
 const out=diag.measure(fixed,fixed.firstDay+delta);
 check(out.estimatedYearNumber===expected&&
  out.quotientBy365===expected-5000n&&
  out.signedDeltaDays===delta&&
  out.oldJumpGuessCalls===1&&
  out.authoritativeTraversalPerformed===false&&
  out.authoritativeTargetYearResolved===false&&
  out.role==="TELEMETRY_ONLY"&&Object.isFrozen(out)&&
  Object.isFrozen(out.anchor)&&out.anchor!==fixed,
  "genuine floor for signed ±365 boundaries, no authoritative guess");
}
check(diag.measure(fixed,1999n).knownAnchorMismatch===true&&
 diag.measure(fixed,1000n).knownAnchorMismatch===false&&
 diag.measure(fixed,999n).knownAnchorMismatch===null&&
 diag.measure(fixed,2000n).knownAnchorMismatch===null,
 "only inside anchor can the true anchor number be used to flag wrong guess");
for(const [numer,denom] of [[1n,0n],[1n,-365n]]){
 check(rejects(()=>legacyFloorDivPositive(numer,denom),MonsterValidationError),
  "nonpositive divisor rejected");
}
for(const a of [null,{number:5000n,firstDay:4n,lastDay:3n},
 {number:5000,firstDay:0n,lastDay:2n}]){
 check(rejects(()=>adapter.oldJumpGuess(a as never,0n),MonsterValidationError),
  "old adapter validates historical year anchor");
}
check(rejects(()=>adapter.oldJumpGuess(fixed,"bad" as never),MonsterValidationError),
 "target must be bigint");
const giant=1n<<32768n;
const div=giant/365n;
check(adapter.oldJumpGuess(fixed,1000n+giant)===5000n+div&&
 adapter.oldJumpGuess(fixed,1000n-giant)===5000n-div-(giant%365n===0n?0n:1n),
 "unbounded bigint floor division both directions");

const contexts=new Set<object>();
let anchors=0,positive=0,negative=0,wrongInside=0,estimateWrong=0;
let realPred=0,realWrites=0,guessCalls=0,rankWrong=0;
for(const index of [1n,-1n,2n,-2n]){
 const x=fixture(index);
 // Stage35 physically selects a synthetic year candidate, but computes the
 // opening gate and seal10 rank from genuine normative question sources.
 const rank=chooseRank(askBowl(sauce(x.day,x.day),1,10n),2n);
 for(const choice of ["inside_end","backward"] as const){
  const selectedOpen=(rank===1n?x.gate-100n:x.gate);
  const selectedClose=selectedOpen+1000n;
  const firstDay=selectedOpen+1n;
  const target=choice==="inside_end"?selectedClose:firstDay-366n;
  const input=[...x.year.startBowls];
  const out=discoverLegacyJumpGuess(x.day,target,index,x.old,x.signed,
   x.year,x.anchor,x.tie);
  const expected=choice==="inside_end"?5002n:4998n;
  if(out.ghostYearNumber!==expected)estimateWrong++;
  if(out.preceding.correctedRank!==rank)rankWrong++;
  check(out.calculationDay===x.day&&out.targetDay===target&&
   out.anchorYearNumber===5000n&&
   out.anchorProvenance==="INJECTED_MULTI_OPENING_GATE_BOUNDARIES"&&
   out.selectedAnchor.number===5000n&&
   out.selectedAnchor.firstDay===firstDay&&
   out.selectedAnchor.lastDay===selectedClose&&
   out.guess.targetDay===target&&out.guess.estimatedYearNumber===expected&&
   out.guess.quotientBy365===(expected-5000n)&&
   out.guess.knownAnchorMismatch===(choice==="inside_end"?true:null)&&
   out.guess.role==="TELEMETRY_ONLY"&&
   !out.guess.authoritativeTraversalPerformed&&
   !out.guess.authoritativeTargetYearResolved&&
   !out.authoritativeTargetYearResolved&&
   out.genuineYearSelectionUnaffected&&
   out.preceding.correctedSelected.candidate.openGateDay===selectedOpen&&
   out.preceding.correctedSelected.candidate.closeGateDay===selectedClose&&
   out.preceding.correctedRank===rank&&
   out.predecessorCallCount===out.preceding.predecessorCallCount&&
   out.predecessorSharedWrites===out.preceding.predecessorSharedWrites&&
   out.context.status==="DISCOVERY_18_RECORDED"&&
   out.context.branchTrace.join(",")=== [
    "BOOTSTRAP_VALIDATE",
    "DISCOVERY_18_FULL_PATCH17_REAL_YEAR5000_SELECTION",
    "DISCOVERY_18_OLD_FLOOR_DIV_365_GUESS_ACTUALLY_INVOKED",
    "DISCOVERY_18_GHOST_TELEMETRY_NEVER_AUTHORITATIVE"
   ].join(",")&&
   out.context.metrics.get("discovery18.calls")===1n&&
   out.context.metrics.get("discovery18.old_jump_guess_calls")===1n&&
   out.context.metrics.get("discovery18.ghost_year_number")===expected&&
   out.context.metrics.get("discovery18.in_seed_mismatches")===
    (choice==="inside_end"?1n:0n)&&
   out.context.metrics.get("discovery18.predecessor_58_write_sequences")===
    BigInt(out.predecessorCallCount)&&
   !contexts.has(out.context)&&out.context!==out.preceding.context&&
   input.every((v,j)=>v===x.year.startBowls[j])&&
   Object.isFrozen(out)&&Object.isFrozen(out.guess)&&
   Object.isFrozen(out.selectedAnchor),
   "true signed gate/Stage35 producer unaffected by wrong 365 jump");
  contexts.add(out.context);
  if(choice==="inside_end")wrongInside++;
  realPred+=out.predecessorCallCount;
  realWrites+=Number(out.predecessorSharedWrites);
  guessCalls++;anchors++;
 }
 if(index>0n)positive++;else negative++;
}
check(anchors===8&&positive===2&&negative===2&&
 wrongInside===4&&rankWrong===0&&estimateWrong===0&&
 contexts.size===8&&realPred===42&&realWrites===2436&&guessCalls===8,
 "eight genuine signed-gate and real seal10 histories, telemetry isolated");

const f=fixture(-1n),handler=new Discovery18JumpHandler();
const unready=createMonsterContext(f.day,f.day);
check(rejects(()=>handler.run(unready,-1n,f.old,f.signed,f.year,
 f.anchor,f.tie),MonsterStageError)&&
 unready.branchTrace.length===0&&unready.metrics.size===0,
 "unready context rejected");
const owner=bootstrapMonster(f.day,f.day);
check(rejects(()=>handler.run(owner,0n,f.old,f.signed,f.year,
 f.anchor,f.tie),MonsterValidationError)&&
 owner.status==="VALIDATED"&&owner.metrics.size===1&&
 owner.branchTrace.join(",")==="BOOTSTRAP_VALIDATE",
 "invalid nonzero gate validation before old path");

const origGuess=Legacy365JumpGuessAdapter.prototype.oldJumpGuess;
const originalPredicate=LegacyYearMaxEligibilityAdapter.prototype.oldEligibleYear;
const originalDispatch=Patch14WideChoiceDispatcher.prototype.dispatch;
let physicalGuess=0,physicalSelector=0,physicalOldPredicate=0;
try{
 Legacy365JumpGuessAdapter.prototype.oldJumpGuess=function(...args){
  physicalGuess++;return origGuess.apply(this,args);
 };
 LegacyYearMaxEligibilityAdapter.prototype.oldEligibleYear=function(...args){
  physicalOldPredicate++;return originalPredicate.apply(this,args);
 };
 Patch14WideChoiceDispatcher.prototype.dispatch=function(...args){
  physicalSelector++;return originalDispatch.apply(this,args);
 };
 handler.run(owner,-1n,f.old,f.signed,f.year,f.anchor,f.tie);
 check(physicalGuess===1&&physicalOldPredicate===3&&physicalSelector===5,
  "old 365 guess, 5781 predicate and five full prior selector invocations physical");
}finally{
 Legacy365JumpGuessAdapter.prototype.oldJumpGuess=origGuess;
 LegacyYearMaxEligibilityAdapter.prototype.oldEligibleYear=originalPredicate;
 Patch14WideChoiceDispatcher.prototype.dispatch=originalDispatch;
}
check(rejects(()=>handler.run(owner,-1n,f.old,f.signed,f.year,
 f.anchor,f.tie),MonsterStageError),"committed context not repeatable");

let faults=0;
for(const fault of ["old_candidate","negative_gate","stage35_corrected_selection","ghost_jump"] as const){
 const c=bootstrapMonster(f.day,f.day);
 const marker="STAGE36_INJECT_"+fault;
 let invokes=0;
 try{
  if(fault==="old_candidate"){
   LegacyYearMaxEligibilityAdapter.prototype.oldEligibleYear=function(...args){
    invokes++;if(invokes===2)throw Error(marker);
    return originalPredicate.apply(this,args);
   };
  }else if(fault==="ghost_jump"){
   Legacy365JumpGuessAdapter.prototype.oldJumpGuess=function():never{
    throw Error(marker);
   };
  }else{
   Patch14WideChoiceDispatcher.prototype.dispatch=function(...args){
    invokes++;
    if(invokes===(fault==="negative_gate"?2:5))throw Error(marker);
    return originalDispatch.apply(this,args);
   };
  }
  try{
   handler.run(c,-1n,f.old,f.signed,f.year,f.anchor,f.tie);
   throw Error("missing injected failure");
  }catch(e){check(e instanceof Error&&e.message===marker,"real failure propagated");}
  check(c.status==="VALIDATED"&&c.metrics.size===1&&
   c.branchTrace.join(",")==="BOOTSTRAP_VALIDATE",
   "outer owner rollback includes failure of telemetry itself");
  faults++;
 }finally{
  LegacyYearMaxEligibilityAdapter.prototype.oldEligibleYear=originalPredicate;
  Legacy365JumpGuessAdapter.prototype.oldJumpGuess=origGuess;
  Patch14WideChoiceDispatcher.prototype.dispatch=originalDispatch;
 }
 check(handler.run(c,-1n,f.old,f.signed,f.year,f.anchor,f.tie).
  guess.oldJumpGuessCalls===1,"same-context retry after injected failure");
}
const isolatedA=discoverLegacyJumpGuess(f.day,f.day,-1n,f.old,f.signed,
 f.year,f.anchor,f.tie);
const isolatedB=discoverLegacyJumpGuess(f.day,f.day,-1n,f.old,f.signed,
 f.year,f.anchor,f.tie);
isolatedA.context.metrics.set("private",8n);
isolatedA.context.logs.push("x");
check(isolatedA.context!==isolatedB.context&&
 isolatedA.guess!==isolatedB.guess&&
 isolatedA.preceding!==isolatedB.preceding&&
 !isolatedB.context.metrics.has("private")&&isolatedB.context.logs.length===0,
 "reentrant semantics and independent diagnostic snapshots");
check(rejects(()=>calendarDateSpaghetti(F,F),MonsterStageError),
 "Stage54 integrated calendar still blocked");
console.log("STAGE_36_DISCOVERY_18_GUARDS_PASS boundaries="+exact.length+
 " signedAnchors="+anchors+" positive="+positive+" negative="+negative+
 " falseWithin="+wrongInside+" estimateWrong="+estimateWrong+
 " rankWrong="+rankWrong+" legacyCalls="+physicalGuess+
 " priorSelectorCalls="+physicalSelector+" originalPredicateCalls="+physicalOldPredicate+
 " truePredecessors="+realPred+" sharedWrites="+realWrites+
 " telemetryOnly="+guessCalls+" faultCases="+faults);
