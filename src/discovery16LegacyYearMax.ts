import {BaseMetricsManager,bootstrapMonster,MonsterStageError,MonsterValidationError} from "./monsterBase.ts";
import type {MonsterContext} from "./monsterBase.ts";
import {patch15SignedGate} from "./patch15SignedGate.ts";
import type {Patch15SignedQuestion,Patch15SignedGateObservation} from "./patch15SignedGate.ts";
import type {Discovery15GateQuestion} from "./discovery15LegacyPositiveGate.ts";
import {patch14WideChoice} from "./patch14WideChoice.ts";
import type {Patch14WideChoiceObservation} from "./patch14WideChoice.ts";

// DISCOVERY 16: जुनी वर्ष-मर्यादा 5781. ही चूक Stage33 पर्यंत दुरुस्त नाही.
// वास्तविक gate anchor आणि प्रत्यक्ष year-selection predecessor चालतात;
// इतर gate boundaries हा मुद्दाम injected candidate fixture input आहे.
export const LEGACY_YEAR_MAX=5781n;
export const LEGACY_YEAR_MIN=252n;
export const LEGACY_YEAR_MIN_GATE_GAPS=6n;

export type LegacyYearCandidate=Readonly<{
  openGateIndex:bigint;
  closeGateIndex:bigint;
  openGateDay:bigint;
  closeGateDay:bigint;
}>;
export type LegacyYearCandidateEntry=Readonly<{
  candidate:LegacyYearCandidate;
  length:bigint;
  accepted:boolean;
  originalPosition:number;
}>;
export type LegacyYearFilterResult=Readonly<{
  examined:number;
  kept:readonly LegacyYearCandidateEntry[];
  rejected:readonly LegacyYearCandidateEntry[];
  all:readonly LegacyYearCandidateEntry[];
  acceptedLongLengths:readonly bigint[];
  oldPredicateCalls:number;
  oldSortCalls:1;
}>;

// This *actual*, intentionally wrong historical gate/year eligibility method
// MUST remain unchanged when Stage33 adds a separate 5778 filter.
export class LegacyYearMaxEligibilityAdapter {
  oldEligibleYear(length:bigint,gateGaps:bigint):boolean {
    if(typeof length!=="bigint"||typeof gateGaps!=="bigint"||
      gateGaps<0n||length<0n)
      throw new MonsterValidationError("वर्षाची लांबी व gate अंतर nonnegative bigint आवश्यक");
    return gateGaps>=LEGACY_YEAR_MIN_GATE_GAPS &&
      length>=LEGACY_YEAR_MIN && length<=LEGACY_YEAR_MAX;
  }
}
export class LegacyYearMaxCandidateFilter {
  private readonly old=new LegacyYearMaxEligibilityAdapter();

  filter(candidates:readonly LegacyYearCandidate[]):LegacyYearFilterResult {
    if(!Array.isArray(candidates)||candidates.length===0)
      throw new MonsterValidationError("किमान एक संभाव्य वर्ष-जोडी आवश्यक");
    // Full all-candidate preflight: no old method is called before this.
    for(const x of candidates){
      if(!x||typeof x!=="object"||typeof x.openGateIndex!=="bigint"||
         typeof x.closeGateIndex!=="bigint"||
         typeof x.openGateDay!=="bigint"||typeof x.closeGateDay!=="bigint"||
         x.closeGateIndex<=x.openGateIndex||
         x.closeGateDay<=x.openGateDay)
        throw new MonsterValidationError("प्रत्येक वर्ष-जोडीला वाढते gate index आणि दिवस आवश्यक");
    }
    const entries:LegacyYearCandidateEntry[]=candidates.map((x,i)=>{
      const length=x.closeGateDay-x.openGateDay;
      const accepted=this.old.oldEligibleYear(length,x.closeGateIndex-x.openGateIndex);
      return Object.freeze({
        candidate:Object.freeze({...x}),length,accepted,originalPosition:i
      });
    });
    // Stage34 tie correction must NOT be anticipated: old stable sort only
    // by length, with no opening-gate tie breaker.
    const kept=entries.filter(e=>e.accepted);
    kept.sort((a,b)=>a.length<b.length?-1:a.length>b.length?1:0);
    const rejected=entries.filter(e=>!e.accepted);
    return Object.freeze({
      examined:candidates.length,kept:Object.freeze(kept),
      rejected:Object.freeze(rejected),all:Object.freeze(entries),
      acceptedLongLengths:Object.freeze(kept.filter(e=>e.length>=5779n).map(e=>e.length)),
      oldPredicateCalls:candidates.length,oldSortCalls:1 as const
    });
  }
}
export type Discovery16YearMaxObservation=Readonly<{
  calculationDay:bigint;
  anchorGateIndex:bigint;
  anchorGateDay:bigint;
  candidateSource:"INJECTED_CANDIDATE_BOUNDARIES";
  filter:LegacyYearFilterResult;
  selected:LegacyYearCandidateEntry;
  selectedRank:bigint;
  yearSelection:Patch14WideChoiceObservation;
  preceding:Patch15SignedGateObservation;
  legacyYearMax:5781n;
  predecessorCallCount:number;
  predecessorSharedWrites:bigint;
  context:MonsterContext;
}>;
export class Discovery16YearMaxHandler {
  private readonly oldFilter=new LegacyYearMaxCandidateFilter();
  private readonly metrics=new BaseMetricsManager();

  run(ctx:MonsterContext,anchorGateIndex:bigint,
      historicalPositive:readonly Discovery15GateQuestion[],
      correctSigned:readonly Patch15SignedQuestion[],
      yearQuestion:Discovery15GateQuestion,
      candidates:readonly LegacyYearCandidate[]):Discovery16YearMaxObservation {
    if(ctx.phase!=="READY"||ctx.status!=="VALIDATED")
      throw new MonsterStageError("DISCOVERY16 पूर्वी READY/VALIDATED context आवश्यक");
    if(typeof ctx.calculationDay!=="bigint"||
      typeof ctx.targetDay!=="bigint"||
      ctx.calculationDay!==ctx.targetDay||
      typeof anchorGateIndex!=="bigint"||anchorGateIndex===0n)
      throw new MonsterValidationError("वर्षाच्या प्रश्नासाठी calculationDay आणि nonzero gate anchor आवश्यक");
    if(!yearQuestion||typeof yearQuestion!=="object"||
       !Array.isArray(yearQuestion.visible)||yearQuestion.visible.length!==47||
       Array.from({length:46},(_,i)=>typeof yearQuestion.visible[i+1]!=="bigint").some(Boolean)||
       !Array.isArray(yearQuestion.stones)||yearQuestion.stones.length!==47||
       Array.from({length:46},(_,i)=>yearQuestion.stones[i+1]).some(row=>
         !Array.isArray(row)||row.length!==5||
         Array.from({length:5},(_,k)=>typeof row[k]!=="bigint").some(Boolean))||
       !Array.isArray(yearQuestion.startBowls)||yearQuestion.startBowls.length!==6||
       yearQuestion.startBowls.some((v:unknown)=>typeof v!=="bigint"))
      throw new MonsterValidationError("वर्षाच्या selection प्रश्नासाठी 46 drops/stones आणि सहा bowls आवश्यक");
    // Validate the injected candidate boundaries BEFORE the expensive
    // genuine signed-gate predecessor chain. The filter is not a repair.
    const filtered=this.oldFilter.filter(candidates);
    if(filtered.kept.length===0)
      throw new MonsterValidationError("जुन्या 5781 मर्यादेमध्ये पात्र वर्ष नाही");
    for(const c of candidates){
      if(c.openGateIndex!==anchorGateIndex)
        throw new MonsterValidationError("candidate open gate चा अंक anchor शी जुळला पाहिजे");
    }

    // Really executes the complete Stage31 route, including the old
    // F+abs(n) mistake, the corrected signed question and 58-write chains.
    const preceding=patch15SignedGate(anchorGateIndex,historicalPositive,correctSigned);
    const anchorDay=preceding.correctedGateDay;
    if(ctx.calculationDay!==anchorDay+1n||
       candidates.some(c=>c.openGateDay!==anchorDay||
         !(c.openGateDay<ctx.calculationDay&&ctx.calculationDay<=c.closeGateDay)))
      throw new MonsterValidationError("वर्ष candidate चा true opening gate आणि calculationDay विसंगत");

    // Genuine production Bowl1/seal10 selection, not a faked test rank.
    const yearSelection=patch14WideChoice(ctx.calculationDay,ctx.calculationDay,
      yearQuestion.visible,yearQuestion.stones,yearQuestion.startBowls,
      1,10n,BigInt(filtered.kept.length));
    if(yearSelection.predecessorSharedWrites!==58||
       yearSelection.realLegacyCalls!==1||
       yearSelection.correctedRank<1n||
       yearSelection.correctedRank>BigInt(filtered.kept.length))
      throw new MonsterStageError("legacy candidates आधी वास्तविक year selector आवश्यक");
    const selected=filtered.kept[Number(yearSelection.correctedRank-1n)]!;
    const predecessorCallCount=preceding.totalPredecessorCalls+1;
    const out=Object.freeze({
      calculationDay:ctx.calculationDay,anchorGateIndex,
      anchorGateDay:anchorDay,
      candidateSource:"INJECTED_CANDIDATE_BOUNDARIES" as const,
      filter:filtered,selected,selectedRank:yearSelection.correctedRank,
      yearSelection,preceding,legacyYearMax:LEGACY_YEAR_MAX as 5781n,
      predecessorCallCount,predecessorSharedWrites:BigInt(predecessorCallCount)*58n,
      context:ctx
    });
    // Outer semantic owner is committed ONLY after all child calls succeed.
    ctx.branchTrace.push("DISCOVERY_16_ACTUAL_PATCH15_SIGNED_GATE_ANCHOR");
    ctx.branchTrace.push("DISCOVERY_16_REAL_LEGACY_5781_CANDIDATE_FILTER");
    ctx.branchTrace.push("DISCOVERY_16_OLD_LENGTH_ONLY_SORT_AND_REAL_SEAL10_SELECTION");
    this.metrics.bump(ctx,"discovery16.calls");
    ctx.metrics.set("discovery16.old_predicate_calls",BigInt(filtered.oldPredicateCalls));
    ctx.metrics.set("discovery16.kept",BigInt(filtered.kept.length));
    ctx.metrics.set("discovery16.long_5779_to_5781_kept",
      BigInt(filtered.acceptedLongLengths.length));
    ctx.metrics.set("discovery16.real_predecessor_58_write_sequences",BigInt(predecessorCallCount));
    ctx.status="DISCOVERY_16_RECORDED";
    return out;
  }
}
export function discoverLegacyYearMax(
  calculationDay:bigint,anchorGateIndex:bigint,
  historicalPositive:readonly Discovery15GateQuestion[],
  correctSigned:readonly Patch15SignedQuestion[],
  yearQuestion:Discovery15GateQuestion,
  candidates:readonly LegacyYearCandidate[]
):Discovery16YearMaxObservation {
  return new Discovery16YearMaxHandler().run(
    bootstrapMonster(calculationDay,calculationDay),anchorGateIndex,
    historicalPositive,correctSigned,yearQuestion,candidates);
}
