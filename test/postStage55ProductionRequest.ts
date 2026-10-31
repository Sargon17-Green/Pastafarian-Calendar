import { MonsterValidationError,bootstrapMonster } from "../src/monsterBase.ts";
import { Patch14WideChoiceDispatcher } from "../src/patch14WideChoice.ts";
import { Patch19YearCacheHandler } from "../src/patch19GuardedYearCache.ts";
import { Discovery20StructureSauceHandler } from "../src/discovery20LegacyStructureSauce.ts";
import { Patch20StructureSauceHandler,patch20StructureSauce } from "../src/patch20StructureSauce.ts";
import { createProductionPatch20Request } from "../src/postStage55ProductionRequest.ts";
import { NormativeOracle } from "./normativeOracle.ts";
function ok(b:boolean,m:string):void{if(!b)throw new Error(m);}
function handler():Patch20StructureSauceHandler {
 return new Patch20StructureSauceHandler(
  new Discovery20StructureSauceHandler(new Patch19YearCacheHandler()));
}
const oracle=new NormativeOracle();
const anchorC=oracle.gateDay(1n)+1n;
const seed=oracle.year5000(anchorC);
const next=oracle.nextYear(anchorC,seed);
const previous=oracle.previousYear(anchorC,seed);
const cases=[
 {name:"anchor-next",c:anchorC,t:next.openGateDay+2n,anchor:1n as bigint|null,direction:"NEXT" as const},
 {name:"non-anchor-previous",c:anchorC+1n,t:previous.closeGateDay-1n,anchor:null as bigint|null,direction:"PREVIOUS" as const}
];
let allCalls=0,allWrites=0n,anchorCandidates=0,multiCandidates=0;
for(const item of cases){
 const request=createProductionPatch20Request(item.c,item.t);
 const construction=request.productionConstruction!;
 ok(construction.signedAnchorIndex===item.anchor,
   item.name+" anchor is exact, not fabricated");
 ok(construction.gateSharedWrites===BigInt(construction.gateNativeCalls)*58n,
   item.name+" construction Native accounting");
 ok(request.historical.yearQuestion.verifiedGateWindow!==undefined,
   item.name+" reuses the measured signed window");
 if(item.anchor===null){
  ok(request.historical.yearQuestion.historicalPositive.length===0&&
     request.historical.yearQuestion.signedQuestions.length===0&&
     request.historical.yearQuestion.oldAnchorCandidates.length===0&&
     request.historical.yearQuestion.oldMultiCandidates.length===0&&
     construction.anchorDiagnostics==="SKIPPED_NO_REAL_STAGE16_ANCHOR",
     "non-anchor never fabricates Stage16 inputs");
 }else{
  ok(construction.oldAnchorCandidateCount>0&&construction.oldMultiCandidateCount>=2&&
     construction.anchorDiagnostics==="EXECUTED",
     "anchored Stage16/17 candidates are derived from actual gate boundaries");
  anchorCandidates+=construction.oldAnchorCandidateCount;
  multiCandidates+=construction.oldMultiCandidateCount;
 }
 const expected=oracle.findTargetYear(item.c,item.t);
 if(item.anchor===null){
  const owner=bootstrapMonster(item.c,item.t);
  const h=handler();
  const oldDispatch=Patch14WideChoiceDispatcher.prototype.dispatch;
  let injected=false;
  try{
   Patch14WideChoiceDispatcher.prototype.dispatch=function(...args:Parameters<typeof oldDispatch>){
    if(!injected){injected=true;throw new Error("POST_STAGE55_REQUEST_DEEP_FAULT");}
    return oldDispatch.apply(this,args);
   };
   try{h.run(owner,request);throw new Error("fault not reached");}
   catch(e){ok(e instanceof Error&&e.message==="POST_STAGE55_REQUEST_DEEP_FAULT",
     "deep predecessor fault propagated");}
  }finally{Patch14WideChoiceDispatcher.prototype.dispatch=oldDispatch;}
  ok(injected&&owner.status==="VALIDATED"&&
     owner.branchTrace.join(",")==="BOOTSTRAP_VALIDATE"&&owner.metrics.size===1,
     "failed deep predecessor leaves caller owner uncommitted");
 }
 const out=patch20StructureSauce(handler(),request);
 const walk=out.historical.fullStage39.originalWrongHistory.preceding;
 ok(walk.legacyDiagnostic===(item.anchor===null?
    "SKIPPED_NO_REAL_STAGE16_ANCHOR":"EXECUTED")&&
    (item.anchor===null?walk.legacy===null:walk.legacy!==null),
    item.name+" Stage16 applicability is explicitly represented");
 ok(walk.authoritative.steps.length===1&&
    (item.direction==="NEXT"?
      walk.authoritative.forwardSteps===1&&walk.authoritative.backwardSteps===0:
      walk.authoritative.backwardSteps===1&&walk.authoritative.forwardSteps===0),
    item.name+" one-step legal year traversal");
 ok(out.trueYearNumber===expected.number&&
    out.trueYearFirstDay===expected.openGateDay+1n&&
    out.authoritativeFirstDay===expected.openGateDay+1n,
    item.name+" actual target-year walk matches independent oracle");
 ok(out.historicalOldSauceActuallyCalled&&out.oldSauceCalls===1&&
    out.firstDaySauceCalls===1&&out.requiredFirstDaySubstitution&&
    out.historicalGhostWasWrongTarget,
    item.name+" original-target Sauce and true first-day Sauce both executed");
 ok(out.productionConstruction===construction&&
    out.totalSharedMemoryWrites===BigInt(out.totalRealPredecessorCalls)*58n,
    item.name+" end-to-end Native calls and writes reconcile");
 allCalls+=out.totalRealPredecessorCalls;
 allWrites+=out.totalSharedMemoryWrites;
}
ok(allWrites===BigInt(allCalls)*58n,"combined request accounting reconciles");
let rejected=0;
for(const [c,t,options] of [
 [0,1n,{}],[0n,"x",{}],[1n,1n,{maxGateSteps:0}],
 [1n,1n,{maximumYearSteps:-1}]
] as unknown as [bigint,bigint,{maxGateSteps?:number;maximumYearSteps?:number}][]){
 try{createProductionPatch20Request(c,t,options);}
 catch(e){if(e instanceof MonsterValidationError)rejected++;}
}
ok(rejected===4,"invalid production request inputs rejected before use");
console.log("POST_STAGE55_PATCH20_REQUEST_PASS cases=2 anchored=1 nonAnchor=1 " +
 "anchorCandidates="+anchorCandidates+" multiCandidates="+multiCandidates+
 " totalNativeCalls="+allCalls+" totalSharedWrites="+allWrites+
 " rollback=1 oracleYears=2 forwardSteps=1 backwardSteps=1 malformedRejected="+rejected);
