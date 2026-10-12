import { BaseMetricsManager,bootstrapMonster,MonsterStageError,MonsterValidationError } from "./monsterBase.ts";
import type { MonsterContext } from "./monsterBase.ts";
import { LEGACY_MODULUS } from "./discovery01LegacyRemainder.ts";
import { discoverLegacyShortOnlyWide } from "./discovery14LegacyShortOnlyWide.ts";
import type { Discovery14ShortOnlyObservation } from "./discovery14LegacyShortOnlyWide.ts";
import { Patch13RejectionRankAdapter } from "./patch13RejectionRank.ts";
import type { Patch13RankSelection } from "./patch13RejectionRank.ts";

// PATCH 14: जुना short-only helper तसाच, त्याची खरी call अगोदर Stage28
// मार्गातून होते. N>M असेल तेव्हाच स्वतंत्र wide-choice dispatcher चालतो.
// Wide choice ची M-अंकी संख्या प्रारंभिक उत्तरांमधून एकदाच तयार केली जाते;
// rejection झाल्यास पूर्ण संख्येवर ±1 cyclic पाऊल लागू होते.
export type Patch14DispatchResult=Readonly<{
  mode:"SHORT_LEGACY"|"WIDE_CHOICE";
  familySize:bigint;
  correctedRank:bigint;
  legacyRank:bigint;
  historicalMismatch:boolean;
  wideSelectorCalls:0|1;
  shortSelectionReused:boolean;
  selection:Patch13RankSelection;
}>;

export class Patch14WideChoiceDispatcher {
  private readonly wide=new Patch13RejectionRankAdapter();

  dispatch(earlier:Discovery14ShortOnlyObservation):Patch14DispatchResult {
    if(typeof earlier!=="object"||earlier===null||
      typeof earlier.familySize!=="bigint"||earlier.familySize<1n||
      typeof earlier.firstAnswer!=="bigint"||earlier.firstAnswer<1n||
      earlier.firstAnswer>LEGACY_MODULUS||
      (earlier.directionStep!==1n&&earlier.directionStep!==-1n)||
      typeof earlier.correctedPredecessorRank!=="bigint"||
      typeof earlier.legacyShortOnlyRank!=="bigint"||
      typeof earlier.oldResult!=="object"||earlier.oldResult===null||
      earlier.oldResult.familySize!==earlier.familySize||
      earlier.oldResult.rank!==earlier.legacyShortOnlyRank||
      earlier.blockedWideSelection!==(earlier.familySize>LEGACY_MODULUS))
      throw new MonsterValidationError("पूर्ण व वैध Stage28 observation आवश्यक");

    const isWide=earlier.familySize>LEGACY_MODULUS;
    let selection:Patch13RankSelection;
    if(isWide){
      if(!earlier.oldResult.blocked||earlier.oldResult.rank!==0n||
        earlier.oldResult.shortSelection!==null||
        earlier.oldResult.shortSelectorCalls!==0||
        earlier.oldResult.wideSelectorCalls!==0)
        throw new MonsterStageError("जुन्या N>M मार्गाचे BLOCKED/0 पुरावे आवश्यक");
      // Real independent production wide method invocation, not Stage29
      // shortcut to Stage27's prior rank. The original stage28 scar remains.
      selection=this.wide.choose({
        first:earlier.firstAnswer,directionStep:earlier.directionStep
      },earlier.familySize);
      if(selection.mode!=="WIDE"||selection.digitCount<2)
        throw new MonsterStageError("M-अंकी Wide Choice dispatch झाला नाही");
    }else{
      // Legacy short method was actually invoked by Stage28; reuse
      // its original successful selection, no secondary wide call.
      if(earlier.oldResult.blocked||earlier.oldResult.shortSelectorCalls!==1||
         earlier.oldResult.shortSelection===null||
         earlier.oldResult.shortSelection.mode!=="SHORT"||
         earlier.oldResult.rank!==earlier.oldResult.shortSelection.rank)
        throw new MonsterStageError("मूळ सत्यापित short selection अनिवार्य");
      selection=earlier.oldResult.shortSelection;
    }
    if(selection.rank!==earlier.correctedPredecessorRank||
      selection.rank<1n||selection.rank>earlier.familySize)
      throw new MonsterStageError("PATCH14 dispatch आणि Stage27 उत्तर वेगळे");
    return Object.freeze({
      mode:isWide?"WIDE_CHOICE" as const:"SHORT_LEGACY" as const,
      familySize:earlier.familySize,correctedRank:selection.rank,
      legacyRank:earlier.legacyShortOnlyRank,
      historicalMismatch:selection.rank!==earlier.legacyShortOnlyRank,
      wideSelectorCalls:isWide?1 as const:0 as const,
      shortSelectionReused:!isWide,selection
    });
  }
}

export type Patch14WideChoiceObservation=Readonly<{
  queriedBowlId:number;
  seal:bigint;
  familySize:bigint;
  correctedRank:bigint;
  legacyShortOnlyRank:bigint;
  historicalMismatch:boolean;
  selectionMode:"SHORT_LEGACY"|"WIDE_CHOICE";
  selection:Patch13RankSelection;
  realLegacyCalls:1;
  extraWideCalls:0|1;
  predecessorSharedWrites:58;
  preceding:Discovery14ShortOnlyObservation;
  context:MonsterContext;
}>;

export class Patch14WideChoiceHandler {
  private readonly dispatcher=new Patch14WideChoiceDispatcher();
  private readonly metrics=new BaseMetricsManager();

  run(ctx:MonsterContext,visible:readonly bigint[],
    stones:readonly (readonly bigint[])[],startBowls:readonly bigint[],
    id:number,seal:bigint,N:bigint):Patch14WideChoiceObservation {
    if(ctx.phase!=="READY"||ctx.status!=="VALIDATED")
      throw new MonsterStageError("PATCH14 पूर्वी वैध READY context आवश्यक");
    if(typeof ctx.calculationDay!=="bigint"||typeof ctx.targetDay!=="bigint"||
      !Number.isInteger(id)||id<1||id>6||
      typeof seal!=="bigint"||typeof N!=="bigint"||N<1n||
      !Array.isArray(visible)||visible.length!==47||
      Array.from({length:46},(_,k)=>typeof visible[k+1]!=="bigint").some(Boolean)||
      !Array.isArray(stones)||stones.length!==47||
      Array.from({length:46},(_,k)=>stones[k+1]).some(row=>
        !Array.isArray(row)||row.length!==5||
        Array.from({length:5},(_,j)=>typeof row[j]!=="bigint").some(Boolean))||
      !Array.isArray(startBowls)||startBowls.length!==6||
      Array.from({length:6},(_,k)=>typeof startBowls[k]!=="bigint").some(Boolean))
      throw new MonsterValidationError("46 थेंब, 46 दगड, सहा वाट्या, ID, seal व N हवेत");

    // Fully real Stage28 path (Stage27, Stage26, Stage25): 58 writes;
    // historical oldChooseShortOnly is really called once on a child context.
    const preceding=discoverLegacyShortOnlyWide(ctx.calculationDay,ctx.targetDay,
      visible,stones,startBowls,id,seal,N);
    if(preceding.predecessorSharedMemoryWrites!==58||
      preceding.legacyShortOnlyCalls!==1||
      preceding.preceding.predecessorSharedMemoryWrites!==58||
      preceding.preceding.preceding.legacyModuloCalls!==1||
      preceding.preceding.preceding.preceding.latchCaptures!==1||
      preceding.preceding.preceding.preceding.preceding.historical.latestSource!=="STIR_12")
      throw new MonsterStageError("Stage28 ची पूर्ण ऐतिहासिक साखळी आवश्यक");

    const picked=this.dispatcher.dispatch(preceding);
    const out=Object.freeze({
      queriedBowlId:id,seal,familySize:N,
      correctedRank:picked.correctedRank,
      legacyShortOnlyRank:preceding.legacyShortOnlyRank,
      historicalMismatch:picked.historicalMismatch,
      selectionMode:picked.mode,
      selection:picked.selection,
      realLegacyCalls:1 as const,extraWideCalls:picked.wideSelectorCalls,
      predecessorSharedWrites:58 as const,preceding,context:ctx
    });
    // No observable writes to caller's context until all computations commit.
    ctx.branchTrace.push("PATCH_14_COMPLETE_DISCOVERY14_LEGACY_PATH");
    ctx.branchTrace.push(picked.mode==="WIDE_CHOICE"?
      "PATCH_14_DISPATCH_WIDE_M_ADIC":"PATCH_14_REUSE_REAL_LEGACY_SHORT");
    ctx.branchTrace.push("PATCH_14_CORRECTED_SELECTION_COMMITTED");
    this.metrics.bump(ctx,"patch14.calls");
    this.metrics.bump(ctx,"patch14.real_legacy_calls");
    this.metrics.bump(ctx,"patch14.preceding_58_write_sequences");
    this.metrics.bump(ctx,picked.mode==="WIDE_CHOICE"?
      "patch14.wide_dispatches":"patch14.short_legacy_reuses");
    if(picked.historicalMismatch)this.metrics.bump(ctx,"patch14.historical_mismatches");
    ctx.status="PATCH_14_APPLIED";
    return out;
  }
}

export function patch14WideChoice(c:bigint,t:bigint,
  visible:readonly bigint[],stones:readonly (readonly bigint[])[],
  startBowls:readonly bigint[],id:number,seal:bigint,N:bigint
):Patch14WideChoiceObservation {
  return new Patch14WideChoiceHandler().run(
    bootstrapMonster(c,t),visible,stones,startBowls,id,seal,N);
}
