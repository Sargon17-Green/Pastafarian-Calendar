import { MonsterValidationError } from "./monsterBase.ts";
import { createProductionPatch20Request } from "./postStage55ProductionRequest.ts";
import { projectObservedStage55Date } from "./postStage55ObservedDate.ts";
import type { ProductionObservedDate } from "./postStage55ObservedDate.ts";
import type { ProductionFivePartDate } from "./postStage55FivePartProjection.ts";
import { Patch19YearCacheHandler } from "./patch19GuardedYearCache.ts";
import { Discovery20StructureSauceHandler } from "./discovery20LegacyStructureSauce.ts";
import { Patch20StructureSauceHandler } from "./patch20StructureSauce.ts";
import { Discovery21LegacyCutletHandler } from "./discovery21LegacyCutletCompositions.ts";
import { Patch21CutletHandler } from "./patch21FilteredCutletCompositions.ts";
import { Discovery22FullHandler } from "./discovery22LegacyCutletNames.ts";
import { Patch22FullHandler } from "./patch22DistinctCutletNames.ts";
import { Discovery23FullHandler } from "./discovery23LegacyMonthLengthList.ts";
import { Patch23FullHandler } from "./patch23VirtualMonthLengths.ts";
import { Discovery24FullHandler } from "./discovery24LegacyDailyMonths.ts";
import { Patch24ScalableFullHandler } from "./patch24ScalableNativeWeaving.ts";
import { Discovery25FullHandler } from "./discovery25LegacyContiguousMonthDay.ts";
import { Patch25FullHandler } from "./patch25MonthDay.ts";
import { Discovery26FullHandler } from "./discovery26LegacyMonthEnd.ts";
import { Patch26FullHandler } from "./patch26MonthEnd.ts";
import { Discovery27FullHandler } from "./discovery27LegacySpanMembership.ts";
import { Patch27FullHandler, patch27MonthMembership } from "./patch27MonthMembership.ts";

/** Fresh, complete physical Stage19..55 Native chain; no test fixture or oracle. */
function makeFinalStage55():Patch27FullHandler {
  const p19=new Patch19YearCacheHandler();
  const d20=new Discovery20StructureSauceHandler(p19);
  const p20=new Patch20StructureSauceHandler(d20);
  const d21=new Discovery21LegacyCutletHandler(p20);
  const p21=new Patch21CutletHandler(d21);
  const d22=new Discovery22FullHandler(p21);
  const p22=new Patch22FullHandler(d22);
  const d23=new Discovery23FullHandler(p22);
  const p23=new Patch23FullHandler(d23);
  const d24=new Discovery24FullHandler(p23);
  const p24=new Patch24ScalableFullHandler(d24);
  const d25=new Discovery25FullHandler(p24);
  const p25=new Patch25FullHandler(d25);
  const d26=new Discovery26FullHandler(p25);
  const p26=new Patch26FullHandler(d26);
  const d27=new Discovery27FullHandler(p26);
  return new Patch27FullHandler(d27);
}

/** Complete two-bigint factory + Native witness + immutable five-part projection.
 * The Stage55 historical probe is month 1/day 1; the target's actual month is
 * separately determined from legal weaving and checked by the direct PATCH27
 * membership predicate inside projectProductionFivePartDate. We never guess
 * the target month before Stage24 has physically produced the weaving.
 */
export function observeProductionCalendarDate(
  calculationDay:bigint,targetDay:bigint
):ProductionObservedDate {
  if(typeof calculationDay!=="bigint"||typeof targetDay!=="bigint")
    throw new MonsterValidationError("c आणि t हे अचूक bigint असणे आवश्यक");
  const request=createProductionPatch20Request(calculationDay,targetDay);
  const stage55=patch27MonthMembership(makeFinalStage55(),request,1,1);
  const result=projectObservedStage55Date(request,stage55);
  if(result.date.length!==5||!Object.isFrozen(result.date)||
     result.totalSharedWrites!==58n*BigInt(result.totalNativeCalls)||
     result.stage55AdditionalNativeQueries!==0)
    throw new MonsterValidationError("अंतिम पाच-घटक Native परिणाम अवैध");
  return result;
}

/** Public synchronous two-bigint entry point. No foundational module imports
 * the Stage55 chain, avoiding an ESM temporal-dead-zone initialization cycle.
 */
export function calendarDateSpaghetti(
  calculationDay:bigint,targetDay:bigint
):ProductionFivePartDate {
  if(typeof calculationDay!=="bigint"||typeof targetDay!=="bigint")
    throw new MonsterValidationError("दोन्ही दिवस अचूक bigint असणे आवश्यक");
  return observeProductionCalendarDate(calculationDay,targetDay).date;
}
