import {
  BaseMetricsManager,bootstrapMonster,MonsterStageError,MonsterValidationError
} from "./monsterBase.ts";
import type {MonsterContext} from "./monsterBase.ts";
import {patch17Year5000Tie} from "./patch17Year5000Tie.ts";
import type {Patch17Year5000Observation} from "./patch17Year5000Tie.ts";
import type {LegacyYearCandidate} from "./discovery16LegacyYearMax.ts";
import type {Patch15SignedQuestion} from "./patch15SignedGate.ts";
import type {Discovery15GateQuestion} from "./discovery15LegacyPositiveGate.ts";

// DISCOVERY18 — ऐतिहासिक 365 दिवसांची उडी प्रत्यक्ष चालते, पण फक्त telemetry.
// ही युक्ती authoritative year record ठरवत नाही; स्वतंत्र सलग
// nextYear/previousYear मार्ग Stage37 मध्येच येईल.
export const LEGACY_JUMP_AVERAGE_DAYS=365n;
export const YEAR_5000_ANCHOR_NUMBER=5000n;

export type Legacy365JumpAnchor=Readonly<{
  number:bigint;
  firstDay:bigint;
  lastDay:bigint;
}>;
export type Legacy365JumpProbe=Readonly<{
  anchor:Legacy365JumpAnchor;
  targetDay:bigint;
  signedDeltaDays:bigint;
  quotientBy365:bigint;
  estimatedYearNumber:bigint;
  oldJumpGuessCalls:1;
  targetInsideAnchor:boolean;
  knownAnchorMismatch:boolean|null;
  authoritativeTraversalPerformed:false;
  authoritativeTargetYearResolved:false;
  role:"TELEMETRY_ONLY";
}>;

// BigInt / uses truncation toward zero. The normative historical formula
// requires mathematical floor even for negative deltas.
export function legacyFloorDivPositive(numerator:bigint,denominator:bigint):bigint {
  if(typeof numerator!=="bigint"||typeof denominator!=="bigint"||denominator<=0n)
    throw new MonsterValidationError("floorDiv साठी bigint आणि positive denominator आवश्यक");
  const q=numerator/denominator;
  return numerator<0n&&numerator%denominator!==0n?q-1n:q;
}

export class Legacy365JumpGuessAdapter {
  oldJumpGuess(anchor:Legacy365JumpAnchor,targetDay:bigint):bigint {
    if(!anchor||typeof anchor!=="object"||
       typeof anchor.number!=="bigint"||
       typeof anchor.firstDay!=="bigint"||
       typeof anchor.lastDay!=="bigint"||
       anchor.firstDay>anchor.lastDay||
       typeof targetDay!=="bigint")
      throw new MonsterValidationError("वर्ष anchor आणि target दिनांक अचूक bigint हवेत");
    return anchor.number+
      legacyFloorDivPositive(targetDay-anchor.firstDay,LEGACY_JUMP_AVERAGE_DAYS);
  }
}

export class Legacy365JumpDiagnostic {
  private readonly old=new Legacy365JumpGuessAdapter();

  measure(anchor:Legacy365JumpAnchor,targetDay:bigint):Legacy365JumpProbe {
    // Invoke actual old method. It is NEVER returned as an authoritative
    // year or used to dispatch nextYear/previousYear in Stage36.
    const estimated=this.old.oldJumpGuess(anchor,targetDay);
    const delta=targetDay-anchor.firstDay;
    const inside=targetDay>=anchor.firstDay&&targetDay<=anchor.lastDay;
    return Object.freeze({
      anchor:Object.freeze({...anchor}),targetDay,signedDeltaDays:delta,
      quotientBy365:estimated-anchor.number,
      estimatedYearNumber:estimated,
      oldJumpGuessCalls:1 as const,targetInsideAnchor:inside,
      knownAnchorMismatch:inside?estimated!==anchor.number:null,
      authoritativeTraversalPerformed:false as const,
      authoritativeTargetYearResolved:false as const,
      role:"TELEMETRY_ONLY" as const
    });
  }
}

export type Discovery18JumpObservation=Readonly<{
  calculationDay:bigint;
  targetDay:bigint;
  anchorYearNumber:5000n;
  anchorProvenance:"INJECTED_MULTI_OPENING_GATE_BOUNDARIES";
  selectedAnchor:Legacy365JumpAnchor;
  guess:Legacy365JumpProbe;
  ghostYearNumber:bigint;
  authoritativeTargetYearResolved:false;
  genuineYearSelectionUnaffected:true;
  preceding:Patch17Year5000Observation;
  predecessorCallCount:number;
  predecessorSharedWrites:bigint;
  context:MonsterContext;
}>;

export class Discovery18JumpHandler {
  private readonly diagnostic=new Legacy365JumpDiagnostic();
  private readonly metrics=new BaseMetricsManager();

  run(ctx:MonsterContext,anchorGateIndex:bigint,
      historicalPositive:readonly Discovery15GateQuestion[],
      signedQuestions:readonly Patch15SignedQuestion[],
      yearQuestion:Discovery15GateQuestion,
      anchorCandidates:readonly LegacyYearCandidate[],
      multiOpeningCandidates:readonly LegacyYearCandidate[]):Discovery18JumpObservation {
    if(ctx.phase!=="READY"||ctx.status!=="VALIDATED")
      throw new MonsterStageError("DISCOVERY18 पूर्वी READY/VALIDATED context आवश्यक");
    if(typeof ctx.calculationDay!=="bigint"||
       typeof ctx.targetDay!=="bigint"||
       typeof anchorGateIndex!=="bigint"||anchorGateIndex===0n)
      throw new MonsterValidationError("दोन्ही दिवस आणि signed gate bigint आवश्यक");

    // Full actual Stage35 producer and all original scars are executed.
    // The canonical target-year walking algorithm is NOT implemented here.
    const preceding=patch17Year5000Tie(
      ctx.calculationDay,anchorGateIndex,
      historicalPositive,signedQuestions,yearQuestion,
      anchorCandidates,multiOpeningCandidates);
    const candidate=preceding.correctedSelected.candidate;
    const anchor=Object.freeze({
      number:YEAR_5000_ANCHOR_NUMBER,
      firstDay:candidate.openGateDay+1n,
      lastDay:candidate.closeGateDay
    });
    if(anchor.firstDay>anchor.lastDay)
      throw new MonsterStageError("Stage35 निवडलेली वर्षमर्यादा वैध असावी");
    const guess=this.diagnostic.measure(anchor,ctx.targetDay);
    if(guess.role!=="TELEMETRY_ONLY"||
       guess.authoritativeTraversalPerformed||
       guess.authoritativeTargetYearResolved)
      throw new MonsterStageError("जुनी 365 उडी authoritative कधीच नसावी");
    const output=Object.freeze({
      calculationDay:ctx.calculationDay,
      targetDay:ctx.targetDay,
      anchorYearNumber:YEAR_5000_ANCHOR_NUMBER as 5000n,
      anchorProvenance:"INJECTED_MULTI_OPENING_GATE_BOUNDARIES" as const,
      selectedAnchor:guess.anchor,guess,
      ghostYearNumber:guess.estimatedYearNumber,
      authoritativeTargetYearResolved:false as const,
      genuineYearSelectionUnaffected:true as const,
      preceding,
      predecessorCallCount:preceding.predecessorCallCount,
      predecessorSharedWrites:preceding.predecessorSharedWrites,
      context:ctx
    });
    // Atomic outer-context state commit only AFTER true predecessors and
    // diagnostic guess finish; no yearly steps and no guess-driven selection.
    ctx.branchTrace.push("DISCOVERY_18_FULL_PATCH17_REAL_YEAR5000_SELECTION");
    ctx.branchTrace.push("DISCOVERY_18_OLD_FLOOR_DIV_365_GUESS_ACTUALLY_INVOKED");
    ctx.branchTrace.push("DISCOVERY_18_GHOST_TELEMETRY_NEVER_AUTHORITATIVE");
    this.metrics.bump(ctx,"discovery18.calls");
    ctx.metrics.set("discovery18.old_jump_guess_calls",1n);
    ctx.metrics.set("discovery18.ghost_year_number",guess.estimatedYearNumber);
    ctx.metrics.set("discovery18.in_seed_mismatches",
      guess.knownAnchorMismatch===true?1n:0n);
    ctx.metrics.set("discovery18.predecessor_58_write_sequences",
      BigInt(output.predecessorCallCount));
    ctx.status="DISCOVERY_18_RECORDED";
    return output;
  }
}
export function discoverLegacyJumpGuess(calculationDay:bigint,targetDay:bigint,
    anchorGateIndex:bigint,
    historicalPositive:readonly Discovery15GateQuestion[],
    signedQuestions:readonly Patch15SignedQuestion[],
    yearQuestion:Discovery15GateQuestion,
    anchorCandidates:readonly LegacyYearCandidate[],
    multiOpeningCandidates:readonly LegacyYearCandidate[]
):Discovery18JumpObservation {
  return new Discovery18JumpHandler().run(
    bootstrapMonster(calculationDay,targetDay),anchorGateIndex,
    historicalPositive,signedQuestions,yearQuestion,
    anchorCandidates,multiOpeningCandidates);
}
