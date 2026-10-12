import {
  LegacyYearMaxEligibilityAdapter,LegacyYearMaxCandidateFilter,
  discoverLegacyYearMax
} from "../src/index.ts";
import {
  FOUNDATION_DAY as F,STONES,NormativeOracle,workCounts,
  buildHiddenDrops,buildVisibleDrops,initialBowls,sauce,askBowl,chooseRank,
  applyVisibleDropsToBowls,postStir12,bowlOrderFromDrop
} from "./normativeOracle.ts";
function check(v:boolean,msg:string):void{if(!v)throw Error(msg);}
function source(c:bigint,t:bigint){
 const w=workCounts(c,t);
 return {visible:buildVisibleDrops(w,STONES,buildHiddenDrops(w,STONES)),
   stones:STONES,startBowls:initialBowls(w)};
}
function candidate(g:bigint,index:bigint,values:readonly bigint[]){
 return values.map((x,i)=>({openGateIndex:index,closeGateIndex:index+BigInt(i+6),
   openGateDay:g,closeGateDay:g+x}));
}
const old=new LegacyYearMaxEligibilityAdapter(),legacy=new LegacyYearMaxCandidateFilter();
let direct=0,wrongAccepted=0,correctAccepted=0,directMismatch=0;
for(let L=5750n;L<=5800n;L++)
 for(let gaps=5n;gaps<=9n;gaps++){
  const actual=old.oldEligibleYear(L,gaps);
  const expected=(L>=252n&&L<=5778n&&gaps>=6n);
  if(actual!==expected)directMismatch++;
  if(actual&&L>5778n)wrongAccepted++;
  if(actual&&L<=5778n)correctAccepted++;
  check(actual===(L>=252n&&L<=5781n&&gaps>=6n),
    "exact legacy 5781 range not patched ahead of Stage33");
  direct++;
 }
for(const giant of [1n<<8192n,1n<<16384n]){
 check(!old.oldEligibleYear(giant,6n)&&!old.oldEligibleYear(giant,giant),
  "unbounded bigint comparison not truncated");
}
check(direct===255&&wrongAccepted===12&&correctAccepted>0&&
 directMismatch===12,"all 5779..5781 × four gap counts incorrectly accepted");
let real=0,positive=0,negative=0,anchorWrong=0,rankWrong=0;
let realLegacy=0,realExtraSigned=0,realSelector=0,realCalls=0,realWrites=0;
const oracle=new NormativeOracle(),contexts=new Set<object>();
for(const side of [1n,-1n] as const){
 for(let n=1n;n<=6n;n++){
  const idx=side*n,g=oracle.gateDay(idx),c=g+1n;
  const historical=Array.from({length:Number(n)},(_,i)=>source(F,F+BigInt(i+1)));
  const signed=Array.from({length:Number(n)},(_,i)=>({
    ...source(F,F+side*BigInt(i+1)),targetDay:F+side*BigInt(i+1)
  }));
  const years=source(c,c),values=[252n,5778n,5779n,5780n,5781n,5782n];
  const out=discoverLegacyYearMax(c,idx,historical,signed,years,candidate(g,idx,values));
  const expectedRank=chooseRank(askBowl(sauce(c,c),1,10n),5n);
  if(out.anchorGateDay!==g)anchorWrong++;
  if(out.selectedRank!==expectedRank)rankWrong++;
  check(out.preceding.correctedGateDay===g&&
    out.preceding.historicalMismatch===(side<0n)&&
    out.filter.kept.map(v=>v.length).join(",")==="252,5778,5779,5780,5781"&&
    out.filter.rejected.map(v=>v.length).join(",")==="5782"&&
    out.filter.acceptedLongLengths.join(",")==="5779,5780,5781"&&
    out.yearSelection.correctedRank===expectedRank&&
    out.selected===out.filter.kept[Number(expectedRank-1n)]&&
    out.preceding.totalPredecessorCalls===Number(n)*(side<0n?2:1)&&
    out.predecessorCallCount===out.preceding.totalPredecessorCalls+1&&
    out.predecessorSharedWrites===BigInt(out.predecessorCallCount)*58n&&
    out.yearSelection.preceding.preceding.preceding.preceding.latchCaptures===1&&
    !contexts.has(out.context)&&out.context.status==="DISCOVERY_16_RECORDED",
    "12 real signed gate anchors, true year select and 3 legacy forbidden lengths");
  contexts.add(out.context);
  realLegacy+=Number(n);realExtraSigned+=side<0n?Number(n):0;
  realSelector++;
  realCalls+=out.predecessorCallCount;realWrites+=out.predecessorCallCount*58;
  if(side<0n)negative++;else positive++;
  real++;
 }
}
check(real===12&&positive===6&&negative===6&&
 anchorWrong===0&&rankWrong===0&&contexts.size===12&&
 realLegacy===42&&realExtraSigned===21&&realSelector===12&&
 realCalls===75&&realWrites===4350,"75 physically invoked full predecessors");

// Noncanonical year-question vectors (clearly injected), used only to
// stress the previous 58-write true history and selection on the 5781 family.
const anchorIndex=1n,anchor=oracle.gateDay(anchorIndex),day=anchor+1n;
const historic=[source(F,F+1n)],signed=[{...source(F,F+1n),targetDay:F+1n}];
const base=source(day,day);
const checked=new Set<string>(),owners=new Set<object>();
let variants=0,varied=0,giant=0,ranks=0,varCalls=0,varWrites=0;
let streamWrong=0,rankMismatch=0,selectedWrong=0;
function verifyInjected(v:readonly bigint[],bowls:readonly bigint[],kind:"varied"|"giant"|"rank"){
 const snap=[...bowls];
 const result=discoverLegacyYearMax(day,anchorIndex,historic,signed,
  {visible:v,stones:STONES,startBowls:bowls},
  candidate(anchor,anchorIndex,[5779n,5780n,5781n]));
 const after=applyVisibleDropsToBowls(
  [...bowls] as [bigint,bigint,bigint,bigint,bigint,bigint],v,STONES);
 const final=postStir12(
  [...after.bowls] as [bigint,bigint,bigint,bigint,bigint,bigint]);
 const order=bowlOrderFromDrop(v[46]!);
 const stream=askBowl({bowls:final,orderAtDrop46:order},1,10n);
 const rank=chooseRank(stream,3n);
 if(result.yearSelection.preceding.firstAnswer!==stream.first||
    result.yearSelection.preceding.directionStep!==stream.directionStep)streamWrong++;
 if(result.yearSelection.correctedRank!==rank)rankMismatch++;
 if(result.selected.length!==[5779n,5780n,5781n][Number(rank-1n)])selectedWrong++;
 check(result.yearSelection.preceding.preceding.preceding.preceding.finalBowls.every((b,j)=>b===final[j])&&
   result.yearSelection.preceding.preceding.preceding.preceding.afterDropBowls.every((b,j)=>b===after.bowls[j])&&
   result.yearSelection.preceding.preceding.preceding.preceding.orderAt46Latch.join(",")===order.join(",")&&
   result.yearSelection.preceding.preceding.preceding.preceding.sharedMemoryWrites===58&&
   result.yearSelection.preceding.preceding.preceding.preceding.preceding.historical.latestSource==="STIR_12"&&
   result.filter.kept.length===3&&result.filter.acceptedLongLengths.length===3&&
   result.selectedRank===rank&&result.selected.length>=5779n&&
   result.selected.length<=5781n&&
   result.predecessorCallCount===2&&result.predecessorSharedWrites===116n&&
   !owners.has(result.context)&&Object.isFrozen(result)&&
   bowls.every((b,j)=>b===snap[j]),"injected previous producer values and old 5781 candidates");
 owners.add(result.context);variants++;varCalls+=2;varWrites+=116;
 if(kind==="rank")checked.add(result.yearSelection.preceding.preceding.preceding.preceding.orderAt46Latch.join(","));
}
for(let i=0;i<64;i++){
 const v=[...base.visible];
 v[1]=i%2===0?BigInt(i*149+1):-BigInt(i*137+3);
 v[46]=i%3===0?BigInt(i*721+2):-BigInt(i*719+11);
 verifyInjected(v,base.startBowls,"varied");varied++;
}
const huge=(1n<<8192n)+193n;
for(const d of [huge,-huge,huge*huge,-huge*huge,0n,720n,1n<<16384n,-(1n<<16384n)]){
 const v=[...base.visible];v[1]=d;v[46]=-d+1n;
 const b=[huge+11n,-huge-13n,huge+17n,-huge-23n,huge+37n,-huge-41n];
 verifyInjected(v,b,"giant");giant++;
}
for(let rank=1n;rank<=720n;rank++){
 const v=[...base.visible];v[46]=rank;
 verifyInjected(v,base.startBowls,"rank");ranks++;
}
check(varied===64&&giant===8&&ranks===720&&variants===792&&
 owners.size===792&&checked.size===720&&varCalls===1584&&
 varWrites===91872&&streamWrong===0&&rankMismatch===0&&selectedWrong===0,
 "792 injected selection histories, 720 unique latch orders, 921? corrected");
console.log("STAGE_32_DISCOVERY_16_PROPERTIES_PASS direct="+direct+
 " wrongAccepted="+wrongAccepted+" directMismatch="+directMismatch+
 " realGates="+real+" positive="+positive+" negative="+negative+
 " anchorWrong="+anchorWrong+" rankWrong="+rankWrong+
 " legacyCalls="+realLegacy+" extraSigned="+realExtraSigned+
 " realSelectors="+realSelector+" realCalls="+realCalls+
 " realWrites="+realWrites+" varied="+varied+" giant="+giant+
 " ranks="+ranks+" unique="+checked.size+" variants="+variants+
 " variantCalls="+varCalls+" variantWrites="+varWrites+
 " totalCalls="+(realCalls+varCalls)+" totalWrites="+(realWrites+varWrites)+
 " streamWrong="+streamWrong+" rankMismatch="+rankMismatch+
 " selectedWrong="+selectedWrong);
