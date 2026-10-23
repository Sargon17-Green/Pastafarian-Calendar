import {
 LegacyRepeatingCutletNames,Discovery22RepeatedNameSelector,
 patch14WideChoice
} from "../src/index.ts";
import {
 FOUNDATION_DAY as F,STONES,NormativeOracle,workCounts,
 buildHiddenDrops,buildVisibleDrops,initialBowls,
 applyVisibleDropsToBowls,postStir12,bowlOrderFromDrop,
 askBowl,chooseRank,fallingFactorial
} from "./normativeOracle.ts";
import {findTrueHistoricalBoundaryMiss,assert} from "./discovery21Fixtures.ts";
const old=new LegacyRepeatingCutletNames();
let familyChecks=0,lexWrong=0,duplicateFamilyRows=0,sampledLarge=0;
for(let K=1;K<=3;K++){
 const family=[...old.oldRows(K)];
 assert(family.length===17**K,"all small repeated rows actually generated");
 for(let i=0;i<family.length;i++){
  const expected: number[]=[];
  let n=i;
  for(let j=K-1;j>=0;j--){
   expected[j]=n%17+1;n=Math.floor(n/17);
  }
  if(family[i]!.join(",")!==expected.join(","))lexWrong++;
  if(new Set(family[i]!).size<K)duplicateFamilyRows++;
  assert(old.oldUnrank(K,BigInt(i+1)).join(",")===expected.join(","),
   "old base17 positional unrank matches independent full lex sequence");
  familyChecks++;
 }
}
assert(familyChecks===5219&&lexWrong===0&&duplicateFamilyRows>0,
 "full 17^1+17^2+17^3 old lex repetitions remain present");
let giantDigits=0;
for(let K=4;K<=17;K++){
 const N=17n**BigInt(K);
 assert(old.oldCount(K)===N&&N>=fallingFactorial(17,K),
  "historical 17^K superset of normative partial permutation");
 for(const r of [1n,2n,17n,18n,(N+1n)/2n,N-1n,N]){
  const out=old.oldUnrank(K,r);
  let rr=r-1n;
  const independent=Array<number>(K);
  for(let j=K-1;j>=0;j--){independent[j]=Number(rr%17n)+1;rr/=17n;}
  assert(out.join(",")===independent.join(",")&&rr===0n&&
   out.length===K&&out.every(x=>x>=1&&x<=17),
   "bigint exact original base17 rank even near 17^17");
  sampledLarge++;giantDigits+=out.length;
 }
}
const witness=findTrueHistoricalBoundaryMiss();
const c=witness.request.historical.yearQuestion.calculationDay;
const source=witness.request.firstDaySauceQuestion!;
const expectedFull=new NormativeOracle().chooseCutletNames(
 {bowls:postStir12([...applyVisibleDropsToBowls(
 [...source.startBowls] as [bigint,bigint,bigint,bigint,bigint,bigint],
 source.visible,source.stones).bowls] as
 [bigint,bigint,bigint,bigint,bigint,bigint]),
 orderAtDrop46:bowlOrderFromDrop(source.visible[46]!)},
 witness.K);
assert(expectedFull.length===witness.K&&new Set(expectedFull).size===witness.K,
 "independent test-only canonical name family has no duplicates");

// All 720 DROP46 bowl orders are deliberately varied inputs, not claims
// that every one is the natural exact historical source question.
const w=workCounts(c,source.targetDay);
const visibleOriginal=buildVisibleDrops(w,STONES,buildHiddenDrops(w,STONES));
const bowls=initialBowls(w),choice=new Discovery22RepeatedNameSelector();
const seen=new Set<string>();
let actual=0,rankWrong=0,namesWrong=0,repeatCases=0,uniqueCases=0,writes=0;
for(let index=1n;index<=720n;index++){
 const visible=[...visibleOriginal];visible[46]=index;
 const state=applyVisibleDropsToBowls(
  [...bowls] as [bigint,bigint,bigint,bigint,bigint,bigint],visible,STONES);
 const final=postStir12([...state.bowls] as
  [bigint,bigint,bigint,bigint,bigint,bigint]);
 const order=bowlOrderFromDrop(index);
 const N=17n**BigInt(witness.K);
 const independent=chooseRank(askBowl({
   bowls:final,orderAtDrop46:order
 },5,22n),N);
 const q={targetDay:source.targetDay,
  visible,stones:source.stones,startBowls:source.startBowls};
 const out=choice.select(c,q,witness.K);
 let d=independent-1n;
 const expected=Array<number>(witness.K);
 for(let j=witness.K-1;j>=0;j--){expected[j]=Number(d%17n)+1;d/=17n;}
 if(independent!==out.legacyRank)rankWrong++;
 if(expected.join(",")!==out.legacyNameIndices.join(","))namesWrong++;
 const duplicates=witness.K-new Set(expected).size;
 assert(out.nativeSeal22.predecessorSharedWrites===58&&
 out.nativeSeal22.queriedBowlId===5&&out.nativeSeal22.seal===22n&&
 out.nativeSeal22.familySize===N&&out.oldActualUnrankCalls===1&&
 out.noDistinctnessFilterApplied&&
 out.legacyRepeatedPositions===duplicates&&
 out.legacyHasRepeatedNames===(duplicates>0),
 "real native Bowl5 seal22 rank and old repeated unrank for injected DROP46");
 if(duplicates>0)repeatCases++;else uniqueCases++;
 writes+=out.nativeSeal22.predecessorSharedWrites;
 actual++;seen.add(order.join(","));
}
assert(seen.size===720&&actual===720&&rankWrong===0&&namesWrong===0&&
 repeatCases>0&&uniqueCases>=0&&writes===41760,
 "720 native Bowl5 real full 58-write path and at least one repeated-name output");
console.log("STAGE_44_DISCOVERY_22_PROPERTIES_PASS"+
 " exhaustiveRows="+familyChecks+" lexWrong="+lexWrong+
 " duplicateRows="+duplicateFamilyRows+" giantRankSamples="+sampledLarge+
 " giantDigits="+giantDigits+" canonicalNamesDistinct=1"+
 " nativeSeal22Variations="+actual+" distinctDrop46Orders="+seen.size+
 " rankWrong="+rankWrong+" namesWrong="+namesWrong+
 " repeatedOutputs="+repeatCases+" uniqueOutputs="+uniqueCases+
 " realSharedWrites="+writes);
