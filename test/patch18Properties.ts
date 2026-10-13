import {
  Patch18OneYearWalker,Patch18VerifiedGateWindowBuilder,
  Patch14WideChoiceDispatcher,MonsterValidationError
} from "../src/index.ts";
import {FOUNDATION_DAY as F,STONES,NormativeOracle,workCounts,
 buildHiddenDrops,buildVisibleDrops,initialBowls} from "./normativeOracle.ts";
function check(x:boolean,msg:string):void{if(!x)throw Error(msg);}
function source(c:bigint,t:bigint){
 const w=workCounts(c,t);return {
  visible:buildVisibleDrops(w,STONES,buildHiddenDrops(w,STONES)),
  stones:STONES,startBowls:initialBowls(w),
  targetDay:t
 };
}
const oracle=new NormativeOracle();
type Year={number:bigint;openGateIndex:bigint;closeGateIndex:bigint;openGateDay:bigint;closeGateDay:bigint};
const calculations=[oracle.gateDay(1n)+1n,oracle.gateDay(-1n)+1n,
 oracle.gateDay(2n)+1n,oracle.gateDay(-2n)+1n];
const benchmarks=calculations.map(c=>{
 const seed=oracle.year5000(c),n1=oracle.nextYear(c,seed),
  n2=oracle.nextYear(c,n1),n3=oracle.nextYear(c,n2),
  p1=oracle.previousYear(c,seed),p2=oracle.previousYear(c,p1),
  p3=oracle.previousYear(c,p2);
 return {c,seed,n1,n2,n3,p1,p2,p3};
});
let maximum=F,minimum=F;
for(const b of benchmarks){
 const hi=[b.c+5779n,b.seed.closeGateDay+5779n,
  b.n1.closeGateDay+5779n,b.n2.closeGateDay+5779n].reduce((a,v)=>v>a?v:a);
 const lo=[b.c-5779n,b.seed.openGateDay-5779n,
  b.p1.openGateDay-5779n,b.p2.openGateDay-5779n].reduce((a,v)=>v<a?v:a);
 if(hi>maximum)maximum=hi;
 if(lo<minimum)minimum=lo;
}
let plusCount=1,minusCount=1;
while(oracle.gateDay(BigInt(plusCount))<=maximum){
 plusCount++;check(plusCount<=128,"bounded positive gate window");
}
while(oracle.gateDay(-BigInt(minusCount))>=minimum){
 minusCount++;check(minusCount<=128,"bounded negative gate window");
}
const positive=Array.from({length:plusCount},(_,i)=>source(F,F+BigInt(i+1)));
const negative=Array.from({length:minusCount},(_,i)=>source(F,F-BigInt(i+1)));
const verified=new Patch18VerifiedGateWindowBuilder().build(positive,negative);
let gateWrong=0;
for(let n=-minusCount;n<=plusCount;n++){
 const v=verified.byIndex.get(BigInt(n));
 if(v!==oracle.gateDay(BigInt(n)))gateWrong++;
}
check(gateWrong===0&&verified.realGapQuestions===plusCount+minusCount,
 "every physical production signed gate equals independent oracle");
const walker=new Patch18OneYearWalker(),seen=new Set<object>();
let cases=0,zero=0,forward=0,backward=0,steps=0;
let yearWrong=0,seedWrong=0,rankFaults=0,badContinuity=0;
let fullProducers=0,sharedWrites=0,oldPredicateCalls=0;
let seals11=0,seals12=0;
function equal(actual:Year,expected:Year):boolean{
 return actual.number===expected.number&&
  actual.openGateIndex===expected.openGateIndex&&
  actual.closeGateIndex===expected.closeGateIndex&&
  actual.openGateDay===expected.openGateDay&&
  actual.closeGateDay===expected.closeGateDay;
}
for(const b of benchmarks){
 const targets=[
  {day:b.seed.openGateDay+1n,expected:b.seed,want:0},
  {day:b.seed.closeGateDay,expected:b.seed,want:0},
  {day:b.seed.openGateDay,expected:b.p1,want:1},
  {day:b.n1.closeGateDay,expected:b.n1,want:1},
  {day:b.n2.closeGateDay,expected:b.n2,want:2},
  {day:b.n3.closeGateDay,expected:b.n3,want:3},
  {day:b.p1.openGateDay+1n,expected:b.p1,want:1},
  {day:b.p2.openGateDay+1n,expected:b.p2,want:2},
  {day:b.p3.openGateDay+1n,expected:b.p3,want:3}
 ];
 for(const data of targets){
  const seenBefore=seen.size;
  const out=walker.walk(b.c,data.day,positive,negative,
   source(b.c,b.c),(c,t)=>source(c,t),data.want);
  if(!equal(out.seed,b.seed))seedWrong++;
  if(!equal(out.selected,data.expected))yearWrong++;
  if(out.steps.length!==data.want)rankFaults++;
  for(const x of out.steps){
   if((x.direction==="NEXT"?(x.before.closeGateIndex!==x.after.openGateIndex||
      x.before.closeGateDay!==x.after.openGateDay):
      (x.before.openGateIndex!==x.after.closeGateIndex||
       x.before.openGateDay!==x.after.closeGateDay))||
      x.after.number!==x.before.number+(x.direction==="NEXT"?1n:-1n))
     badContinuity++;
   if(x.direction==="NEXT")seals11++;else seals12++;
   if(x.correctedRank!==x.realSelector.correctedRank||
      x.correctedFamilySize!==Number(x.realSelector.familySize)||
      x.realSelector.predecessorSharedWrites!==58)
     rankFaults++;
   oldPredicateCalls+=x.oldPredicateCalls;
  }
  if(out.seedSelector.predecessorSharedWrites!==58||
   out.realPredecessorCount!==verified.realGapQuestions+1+data.want||
   out.realPredecessorWrites!==BigInt(out.realPredecessorCount)*58n||
   out.targetContained!==true||out.legacyGuessUsedForNavigation!==false||
   out.gateProvenance!=="PHYSICALLY_RECOMPUTED_SIGNED_GATES"||
   seenBefore!==seen.size||!Object.isFrozen(out.steps))
   rankFaults++;
  seen.add(out);cases++;steps+=data.want;
  fullProducers+=out.realPredecessorCount;
  sharedWrites+=Number(out.realPredecessorWrites);
  if(data.want===0)zero++;else if(data.expected.number>5000n)forward++;else backward++;
 }
}
check(cases===36&&zero===8&&forward===12&&backward===16&&
 steps===52&&seedWrong===0&&yearWrong===0&&rankFaults===0&&
 badContinuity===0&&seen.size===36&&
 seals11===24&&seals12===28&&sharedWrites===fullProducers*58,
 "36 real four-calculation action-based year walks, every step and seal grounded");
const old=Patch14WideChoiceDispatcher.prototype.dispatch;
let actualCalls=0;
try{
 Patch14WideChoiceDispatcher.prototype.dispatch=function(...args){
  actualCalls++;return old.apply(this,args);
 };
 const b=benchmarks[0]!;
 const out=walker.walk(b.c,b.n1.closeGateDay,positive,negative,
  source(b.c,b.c),(c,t)=>source(c,t),1);
 check(actualCalls===out.realPredecessorCount&&
   out.steps[0]!.realSelector.seal===11n,
  "one physical Stage29 historical/corrected selector per signed gate and year step");
}finally{Patch14WideChoiceDispatcher.prototype.dispatch=old;}
let insufficient=0;
try{
 const b=benchmarks[0]!;
 walker.walk(b.c,b.n3.closeGateDay,positive,negative,
  source(b.c,b.c),(c,t)=>source(c,t),2);
}catch(e){if(e instanceof MonsterValidationError)insufficient++;}
check(insufficient===1,"too-few steps fails explicitly without a guessed year");
console.log("STAGE_37_PATCH_18_PROPERTIES_PASS calculations="+benchmarks.length+
 " realGateQuestions="+verified.realGapQuestions+
 " gateWrong="+gateWrong+" walkCases="+cases+" zeroSteps="+zero+
 " forwardCases="+forward+" backwardCases="+backward+
 " steps="+steps+" seal11="+seals11+" seal12="+seals12+
 " seedWrong="+seedWrong+" yearWrong="+yearWrong+
 " rankWrong="+rankFaults+" continuityWrong="+badContinuity+
 " fullPredecessors="+fullProducers+" fullWrites="+sharedWrites+
 " originalPredicateCalls="+oldPredicateCalls+
 " physicalDispatcherSpy="+actualCalls+" explicitBudgetFailure="+insufficient);
