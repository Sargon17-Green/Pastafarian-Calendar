import {MonsterValidationError} from "../src/monsterBase.ts";
import {projectProductionCutletFromGateDays} from "../src/postStage55CutletProjection.ts";
import {cutletNameByCanonicalIndex} from "../src/sourceLanguageCatalog.ts";
import {NormativeOracle,sauce} from "./normativeOracle.ts";
function ok(condition:boolean,message:string):void{if(!condition)throw Error(message);}
const oracle=new NormativeOracle();
const c=oracle.gateDay(1n)+1n;
const year=oracle.year5000(c);
const source=sauce(c,year.openGateDay+1n);
const K=oracle.chooseCutletCount(source,year);
const partition=oracle.chooseCutletPartition(c,source,year,K);
const canonical=oracle.chooseCutletNames(source,K);
const expected=oracle.materializeCutlets(year,partition,canonical);
const gates:bigint[]=[];
for(let i=year.openGateIndex;i<=year.closeGateIndex;i++)gates.push(oracle.gateDay(i));
ok(gates.length===Number(year.closeGateIndex-year.openGateIndex)+1,"real gate count");
ok(partition.reduce((a,b)=>a+b,0n)===BigInt(gates.length-1),"real gate-gap partition");
let tested=0, boundaries=0;
for(let t=year.openGateDay+1n;t<=year.closeGateDay;t++){
  const actual=projectProductionCutletFromGateDays(year.number,t,gates,partition,canonical);
  // Independent oracle materializes each cutlet directly from signed gate indices.
  const reference=expected.find(e=>e.firstDay<=t&&t<=e.lastDay);
  if(reference===undefined)throw new Error("oracle cutlet covers day");
  ok(actual.yearNumber===year.number&&
     actual.cutletName===cutletNameByCanonicalIndex(reference.canonicalIndex)&&
     actual.canonicalIndex===reference.canonicalIndex&&
     actual.firstDay===reference.firstDay&&actual.lastDay===reference.lastDay&&
     actual.dayInCutlet===t-reference.firstDay+1n&&
     actual.dayInCutlet>=1n&&Object.isFrozen(actual),
     "real Year5000 measured-gate projection mismatch at "+String(t));
  if(t===reference.firstDay||t===reference.lastDay)boundaries++;
  tested++;
}
ok(tested===Number(year.closeGateDay-year.openGateDay),"every real Year5000 day tested");
const first=year.openGateDay+1n;
const safe=projectProductionCutletFromGateDays(year.number,first,gates,partition,canonical);
let malformed=0;
const invalid:unknown[][]=[
  [Number(year.number),first,gates,partition,canonical],
  [year.number,Number(first),gates,partition,canonical],
  [year.number,year.openGateDay,gates,partition,canonical],
  [year.number,year.closeGateDay+1n,gates,partition,canonical],
  [year.number,first,gates.slice(1),partition,canonical],
  [year.number,first,[...gates].reverse(),partition,canonical],
  [year.number,first,gates,partition.slice(1),canonical.slice(1)],
  [year.number,first,gates,[...partition.slice(0,-1),0n],canonical],
  [year.number,first,gates,partition,[...canonical.slice(0,-1),canonical[0]]],
  [year.number,first,gates,partition,canonical.map((n,i)=>i===0?18:n)],
  [year.number,first,[...gates.slice(0,1),gates[0]!+1n,...gates.slice(2)],partition,canonical],
  [year.number,first,gates,partition,canonical.slice(1)]
];
for(const args of invalid){
  try{projectProductionCutletFromGateDays(...(args as Parameters<typeof projectProductionCutletFromGateDays>));}
  catch(e){if(e instanceof MonsterValidationError)malformed++;}
}
ok(malformed===invalid.length,"invalid gate/partition/name inputs rejected");
const retry=projectProductionCutletFromGateDays(year.number,first,gates,partition,canonical);
ok(retry.cutletName===safe.cutletName&&retry.dayInCutlet===safe.dayInCutlet&&
   Object.isFrozen(retry)&&Object.isFrozen(safe),
   "invalid paths do not poison subsequent pure projection");
console.log("POST_STAGE55_CUTLET_PROJECTION_PASS realYear="+year.number+
  " realYearDays="+tested+" cutlets="+K+" exactBoundaryDays="+boundaries+
  " malformedRejected="+malformed+" pureRetry=1 additionalNativeCalls=0");
