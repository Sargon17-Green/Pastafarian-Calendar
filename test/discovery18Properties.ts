import {
  Legacy365JumpGuessAdapter,Legacy365JumpDiagnostic,
  legacyFloorDivPositive,discoverLegacyJumpGuess
} from "../src/index.ts";
import {
  FOUNDATION_DAY as F,STONES,NormativeOracle,workCounts,
  buildHiddenDrops,buildVisibleDrops,initialBowls,sauce,askBowl,chooseRank,
  applyVisibleDropsToBowls,postStir12,bowlOrderFromDrop
} from "./normativeOracle.ts";
function check(x:boolean,m:string):void{if(!x)throw Error(m);}
function source(c:bigint,t:bigint){
 const w=workCounts(c,t);
 return {visible:buildVisibleDrops(w,STONES,buildHiddenDrops(w,STONES)),
  stones:STONES,startBowls:initialBowls(w)};
}
const old=new Legacy365JumpGuessAdapter(),diag=new Legacy365JumpDiagnostic();
const a={number:5000n,firstDay:F+1n,lastDay:F+5778n};
let grid=0,gridWrong=0,insideFalse=0,negativeFloors=0;
for(let delta=-2000n;delta<=2000n;delta+=5n){
 const q=delta>=0n?delta/365n:-((-delta+364n)/365n);
 const expected=5000n+q;
 const value=old.oldJumpGuess(a,a.firstDay+delta);
 const record=diag.measure(a,a.firstDay+delta);
 if(value!==expected)gridWrong++;
 if(delta<0n&&delta%365n!==0n)negativeFloors++;
 if(delta>=0n&&record.knownAnchorMismatch===true)insideFalse++;
 check(value===expected&&
  legacyFloorDivPositive(delta,365n)===q&&
  record.estimatedYearNumber===expected&&
  record.authoritativeTargetYearResolved===false&&
  record.authoritativeTraversalPerformed===false&&
  record.knownAnchorMismatch===(delta>=0n&&delta<=5777n?q!==0n:null),
  "801 independently calculated signed floor-div cells, no guessed authority");
 grid++;
}
check(grid===801&&gridWrong===0&&negativeFloors>0&&insideFalse>200,
 "many true in-anchor false 365 guesses and exact mathematical floor");
const huge=(1n<<16384n)+193n;
const giantSamples=[huge,-huge,huge*huge,-huge*huge,
 (1n<<32768n)+1n,-(1n<<32768n)-1n,0n,365n];
let big=0;
for(const d of giantSamples){
 const independent=d>=0n?d/365n:-((-d+364n)/365n);
 check(old.oldJumpGuess(a,a.firstDay+d)===5000n+independent&&
   diag.measure(a,a.firstDay+d).role==="TELEMETRY_ONLY",
  "arbitrary-width signed jump guesses use floor not truncation");
 big++;
}

// Real gate-pair seed and genuine normative SEAL11/SEAL12 one-step
// oracles. Number 5000 assigned only as a hypothetical seed; this seed
// has NOT been claimed to equal independently selected year5000(c).
const gateOracle=new NormativeOracle();
const start=gateOracle.gateDay(1n),end=gateOracle.gateDay(7n),cDay=start+1n;
const genuineSeed={
 number:5000n,openGateIndex:1n,closeGateIndex:7n,
 openGateDay:start,closeGateDay:end
};
check(end>start&&end-start>=252n&&end-start<=5778n,
 "true gate-generated 6-gap pair is a legally ranged seed");
const right=gateOracle.nextYear(cDay,genuineSeed);
const left=gateOracle.previousYear(cDay,genuineSeed);
check(right.number===5001n&&left.number===4999n&&
 right.openGateIndex===genuineSeed.closeGateIndex&&
 left.closeGateIndex===genuineSeed.openGateIndex,
 "test-only oracle genuinely stepped one year in either direction");
const realProbe={
 number:5000n,firstDay:start+1n,lastDay:end
};
const forwardDay=right.closeGateDay;
const backwardDay=left.openGateDay+1n;
const forwardOld=old.oldJumpGuess(realProbe,forwardDay);
const backwardOld=old.oldJumpGuess(realProbe,backwardDay);
check(forwardOld!==right.number&&backwardOld!==left.number&&
 forwardDay>genuineSeed.closeGateDay&&backwardDay<=genuineSeed.openGateDay&&
 diag.measure(realProbe,forwardDay).authoritativeTargetYearResolved===false&&
 diag.measure(realProbe,backwardDay).authoritativeTargetYearResolved===false,
 "independent genuine one-step seal11/12 proves wrong old /365 guesses both directions");
const inSeedWrong=old.oldJumpGuess(realProbe,end)!==genuineSeed.number;
check(inSeedWrong,"original 365 guess even wrong inside genuine six-gate seed");

function nominal(index:bigint,oracle:NormativeOracle){
 const g=oracle.gateDay(index),c=g+1n;
 const sign=index<0n?-1n:1n,n=Number(index<0n?-index:index);
 return {index,g,c,
  historical:Array.from({length:n},(_,j)=>source(F,F+BigInt(j+1))),
  signed:Array.from({length:n},(_,j)=>({
    ...source(F,F+sign*BigInt(j+1)),targetDay:F+sign*BigInt(j+1)
  })),
  year:source(c,c),
  anchor:[{openGateIndex:index,closeGateIndex:index+6n,
   openGateDay:g,closeGateDay:g+800n}],
  candidates:[
    {openGateIndex:index,closeGateIndex:index+6n,
     openGateDay:g,closeGateDay:g+1000n},
    {openGateIndex:index-1n,closeGateIndex:index+6n,
     openGateDay:g-100n,closeGateDay:g+900n}
  ]
 };
}
const oracle=new NormativeOracle(),owners=new Set<object>();
let trueCases=0,pos=0,neg=0,realGuessWrong=0,realRankWrong=0;
let genuineCalls=0,genuineWrites=0,knownWrong=0;
for(const side of [1n,-1n] as const){
 for(let n=1n;n<=6n;n++){
  const f=nominal(side*n,oracle);
  const rank=chooseRank(askBowl(sauce(f.c,f.c),1,10n),2n);
  const open=rank===1n?f.g-100n:f.g;
  const chosenLast=open+1000n,chosenFirst=open+1n;
  for(const where of ["inside","before"] as const){
   const target=where==="inside"?chosenLast:chosenFirst-366n;
   const out=discoverLegacyJumpGuess(f.c,target,f.index,f.historical,
    f.signed,f.year,f.anchor,f.candidates);
   const expected=where==="inside"?5002n:4998n;
   if(out.ghostYearNumber!==expected)realGuessWrong++;
   if(out.preceding.correctedRank!==rank)realRankWrong++;
   if(out.guess.knownAnchorMismatch===true)knownWrong++;
   check(out.selectedAnchor.firstDay===chosenFirst&&
     out.selectedAnchor.lastDay===chosenLast&&
     out.ghostYearNumber===expected&&
     out.guess.estimatedYearNumber===expected&&
     out.guess.role==="TELEMETRY_ONLY"&&
     out.authoritativeTargetYearResolved===false&&
     out.preceding.correctedSelected.candidate.openGateDay===open&&
     out.preceding.correctedSelected.candidate.closeGateDay===chosenLast&&
     out.preceding.correctedRank===rank&&
     out.preceding.correctedYearSelection.correctedRank===rank&&
     out.preceding.correctedYearSelection.predecessorSharedWrites===58&&
     out.preceding.preceding.yearSelection.correctedRank===rank&&
     out.preceding.preceding.preceding.yearSelection.correctedRank===1n&&
     out.preceding.predecessorCallCount===out.predecessorCallCount&&
     out.predecessorSharedWrites===BigInt(out.predecessorCallCount)*58n&&
     out.context.status==="DISCOVERY_18_RECORDED"&&
     !owners.has(out.context)&&out.context!==out.preceding.context,
     "24 signed-gate authentic predecessor histories leave Year5000 selection unaffected");
   owners.add(out.context);trueCases++;
   genuineCalls+=out.predecessorCallCount;
   genuineWrites+=Number(out.predecessorSharedWrites);
  }
  if(side>0n)pos++;else neg++;
 }
}
check(trueCases===24&&pos===6&&neg===6&&
 owners.size===24&&realGuessWrong===0&&realRankWrong===0&&
 knownWrong===12&&genuineCalls===198&&genuineWrites===11484,
 "all ±1..±6 authentic gate Sauce histories unaffected by ghost guess");

// Explicitly noncanonical injected vectors check full Sauce ownership and
// every DROP46 ordering. No synthetic candidate is claimed to be real year5000.
const ix=1n,f=nominal(ix,oracle),baseline=f.year;
const variantsOwners=new Set<object>(),seen=new Set<string>();
let varied=0,giants=0,ranks=0,variants=0,variantCalls=0,variantWrites=0;
let streamWrong=0,rankWrong=0,guessWrong=0,selectionChanged=0;
function verifyInjected(visible:readonly bigint[],bowls:readonly bigint[],kind:"varied"|"giant"|"rank"){
 const before=[...bowls];
 const initialTarget=f.g+900n;
 const out=discoverLegacyJumpGuess(f.c,initialTarget,ix,
  f.historical,f.signed,{visible,stones:STONES,startBowls:bowls},
  f.anchor,f.candidates);
 const after=applyVisibleDropsToBowls(
   [...bowls] as [bigint,bigint,bigint,bigint,bigint,bigint],visible,STONES);
 const final=postStir12(
   [...after.bowls] as [bigint,bigint,bigint,bigint,bigint,bigint]);
 const order=bowlOrderFromDrop(visible[46]!);
 const stream=askBowl({bowls:final,orderAtDrop46:order},1,10n);
 const expectedRank=chooseRank(stream,2n);
 const expectedOpen=expectedRank===1n?f.g-100n:f.g;
 const expectedGhost=5000n+
  (initialTarget-(expectedOpen+1n))/365n;
 if(out.preceding.correctedYearSelection.preceding.firstAnswer!==stream.first||
    out.preceding.correctedYearSelection.preceding.directionStep!==stream.directionStep)
   streamWrong++;
 if(out.preceding.correctedRank!==expectedRank)rankWrong++;
 if(out.ghostYearNumber!==expectedGhost)guessWrong++;
 if(out.preceding.correctedSelected.candidate.openGateDay!==expectedOpen)
   selectionChanged++;
 check(out.preceding.correctedYearSelection.preceding.preceding.preceding.preceding.finalBowls.every((x,j)=>x===final[j])&&
  out.preceding.correctedYearSelection.preceding.preceding.preceding.preceding.afterDropBowls.every((x,j)=>x===after.bowls[j])&&
  out.preceding.correctedYearSelection.preceding.preceding.preceding.preceding.orderAt46Latch.join(",")===order.join(",")&&
  out.preceding.correctedYearSelection.preceding.preceding.preceding.preceding.sharedMemoryWrites===58&&
  out.preceding.correctedYearSelection.preceding.preceding.preceding.preceding.preceding.historical.latestSource==="STIR_12"&&
  out.preceding.correctedRank===expectedRank&&
  out.preceding.correctedSelected.candidate.openGateDay===expectedOpen&&
  out.ghostYearNumber===expectedGhost&&
  out.guess.authoritativeTraversalPerformed===false&&
  out.authoritativeTargetYearResolved===false&&
  out.predecessorCallCount===4&&out.predecessorSharedWrites===232n&&
  !variantsOwners.has(out.context)&&
  bowls.every((v,j)=>v===before[j]),
  "test-only independent rank and full 58-write path, telemetry not on selection");
 variantsOwners.add(out.context);variants++;variantCalls+=4;variantWrites+=232;
 if(kind==="rank")seen.add(out.preceding.correctedYearSelection.preceding.preceding.preceding.preceding.orderAt46Latch.join(","));
}
for(let j=0;j<64;j++){
 const v=[...baseline.visible];v[1]=j%2===0?BigInt(j*149+1):-BigInt(j*137+3);
 v[46]=j%3===0?BigInt(j*721+2):-BigInt(j*719+11);
 verifyInjected(v,baseline.startBowls,"varied");varied++;
}
for(const d of [huge,-huge,huge*huge,-huge*huge,0n,720n,
 1n<<16384n,-(1n<<16384n)]){
 const v=[...baseline.visible];v[1]=d;v[46]=-d+1n;
 const b=[huge+11n,-huge-13n,huge+17n,-huge-23n,huge+37n,-huge-41n];
 verifyInjected(v,b,"giant");giants++;
}
for(let k=1n;k<=720n;k++){
 const v=[...baseline.visible];v[46]=k;
 verifyInjected(v,baseline.startBowls,"rank");ranks++;
}
check(varied===64&&giants===8&&ranks===720&&variants===792&&
 variantsOwners.size===792&&seen.size===720&&variantCalls===3168&&
 variantWrites===183744&&streamWrong===0&&rankWrong===0&&
 guessWrong===0&&selectionChanged===0,
 "792 true 58-write Sauce chains plus independently tested 365 telemetry");
console.log("STAGE_36_DISCOVERY_18_PROPERTIES_PASS floorGrid="+grid+
 " floorWrong="+gridWrong+" wrongWithinCells="+insideFalse+
 " negativeFloors="+negativeFloors+" giantDeltas="+big+
 " genuineSeedPair=1 normativeNext=1 normativePrevious=1 forwardOldWrong=1 backwardOldWrong=1"+
 " realAnchors="+trueCases+" positive="+pos+" negative="+neg+
 " realGhostWrong="+realGuessWrong+" realRankWrong="+realRankWrong+
 " realKnownMismatches="+knownWrong+" realPredecessors="+genuineCalls+
 " realWrites="+genuineWrites+" varied="+varied+" giants="+giants+
 " ranks="+ranks+" unique="+seen.size+" variants="+variants+
 " variantPredecessors="+variantCalls+" variantWrites="+variantWrites+
 " totalPredecessors="+(genuineCalls+variantCalls)+
 " totalWrites="+(genuineWrites+variantWrites)+
 " streamWrong="+streamWrong+" rankWrong="+rankWrong+
 " ghostWrong="+guessWrong+" selectionChanged="+selectionChanged);
