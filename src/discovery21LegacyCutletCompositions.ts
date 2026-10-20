import {BaseMetricsManager,bootstrapMonster,MonsterStageError,MonsterValidationError} from "./monsterBase.ts";
import type {MonsterContext} from "./monsterBase.ts";
import {patch20StructureSauce} from "./patch20StructureSauce.ts";
import type {Patch20StructureRequest,Patch20StructureObservation} from "./patch20StructureSauce.ts";
import {Patch20StructureSauceHandler} from "./patch20StructureSauce.ts";
import {Patch18VerifiedGateWindowBuilder} from "./patch18YearWalk.ts";
import {patch14WideChoice} from "./patch14WideChoice.ts";
import type {Patch14WideChoiceObservation} from "./patch14WideChoice.ts";

// DISCOVERY21 — जुनी सर्व सकारात्मक K-भाग रचना lex क्रमानेच चालते.
// कृती-दिवसाच्या आतील gate वर cutlet सीमा असावी हा अट-फिल्टर नाही.
// ही मूळ चूक Stage43 मध्येच वेगळ्या DP ने सुधारायची.
export function countOldPositiveCompositions(G:bigint,K:number):bigint {
  if(typeof G!=="bigint"||!Number.isSafeInteger(K)||K<1||K>17||G<BigInt(K))
    throw new MonsterValidationError("positive cutlet composition साठी G≥K≥1 आवश्यक");
  let result=1n;
  const n=G-1n,k=BigInt(K-1);
  for(let i=1n;i<=k;i++)result=result*(n-k+i)/i;
  return result;
}
export class LegacyPositiveCompositions {
  oldCount(G:bigint,K:number):bigint {
    return countOldPositiveCompositions(G,K);
  }
  *legacyPositiveCompositions(G:bigint,K:number):Generator<readonly bigint[]> {
    this.oldCount(G,K);
    function* emit(rem:bigint,k:number,parts:bigint[]):Generator<readonly bigint[]> {
      if(k===1){yield Object.freeze([...parts,rem]);return;}
      const limit=rem-BigInt(k-1);
      for(let x=1n;x<=limit;x++)yield* emit(rem-x,k-1,[...parts,x]);
    }
    yield* emit(G,K,[]);
  }
  oldUnrank(G:bigint,K:number,rank:bigint):readonly bigint[] {
    const N=this.oldCount(G,K);
    if(typeof rank!=="bigint"||rank<1n||rank>N)
      throw new MonsterValidationError("old partition rank बाहेर आहे");
    // For finite historical families actually traverse the old generator.
    // For enormous families use the exactly equivalent combinatorial
    // lex block selection; do NOT truncate or sample any rank.
    if(N<=10000n){
      let i=0n;
      for(const row of this.legacyPositiveCompositions(G,K)){
        i++;
        if(i===rank)return row;
      }
      throw new MonsterStageError("जुन्या generator मध्ये rank सापडला नाही");
    }
    const row:bigint[]=[];let rem=G,r=rank,k=K;
    while(k>1){
      const all=this.oldCount(rem,k);
      let lo=1n,hi=rem-BigInt(k-1);
      // #compositions with first <= x = all - C(rem-x-1,k-1).
      while(lo<hi){
        const mid=(lo+hi)/2n;
        const tail=rem-mid-1n>=BigInt(k-1)?
          this.oldCount(rem-mid,k):0n;
        if(all-tail>=r)hi=mid;
        else lo=mid+1n;
      }
      const x=lo;
      const tail=rem-x>=BigInt(k-1)?this.oldCount(rem-x+1n,k):0n;
      // Count with first < x. Equivalent to all - C(rem-x,k-1).
      const before=all-tail;
      r-=before;row.push(x);rem-=x;k--;
    }
    row.push(rem);
    return Object.freeze(row);
  }
}
export function oldHasPrefixBoundary(parts:readonly bigint[],required:bigint):boolean{
  if(!Array.isArray(parts)||typeof required!=="bigint"||required<1n)
    throw new MonsterValidationError("cutlet boundary चा वैध पुरावा हवा");
  let sum=0n;
  for(let i=0;i<parts.length-1;i++){
    const part=parts[i]!;
    if(typeof part!=="bigint"||part<1n)
      throw new MonsterValidationError("positive parts आवश्यक");
    sum+=part;if(sum===required)return true;
  }
  return false;
}
export type Discovery21LegacyCutletObservation=Readonly<{
 calculationDay:bigint;originalTargetDay:bigint;
 yearOpenGateIndex:bigint;yearCloseGateIndex:bigint;
 G:bigint;selectedK:number;eligibleK:readonly number[];
 exactActionGateIndex:bigint|null;
 requiredBoundary:bigint|null;
 historicalUnfilteredCount:bigint;historicalRank:bigint;
 historicalPartition:readonly bigint[];
 historicalActualGeneratorCalls:1;
 historicalPrefixConstraintApplied:false;
 historicalMissesRequiredGate:boolean;
 legacyCutletCountSelection:Patch14WideChoiceObservation;
 legacyPartitionSelection:Patch14WideChoiceObservation;
 realGateQuestions:number;
 preceding:Patch20StructureObservation;
 realPredecessorCalls:number;
 realSharedWrites:bigint;
 context:MonsterContext;
}>;
export class Discovery21LegacyCutletHandler {
 private readonly old=new LegacyPositiveCompositions();
 private readonly windows=new Patch18VerifiedGateWindowBuilder();
 private readonly metrics=new BaseMetricsManager();
 readonly preceding:Patch20StructureSauceHandler;
 constructor(preceding:Patch20StructureSauceHandler){
  this.preceding=preceding;
 }
 run(ctx:MonsterContext,q:Patch20StructureRequest):Discovery21LegacyCutletObservation{
  if(ctx.phase!=="READY"||ctx.status!=="VALIDATED"||
     !q?.historical?.yearQuestion||
     q.historical.yearQuestion.calculationDay!==ctx.calculationDay||
     q.historical.yearQuestion.targetDay!==ctx.targetDay)
    throw new MonsterStageError("DISCOVERY21 साठी पूर्ण READY Stage41 प्रश्न आवश्यक");
  const previous=patch20StructureSauce(this.preceding,q);
  if(previous.context.status!=="PATCH_20_APPLIED"||
     !previous.structureSauceReady||
     previous.authoritativeBowls.length!==6||
     previous.authoritativeOrderAtDrop46.length!==6)
    throw new MonsterStageError("पूर्ण Stage41 first-day structure Sauce आवश्यक");
  const year=previous.historical.fullStage39.correctedServed.year;
  const G=year.closeGateIndex-year.openGateIndex;
  if(G<6n)throw new MonsterStageError("किमान सहा gate-gap असलेले वर्ष आवश्यक");
  const eligibleK=Object.freeze(Array.from({length:12},(_,i)=>i+6)
    .filter(k=>BigInt(k)<=G));
  if(!eligibleK.length)throw new MonsterStageError("cutlet-count family रिकामी");
  const firstDay=previous.trueYearFirstDay;
  const source=q.firstDaySauceQuestion??
    (firstDay===ctx.targetDay?q.historical.originalSauceQuestion:undefined);
  if(!source||source.targetDay!==firstDay)
    throw new MonsterValidationError("native first-day structure question आवश्यक");
  // Independent real Stage29 Sauce/candidate selectors, NOT oracle shortcuts.
  const countChoice=patch14WideChoice(ctx.calculationDay,firstDay,
    source.visible,source.stones,source.startBowls,2,20n,BigInt(eligibleK.length));
  const K=eligibleK[Number(countChoice.correctedRank-1n)]!;
  const N=this.old.oldCount(G,K);
  const partitionChoice=patch14WideChoice(ctx.calculationDay,firstDay,
    source.visible,source.stones,source.startBowls,2,21n,N);
  // PHYSICALLY invoke the old lexicographic positive family generator.
  const partition=this.old.oldUnrank(G,K,partitionChoice.correctedRank);
  const windows=q.historical.yearQuestion;
  const gateWindow=this.windows.build(windows.positive,windows.negative);
  if(gateWindow.byIndex.get(year.openGateIndex)!==year.openGateDay||
     gateWindow.byIndex.get(year.closeGateIndex)!==year.closeGateDay)
    throw new MonsterStageError("वर्ष gate indexes खऱ्या sauce शी जुळत नाहीत");
  let exact:bigint|null=null;
  for(const [gateIndex,gateDay] of gateWindow.byIndex){
    if(gateDay===ctx.calculationDay){
      exact=gateIndex;
      break;
    }
  }
  const required=exact!==null&&
    year.openGateIndex<exact&&exact<year.closeGateIndex?
      exact-year.openGateIndex:null;
  const misses=required!==null&&!oldHasPrefixBoundary(partition,required);
  if(partition.length!==K||partition.some(x=>x<1n)||
     partition.reduce((a,b)=>a+b,0n)!==G||
     countChoice.predecessorSharedWrites!==58||
     partitionChoice.predecessorSharedWrites!==58)
    throw new MonsterStageError("सर्व जुने positive parts आणि 58-write दोन्ही प्रश्न अनिवार्य");
  const calls=previous.totalRealPredecessorCalls+2+gateWindow.realGapQuestions;
  const out=Object.freeze({
    calculationDay:ctx.calculationDay,originalTargetDay:ctx.targetDay,
    yearOpenGateIndex:year.openGateIndex,yearCloseGateIndex:year.closeGateIndex,
    G,selectedK:K,eligibleK,
    exactActionGateIndex:exact,requiredBoundary:required,
    historicalUnfilteredCount:N,historicalRank:partitionChoice.correctedRank,
    historicalPartition:partition,historicalActualGeneratorCalls:1 as const,
    historicalPrefixConstraintApplied:false as const,
    historicalMissesRequiredGate:misses,
    legacyCutletCountSelection:countChoice,
    legacyPartitionSelection:partitionChoice,
    realGateQuestions:gateWindow.realGapQuestions,
    preceding:previous,
    realPredecessorCalls:calls,
    realSharedWrites:previous.totalSharedMemoryWrites+
      BigInt(2+gateWindow.realGapQuestions)*58n,
    context:ctx
  });
  ctx.branchTrace.push("DISCOVERY_21_FULL_PATCH20_FIRST_DAY_SAUCE");
  ctx.branchTrace.push("DISCOVERY_21_REAL_SEAL20_CUTLET_COUNT");
  ctx.branchTrace.push("DISCOVERY_21_ACTUAL_LEGACY_POSITIVE_COMPOSITIONS_NO_GATE_FILTER");
  ctx.branchTrace.push("DISCOVERY_21_REAL_SEAL21_UNFILTERED_PARTITION_SELECTION");
  this.metrics.bump(ctx,"discovery21.calls");
  ctx.metrics.set("discovery21.old_generator_calls",1n);
  ctx.metrics.set("discovery21.missed_required_gate",misses?1n:0n);
  ctx.metrics.set("discovery21.predecessor_58_write_sequences",BigInt(calls));
  ctx.status="DISCOVERY_21_RECORDED";
  return out;
 }
}
export function discoverLegacyCutletPartition(
 handler:Discovery21LegacyCutletHandler,q:Patch20StructureRequest
):Discovery21LegacyCutletObservation{
 if(!(handler instanceof Discovery21LegacyCutletHandler)||!q?.historical?.yearQuestion)
  throw new MonsterValidationError("DISCOVERY21 handler आणि प्रश्न आवश्यक");
 const req=q.historical.yearQuestion;
 return handler.run(bootstrapMonster(req.calculationDay,req.targetDay),q);
}
