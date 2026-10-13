import {BaseMetricsManager,bootstrapMonster,MonsterStageError,MonsterValidationError} from "./monsterBase.ts";
import type {MonsterContext} from "./monsterBase.ts";
import {DISCOVERY15_FOUNDATION_DAY} from "./discovery15LegacyPositiveGate.ts";
import type {Discovery15GateQuestion} from "./discovery15LegacyPositiveGate.ts";
import type {Patch15SignedQuestion} from "./patch15SignedGate.ts";
import type {LegacyYearCandidate,LegacyYearCandidateEntry} from "./discovery16LegacyYearMax.ts";
import {Patch16YearLengthGuard,REAL_YEAR_MAX_PATCH} from "./patch16YearMax.ts";
import {Patch17EqualLengthRunSorter} from "./patch17Year5000Tie.ts";
import {patch14WideChoice} from "./patch14WideChoice.ts";
import type {Patch14WideChoiceObservation} from "./patch14WideChoice.ts";
import {discoverLegacyJumpGuess,Legacy365JumpDiagnostic} from "./discovery18LegacyJump.ts";
import type {Discovery18JumpObservation,Legacy365JumpProbe} from "./discovery18LegacyJump.ts";

// PATCH18: 365-दिवसांचा जुना अंदाज telemetry म्हणून प्रत्यक्ष जतन.
// खरे वर्ष शोधताना कोणतीही वर्ष-उडी नाही: दरवेळी SEAL11 किंवा SEAL12
// सह एकच वर्ष. Stage36 मधील synthetic वर्षबीज authoritative नाही.
export type Patch18Question=Patch15SignedQuestion;
export type Patch18Year=Readonly<{
 number:bigint;openGateIndex:bigint;closeGateIndex:bigint;
 openGateDay:bigint;closeGateDay:bigint;
}>;
export type Patch18VerifiedGateWindow=Readonly<{
 byIndex:ReadonlyMap<bigint,bigint>;
 minimumIndex:bigint;maximumIndex:bigint;
 minimumDay:bigint;maximumDay:bigint;
 realGapQuestions:number;
 realPredecessorWrites:bigint;
 provenance:"PHYSICALLY_RECOMPUTED_SIGNED_GATES";
}>;
function assertQuestion(q:Patch18Question,target:bigint):void {
 if(!q||typeof q!=="object"||q.targetDay!==target||
  !Array.isArray(q.visible)||q.visible.length!==47||
  Array.from({length:46},(_,i)=>typeof q.visible[i+1]!=="bigint").some(Boolean)||
  !Array.isArray(q.stones)||q.stones.length!==47||
  Array.from({length:46},(_,i)=>q.stones[i+1]).some(row=>
   !Array.isArray(row)||row.length!==5||
   Array.from({length:5},(_,j)=>typeof row[j]!=="bigint").some(Boolean))||
  !Array.isArray(q.startBowls)||q.startBowls.length!==6||
  q.startBowls.some(v=>typeof v!=="bigint"))
   throw new MonsterValidationError("पूर्ण 46 थेंब/दगड, सहा वाट्या आणि योग्य प्रश्न दिवस हवा");
}
function gateDay(w:Patch18VerifiedGateWindow,index:bigint):bigint {
 const value=w.byIndex.get(index);
 if(value===undefined)throw new MonsterValidationError("गेट विंडो अपूर्ण आहे");
 return value;
}

export class Patch18VerifiedGateWindowBuilder {
 build(positive:readonly Patch18Question[],negative:readonly Patch18Question[]):Patch18VerifiedGateWindow {
  if(!Array.isArray(positive)||!Array.isArray(negative)||
   !positive.length||!negative.length||
   positive.length>128||negative.length>128)
    throw new MonsterValidationError("दोन्ही दिशांनी मर्यादित signed gate प्रश्न आवश्यक");
  // Preflight the WHOLE question window before the first fallible Sauce.
  for(let i=0;i<positive.length;i++)
   assertQuestion(positive[i]!,DISCOVERY15_FOUNDATION_DAY+BigInt(i+1));
  for(let i=0;i<negative.length;i++)
   assertQuestion(negative[i]!,DISCOVERY15_FOUNDATION_DAY-BigInt(i+1));
  const map=new Map<bigint,bigint>([[0n,DISCOVERY15_FOUNDATION_DAY]]);
  let day=DISCOVERY15_FOUNDATION_DAY;
  for(let i=0;i<positive.length;i++){
   const n=BigInt(i+1),q=positive[i]!;
   const actual=patch14WideChoice(DISCOVERY15_FOUNDATION_DAY,q.targetDay,
    q.visible,q.stones,q.startBowls,1,1n,922n);
   if(actual.predecessorSharedWrites!==58||
      actual.realLegacyCalls!==1||actual.correctedRank<1n||
      actual.correctedRank>922n)
    throw new MonsterStageError("गेटचा प्रत्यक्ष 58-write predecessor अपूर्ण");
   day+=41n+actual.correctedRank;map.set(n,day);
  }
  day=DISCOVERY15_FOUNDATION_DAY;
  for(let i=0;i<negative.length;i++){
   const n=BigInt(i+1),q=negative[i]!;
   const actual=patch14WideChoice(DISCOVERY15_FOUNDATION_DAY,q.targetDay,
    q.visible,q.stones,q.startBowls,1,1n,922n);
   if(actual.predecessorSharedWrites!==58||
      actual.realLegacyCalls!==1||actual.correctedRank<1n||
      actual.correctedRank>922n)
    throw new MonsterStageError("ऋण गेटचा प्रत्यक्ष 58-write predecessor अपूर्ण");
   day-=41n+actual.correctedRank;map.set(-n,day);
  }
  // ReadonlyMap is a type-level guarantee; Map ownership stays private
  // and we expose read-only get/has entries through an immutable facade.
  const min=-BigInt(negative.length),max=BigInt(positive.length);
  const safe:ReadonlyMap<bigint,bigint>=Object.freeze({
   get:(k:bigint)=>map.get(k),
   has:(k:bigint)=>map.has(k),
   entries:()=>map.entries(),
   keys:()=>map.keys(),
   values:()=>map.values(),
   forEach:(fn:(value:bigint,key:bigint,map:ReadonlyMap<bigint,bigint>)=>void)=>
     map.forEach((v,k)=>fn(v,k,safe)),
   [Symbol.iterator]:()=>map.entries(),
   get size(){return map.size;}
  });
  return Object.freeze({
   byIndex:safe,minimumIndex:min,maximumIndex:max,
   minimumDay:map.get(min)!,maximumDay:map.get(max)!,
   realGapQuestions:positive.length+negative.length,
   realPredecessorWrites:BigInt(positive.length+negative.length)*58n,
   provenance:"PHYSICALLY_RECOMPUTED_SIGNED_GATES" as const
  });
 }
}

export type Patch18Step=Readonly<{
 direction:"NEXT"|"PREVIOUS";
 before:Patch18Year;after:Patch18Year;
 seal:11n|12n;questionTargetDay:bigint;
 examined:number;historicalFamilySize:number;
 correctedFamilySize:number;oldPredicateCalls:number;
 correctedRank:bigint;realSelector:Patch14WideChoiceObservation;
}>;
export type Patch18WalkResult=Readonly<{
 seed:Patch18Year;selected:Patch18Year;
 seedRank:bigint;seedSelector:Patch14WideChoiceObservation;
 steps:readonly Patch18Step[];
 forwardSteps:number;backwardSteps:number;
 realYearQuestionCalls:number;
 realGateQuestionCalls:number;
 realPredecessorCount:number;
 realPredecessorWrites:bigint;
 gateProvenance:"PHYSICALLY_RECOMPUTED_SIGNED_GATES";
 targetContained:true;
 legacyGuessUsedForNavigation:false;
}>;
export type Patch18TransitionQuestionFactory=(
 calculationDay:bigint,transitionGateDay:bigint,seal:11n|12n
)=>Patch18Question;

export class Patch18OneYearWalker {
 private readonly filter=new Patch16YearLengthGuard();
 private readonly runs=new Patch17EqualLengthRunSorter();
 private readonly gateBuilder=new Patch18VerifiedGateWindowBuilder();

 walk(c:bigint,t:bigint,
  positive:readonly Patch18Question[],negative:readonly Patch18Question[],
  yearQuestion:Patch18Question,transitionQuestion:Patch18TransitionQuestionFactory,
  maximumSteps:number):Patch18WalkResult {
  if(typeof c!=="bigint"||typeof t!=="bigint"||
     !Number.isSafeInteger(maximumSteps)||maximumSteps<0||maximumSteps>512||
     typeof transitionQuestion!=="function")
   throw new MonsterValidationError("दोन्ही दिवस bigint आणि सुरक्षित step budget आवश्यक");
  assertQuestion(yearQuestion,c);
  const window=this.gateBuilder.build(positive,negative);
  // The complete +/-5778 neighbourhood is needed to enumerate ALL
  // genuine Year5000 candidate pairs, not merely a convenient subset.
  if(window.minimumDay>=c-REAL_YEAR_MAX_PATCH||
     window.maximumDay<=c+REAL_YEAR_MAX_PATCH)
   throw new MonsterValidationError("पूर्ण वर्ष5000 कुटुंबासाठी signed gate खिडकी अपुरी");
  const yearCandidates:LegacyYearCandidate[]=[];
  for(let i=window.minimumIndex;i<window.maximumIndex;i++){
   const open=gateDay(window,i);
   if(open>=c||c-open>REAL_YEAR_MAX_PATCH)continue;
   for(let j=i+1n;j<=window.maximumIndex;j++){
    const close=gateDay(window,j);
    if(close< c)continue;
    if(close-open>REAL_YEAR_MAX_PATCH)break;
    if(close>open&&j-i>=6n)
     yearCandidates.push(Object.freeze({
      openGateIndex:i,closeGateIndex:j,openGateDay:open,closeGateDay:close
     }));
   }
  }
  if(!yearCandidates.length)
   throw new MonsterStageError("कुठलेही पूर्ण नियमाधारित वर्ष5000 उमेदवार नाहीत");
  const seedFamily=this.filter.apply(yearCandidates);
  const seedSorted=this.runs.sortAfterHistorical(seedFamily.corrected);
  const seedAnswer=patch14WideChoice(c,c,yearQuestion.visible,yearQuestion.stones,
   yearQuestion.startBowls,1,10n,BigInt(seedSorted.corrected.length));
  if(seedAnswer.predecessorSharedWrites!==58)throw new MonsterStageError("वर्ष5000 उत्तरे अपुरी");
  const seed=this.record(5000n,seedSorted.corrected[Number(seedAnswer.correctedRank-1n)]!);
  let current=seed;
  const history:Patch18Step[]=[];
  while(t>current.closeGateDay||t<=current.openGateDay){
   if(history.length>=maximumSteps)
    throw new MonsterValidationError("step budget संपला; अंदाजाऐवजी explicit अपयश");
   const next=t>current.closeGateDay;
   const bound=next?current.closeGateDay:current.openGateDay;
   if(next?window.maximumDay<=bound+REAL_YEAR_MAX_PATCH:
           window.minimumDay>=bound-REAL_YEAR_MAX_PATCH)
    throw new MonsterValidationError("या पुढील वर्षासाठी पूर्ण signed gate खिडकी आवश्यक");
   const raw:LegacyYearCandidate[]=[];
   if(next){
    for(let j=current.closeGateIndex+1n;j<=window.maximumIndex;j++){
     const close=gateDay(window,j),length=close-bound;
     if(length>REAL_YEAR_MAX_PATCH)break;
     raw.push(Object.freeze({
      openGateIndex:current.closeGateIndex,closeGateIndex:j,
      openGateDay:bound,closeGateDay:close
     }));
    }
   }else{
    for(let i=current.openGateIndex-1n;i>=window.minimumIndex;i--){
     const open=gateDay(window,i),length=bound-open;
     if(length>REAL_YEAR_MAX_PATCH)break;
     raw.push(Object.freeze({
      openGateIndex:i,closeGateIndex:current.openGateIndex,
      openGateDay:open,closeGateDay:bound
     }));
    }
   }
   if(!raw.length)throw new MonsterStageError("वर्ष बदलण्यासाठी gate जोडी नाही");
   const family=this.filter.apply(raw);
   if(!family.correctedFamilySize)throw new MonsterStageError("योग्य वर्ष-जोडी नाही");
   // Fixed opening for NEXT / fixed closing for PREVIOUS, so length-only
   // sorting is precisely the canonical ascending order.
   const ordered=family.corrected;
   const seal=next?11n as const:12n as const;
   const q=transitionQuestion(c,bound,seal);
   assertQuestion(q,bound);
   const answer=patch14WideChoice(c,bound,q.visible,q.stones,q.startBowls,
     1,seal,BigInt(ordered.length));
   if(answer.predecessorSharedWrites!==58||answer.familySize!==BigInt(ordered.length))
    throw new MonsterStageError("पुढील वर्षाचे seal11/12 प्रश्न अपूर्ण");
   const picked=ordered[Number(answer.correctedRank-1n)]!;
   const after=this.record(current.number+(next?1n:-1n),picked);
   if(next?(after.openGateIndex!==current.closeGateIndex||
            after.openGateDay!==current.closeGateDay):
           (after.closeGateIndex!==current.openGateIndex||
            after.closeGateDay!==current.openGateDay))
    throw new MonsterStageError("शेजारच्या वर्षांची gate continuity चुकीची");
   history.push(Object.freeze({
     direction:next?"NEXT" as const:"PREVIOUS" as const,
     before:current,after,seal,questionTargetDay:bound,
     examined:raw.length,
     historicalFamilySize:family.historicalFamilySize,
     correctedFamilySize:family.correctedFamilySize,
     oldPredicateCalls:family.oldPredicateCalls,
     correctedRank:answer.correctedRank,realSelector:answer
   }));
   current=after;
  }
  if(!(current.openGateDay<t&&t<=current.closeGateDay))
   throw new MonsterStageError("निवडलेल्या वर्षात target नाही");
  return Object.freeze({
   seed,selected:current,seedRank:seedAnswer.correctedRank,
   seedSelector:seedAnswer,steps:Object.freeze(history),
   forwardSteps:history.filter(s=>s.direction==="NEXT").length,
   backwardSteps:history.filter(s=>s.direction==="PREVIOUS").length,
   realYearQuestionCalls:1+history.length,
   realGateQuestionCalls:window.realGapQuestions,
   realPredecessorCount:window.realGapQuestions+1+history.length,
   realPredecessorWrites:window.realPredecessorWrites+
     BigInt(1+history.length)*58n,
   gateProvenance:window.provenance,
   targetContained:true as const,
   legacyGuessUsedForNavigation:false as const
  });
 }
 private record(number:bigint,entry:LegacyYearCandidateEntry):Patch18Year {
  const p=entry.candidate;
  if(entry.length<252n||entry.length>5778n||
     p.closeGateIndex-p.openGateIndex<6n)
   throw new MonsterStageError("अवैध वर्ष सीमा");
  return Object.freeze({number,openGateIndex:p.openGateIndex,
    closeGateIndex:p.closeGateIndex,openGateDay:p.openGateDay,
    closeGateDay:p.closeGateDay});
 }
}

export type Patch18YearWalkObservation=Readonly<{
 calculationDay:bigint;targetDay:bigint;
 legacy:Discovery18JumpObservation;
 authoritative:Patch18WalkResult;
 oldGuess:bigint;historicalSyntheticGuess:bigint;
 realSeedGuess:Legacy365JumpProbe;authoritativeYear:Patch18Year;
 predecessorCallCount:number;predecessorSharedWrites:bigint;
 authoritativeSource:"RECOMPUTED_GATES_AND_SEAL10_11_12";
 originalSyntheticYearNotUsed:true;
 context:MonsterContext;
}>;
export class Patch18YearWalkHandler {
 private readonly walker=new Patch18OneYearWalker();
 private readonly ghost=new Legacy365JumpDiagnostic();
 private readonly metrics=new BaseMetricsManager();

 run(ctx:MonsterContext,anchorGateIndex:bigint,
  historicalPositive:readonly Discovery15GateQuestion[],
  signedQuestions:readonly Patch15SignedQuestion[],
  oldYearQuestion:Discovery15GateQuestion,
  oldAnchorCandidates:readonly LegacyYearCandidate[],
  oldMultiCandidates:readonly LegacyYearCandidate[],
  positive:readonly Patch18Question[],negative:readonly Patch18Question[],
  trueYearQuestion:Patch18Question,
  transitionQuestion:Patch18TransitionQuestionFactory,
  maximumSteps:number):Patch18YearWalkObservation {
  if(ctx.phase!=="READY"||ctx.status!=="VALIDATED"||
     typeof ctx.calculationDay!=="bigint"||typeof ctx.targetDay!=="bigint")
   throw new MonsterStageError("PATCH18 ready/validated संदर्भ आवश्यक");
  // Actually run Stage36, including old /365 error and all old scars.
  const legacy=discoverLegacyJumpGuess(
   ctx.calculationDay,ctx.targetDay,anchorGateIndex,historicalPositive,
   signedQuestions,oldYearQuestion,oldAnchorCandidates,oldMultiCandidates);
  if(legacy.guess.role!=="TELEMETRY_ONLY"||
     legacy.guess.oldJumpGuessCalls!==1||
     legacy.preceding.realYearSelectorCalls!==3)
   throw new MonsterStageError("जुनी 365 उडी आणि Stage35 खऱ्या पूर्ण chain आवश्यक");
  const authoritative=this.walker.walk(
   ctx.calculationDay,ctx.targetDay,positive,negative,trueYearQuestion,
   transitionQuestion,maximumSteps);
  // Re-ask the unmodified old /365 helper with the newly VERIFIED Year5000,
  // never with the synthetic Stage36 anchor as the authoritative seed.
  const realSeedGuess=this.ghost.measure(Object.freeze({
   number:authoritative.seed.number,
   firstDay:authoritative.seed.openGateDay+1n,
   lastDay:authoritative.seed.closeGateDay
  }),ctx.targetDay);
  const predecessorCallCount=legacy.predecessorCallCount+
    authoritative.realPredecessorCount;
  const output=Object.freeze({
   calculationDay:ctx.calculationDay,targetDay:ctx.targetDay,
   legacy,authoritative,oldGuess:realSeedGuess.estimatedYearNumber,
   historicalSyntheticGuess:legacy.ghostYearNumber,realSeedGuess,
   authoritativeYear:authoritative.selected,predecessorCallCount,
   predecessorSharedWrites:legacy.predecessorSharedWrites+
     authoritative.realPredecessorWrites,
   authoritativeSource:"RECOMPUTED_GATES_AND_SEAL10_11_12" as const,
   originalSyntheticYearNotUsed:true as const,context:ctx
  });
  ctx.branchTrace.push("PATCH_18_EXECUTE_OLD_365_GHOST_AND_ALL_STAGE36_SCARS");
  ctx.branchTrace.push("PATCH_18_PHYSICALLY_RECOMPUTE_SIGNED_GATES");
  ctx.branchTrace.push("PATCH_18_REAL_YEAR5000_FROM_ACTUAL_GATE_PAIRS");
  ctx.branchTrace.push("PATCH_18_OLD_365_TELEMETRY_REASK_TRUE_SEED");
  ctx.branchTrace.push("PATCH_18_STEP_SEAL11_12_ONE_YEAR_AT_A_TIME");
  this.metrics.bump(ctx,"patch18.calls");
  ctx.metrics.set("patch18.real_gate_questions",
    BigInt(authoritative.realGateQuestionCalls));
  ctx.metrics.set("patch18.actual_steps",BigInt(authoritative.steps.length));
  ctx.metrics.set("patch18.old_guess",realSeedGuess.estimatedYearNumber);
  ctx.metrics.set("patch18.synthetic_old_guess",legacy.ghostYearNumber);
  ctx.metrics.set("patch18.actual_year",authoritative.selected.number);
  ctx.metrics.set("patch18.full_predecessor_58_write_sequences",
    BigInt(predecessorCallCount));
  ctx.status="PATCH_18_APPLIED";
  return output;
 }
}
export function patch18WalkYear(c:bigint,t:bigint,anchorGateIndex:bigint,
  historicalPositive:readonly Discovery15GateQuestion[],
  signedQuestions:readonly Patch15SignedQuestion[],
  oldYearQuestion:Discovery15GateQuestion,
  oldAnchorCandidates:readonly LegacyYearCandidate[],
  oldMultiCandidates:readonly LegacyYearCandidate[],
  positive:readonly Patch18Question[],negative:readonly Patch18Question[],
  trueYearQuestion:Patch18Question,
  transitionQuestion:Patch18TransitionQuestionFactory,
  maximumSteps:number):Patch18YearWalkObservation {
 return new Patch18YearWalkHandler().run(
  bootstrapMonster(c,t),anchorGateIndex,historicalPositive,
  signedQuestions,oldYearQuestion,oldAnchorCandidates,oldMultiCandidates,
  positive,negative,trueYearQuestion,transitionQuestion,maximumSteps);
}
