import {
  bootstrapMonster,createMonsterContext,LegacyShortOnlyWideSelectionAdapter,
  Discovery14ShortOnlyWideHandler,discoverLegacyShortOnlyWide,
  Patch13RejectionRankAdapter,LegacyBiasedModuloRankAdapter,
  MonsterStageError,MonsterValidationError,calendarDateSpaghetti
} from "../src/index.ts";
import {
  FOUNDATION_DAY as F,M,STONES,workCounts,buildHiddenDrops,buildVisibleDrops,
  initialBowls,sauce,askBowl,chooseRank
} from "./normativeOracle.ts";
function check(ok:boolean,msg:string):void{if(!ok)throw Error(msg);}
function rejects(fn:()=>unknown,Cls:typeof MonsterStageError|typeof MonsterValidationError):boolean{
  try{fn();}catch(e){return e instanceof Cls;}return false;
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
const sizes=[1n,2n,3n,5n,922n,M-1n,M,M+1n,M*M,M*M+1n] as const;
const contexts=new Set<object>(),old=new LegacyShortOnlyWideSelectionAdapter();
let pairsDone=0,cells=0,short=0,wide=0,shortWrong=0,wideWrong=0;
for(const [c,t] of pairs){
 const {visible,start}=fixture(c,t),unchanged=[...start],truth=sauce(c,t);
 for(let id=1;id<=6;id++){
  const N=sizes[(pairsDone*6+id)%sizes.length]!;
  const seal=[1n,10n,20n,21n,30n,33n][id-1]!;
  const out=discoverLegacyShortOnlyWide(c,t,visible,STONES,start,id,seal,N);
  const stream=askBowl(truth,id,seal),expected=chooseRank(stream,N);
  const isWide=N>M;
  check(out.preceding.correctedRank===expected&&
    out.firstAnswer===stream.first&&out.directionStep===stream.directionStep&&
    out.preceding.firstAnswer===stream.first&&
    out.preceding.preceding.preceding.correctedNextBowlId===
      truth.orderAtDrop46[(truth.orderAtDrop46.indexOf(id)+1)%6]&&
    out.preceding.preceding.preceding.finalBowls.every((b,j)=>b===truth.bowls[j])&&
    out.preceding.preceding.preceding.sharedMemoryWrites===58&&
    out.preceding.preceding.preceding.preceding.historical.memoryWrites===58&&
    out.preceding.preceding.preceding.preceding.historical.latestSource==="STIR_12"&&
    out.predecessorSharedMemoryWrites===58&&out.legacyShortOnlyCalls===1&&
    out.blockedWideSelection===isWide&&
    out.historicalMismatch===(out.legacyShortOnlyRank!==expected)&&
    start.every((b,j)=>b===unchanged[j]),"complete verified chain and historical branch");
  if(isWide){
   wide++;
   if(out.legacyShortOnlyRank!==expected)wideWrong++;
   check(out.legacyShortOnlyRank===0n&&out.oldResult.blocked&&
     out.oldResult.shortSelection===null&&out.oldResult.legacyAcceptanceLimit===0n&&
     out.oldResult.shortSelectorCalls===0&&out.oldResult.wideSelectorCalls===0,
     "wide family blocked with invalid zero rank, no Stage29 repair");
  }else{
   short++;
   if(out.legacyShortOnlyRank!==expected)shortWrong++;
   check(out.legacyShortOnlyRank===expected&&out.oldResult.rank===expected&&
     out.oldResult.shortSelectorCalls===1&&out.oldResult.wideSelectorCalls===0&&
     out.oldResult.shortSelection?.mode==="SHORT"&&
     out.oldResult.legacyAcceptanceLimit===(M/N)*N,
     "old short-only route exactly retains Stage27 short selection");
  }
  check(!contexts.has(out.context)&&Object.isFrozen(out)&&
    Object.isFrozen(out.oldResult)&&out.context!==out.preceding.context&&
    out.context.phase==="READY"&&out.context.status==="DISCOVERY_14_RECORDED"&&
    out.context.branchTrace.join(",")=== [
     "BOOTSTRAP_VALIDATE","DISCOVERY_14_REAL_PATCH13_58_WRITE_CHAIN",
     "DISCOVERY_14_REAL_LEGACY_SHORT_ONLY_CALL",
     isWide?"DISCOVERY_14_WIDE_N_GT_M_BLOCKED_ZERO":"DISCOVERY_14_SHORT_N_LE_M_PRESERVED"
    ].join(",")&&
    out.context.metrics.get("discovery14.calls")===1n&&
    out.context.metrics.get("discovery14.legacy_short_only_calls")===1n&&
    out.context.metrics.get("discovery14.preceding_58_write_sequences")===1n&&
    (out.context.metrics.get("discovery14.wide_blocked")??0n)===(isWide?1n:0n)&&
    (out.context.metrics.get("discovery14.short_successes")??0n)===(isWide?0n:1n)&&
    (out.context.metrics.get("discovery14.historical_mismatches")??0n)===(isWide?1n:0n),
    "fresh frozen output, correct forensic branch trace and metrics");
  contexts.add(out.context);cells++;
 }
 pairsDone++;
}
check(pairsDone===12&&cells===72&&contexts.size===72&&
 short>0&&wide>0&&shortWrong===0&&wideWrong===wide,
 "72 genuine pair/cell histories, all short correct, all wide blocked");
let boundary=0;
const sample={first:M,directionStep:-1n as const};
for(const N of [1n,2n,3n,M-1n,M]){
 const actual=old.oldChooseShortOnly(sample,N);
 const expected=chooseRank(sample,N);
 check(actual.rank===expected&&!actual.blocked&&actual.shortSelection?.mode==="SHORT"&&
  actual.shortSelectorCalls===1,"short edge including N=M passes");
 boundary++;
}
for(const N of [M+1n,M+2n,M*M,M*M+1n,1n<<16384n]){
 const actual=old.oldChooseShortOnly({first:1n,directionStep:1n},N);
 const expected=chooseRank({first:1n,directionStep:1n},N);
 check(actual.rank===0n&&actual.blocked&&actual.legacyAcceptanceLimit===0n&&
  actual.shortSelection===null&&actual.shortSelectorCalls===0&&
  expected>=1n&&expected<=N,"wide edges are intentionally invalid zero");
 boundary++;
}
for(const bad of [null,{}, {first:0n,directionStep:1n},
 {first:M+1n,directionStep:-1n},{first:1n,directionStep:0n},
 {first:1n,directionStep:1},{first:"1",directionStep:1n}]){
 check(rejects(()=>old.oldChooseShortOnly(bad as never,2n),MonsterValidationError),
 "invalid stream rejected");
}
for(const n of [-1n,0n,2,null] as unknown[])
 check(rejects(()=>old.oldChooseShortOnly(sample,n as bigint),MonsterValidationError),
 "invalid family cardinalities rejected");
const {visible,start}=fixture(F,F),handler=new Discovery14ShortOnlyWideHandler();
const raw=createMonsterContext(F,F);
check(rejects(()=>handler.run(raw,visible,STONES,start,1,1n,M+1n),MonsterStageError)&&
 raw.status==="NEW"&&raw.metrics.size===0&&!raw.branchTrace.length,"unready context rejected");
const ready=bootstrapMonster(F,F);
for(const id of [0,7,1.5,NaN,Infinity,"1" as unknown as number])
 check(rejects(()=>handler.run(ready,visible,STONES,start,id,1n,M+1n),MonsterValidationError),
 "invalid ID preflight rejected");
for(const n of [-1n,0n,2,null] as unknown[])
 check(rejects(()=>handler.run(ready,visible,STONES,start,1,1n,n as bigint),
 MonsterValidationError),"invalid N preflight");
for(const v of [[],[1n],Object.assign(new Array<bigint>(47),{1:1n})])
 check(rejects(()=>handler.run(ready,v,STONES,start,1,1n,2n),MonsterValidationError),
 "bad visible drops preflight");
for(const stones of [[],STONES.slice(0,46),STONES.map((r,j)=>j===7?[1n]:r)])
 check(rejects(()=>handler.run(ready,visible,stones,start,1,1n,2n),MonsterValidationError),
 "bad stones preflight");
for(const b of [[1n],[1n,2n,3n,4n,5n,1 as unknown as bigint]])
 check(rejects(()=>handler.run(ready,visible,STONES,b,1,1n,2n),MonsterValidationError),
 "bad initial bowls preflight");
check(rejects(()=>handler.run({...ready,targetDay:null as unknown as bigint},
 visible,STONES,start,1,1n,2n),MonsterValidationError)&&
 ready.status==="VALIDATED"&&ready.metrics.size===1&&
 ready.branchTrace.join(",")==="BOOTSTRAP_VALIDATE",
 "outer context not partially mutated");
handler.run(ready,visible,STONES,start,1,1n,M+1n);
check(rejects(()=>handler.run(ready,visible,STONES,start,1,1n,2n),MonsterStageError),
 "context cannot be reused after final historical observation");

const originalOld=LegacyShortOnlyWideSelectionAdapter.prototype.oldChooseShortOnly;
const originalShort=Patch13RejectionRankAdapter.prototype.choose;
let actualOld=0,actualPredecessor=0,shortHelper=0;
try{
 LegacyShortOnlyWideSelectionAdapter.prototype.oldChooseShortOnly=function(...args){
  actualOld++;return originalOld.apply(this,args);
 };
 Patch13RejectionRankAdapter.prototype.choose=function(...args){
  actualPredecessor++;
  if(args[1]<=M)shortHelper++;
  return originalShort.apply(this,args);
 };
 discoverLegacyShortOnlyWide(F,F,visible,STONES,start,1,1n,2n);
 discoverLegacyShortOnlyWide(F,F,visible,STONES,start,1,1n,M+1n);
 check(actualOld===2&&actualPredecessor===3&&shortHelper===2,
  "true old helper invoked; short case calls predecessor and legacy short selector; wide only predecessor");
}finally{
 LegacyShortOnlyWideSelectionAdapter.prototype.oldChooseShortOnly=originalOld;
 Patch13RejectionRankAdapter.prototype.choose=originalShort;
}
let faults=0;
for(const which of ["preceding","legacy_short","legacy_wide"] as const){
 const ctx=bootstrapMonster(F,F),caller=[...start],name="INJECTED_DISCOVERY14_"+which;
 try{
  if(which==="preceding"){
   Patch13RejectionRankAdapter.prototype.choose=function():never{throw Error(name);};
  }else{
   LegacyShortOnlyWideSelectionAdapter.prototype.oldChooseShortOnly=function():never{throw Error(name);};
  }
  const N=which==="legacy_short"?2n:M+1n;
  try{handler.run(ctx,visible,STONES,caller,1,1n,N);throw Error("missing injected error");}
  catch(e){check(e instanceof Error&&e.message===name,"correct exception propagated");}
  check(ctx.status==="VALIDATED"&&ctx.metrics.size===1&&
    ctx.branchTrace.join(",")==="BOOTSTRAP_VALIDATE"&&
    caller.every((b,j)=>b===start[j]),"fault after actual predecessor has no caller-side effects");
  faults++;
 }finally{
  Patch13RejectionRankAdapter.prototype.choose=originalShort;
  LegacyShortOnlyWideSelectionAdapter.prototype.oldChooseShortOnly=originalOld;
 }
 const N=which==="legacy_short"?2n:M+1n;
 check(handler.run(ctx,visible,STONES,caller,1,1n,N).blockedWideSelection===(N>M),
 "fault retry stays deterministic on same outer context");
}
const left=discoverLegacyShortOnlyWide(F,F,visible,STONES,start,1,1n,M+1n);
const right=discoverLegacyShortOnlyWide(F,F,visible,STONES,start,1,1n,M+1n);
left.context.logs.push("पहिली");left.context.metrics.set("private",777n);
check(left.context!==right.context&&left.oldResult!==right.oldResult&&
 left.preceding!==right.preceding&&!right.context.metrics.has("private")&&
 right.context.logs.length===0,"fresh owner and no cross-call mutation");
check(rejects(()=>calendarDateSpaghetti(F,F),MonsterStageError),
 "Stage54 final route remains forbidden");
console.log("STAGE_28_DISCOVERY_14_GUARDS_PASS pairs="+pairsDone+" cells="+cells+
 " short="+short+" wide="+wide+" shortWrong="+shortWrong+" wideWrong="+wideWrong+
 " boundary="+boundary+" legacyCalls="+actualOld+" predecessorCalls="+actualPredecessor+
 " shortHelperCalls="+shortHelper+" injectedFailures="+faults);
