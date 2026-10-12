import {
  Patch13RejectionRankAdapter,patch13RejectionRank,
  LegacyBiasedModuloRankAdapter
} from "../src/index.ts";
import {
  FOUNDATION_DAY as F,M,STONES,workCounts,buildHiddenDrops,buildVisibleDrops,
  initialBowls,applyVisibleDropsToBowls,postStir12,bowlOrderFromDrop,
  askBowl,chooseRank
} from "./normativeOracle.ts";
function check(ok:boolean,msg:string):void{if(!ok)throw Error(msg);}
const corrected=new Patch13RejectionRankAdapter(),old=new LegacyBiasedModuloRankAdapter();
let sizes=0,cells=0,mismatches=0,oldWrong=0,oldMatches=0;
let shortRejected=0,shortWraps=0,wideCases=0,wideWrong=0;
const firstSamples=[1n,2n,M-2n,M-1n,M];
for(let N=1n;N<=256n;N++){
 for(const first of firstSamples){
  for(const directionStep of [-1n,1n] as const){
   const stream={first,directionStep};
   const want=chooseRank(stream,N),out=corrected.choose(stream,N);
   if(out.rank!==want)mismatches++;
   if(old.oldChooseModulo(first,N)===want)oldMatches++;else oldWrong++;
   if(out.rejectedCandidates>0n){
    shortRejected++;
    if(directionStep===1n)shortWraps++;
   }
   check(out.mode==="SHORT"&&out.digitCount===1&&
     out.answerDigits.join(",")===String(first)&&
     out.firstCandidate===first&&out.acceptanceLimit===(M/N)*N&&
     out.sampleSpace===M&&
     out.acceptedCandidate<=out.acceptanceLimit&&
     out.acceptedCandidate>=1n&&
     out.rank>=1n&&out.rank<=N,"all short grid invariants");
   cells++;
  }
 }
 sizes++;
}
check(sizes===256&&cells===2560&&mismatches===0&&
 oldWrong>0&&oldMatches>0&&shortRejected>0&&shortWraps>0,
 "256 short families × 5 boundary first answers × 2 directions");

// Independent, exhaustive finite-base proof of the O(1) rejection jump.
// The oracle below REALLY enumerates each +1/-1 candidate, unlike production.
// For each small base also construct consecutive base digits independently.
function mod(x:bigint,b:bigint):bigint{const r=x%b;return r<0n?r+b:r;}
function finiteReference(base:bigint,first:bigint,step:1n|-1n,N:bigint){
 let k=1,space=base;
 while(space<N){space*=base;k++;}
 let composite=1n,weight=1n;
 for(let j=0;j<k;j++){
  const digit=1n+mod(first-1n+step*BigInt(j),base);
  composite+=(digit-1n)*weight;weight*=base;
 }
 const threshold=(space/N)*N,original=composite;
 let walked=0n;
 while(composite>threshold){
  composite=1n+mod(composite-1n+step,space);
  walked++;
  if(walked>space)throw Error("finite oracle exhausted every cyclic state");
 }
 return {space,threshold,original,accepted:composite,walked,
   rank:1n+mod(composite-1n,N),digits:k};
}
let surrogate=0,surrogateRejected=0,surrogateWide=0,surrogateWrap=0;
for(let b=2n;b<=12n;b++){
 for(let N=1n;N<=b*b+b+3n;N++){
  for(let first=1n;first<=b;first++){
   for(const step of [-1n,1n] as const){
    const gold=finiteReference(b,first,step,N);
    // The algebraic shortcut does NOT use the slow oracle's candidate scan.
    const limit=gold.threshold,space=gold.space,initial=gold.original;
    const selected=initial<=limit?initial:step===-1n?limit:1n;
    const jumped=initial<=limit?0n:step===-1n?initial-limit:space-initial+1n;
    const rank=1n+mod(selected-1n,N);
    check(selected===gold.accepted&&jumped===gold.walked&&rank===gold.rank,
      "finite exhaustive brute oracle proves skip count and cyclic crossing");
    if(gold.walked>0n){
     surrogateRejected++;
     if(step===1n&&gold.accepted===1n)surrogateWrap++;
    }
    if(N>b)surrogateWide++;
    surrogate++;
   }
  }
 }
}
check(surrogate>10000&&surrogateRejected>0&&surrogateWide>0&&surrogateWrap>0,
 "small-base exhaustive brute proof of all 1..k digit paths");

// Wide real M-adic cases with bounded independent reference enumeration.
const powers=[M+1n,M+2n,M*M-1n,M*M,M*M+1n,
   M*M+M+1n,M*M*M-1n,M*M*M,M*M*M+1n,1n<<16384n];
let powerCases=0,powerDigits=0;
for(const N of powers){
 const stream={first:1n,directionStep:1n as const};
 const want=chooseRank(stream,N),actual=corrected.choose(stream,N);
 check(actual.rank===want&&actual.mode==="WIDE"&&actual.digitCount>=2&&
    actual.digitCount===actual.answerDigits.length&&
    actual.sampleSpace>=N&&
    actual.sampleSpace/M<N&&
    actual.rank>=1n&&actual.rank<=N,
 "wide boundary M^k±1, giant 16k-bit N and M-adic digit order");
 powerDigits+=actual.digitCount;powerCases++;
}
const bigGap=M*M/2n+1n;
for(const [first,step] of [[M,-1n],[M-1n,1n]] as const){
 const out=corrected.choose({first,directionStep:step},bigGap);
 const accepted=step===-1n?out.acceptanceLimit:1n;
 const walks=step===-1n?
  out.firstCandidate-out.acceptanceLimit:out.sampleSpace-out.firstCandidate+1n;
 check(out.mode==="WIDE"&&out.firstCandidate>out.acceptanceLimit&&
  out.acceptedCandidate===accepted&&out.rejectedCandidates===walks&&
  out.rank===1n+(accepted-1n)%bigGap,
 "huge rank gap analytically skipped without an impossible oracle loop");
 wideCases++;
}
for(const N of [M+1n,M*M-1n,M*M,M*M+1n]){
 const out=corrected.choose({first:1n,directionStep:1n},N);
 if(out.rank!==old.oldChooseModulo(1n,N))wideWrong++;
}
check(powerCases===powers.length&&powerDigits>20&&wideCases===2,
 "wide M-adic boundaries and exact enormous skip proof");

const pairs:readonly (readonly [bigint,bigint])[]=[
 [F,F],[F-1n,F],[F+1n,F],[F,F-1n],[F,F+1n],
 [F-89n,F+273n],[F+273n,F-89n],[-278522n,-278522n],
 [-278522n,-268522n],[1n,1n],[100000n,-100000n],[-100000n,100000n]
];
const counts=workCounts(F,F),hidden=buildHiddenDrops(counts,STONES);
const baseline=buildVisibleDrops(counts,STONES,hidden),start=initialBowls(counts);
const familySizes=[1n,2n,3n,5n,7n,922n,M,M+1n,M*M+1n] as const;
const contexts=new Set<object>(),orders=new Set<string>();
let real=0,varied=0,giant=0,ranks=0,histories=0,writes=0;
let fullMismatches=0,fullOldWrong=0,fullOldMatches=0,streamWrong=0;
function verify(c:bigint,t:bigint,visible:readonly bigint[],bowls:readonly bigint[],
 id:number,seal:bigint,N:bigint,kind:"real"|"varied"|"giant"|"rank"):void{
 const priorInputs=[...bowls];
 const out=patch13RejectionRank(c,t,visible,STONES,bowls,id,seal,N);
 const expectedDrop=applyVisibleDropsToBowls(
   [...bowls] as [bigint,bigint,bigint,bigint,bigint,bigint],visible,STONES);
 const canonicalBowls=postStir12(
   [...expectedDrop.bowls] as [bigint,bigint,bigint,bigint,bigint,bigint]);
 const order=bowlOrderFromDrop(visible[46]!);
 const stream=askBowl({bowls:canonicalBowls,orderAtDrop46:order},id,seal);
 const trueRank=chooseRank(stream,N);
 if(out.correctedRank!==trueRank)fullMismatches++;
 if(out.legacyBiasedRank===trueRank)fullOldMatches++;else fullOldWrong++;
 if(out.firstAnswer!==stream.first||out.directionStep!==stream.directionStep)streamWrong++;
 check(out.preceding.preceding.orderAt46Latch.join(",")===order.join(",")&&
  out.preceding.preceding.correctedNextBowlId===order[(order.indexOf(id)+1)%6]&&
  out.preceding.preceding.afterDropBowls.every((v,j)=>v===expectedDrop.bowls[j])&&
  out.preceding.preceding.finalBowls.every((v,j)=>v===canonicalBowls[j])&&
  out.preceding.preceding.preceding.sharedMemoryWrites===58&&
  out.preceding.preceding.preceding.historical.latestSource==="STIR_12"&&
  out.preceding.legacyModuloCalls===1&&
  out.legacyBiasedRank===old.oldChooseModulo(stream.first,N)&&
  out.correctedRank===out.selection.rank&&
  out.correctedSelectorCalls===1&&out.legacySelectorCalls===1&&
  out.predecessorSharedMemoryWrites===58&&
  out.context.metrics.get("patch13.corrected_selector_calls")===1n&&
  out.context.metrics.get("patch13.legacy_selector_calls")===1n&&
  out.context.status==="PATCH_13_APPLIED"&&
  out.selection.sampleSpace>=N&&out.correctedRank>=1n&&out.correctedRank<=N&&
  !contexts.has(out.context)&&out.context!==out.preceding.context&&
  Object.isFrozen(out.selection.answerDigits)&&
  bowsUnchanged(bowls,priorInputs),
  "804 true 58-write predecessor histories and corrected independent rank");
 contexts.add(out.context);histories++;writes+=out.predecessorSharedMemoryWrites;
 if(kind==="rank")orders.add(out.preceding.preceding.orderAt46Latch.join(","));
}
function bowsUnchanged(a:readonly bigint[],b:readonly bigint[]):boolean{
 return a.length===b.length&&a.every((v,j)=>v===b[j]);
}
for(const [c,t] of pairs){
 const w=workCounts(c,t),hidden=buildHiddenDrops(w,STONES),v=buildVisibleDrops(w,STONES,hidden);
 verify(c,t,v,initialBowls(w),(real%6)+1,BigInt(1+real%33),
   familySizes[real%familySizes.length]!,"real");real++;
}
for(let j=0;j<64;j++){
 const v=[...baseline];
 v[1]=j%2===0?BigInt(j*149+1):-BigInt(j*137+3);
 v[46]=j%3===0?BigInt(j*721+2):-BigInt(j*719+11);
 verify(F+BigInt(j),F-BigInt(j),v,start,(j%6)+1,BigInt(1+j%33),
   familySizes[j%familySizes.length]!,"varied");varied++;
}
const huge=(1n<<8192n)+193n;
for(const d of [huge,-huge,huge*huge,-huge*huge,0n,720n,1n<<16384n,-(1n<<16384n)]){
 const v=[...baseline];v[1]=d;v[46]=-d+1n;
 const b=[huge+11n,-huge-13n,huge+17n,-huge-23n,huge+37n,-huge-41n];
 verify(F-huge,F+huge,v,b,(giant%6)+1,BigInt(giant+1),
   familySizes[giant%familySizes.length]!,"giant");giant++;
}
for(let rank=1n;rank<=720n;rank++){
 const v=[...baseline];v[46]=rank;
 verify(F,F,v,start,(Number(rank)%6)+1,BigInt(Number(rank)%33+1),
   familySizes[Number(rank)%familySizes.length]!,"rank");ranks++;
}
check(real===12&&varied===64&&giant===8&&ranks===720&&histories===804&&
 writes===46632&&orders.size===720&&contexts.size===804&&
 fullMismatches===0&&streamWrong===0&&fullOldWrong>0&&fullOldMatches>0&&
 fullOldWrong+fullOldMatches===histories,
 "804 full Stage25+26 chains, independently selected correct ranks, old scar remains");
console.log("STAGE_27_PATCH_13_PROPERTIES_PASS shortSizes="+sizes+
 " shortCells="+cells+" shortMismatches="+mismatches+
 " shortOldWrong="+oldWrong+" shortOldMatches="+oldMatches+
 " shortRejected="+shortRejected+" shortWraps="+shortWraps+
 " surrogateCases="+surrogate+" surrogateRejected="+surrogateRejected+
 " surrogateWide="+surrogateWide+" surrogateWrap="+surrogateWrap+
 " powerCases="+powerCases+" powerDigits="+powerDigits+
 " giantWideGaps="+wideCases+" realPairs="+real+
 " varied="+varied+" giant="+giant+" ranks="+ranks+" unique="+orders.size+
 " histories="+histories+" sharedWrites="+writes+" streamMismatches="+streamWrong+
 " fullMismatches="+fullMismatches+" fullOldWrong="+fullOldWrong+
 " fullOldMatches="+fullOldMatches);
