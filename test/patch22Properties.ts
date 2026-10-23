import {
 Patch22DistinctNameFamily,Patch22NameSelection,
 Discovery22RepeatedNameSelector
} from "../src/index.ts";
import {FOUNDATION_DAY as F,STONES,NormativeOracle,workCounts,
 buildHiddenDrops,buildVisibleDrops,initialBowls,
 applyVisibleDropsToBowls,postStir12,bowlOrderFromDrop,
 askBowl,chooseRank,fallingFactorial,unrankDistinctIndices
} from "./normativeOracle.ts";
import {findTrueHistoricalBoundaryMiss,assert} from "./discovery21Fixtures.ts";
const family=new Patch22DistinctNameFamily();
let rows=0,wrong=0;
for(let K=1;K<=3;K++){
 const expected:number[][]=[];
 function visit(prefix:number[],available:number[]):void {
  if(prefix.length===K){expected.push([...prefix]);return;}
  for(let i=0;i<available.length;i++){
   visit([...prefix,available[i]!],
    available.filter((_,j)=>j!==i));
  }
 }
 visit([],Array.from({length:17},(_,i)=>i+1));
 assert(BigInt(expected.length)===family.count(K),"full independent lex family");
 for(let i=0;i<expected.length;i++){
  const actual=family.unrank(K,BigInt(i+1));
  if(actual.join(",")!==expected[i]!.join(","))wrong++;
  rows++;
 }
}
assert(rows===4369&&wrong===0,"exhaustive 1/2/3 unique lex family");
let giants=0;
for(let K=4;K<=17;K++){
 const count=fallingFactorial(17,K);
 assert(family.count(K)===count,"K-length count exactly 17!/(17-K)!");
 for(const rank of [1n,2n,(count+1n)/2n,count-1n,count]){
  const result=family.unrank(K,rank);
  assert(result.length===K&&new Set(result).size===K&&
   result.join(",")===unrankDistinctIndices(17,K,rank).join(","),
   "giant exact one-based distinct lex unrank");
  giants++;
 }
}
const probe=findTrueHistoricalBoundaryMiss();
const c=probe.request.historical.yearQuestion.calculationDay;
const src=probe.request.firstDaySauceQuestion!;
const w=workCounts(c,src.targetDay);
const visible0=buildVisibleDrops(w,STONES,buildHiddenDrops(w,STONES));
const start=initialBowls(w);
const old=new Discovery22RepeatedNameSelector();
const choice=new Patch22NameSelection();
const N=fallingFactorial(17,probe.K);
let rankWrong=0,nameWrong=0,replaced=0,reused=0,writes=0;
const seen=new Set<string>();
for(let i=1n;i<=720n;i++){
 const visible=[...visible0];visible[46]=i;
 const after=applyVisibleDropsToBowls(
  [...start] as [bigint,bigint,bigint,bigint,bigint,bigint],visible,STONES);
 const bowls=postStir12(
  [...after.bowls] as [bigint,bigint,bigint,bigint,bigint,bigint]);
 const order=bowlOrderFromDrop(i);
 const expectedRank=chooseRank(askBowl({bowls,orderAtDrop46:order},5,22n),N);
 const expected=unrankDistinctIndices(17,probe.K,expectedRank);
 const source={targetDay:src.targetDay,visible,
  stones:src.stones,startBowls:src.startBowls};
 const bad=old.select(c,source,probe.K);
 const good=choice.select(c,source,bad);
 if(good.correctedRank!==expectedRank)rankWrong++;
 if(good.correctedNameIndices.join(",")!==expected.join(","))nameWrong++;
 const equal=bad.legacyNameIndices.join(",")===expected.join(",");
 assert(good.legacyEqualsCorrect===equal&&
  good.historicalResultReused===equal&&
  good.correctedNativeSeal22.seal===22n&&
  good.correctedNativeSeal22.queriedBowlId===5&&
  good.correctedNativeSeal22.familySize===N&&
  good.correctedNativeSeal22.predecessorSharedWrites===58&&
  bad.nativeSeal22.familySize===17n**BigInt(probe.K)&&
  bad.nativeSeal22.predecessorSharedWrites===58&&
  good.correctedSelectorCalls===1&&
  new Set(good.correctedNameIndices).size===probe.K,
  "true old seal22, second true corrected seal22, 58+58 writes");
 if(equal)reused++;else replaced++;
 seen.add(order.join(","));writes+=116;
}
assert(rows===4369&&giants===70&&seen.size===720&&
 rankWrong===0&&nameWrong===0&&writes===83520&&replaced>0,
 "all 720 distinct physical DROP46 orders corrected and old calls retained");
console.log("STAGE_45_PATCH_22_PROPERTIES_PASS"+
 " exhaustiveDistinctRows="+rows+" exhaustiveWrong="+wrong+
 " largeRankSamples="+giants+
 " nativeOldPlusCorrectedSeal22="+(seen.size*2)+
 " distinctDrop46Orders="+seen.size+
 " rankWrong="+rankWrong+" namesWrong="+nameWrong+
 " correctedLegacyReplaced="+replaced+" exactLegacyReused="+reused+
 " realSharedWrites="+writes);
