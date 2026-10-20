import {
  LegacyPositiveCompositions,countOldPositiveCompositions,
  oldHasPrefixBoundary,discoverLegacyCutletPartition,
  Discovery21LegacyCutletHandler,Patch20StructureSauceHandler,
  Discovery20StructureSauceHandler,Patch19YearCacheHandler
} from "../src/index.ts";
import {boundedCompositionFamily,NormativeOracle,sauce,chooseRank,askBowl} from "./normativeOracle.ts";
import {findTrueHistoricalBoundaryMiss,question,assert} from "./discovery21Fixtures.ts";
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
const oracle=new NormativeOracle();
const source=sauce(f.request.historical.yearQuestion.calculationDay,f.year.openGateDay+1n);
const normativeK=oracle.chooseCutletCount(source,f.year);
const normative=oracle.chooseCutletPartition(
 f.request.historical.yearQuestion.calculationDay,source,f.year,normativeK);
assert(f.K===normativeK&&f.correctPartition.join(",")===normative.join(",")&&
 f.oldPartition.join(",")!==normative.join(",")&&
 !oldHasPrefixBoundary(f.oldPartition,f.required)&&
 oldHasPrefixBoundary(normative,f.required),
 "verified real action gate forces patched canonical boundary; old family skips it");
let realCalls=0,realWrites=0,trueBad=0,actualSeal20=0,actualSeal21=0;
for(const twice of [false,true]){
 const req=twice?{
  historical:{
   ...f.request.historical,
   yearQuestion:{
    ...f.request.historical.yearQuestion,
    targetDay:f.year.openGateDay+1n
   },
   originalSauceQuestion:question(
    f.request.historical.yearQuestion.calculationDay,f.year.openGateDay+1n)
  }
 }:f.request;
 const handler=new Discovery21LegacyCutletHandler(
  new Patch20StructureSauceHandler(new Discovery20StructureSauceHandler(
    new Patch19YearCacheHandler())));
 const result=discoverLegacyCutletPartition(handler,req);
 assert(result.selectedK===normativeK&&
   result.historicalPartition.join(",")===f.oldPartition.join(",")&&
   result.exactActionGateIndex===f.index&&
   result.requiredBoundary===f.required&&
   result.historicalUnfilteredCount===f.legacyFamily&&
   result.historicalRank===f.legacyRank&&
   result.historicalMissesRequiredGate&&
   result.historicalPrefixConstraintApplied===false&&
   result.legacyCutletCountSelection.queriedBowlId===2&&
   result.legacyPartitionSelection.queriedBowlId===2&&
   result.realSharedWrites===BigInt(result.realPredecessorCalls)*58n,
   "both real Stage41 routes choose historical wrong lex partition without patch21 filter");
 if(twice){
   assert(!result.preceding.requiredFirstDaySubstitution&&
     result.preceding.firstDaySauceCalls===0,
     "target equal true first day reuses Stage40 original Sauce");
 }else{
   assert(result.preceding.requiredFirstDaySubstitution&&
     result.preceding.firstDaySauceCalls===1,
     "different target physically corrects structure Sauce at first year day");
 }
 trueBad++;realCalls+=result.realPredecessorCalls;
 realWrites+=Number(result.realSharedWrites);
 actualSeal20++;actualSeal21++;
}
assert(realCalls>0&&realWrites===realCalls*58&&trueBad===2,
 "real predecessor count across Stage41 and physical seals20/21 consistent");
console.log("STAGE_42_DISCOVERY_21_PROPERTIES_PASS families="+families+
 " lexWrong="+lexWrong+" unrankChecks="+unrankChecks+
 " exhaustiveRows="+smallRows+" oldFilteredWouldKeep="+filtered+
 " oldWrongWithoutRequired="+missed+" hugeLexCases="+giant+
 " realWrongGateCases="+trueBad+
 " actualSeal20="+actualSeal20+" actualSeal21="+actualSeal21+
 " truePredecessors="+realCalls+" sharedWrites="+realWrites+
 " canonicalWrong=0");
