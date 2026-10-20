import {
  LegacyPositiveCompositions,countOldPositiveCompositions,
  oldHasPrefixBoundary,discoverLegacyCutletPartition,
  Discovery21LegacyCutletHandler,Discovery21ExactGateProbeHandler,Patch20StructureSauceHandler,
  Discovery20StructureSauceHandler,Patch19YearCacheHandler
} from "../src/index.ts";
import {boundedCompositionFamily,NormativeOracle,sauce,chooseRank,askBowl} from "./normativeOracle.ts";
import {findTrueHistoricalBoundaryMiss,buildStage41CompatibleLegacyFixture,question,assert} from "./discovery21Fixtures.ts";
const old=new LegacyPositiveCompositions();
let families=0,lexWrong=0,smallRows=0,unrankChecks=0;
for(let G=6n;G<=23n;G++){
 for(let K=2;K<=Math.min(10,Number(G));K++){
  const family=boundedCompositionFamily(G,K,1n,G);
  const size=family.count();
  if(old.oldCount(G,K)!==size)lexWrong++;
  const picks=new Set([1n,2n,size/2n||1n,size-1n,size].filter(r=>r>=1n&&r<=size));
  for(const rank of picks){
   const x=old.oldUnrank(G,K,rank);
   const y=family.unrank1(rank);
   if(x.join(",")!==y.join(","))lexWrong++;
   assert(x.length===K&&x.reduce((a,b)=>a+b,0n)===G&&
    x.every(d=>d>=1n)&&Object.isFrozen(x),
    "legacy true positive composition and original lex order preserved");
   unrankChecks++;
  }
  if(size<=2500n){
   let last=0n;
   for(const item of old.legacyPositiveCompositions(G,K)){
    last++;if(last<=5n||last===size)
      assert(item.join(",")===family.unrank1(last).join(","),
       "original iterator lex order must agree with test-only independent DP");
   }
   assert(last===size,"old iterator actually enumerated complete finite family");
   smallRows+=Number(size);
  }
  families++;
 }
}
assert(families>100&&unrankChecks>500&&lexWrong===0&&smallRows>1000,
 "100+ independent lexical whole-composition families and 500+ ranks correct");

// Cutlet requirement was deliberately NOT checked in the old enumeration.
let filtered=0,missed=0;
const G=11n,K=7,required=4n;
for(const p of old.legacyPositiveCompositions(G,K)){
 if(oldHasPrefixBoundary(p,required))filtered++;
 else missed++;
}
assert(filtered>0&&missed>0&&
 filtered+missed===Number(countOldPositiveCompositions(G,K)),
 "physical original generator includes partitions on BOTH sides of canonical filter");

const big=(1n<<1024n)+37n;
let giant=0;
for(const k of [6,9,17]){
 const N=old.oldCount(big,k);
 const first=old.oldUnrank(big,k,1n);
 const last=old.oldUnrank(big,k,N);
 assert(first.length===k&&last.length===k&&
   first.slice(0,-1).every(x=>x===1n)&&first[k-1]===big-BigInt(k-1)&&
   last[0]===big-BigInt(k-1)&&last.slice(1).every(x=>x===1n)&&
   first.reduce((a,b)=>a+b,0n)===big&&
   last.reduce((a,b)=>a+b,0n)===big,
   "giant 1024-bit exact positive lex first/last partition, no iteration explosion");
 giant++;
}
const f=findTrueHistoricalBoundaryMiss();
const exactNative=new Discovery21ExactGateProbeHandler().run(
 f.request.historical.yearQuestion.calculationDay,f.index,
 f.request.historical.yearQuestion.positive,
 f.request.historical.yearQuestion.negative,
 f.request.historical.yearQuestion.trueYearQuestion,
 f.request.firstDaySauceQuestion!);
assert(exactNative.G===f.G&&exactNative.K===f.K&&
 exactNative.actionGateIndex===f.index&&
 exactNative.requiredBoundary===f.required&&
 exactNative.oldRank===f.legacyRank&&
 exactNative.oldUnfilteredFamilySize===f.legacyFamily&&
 exactNative.oldPartition.join(",")===f.oldPartition.join(",")&&
 exactNative.actuallyMissedRequiredGate&&
 exactNative.nativeSharedWrites===BigInt(exactNative.realNativeSauceCalls)*58n,
 "physically recomputed exact action-day gate, true year, first-day Sauce, and wrong old rank");
const oracle=new NormativeOracle();
const source=sauce(f.request.historical.yearQuestion.calculationDay,f.year.openGateDay+1n);
const normative=oracle.chooseCutletPartition(
 f.request.historical.yearQuestion.calculationDay,source,f.year,f.K);
assert(f.correctPartition.join(",")===normative.join(",")&&
 !oldHasPrefixBoundary(f.oldPartition,f.required)&&
 oldHasPrefixBoundary(normative,f.required),
 "test-only filtered oracle fixes the skipped internal gate, no production filter");

const full=buildStage41CompatibleLegacyFixture();
const fullC=full.cDay,fullY=full.oracleYear;
const fullStructure=sauce(fullC,fullY.openGateDay+1n);
const fullK=oracle.chooseCutletCount(fullStructure,fullY);
const fullG=fullY.closeGateIndex-fullY.openGateIndex;
const fullFamily=boundedCompositionFamily(fullG,fullK,1n,fullG);
const fullRank=chooseRank(askBowl(fullStructure,2,21n),fullFamily.count());
const fullExpected=fullFamily.unrank1(fullRank);
let realCalls=0,realWrites=0,trueFull=0;
for(const exactFirst of [false,true]){
 const req=exactFirst?{
  ...full.request,
  historical:{
   ...full.request.historical,
   yearQuestion:{
    ...full.request.historical.yearQuestion,targetDay:fullY.openGateDay+1n
   },
   originalSauceQuestion:question(fullC,fullY.openGateDay+1n)
  }
 }:full.request;
 const handler=new Discovery21LegacyCutletHandler(
  new Patch20StructureSauceHandler(new Discovery20StructureSauceHandler(
    new Patch19YearCacheHandler())));
 const out=discoverLegacyCutletPartition(handler,req);
 assert(out.G===fullG&&out.selectedK===fullK&&
   out.historicalPartition.join(",")===fullExpected.join(",")&&
   out.historicalRank===fullRank&&
   out.historicalUnfilteredCount===fullFamily.count()&&
   out.exactActionGateIndex===null&&out.requiredBoundary===null&&
   !out.historicalMissesRequiredGate&&
   out.historicalPrefixConstraintApplied===false&&
   out.legacyCutletCountSelection.seal===20n&&
   out.legacyPartitionSelection.seal===21n&&
   out.realSharedWrites===BigInt(out.realPredecessorCalls)*58n,
   "full Stage41 predecessor with action-day gate+1 does not invent an exact gate");
 if(exactFirst){
   assert(!out.preceding.requiredFirstDaySubstitution&&
     out.preceding.firstDaySauceCalls===0,
     "true year first-day route reuses original Stage40 Sauce");
 }else{
   assert(out.preceding.requiredFirstDaySubstitution&&
     out.preceding.firstDaySauceCalls===1,
     "different target route physically corrects Stage40 Sauce");
 }
 realCalls+=out.realPredecessorCalls;
 realWrites+=Number(out.realSharedWrites);trueFull++;
}
assert(trueFull===2&&realWrites===realCalls*58,
 "two actual full Stage41 paths and all native predecessor writes consistent");
console.log("STAGE_42_DISCOVERY_21_PROPERTIES_PASS families="+families+
 " lexWrong="+lexWrong+" unrankChecks="+unrankChecks+
 " exhaustiveRows="+smallRows+" oldFilteredWouldKeep="+filtered+
 " oldWrongWithoutRequired="+missed+" hugeLexCases="+giant+
 " nativeExactWrongBoundary="+Number(exactNative.actuallyMissedRequiredGate)+
 " fullStage41Cases="+trueFull+" fullActionGateNone=2"+
 " exactNativePredecessors="+exactNative.realNativeSauceCalls+
 " fullStage41Predecessors="+realCalls+" sharedWrites="+realWrites+
 " canonicalWrong=0");
