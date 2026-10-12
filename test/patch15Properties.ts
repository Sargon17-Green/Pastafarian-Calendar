import {patch15SignedGate} from "../src/index.ts";
import {
 FOUNDATION_DAY as F,STONES,NormativeOracle,workCounts,
 buildHiddenDrops,buildVisibleDrops,initialBowls,
 applyVisibleDropsToBowls,postStir12,bowlOrderFromDrop,
 sauce,askBowl,chooseRank
} from "./normativeOracle.ts";
function check(ok:boolean,msg:string):void{if(!ok)throw Error(msg);}
function source(step:bigint){
 const w=workCounts(F,F+step);
 return {targetDay:F+step,visible:buildVisibleDrops(w,STONES,buildHiddenDrops(w,STONES)),
  stones:STONES,startBowls:initialBowls(w)};
}
function fixtures(gate:bigint){
 const n=Number(gate<0n?-gate:gate),sign=gate<0n?-1n:1n;
 return {
  historical:Array.from({length:n},(_,i)=>source(BigInt(i+1))),
  correct:Array.from({length:n},(_,i)=>source(BigInt(i+1)*sign))
 };
}
const oracle=new NormativeOracle();
const owners=new Set<object>();
let gates=0,positive=0,negative=0,correctWrong=0,oldWrong=0,oldSame=0;
let gateLegacy=0,gateAdditional=0,gateCalls=0,gateWrites=0;
for(const side of [1n,-1n] as const){
 for(let n=1n;n<=6n;n++){
  const signed=side*n,qs=fixtures(signed);
  const out=patch15SignedGate(signed,qs.historical,qs.correct);
  const canonical=oracle.gateDay(signed);
  if(out.correctedGateDay!==canonical)correctWrong++;
  if(out.historicalGateDay!==canonical)oldWrong++;else oldSame++;
  if(side===1n)positive++;else negative++;
  const oldGaps:number[]=[],signedGaps:number[]=[];
  for(let j=0;j<Number(n);j++){
   const positiveIndex=BigInt(j+1),right=side*positiveIndex;
   const expected=chooseRank(askBowl(sauce(F,F+right),1,1n),922n);
   const oldExpected=chooseRank(askBowl(sauce(F,F+positiveIndex),1,1n),922n);
   const g=out.gaps[j]!;
   check(g.correctedRank===expected&&g.correctedGap===41n+expected&&
     g.historicalGap===41n+oldExpected&&g.askedTargetDay===F+right&&
     g.historicalAskedTargetDay===F+positiveIndex&&
     g.correctedPredecessor.correctedRank===expected&&
     g.correctedPredecessor.predecessorSharedWrites===58&&
     g.correctedPredecessor.preceding.preceding.preceding.legacyModuloCalls===1&&
     g.correctedPredecessor.preceding.preceding.preceding.preceding.latchCaptures===1&&
     g.correctedPredecessor.preceding.preceding.preceding.preceding.preceding.historical.latestSource==="STIR_12"&&
     g.reusedPositiveHistorical===(side===1n)&&
     g.addedNegativeSideCalls===(side<0n?1:0),
     "each signed gap independent canonical saucepan and previous 58 writes");
   oldGaps.push(Number(g.historicalGap));
   signedGaps.push(Number(g.correctedGap));
  }
  const sumRight=signedGaps.reduce((a,b)=>a+b,0);
  const sumOld=oldGaps.reduce((a,b)=>a+b,0);
  check(out.correctedGateDay===F+side*BigInt(sumRight)&&
    out.historicalGateDay===F+side*BigInt(sumOld)&&
    out.totalPredecessorCalls===Number(n)*(side<0n?2:1)&&
    out.extraNegativePredecessorCalls===(side<0n?Number(n):0)&&
    out.totalSharedWrites===BigInt(out.totalPredecessorCalls)*58n&&
    out.preceding.predecessorSharedWrites===n*58n&&
    out.context.status==="PATCH_15_APPLIED"&&
    !owners.has(out.context)&&out.context!==out.preceding.context&&
    Object.isFrozen(out)&&Object.isFrozen(out.gaps),
    "correct accumulated gate position and immutable owners");
  owners.add(out.context);gates++;
  gateLegacy+=Number(n);gateAdditional+=out.extraNegativePredecessorCalls;
  gateCalls+=out.totalPredecessorCalls;gateWrites+=out.totalPredecessorCalls*58;
 }
}
check(gates===12&&positive===6&&negative===6&&correctWrong===0&&
  oldWrong===6&&oldSame===6&&owners.size===12&&
  gateLegacy===42&&gateAdditional===21&&gateCalls===63&&gateWrites===3654,
 "signed ±1..±6 full real production histories and preserved six failures");

// 792 noncanonical injected correct-negative inputs. They validate the
// real production 58-write route against an independently reconstructed
// answer stream for precisely those same values, NOT a calendar date claim.
const oldSource=source(1n),baseline=source(-1n);
const orders=new Set<string>(),variantOwners=new Set<object>();
let varied=0,giant=0,ranks=0,variantCases=0,variantCalls=0,variantWrites=0;
let streamWrong=0,rankWrong=0,oldRankWrong=0,oldQuestionWrong=0;
function verifyInjected(visible:readonly bigint[],bowls:readonly bigint[],kind:"varied"|"giant"|"rank"){
 const oldSnapshot=[...oldSource.startBowls],signedSnapshot=[...bowls];
 const signed={targetDay:F-1n,visible,stones:STONES,startBowls:bowls};
 const out=patch15SignedGate(-1n,[oldSource],[signed]);
 const entry=out.gaps[0]!;
 const after=applyVisibleDropsToBowls(
  [...bowls] as [bigint,bigint,bigint,bigint,bigint,bigint],visible,STONES);
 const final=postStir12(
  [...after.bowls] as [bigint,bigint,bigint,bigint,bigint,bigint]);
 const order=bowlOrderFromDrop(visible[46]!);
 const stream=askBowl({bowls:final,orderAtDrop46:order},1,1n);
 const rank=chooseRank(stream,922n);
 const oldRank=chooseRank(askBowl(sauce(F,F+1n),1,1n),922n);
 if(entry.correctedPredecessor.preceding.preceding.firstAnswer!==stream.first||
   entry.correctedPredecessor.preceding.preceding.directionStep!==stream.directionStep)
   streamWrong++;
 if(entry.correctedRank!==rank)rankWrong++;
 if(entry.historicalGap!==41n+oldRank)oldRankWrong++;
 if(entry.historicalAskedTargetDay!==F+1n||entry.askedTargetDay!==F-1n)oldQuestionWrong++;
 check(out.correctedGateDay===F-(41n+rank)&&
  out.historicalGateDay===F-(41n+oldRank)&&
  entry.correctedPredecessor.preceding.preceding.preceding.preceding.finalBowls.every((v,j)=>v===final[j])&&
  entry.correctedPredecessor.preceding.preceding.preceding.preceding.afterDropBowls.every((v,j)=>v===after.bowls[j])&&
  entry.correctedPredecessor.preceding.preceding.preceding.preceding.orderAt46Latch.join(",")===order.join(",")&&
  entry.correctedPredecessor.preceding.preceding.preceding.preceding.sharedMemoryWrites===58&&
  entry.correctedPredecessor.preceding.preceding.preceding.preceding.preceding.historical.latestSource==="STIR_12"&&
  entry.correctedPredecessor.correctedRank===rank&&
  out.totalPredecessorCalls===2&&out.totalSharedWrites===116n&&
  out.extraNegativePredecessorCalls===1&&
  out.preceding.gaps[0]!.preceding.correctedRank===oldRank&&
  !variantOwners.has(out.context)&&out.context!==out.preceding.context&&
  bowls.every((v,j)=>v===signedSnapshot[j])&&
  oldSource.startBowls.every((v,j)=>v===oldSnapshot[j]),
  "injected negative input independently rebuilt from all 58 shared writes");
 variantOwners.add(out.context);variantCases++;variantCalls+=2;variantWrites+=116;
 if(kind==="rank")
  orders.add(entry.correctedPredecessor.preceding.preceding.preceding.preceding.orderAt46Latch.join(","));
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
check(varied===64&&giant===8&&ranks===720&&
 variantCases===792&&variantOwners.size===792&&orders.size===720&&
 variantCalls===1584&&variantWrites===91872&&
 streamWrong===0&&rankWrong===0&&oldRankWrong===0&&oldQuestionWrong===0,
 "all 720 order permutations, signed giants, and independent true reference");
console.log("STAGE_31_PATCH_15_PROPERTIES_PASS gateCases="+gates+
 " positive="+positive+" negative="+negative+" correctedWrong="+correctWrong+
 " oldWrong="+oldWrong+" oldMatches="+oldSame+" historicalQuestions="+gateLegacy+
 " additionalNegative="+gateAdditional+" genuineCalls="+gateCalls+
 " genuineWrites="+gateWrites+" varied="+varied+" giant="+giant+
 " ranks="+ranks+" unique="+orders.size+" variants="+variantCases+
 " variantCalls="+variantCalls+" variantWrites="+variantWrites+
 " totalCalls="+(gateCalls+variantCalls)+" totalWrites="+(gateWrites+variantWrites)+
 " streamWrong="+streamWrong+" rankWrong="+rankWrong+
 " oldRankWrong="+oldRankWrong+" oldQuestionWrong="+oldQuestionWrong);
