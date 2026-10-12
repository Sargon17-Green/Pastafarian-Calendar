import {
  BaseMetricsManager,bootstrapMonster,MonsterStageError,MonsterValidationError
} from "./monsterBase.ts";
import type {MonsterContext} from "./monsterBase.ts";
import {
  LegacyYearMaxCandidateFilter,LEGACY_YEAR_MAX
} from "./discovery16LegacyYearMax.ts";
import type {
  LegacyYearCandidate,LegacyYearCandidateEntry,LegacyYearFilterResult
} from "./discovery16LegacyYearMax.ts";
import {patch15SignedGate} from "./patch15SignedGate.ts";
import type {Patch15SignedQuestion,Patch15SignedGateObservation} from "./patch15SignedGate.ts";
import type {Discovery15GateQuestion} from "./discovery15LegacyPositiveGate.ts";
import {patch14WideChoice} from "./patch14WideChoice.ts";
import type {Patch14WideChoiceObservation} from "./patch14WideChoice.ts";

// PATCH 16: जुनी 5781 मर्यादा बदलायची नाही. तिचा filter प्रत्यक्ष चालवल्यावर
// पण योग्य वर्ष-सूचीच्या sort आणि selector आधी 5778 तपासणी करावी.
export const REAL_YEAR_MAX_PATCH=5778n;

export type Patch16YearFilterResult=Readonly<{
  historical:LegacyYearFilterResult;
  corrected:readonly LegacyYearCandidateEntry[];
  excludedLong:readonly LegacyYearCandidateEntry[];
  correctedFamilySize:number;
  historicalFamilySize:number;
  oldPredicateCalls:number;
  appliedCeiling:5778n;
  correctedSortCalls:1;
  historicalSortCalls:1;
  source:"INJECTED_CANDIDATE_BOUNDARIES";
}>;

// The original Stage32 filter really calls the old 5781 predicate on EVERY
// candidate. It keeps its old diagnostic result untouched. Stage33's new
// filter removes 5779..5781 BEFORE constructing/sorting the new family.
// The later Stage35 equal-length tie correction is NOT anticipated.
export class Patch16YearLengthGuard {
  private readonly old=new LegacyYearMaxCandidateFilter();

  apply(candidates:readonly LegacyYearCandidate[]):Patch16YearFilterResult {
    const historical=this.old.filter(candidates);
    // Historical kept was already sorted by its own unchanged method.
    // Use historical ALL (original positions) for the corrected sort.
    const corrected:LegacyYearCandidateEntry[]=[];
    const excludedLong:LegacyYearCandidateEntry[]=[];
    for(const entry of historical.all){
      if(!entry.accepted)continue;
      if(entry.length>REAL_YEAR_MAX_PATCH)excludedLong.push(entry);
      else corrected.push(entry);
    }
    corrected.sort((a,b)=>a.length<b.length?-1:a.length>b.length?1:0);
    if(corrected.some(e=>e.length>REAL_YEAR_MAX_PATCH)|| 
       excludedLong.some(e=>e.length<=REAL_YEAR_MAX_PATCH)||
       corrected.length+excludedLong.length!==historical.kept.length)
      throw new MonsterStageError("5781 historical आणि 5778 patched ledger विसंगत");
    return Object.freeze({
      historical,corrected:Object.freeze(corrected),
      excludedLong:Object.freeze(excludedLong),
      correctedFamilySize:corrected.length,
      historicalFamilySize:historical.kept.length,
      oldPredicateCalls:historical.oldPredicateCalls,
      appliedCeiling:REAL_YEAR_MAX_PATCH as 5778n,
      correctedSortCalls:1 as const,
      historicalSortCalls:historical.oldSortCalls,
      source:"INJECTED_CANDIDATE_BOUNDARIES" as const
    });
  }
}

export type Patch16YearMaxObservation=Readonly<{
  calculationDay:bigint;
  anchorGateIndex:bigint;
  anchorGateDay:bigint;
  candidateSource:"INJECTED_CANDIDATE_BOUNDARIES";
  yearMax:5778n;
  originalOldYearMax:5781n;
  filter:Patch16YearFilterResult;
  selected:LegacyYearCandidateEntry;
  selectedRank:bigint;
  yearSelection:Patch14WideChoiceObservation;
  preceding:Patch15SignedGateObservation;
  realOldPredicateCalls:number;
  realYearSelectorCalls:1;
  predecessorCallCount:number;
  predecessorSharedWrites:bigint;
  context:MonsterContext;
}>;

export class Patch16YearMaxHandler {
  private readonly patched=new Patch16YearLengthGuard();
  private readonly metrics=new BaseMetricsManager();

  run(ctx:MonsterContext,anchorGateIndex:bigint,
      historicalPositive:readonly Discovery15GateQuestion[],
      correctSigned:readonly Patch15SignedQuestion[],
      yearQuestion:Discovery15GateQuestion,
      candidates:readonly LegacyYearCandidate[]):Patch16YearMaxObservation {
    if(ctx.phase!=="READY"||ctx.status!=="VALIDATED")
      throw new MonsterStageError("PATCH16 पूर्वी READY/VALIDATED state आवश्यक");
    if(typeof ctx.calculationDay!=="bigint"||
       typeof ctx.targetDay!=="bigint"||
       ctx.calculationDay!==ctx.targetDay||
       typeof anchorGateIndex!=="bigint"||anchorGateIndex===0n)
      throw new MonsterValidationError("वैध calculationDay आणि nonzero gate index आवश्यक");
    if(!yearQuestion||typeof yearQuestion!=="object"||
       !Array.isArray(yearQuestion.visible)||yearQuestion.visible.length!==47||
       Array.from({length:46},(_,i)=>typeof yearQuestion.visible[i+1]!=="bigint").some(Boolean)||
       !Array.isArray(yearQuestion.stones)||yearQuestion.stones.length!==47||
       Array.from({length:46},(_,i)=>yearQuestion.stones[i+1]).some(row=>
         !Array.isArray(row)||row.length!==5||
         Array.from({length:5},(_,k)=>typeof row[k]!=="bigint").some(Boolean))||
       !Array.isArray(yearQuestion.startBowls)||yearQuestion.startBowls.length!==6||
       yearQuestion.startBowls.some((v:unknown)=>typeof v!=="bigint"))
      throw new MonsterValidationError("वर्ष seal10 प्रश्नाची 46 drops/stones आणि 6 bowls आवश्यक");
    // Full old predicate is executed for all candidate pairs and snapshotted.
    // A 5781-only family is rejected BEFORE any Sauce year-selector call.
    const filtered=this.patched.apply(candidates);
    if(filtered.correctedFamilySize===0)
      throw new MonsterValidationError("योग्य 5778 मर्यादेत वर्ष-मुदतीचा उमेदवार नाही");
    if(candidates.some(c=>c.openGateIndex!==anchorGateIndex))
      throw new MonsterValidationError("सर्व candidate opening gate indices सारखे हवेत");

    // Full Stage31 signed gate path, including Stage30 legacy wrong-side
    // question and all 58-write Stage29 predecessors.
    const preceding=patch15SignedGate(anchorGateIndex,historicalPositive,correctSigned);
    const anchorDay=preceding.correctedGateDay;
    if(ctx.calculationDay!==anchorDay+1n||
       candidates.some(c=>c.openGateDay!==anchorDay||
         !(c.openGateDay<ctx.calculationDay&&ctx.calculationDay<=c.closeGateDay)))
      throw new MonsterValidationError("actual signed gate anchor व year candidate source विसंगत");
    // Corrected year-selector sees ONLY the post-patch family (N=count).
    const yearSelection=patch14WideChoice(ctx.calculationDay,ctx.calculationDay,
      yearQuestion.visible,yearQuestion.stones,yearQuestion.startBowls,
      1,10n,BigInt(filtered.correctedFamilySize));
    if(yearSelection.predecessorSharedWrites!==58||
       yearSelection.realLegacyCalls!==1||
       yearSelection.familySize!==BigInt(filtered.correctedFamilySize)||
       yearSelection.correctedRank<1n||
       yearSelection.correctedRank>BigInt(filtered.correctedFamilySize))
      throw new MonsterStageError("corrected वर्ष निवडीला केवळ 5778-मान्य परिवार मिळायला हवा");
    const selected=filtered.corrected[Number(yearSelection.correctedRank-1n)]!;
    if(selected.length>REAL_YEAR_MAX_PATCH)
      throw new MonsterStageError("5781 फक्त historical ledger मध्ये हवा, selected मध्ये नाही");

    const predecessorCallCount=preceding.totalPredecessorCalls+1;
    const output=Object.freeze({
      calculationDay:ctx.calculationDay,
      anchorGateIndex,anchorGateDay:anchorDay,
      candidateSource:"INJECTED_CANDIDATE_BOUNDARIES" as const,
      yearMax:REAL_YEAR_MAX_PATCH as 5778n,
      originalOldYearMax:LEGACY_YEAR_MAX as 5781n,
      filter:filtered,selected,selectedRank:yearSelection.correctedRank,
      yearSelection,preceding,
      realOldPredicateCalls:filtered.oldPredicateCalls,
      realYearSelectorCalls:1 as const,
      predecessorCallCount,
      predecessorSharedWrites:BigInt(predecessorCallCount)*58n,
      context:ctx
    });
    // Transactional outer owner: all fallible predecessor calls have finished.
    ctx.branchTrace.push("PATCH_16_ACTUAL_PATCH15_SIGNED_GATE_ANCHOR");
    ctx.branchTrace.push("PATCH_16_REAL_5781_HISTORICAL_PREDICATE");
    ctx.branchTrace.push("PATCH_16_FILTER_ABOVE_5778_BEFORE_CORRECTED_SORT");
    ctx.branchTrace.push("PATCH_16_REAL_SEAL10_ON_CORRECTED_FAMILY");
    this.metrics.bump(ctx,"patch16.calls");
    ctx.metrics.set("patch16.real_old_predicate_calls",BigInt(filtered.oldPredicateCalls));
    ctx.metrics.set("patch16.historical_kept",BigInt(filtered.historicalFamilySize));
    ctx.metrics.set("patch16.corrected_kept",BigInt(filtered.correctedFamilySize));
    ctx.metrics.set("patch16.long_rejected",BigInt(filtered.excludedLong.length));
    ctx.metrics.set("patch16.real_predecessor_58_write_sequences",BigInt(predecessorCallCount));
    ctx.status="PATCH_16_APPLIED";
    return output;
  }
}

export function patch16YearMax(calculationDay:bigint,anchorGateIndex:bigint,
  historicalPositive:readonly Discovery15GateQuestion[],
  correctSigned:readonly Patch15SignedQuestion[],
  yearQuestion:Discovery15GateQuestion,
  candidates:readonly LegacyYearCandidate[]):Patch16YearMaxObservation {
  return new Patch16YearMaxHandler().run(
    bootstrapMonster(calculationDay,calculationDay),anchorGateIndex,
    historicalPositive,correctSigned,yearQuestion,candidates);
}
