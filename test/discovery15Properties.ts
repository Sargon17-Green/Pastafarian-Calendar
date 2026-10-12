import {discoverLegacyPositiveGate} from "../src/index.ts";
import {
 FOUNDATION_DAY as F,STONES,NormativeOracle,workCounts,
 buildHiddenDrops,buildVisibleDrops,initialBowls,
 applyVisibleDropsToBowls,postStir12,bowlOrderFromDrop,
 sauce,askBowl,chooseRank
} from "./normativeOracle.ts";
function check(v:boolean,msg:string):void{if(!v)throw Error(msg);}
function source(day:bigint){
 const w=workCounts(F,F+day);
 return {visible:buildVisibleDrops(w,STONES,buildHiddenDrops(w,STONES)),
  stones:STONES,startBowls:initialBowls(w)};
}
const oracle=new NormativeOracle();
let gateCases=0,positive=0,negative=0,gateWrong=0,correctMatches=0,
  genuineCalls=0,genuineWrites=0;
const contexts=new Set<object>();
for(const side of [1n,-1n] as const){
 for(let magnitude=1n;magnitude<=6n;magnitude++){
  const gateIndex=side*magnitude;
  const queries=Array.from({length:Number(magnitude)},(_,i)=>source(BigInt(i+1)));
  const old=discoverLegacyPositiveGate(gateIndex,queries);
  const actual=oracle.gateDay(gateIndex);
  if(old.historicalGateDay!==actual)gateWrong++;else correctMatches++;
  if(side>0n)positive++;else negative++;
  let sum=0n;
  for(let i=0;i<queries.length;i++){
   const n=BigInt(i+1),entry=old.gaps[i]!;
   const expectedRank=chooseRank(askBowl(sauce(F,F+n),1,1n),922n);
   check(entry.historicalRank===expectedRank&&
    entry.historicalGap===41n+expectedRank&&
    entry.askedTargetDay===F+n&&
    entry.normativeTargetDay===F+side*n&&
    entry.predecessorWrites===58&&
    entry.preceding.predecessorSharedWrites===58&&
    entry.preceding.preceding.preceding.preceding.preceding.latchCaptures===1&&
    entry.preceding.preceding.preceding.preceding.preceding.preceding.historical.latestSource==="STIR_12"&&
    entry.preceding.correctedRank===expectedRank&&
    entry.preceding.legacyShortOnlyRank===expectedRank,
    "genuine Foundation signed gate question and complete chain");
   sum+=entry.historicalGap;
   genuineCalls++;genuineWrites+=58;
  }
  check(old.historicalGateDay===F+side*sum&&
   old.actualPredecessorCalls===Number(magnitude)&&
   old.predecessorSharedWrites===magnitude*58n&&
   !contexts.has(old.context)&&
   (side>0n?old.historicalGateDay===actual:true),
   "positive equals normative; negative historical result carries abs error");
  contexts.add(old.context);gateCases++;
 }
}
check(gateCases===12&&positive===6&&negative===6&&correctMatches===6&&
 gateWrong===6&&genuineCalls===42&&genuineWrites===2436,
 "all six negative gate indices reveal wrong positive sauce side");

// Variations with a single historical positive-side question. These are
// NONCANONICAL injected drops, so compare to independent pipeline fed exactly
// the same source. Never mislabel these as true calendar gate fixtures.
const baseline=source(1n),groups=new Set<string>(),variantContexts=new Set<object>();
let varied=0,giant=0,ranks=0,variantCount=0,variantWrites=0;
let injectedStreamWrong=0,injectedGapWrong=0;
function verifyInjected(v:readonly bigint[],bowls:readonly bigint[],kind:"varied"|"giant"|"rank"){
 const original=[...bowls];
 const out=discoverLegacyPositiveGate(-1n,[{visible:v,stones:STONES,startBowls:bowls}]);
 const old=out.gaps[0]!;
 const drops=applyVisibleDropsToBowls([...bowls] as [bigint,bigint,bigint,bigint,bigint,bigint],v,STONES);
 const final=postStir12([...drops.bowls] as [bigint,bigint,bigint,bigint,bigint,bigint]);
 const order=bowlOrderFromDrop(v[46]!);
 const stream=askBowl({bowls:final,orderAtDrop46:order},1,1n);
 const expected=chooseRank(stream,922n);
 if(old.preceding.preceding.firstAnswer!==stream.first||
    old.preceding.preceding.directionStep!==stream.directionStep)injectedStreamWrong++;
 if(old.historicalGap!==41n+expected)injectedGapWrong++;
 check(old.gateIndex===-1n&&old.askedTargetDay===F+1n&&
   old.normativeTargetDay===F-1n&&
   old.preceding.correctedRank===expected&&
   old.preceding.preceding.preceding.preceding.preceding.finalBowls.every((b,j)=>b===final[j])&&
   old.preceding.preceding.preceding.preceding.preceding.afterDropBowls.every((b,j)=>b===drops.bowls[j])&&
   old.preceding.preceding.preceding.preceding.preceding.orderAt46Latch.join(",")===order.join(",")&&
   old.preceding.preceding.preceding.preceding.preceding.sharedMemoryWrites===58&&
   old.preceding.preceding.preceding.preceding.preceding.preceding.historical.latestSource==="STIR_12"&&
   out.historicalGateDay===F-(41n+expected)&&
   out.actualPredecessorCalls===1&&out.predecessorSharedWrites===58n&&
   !variantContexts.has(out.context)&&
   bowls.every((b,j)=>b===original[j]),
   "injected 58-write historical chain matches the independent source transformation");
 variantContexts.add(out.context);variantWrites+=58;variantCount++;
 if(kind==="rank")groups.add(old.preceding.preceding.preceding.preceding.preceding.orderAt46Latch.join(","));
}
for(let j=0;j<64;j++){
 const v=[...baseline.visible];
 v[1]=j%2===0?BigInt(j*149+1):-BigInt(j*137+3);
 v[46]=j%3===0?BigInt(j*721+2):-BigInt(j*719+11);
 verifyInjected(v,baseline.startBowls,"varied");varied++;
}
const huge=(1n<<8192n)+193n;
for(const d of [huge,-huge,huge*huge,-huge*huge,0n,720n,1n<<16384n,-(1n<<16384n)]){
 const v=[...baseline.visible];v[1]=d;v[46]=-d+1n;
 const b=[huge+11n,-huge-13n,huge+17n,-huge-23n,huge+37n,-huge-41n];
 verifyInjected(v,b,"giant");giant++;
}
for(let rank=1n;rank<=720n;rank++){
 const v=[...baseline.visible];v[46]=rank;
 verifyInjected(v,baseline.startBowls,"rank");ranks++;
}
check(varied===64&&giant===8&&ranks===720&&variantCount===792&&
 groups.size===720&&variantContexts.size===792&&variantWrites===45936&&
 injectedStreamWrong===0&&injectedGapWrong===0,
 "720 true DROP46 ranks and giant variations preserve negative legacy error");
console.log("STAGE_30_DISCOVERY_15_PROPERTIES_PASS realCases="+gateCases+
 " positive="+positive+" negative="+negative+" oldWrong="+gateWrong+
 " oldMatches="+correctMatches+" genuineCalls="+genuineCalls+
 " genuineWrites="+genuineWrites+" varied="+varied+" giant="+giant+
 " ranks="+ranks+" unique="+groups.size+" variants="+variantCount+
 " variantWrites="+variantWrites+" totalCalls="+(genuineCalls+variantCount)+
 " totalWrites="+(genuineWrites+variantWrites)+
 " streamWrong="+injectedStreamWrong+" gapWrong="+injectedGapWrong);
