import {
 ScalableLegalWeavingCounter,ScalableLegalWeavingUnrank,
 MonsterValidationError
} from "../src/index.ts";
import {weavingFamily} from "./normativeOracle.ts";
import {assert} from "./discovery21Fixtures.ts";
// More than the original four uniform/single-offset families:
// compare two production derivations against the independent test-only oracle.
const families:readonly (readonly bigint[])[]=[
 [4n,4n,4n],[4n,4n,5n],[4n,5n,4n],[5n,4n,4n],
 [4n,4n,6n],[6n,4n,4n],[4n,6n,4n],[5n,4n,5n],
 [5n,5n,4n],[4n,5n,5n],[6n,5n,4n],[4n,6n,5n],
 [4n,4n,4n,4n],[5n,4n,4n,4n],[4n,5n,4n,5n],
 [6n,4n,5n,4n],[4n,6n,4n,5n],[5n,5n,4n,4n],
 [4n,4n,4n,4n,4n],[4n,5n,4n,4n,4n],
 [5n,4n,4n,5n,4n]
];
let checkedRanks=0,checkedFamilies=0,mirrorCounts=0,lexAdjacent=0;
for(const lengths of families){
 const oracle=weavingFamily(lengths);
 const fast=new ScalableLegalWeavingUnrank(lengths);
 const separate=new ScalableLegalWeavingCounter(lengths);
 const N=oracle.count();
 assert(fast.count()===N&&separate.count()===N,
  "two independent production counts match legal oracle");
 const reversed=[...lengths].reverse();
 assert(new ScalableLegalWeavingCounter(reversed).count()===N,
  "time-reversal and month-ID reversal preserve family count");
 mirrorCounts++;
 const ranks=new Set<bigint>([
  1n,2n,3n,4n,5n,11n,23n,
  (N+1n)/2n,N/2n,N-2n,N-1n,N
 ]);
 for(const rank of ranks){
  if(rank<1n||rank>N)continue;
  const got=fast.itemAt1(rank);
  const expected=oracle.unrank1(rank);
  assert(got.join(",")===expected.join(","),
   "independent oracle exact one-based lex rank");
  assert(got.length===Number(lengths.reduce((a,b)=>a+b,0n)),
   "legal weaving full-day length");
  checkedRanks++;
  if(rank<N&&rank<=4n){
   const next=fast.itemAt1(rank+1n);
   let smaller=false;
   for(let i=0;i<got.length;i++){
    if(got[i]!==next[i]){
     smaller=got[i]!<next[i]!;
     break;
    }
   }
   assert(smaller,"adjacent legal ranks strictly ascend lexically");
   lexAdjacent++;
  }
 }
 let invalid=0;
 for(const rank of [0n,N+1n]){
  try{fast.itemAt1(rank);}
  catch(e){if(e instanceof MonsterValidationError)invalid++;}
 }
 assert(invalid===2,"invalid rank boundaries rejected");
 const statistics=fast.statistics();
 assert(statistics.distributionCells<=lengths.length*(fast.totalDays+1)&&
  statistics.cachedFactors<=12000,
  "bounded lex suffix distributions");
 checkedFamilies++;
}
console.log("STAGE_49_SCALABLE_METAMORPHIC_PASS"+
 " families="+checkedFamilies+" independentRankSamples="+checkedRanks+
 " mirroredCounts="+mirrorCounts+" lexAdjacent="+lexAdjacent+
 " unexpectedLexMismatches=0 archivedExpectedReds=24 stage49NotClosed=1");
