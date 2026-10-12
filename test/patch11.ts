import {
  bootstrapMonster,createMonsterContext,Patch11Drop46LatchAdapter,
  Patch11OrderLatchHandler,patch11OrderLatch,discoverLegacyOrderMemory,
  LegacySharedOrderMemoryAdapter,MonsterStageError,MonsterValidationError,
  calendarDateSpaghetti
} from "../src/index.ts";
import { FOUNDATION_DAY as F,STONES,workCounts,buildHiddenDrops,
  buildVisibleDrops,initialBowls,applyVisibleDropsToBowls,sauce,postStir12
} from "./normativeOracle.ts";
function check(ok:boolean,why:string):void{if(!ok)throw Error(why);}
function rejects(f:()=>unknown,Cls:typeof MonsterStageError|typeof MonsterValidationError):boolean{
  try{f();}catch(e){return e instanceof Cls;}return false;
}
function fixture(c:bigint,t:bigint){
  const counts=workCounts(c,t),hidden=buildHiddenDrops(counts,STONES);
  return {visible:buildVisibleDrops(counts,STONES,hidden),start:initialBowls(counts)};
}
const pairs:readonly (readonly [bigint,bigint])[]=[
 [F,F],[F-1n,F],[F+1n,F],[F,F-1n],[F,F+1n],
 [F-89n,F+273n],[F+273n,F-89n],[-278522n,-278522n],
 [-278522n,-268522n],[1n,1n],[100000n,-100000n],[-100000n,100000n]
];
const contexts=new Set<object>();
let cases=0,cells=0,correctedMisses=0,oldMisses=0,oldMatches=0,threeWrong=0;
for(const [c,t] of pairs){
  const {visible,start}=fixture(c,t),input=[...start];
  const result=patch11OrderLatch(c,t,visible,STONES,start);
  const oracle=applyVisibleDropsToBowls(
    [...start] as [bigint,bigint,bigint,bigint,bigint,bigint],visible,STONES);
  const oracleFull=sauce(c,t);
  const afterStirs=postStir12(
    [...oracle.bowls] as [bigint,bigint,bigint,bigint,bigint,bigint]);
  cases++;
  check(result.sharedMemoryWrites===58&&result.latchWriteIndex===46&&
    result.latchCaptures===1&&result.correctedQueryReads===1&&
    result.legacyQueryReads===1&&result.drops===46&&result.postStirs===12,
    "one latch at actual DROP46 and all 58 historical writes");
  check(result.historical.memoryWrites===58&&result.historical.queryReads===1&&
    result.historical.latestSource==="STIR_12"&&
    result.ledger.length===58&&
    result.ledger[45]!.source==="DROP_46"&&
    result.ledger[57]!.source==="STIR_12"&&
    result.legacyQueryOrder.join(",")===result.ledger[57]!.order.join(","),
    "historical 58 writes and STIR_12 query preserved verbatim");
  check(result.orderAt46Latch.join(",")===result.ledger[45]!.order.join(",")&&
    result.correctedQueryOrder.join(",")===oracle.orderAtDrop46.join(",")&&
    result.correctedQueryOrder.join(",")===oracleFull.orderAtDrop46.join(","),
    "latch agrees with actual DROP46 and independent reference");
  check(result.orderAt46Latch!==result.ledger[45]!.order&&
    result.correctedQueryOrder!==result.orderAt46Latch&&
    result.correctedQueryOrder!==result.legacyQueryOrder&&
    Object.isFrozen(result.orderAt46Latch)&&Object.isFrozen(result.correctedQueryOrder)&&
    Object.isFrozen(result)&&Object.isFrozen(result.ledger),
    "independently frozen latch and query without alias to legacy memory/ledger");
  check(result.afterDropBowls.every((v,j)=>v===oracle.bowls[j])&&
    result.finalBowls.every((v,j)=>v===afterStirs[j]&&v===oracleFull.bowls[j])&&
    start.every((v,j)=>v===input[j]),"all bowl results unchanged, external caller untouched");
  check(!contexts.has(result.context)&&result.context.phase==="READY"&&
    result.context.status==="PATCH_11_APPLIED"&&
    result.context!==result.historical.context&&
    result.context.branchTrace.join(",")=== [
      "BOOTSTRAP_VALIDATE","PATCH_11_REAL_46_DROP_ROUNDS",
      "PATCH_11_LATCH_ONCE_AFTER_DROP_46",
      "PATCH_11_PRESERVE_12_POST_STIR_OVERWRITES",
      "PATCH_11_CORRECTED_QUERY_FROM_INDEPENDENT_LATCH"
    ].join(",")&&
    result.context.metrics.get("patch11.calls")===1n&&
    result.context.metrics.get("patch11.latch_writes")===1n&&
    result.context.metrics.get("patch11.semantic_queries")===1n&&
    result.context.metrics.get("patch11.legacy_queries")===1n&&
    result.context.metrics.get("patch11.shared_memory_writes")===58n&&
    result.context.metrics.get("patch11.drop_rounds")===46n&&
    result.context.metrics.get("patch11.post_stirs")===12n,
    "independent outer/inner contexts, trace and exact metrics");
  contexts.add(result.context);
  let fullWrong=true;
  for(const pos of [1,2,6]){
    cells++;
    if(result.correctedQueryOrder[pos-1]!==oracle.orderAtDrop46[pos-1])correctedMisses++;
    if(result.legacyQueryOrder[pos-1]!==oracle.orderAtDrop46[pos-1])oldMisses++;
    else{oldMatches++;fullWrong=false;}
  }
  if(fullWrong)threeWrong++;
}
check(cases===12&&cells===36&&correctedMisses===0&&
  oldMisses===32&&oldMatches===4&&threeWrong>0&&contexts.size===12,
  "repair all real positions while retaining 32 historical wrong / 4 coincidence");

// Adapter itself: no query before latch, precisely one capture, detached clones.
const latch=new Patch11Drop46LatchAdapter();
check(rejects(()=>latch.queryOrder(),MonsterStageError),"uninitialized latch blocks query");
for(const n of [0,45,47,58]){
  check(rejects(()=>latch.captureAfterWrite(n,[1,2,3,4,5,6]),
    MonsterValidationError),"latch must be after write 46 and nowhere else");
}
for(const p of [[1,2,3],[1,2,3,4,5,5],[1,2,3,4,5,7]]){
  check(rejects(()=>latch.captureAfterWrite(46,p),MonsterValidationError),
    "latch only valid permutation");
}
const mutable=[1,2,3,4,5,6];latch.captureAfterWrite(46,mutable);
mutable.reverse();
const one=latch.queryOrder(),two=latch.queryOrder();
check(latch.captures===1&&latch.queries===2&&latch.latchOrder!==mutable&&
  latch.latchOrder!==one&&one!==two&&one.join(",")==="1,2,3,4,5,6"&&
  two.join(",")==="1,2,3,4,5,6"&&
  Object.isFrozen(one)&&Object.isFrozen(two)&&Object.isFrozen(latch.latchOrder),
  "latch saved once, caller mutation and repeated queries cannot alias");
check(rejects(()=>latch.captureAfterWrite(46,[6,5,4,3,2,1]),MonsterValidationError),
  "second overwrite cannot replace the orderAt46 latch");

// Real historical Stage22 write method must be invoked by corrected Stage23,
// not synthesized by a test-only reference.
const oldWrite=LegacySharedOrderMemoryAdapter.prototype.write;
let writeCalls=0;const memoryObjects=new Set<object>();
try{
 LegacySharedOrderMemoryAdapter.prototype.write=function(...args){
   writeCalls++;memoryObjects.add(this);
   return oldWrite.apply(this,args);
 };
 const f=fixture(F,F);
 const result=patch11OrderLatch(F,F,f.visible,STONES,f.start);
 check(writeCalls===58&&memoryObjects.size===1&&
   result.sharedMemoryWrites===58&&result.historical.memoryWrites===58,
   "actual unchanged legacy write called 58 times on same memory");
}finally{LegacySharedOrderMemoryAdapter.prototype.write=oldWrite;}

// Invalid inputs must leave provided context and caller arrays untouched.
const f=fixture(F,F),ctx=createMonsterContext(F,F);
const handler=new Patch11OrderLatchHandler();
check(rejects(()=>handler.run(ctx,f.visible,STONES,f.start),MonsterStageError)&&
  ctx.status==="NEW"&&ctx.metrics.size===0&&!ctx.branchTrace.length,
  "unready caller context unchanged");
const ready=bootstrapMonster(F,F);
for(const bad of [[],[1n],Object.assign(new Array<bigint>(47),{1:1n})])
  check(rejects(()=>handler.run(ready,bad,STONES,f.start),MonsterValidationError),
    "invalid visible drops");
for(const st of [[],STONES.slice(0,46),STONES.map((v,k)=>k===11?[1n]:v)])
  check(rejects(()=>handler.run(ready,f.visible,st,f.start),MonsterValidationError),
    "invalid stones");
for(const b of [[1n],[1n,2n,3n,4n,5n,0 as unknown as bigint]])
  check(rejects(()=>handler.run(ready,f.visible,STONES,b),MonsterValidationError),
    "invalid bowl array");
check(rejects(()=>handler.run({...ready,calculationDay:null as unknown as bigint},
  f.visible,STONES,f.start),MonsterValidationError)&&
  ready.status==="VALIDATED"&&ready.metrics.size===1&&
  ready.branchTrace.join(",")==="BOOTSTRAP_VALIDATE","preflight has no effects");
handler.run(ready,f.visible,STONES,f.start);
check(rejects(()=>handler.run(ready,f.visible,STONES,f.start),MonsterStageError),
  "context cannot be reused");

// Inject interruptions both before and after DROP46 latch, with all caller state
// and context intact; retry the exact same context deterministically.
let faults=0;
for(const at of [1,45,46,47,52,58]){
  const faultContext=bootstrapMonster(F,F),caller=[...f.start];
  let seen=0;
  const broken=new Patch11OrderLatchHandler(n=>{
    seen++;if(n===at)throw new Error("STAGE_23_INJECTED_FAILURE");
  });
  try{broken.run(faultContext,f.visible,STONES,caller);
    throw new Error("injection never fired");
  }catch(e){
    check(e instanceof Error&&e.message==="STAGE_23_INJECTED_FAILURE",
      "original failure propagated without a partial commit");
  }
  check(seen===at&&faultContext.status==="VALIDATED"&&
    faultContext.metrics.size===1&&
    faultContext.branchTrace.join(",")==="BOOTSTRAP_VALIDATE"&&
    caller.every((v,j)=>v===f.start[j]),"no owner state leaked across injected failure");
  const recovered=handler.run(faultContext,f.visible,STONES,caller);
  const canonical=sauce(F,F);
  check(recovered.correctedQueryOrder.join(",")===canonical.orderAtDrop46.join(",")&&
    recovered.sharedMemoryWrites===58,"retry gives the deterministic canonical order");
  faults++;
}
check(faults===6,"all latch-adjacent and final-stage fail points verified");
const left=patch11OrderLatch(F,F,f.visible,STONES,f.start);
const right=patch11OrderLatch(F,F,f.visible,STONES,f.start);
left.context.logs.push("पहिला");left.context.metrics.set("private",101n);
check(left.context!==right.context&&left.orderAt46Latch!==right.orderAt46Latch&&
  left.ledger!==right.ledger&&!right.context.metrics.has("private")&&
  !right.context.logs.length,"per-call independent ownership");
check(rejects(()=>calendarDateSpaghetti(F,F),MonsterStageError),
  "final calendar route still unavailable until Stage54");
console.log(`STAGE_23_PATCH_11_GUARDS_PASS pairs=${cases} cells=${cells} mismatches=${correctedMisses} oldWrong=${oldMisses} oldMatches=${oldMatches} latchWrites=1 latchAt=46 sharedWrites=58 legacyCalls=${writeCalls} injectedFailures=${faults}`);
