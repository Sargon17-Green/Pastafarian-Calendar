import {
  BaseMetricsManager,bootstrapMonster,MonsterStageError,MonsterValidationError
} from "./monsterBase.ts";
import type {MonsterContext} from "./monsterBase.ts";
import {Patch16YearLengthGuard,patch16YearMax} from "./patch16YearMax.ts";
import type {Patch16YearFilterResult,Patch16YearMaxObservation} from "./patch16YearMax.ts";
import type {LegacyYearCandidate,LegacyYearCandidateEntry} from "./discovery16LegacyYearMax.ts";
import type {Patch15SignedQuestion} from "./patch15SignedGate.ts";
import type {Discovery15GateQuestion} from "./discovery15LegacyPositiveGate.ts";
import {patch14WideChoice} from "./patch14WideChoice.ts";
import type {Patch14WideChoiceObservation} from "./patch14WideChoice.ts";

// DISCOVERY 17: जुना Year5000 sort केवळ length वर stable आहे.
// समान लांबीच्या वर्षांसाठी gate-opening दिन लवकर असण्याचा नियम
// Stage35 PATCH17 पर्यंत लागू करू नये. जुना comparator खरोखर चालवा.
export class LegacyYear5000LengthOnlySorter {
  oldLengthCompare(a:LegacyYearCandidateEntry,b:LegacyYearCandidateEntry):number {
    if(typeof a?.length!=="bigint"||typeof b?.length!=="bigint")
      throw new MonsterValidationError("मूळ वर्ष-length comparator साठी दोन bigint वर्षे आवश्यक");
    return a.length<b.length?-1:a.length>b.length?1:0;
  }
  oldSortStable(entries:readonly LegacyYearCandidateEntry[]):Readonly<{
    ordered:readonly LegacyYearCandidateEntry[];
    comparatorCalls:number;
    historicalSortCalls:1;
  }> {
    if(!Array.isArray(entries)||entries.length===0||
       entries.some(e=>!e||typeof e.length!=="bigint"||
          typeof e.originalPosition!=="number"||
          !e.candidate||typeof e.candidate.openGateDay!=="bigint"))
      throw new MonsterValidationError("जुना stable sort केवळ पूर्ण वर्ष-जोडींवर");
    let comparatorCalls=0;
    const decorated=entries.map((entry,index)=>({entry,index}));
    // Actual old length comparator. Explicit original-position fallback
    // preserves stable behavior even on runtimes with different sort engines.
    decorated.sort((a,b)=>{
      comparatorCalls++;
      const relative=this.oldLengthCompare(a.entry,b.entry);
      return relative!==0?relative:a.index-b.index;
    });
    return Object.freeze({
      ordered:Object.freeze(decorated.map(d=>d.entry)),
      comparatorCalls,historicalSortCalls:1 as const
    });
  }
}

export type Discovery17LegacyYear5000Observation=Readonly<{
  calculationDay:bigint;
  signedAnchorIndex:bigint;
  signedAnchorDay:bigint;
  provenance:"INJECTED_MULTI_OPENING_GATE_BOUNDARIES";
  oldSorted:readonly LegacyYearCandidateEntry[];
  filter:Patch16YearFilterResult;
  oldSelected:LegacyYearCandidateEntry;
  oldSelectedRank:bigint;
  lengthTieInversions:number;
  tiedDistinctOpeningDays:boolean;
  realComparatorCalls:number;
  oldStableSortCalls:1;
  realYearSelectorCalls:2;
  preceding:Patch16YearMaxObservation;
  yearSelection:Patch14WideChoiceObservation;
  predecessorCallCount:number;
  predecessorSharedWrites:bigint;
  context:MonsterContext;
}>;

export class Discovery17Year5000TieHandler {
  private readonly correctedLimit=new Patch16YearLengthGuard();
  private readonly stableOld=new LegacyYear5000LengthOnlySorter();
  private readonly metrics=new BaseMetricsManager();

  run(ctx:MonsterContext,signedAnchorIndex:bigint,
    historicalPositive:readonly Discovery15GateQuestion[],
    signedQuestions:readonly Patch15SignedQuestion[],
    yearQuestion:Discovery15GateQuestion,
    anchorCandidates:readonly LegacyYearCandidate[],
    multiOpeningCandidates:readonly LegacyYearCandidate[]
  ):Discovery17LegacyYear5000Observation {
    if(ctx.phase!=="READY"||ctx.status!=="VALIDATED")
      throw new MonsterStageError("DISCOVERY17 पूर्वी READY/VALIDATED state आवश्यक");
    if(typeof ctx.calculationDay!=="bigint"||
       ctx.calculationDay!==ctx.targetDay||
       typeof signedAnchorIndex!=="bigint"||signedAnchorIndex===0n)
      throw new MonsterValidationError("valid calculationDay व signed anchor आवश्यक");
    if(!Array.isArray(multiOpeningCandidates)||
       multiOpeningCandidates.length<2)
      throw new MonsterValidationError("किमान दोन distinct year candidates हवेत");
    // Stage33 guard validates ALL historical raw candidates through its
    // original 5781 predicate and the 5778 patch, before any sort here.
    const filtered=this.correctedLimit.apply(multiOpeningCandidates);
    if(filtered.correctedFamilySize<2)
      throw new MonsterValidationError("historical tie comparison साठी दोन वैध वर्षे आवश्यक");
    for(const e of filtered.historical.all){
      const c=e.candidate;
      if(!(c.openGateDay<ctx.calculationDay&&ctx.calculationDay<=c.closeGateDay))
        throw new MonsterValidationError("प्रत्येक injected वर्ष calculationDay व्यापायला हवे");
    }
    if(!yearQuestion||typeof yearQuestion!=="object"||
       !Array.isArray(yearQuestion.visible)||yearQuestion.visible.length!==47||
       Array.from({length:46},(_,k)=>typeof yearQuestion.visible[k+1]!=="bigint").some(Boolean)||
       !Array.isArray(yearQuestion.stones)||yearQuestion.stones.length!==47||
       Array.from({length:46},(_,k)=>yearQuestion.stones[k+1]).some(row=>
         !Array.isArray(row)||row.length!==5||
         Array.from({length:5},(_,j)=>typeof row[j]!=="bigint").some(Boolean))||
       !Array.isArray(yearQuestion.startBowls)||yearQuestion.startBowls.length!==6||
       yearQuestion.startBowls.some((v:unknown)=>typeof v!=="bigint"))
      throw new MonsterValidationError("seal10 year-question source अपूर्ण");

    // Full Stage33 production is actually executed, including the old
    // 5781 candidate predicate, signed Stage31 gate and genuine seal10.
    const preceding=patch16YearMax(ctx.calculationDay,signedAnchorIndex,
      historicalPositive,signedQuestions,yearQuestion,anchorCandidates);
    const anchorDay=preceding.anchorGateDay;
    if(ctx.calculationDay!==anchorDay+1n)
      throw new MonsterStageError("खरा gate anchor आवश्यक");
    if(multiOpeningCandidates.every(c=>c.openGateDay!==anchorDay))
      throw new MonsterValidationError("किमान एक candidate खऱ्या anchor day वर उघडायला हवा");

    // Exactly the intentionally wrong historical sort, *physically* run.
    // Do not apply a tie correction or call a two-key comparator here.
    const sorted=this.stableOld.oldSortStable(filtered.corrected);
    let inversions=0;
    let distinct=false;
    for(let i=0;i<sorted.ordered.length;i++){
      const a=sorted.ordered[i]!;
      for(let j=i+1;j<sorted.ordered.length&&
          sorted.ordered[j]!.length===a.length;j++){
        const b=sorted.ordered[j]!;
        if(a.candidate.openGateDay!==b.candidate.openGateDay)distinct=true;
        if(a.candidate.openGateDay>b.candidate.openGateDay)inversions++;
      }
    }
    const yearSelection=patch14WideChoice(ctx.calculationDay,ctx.calculationDay,
      yearQuestion.visible,yearQuestion.stones,yearQuestion.startBowls,
      1,10n,BigInt(sorted.ordered.length));
    if(yearSelection.predecessorSharedWrites!==58||
       yearSelection.realLegacyCalls!==1||
       yearSelection.familySize!==BigInt(sorted.ordered.length)||
       yearSelection.correctedRank<1n||
       yearSelection.correctedRank>BigInt(sorted.ordered.length))
      throw new MonsterStageError("मूळ length-only list नंतर खरा seal10 selector");
    const oldSelected=sorted.ordered[Number(yearSelection.correctedRank-1n)]!;
    const predecessorCallCount=preceding.predecessorCallCount+1;
    const output=Object.freeze({
      calculationDay:ctx.calculationDay,signedAnchorIndex,
      signedAnchorDay:anchorDay,
      provenance:"INJECTED_MULTI_OPENING_GATE_BOUNDARIES" as const,
      oldSorted:sorted.ordered,filter:filtered,oldSelected,
      oldSelectedRank:yearSelection.correctedRank,
      lengthTieInversions:inversions,tiedDistinctOpeningDays:distinct,
      realComparatorCalls:sorted.comparatorCalls,
      oldStableSortCalls:sorted.historicalSortCalls,
      realYearSelectorCalls:2 as const,
      preceding,yearSelection,predecessorCallCount,
      predecessorSharedWrites:BigInt(predecessorCallCount)*58n,
      context:ctx
    });
    ctx.branchTrace.push("DISCOVERY_17_FULL_PATCH16_REAL_GATE_AND_YEAR");
    ctx.branchTrace.push("DISCOVERY_17_OLD_STABLE_LENGTH_ONLY_COMPARATOR");
    ctx.branchTrace.push("DISCOVERY_17_REAL_SEAL10_UNCORRECTED_TIE_SELECTION");
    this.metrics.bump(ctx,"discovery17.calls");
    ctx.metrics.set("discovery17.extra_legacy_predicate_calls",BigInt(filtered.oldPredicateCalls));
    ctx.metrics.set("discovery17.old_comparator_calls",BigInt(sorted.comparatorCalls));
    ctx.metrics.set("discovery17.uncorrected_tie_inversions",BigInt(inversions));
    ctx.metrics.set("discovery17.predecessor_58_write_sequences",BigInt(predecessorCallCount));
    ctx.status="DISCOVERY_17_RECORDED";
    return output;
  }
}

export function discoverLegacyYear5000Tie(calculationDay:bigint,signedAnchorIndex:bigint,
  historicalPositive:readonly Discovery15GateQuestion[],
  signedQuestions:readonly Patch15SignedQuestion[],
  yearQuestion:Discovery15GateQuestion,
  anchorCandidates:readonly LegacyYearCandidate[],
  multiOpeningCandidates:readonly LegacyYearCandidate[]
):Discovery17LegacyYear5000Observation {
  return new Discovery17Year5000TieHandler().run(
    bootstrapMonster(calculationDay,calculationDay),signedAnchorIndex,
    historicalPositive,signedQuestions,yearQuestion,
    anchorCandidates,multiOpeningCandidates);
}
