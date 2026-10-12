import {
  bootstrapMonster,createMonsterContext,Patch12PermutationSuccessorAdapter,
  Patch12NextBowlHandler,patch12NextBowl,LegacyNextBowlFixedNameAdapter,
  MonsterStageError,MonsterValidationError,calendarDateSpaghetti
} from "../src/index.ts";
import { FOUNDATION_DAY as F,STONES,workCounts,buildHiddenDrops,buildVisibleDrops,
  initialBowls,applyVisibleDropsToBowls,sauce
} from "./normativeOracle.ts";
import { canonicalNextBowl } from "./discovery12Reference.ts";
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
let dayPairs=0,cells=0,mismatches=0,oldWrong=0,oldMatches=0;
const contexts=new Set<object>();
for(const [c,t] of pairs){
 const {visible,start}=fixture(c,t),copy=[...start];
 const independent=applyVisibleDropsToBowls(
   [...start] as [bigint,bigint,bigint,bigint,bigint,bigint],visible,STONES);
 const full=sauce(c,t);
 for(let id=1;id<=6;id++){
  const out=patch12NextBowl(c,t,visible,STONES,start,id);
  const want=canonicalNextBowl(independent.orderAtDrop46,id);
  if(out.correctedNextBowlId!==want)mismatches++;
  if(out.legacyNextBowlId===want)oldMatches++;else oldWrong++;
  check(out.queriedBowlId===id&&out.numericSuccessorCalls===1&&
    out.positionalSuccessorCalls===1&&out.latchCaptures===1&&
    out.sharedMemoryWrites===58&&
    out.legacyNextBowlId===(id===6?1:id+1)&&
    out.historicalMismatch===(out.correctedNextBowlId!==out.legacyNextBowlId)&&
    out.orderAt46Latch.join(",")===independent.orderAtDrop46.join(",")&&
    out.actualDrop46Order.join(",")===independent.orderAtDrop46.join(",")&&
    out.historicalOverwrittenOrder.join(",")===
      out.preceding.historical.legacyQueryOrder.join(",")&&
    out.preceding.historical.latestSource==="STIR_12"&&
    out.preceding.ledger.length===58&&
    out.preceding.ledger[45]!.source==="DROP_46"&&
    out.preceding.ledger[57]!.source==="STIR_12"&&
    out.afterDropBowls.every((v,j)=>v===independent.bowls[j])&&
    out.finalBowls.every((v,j)=>v===full.bowls[j])&&
    start.every((v,j)=>v===copy[j]),"independent canonical successor and bowls");
  check(Object.isFrozen(out)&&Object.isFrozen(out.orderAt46Latch)&&
    Object.isFrozen(out.finalBowls)&&
    !contexts.has(out.context)&&out.context!==out.preceding.context&&
    out.context.status==="PATCH_12_APPLIED"&&out.context.phase==="READY"&&
    out.context.branchTrace.join(",")=== [
      "BOOTSTRAP_VALIDATE","PATCH_12_REUSE_PATCH11_REAL_DROP46_LATCH",
      "PATCH_12_RUN_LEGACY_FIXED_NUMERIC_SUCCESSOR",
      "PATCH_12_CORRECT_SUCCESSOR_BY_FROZEN_POSITION"
    ].join(",")&&
    out.context.metrics.get("bootstrap.calls")===1n&&
    out.context.metrics.get("patch12.calls")===1n&&
    out.context.metrics.get("patch12.legacy_numeric_calls")===1n&&
    out.context.metrics.get("patch12.corrected_positional_calls")===1n&&
    out.context.metrics.get("patch12.preceding_58_write_sequences")===1n&&
    (out.context.metrics.get("patch12.historical_mismatches")??0n)===(out.historicalMismatch?1n:0n),
    "isolated frozen observations with accurate production call counts");
  contexts.add(out.context);cells++;
 }
 dayPairs++;
}
check(dayPairs===12&&cells===72&&mismatches===0&&oldWrong===60&&oldMatches===12,
  "all 72 complete cases, old 60 wrong, corrected zero wrong");

const selector=new Patch12PermutationSuccessorAdapter(),rank2=[1,2,3,4,6,5];
const {visible,start}=fixture(F,F),changed=[...visible];changed[46]=2n;
let rank2Fixed=0;
for(const [id,expected] of [[4,6],[5,1],[6,5]]){
 const out=patch12NextBowl(F,F,changed,STONES,start,id!);
 check(out.orderAt46Latch.join(",")===rank2.join(",")&&
    out.correctedNextBowlId===expected&&out.legacyNextBowlId!==expected&&
    selector.nextFromLatchedPermutation(rank2,id!)===expected,
    "rank2 historic ID4, ID5 and ID6 corrected, both wrap rules distinguished");
 rank2Fixed++;
}
const legacy=new LegacyNextBowlFixedNameAdapter();
check([1,2,3,4,5,6].map(id=>legacy.oldNextBowlFixedName(id)).join(",")==="2,3,4,5,6,1",
  "historical fixed-ID scar unchanged");
for(const id of [0,-1,7,1.5,NaN,Infinity,"1" as unknown as number]){
 check(rejects(()=>selector.nextFromLatchedPermutation(rank2,id),MonsterValidationError)&&
   rejects(()=>legacy.oldNextBowlFixedName(id),MonsterValidationError),
   "invalid queried ID rejected independently");
}
for(const bad of [[],[1,2,3,4,5,5],[1,2,3,4,5,7],
    Object.assign(new Array<number>(6),{0:1,1:2,2:3,3:4,4:5})]){
 check(rejects(()=>selector.nextFromLatchedPermutation(bad,4),MonsterValidationError),
   "all order slots must form valid 6-ID permutation");
}
const oldMethod=LegacyNextBowlFixedNameAdapter.prototype.oldNextBowlFixedName;
const correctedMethod=Patch12PermutationSuccessorAdapter.prototype.nextFromLatchedPermutation;
let oldCalls=0,correctedCalls=0;
try{
 LegacyNextBowlFixedNameAdapter.prototype.oldNextBowlFixedName=function(...args){
  oldCalls++;return oldMethod.apply(this,args);
 };
 Patch12PermutationSuccessorAdapter.prototype.nextFromLatchedPermutation=function(...args){
  correctedCalls++;return correctedMethod.apply(this,args);
 };
 patch12NextBowl(F,F,changed,STONES,start,5);
 patch12NextBowl(F,F,changed,STONES,start,6);
 check(oldCalls===2&&correctedCalls===2,"both actual old and actual corrected methods invoked twice");
}finally{
 LegacyNextBowlFixedNameAdapter.prototype.oldNextBowlFixedName=oldMethod;
 Patch12PermutationSuccessorAdapter.prototype.nextFromLatchedPermutation=correctedMethod;
}
const handler=new Patch12NextBowlHandler(),raw=createMonsterContext(F,F);
check(rejects(()=>handler.run(raw,changed,STONES,start,6),MonsterStageError)&&
  raw.status==="NEW"&&raw.metrics.size===0&&!raw.branchTrace.length,
  "unready caller context unchanged");
const ready=bootstrapMonster(F,F);
for(const id of [0,7,1.25,NaN,Infinity]){
 check(rejects(()=>handler.run(ready,changed,STONES,start,id),MonsterValidationError),
   "invalid ID rejected before full Stage23 route");
}
for(const v of [[],[1n],Object.assign(new Array<bigint>(47),{1:1n})])
 check(rejects(()=>handler.run(ready,v,STONES,start,4),MonsterValidationError),
   "invalid visible values rejected");
for(const s of [[],STONES.slice(0,46),STONES.map((r,k)=>k===11?[1n]:r)])
 check(rejects(()=>handler.run(ready,changed,s,start,4),MonsterValidationError),
   "invalid stones rejected");
for(const b of [[1n],[1n,2n,3n,4n,5n,1 as unknown as bigint]])
 check(rejects(()=>handler.run(ready,changed,STONES,b,4),MonsterValidationError),
   "invalid six bowl input rejected");
check(rejects(()=>handler.run({...ready,targetDay:null as unknown as bigint},
  changed,STONES,start,4),MonsterValidationError)&&
  ready.status==="VALIDATED"&&ready.metrics.size===1&&
  ready.branchTrace.join(",")==="BOOTSTRAP_VALIDATE",
  "preflight has no context side effects");
handler.run(ready,changed,STONES,start,4);
check(rejects(()=>handler.run(ready,changed,STONES,start,4),MonsterStageError),
  "single use of outer context");

let injectedFailures=0;
for(const which of ["legacy","corrected"] as const){
 const ctx=bootstrapMonster(F,F),caller=[...start],signal="PATCH_12_INJECTED_"+which;
 try{
  if(which==="legacy"){
   LegacyNextBowlFixedNameAdapter.prototype.oldNextBowlFixedName=function():never{
    throw Error(signal);
   };
  }else{
   Patch12PermutationSuccessorAdapter.prototype.nextFromLatchedPermutation=function():never{
    throw Error(signal);
   };
  }
  try{handler.run(ctx,changed,STONES,caller,4);throw Error("injection absent");}
  catch(e){check(e instanceof Error&&e.message===signal,
    "failure propagated at original/corrected successor after 58 writes");}
  check(ctx.status==="VALIDATED"&&ctx.metrics.size===1&&
    ctx.branchTrace.join(",")==="BOOTSTRAP_VALIDATE"&&
    caller.every((v,j)=>v===start[j]),"rollback preserves outer context and input");
  injectedFailures++;
 }finally{
  LegacyNextBowlFixedNameAdapter.prototype.oldNextBowlFixedName=oldMethod;
  Patch12PermutationSuccessorAdapter.prototype.nextFromLatchedPermutation=correctedMethod;
 }
 check(handler.run(ctx,changed,STONES,caller,4).correctedNextBowlId===6,
   "same context retry correct after exception");
}
const left=patch12NextBowl(F,F,changed,STONES,start,4),
 right=patch12NextBowl(F,F,changed,STONES,start,4);
left.context.logs.push("स्थानिक");left.context.metrics.set("private",19n);
check(left.context!==right.context&&left.preceding!==right.preceding&&
 left.orderAt46Latch!==right.orderAt46Latch&&
 !right.context.metrics.has("private")&&!right.context.logs.length,
 "reentrant independent ownership");
check(rejects(()=>calendarDateSpaghetti(F,F),MonsterStageError),
 "Stage54 calendarDateSpaghetti barrier remains");
console.log("STAGE_25_PATCH_12_GUARDS_PASS dayPairs="+dayPairs+" cells="+cells+
 " mismatches="+mismatches+" oldWrong="+oldWrong+" oldMatches="+oldMatches+
 " rank2Fixed="+rank2Fixed+" legacyCalls="+oldCalls+" positionalCalls="+correctedCalls+
 " injectedFailures="+injectedFailures);
