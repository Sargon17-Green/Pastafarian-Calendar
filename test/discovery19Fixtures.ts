import type {Discovery19Request} from "../src/discovery19LegacyYearCache.ts";
import {FOUNDATION_DAY as F,STONES,NormativeOracle,
 workCounts,buildHiddenDrops,buildVisibleDrops,initialBowls} from "./normativeOracle.ts";
export function assert(v:boolean,m:string):void{if(!v)throw Error(m);}
export function source(c:bigint,t:bigint){
 const w=workCounts(c,t);
 return {visible:buildVisibleDrops(w,STONES,buildHiddenDrops(w,STONES)),
  stones:STONES,startBowls:initialBowls(w)};
}
export function question(c:bigint,t:bigint){
 return {...source(c,t),targetDay:t};
}
export type CacheFixture=Readonly<{
 first:Discovery19Request;second:Discovery19Request;
 firstSeed:ReturnType<NormativeOracle["year5000"]>;
 secondSeed:ReturnType<NormativeOracle["year5000"]>;
 actualGateQuestions:number;
}>;
export function buildDiscovery19Fixture():CacheFixture {
 const oracle=new NormativeOracle();
 const firstDay=oracle.gateDay(-2n)+1n;
 const secondDay=oracle.gateDay(2n)+1n;
 const seedFirst=oracle.year5000(firstDay),seedSecond=oracle.year5000(secondDay);
 assert(seedFirst.number===5000n&&seedSecond.number===5000n&&
  (seedFirst.openGateDay!==seedSecond.openGateDay||
   seedFirst.closeGateDay!==seedSecond.closeGateDay),
  "two independent cDays must select distinct true Year5000 boundaries");
 const low=(firstDay<secondDay?firstDay:secondDay)-5779n;
 const high=(firstDay>secondDay?firstDay:secondDay)+5779n;
 let positiveCount=1,negativeCount=1;
 while(oracle.gateDay(BigInt(positiveCount))<=high){
  positiveCount++;assert(positiveCount<=128,"positive window bounded");
 }
 while(oracle.gateDay(-BigInt(negativeCount))>=low){
  negativeCount++;assert(negativeCount<=128,"negative window bounded");
 }
 const positive=Array.from({length:positiveCount},(_,i)=>question(F,F+BigInt(i+1)));
 const negative=Array.from({length:negativeCount},(_,i)=>question(F,F-BigInt(i+1)));
 function request(cDay:bigint,seed:typeof seedFirst,index:bigint):Discovery19Request {
  const signedDirection=index<0n?-1n:1n;
  const steps=Number(index<0n?-index:index);
  const g=oracle.gateDay(index);
  return {
   calculationDay:cDay,targetDay:seed.closeGateDay,
   anchorGateIndex:index,
   historicalPositive:Array.from({length:steps},(_,i)=>source(F,F+BigInt(i+1))),
   signedQuestions:Array.from({length:steps},(_,i)=>question(F,F+signedDirection*BigInt(i+1))),
   oldYearQuestion:source(cDay,cDay),
   oldAnchorCandidates:[{
    openGateIndex:index,closeGateIndex:index+6n,
    openGateDay:g,closeGateDay:g+800n
   }],
   oldMultiCandidates:[{
    openGateIndex:index,closeGateIndex:index+6n,
    openGateDay:g,closeGateDay:g+1000n
   },{
    openGateIndex:index-1n,closeGateIndex:index+6n,
    openGateDay:g-100n,closeGateDay:g+900n
   }],
   positive,negative,
   trueYearQuestion:question(cDay,cDay),
   transitionQuestion:(c,t,_seal)=>question(c,t),
   maximumSteps:0
  };
 }
 return Object.freeze({
  first:request(firstDay,seedFirst,-2n),
  second:request(secondDay,seedSecond,2n),
  firstSeed:seedFirst,secondSeed:seedSecond,
  actualGateQuestions:positiveCount+negativeCount
 });
}
