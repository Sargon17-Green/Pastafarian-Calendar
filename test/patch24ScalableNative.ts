import {
 Patch24ScalableFullHandler,Patch24ScalableSelector,
 Discovery24FullHandler,Discovery24LegacySelector,
 Patch23FullHandler,Discovery23FullHandler,Patch22FullHandler,
 Discovery22FullHandler,Patch21CutletHandler,Discovery21LegacyCutletHandler,
 Patch20StructureSauceHandler,Discovery20StructureSauceHandler,
 Patch19YearCacheHandler,Patch14WideChoiceHandler,
 ScalableLegalWeavingCounter,MonsterStageError,
 bootstrapMonster,calendarDateSpaghetti,patch24ScalableLegalWeaving
} from "../src/index.ts";
import {FOUNDATION_DAY as F,sauce,askBowl,chooseRank,weavingFamily}
 from "./normativeOracle.ts";
import {assert,buildStage41CompatibleLegacyFixture} from "./discovery21Fixtures.ts";
const f=buildStage41CompatibleLegacyFixture(),c=f.cDay;
const source=f.request.firstDaySauceQuestion!,reference=sauce(c,source.targetDay);
const L=[4n,4n,5n],old=new Discovery24LegacySelector().select(c,source,L);
const small=new Patch24ScalableSelector().select(c,source,old);
const oracle=weavingFamily(L),Nsmall=oracle.count();
const rank=chooseRank(askBowl(reference,4,32n),Nsmall);
assert(small.exactFamilySize===Nsmall&&small.correctedRank===rank&&
 small.legalWeaving.join(",")===oracle.unrank1(rank).join(",")&&
 small.correctedNativeSeal32.predecessorSharedWrites===58&&
 small.historicalDailyGhostExecuted&&!small.oldGhostReused,
 "small corrected native Bowl4 Seal32 vs independent oracle");
const preceding=()=>new Discovery24FullHandler(new Patch23FullHandler(
 new Discovery23FullHandler(new Patch22FullHandler(
 new Discovery22FullHandler(new Patch21CutletHandler(
 new Discovery21LegacyCutletHandler(new Patch20StructureSauceHandler(
 new Discovery20StructureSauceHandler(new Patch19YearCacheHandler())
))))))));
const maker=()=>new Patch24ScalableFullHandler(preceding());
const full=patch24ScalableLegalWeaving(maker(),f.request);
const corrected=full.corrected;
const N=new ScalableLegalWeavingCounter(corrected.historical.lengths).count();
const independentRank=chooseRank(askBowl(reference,4,32n),N);
const seen=Array<number>(44).fill(0),first:number[]=[],last=Array<number>(44).fill(-1);
for(let i=0;i<corrected.legalWeaving.length;i++){
 const j=corrected.legalWeaving[i]!;
 if(seen[j-1]===0)first.push(j);
 seen[j-1]!++;last[j-1]=i;
}
const ids=Array.from({length:44},(_,i)=>i+1);
const ending=[...ids].sort((a,b)=>last[a-1]!-last[b-1]!);
assert(full.context.status==="PATCH_24_APPLIED"&&
 full.historical.context.status==="DISCOVERY_24_RECORDED"&&
 full.historical.historical.context.status==="PATCH_23_APPLIED"&&
 full.historical.weaving.historicalMonthIdChoice.seal===32n&&
 corrected.correctedNativeSeal32.seal===32n&&
 corrected.correctedNativeSeal32.predecessorSharedWrites===58&&
 corrected.exactFamilySize===N&&corrected.correctedRank===independentRank&&
 corrected.legalWeaving.length===5349&&
 seen.every((v,i)=>v===Number(corrected.historical.lengths[i]))&&
 first.join(",")===ids.join(",")&&ending.join(",")===ids.join(",")&&
 !corrected.oldGhostReused&&
 full.realPredecessorCalls===full.historical.realPredecessorCalls+1&&
 full.realSharedWrites===BigInt(full.realPredecessorCalls)*58n,
 "real full Stage48 predecessor and independently selected legal Year5000 weaving");
const ready=bootstrapMonster(c,f.request.historical.yearQuestion.targetDay);
const original=Patch14WideChoiceHandler.prototype.run;
let seals=0,faulted=0;
try{
 Patch14WideChoiceHandler.prototype.run=function(...args){
  if(args[5]===32n&&++seals===2)
   throw Error("PATCH24_SECOND_NATIVE_SEAL32_FAULT");
  return original.apply(this,args);
 };
 try{maker().run(ready,f.request);throw Error("no fault");}
 catch(e){assert(e instanceof Error&&
  e.message==="PATCH24_SECOND_NATIVE_SEAL32_FAULT","deep fault");}
 assert(seals===2&&ready.status==="VALIDATED"&&
  ready.branchTrace.join(",")==="BOOTSTRAP_VALIDATE"&&
  ready.metrics.size===1,"fault has no caller contamination");faulted++;
}finally{Patch14WideChoiceHandler.prototype.run=original;}
const recovered=maker().run(ready,f.request);
let repeated=false,notIntegrated=false;
try{maker().run(ready,f.request);}catch(e){repeated=e instanceof MonsterStageError;}
try{calendarDateSpaghetti(F,F);}catch(e){notIntegrated=e instanceof MonsterStageError;}
assert(recovered.context===ready&&repeated&&notIntegrated,
 "recover once only; Stage54 barrier unchanged");
console.log("STAGE_49_SCALABLE_NATIVE_PASS realYearDays=5349 realMonths=44"+
 " giantCountBits="+N.toString(2).length+
 " historicalSeal32=1 correctedSeal32=1"+
 " sharedWrites="+full.realSharedWrites+
 " predecessorCalls="+full.realPredecessorCalls+
 " ghostReused=0 deepFaults="+faulted+
 " archivedExpectedReds=24 stage54Blocked=1");
