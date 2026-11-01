import {MonsterStageError,MonsterValidationError} from "./monsterBase.ts";
import type {Patch27FullObservation} from "./patch27MonthMembership.ts";
import type {Patch20StructureRequest} from "./patch20StructureSauce.ts";
import {resolvePatch20FirstDaySauceQuestion} from "./patch20StructureSauce.ts";
import {selectProductionMonthNames} from "./postStage55MonthNames.ts";
import {projectProductionFivePartDate} from "./postStage55FivePartProjection.ts";
import type {ProductionFivePartDate} from "./postStage55FivePartProjection.ts";

// Gate C: typed bridge from a completed PHYSICAL Stage55 chain to five parts.
// The caller must have constructed q from c,t through the production request
// builder and run Patch27 against it; this bridge neither reruns Seal32 nor
// replaces any historical result with a test oracle.
export type ProductionObservedDate=Readonly<{
  date:ProductionFivePartDate;
  yearNativeCalls:number;
  monthNamesNativeCalls:1;
  totalNativeCalls:number;
  totalSharedWrites:bigint;
  stage55AdditionalNativeQueries:0;
  source:"POST_STAGE55_FULL_NATIVE_OBSERVATION_FIVE_PART_DATE";
}>;

export function projectObservedStage55Date(
  q:Patch20StructureRequest,stage55:Patch27FullObservation
):ProductionObservedDate {
  const yrq=q?.historical?.yearQuestion;
  const window=yrq?.verifiedGateWindow;
  if(!yrq||!window||!q.productionConstruction||
     q.productionConstruction.source!=="PRODUCTION_C_T_NATIVE_FACTORY"||
     stage55?.source!=="FULL_STAGE54_PATCH27_DIRECT_MONTH_MEMBERSHIP"||
     stage55.context.status!=="PATCH_27_APPLIED"||
     stage55.context.calculationDay!==yrq.calculationDay||
     stage55.context.targetDay!==yrq.targetDay||
     stage55.additionalNativeQueries!==0||
     stage55.actualSharedWrites!==58n*BigInt(stage55.actualPredecessorCalls))
    throw new MonsterValidationError("सत्यापित production Stage55 Native chain आवश्यक");
  const c=yrq.calculationDay,t=yrq.targetDay;
  // Full Stage55 -> Stage54 -> Stage53 -> Stage52 -> Stage51 -> Stage50
  // -> corrected Stage49 weaving, with immutable historical records retained.
  const p24=stage55.historical.historical.historical.historical.historical.historical;
  const p23=p24.historical.historical;
  const p22=p23.historical.historical;
  const p21=p22.historical.historical;
  const p20=p21.historical.preceding;
  const year=p20.historical.fullStage39.correctedServed.year;
  if(year.number!==p20.trueYearNumber||
     year.openGateDay+1n!==p20.trueYearFirstDay||
     !(year.openGateDay<t&&t<=year.closeGateDay)||
     p21.historical.yearOpenGateIndex!==year.openGateIndex||
     p21.historical.yearCloseGateIndex!==year.closeGateIndex||
     p24.corrected.legalWeaving.length!==Number(year.closeGateDay-year.openGateDay))
    throw new MonsterStageError("Stage41/49 authoritative वर्ष विसंगत");
  const gaps=year.closeGateIndex-year.openGateIndex;
  if(gaps<3n||gaps>5778n)
    throw new MonsterStageError("खऱ्या वर्षातील gate gap संख्या अवैध");
  const measuredGateDays:bigint[]=[];
  for(let idx=year.openGateIndex;idx<=year.closeGateIndex;idx++){
    const day=window.byIndex.get(idx);
    if(day===undefined)
      throw new MonsterStageError("production verified window मधील वर्ष-gate हरवले");
    measuredGateDays.push(day);
  }
  if(measuredGateDays[0]!==year.openGateDay||
     measuredGateDays[measuredGateDays.length-1]!==year.closeGateDay)
    throw new MonsterStageError("year gate दिवस provenance अवैध");
  const firstDayQuestion=resolvePatch20FirstDaySauceQuestion(q,c,p20.trueYearFirstDay);
  const selectedMonthNames=selectProductionMonthNames(
    c,firstDayQuestion,p23.corrected.correctedLengths.length);
  const date=projectProductionFivePartDate(
    p20.trueYearNumber,t,measuredGateDays,
    p21.corrected.correctedPartition,p22.corrected.correctedNameIndices,
    p23.corrected.correctedLengths,p24.corrected.legalWeaving,
    selectedMonthNames.correctedNameIndices);
  const totalNativeCalls=stage55.actualPredecessorCalls+
    selectedMonthNames.actualNativeCalls;
  const totalSharedWrites=stage55.actualSharedWrites+
    selectedMonthNames.actualSharedWrites;
  if(totalSharedWrites!==58n*BigInt(totalNativeCalls))
    throw new MonsterStageError("Native shared writes != 58 * calls");
  return Object.freeze({
    date,yearNativeCalls:stage55.actualPredecessorCalls,
    monthNamesNativeCalls:1 as const,totalNativeCalls,totalSharedWrites,
    stage55AdditionalNativeQueries:0 as const,
    source:"POST_STAGE55_FULL_NATIVE_OBSERVATION_FIVE_PART_DATE" as const
  });
}
