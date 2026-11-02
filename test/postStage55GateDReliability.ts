import {calendarDateSpaghetti} from "../src/postStage55FinalDate.ts";
import {Patch14WideChoiceDispatcher} from "../src/patch14WideChoice.ts";
import {NormativeOracle} from "./normativeOracle.ts";

// Gate D supplementary contract: the public API must be repeatable across
// independent physical Native executions, cross an exact signed year gate,
// propagate a deliberately injected deep predecessor fault, and permit a
// clean subsequent call. It does not claim that private owner rollback is
// observable from the public API; that is verified in earlier Stage tests.
function ok(condition:boolean,message:string):void {
  if(!condition)throw new Error("GATE_D_RELIABILITY: "+message);
}
function sameFive(a:readonly (bigint|string)[],b:readonly (bigint|string)[]):boolean {
  return a.length===5&&b.length===5&&a.every((v,i)=>v===b[i]);
}
const oracle=new NormativeOracle();
const c=oracle.gateDay(1n)+1n;
const current=oracle.year5000(c);
const close=current.closeGateDay;
const after=close+1n;
const successor=oracle.findTargetYear(c,after);
ok(successor.number===current.number+1n&&
   successor.openGateDay===close,
   "independent oracle resolves the adjacent year at the signed gate");

const last=calendarDateSpaghetti(c,close);
const first=calendarDateSpaghetti(c,after);
ok(Object.isFrozen(last)&&Object.isFrozen(first)&&
   Object.keys(last).length===5&&Object.keys(first).length===5,
   "two boundary tuples are immutable and contain exactly five fields");
ok(last[0]===current.number&&first[0]===successor.number&&
   first[2]===1n&&first[4]===1n,
   "last day / successor first day agree with independent year oracle and ordinals");

const replay=calendarDateSpaghetti(c,close);
ok(sameFive(last,replay)&&Object.isFrozen(replay)&&last!==replay,
   "fresh public Native replay is identical but does not reuse output identity");

const originalDispatch=Patch14WideChoiceDispatcher.prototype.dispatch;
const marker="GATE_D_PUBLIC_DEEP_PREDECESSOR_FAULT";
let injected=false;
let propagated=false;
try {
  Patch14WideChoiceDispatcher.prototype.dispatch=function(
    ...args:Parameters<typeof originalDispatch>
  ) {
    if(!injected){
      injected=true;
      throw new Error(marker);
    }
    return originalDispatch.apply(this,args);
  };
  try {
    calendarDateSpaghetti(c,close);
  }catch(error){
    propagated=error instanceof Error&&error.message===marker;
  }
}finally{
  Patch14WideChoiceDispatcher.prototype.dispatch=originalDispatch;
}
ok(injected&&propagated,
   "injected deep Native predecessor error must propagate through public API");

const recovered=calendarDateSpaghetti(c,close);
ok(sameFive(last,recovered)&&Object.isFrozen(recovered)&&
   last!==recovered&&replay!==recovered,
   "clean call after failure is repeatable, frozen, and independently allocated");
console.log("POST_STAGE55_GATE_D_RELIABILITY_PASS boundaryPairs=1"+
  " successfulPublicCalls=4 replayComparisons=10 deepFaultInjected=1"+
  " deepFaultPropagated=1 cleanRetry=1 freshOutputObjects=3");
