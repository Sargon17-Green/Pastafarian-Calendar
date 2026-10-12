import {
  bootstrapMonster,createMonsterContext,LegacyNextBowlFixedNameAdapter,
  Discovery12FixedSuccessorHandler,discoverLegacyFixedNextBowl,
  patch11OrderLatch,MonsterValidationError,MonsterStageError,calendarDateSpaghetti
} from "../src/index.ts";
import {
  FOUNDATION_DAY as F,STONES,workCounts,buildHiddenDrops,
  buildVisibleDrops,initialBowls,applyVisibleDropsToBowls,sauce
} from "./normativeOracle.ts";
import { canonicalNextBowl } from "./discovery12Reference.ts";
function check(ok:boolean,why:string):void {if(!ok)throw Error(why);}
function rejects(f:()=>unknown,Type:typeof MonsterValidationError|typeof MonsterStageError):boolean{
  try{f();}catch(e){return e instanceof Type}return false;
}
const pairs:readonly (readonly [bigint,bigint])[]=[
 [F,F],[F-1n,F],[F+1n,F],[F,F-1n],[F,F+1n],
 [F-89n,F+273n],[F+273n,F-89n],[-278522n,-278522n],
 [-278522n,-268522n],[1n,1n],[100000n,-100000n],[-100000n,100000n]
];
const contexts=new Set<object>();
let pairsDone=0,cells=0,oldWrong=0,oldMatches=0;
for(const [c,t] of pairs){
  const count=workCounts(c,t),hidden=buildHiddenDrops(count,STONES);
  const visible=buildVisibleDrops(count,STONES,hidden);
  const start=initialBowls(count),snapshot=[...start];
  const oracle=applyVisibleDropsToBowls(
    [...start] as [bigint,bigint,bigint,bigint,bigint,bigint],visible,STONES);
  const full=sauce(c,t);
  for(let id=1;id<=6;id++){
    const old=discoverLegacyFixedNextBowl(c,t,visible,STONES,start,id);
    const correct=canonicalNextBowl(oracle.orderAtDrop46,id);
    const numeric=id===6?1:id+1;
    check(old.queriedBowlId===id&&old.legacyNextBowlId===numeric&&
      old.numericSuccessorCalls===1&&old.latchCaptures===1&&
      old.sharedMemoryWrites===58&&
      old.orderAt46Latch.join(",")===oracle.orderAtDrop46.join(",")&&
      old.actualDrop46Order.join(",")===full.orderAtDrop46.join(",")&&
      old.preceding.historical.latestSource==="STIR_12"&&
      old.historicalOverwrittenOrder.join(",")===
      old.preceding.historical.legacyQueryOrder.join(","),
      "old numeric successor despite valid real DROP46 latch and 58 writes");
    check(old.finalBowls.every((v,j)=>v===full.bowls[j])&&
      old.afterDropBowls.every((v,j)=>v===oracle.bowls[j])&&
      start.every((v,j)=>v===snapshot[j]),"full historical route computes correct bowls without input changes");
    check(Object.isFrozen(old)&&Object.isFrozen(old.orderAt46Latch)&&
      Object.isFrozen(old.afterDropBowls)&&Object.isFrozen(old.finalBowls)&&
      Object.isFrozen(old.actualDrop46Order)&&
      !contexts.has(old.context)&&old.context!==old.preceding.context&&
      old.context.status==="DISCOVERY_12_RECORDED"&&old.context.phase==="READY",
      "frozen ownership, separate context and status");
    contexts.add(old.context);
    check(old.context.branchTrace.join(",")=== [
      "BOOTSTRAP_VALIDATE","DISCOVERY_12_REUSE_PATCH11_DROP46_LATCH",
      "DISCOVERY_12_FIXED_NUMERIC_ID_SUCCESSOR",
      "DISCOVERY_12_PERMUTATION_POSITION_IGNORED"
    ].join(",")&&
    old.context.metrics.get("bootstrap.calls")===1n&&
    old.context.metrics.get("discovery12.calls")===1n&&
    old.context.metrics.get("discovery12.legacy_successor_calls")===1n&&
    old.context.metrics.get("discovery12.preceding_latch_reads")===1n&&
    old.context.metrics.get("discovery12.preceding_58_write_sequences")===1n,
    "accurate recorded call, latch and numeric scar metrics");
    cells++;if(old.legacyNextBowlId===correct)oldMatches++;else oldWrong++;
  }
  pairsDone++;
}
check(pairsDone===12&&cells===72&&oldWrong>0&&oldMatches>0&&
  oldWrong+oldMatches===cells,"12 complete day-pairs, all six queried bowl IDs");

// The historical numeric wrap and the permutation cyclic wrap are different.
// Rank2 = [1,2,3,4,6,5]: queried ID6 numeric->1, actual->5;
// final-position queried ID5 permutation->1, numeric->6.
const counts=workCounts(F,F),hidden=buildHiddenDrops(counts,STONES);
const visible=[...buildVisibleDrops(counts,STONES,hidden)],b=initialBowls(counts);
visible[46]=2n;
const expected=[1,2,3,4,6,5];
let wrong3=0;
for(const [id,actual] of [[4,6],[5,1],[6,5]]){
  const x=discoverLegacyFixedNextBowl(F,F,visible,STONES,b,id!);
  check(x.orderAt46Latch.join(",")===expected.join(",")&&
    canonicalNextBowl(x.orderAt46Latch,id!)===actual,"rank 2 witnesses");
  if(x.legacyNextBowlId!==actual)wrong3++;
}
check(wrong3===3&&canonicalNextBowl(expected,5)===1&&
  canonicalNextBowl(expected,6)===5,
  "numeric ID6 wrap and position-six cyclic wrap separate");

// Verify actual old method was called from handler. Handler MUST NOT use
// independent normative test oracle as a substitute for original broken method.
const legacy=new LegacyNextBowlFixedNameAdapter();
check([1,2,3,4,5,6].map(id=>legacy.oldNextBowlFixedName(id)).join(",")==="2,3,4,5,6,1",
  "original ID arithmetic unchanged");
let calls=0;const original=LegacyNextBowlFixedNameAdapter.prototype.oldNextBowlFixedName;
try{
  LegacyNextBowlFixedNameAdapter.prototype.oldNextBowlFixedName=function(...args){
    calls++;return original.apply(this,args);
  };
  discoverLegacyFixedNextBowl(F,F,visible,STONES,b,6);
  discoverLegacyFixedNextBowl(F,F,visible,STONES,b,5);
  check(calls===2,"exactly two physical old successor calls");
}finally{LegacyNextBowlFixedNameAdapter.prototype.oldNextBowlFixedName=original;}

const handler=new Discovery12FixedSuccessorHandler(),raw=createMonsterContext(F,F);
check(rejects(()=>handler.run(raw,visible,STONES,b,6),MonsterStageError)&&
  raw.status==="NEW"&&raw.branchTrace.length===0&&raw.metrics.size===0,
  "unready context rejected without mutations");
const ready=bootstrapMonster(F,F);
for(const id of [0,-1,7,1.5,NaN,Infinity,"1" as unknown as number]){
  check(rejects(()=>handler.run(ready,visible,STONES,b,id),MonsterValidationError)&&
    rejects(()=>legacy.oldNextBowlFixedName(id),MonsterValidationError),
    "invalid IDs rejected by both wrapper and historical helper");
}
for(const vis of [[],[1n],Object.assign(new Array<bigint>(47),{1:1n})])
  check(rejects(()=>handler.run(ready,vis,STONES,b,4),MonsterValidationError),"invalid drop data");
for(const stone of [[],STONES.slice(0,46),STONES.map((v,k)=>k===11?[1n]:v)])
  check(rejects(()=>handler.run(ready,visible,stone,b,4),MonsterValidationError),"invalid stones");
for(const bs of [[1n],[1n,2n,3n,4n,5n,1 as unknown as bigint]])
  check(rejects(()=>handler.run(ready,visible,STONES,bs,4),MonsterValidationError),"invalid bowls");
check(rejects(()=>handler.run({...ready,targetDay:null as unknown as bigint},
  visible,STONES,b,4),MonsterValidationError)&&ready.status==="VALIDATED"&&
  ready.metrics.size===1&&ready.branchTrace.join(",")==="BOOTSTRAP_VALIDATE",
  "invalid preflight never changes outer context");
handler.run(ready,visible,STONES,b,4);
check(rejects(()=>handler.run(ready,visible,STONES,b,4),MonsterStageError),
  "reused context is rejected");

let failureCases=0;
const oldMethod=LegacyNextBowlFixedNameAdapter.prototype.oldNextBowlFixedName;
try{
  LegacyNextBowlFixedNameAdapter.prototype.oldNextBowlFixedName=function():never{
    throw Error("INJECTED_DISCOVERY_12_FAULT");
  };
  const ctx=bootstrapMonster(F,F),caller=[...b];
  try{handler.run(ctx,visible,STONES,caller,4);throw Error("missing injected fault");}
  catch(e){check(e instanceof Error&&e.message==="INJECTED_DISCOVERY_12_FAULT",
      "fault from actual original helper propagated");}
  check(ctx.status==="VALIDATED"&&ctx.metrics.size===1&&
    ctx.branchTrace.join(",")==="BOOTSTRAP_VALIDATE"&&
    caller.every((v,j)=>v===b[j]),"no context or bowl partial mutation after 58-round work");
  failureCases++;
}finally{LegacyNextBowlFixedNameAdapter.prototype.oldNextBowlFixedName=oldMethod;}

const left=discoverLegacyFixedNextBowl(F,F,visible,STONES,b,4),
right=discoverLegacyFixedNextBowl(F,F,visible,STONES,b,4);
left.context.logs.push("पहिली");left.context.metrics.set("private",31n);
check(left.context!==right.context&&left.preceding!==right.preceding&&
  left.orderAt46Latch!==right.orderAt46Latch&&!right.context.logs.length&&
  !right.context.metrics.has("private"),"independent reentrant histories");
check(rejects(()=>calendarDateSpaghetti(F,F),MonsterStageError),
  "Stage54 final date route still unavailable");
console.log(`STAGE_24_DISCOVERY_12_GUARDS_PASS dayPairs=${pairsDone} cells=${cells} mismatches=${oldWrong} matches=${oldMatches} rank2Wrong=${wrong3} actualLegacyCalls=${calls} injectedFailures=${failureCases}`);
