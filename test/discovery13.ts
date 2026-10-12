import {
 bootstrapMonster,createMonsterContext,LegacyBiasedModuloRankAdapter,
 Discovery13BiasedModuloHandler,discoverLegacyBiasedModulo,
 Patch12PermutationSuccessorAdapter,LegacyNextBowlFixedNameAdapter,
 MonsterStageError,MonsterValidationError,calendarDateSpaghetti
} from "../src/index.ts";
import {
 FOUNDATION_DAY as F,M,STONES,workCounts,buildHiddenDrops,buildVisibleDrops,
 initialBowls,sauce,askBowl,chooseRank
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
const sizes=[1n,2n,3n,5n,7n,922n,M,M+1n,M*M+1n] as const;
let dayPairs=0,cells=0,oldWrong=0,oldMatches=0,wideWrong=0,wideSame=0;
const contexts=new Set<object>(),helper=new LegacyBiasedModuloRankAdapter();
for(const [c,t] of pairs){
 const {visible,start}=fixture(c,t),independent=sauce(c,t);
 for(let id=1;id<=6;id++){
  const size=sizes[(dayPairs*6+id)%sizes.length]!;
  const seal=[1n,10n,20n,30n,31n,33n][id-1]!;
  const out=discoverLegacyBiasedModulo(c,t,visible,STONES,start,id,seal,size);
  const expectedStream=askBowl(independent,id,seal);
  const wantedRank=chooseRank(expectedStream,size);
  if(out.biasedRank===wantedRank){oldMatches++;if(size>M)wideSame++;}
  else{oldWrong++;if(size>M)wideWrong++;}
  check(out.queriedBowlId===id&&out.seal===seal&&out.familySize===size&&
   out.firstAnswer===expectedStream.first&&
   out.directionStep===expectedStream.directionStep&&
   out.answerStream.first===expectedStream.first&&
   out.answerStream.directionStep===expectedStream.directionStep&&
   out.biasedRank===1n+(out.firstAnswer-1n)%size&&
   out.biasedRank===helper.oldChooseModulo(out.firstAnswer,size)&&
   out.biasedRank>=1n&&out.biasedRank<=size&&
   out.actualNextBowlId===independent.orderAtDrop46[
      (independent.orderAtDrop46.indexOf(id)+1)%6]&&
   out.preceding.correctedNextBowlId===out.actualNextBowlId&&
   out.preceding.finalBowls.every((v,j)=>v===independent.bowls[j])&&
   out.preceding.orderAt46Latch.join(",")===independent.orderAtDrop46.join(",")&&
   out.preceding.sharedMemoryWrites===58&&out.predecessorSharedMemoryWrites===58&&
   out.preceding.preceding.historical.latestSource==="STIR_12"&&
   out.legacyModuloCalls===1,"full corrected predecessor, exact stream, uncorrected rank");
  check(Object.isFrozen(out)&&Object.isFrozen(out.answerStream)&&
   !contexts.has(out.context)&&out.context!==out.preceding.context&&
   out.context.phase==="READY"&&out.context.status==="DISCOVERY_13_RECORDED"&&
   out.context.branchTrace.join(",")=== [
    "BOOTSTRAP_VALIDATE","DISCOVERY_13_REAL_PATCH12_SUCCESSOR_AND_58_WRITES",
    "DISCOVERY_13_PRODUCTION_BOWL_ANSWER_STREAM",
    "DISCOVERY_13_BIASED_FIRST_ANSWER_MODULO_NO_REJECTION"
   ].join(",")&&
   out.context.metrics.get("discovery13.calls")===1n&&
   out.context.metrics.get("discovery13.actual_legacy_modulo_calls")===1n&&
   out.context.metrics.get("discovery13.patch12_routes")===1n&&
   out.context.metrics.get("discovery13.answer_streams")===1n&&
   out.context.metrics.get("discovery13.predecessor_58_write_sequences")===1n,
   "observable independent context, frozen output, real call metrics");
  contexts.add(out.context);cells++;
 }
 dayPairs++;
}
check(dayPairs===12&&cells===72&&contexts.size===72&&oldWrong>0&&
 oldMatches>0&&wideWrong>0&&oldWrong+oldMatches===cells,
 "72 full real paths have intentional wrong selection and correct coincidences");

// Historical modulo must be wrong at the top rejected value; do not repair in Discovery.
let redWitnesses=0;
for(const size of [2n,3n,5n]){
 const old=helper.oldChooseModulo(M,size);
 const want=chooseRank({first:M,directionStep:-1n},size);
 check(old!==want,"M is rejected by correct selector for non-divisors");
 redWitnesses++;
}
for(const [first,n] of [[1n,1n],[M,M],[1n,M+1n],[M,M*M+1n]]){
 check(helper.oldChooseModulo(first!,n!)===1n+(first!-1n)%n!,
 "legacy modulo unchanged at short/wide borders");
}
const {visible,start}=fixture(F,F),handler=new Discovery13BiasedModuloHandler();
const raw=createMonsterContext(F,F);
check(rejects(()=>handler.run(raw,visible,STONES,start,1,1n,2n),MonsterStageError)&&
 raw.branchTrace.length===0&&raw.metrics.size===0&&raw.status==="NEW",
 "unready outer context unchanged");
const ready=bootstrapMonster(F,F);
for(const id of [0,-1,7,1.25,NaN,Infinity,"1" as unknown as number])
 check(rejects(()=>handler.run(ready,visible,STONES,start,id,1n,2n),MonsterValidationError),
 "invalid bowl IDs rejected before precursor runs");
for(const n of [0n,-1n,1,"2" as unknown as bigint])
 check(rejects(()=>handler.run(ready,visible,STONES,start,1,1n,n as bigint),MonsterValidationError),
 "invalid family count rejected");
for(const seal of [null,"1",1] as unknown[])
 check(rejects(()=>handler.run(ready,visible,STONES,start,1,seal as bigint,2n),
  MonsterValidationError),"invalid seal rejected");
for(const v of [[],[1n],Object.assign(new Array<bigint>(47),{1:1n})])
 check(rejects(()=>handler.run(ready,v,STONES,start,1,1n,2n),MonsterValidationError),
  "missing visible drops rejected");
for(const s of [[],STONES.slice(0,46),STONES.map((r,k)=>k===11?[1n]:r)])
 check(rejects(()=>handler.run(ready,visible,s,start,1,1n,2n),MonsterValidationError),
  "invalid stones rejected");
for(const b of [[1n],[1n,2n,3n,4n,5n,1 as unknown as bigint]])
 check(rejects(()=>handler.run(ready,visible,STONES,b,1,1n,2n),MonsterValidationError),
 "invalid bowl data rejected");
check(rejects(()=>helper.oldChooseModulo(0n,2n),MonsterValidationError)&&
 rejects(()=>helper.oldChooseModulo(M+1n,2n),MonsterValidationError)&&
 rejects(()=>helper.oldChooseModulo(1n,0n),MonsterValidationError)&&
 rejects(()=>handler.run({...ready,calculationDay:null as unknown as bigint},
  visible,STONES,start,1,1n,2n),MonsterValidationError)&&
 ready.status==="VALIDATED"&&ready.branchTrace.join(",")==="BOOTSTRAP_VALIDATE"&&
 ready.metrics.size===1,"bad preflight and bad historical direct calls leave context");
handler.run(ready,visible,STONES,start,1,1n,2n);
check(rejects(()=>handler.run(ready,visible,STONES,start,1,1n,2n),MonsterStageError),
 "context single use");
const original=LegacyBiasedModuloRankAdapter.prototype.oldChooseModulo;
const nextMethod=Patch12PermutationSuccessorAdapter.prototype.nextFromLatchedPermutation;
const oldBowlMethod=LegacyNextBowlFixedNameAdapter.prototype.oldNextBowlFixedName;
let directOldCalls=0,correctedNextCalls=0,oldNextCalls=0;
try {
 LegacyBiasedModuloRankAdapter.prototype.oldChooseModulo=function(...args){
  directOldCalls++;return original.apply(this,args);
 };
 Patch12PermutationSuccessorAdapter.prototype.nextFromLatchedPermutation=function(...args){
  correctedNextCalls++;return nextMethod.apply(this,args);
 };
 LegacyNextBowlFixedNameAdapter.prototype.oldNextBowlFixedName=function(...args){
  oldNextCalls++;return oldBowlMethod.apply(this,args);
 };
 discoverLegacyBiasedModulo(F,F,visible,STONES,start,4,1n,2n);
 discoverLegacyBiasedModulo(F,F,visible,STONES,start,5,20n,M+1n);
 check(directOldCalls===2&&correctedNextCalls===2&&oldNextCalls===2,
 "two real old modulo calls and two actual Stage25 legacy/corrected successor calls");
}finally {
 LegacyBiasedModuloRankAdapter.prototype.oldChooseModulo=original;
 Patch12PermutationSuccessorAdapter.prototype.nextFromLatchedPermutation=nextMethod;
 LegacyNextBowlFixedNameAdapter.prototype.oldNextBowlFixedName=oldBowlMethod;
}
let injectedFailures=0;
for(const target of ["predecessor","modulo"] as const) {
 const ctx=bootstrapMonster(F,F),saved=[...start],fault="INJECTED_13_"+target;
 try {
  if(target==="predecessor")
   Patch12PermutationSuccessorAdapter.prototype.nextFromLatchedPermutation=function():never{
    throw Error(fault);
   };
  else
   LegacyBiasedModuloRankAdapter.prototype.oldChooseModulo=function():never{
    throw Error(fault);
   };
  try{handler.run(ctx,visible,STONES,saved,4,1n,2n);throw Error("no fault");}
  catch(e){check(e instanceof Error&&e.message===fault,"original injected exception propagated");}
  check(ctx.status==="VALIDATED"&&ctx.metrics.size===1&&
    ctx.branchTrace.join(",")==="BOOTSTRAP_VALIDATE"&&
    saved.every((v,j)=>v===start[j]),"no partial caller/context mutation on failure");
  injectedFailures++;
 }finally{
  Patch12PermutationSuccessorAdapter.prototype.nextFromLatchedPermutation=nextMethod;
  LegacyBiasedModuloRankAdapter.prototype.oldChooseModulo=original;
 }
 const restored=handler.run(ctx,visible,STONES,saved,4,1n,2n);
 check(restored.firstAnswer===askBowl(sauce(F,F),4,1n).first,
   "deterministic same-context retry after injected failure");
}
const left=discoverLegacyBiasedModulo(F,F,visible,STONES,start,1,1n,2n),
 right=discoverLegacyBiasedModulo(F,F,visible,STONES,start,1,1n,2n);
left.context.logs.push("पहिली");left.context.metrics.set("private",99n);
check(left.context!==right.context&&left.preceding!==right.preceding&&
 left.answerStream!==right.answerStream&&
 !right.context.logs.length&&!right.context.metrics.has("private"),
 "reentrant context and stream ownership");
check(rejects(()=>calendarDateSpaghetti(F,F),MonsterStageError),
 "Stage54 main calendar path remains blocked");
console.log("STAGE_26_DISCOVERY_13_GUARDS_PASS dayPairs="+dayPairs+
 " cells="+cells+" oldWrong="+oldWrong+" oldMatches="+oldMatches+
 " wideWrong="+wideWrong+" wideSame="+wideSame+" redWitnesses="+redWitnesses+
 " moduloCalls="+directOldCalls+" correctedNextCalls="+correctedNextCalls+
 " oldNextCalls="+oldNextCalls+" injectedFailures="+injectedFailures);
