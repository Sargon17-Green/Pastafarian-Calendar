import { LegacyBiasedModuloRankAdapter,discoverLegacyBiasedModulo } from "../src/index.ts";
import {
 FOUNDATION_DAY as F,M,STONES,workCounts,buildHiddenDrops,buildVisibleDrops,
 initialBowls,applyVisibleDropsToBowls,postStir12,bowlOrderFromDrop,
 askBowl,chooseRank,answerAt
} from "./normativeOracle.ts";
function check(ok:boolean,why:string):void{if(!ok)throw Error(why);}
const old=new LegacyBiasedModuloRankAdapter();
let analyticalSizes=0,biasedFamilies=0,topRejections=0,acceptedNearBoundary=0;
let directMismatches=0,directMatches=0,directCases=0,wideCases=0,wideWrong=0;
for(let n=1n;n<=256n;n++){
 const q=M/n,r=M%n;
 check(q*n+r===M&&r>=0n&&r<n,
  "exact count decomposition for first answer uniform over 1..M");
 if(r>0n)biasedFamilies++;analyticalSizes++;
 const a=old.oldChooseModulo(M,n);
 const canonical=chooseRank({first:M,directionStep:-1n},n);
 if(r>0n){
  check(M>q*n&&canonical!==a&&canonical===1n+((q*n-1n)%n),
    "top rejected answer: canonical follows stream, not modulo");
  topRejections++;
 }else check(canonical===a,"dividing family needs no rejection");
}
const sizes=[2n,3n,5n,7n,11n,922n,M-1n,M,M+1n,M+2n,M*M+1n,M*M*M+1n];
for(const n of sizes){
 for(let j=0n;j<=40n;j++){
  const x=M-j;
  for(const directionStep of [-1n,1n] as const){
   // For small n, close to M at most 922 iterations before an accepted value.
   // For wide n, space >=M² and the test-only oracle takes the wide path.
   // Large wide N with upward steps near M can create an astronomical
   // acceptance walk. Use a lower-bound upward stream; keep near-M downward
   // and both directions for short and near-M wide (M+1, M+2) cases.
   const first=n>M+2n&&directionStep===1n ? 1n+j : x;
   const stream={first,directionStep};
   const want=chooseRank(stream,n);
   const got=old.oldChooseModulo(first,n);
   if(want===got)directMatches++;else directMismatches++;
   if(n>M){wideCases++;if(want!==got)wideWrong++;}
   directCases++;
  }
 }
}
const n=M/2n+1n,limit=(M/n)*n;
for(let j=1n;j<=3n;j++){
 const first=limit+j;
 const stream={first,directionStep:-1n as const};
 const want=chooseRank(stream,n);
 check(first>limit&&want===1n+(limit-1n)%n&&
    old.oldChooseModulo(first,n)!==want,
   "half-range synthetic counterexample with bounded rejection walk");
 acceptedNearBoundary++;
}
check(analyticalSizes===256&&biasedFamilies>0&&topRejections>0&&
 directCases===sizes.length*41*2&&directMismatches>0&&directMatches>0&&
 wideCases>0&&wideWrong>0&&acceptedNearBoundary===3,
 "analytical exact bias, finite short and wide direct case grid");

const pairs:readonly (readonly [bigint,bigint])[]=[
 [F,F],[F-1n,F],[F+1n,F],[F,F-1n],[F,F+1n],
 [F-89n,F+273n],[F+273n,F-89n],[-278522n,-278522n],
 [-278522n,-268522n],[1n,1n],[100000n,-100000n],[-100000n,100000n]
];
let real=0,varied=0,giant=0,ranks=0,histories=0,sharedWrites=0;
let fullWrong=0,fullSame=0,canonicalStreamWrong=0;
const contexts=new Set<object>(),distinctRanks=new Set<string>();
const familySizes=[1n,2n,3n,5n,7n,922n,M,M+1n,M*M+1n];
function verify(c:bigint,t:bigint,visible:readonly bigint[],start:readonly bigint[],
 id:number,seal:bigint,size:bigint,family:"real"|"varied"|"giant"|"rank"):void {
 const firstInput=[...start];
 const out=discoverLegacyBiasedModulo(c,t,visible,STONES,start,id,seal,size);
 const oracle=applyVisibleDropsToBowls(
  [...start] as [bigint,bigint,bigint,bigint,bigint,bigint],visible,STONES);
 const bowls=postStir12(
  [...oracle.bowls] as [bigint,bigint,bigint,bigint,bigint,bigint]);
 const independentOrder=bowlOrderFromDrop(visible[46]!);
 const stream=askBowl({bowls,orderAtDrop46:independentOrder},id,seal);
 const trueRank=chooseRank(stream,size);
 if(out.biasedRank===trueRank)fullSame++;else fullWrong++;
 if(out.firstAnswer!==stream.first||out.directionStep!==stream.directionStep)
  canonicalStreamWrong++;
 check(out.preceding.orderAt46Latch.join(",")===independentOrder.join(",")&&
  out.preceding.correctedNextBowlId===independentOrder[
   (independentOrder.indexOf(id)+1)%6]&&
  out.preceding.finalBowls.every((v,j)=>v===bowls[j])&&
  out.preceding.afterDropBowls.every((v,j)=>v===oracle.bowls[j])&&
  out.preceding.preceding.sharedMemoryWrites===58&&
  out.preceding.preceding.historical.memoryWrites===58&&
  out.preceding.preceding.historical.latestSource==="STIR_12"&&
  out.preceding.preceding.ledger[45]!.source==="DROP_46"&&
  out.preceding.preceding.ledger[57]!.source==="STIR_12"&&
  out.biasedRank===old.oldChooseModulo(stream.first,size)&&
  out.answerStream.directionStep===stream.directionStep&&
  out.context.status==="DISCOVERY_13_RECORDED"&&
  out.context.metrics.get("discovery13.actual_legacy_modulo_calls")===1n&&
  out.legacyModuloCalls===1&&out.predecessorSharedMemoryWrites===58&&
  out.context!==out.preceding.context&&
  !contexts.has(out.context)&&start.every((v,j)=>v===firstInput[j])&&
  Object.isFrozen(out)&&Object.isFrozen(out.answerStream),
  "canonical bowl route and question stream, old biased rank selection");
 contexts.add(out.context);histories++;sharedWrites+=58;
 if(family==="rank")distinctRanks.add(out.preceding.orderAt46Latch.join(","));
}
for(const [c,t] of pairs){
 const counts=workCounts(c,t),hidden=buildHiddenDrops(counts,STONES);
 const visible=buildVisibleDrops(counts,STONES,hidden),start=initialBowls(counts);
 verify(c,t,visible,start,(real%6)+1,BigInt(1+real%33),
   familySizes[real%familySizes.length]!,"real");real++;
}
const counts=workCounts(F,F),hidden=buildHiddenDrops(counts,STONES);
const baseline=buildVisibleDrops(counts,STONES,hidden),start=initialBowls(counts);
for(let j=0;j<64;j++){
 const changed=[...baseline];
 changed[1]=j%2===0?BigInt(j*149+1):-BigInt(j*137+3);
 changed[46]=j%3===0?BigInt(j*721+2):-BigInt(j*719+11);
 verify(F+BigInt(j),F-BigInt(j),changed,start,(j%6)+1,BigInt(1+j%33),
  familySizes[j%familySizes.length]!,"varied");varied++;
}
const huge=(1n<<8192n)+193n;
for(const d of [huge,-huge,huge*huge,-huge*huge,0n,720n,
 1n<<16384n,-(1n<<16384n)]){
 const changed=[...baseline];changed[1]=d;changed[46]=-d+1n;
 const b=[huge+11n,-huge-13n,huge+17n,-huge-23n,huge+37n,-huge-41n];
 verify(F-huge,F+huge,changed,b,(giant%6)+1,BigInt(1+giant),
 familySizes[giant%familySizes.length]!,"giant");giant++;
}
for(let rank=1n;rank<=720n;rank++){
 const changed=[...baseline];changed[46]=rank;
 verify(F,F,changed,start,(Number(rank)%6)+1,BigInt(Number(rank)%33+1),
  familySizes[Number(rank)%familySizes.length]!,"rank");ranks++;
}
check(real===12&&varied===64&&giant===8&&ranks===720&&histories===804&&
 sharedWrites===46632&&contexts.size===804&&distinctRanks.size===720&&
 canonicalStreamWrong===0&&fullWrong>0&&fullSame>0&&fullWrong+fullSame===histories,
 "804 authentic Stage25 precursor histories, 0 stream errors, historic bias survives");
console.log("STAGE_26_DISCOVERY_13_PROPERTIES_PASS analyticalSizes="+analyticalSizes+
 " biasedFamilies="+biasedFamilies+" topRejections="+topRejections+
 " directCases="+directCases+" directWrong="+directMismatches+
 " directMatches="+directMatches+" wideCases="+wideCases+
 " wideWrong="+wideWrong+" thresholdWitnesses="+acceptedNearBoundary+
 " realPairs="+real+" varied="+varied+" giant="+giant+" ranks="+ranks+
 " unique="+distinctRanks.size+" histories="+histories+
 " sharedWrites="+sharedWrites+" streamMismatches="+canonicalStreamWrong+
 " oldWrong="+fullWrong+" oldMatches="+fullSame);
