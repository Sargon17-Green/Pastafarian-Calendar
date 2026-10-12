import {
  bootstrapMonster,createMonsterContext,Patch14WideChoiceDispatcher,
  Patch14WideChoiceHandler,patch14WideChoice,
  Patch13RejectionRankAdapter,LegacyShortOnlyWideSelectionAdapter,
  MonsterStageError,MonsterValidationError,calendarDateSpaghetti
} from "../src/index.ts";
import {
  FOUNDATION_DAY as F,M,STONES,workCounts,buildHiddenDrops,buildVisibleDrops,
  initialBowls,sauce,askBowl,chooseRank
} from "./normativeOracle.ts";
function check(ok:boolean,msg:string):void{if(!ok)throw Error(msg);}
function rejects(fn:()=>unknown,cls:typeof MonsterStageError|typeof MonsterValidationError):boolean{
 try{fn();}catch(e){return e instanceof cls;}return false;
}
function fixture(c:bigint,t:bigint){
 const w=workCounts(c,t),h=buildHiddenDrops(w,STONES);
 return {visible:buildVisibleDrops(w,STONES,h),bowls:initialBowls(w)};
}
const pairs:readonly (readonly [bigint,bigint])[]=[
 [F,F],[F-1n,F],[F+1n,F],[F,F-1n],[F,F+1n],
 [F-89n,F+273n],[F+273n,F-89n],[-278522n,-278522n],
 [-278522n,-268522n],[1n,1n],[100000n,-100000n],[-100000n,100000n]
];
const sizes=[1n,2n,3n,5n,922n,M-1n,M,M+1n,M*M,M*M+1n] as const;
const contexts=new Set<object>();
let real=0,cells=0,short=0,wide=0,mismatches=0,oldWrong=0,oldSame=0;
for(const [c,t] of pairs){
 const {visible,bowls}=fixture(c,t),snapshot=[...bowls],norm=sauce(c,t);
 for(let id=1;id<=6;id++){
  const N=sizes[(real*6+id)%sizes.length]!,seal=[1n,10n,20n,21n,30n,33n][id-1]!;
  const out=patch14WideChoice(c,t,visible,STONES,bowls,id,seal,N);
  const stream=askBowl(norm,id,seal),expected=chooseRank(stream,N),isWide=N>M;
  if(out.correctedRank!==expected)mismatches++;
  if(out.legacyShortOnlyRank!==expected)oldWrong++;else oldSame++;
  if(isWide)wide++;else short++;
  check(out.selection.mode===(isWide?"WIDE":"SHORT")&&
    out.selectionMode===(isWide?"WIDE_CHOICE":"SHORT_LEGACY")&&
    out.correctedRank===out.selection.rank&&
    out.correctedRank===out.preceding.correctedPredecessorRank&&
    out.preceding.preceding.correctedRank===expected&&
    out.preceding.firstAnswer===stream.first&&
    out.preceding.directionStep===stream.directionStep&&
    out.preceding.preceding.preceding.preceding.correctedNextBowlId===
      norm.orderAtDrop46[(norm.orderAtDrop46.indexOf(id)+1)%6]&&
    out.preceding.preceding.preceding.preceding.finalBowls.every((x,j)=>x===norm.bowls[j])&&
    out.preceding.preceding.preceding.preceding.sharedMemoryWrites===58&&
    out.preceding.preceding.preceding.preceding.preceding.historical.memoryWrites===58&&
    out.preceding.preceding.preceding.preceding.preceding.historical.latestSource==="STIR_12"&&
    out.predecessorSharedWrites===58&&out.realLegacyCalls===1&&
    out.extraWideCalls===(isWide?1:0)&&
    out.preceding.legacyShortOnlyCalls===1&&
    out.preceding.blockedWideSelection===isWide&&
    out.preceding.oldResult.blocked===isWide&&
    out.legacyShortOnlyRank===(isWide?0n:expected)&&
    out.historicalMismatch===isWide&&
    out.selection.answerDigits.length===out.selection.digitCount&&
    out.selection.acceptedCandidate<=out.selection.acceptanceLimit&&
    bowls.every((v,j)=>v===snapshot[j]),
    "complete canonical upstream and corrected dispatcher");
  if(isWide)
   check(out.selection.digitCount>=2&&out.preceding.oldResult.shortSelectorCalls===0&&
     out.preceding.oldResult.wideSelectorCalls===0,"wide digits built once; old scar intact");
  else
   check(out.selection===out.preceding.oldResult.shortSelection&&
     out.preceding.oldResult.shortSelectorCalls===1&&
     out.extraWideCalls===0,"reuse actual previous short selection by identity");
  check(Object.isFrozen(out)&&Object.isFrozen(out.selection)&&
    !contexts.has(out.context)&&out.context!==out.preceding.context&&
    out.context.phase==="READY"&&out.context.status==="PATCH_14_APPLIED"&&
    out.context.branchTrace.join(",")=== [
      "BOOTSTRAP_VALIDATE","PATCH_14_COMPLETE_DISCOVERY14_LEGACY_PATH",
      isWide?"PATCH_14_DISPATCH_WIDE_M_ADIC":"PATCH_14_REUSE_REAL_LEGACY_SHORT",
      "PATCH_14_CORRECTED_SELECTION_COMMITTED"
    ].join(",")&&
    out.context.metrics.get("patch14.calls")===1n&&
    out.context.metrics.get("patch14.real_legacy_calls")===1n&&
    out.context.metrics.get("patch14.preceding_58_write_sequences")===1n&&
    (out.context.metrics.get("patch14.wide_dispatches")??0n)===(isWide?1n:0n)&&
    (out.context.metrics.get("patch14.short_legacy_reuses")??0n)===(isWide?0n:1n)&&
    (out.context.metrics.get("patch14.historical_mismatches")??0n)===(isWide?1n:0n),
    "fresh independent outer ctx and metrics");
  contexts.add(out.context);cells++;
 }
 real++;
}
check(real===12&&cells===72&&contexts.size===72&&mismatches===0&&
 oldWrong===wide&&oldSame===short&&short>0&&wide>0,
 "72 full traces corrected with historical wide scar");

const selector=new Patch13RejectionRankAdapter();
const historical=new LegacyShortOnlyWideSelectionAdapter();
let boundaries=0;
for(const N of [1n,2n,3n,M-1n,M,M+1n,M+2n,M*M-1n,M*M,M*M+1n,M*M*M+1n]){
 const stream={first:1n,directionStep:1n as const};
 const h=historical.oldChooseShortOnly(stream,N);
 const reference=chooseRank(stream,N),corrected=selector.choose(stream,N);
 check(corrected.rank===reference&&
 (N>M?h.rank===0n&&h.blocked:h.rank===reference&&!h.blocked),
 "short/wide and M-adic power boundaries");
 boundaries++;
}
const {visible,bowls}=fixture(F,F),handler=new Patch14WideChoiceHandler(),dispatcher=new Patch14WideChoiceDispatcher();
const bogus={} as never;
check(rejects(()=>dispatcher.dispatch(bogus),MonsterValidationError),"invalid historical observation rejected");
const raw=createMonsterContext(F,F);
check(rejects(()=>handler.run(raw,visible,STONES,bowls,1,1n,M+1n),MonsterStageError)&&
 raw.status==="NEW"&&raw.metrics.size===0&&raw.branchTrace.length===0,
 "READY state required");
const ready=bootstrapMonster(F,F);
for(const id of [0,7,1.1,NaN,Infinity,"1" as unknown as number])
 check(rejects(()=>handler.run(ready,visible,STONES,bowls,id,1n,M+1n),MonsterValidationError),
 "malformed bowl id");
for(const N of [0n,-1n,0,null,"2"] as unknown[])
 check(rejects(()=>handler.run(ready,visible,STONES,bowls,1,1n,N as bigint),
 MonsterValidationError),"malformed N");
for(const v of [[],[1n],Object.assign(new Array<bigint>(47),{1:1n})])
 check(rejects(()=>handler.run(ready,v,STONES,bowls,1,1n,2n),MonsterValidationError),
 "malformed drops");
for(const st of [[],STONES.slice(0,46),STONES.map((x,j)=>j===13?[1n]:x)])
 check(rejects(()=>handler.run(ready,visible,st,bowls,1,1n,2n),MonsterValidationError),
 "malformed stones");
for(const b of [[1n],[1n,2n,3n,4n,5n,1 as unknown as bigint]])
 check(rejects(()=>handler.run(ready,visible,STONES,b,1,1n,2n),MonsterValidationError),
 "malformed bowls");
check(ready.status==="VALIDATED"&&ready.metrics.size===1&&
 ready.branchTrace.join(",")==="BOOTSTRAP_VALIDATE","preflight leaves owner untouched");
handler.run(ready,visible,STONES,bowls,1,1n,2n);
check(rejects(()=>handler.run(ready,visible,STONES,bowls,1,1n,2n),MonsterStageError),
 "same committed context cannot be reused");

const oldCall=LegacyShortOnlyWideSelectionAdapter.prototype.oldChooseShortOnly;
const wideCall=Patch13RejectionRankAdapter.prototype.choose;
let actualOld=0,actualWide=0,shortCalls=0;
try{
 LegacyShortOnlyWideSelectionAdapter.prototype.oldChooseShortOnly=function(...args){
  actualOld++;return oldCall.apply(this,args);
 };
 Patch13RejectionRankAdapter.prototype.choose=function(...args){
  if(args[1]>M)actualWide++;else shortCalls++;
  return wideCall.apply(this,args);
 };
 patch14WideChoice(F,F,visible,STONES,bowls,1,1n,2n);
 patch14WideChoice(F,F,visible,STONES,bowls,1,1n,M+1n);
 // short: Stage27 1 + old short 1, wide: Stage27 1 + new wide 1
 check(actualOld===2&&actualWide===2&&shortCalls===2,
  "real old method called both routes; new dispatch adds wide only");
}finally{
 LegacyShortOnlyWideSelectionAdapter.prototype.oldChooseShortOnly=oldCall;
 Patch13RejectionRankAdapter.prototype.choose=wideCall;
}
let faults=0;
for(const place of ["before","old","wide"] as const){
 const ctx=bootstrapMonster(F,F),original=[...bowls],name="INJECT_PATCH14_"+place;
 let wideInvocations=0;
 try{
  if(place==="old")
   LegacyShortOnlyWideSelectionAdapter.prototype.oldChooseShortOnly=function():never{throw Error(name);};
  else
   Patch13RejectionRankAdapter.prototype.choose=function(...args){
    if(args[1]>M)wideInvocations++;
    if(place==="before"||(place==="wide"&&wideInvocations===2))
      throw Error(name);
    return wideCall.apply(this,args);
   };
  const N=place==="wide"?M+1n:2n;
  try{handler.run(ctx,visible,STONES,original,1,1n,N);throw Error("no injection");}
  catch(e){check(e instanceof Error&&e.message===name,"original fault propagated");}
  check(ctx.status==="VALIDATED"&&ctx.metrics.size===1&&
    ctx.branchTrace.join(",")==="BOOTSTRAP_VALIDATE"&&
    original.every((v,j)=>v===bowls[j]),"no outer or caller partial mutation");
  faults++;
 }finally{
  LegacyShortOnlyWideSelectionAdapter.prototype.oldChooseShortOnly=oldCall;
  Patch13RejectionRankAdapter.prototype.choose=wideCall;
 }
 const N=place==="wide"?M+1n:2n;
 check(handler.run(ctx,visible,STONES,original,1,1n,N).correctedRank===
   chooseRank(askBowl(sauce(F,F),1,1n),N),"same context deterministic recovery");
}
const x=patch14WideChoice(F,F,visible,STONES,bowls,1,1n,M+1n),
      y=patch14WideChoice(F,F,visible,STONES,bowls,1,1n,M+1n);
x.context.logs.push("पहिले");x.context.metrics.set("private",2n);
check(x.context!==y.context&&x.preceding!==y.preceding&&x.selection!==y.selection&&
 !y.context.metrics.has("private")&&y.context.logs.length===0,"fresh ownership");
check(rejects(()=>calendarDateSpaghetti(F,F),MonsterStageError),"Stage54 barrier");
console.log("STAGE_29_PATCH_14_GUARDS_PASS pairs="+real+" cells="+cells+
 " short="+short+" wide="+wide+" correctedWrong="+mismatches+
 " oldWrong="+oldWrong+" oldMatches="+oldSame+" boundaries="+boundaries+
 " oldMethodCalls="+actualOld+" wideMethodCalls="+actualWide+
 " shortMethodCalls="+shortCalls+" faultCases="+faults);
