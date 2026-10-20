import type {Patch20StructureRequest} from "../src/patch20StructureSauce.ts";
import {
  FOUNDATION_DAY as F,STONES,NormativeOracle,workCounts,
  buildHiddenDrops,buildVisibleDrops,initialBowls,
  sauce,askBowl,chooseRank,boundedCompositionFamily
} from "./normativeOracle.ts";
export function assert(v:boolean,m:string):void{if(!v)throw Error(m);}
export function question(c:bigint,t:bigint){
 const w=workCounts(c,t);
 return {targetDay:t,
   visible:buildVisibleDrops(w,STONES,buildHiddenDrops(w,STONES)),
   stones:STONES,startBowls:initialBowls(w)};
}
export function anyPrefix(parts:readonly bigint[],wanted:bigint):boolean{
 let sum=0n;
 for(let i=0;i<parts.length-1;i++){sum+=parts[i]!;if(sum===wanted)return true;}
 return false;
}
export type Fixture=Readonly<{
  request:Patch20StructureRequest;
  index:bigint;
  G:bigint;K:number;required:bigint;
  legacyRank:bigint;
  legacyFamily:bigint;
  oldPartition:readonly bigint[];
  correctPartition:readonly bigint[];
  year:ReturnType<NormativeOracle["year5000"]>;
  gateQuestions:number;
}>;
export function findTrueHistoricalBoundaryMiss():Fixture {
 const oracle=new NormativeOracle();
 for(const i of [1n,-1n,2n,-2n,3n,-3n,4n,-4n,
   5n,-5n,6n,-6n,7n,-7n,8n,-8n]){
  const c=oracle.gateDay(i),year=oracle.year5000(c);
  if(!(year.openGateIndex<i&&i<year.closeGateIndex))continue;
  const G=year.closeGateIndex-year.openGateIndex;
  const structure=sauce(c,year.openGateDay+1n);
  const K=oracle.chooseCutletCount(structure,year);
  const legacy=boundedCompositionFamily(G,K,1n,G);
  const rank=chooseRank(askBowl(structure,2,21n),legacy.count());
  const oldPartition=legacy.unrank1(rank);
  const required=i-year.openGateIndex;
  if(anyPrefix(oldPartition,required))continue;
  const corrected=oracle.chooseCutletPartition(c,structure,year,K);
  assert(anyPrefix(corrected,required),
   "true independent oracle chooses cutlet boundary at calculation-day gate");
  const low=c-5779n,high=c+5779n;
  let positiveCount=1,negativeCount=1;
  while(oracle.gateDay(BigInt(positiveCount))<=high){
    positiveCount++;assert(positiveCount<=100,"bounded positive gate window");
  }
  while(oracle.gateDay(-BigInt(negativeCount))>=low){
    negativeCount++;assert(negativeCount<=100,"bounded negative gate window");
  }
  const positives=Array.from({length:positiveCount},(_,j)=>question(F,F+BigInt(j+1)));
  const negatives=Array.from({length:negativeCount},(_,j)=>question(F,F-BigInt(j+1)));
  const indexSign=i<0n?-1n:1n;
  const abs=Number(i<0n?-i:i);
  const originalTarget=year.closeGateDay;
  const request:Patch20StructureRequest={
    historical:{
      yearQuestion:{
        calculationDay:c,targetDay:originalTarget,anchorGateIndex:i,
        historicalPositive:Array.from({length:abs},(_,j)=>
          question(F,F+BigInt(j+1))),
        signedQuestions:Array.from({length:abs},(_,j)=>
          question(F,F+indexSign*BigInt(j+1))),
        oldYearQuestion:question(c,c),
        oldAnchorCandidates:[{
          openGateIndex:i,closeGateIndex:i+6n,
          openGateDay:c,closeGateDay:c+800n
        }],
        oldMultiCandidates:[{
          openGateIndex:i,closeGateIndex:i+6n,
          openGateDay:c,closeGateDay:c+1000n
        },{
          openGateIndex:i-1n,closeGateIndex:i+6n,
          openGateDay:c-100n,closeGateDay:c+900n
        }],
        positive:positives,negative:negatives,
        trueYearQuestion:question(c,c),
        transitionQuestion:(cc,tt,_seal)=>question(cc,tt),
        maximumSteps:0
      },
      originalSauceQuestion:question(c,originalTarget)
    },
    firstDaySauceQuestion:question(c,year.openGateDay+1n)
  };
  return Object.freeze({
    request,index:i,G,K,required,legacyRank:rank,
    legacyFamily:legacy.count(),
    oldPartition,correctPartition:corrected,year,
    gateQuestions:positiveCount+negativeCount
  });
 }
 throw Error("NO_TRUE_INTERNAL_ACTION_GATE_WITH_UNFILTERED_LEGACY_MISS_IN_16_SIGNED_WITNESSES");
}
