import {
  Patch18VerifiedGateWindowBuilder,Patch18OneYearWalker,Patch18YearWalkHandler,
  patch18WalkYear,Legacy365JumpGuessAdapter,Patch14WideChoiceDispatcher,
  bootstrapMonster,createMonsterContext,MonsterStageError,MonsterValidationError,
  calendarDateSpaghetti
} from "../src/index.ts";
import {
  FOUNDATION_DAY as F,STONES,NormativeOracle,workCounts,
  buildHiddenDrops,buildVisibleDrops,initialBowls
} from "./normativeOracle.ts";
function check(ok:boolean,msg:string):void{if(!ok)throw Error(msg);}
function rejects(fn:()=>unknown,cls:typeof MonsterValidationError|typeof MonsterStageError):boolean{
 try{fn();}catch(e){return e instanceof cls;}return false;
}
function raw(c:bigint,t:bigint){
 const w=workCounts(c,t);return {
  visible:buildVisibleDrops(w,STONES,buildHiddenDrops(w,STONES)),
  stones:STONES,startBowls:initialBowls(w)
 };
}
function question(c:bigint,t:bigint){return {...raw(c,t),targetDay:t};}
const oracle=new NormativeOracle();
const g=oracle.gateDay(1n),c=g+1n;
const seed=oracle.year5000(c),next1=oracle.nextYear(c,seed),
 next2=oracle.nextYear(c,next1),prev1=oracle.previousYear(c,seed),
 prev2=oracle.previousYear(c,prev1);
const neededMax=[c+5779n,seed.closeGateDay+5779n,next1.closeGateDay+5779n].reduce((a,b)=>a>b?a:b);
const neededMin=[c-5779n,seed.openGateDay-5779n,prev1.openGateDay-5779n].reduce((a,b)=>a<b?a:b);
let positiveCount=1,negativeCount=1;
while(oracle.gateDay(BigInt(positiveCount))<=neededMax){positiveCount++;check(positiveCount<=96,"positive gate budget");}
while(oracle.gateDay(-BigInt(negativeCount))>=neededMin){negativeCount++;check(negativeCount<=96,"negative gate budget");}
const plus=Array.from({length:positiveCount},(_,i)=>question(F,F+BigInt(i+1)));
const minus=Array.from({length:negativeCount},(_,i)=>question(F,F-BigInt(i+1)));
const window=new Patch18VerifiedGateWindowBuilder().build(plus,minus);
for(let i=-negativeCount;i<=positiveCount;i++){
 check(window.byIndex.get(BigInt(i))===oracle.gateDay(BigInt(i)),
  "each actual gate from production Sauce rank equals independent oracle");
}
check(window.realGapQuestions===positiveCount+negativeCount&&
 window.realPredecessorWrites===BigInt(window.realGapQuestions)*58n&&
 window.provenance==="PHYSICALLY_RECOMPUTED_SIGNED_GATES"&&
 window.minimumDay===oracle.gateDay(-BigInt(negativeCount))&&
 window.maximumDay===oracle.gateDay(BigInt(positiveCount))&&
 typeof (window.byIndex as unknown as {set?:unknown}).set==="undefined",
 "complete readonly native computed signed gate ledger");

const hist=[raw(F,F+1n)],signed=[{...raw(F,F+1n),targetDay:F+1n}];
const oldYear=raw(c,c);
const fakeSeed=[{openGateIndex:1n,closeGateIndex:7n,
 openGateDay:g,closeGateDay:g+800n}];
const fakeTie=[
 {openGateIndex:1n,closeGateIndex:7n,
  openGateDay:g,closeGateDay:g+1000n},
 {openGateIndex:0n,closeGateIndex:6n,
  openGateDay:g-100n,closeGateDay:g+900n}
];
const trueYear=question(c,c);
const transition=(calc:bigint,day:bigint,seal:11n|12n)=>{
 check(calc===c&&(seal===11n||seal===12n),"real transition question invocation");
 return question(calc,day);
};
function assertYear(actual:Readonly<{number:bigint;openGateIndex:bigint;closeGateIndex:bigint;openGateDay:bigint;closeGateDay:bigint}>,
 expected:typeof seed,msg:string):void{
 check(actual.number===expected.number&&
   actual.openGateIndex===expected.openGateIndex&&
   actual.closeGateIndex===expected.closeGateIndex&&
   actual.openGateDay===expected.openGateDay&&
   actual.closeGateDay===expected.closeGateDay,msg);
}
const forward=patch18WalkYear(c,next2.closeGateDay,1n,hist,signed,
 oldYear,fakeSeed,fakeTie,plus,minus,trueYear,transition,2);
assertYear(forward.authoritative.seed,seed,"full true Year5000 is genuinely selected");
assertYear(forward.authoritativeYear,next2,"2 real SEAL11 one-year steps");
check(forward.authoritative.forwardSteps===2&&
 forward.authoritative.backwardSteps===0&&
 forward.authoritative.steps.length===2&&
 forward.authoritative.steps.every((x,i)=>x.direction==="NEXT"&&
  x.seal===11n&&x.questionTargetDay===(i===0?seed.closeGateDay:next1.closeGateDay)&&
  x.correctedFamilySize>0&&x.realSelector.seal===11n&&
  x.realSelector.predecessorSharedWrites===58)&&
 forward.authoritative.legacyGuessUsedForNavigation===false&&
 forward.authoritative.gateProvenance==="PHYSICALLY_RECOMPUTED_SIGNED_GATES"&&
 forward.legacy.guess.role==="TELEMETRY_ONLY"&&
 forward.originalSyntheticYearNotUsed===true&&
 forward.authoritative.realGateQuestionCalls===positiveCount+negativeCount&&
 forward.authoritative.realYearQuestionCalls===3&&
 forward.authoritative.realPredecessorCount===positiveCount+negativeCount+3&&
 forward.predecessorSharedWrites===BigInt(forward.predecessorCallCount)*58n&&
 forward.context.status==="PATCH_18_APPLIED"&&
 Object.isFrozen(forward)&&Object.isFrozen(forward.authoritative)&&
 Object.isFrozen(forward.authoritative.steps),
 "genuine two-step forward trace, fully preserved Stage36 old 365 telemetry");
const backward=patch18WalkYear(c,prev2.openGateDay+1n,1n,hist,signed,
 oldYear,fakeSeed,fakeTie,plus,minus,trueYear,transition,2);
assertYear(backward.authoritative.seed,seed,"backward seed unaffected");
assertYear(backward.authoritativeYear,prev2,"2 real SEAL12 one-year steps");
check(backward.authoritative.forwardSteps===0&&
 backward.authoritative.backwardSteps===2&&
 backward.authoritative.steps.length===2&&
 backward.authoritative.steps.every((x,i)=>x.direction==="PREVIOUS"&&
  x.seal===12n&&x.questionTargetDay===(i===0?seed.openGateDay:prev1.openGateDay)&&
  x.correctedFamilySize>0&&x.realSelector.seal===12n&&
  x.realSelector.predecessorSharedWrites===58)&&
 backward.legacy.guess.role==="TELEMETRY_ONLY"&&
 backward.predecessorSharedWrites===BigInt(backward.predecessorCallCount)*58n,
 "genuine two-step backward trace using same true canonical Year5000");

const within=new Patch18OneYearWalker().walk(c,seed.closeGateDay,
 plus,minus,trueYear,transition,0);
assertYear(within.selected,seed,"close day inclusive at seed boundary");
check(within.steps.length===0&&within.realYearQuestionCalls===1,
 "target equal closing gate requires zero steps");
const firstDay=new Patch18OneYearWalker().walk(c,seed.openGateDay+1n,
 plus,minus,trueYear,transition,0);
assertYear(firstDay.selected,seed,"opening gate +1 is inside seed");
check(rejects(()=>new Patch18OneYearWalker().walk(c,seed.openGateDay,
 plus,minus,trueYear,transition,0),MonsterValidationError),
 "open gate exact day belongs to previous year; budget 0 must fail, not guess");

let ghostCalls=0;
const old=Legacy365JumpGuessAdapter.prototype.oldJumpGuess;
try{
 Legacy365JumpGuessAdapter.prototype.oldJumpGuess=function(...args){
  ghostCalls++;old.apply(this,args);return -9999999999999999n;
 };
 const noisy=patch18WalkYear(c,next1.closeGateDay,1n,hist,signed,
  oldYear,fakeSeed,fakeTie,plus,minus,trueYear,transition,1);
 assertYear(noisy.authoritativeYear,next1,
   "nonsense legacy guess cannot affect authoritative year");
 check(noisy.oldGuess===-9999999999999999n&&ghostCalls===1&&
   noisy.authoritative.forwardSteps===1,
  "physically called old method remained telemetry only");
}finally{Legacy365JumpGuessAdapter.prototype.oldJumpGuess=old;}

for(const invalid of [
 {positive:[],negative:minus},
 {positive:plus,negative:[]},
 {positive:[{...plus[0]!,targetDay:F+55n},...plus.slice(1)],negative:minus}
]){
 check(rejects(()=>new Patch18VerifiedGateWindowBuilder().build(
  invalid.positive,invalid.negative),MonsterValidationError),
  "missing or mismatched source question preflight rejected");
}
check(rejects(()=>new Patch18OneYearWalker().walk(c,next2.closeGateDay,
 plus,minus,trueYear,transition,1),MonsterValidationError),
 "explicit insufficient maximum-step budget never produces fabricated year");
check(rejects(()=>new Patch18OneYearWalker().walk(c,next2.closeGateDay,
 plus.slice(0,4),minus.slice(0,4),trueYear,transition,2),MonsterValidationError),
 "truncated gate window must refuse year computation");

const dispatch=Patch14WideChoiceDispatcher.prototype.dispatch;
const owner=new Patch18YearWalkHandler();
const badCtx=createMonsterContext(c,next1.closeGateDay);
check(rejects(()=>owner.run(badCtx,1n,hist,signed,oldYear,
 fakeSeed,fakeTie,plus,minus,trueYear,transition,1),MonsterStageError)&&
 badCtx.metrics.size===0,"not-READY owner blocked");
const live=bootstrapMonster(c,next1.closeGateDay);
let failure=0;
try{
 const broken=(calc:bigint,day:bigint,seal:11n|12n)=>{
  if(seal===11n)throw Error("PATCH18_TRANSITION_FAULT");
  return transition(calc,day,seal);
 };
 try{
  owner.run(live,1n,hist,signed,oldYear,
    fakeSeed,fakeTie,plus,minus,trueYear,broken,1);
  throw Error("fault not reached");
 }catch(e){check(e instanceof Error&&e.message==="PATCH18_TRANSITION_FAULT",
   "late transition callback error propagated");}
 check(live.status==="VALIDATED"&&live.branchTrace.join(",")==="BOOTSTRAP_VALIDATE"&&
  live.metrics.size===1,"transactional outer context rollback after full Stage36 + gates");
 failure++;
}finally{Patch14WideChoiceDispatcher.prototype.dispatch=dispatch;}
const retried=owner.run(live,1n,hist,signed,oldYear,
 fakeSeed,fakeTie,plus,minus,trueYear,transition,1);
assertYear(retried.authoritativeYear,next1,"same owner retries after late failure");
check(rejects(()=>owner.run(live,1n,hist,signed,oldYear,
 fakeSeed,fakeTie,plus,minus,trueYear,transition,1),MonsterStageError),
 "committed caller owner single use");

const other=patch18WalkYear(c,next1.closeGateDay,1n,hist,signed,
 oldYear,fakeSeed,fakeTie,plus,minus,trueYear,transition,1);
other.context.metrics.set("left",4n);
check(other.context!==retried.context&&
 !retried.context.metrics.has("left")&&
 other.authoritative!==retried.authoritative&&
 other.legacy!==retried.legacy&&
 other.authoritative.steps[0]!.after!==retried.authoritative.steps[0]!.after,
 "fresh instance owns independent mutable contexts and snapshot steps");
check(rejects(()=>calendarDateSpaghetti(F,F),MonsterStageError),
 "Stage54 calendar route remains unopened");
console.log("STAGE_37_PATCH_18_GUARDS_PASS positiveGates="+positiveCount+
 " negativeGates="+negativeCount+" verifiedGates="+window.realGapQuestions+
 " seedOpen="+seed.openGateIndex+" seedClose="+seed.closeGateIndex+
 " forwardSteps="+forward.authoritative.forwardSteps+
 " backwardSteps="+backward.authoritative.backwardSteps+
 " ghostActualCalls="+ghostCalls+
 " budgetFaults=2 transitionFaults="+failure+
 " gateSharedWrites="+window.realPredecessorWrites+
 " forwardFullCalls="+forward.predecessorCallCount+
 " backwardFullCalls="+backward.predecessorCallCount+
 " referenceMismatches=0");
