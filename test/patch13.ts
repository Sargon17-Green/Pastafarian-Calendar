import {
  bootstrapMonster,createMonsterContext,Patch13RejectionRankAdapter,
  Patch13RejectionRankHandler,patch13RejectionRank,
  LegacyBiasedModuloRankAdapter,Patch12PermutationSuccessorAdapter,
  MonsterStageError,MonsterValidationError,calendarDateSpaghetti
} from "../src/index.ts";
import {
  FOUNDATION_DAY as F,M,STONES,workCounts,buildHiddenDrops,buildVisibleDrops,
  initialBowls,sauce,askBowl,chooseRank
} from "./normativeOracle.ts";
function check(x:boolean,msg:string):void {if(!x)throw Error(msg);}
function rejects(fn:()=>unknown,cls:typeof MonsterStageError|typeof MonsterValidationError):boolean{
  try{fn();}catch(e){return e instanceof cls;}return false;
}
function fixture(c:bigint,t:bigint){
 const w=workCounts(c,t),h=buildHiddenDrops(w,STONES);
 return {visible:buildVisibleDrops(w,STONES,h),start:initialBowls(w)};
}
const pairs:readonly (readonly [bigint,bigint])[]=[
 [F,F],[F-1n,F],[F+1n,F],[F,F-1n],[F,F+1n],
 [F-89n,F+273n],[F+273n,F-89n],[-278522n,-278522n],
 [-278522n,-268522n],[1n,1n],[100000n,-100000n],[-100000n,100000n]
];
const sizes=[1n,2n,3n,5n,7n,922n,M,M+1n,M*M+1n] as const;
const selector=new Patch13RejectionRankAdapter();
const seen=new Set<object>();
let pairsDone=0,cells=0,wrong=0,oldWrong=0,oldMatches=0,wide=0;
for(const [c,t] of pairs){
 const {visible,start}=fixture(c,t),original=[...start],canonical=sauce(c,t);
 for(let id=1;id<=6;id++){
  const size=sizes[(pairsDone*6+id)%sizes.length]!;
  const seal=[1n,10n,20n,30n,31n,33n][id-1]!;
  const expectedStream=askBowl(canonical,id,seal);
  const expected=chooseRank(expectedStream,size);
  const result=patch13RejectionRank(c,t,visible,STONES,start,id,seal,size);
  if(result.correctedRank!==expected)wrong++;
  if(result.legacyBiasedRank!==expected)oldWrong++;else oldMatches++;
  if(size>M)wide++;
  check(result.correctedRank===result.selection.rank&&
    result.selection.mode===(size>M?"WIDE":"SHORT")&&
    result.selection.familySize===size&&
    result.selection.answerDigits[0]===expectedStream.first&&
    result.selection.firstCandidate>=1n&&
    result.selection.firstCandidate<=result.selection.sampleSpace&&
    result.selection.acceptedCandidate<=result.selection.acceptanceLimit&&
    result.selection.acceptedCandidate>=1n&&
    result.selection.rejectedCandidates>=0n&&
    result.firstAnswer===expectedStream.first&&
    result.directionStep===expectedStream.directionStep&&
    result.preceding.firstAnswer===expectedStream.first&&
    result.legacyBiasedRank===1n+(expectedStream.first-1n)%size&&
    result.historicalMismatch===(result.legacyBiasedRank!==result.correctedRank)&&
    result.legacySelectorCalls===1&&result.correctedSelectorCalls===1&&
    result.predecessorSharedMemoryWrites===58&&
    result.preceding.predecessorSharedMemoryWrites===58&&
    result.preceding.preceding.sharedMemoryWrites===58&&
    result.preceding.preceding.preceding.historical.memoryWrites===58&&
    result.preceding.preceding.preceding.historical.latestSource==="STIR_12"&&
    result.preceding.preceding.correctedNextBowlId===
      canonical.orderAtDrop46[(canonical.orderAtDrop46.indexOf(id)+1)%6]&&
    result.preceding.preceding.finalBowls.every((v,j)=>v===canonical.bowls[j])&&
    start.every((v,j)=>v===original[j]),"Stage25/26 true predecessor and independent norm");
  check(Object.isFrozen(result)&&Object.isFrozen(result.selection)&&
    Object.isFrozen(result.selection.answerDigits)&&
    !seen.has(result.context)&&result.context!==result.preceding.context&&
    result.context.status==="PATCH_13_APPLIED"&&result.context.phase==="READY"&&
    result.context.branchTrace.join(",")=== [
      "BOOTSTRAP_VALIDATE",
      "PATCH_13_REAL_DISCOVERY13_LEGACY_SELECTOR_AND_58_WRITES",
      "PATCH_13_REJECTION_ON_CANONICAL_STREAM",
      size>M?"PATCH_13_MULTI_DIGIT_WIDE_RANK":"PATCH_13_SHORT_RANK"
    ].join(",")&&
    result.context.metrics.get("patch13.calls")===1n&&
    result.context.metrics.get("patch13.corrected_selector_calls")===1n&&
    result.context.metrics.get("patch13.legacy_selector_calls")===1n&&
    result.context.metrics.get("patch13.predecessor_58_write_sequences")===1n&&
    (result.context.metrics.get("patch13.historical_mismatches")??0n)===
       (result.historicalMismatch?1n:0n),"isolation, frozen result and correct metrics");
  seen.add(result.context);cells++;
 }
 pairsDone++;
}
check(pairsDone===12&&cells===72&&wrong===0&&oldWrong===16&&oldMatches===56&&wide>0,
  "72 real complete histories with 16 preserved legacy errors");

let boundary=0;
for(const n of [2n,3n,5n]){
 const stream={first:M,directionStep:-1n as const};
 const out=selector.choose(stream,n);
 const expected=chooseRank(stream,n);
 check(out.rank===expected&&out.rank!==1n+(M-1n)%n&&
  out.firstCandidate===M&&out.acceptedCandidate===out.acceptanceLimit&&
  out.rejectedCandidates===M-out.acceptanceLimit,
  "top rejection negative direction repaired for three archived red witnesses");
 boundary++;
}
const largeShort=M/2n+1n,limit=(M/largeShort)*largeShort;
const down=selector.choose({first:M,directionStep:-1n},largeShort);
const up=selector.choose({first:M,directionStep:1n},largeShort);
check(down.acceptedCandidate===limit&&down.rejectedCandidates===M-limit&&
  up.acceptedCandidate===1n&&up.rejectedCandidates===1n&&
  down.rejectedCandidates>M/3n&&
  down.rank===largeShort&&up.rank===1n,
  "constant-time skip over enormous exact rejection gap in BOTH directions");
boundary+=2;
const hugeWide=M*M/2n+1n;
const downWide=selector.choose({first:M,directionStep:-1n},hugeWide);
const upWide=selector.choose({first:M-1n,directionStep:1n},hugeWide);
check(downWide.mode==="WIDE"&&downWide.digitCount===2&&
 downWide.answerDigits.join(",")===[M,M-1n].join(",")&&
 downWide.firstCandidate>downWide.acceptanceLimit&&
 downWide.acceptedCandidate===downWide.acceptanceLimit&&
 downWide.rejectedCandidates===downWide.firstCandidate-downWide.acceptanceLimit&&
 downWide.rejectedCandidates>M&&
 upWide.mode==="WIDE"&&upWide.answerDigits.join(",")===[M-1n,M].join(",")&&
 upWide.firstCandidate===M*M-1n&&
 upWide.acceptedCandidate===1n&&upWide.rejectedCandidates===2n,
 "two-digit enormous wide rejection skip with explicit wrap and step");
boundary+=2;
for(const n of [M,M+1n,M*M-1n,M*M,M*M+1n,M*M*M+1n]){
 const x=selector.choose({first:1n,directionStep:1n},n);
 check(x.familySize===n&&x.sampleSpace>=n&&x.rank>=1n&&x.rank<=n&&
  x.digitCount===(n<=M?1:n<=M*M?2:n<=M*M*M?3:4),
  "M^k wide digit and family-size boundaries");
 boundary++;
}
for(const bad of [null,{}, {first:0n,directionStep:1n},
 {first:M+1n,directionStep:-1n},{first:1n,directionStep:0n},
 {first:1n,directionStep:1},{first:"1",directionStep:1n}]){
 check(rejects(()=>selector.choose(bad as never,2n),MonsterValidationError),
   "wrong stream shapes and invalid directions must reject");
}
for(const n of [-1n,0n,2,NaN,null] as unknown[])
 check(rejects(()=>selector.choose({first:1n,directionStep:1n},n as bigint),
   MonsterValidationError),"nonpositive and non-bigint family sizes reject");
const {visible,start}=fixture(F,F),handler=new Patch13RejectionRankHandler(),raw=createMonsterContext(F,F);
check(rejects(()=>handler.run(raw,visible,STONES,start,1,1n,2n),MonsterStageError)&&
 raw.status==="NEW"&&raw.branchTrace.length===0&&raw.metrics.size===0,
 "not-ready context fails before any mutation");
const ready=bootstrapMonster(F,F);
for(const id of [0,7,1.5,NaN,Infinity]){
 check(rejects(()=>handler.run(ready,visible,STONES,start,id,1n,2n),MonsterValidationError),
   "bad ID rejected");
}
for(const arr of [[],[1n],Object.assign(new Array<bigint>(47),{1:1n})]){
 check(rejects(()=>handler.run(ready,arr,STONES,start,1,1n,2n),MonsterValidationError),
  "bad visible drop matrix rejected");
}
for(const rows of [[],STONES.slice(0,46),STONES.map((r,k)=>k===10?[1n]:r)])
 check(rejects(()=>handler.run(ready,visible,rows,start,1,1n,2n),MonsterValidationError),
 "bad stone matrix rejected");
for(const b of [[1n],[1n,2n,3n,4n,5n,1 as unknown as bigint]])
 check(rejects(()=>handler.run(ready,visible,STONES,b,1,1n,2n),MonsterValidationError),
 "bad bowl vector rejected");
check(rejects(()=>handler.run({...ready,targetDay:null as unknown as bigint},
 visible,STONES,start,1,1n,2n),MonsterValidationError)&&
 rejects(()=>handler.run(ready,visible,STONES,start,1,1n,0n),MonsterValidationError)&&
 rejects(()=>handler.run(ready,visible,STONES,start,1,1 as unknown as bigint,2n),
   MonsterValidationError)&&
 ready.metrics.size===1&&ready.status==="VALIDATED"&&
 ready.branchTrace.join(",")==="BOOTSTRAP_VALIDATE","no partial state on input errors");
handler.run(ready,visible,STONES,start,1,1n,2n);
check(rejects(()=>handler.run(ready,visible,STONES,start,1,1n,2n),MonsterStageError),
 "single-use outer context");

let physicalOld=0,physicalNew=0,physicalPrevious=0;
const originalOld=LegacyBiasedModuloRankAdapter.prototype.oldChooseModulo;
const originalNew=Patch13RejectionRankAdapter.prototype.choose;
const originalPrev=Patch12PermutationSuccessorAdapter.prototype.nextFromLatchedPermutation;
try{
 LegacyBiasedModuloRankAdapter.prototype.oldChooseModulo=function(...args){
  physicalOld++;return originalOld.apply(this,args);
 };
 Patch13RejectionRankAdapter.prototype.choose=function(...args){
  physicalNew++;return originalNew.apply(this,args);
 };
 Patch12PermutationSuccessorAdapter.prototype.nextFromLatchedPermutation=function(...args){
  physicalPrevious++;return originalPrev.apply(this,args);
 };
 patch13RejectionRank(F,F,visible,STONES,start,4,1n,2n);
 patch13RejectionRank(F,F,visible,STONES,start,5,20n,M+1n);
 check(physicalOld===2&&physicalNew===2&&physicalPrevious===2,
  "physical old selector and corrected new selector called twice after true Stage25");
}finally{
 LegacyBiasedModuloRankAdapter.prototype.oldChooseModulo=originalOld;
 Patch13RejectionRankAdapter.prototype.choose=originalNew;
 Patch12PermutationSuccessorAdapter.prototype.nextFromLatchedPermutation=originalPrev;
}
let faults=0;
for(const faultAt of ["old","new","before"] as const){
 const ctx=bootstrapMonster(F,F),caller=[...start],signal="PATCH13_INJECT_"+faultAt;
 try{
  if(faultAt==="old")
   LegacyBiasedModuloRankAdapter.prototype.oldChooseModulo=function():never{throw Error(signal);};
  else if(faultAt==="new")
   Patch13RejectionRankAdapter.prototype.choose=function():never{throw Error(signal);};
  else
   Patch12PermutationSuccessorAdapter.prototype.nextFromLatchedPermutation=function():never{throw Error(signal);};
  try{handler.run(ctx,visible,STONES,caller,4,1n,2n);throw Error("missing injection");}
  catch(e){check(e instanceof Error&&e.message===signal,"fault propagated");}
  check(ctx.status==="VALIDATED"&&ctx.branchTrace.join(",")==="BOOTSTRAP_VALIDATE"&&
    ctx.metrics.size===1&&caller.every((v,j)=>v===start[j]),
    "old/new/previous faults leave outer context and inputs unchanged");
  faults++;
 }finally{
  LegacyBiasedModuloRankAdapter.prototype.oldChooseModulo=originalOld;
  Patch13RejectionRankAdapter.prototype.choose=originalNew;
  Patch12PermutationSuccessorAdapter.prototype.nextFromLatchedPermutation=originalPrev;
 }
 const recovered=handler.run(ctx,visible,STONES,caller,4,1n,2n);
 check(recovered.correctedRank===chooseRank(askBowl(sauce(F,F),4,1n),2n),
  "same context safe retry");
}
const left=patch13RejectionRank(F,F,visible,STONES,start,1,1n,2n);
const right=patch13RejectionRank(F,F,visible,STONES,start,1,1n,2n);
left.context.metrics.set("private",61n);left.context.logs.push("डावा");
check(left.context!==right.context&&left.selection!==right.selection&&
 left.selection.answerDigits!==right.selection.answerDigits&&
 left.preceding!==right.preceding&&
 !right.context.metrics.has("private")&&right.context.logs.length===0,
 "independent ownership across reentrant calls");
check(rejects(()=>calendarDateSpaghetti(F,F),MonsterStageError),
  "Stage54 calendar result still unavailable");
console.log("STAGE_27_PATCH_13_GUARDS_PASS dayPairs="+pairsDone+
 " cells="+cells+" mismatches="+wrong+" oldWrong="+oldWrong+
 " oldMatches="+oldMatches+" wide="+wide+" boundaries="+boundary+
 " legacyCalls="+physicalOld+" correctedCalls="+physicalNew+
 " predecessorCalls="+physicalPrevious+" injectedFailures="+faults);
