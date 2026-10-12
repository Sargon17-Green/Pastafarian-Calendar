import {
  BaseMetricsManager,bootstrapMonster,MonsterStageError,MonsterValidationError
} from "./monsterBase.ts";
import type {MonsterContext} from "./monsterBase.ts";
import {
  discoverLegacyYear5000Tie,LegacyYear5000LengthOnlySorter
} from "./discovery17LegacyYearTie.ts";
import type {Discovery17LegacyYear5000Observation} from "./discovery17LegacyYearTie.ts";
import type {LegacyYearCandidate,LegacyYearCandidateEntry} from "./discovery16LegacyYearMax.ts";
import type {Patch15SignedQuestion} from "./patch15SignedGate.ts";
import type {Discovery15GateQuestion} from "./discovery15LegacyPositiveGate.ts";
import type {Patch14WideChoiceObservation} from "./patch14WideChoice.ts";
import {patch14WideChoice} from "./patch14WideChoice.ts";

// PATCH 17: जुने stable length-only sort अपरिवर्तित आणि प्रत्यक्ष चालते.
// नंतर फक्त contiguous equal-length runs मध्ये लवकर उघडणारा gate प्रथम.
// नवीन clean two-key global comparator वापरणे निषिद्ध.
export type Patch17TiedRun=Readonly<{
  start:number;
  exclusiveEnd:number;
  length:bigint;
  movedMembers:number;
  originalPositions:readonly number[];
  repairedPositions:readonly number[];
}>;
export type Patch17TieRunResult=Readonly<{
  historical:readonly LegacyYearCandidateEntry[];
  corrected:readonly LegacyYearCandidateEntry[];
  tiedRuns:readonly Patch17TiedRun[];
  examined:number;
  tieRunCount:number;
  tieMemberCount:number;
  movedMembers:number;
  oldHistoricalSortCalls:1;
  oldComparatorCalls:number;
  runSortCalls:number;
  openedDayTieComparisons:number;
}>;

export class Patch17EqualLengthRunSorter {
  private readonly old=new LegacyYear5000LengthOnlySorter();

  sortAfterHistorical(entries:readonly LegacyYearCandidateEntry[]):Patch17TieRunResult {
    // This is a second real invocation of the historical comparator; Stage34
    // also called the same old comparator along its full preceding chain.
    const historical=this.old.oldSortStable(entries);
    const corrected=[...historical.ordered];
    const tiedRuns:Patch17TiedRun[]=[];
    let tiedMembers=0,moved=0,runSortCalls=0,openedDayComparisons=0;

    for(let i=0;i<corrected.length;){
      const start=i,length=corrected[i]!.length;
      while(i<corrected.length&&corrected[i]!.length===length)i++;
      const end=i;
      if(end-start<=1)continue;
      const before=corrected.slice(start,end);
      // Sort just this maximal contiguous run; array outside [start,end)
      // remains precisely as the historical length-only comparator left it.
      let comparisons=0;
      const after=before.map((entry,at)=>({entry,at}));
      after.sort((a,b)=>{
        comparisons++;
        const dayA=a.entry.candidate.openGateDay;
        const dayB=b.entry.candidate.openGateDay;
        return dayA<dayB?-1:dayA>dayB?1:a.at-b.at;
      });
      let changes=0;
      for(let j=0;j<after.length;j++){
        corrected[start+j]=after[j]!.entry;
        if(before[j]!==after[j]!.entry)changes++;
      }
      moved+=changes;tiedMembers+=end-start;runSortCalls++;
      openedDayComparisons+=comparisons;
      tiedRuns.push(Object.freeze({
        start,exclusiveEnd:end,length,movedMembers:changes,
        originalPositions:Object.freeze(before.map(x=>x.originalPosition)),
        repairedPositions:Object.freeze(after.map(x=>x.entry.originalPosition))
      }));
    }
    if(corrected.length!==historical.ordered.length||
      corrected.some((e,j)=>e.length!==historical.ordered[j]!.length))
      throw new MonsterStageError("equal-run दुरुस्तीने वर्ष-length sort बदलता कामा नये");
    return Object.freeze({
      historical:historical.ordered,
      corrected:Object.freeze(corrected),
      tiedRuns:Object.freeze(tiedRuns),
      examined:corrected.length,tieRunCount:tiedRuns.length,
      tieMemberCount:tiedMembers,movedMembers:moved,
      oldHistoricalSortCalls:historical.historicalSortCalls,
      oldComparatorCalls:historical.comparatorCalls,
      runSortCalls,openedDayTieComparisons:openedDayComparisons
    });
  }
}

export type Patch17Year5000Observation=Readonly<{
  calculationDay:bigint;
  signedAnchorIndex:bigint;
  signedAnchorDay:bigint;
  candidateProvenance:"INJECTED_MULTI_OPENING_GATE_BOUNDARIES";
  sorted:Patch17TieRunResult;
  oldSelected:LegacyYearCandidateEntry;
  correctedSelected:LegacyYearCandidateEntry;
  correctedRank:bigint;
  oldRank:bigint;
  legacyTieMismatch:boolean;
  correctedYearSelection:Patch14WideChoiceObservation;
  realYearSelectorCalls:3;
  actualStage34PredecessorCalls:number;
  predecessorCallCount:number;
  predecessorSharedWrites:bigint;
  preceding:Discovery17LegacyYear5000Observation;
  context:MonsterContext;
}>;

export class Patch17Year5000TieHandler {
  private readonly runs=new Patch17EqualLengthRunSorter();
  private readonly metrics=new BaseMetricsManager();

  run(ctx:MonsterContext,signedAnchorIndex:bigint,
      historicalPositive:readonly Discovery15GateQuestion[],
      signedQuestions:readonly Patch15SignedQuestion[],
      yearQuestion:Discovery15GateQuestion,
      anchorCandidates:readonly LegacyYearCandidate[],
      multiOpeningCandidates:readonly LegacyYearCandidate[]
  ):Patch17Year5000Observation {
    if(ctx.phase!=="READY"||ctx.status!=="VALIDATED")
      throw new MonsterStageError("PATCH17 पूर्वी READY/VALIDATED context आवश्यक");
    if(typeof ctx.calculationDay!=="bigint"||
       ctx.calculationDay!==ctx.targetDay||
       typeof signedAnchorIndex!=="bigint"||signedAnchorIndex===0n)
      throw new MonsterValidationError("वैध signed gate anchor व calculationDay आवश्यक");
    // The complete original Stage34 route is physically executed, preserving
    // old 5781 eligibility, late 5778 patch, old length-only tie and seal10.
    const preceding=discoverLegacyYear5000Tie(
      ctx.calculationDay,signedAnchorIndex,historicalPositive,signedQuestions,
      yearQuestion,anchorCandidates,multiOpeningCandidates);
    const sorted=this.runs.sortAfterHistorical(preceding.filter.corrected);
    if(sorted.examined!==preceding.oldSorted.length||
       sorted.historical.some((e,j)=>e!==preceding.oldSorted[j]))
      throw new MonsterStageError("Stage34 चे original stable length-only ledger बदलले");
    const correctedYearSelection=patch14WideChoice(
      ctx.calculationDay,ctx.calculationDay,
      yearQuestion.visible,yearQuestion.stones,yearQuestion.startBowls,
      1,10n,BigInt(sorted.corrected.length));
    if(correctedYearSelection.predecessorSharedWrites!==58||
       correctedYearSelection.realLegacyCalls!==1||
       correctedYearSelection.familySize!==BigInt(sorted.corrected.length)||
       correctedYearSelection.correctedRank!==preceding.oldSelectedRank||
       correctedYearSelection.correctedRank<1n||
       correctedYearSelection.correctedRank>BigInt(sorted.corrected.length))
      throw new MonsterStageError("समान seal10 उत्तराने वेगळी rank निवडली");
    const correctedSelected=sorted.corrected[
      Number(correctedYearSelection.correctedRank-1n)]!;
    const oldSelected=preceding.oldSelected;
    const predecessorCallCount=preceding.predecessorCallCount+1;
    const output=Object.freeze({
      calculationDay:ctx.calculationDay,signedAnchorIndex,
      signedAnchorDay:preceding.signedAnchorDay,
      candidateProvenance:"INJECTED_MULTI_OPENING_GATE_BOUNDARIES" as const,
      sorted,oldSelected,correctedSelected,
      correctedRank:correctedYearSelection.correctedRank,
      oldRank:preceding.oldSelectedRank,
      legacyTieMismatch:oldSelected!==correctedSelected,
      correctedYearSelection,
      realYearSelectorCalls:3 as const,
      actualStage34PredecessorCalls:preceding.predecessorCallCount,
      predecessorCallCount,
      predecessorSharedWrites:BigInt(predecessorCallCount)*58n,
      preceding,context:ctx
    });
    // Single transactional commit to the OUTER context, after every
    // historical sorter and both full Sauce question chains succeed.
    ctx.branchTrace.push("PATCH_17_FULL_DISCOVERY17_HISTORICAL_PREDECESSOR");
    ctx.branchTrace.push("PATCH_17_OLD_STABLE_LENGTH_ONLY_SORT_ACTUALLY_CALLED");
    ctx.branchTrace.push("PATCH_17_ONLY_EQUAL_LENGTH_RUNS_SORT_BY_EARLIER_GATE");
    ctx.branchTrace.push("PATCH_17_REAL_SEAL10_CORRECTED_ORDER");
    this.metrics.bump(ctx,"patch17.calls");
    ctx.metrics.set("patch17.old_length_sort_comparisons",
      BigInt(preceding.realComparatorCalls+sorted.oldComparatorCalls));
    ctx.metrics.set("patch17.equal_length_runs",BigInt(sorted.tieRunCount));
    ctx.metrics.set("patch17.changed_positions",BigInt(sorted.movedMembers));
    ctx.metrics.set("patch17.predecessor_58_write_sequences",BigInt(predecessorCallCount));
    if(output.legacyTieMismatch)this.metrics.bump(ctx,"patch17.legacy_mismatches");
    ctx.status="PATCH_17_APPLIED";
    return output;
  }
}

export function patch17Year5000Tie(calculationDay:bigint,signedAnchorIndex:bigint,
    historicalPositive:readonly Discovery15GateQuestion[],
    signedQuestions:readonly Patch15SignedQuestion[],
    yearQuestion:Discovery15GateQuestion,
    anchorCandidates:readonly LegacyYearCandidate[],
    multiOpeningCandidates:readonly LegacyYearCandidate[]
):Patch17Year5000Observation {
  return new Patch17Year5000TieHandler().run(
    bootstrapMonster(calculationDay,calculationDay),
    signedAnchorIndex,historicalPositive,signedQuestions,
    yearQuestion,anchorCandidates,multiOpeningCandidates);
}
