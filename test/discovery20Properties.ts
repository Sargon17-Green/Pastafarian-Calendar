import {
  LegacyStructureSauceAdapter,Discovery20StructureSauceHandler,
  discoverLegacyStructureSauce,Patch19YearCacheHandler,
  Patch11OrderLatchHandler
} from "../src/index.ts";
import {
  FOUNDATION_DAY as F,STONES,NormativeOracle,
  workCounts,buildHiddenDrops,buildVisibleDrops,initialBowls,
  sauce,applyVisibleDropsToBowls,postStir12,bowlOrderFromDrop
} from "./normativeOracle.ts";
import {buildDiscovery19Fixture,question,assert} from "./discovery19Fixtures.ts";
function raw(c:bigint,t:bigint){
 const counts=workCounts(c,t);
 return {
  targetDay:t,
  visible:buildVisibleDrops(counts,STONES,buildHiddenDrops(counts,STONES)),
  stones:STONES,startBowls:initialBowls(counts)
 };
}
function eq(a:readonly bigint[],b:readonly bigint[]):boolean{
 return a.length===b.length&&a.every((v,i)=>v===b[i]);
}
const old=new LegacyStructureSauceAdapter();
let directCases=0,directWrong=0,exact=0,realWrites=0;
let enormousDays=0;
const big=1n<<8192n;
for(let i=0;i<128;i++){
 const c=i%4===0?big+BigInt(i):
         i%4===1?-big-BigInt(i):
         i%4===2?F+BigInt(i):F-BigInt(i);
 const t=i%3===0?c:((i%3===1)?c+BigInt(i+1):c-BigInt(i+1));
 const q=raw(c,t);
 const out=old.oldStructureSauce(c,t,q);
 const want=sauce(c,t);
 assert(eq(out.bowls,want.bowls)&&
  out.orderAtDrop46.join(",")===want.orderAtDrop46.join(",")&&
  out.sharedMemoryWrites===58&&out.preceding.drops===46&&
  out.preceding.postStirs===12&&
  out.preceding.historical.latestSource==="STIR_12"&&
  out.preceding.ledger[45]?.source==="DROP_46"&&
  out.preceding.ledger[57]?.source==="STIR_12"&&
  Object.isFrozen(out)&&Object.isFrozen(out.bowls),
  "historical raw Sauce agrees with independent full 46-drop/12-stir oracle");
 if(t!==c&&(!eq(want.bowls,sauce(c,c).bowls)||
   want.orderAtDrop46.join(",")!==sauce(c,c).orderAtDrop46.join(",")))directWrong++;
 if(t===c)exact++;
 if(c>big/2n||c< -big/2n)enormousDays++;
 realWrites+=58;directCases++;
}
const source=raw(F+145n,F+211n),ownerSnapshot=[...source.startBowls];
const orders=new Set<string>();
let syntheticVariants=0,variantWrong=0,variantWrites=0;
for(let id=1n;id<=720n;id++){
 const altered=[...source.visible];
 altered[46]=id;
 const q={...source,visible:altered};
 const after=applyVisibleDropsToBowls(
   [...source.startBowls] as [bigint,bigint,bigint,bigint,bigint,bigint],
   altered,STONES);
 const expected=postStir12(
   [...after.bowls] as [bigint,bigint,bigint,bigint,bigint,bigint]);
 const desiredOrder=bowlOrderFromDrop(id);
 const out=old.oldStructureSauce(F+145n,F+211n,q);
 if(!eq(out.bowls,expected))variantWrong++;
 assert(eq(out.bowls,expected)&&
  out.orderAtDrop46.join(",")===desiredOrder.join(",")&&
  out.preceding.afterDropBowls.every((v,j)=>v===after.bowls[j])&&
  out.preceding.finalBowls.every((v,j)=>v===expected[j])&&
  out.preceding.sharedMemoryWrites===58&&
  out.preceding.historical.ledger[57]?.source==="STIR_12"&&
  source.startBowls.every((v,j)=>v===ownerSnapshot[j]),
  "720 native shared-bowl states vs independent post-stir reference");
 orders.add(out.orderAtDrop46.join(","));
 syntheticVariants++;variantWrites+=58;
}
assert(orders.size===720&&variantWrong===0,
 "all 720 distinct latched orders preserved for historical old t sauce");
let giantSources=0,giantWrites=0;
for(const d of [big,-big,big*big,-big*big,0n,720n,
 (1n<<16384n),-(1n<<16384n)]){
 const altered=[...source.visible];altered[1]=d;altered[46]=-d+1n;
 const bowls=[big+11n,-big-13n,big+17n,-big-23n,big+37n,-big-41n];
 const q={...source,visible:altered,startBowls:bowls};
 const after=applyVisibleDropsToBowls(
  [...bowls] as [bigint,bigint,bigint,bigint,bigint,bigint],
  altered,STONES);
 const post=postStir12(
  [...after.bowls] as [bigint,bigint,bigint,bigint,bigint,bigint]);
 const got=old.oldStructureSauce(F+145n,F+211n,q);
 assert(eq(got.bowls,post)&&
  got.orderAtDrop46.join(",")===bowlOrderFromDrop(altered[46]!).join(",")&&
  got.sharedMemoryWrites===58,
  "unbounded signed bigint source still executes real legacy 58 shared writes");
 giantSources++;giantWrites+=58;
}
// Distinct genuine current years in consecutive calculations, historical
// original-target sauce not mistaken for first-day sauce.
const fixture=buildDiscovery19Fixture(),oracle=new NormativeOracle();
const h=new Discovery20StructureSauceHandler(new Patch19YearCacheHandler());
const requests=[
 {yearQuestion:fixture.first,
  originalSauceQuestion:question(fixture.first.calculationDay,fixture.first.targetDay)},
 {yearQuestion:fixture.second,
  originalSauceQuestion:question(fixture.second.calculationDay,fixture.second.targetDay)}
];
let trueCases=0,trueWrong=0,truePredecessors=0,trueWrites=0;
const contexts=new Set<object>();
for(const q of requests){
 const got=discoverLegacyStructureSauce(h,q);
 const seed=oracle.year5000(q.yearQuestion.calculationDay);
 const incorrect=sauce(q.yearQuestion.calculationDay,q.yearQuestion.targetDay);
 const right=sauce(q.yearQuestion.calculationDay,seed.openGateDay+1n);
 if(got.oldSauce.bowls.some((x,i)=>x!==right.bowls[i])||
     got.oldSauce.orderAtDrop46.join(",")!==right.orderAtDrop46.join(","))trueWrong++;
 assert(got.yearOpenGateDay===seed.openGateDay&&
  got.yearCloseGateDay===seed.closeGateDay&&
  got.yearNumber===5000n&&
  got.oldSauce.originalTargetDay===q.yearQuestion.targetDay&&
  eq(got.oldSauce.bowls,incorrect.bowls)&&
  got.oldSauce.orderAtDrop46.join(",")===incorrect.orderAtDrop46.join(",")&&
  got.historicalWrongTarget&&!got.correctedStructureSauceComputed&&
  got.fullStage39.context.status==="PATCH_19_APPLIED"&&
  got.fullStage39.correctedServed.year.number===5000n&&
  got.totalRealPredecessorCalls===got.trueYearPredecessorCalls+1&&
  got.totalSharedMemoryWrites===BigInt(got.totalRealPredecessorCalls)*58n&&
  !contexts.has(got.context),
  "genuine Stage39 full predecessor followed by a real wrong target-based Sauce");
 contexts.add(got.context);
 trueCases++;truePredecessors+=got.totalRealPredecessorCalls;
 trueWrites+=Number(got.totalSharedMemoryWrites);
}
assert(trueWrong===2&&contexts.size===2,
 "both independent physically selected Year5000 examples expose original t bug");
const physical=Patch11OrderLatchHandler.prototype.run;
let spy=0;
try{
 Patch11OrderLatchHandler.prototype.run=function(...args){
  spy++;return physical.apply(this,args);
 };
 const q=raw(17n,21n);
 const result=old.oldStructureSauce(17n,21n,q);
 assert(spy===1&&result.sharedMemoryWrites===58,
  "actually invokes the old 58-write production bowl chain");
}finally{Patch11OrderLatchHandler.prototype.run=physical;}
console.log("STAGE_40_DISCOVERY_20_PROPERTIES_PASS"+
 " directSauces="+directCases+" directDifferent="+directWrong+
 " equalTarget="+exact+" giantCalculationDays="+enormousDays+
 " directWrites="+realWrites+
 " drop46Variations="+syntheticVariants+" uniqueOrder="+orders.size+
 " syntheticWrong="+variantWrong+" syntheticWrites="+variantWrites+
 " enormousSources="+giantSources+" enormousWrites="+giantWrites+
 " realYear5000Cases="+trueCases+" historicalWrong="+trueWrong+
 " realFullPredecessors="+truePredecessors+" realFullWrites="+trueWrites+
 " actualOldBowlChainSpy="+spy+
 " nextStageCorrectedSauceCalls=0");
