import {
  Patch11OrderLatchHandler,patch11OrderLatch,Patch20StructureSauceHandler,
  Discovery20StructureSauceHandler,Patch19YearCacheHandler,
  patch20StructureSauce
} from "../src/index.ts";
import {
  FOUNDATION_DAY as F,STONES,workCounts,buildHiddenDrops,buildVisibleDrops,
  initialBowls,sauce,applyVisibleDropsToBowls,postStir12,bowlOrderFromDrop
} from "./normativeOracle.ts";
import {buildDiscovery19Fixture,question,assert} from "./discovery19Fixtures.ts";
function eq(a:readonly bigint[],b:readonly bigint[]){
 return a.length===b.length&&a.every((v,j)=>v===b[j]);
}
function raw(c:bigint,t:bigint){
 const counts=workCounts(c,t);return {
  targetDay:t,
  visible:buildVisibleDrops(counts,STONES,buildHiddenDrops(counts,STONES)),
  stones:STONES,startBowls:initialBowls(counts)
 };
}
const big=1n<<8192n;
let direct=0,giantDays=0,directWrong=0,directWrites=0;
for(let j=0;j<128;j++){
 const c=j%4===0?big+BigInt(j):j%4===1?-big-BigInt(j):
   j%4===2?F+BigInt(j):F-BigInt(j);
 const first=c+BigInt((j%41)+1);
 const input=raw(c,first),snapshot=[...input.startBowls];
 const out=patch11OrderLatch(c,first,input.visible,input.stones,input.startBowls);
 const expected=sauce(c,first);
 if(!eq(out.finalBowls,expected.bowls)||
    out.orderAt46Latch.join(",")!==expected.orderAtDrop46.join(","))
  directWrong++;
 assert(out.sharedMemoryWrites===58&&out.drops===46&&out.postStirs===12&&
  out.latchCaptures===1&&
  out.historical.latestSource==="STIR_12"&&
  out.ledger[45]?.source==="DROP_46"&&
  out.ledger[57]?.source==="STIR_12"&&
  input.startBowls.every((v,k)=>v===snapshot[k])&&
  Object.isFrozen(out.finalBowls)&&Object.isFrozen(out.orderAt46Latch),
  "128 genuine native first-day Sauce paths compare independent normative source");
 if(c>big/2n||c< -big/2n)giantDays++;
 direct++;directWrites+=58;
}
assert(direct===128&&giantDays===64&&directWrong===0&&directWrites===7424,
 "direct canonical first-day Sauce checked including 8192-bit signed days");

const c=F+145n,first=F+211n;
const base=raw(c,first);
const snapshot=[...base.startBowls];
const orderIDs=new Set<string>();
let permutations=0,permutationWrong=0,permutationWrites=0;
for(let k=1n;k<=720n;k++){
 const altered=[...base.visible];altered[46]=k;
 const input={...base,visible:altered};
 const after=applyVisibleDropsToBowls(
  [...base.startBowls] as [bigint,bigint,bigint,bigint,bigint,bigint],
  altered,STONES);
 const final=postStir12(
  [...after.bowls] as [bigint,bigint,bigint,bigint,bigint,bigint]);
 const expectedOrder=bowlOrderFromDrop(k);
 const out=patch11OrderLatch(c,first,input.visible,input.stones,input.startBowls);
 if(!eq(out.finalBowls,final)||
    out.orderAt46Latch.join(",")!==expectedOrder.join(","))
  permutationWrong++;
 assert(eq(out.afterDropBowls,after.bowls)&&
  eq(out.finalBowls,final)&&
  out.orderAt46Latch.join(",")===expectedOrder.join(",")&&
  out.sharedMemoryWrites===58&&
  out.ledger[45]?.source==="DROP_46"&&
  out.ledger[57]?.source==="STIR_12"&&
  base.startBowls.every((v,j)=>v===snapshot[j]),
  "explicit injected DROP46 rank verified by independent full bowl replay");
 orderIDs.add(out.orderAt46Latch.join(","));
 permutations++;permutationWrites+=58;
}
assert(orderIDs.size===720&&permutations===720&&permutationWrong===0,
 "720 distinct independently rechecked latch permutations");
let giantSources=0,giantWrites=0;
for(const d of [big,-big,big*big,-big*big,0n,720n,
 1n<<16384n,-(1n<<16384n)]){
 const drops=[...base.visible];drops[1]=d;drops[46]=-d+1n;
 const bowls=[big+11n,-big-13n,big+17n,-big-23n,big+37n,-big-41n];
 const before=[...bowls];
 const after=applyVisibleDropsToBowls(
  [...bowls] as [bigint,bigint,bigint,bigint,bigint,bigint],drops,STONES);
 const final=postStir12(
  [...after.bowls] as [bigint,bigint,bigint,bigint,bigint,bigint]);
 const expectedOrder=bowlOrderFromDrop(drops[46]!);
 const out=patch11OrderLatch(c,first,drops,STONES,bowls);
 assert(eq(out.finalBowls,final)&&
  out.orderAt46Latch.join(",")===expectedOrder.join(",")&&
  bowls.every((v,j)=>v===before[j])&&
  out.sharedMemoryWrites===58,
  "enormous noncanonical input correctly processed, no shared buffer aliasing");
 giantSources++;giantWrites+=58;
}
const fixture=buildDiscovery19Fixture();
const handler=new Patch20StructureSauceHandler(
 new Discovery20StructureSauceHandler(new Patch19YearCacheHandler()));
let trueYears=0,trueWrong=0,oldWrong=0,trueSharedWrites=0,truePredecessors=0;
for(const [req,seed] of [[fixture.first,fixture.firstSeed],
 [fixture.second,fixture.secondSeed]] as const){
 const q={
  historical:{
   yearQuestion:req,
   originalSauceQuestion:question(req.calculationDay,req.targetDay)
  },
  firstDaySauceQuestion:question(req.calculationDay,seed.openGateDay+1n)
 };
 const obs=patch20StructureSauce(handler,q);
 const corrected=sauce(req.calculationDay,seed.openGateDay+1n);
 const original=sauce(req.calculationDay,req.targetDay);
 if(!eq(obs.authoritativeBowls,corrected.bowls)||
   obs.authoritativeOrderAtDrop46.join(",")!==
     corrected.orderAtDrop46.join(","))trueWrong++;
 if(eq(obs.historical.oldSauce.bowls,corrected.bowls)&&
   obs.historical.oldSauce.orderAtDrop46.join(",")===
     corrected.orderAtDrop46.join(","))oldWrong++;
 assert(obs.historical.fullStage39.correctedServed.year.openGateDay===
    seed.openGateDay&&
   obs.trueYearFirstDay===seed.openGateDay+1n&&
   obs.trueYearNumber===5000n&&
   obs.newFirstDaySauce!==null&&
   obs.newFirstDaySauce.sharedMemoryWrites===58&&
   obs.authoritativeFirstDay===seed.openGateDay+1n&&
   eq(obs.historical.oldSauce.bowls,original.bowls)&&
   obs.historical.oldSauce.orderAtDrop46.join(",")===
      original.orderAtDrop46.join(",")&&
   obs.totalSharedMemoryWrites===BigInt(obs.totalRealPredecessorCalls)*58n&&
   obs.context.status==="PATCH_20_APPLIED",
   "true Stage39/40 predecessors and first-day patched Sauce both physical");
 trueYears++;trueSharedWrites+=Number(obs.totalSharedMemoryWrites);
 truePredecessors+=obs.totalRealPredecessorCalls;
}
assert(trueYears===2&&trueWrong===0&&oldWrong===0&&
 trueSharedWrites===truePredecessors*58&&
 giantSources===8&&permutationWrites===41760&&giantWrites===464,
 "two true Year5000 routes repaired with exact shared-memory write ledger");
console.log("STAGE_41_PATCH_20_PROPERTIES_PASS directSauces="+direct+
 " signedGiantDays="+giantDays+" directWrong="+directWrong+
 " directWrites="+directWrites+" drop46Variants="+permutations+
 " uniqueOrders="+orderIDs.size+" permutationWrong="+permutationWrong+
 " permutationWrites="+permutationWrites+" giantSources="+giantSources+
 " giantSourceWrites="+giantWrites+" realYears="+trueYears+
 " correctedWrong="+trueWrong+" oldFortuitousMatches="+oldWrong+
 " fullRealPredecessors="+truePredecessors+
 " fullRealWrites="+trueSharedWrites);
