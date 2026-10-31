import { MonsterValidationError,MonsterStageError } from "./monsterBase.ts";
import { DISCOVERY15_FOUNDATION_DAY as FOUNDATION } from "./discovery15LegacyPositiveGate.ts";
import type { Discovery15GateQuestion } from "./discovery15LegacyPositiveGate.ts";
import type { Patch15SignedQuestion } from "./patch15SignedGate.ts";
import {
  LEGACY_YEAR_MAX,LEGACY_YEAR_MIN,LEGACY_YEAR_MIN_GATE_GAPS
} from "./discovery16LegacyYearMax.ts";
import type { LegacyYearCandidate } from "./discovery16LegacyYearMax.ts";
import { REAL_YEAR_MAX_PATCH } from "./patch16YearMax.ts";
import type {
  Patch18Question,Patch18VerifiedGateWindow,Patch18TransitionQuestionFactory
} from "./patch18YearWalk.ts";
import { createProductionPatch18Question } from "./postStage55NativeQuestion.ts";
import { createProductionSignedGatePrefix } from "./postStage55SignedGatePrefix.ts";
import type { Discovery19Request } from "./discovery19LegacyYearCache.ts";
import type { Discovery20StructureRequest } from "./discovery20LegacyStructureSauce.ts";
import type {
  Patch20StructureRequest,Patch20ProductionConstruction
} from "./patch20StructureSauce.ts";

export type ProductionPatch20RequestOptions=Readonly<{
  maxGateSteps?:number;
  maximumYearSteps?:number;
}>;

function gateAt(window:Patch18VerifiedGateWindow,index:bigint):bigint {
  const day=window.byIndex.get(index);
  if(day===undefined)throw new MonsterValidationError("production gate map मध्ये index नाही");
  return day;
}
function firstIndexAtOrAfter(window:Patch18VerifiedGateWindow,day:bigint):bigint {
  let low=window.minimumIndex,high=window.maximumIndex+1n;
  while(low<high){
    const mid=low+(high-low)/2n;
    if(mid>window.maximumIndex||gateAt(window,mid)>=day)high=mid;
    else low=mid+1n;
  }
  return low;
}
function buildRealHistoricalCandidates(
  window:Patch18VerifiedGateWindow,calculationDay:bigint,anchor:bigint
):Readonly<{anchor:readonly LegacyYearCandidate[];multi:readonly LegacyYearCandidate[]}> {
  if(gateAt(window,anchor)!==calculationDay-1n)
    throw new MonsterStageError("Stage16 साठी c-1 वर खरा gate आवश्यक");
  const firstOpen=firstIndexAtOrAfter(window,calculationDay-LEGACY_YEAR_MAX);
  const afterLastClose=firstIndexAtOrAfter(window,calculationDay+LEGACY_YEAR_MAX+1n);
  const lastClose=afterLastClose-1n;
  const anchorCandidates:LegacyYearCandidate[]=[];
  const multiCandidates:LegacyYearCandidate[]=[];
  for(let i=firstOpen;i<=lastClose;i++){
    const openDay=gateAt(window,i);
    if(openDay>=calculationDay)break;
    for(let j=i+1n;j<=lastClose;j++){
      const closeDay=gateAt(window,j);
      if(closeDay<calculationDay)continue;
      const length=closeDay-openDay;
      if(length>LEGACY_YEAR_MAX)break;
      if(length<LEGACY_YEAR_MIN||j-i<LEGACY_YEAR_MIN_GATE_GAPS)continue;
      const candidate=Object.freeze({
        openGateIndex:i,closeGateIndex:j,openGateDay:openDay,closeGateDay:closeDay
      });
      multiCandidates.push(candidate);
      if(i===anchor)anchorCandidates.push(candidate);
    }
  }
  const correctedMulti=multiCandidates.filter(x=>
    x.closeGateDay-x.openGateDay<=REAL_YEAR_MAX_PATCH);
  if(anchorCandidates.length===0||correctedMulti.length<2)
    throw new MonsterStageError("खऱ्या gate map मधून पूर्ण Stage16/17 candidate family तयार झाली नाही");
  return Object.freeze({
    anchor:Object.freeze(anchorCandidates),
    multi:Object.freeze(multiCandidates)
  });
}

/** Build the complete production-owned Patch20 request from c,t only.
 * All Native gate calls are real and counted. A non-anchor c explicitly skips
 * only the historical Stage16/17 telemetry; Stage37 still selects the true
 * year from the complete signed gate window. No test oracle or fake candidate
 * is reachable from src/.
 */
export function createProductionPatch20Request(
  calculationDay:bigint,targetDay:bigint,
  options:ProductionPatch20RequestOptions={}
):Patch20StructureRequest {
  if(typeof calculationDay!=="bigint"||typeof targetDay!=="bigint")
    throw new MonsterValidationError("c आणि t हे bigint असणे आवश्यक");
  const maxGateSteps=options.maxGateSteps;
  const maximumYearSteps=options.maximumYearSteps??Number.MAX_SAFE_INTEGER;
  if(!Number.isSafeInteger(maximumYearSteps)||maximumYearSteps<0)
    throw new MonsterValidationError("year-walk execution budget सुरक्षित असावा");
  const prefix=createProductionSignedGatePrefix(calculationDay,targetDay,maxGateSteps);
  const anchor=prefix.signedAnchorIndex;
  let historicalPositive:readonly Discovery15GateQuestion[]=[];
  let signedQuestions:readonly Patch15SignedQuestion[]=[];
  let oldAnchorCandidates:readonly LegacyYearCandidate[]=[];
  let oldMultiCandidates:readonly LegacyYearCandidate[]=[];
  if(anchor!==null){
    const magnitudeBig=anchor<0n?-anchor:anchor;
    if(magnitudeBig>BigInt(Number.MAX_SAFE_INTEGER))
      throw new MonsterValidationError("Stage16 historical question array exceeds safe JS indexing");
    const magnitude=Number(magnitudeBig);
    if(anchor>0n){
      if(prefix.positive.length<magnitude)
        throw new MonsterStageError("positive Stage16 historical question prefix अपूर्ण");
      historicalPositive=Object.freeze(prefix.positive.slice(0,magnitude));
      signedQuestions=Object.freeze(prefix.positive.slice(0,magnitude));
    }else{
      if(prefix.negative.length<magnitude)
        throw new MonsterStageError("negative Stage16 signed question prefix अपूर्ण");
      const oldPositive:Patch18Question[]=[];
      for(let i=1;i<=magnitude;i++)
        oldPositive.push(createProductionPatch18Question(FOUNDATION,FOUNDATION+BigInt(i)));
      historicalPositive=Object.freeze(oldPositive);
      signedQuestions=Object.freeze(prefix.negative.slice(0,magnitude));
    }
    const candidates=buildRealHistoricalCandidates(prefix.verifiedWindow,calculationDay,anchor);
    oldAnchorCandidates=candidates.anchor;
    oldMultiCandidates=candidates.multi;
  }
  const yearQuestion=createProductionPatch18Question(calculationDay,calculationDay);
  const transitionQuestion:Patch18TransitionQuestionFactory=(cc,gateDay,_seal)=>{
    if(cc!==calculationDay)
      throw new MonsterValidationError("transition factory calculationDay mismatch");
    return createProductionPatch18Question(calculationDay,gateDay);
  };
  const yearRequest:Discovery19Request=Object.freeze({
    calculationDay,targetDay,anchorGateIndex:anchor,
    historicalPositive,signedQuestions,
    oldYearQuestion:yearQuestion,
    oldAnchorCandidates,oldMultiCandidates,
    positive:prefix.positive,negative:prefix.negative,
    trueYearQuestion:yearQuestion,
    transitionQuestion,maximumSteps:maximumYearSteps,
    verifiedGateWindow:prefix.verifiedWindow
  });
  const historical:Discovery20StructureRequest=Object.freeze({
    yearQuestion:yearRequest,
    originalSauceQuestion:createProductionPatch18Question(calculationDay,targetDay)
  });
  const firstDaySauceQuestionFactory=(cc:bigint,firstDay:bigint):Patch18Question=>{
    if(cc!==calculationDay||typeof firstDay!=="bigint")
      throw new MonsterValidationError("first-day Sauce factory received foreign owner/day");
    return createProductionPatch18Question(calculationDay,firstDay);
  };
  const productionConstruction:Patch20ProductionConstruction=Object.freeze({
    source:"PRODUCTION_C_T_NATIVE_FACTORY",
    gateNativeCalls:prefix.actualNativeCalls,
    gateSharedWrites:prefix.actualSharedWrites,
    signedAnchorIndex:anchor,
    anchorDiagnostics:anchor===null?
      "SKIPPED_NO_REAL_STAGE16_ANCHOR":"EXECUTED",
    oldAnchorCandidateCount:oldAnchorCandidates.length,
    oldMultiCandidateCount:oldMultiCandidates.length,
    firstDayQuestionDeferred:true
  });
  return Object.freeze({
    historical,firstDaySauceQuestionFactory,productionConstruction
  });
}
