import {
  REAL_YEAR_MAX_PATCH,LEGACY_YEAR_MAX,
  Patch16YearLengthGuard,patch16YearMax,
  LegacyYearMaxEligibilityAdapter
} from "../src/index.ts";
import {
  FOUNDATION_DAY as F,YEAR_MAX_DAYS,YEAR_MIN_DAYS,
  STONES,NormativeOracle,workCounts,buildHiddenDrops,buildVisibleDrops,
  initialBowls,sauce,askBowl,chooseRank,
  applyVisibleDropsToBowls,postStir12,bowlOrderFromDrop
} from "./normativeOracle.ts";
function check(b:boolean,m:string):void{if(!b)throw Error(m);}
function source(c:bigint,t:bigint){
 const w=workCounts(c,t);
 return {visible:buildVisibleDrops(w,STONES,buildHiddenDrops(w,STONES)),
  stones:STONES,startBowls:initialBowls(w)};
}
function candidate(g:bigint,index:bigint,lengths:readonly bigint[]){
 return lengths.map((L,i)=>({openGateIndex:index,closeGateIndex:index+BigInt(i+6),
  openGateDay:g,closeGateDay:g+L}));
}
const patch=new Patch16YearLengthGuard(),old=new LegacyYearMaxEligibilityAdapter();
check(REAL_YEAR_MAX_PATCH===YEAR_MAX_DAYS&&YEAR_MIN_DAYS===252n&&
 LEGACY_YEAR_MAX===5781n,"normative maximum is 5778 and old remains 5781");
let direct=0,directOldAccepted=0,directNewAccepted=0,
  falseAccepts=0,directWrong=0;
for(let L=5750n;L<=5800n;L++){
 for(let gaps=5n;gaps<=9n;gaps++){
  const x={openGateIndex:1n,closeGateIndex:1n+gaps,
   openGateDay:F,closeGateDay:F+L};
  const result=patch.apply([x]);
  const canonical=gaps>=6n&&L>=YEAR_MIN_DAYS&&L<=YEAR_MAX_DAYS;
  const historical=old.oldEligibleYear(L,gaps);
  const actual=result.correctedFamilySize===1;
  if(actual!==canonical)directWrong++;
  if(historical)directOldAccepted++;
  if(actual)directNewAccepted++;
  if(historical&&!canonical)falseAccepts++;
  check(actual===canonical&&
   result.historicalFamilySize===(historical?1:0)&&
   result.oldPredicateCalls===1&&
   result.excludedLong.length===(historical&&!canonical?1:0)&&
   result.correctedSortCalls===1&&result.historicalSortCalls===1,
   "precise 51×5 matrix of old-versus-corrected filter");
  direct++;
 }
}
check(direct===255&&falseAccepts===12&&directWrong===0&&
 directOldAccepted-directNewAccepted===12,
 "12 false accepts are exactly 5779,5780,5781 at four gate separations");
let giantCases=0;
const extremes=[1n<<8192n,1n<<16384n,
 (1n<<16384n)+5778n,(1n<<32768n)+1n];
for(const L of extremes){
 for(const gaps of [6n,7n,L]){
  const res=patch.apply([{openGateIndex:1n,closeGateIndex:1n+gaps,
   openGateDay:F,closeGateDay:F+L}]);
  check(res.correctedFamilySize===0&&
   res.historicalFamilySize===0&&res.excludedLong.length===0,
   "unbounded huge candidate length never overflows into selected year");
  giantCases++;
 }
}
const o=new NormativeOracle(),owners=new Set<object>();
let real=0,positive=0,negative=0,anchorWrong=0,selectedWrong=0;
let filteredLong=0,oldKept=0,newKept=0,legacyGapCalls=0;
let signedExtra=0,selectors=0,predecessors=0,sharedWrites=0;
for(const side of [1n,-1n] as const){
 for(let n=1n;n<=6n;n++){
  const idx=side*n,g=o.gateDay(idx),c=g+1n;
  const historical=Array.from({length:Number(n)},(_,i)=>source(F,F+BigInt(i+1)));
  const signed=Array.from({length:Number(n)},(_,i)=>({
   ...source(F,F+side*BigInt(i+1)),targetDay:F+side*BigInt(i+1)
  }));
  const year=source(c,c);
  const list=candidate(g,idx,[252n,5778n,5779n,5780n,5781n,5782n]);
  const result=patch16YearMax(c,idx,historical,signed,year,list);
  const expectedRank=chooseRank(askBowl(sauce(c,c),1,10n),2n);
  if(result.anchorGateDay!==g)anchorWrong++;
  if(result.selectedRank!==expectedRank)selectedWrong++;
  check(result.preceding.correctedGateDay===g&&
   result.preceding.historicalMismatch===(side<0n)&&
   result.filter.historical.kept.map(e=>e.length).join(",")==="252,5778,5779,5780,5781"&&
   result.filter.historical.rejected.map(e=>e.length).join(",")==="5782"&&
   result.filter.corrected.map(e=>e.length).join(",")==="252,5778"&&
   result.filter.excludedLong.map(e=>e.length).join(",")==="5779,5780,5781"&&
   result.filter.oldPredicateCalls===6&&
   result.yearSelection.correctedRank===expectedRank&&
   result.yearSelection.familySize===2n&&
   result.selected===result.filter.corrected[Number(expectedRank-1n)]&&
   result.selected.length>=YEAR_MIN_DAYS&&result.selected.length<=YEAR_MAX_DAYS&&
   result.preceding.totalPredecessorCalls===Number(n)*(side<0n?2:1)&&
   result.predecessorCallCount===result.preceding.totalPredecessorCalls+1&&
   result.predecessorSharedWrites===BigInt(result.predecessorCallCount)*58n&&
   result.yearSelection.preceding.preceding.preceding.preceding.latchCaptures===1&&
   result.yearSelection.preceding.preceding.preceding.legacyModuloCalls===1&&
   result.filter.historical.kept.every(e=>Object.isFrozen(e))&&
   result.context.status==="PATCH_16_APPLIED"&&
   !owners.has(result.context)&&Object.isFrozen(result.filter)&&
   Object.isFrozen(result.selected),
   "real signed gate predecessor, old scar and only two canonical year candidates");
  owners.add(result.context);real++;
  oldKept+=result.filter.historicalFamilySize;
  newKept+=result.filter.correctedFamilySize;
  filteredLong+=result.filter.excludedLong.length;
  legacyGapCalls+=Number(n);
  signedExtra+=side<0n?Number(n):0;
  selectors++;
  predecessors+=result.predecessorCallCount;
  sharedWrites+=result.predecessorCallCount*58;
  if(side===1n)positive++;else negative++;
 }
}
check(real===12&&positive===6&&negative===6&&
 anchorWrong===0&&selectedWrong===0&&owners.size===12&&
 oldKept===60&&newKept===24&&filteredLong===36&&
 legacyGapCalls===42&&signedExtra===21&&selectors===12&&
 predecessors===75&&sharedWrites===4350,
 "12 real gate anchors and 75 genuine predecessor computations");

// Explicitly injected noncanonical DROP46/year-selector vectors; preserve
// provenance of synthetic candidate close gates. The genuine signed anchor,
// both original old-filter calls and 58-write Sauce are still physically run.
const index=1n,anchor=o.gateDay(index),day=anchor+1n;
const historical=[source(F,F+1n)],signed=[{...source(F,F+1n),targetDay:F+1n}];
const baseline=source(day,day);
const seen=new Set<string>(),variantContexts=new Set<object>();
let varied=0,giants=0,ranks=0,variantCases=0;
let variantPredecessors=0,variantWrites=0;
let streamWrong=0,rankWrong=0,selectedWrongVariant=0,filteredWrong=0;
function verifyInjected(v:readonly bigint[],bowls:readonly bigint[],kind:"varied"|"giant"|"rank"){
 const before=[...bowls];
 const result=patch16YearMax(day,index,historical,signed,
  {visible:v,stones:STONES,startBowls:bowls},
  candidate(anchor,index,[252n,5778n,5779n,5780n,5781n]));
 const applied=applyVisibleDropsToBowls(
   [...bowls] as [bigint,bigint,bigint,bigint,bigint,bigint],v,STONES);
 const final=postStir12(
   [...applied.bowls] as [bigint,bigint,bigint,bigint,bigint,bigint]);
 const order=bowlOrderFromDrop(v[46]!);
 const stream=askBowl({bowls:final,orderAtDrop46:order},1,10n);
 const expected=chooseRank(stream,2n);
 if(result.yearSelection.preceding.firstAnswer!==stream.first||
    result.yearSelection.preceding.directionStep!==stream.directionStep)streamWrong++;
 if(result.selectedRank!==expected)rankWrong++;
 if(result.selected.length!==[252n,5778n][Number(expected-1n)])selectedWrongVariant++;
 if(result.filter.correctedFamilySize!==2||result.filter.excludedLong.length!==3)filteredWrong++;
 check(result.yearSelection.preceding.preceding.preceding.preceding.finalBowls.every((b,j)=>b===final[j])&&
  result.yearSelection.preceding.preceding.preceding.preceding.afterDropBowls.every((b,j)=>b===applied.bowls[j])&&
  result.yearSelection.preceding.preceding.preceding.preceding.orderAt46Latch.join(",")===order.join(",")&&
  result.yearSelection.preceding.preceding.preceding.preceding.sharedMemoryWrites===58&&
  result.yearSelection.preceding.preceding.preceding.preceding.preceding.historical.latestSource==="STIR_12"&&
  result.selectedRank===expected&&result.selected.length<=5778n&&
  result.filter.historical.kept.length===5&&
  result.filter.correctedFamilySize===2&&
  result.yearSelection.familySize===2n&&
  result.predecessorCallCount===2&&result.predecessorSharedWrites===116n&&
  !variantContexts.has(result.context)&&
  bowls.every((b,j)=>b===before[j]),"complete genuine producer with synthetic variant and corrected eligible family");
 variantContexts.add(result.context);variantCases++;
 variantPredecessors+=2;variantWrites+=116;
 if(kind==="rank")seen.add(result.yearSelection.preceding.preceding.preceding.preceding.orderAt46Latch.join(","));
}
for(let j=0;j<64;j++){
 const v=[...baseline.visible];
 v[1]=j%2===0?BigInt(j*149+1):-BigInt(j*137+3);
 v[46]=j%3===0?BigInt(j*721+2):-BigInt(j*719+11);
 verifyInjected(v,baseline.startBowls,"varied");varied++;
}
const huge=(1n<<8192n)+193n;
for(const d of [huge,-huge,huge*huge,-huge*huge,0n,720n,
 1n<<16384n,-(1n<<16384n)]){
 const v=[...baseline.visible];v[1]=d;v[46]=-d+1n;
 const b=[huge+11n,-huge-13n,huge+17n,-huge-23n,huge+37n,-huge-41n];
 verifyInjected(v,b,"giant");giants++;
}
for(let rank=1n;rank<=720n;rank++){
 const v=[...baseline.visible];v[46]=rank;
 verifyInjected(v,baseline.startBowls,"rank");ranks++;
}
check(varied===64&&giants===8&&ranks===720&&variantCases===792&&
 variantContexts.size===792&&seen.size===720&&
 variantPredecessors===1584&&variantWrites===91872&&
 streamWrong===0&&rankWrong===0&&selectedWrongVariant===0&&filteredWrong===0,
 "792 variants, unique order46 permutations, zero corrected selection differences");
console.log("STAGE_33_PATCH_16_PROPERTIES_PASS direct="+direct+
 " oldDirectAccepted="+directOldAccepted+" newDirectAccepted="+directNewAccepted+
 " falseAccepts="+falseAccepts+" directWrong="+directWrong+
 " hugeCases="+giantCases+" realGates="+real+" positive="+positive+
 " negative="+negative+" anchorWrong="+anchorWrong+" rankWrong="+selectedWrong+
 " oldKept="+oldKept+" correctedKept="+newKept+" removedLong="+filteredLong+
 " originalGateCalls="+legacyGapCalls+" extraSigned="+signedExtra+
 " realSelectors="+selectors+" realCalls="+predecessors+" realWrites="+sharedWrites+
 " varied="+varied+" giants="+giants+" ranks="+ranks+" unique="+seen.size+
 " variants="+variantCases+" variantCalls="+variantPredecessors+
 " variantWrites="+variantWrites+" totalCalls="+(predecessors+variantPredecessors)+
 " totalWrites="+(sharedWrites+variantWrites)+
 " streamWrong="+streamWrong+" variantRankWrong="+rankWrong+
 " variantSelectedWrong="+selectedWrongVariant+" filterWrong="+filteredWrong);
