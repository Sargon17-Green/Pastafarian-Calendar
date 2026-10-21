import {
 Patch21FilteredPositiveCompositions,LegacyPositiveCompositions,
 oldHasPrefixBoundary,patch14WideChoice
} from "../src/index.ts";
import {
 FOUNDATION_DAY as F,STONES,workCounts,buildHiddenDrops,
 buildVisibleDrops,initialBowls,applyVisibleDropsToBowls,
 postStir12,bowlOrderFromDrop,askBowl,chooseRank
} from "./normativeOracle.ts";
import {assert,anyPrefix} from "./discovery21Fixtures.ts";
const dp=new Patch21FilteredPositiveCompositions();
const old=new LegacyPositiveCompositions();
let families=0,filteredWrong=0,totalMembers=0,giantCases=0;
for(let G=6n;G<=19n;G++){
 for(let K=2;K<=Math.min(Number(G),7);K++){
  const rows=[...old.legacyPositiveCompositions(G,K)];
  for(let required=1n;required<G;required++){
   const truth=rows.filter(row=>anyPrefix(row,required));
   const count=dp.count(G,K,required);
   if(count!==BigInt(truth.length))filteredWrong++;
   assert(count===BigInt(truth.length)&&count>0n,
    "exact DP count matches separately generated normative lex family");
   for(let i=0;i<truth.length;i++){
    const got=dp.unrank(G,K,required,BigInt(i+1));
    assert(got.join(",")===truth[i]!.join(","),
     "exact DP unrank matches independent lex filtering at every rank");
    totalMembers++;
   }
   families++;
  }
 }
}
const huge=1n<<1024n;
for(const x of [
 [huge+50n,6,1n],[huge+50n,6,huge],
 [huge+50n,17,huge/2n],[huge+50n,17,huge+49n]
] as const){
 const [G,K,required]=x;
 const N=dp.count(G,K,required);
 assert(N>0n&&N<=old.oldCount(G,K),
   "giant exact combinatorial count bounded by unfiltered history");
 for(const rank of [1n,(N+1n)/2n,N]){
  const row=dp.unrank(G,K,required,rank);
  assert(row.length===K&&row.reduce((a,b)=>a+b,0n)===G&&
   oldHasPrefixBoundary(row,required)&&row.every(v=>v>0n),
   "giant 1024-bit exact lex unrank preserves mandatory boundary");
 }
 giantCases++;
}
// 720 physically distinct first-day 46-drop order latch questions; for
// each compare the real production seal21 rank to test-only independent
// after-drop bowls, post-stir12, and original lex filtered family.
const c=F+1031n,t=F+911n,w=workCounts(c,t);
const original=buildVisibleDrops(w,STONES,buildHiddenDrops(w,STONES));
const start=initialBowls(w);
const G=26n,K=6,required=11n,N=dp.count(G,K,required);
const seen=new Set<string>();
let orders=0,rankWrong=0,boundaryWrong=0,sharedWrites=0;
for(let pos=1n;pos<=720n;pos++){
 const visible=[...original];visible[46]=pos;
 const after=applyVisibleDropsToBowls(
   [...start] as [bigint,bigint,bigint,bigint,bigint,bigint],
   visible,STONES);
 const final=postStir12([...after.bowls] as
   [bigint,bigint,bigint,bigint,bigint,bigint]);
 const order=bowlOrderFromDrop(pos);
 const expected=chooseRank(askBowl({
   bowls:final,orderAtDrop46:order
 },2,21n),N);
 const actual=patch14WideChoice(c,t,visible,STONES,start,2,21n,N);
 if(actual.correctedRank!==expected)rankWrong++;
 const row=dp.unrank(G,K,required,actual.correctedRank);
 if(!oldHasPrefixBoundary(row,required))boundaryWrong++;
 assert(actual.queriedBowlId===2&&actual.seal===21n&&
   actual.familySize===N&&actual.predecessorSharedWrites===58,
   "one native Sauce/Seal21 choice per Drop46 ordering");
 sharedWrites+=actual.predecessorSharedWrites;
 seen.add(order.join(","));
 orders++;
}
assert(orders===720&&seen.size===720&&rankWrong===0&&
 boundaryWrong===0&&sharedWrites===41760,
 "all 720 distinct order latches preserve true filtered seal21 rank");
console.log("STAGE_43_PATCH_21_PROPERTIES_PASS exhaustiveFamilies="+families+
 " exhaustiveMembers="+totalMembers+" filteredWrong="+filteredWrong+
 " giant1024BitFamilies="+giantCases+" nativeSeal21Cases="+orders+
 " uniqueDrop46Orders="+seen.size+" independentRankWrong="+rankWrong+
 " mandatoryBoundaryWrong="+boundaryWrong+" sharedWrites="+sharedWrites);
