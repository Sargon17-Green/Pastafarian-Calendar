import {MonsterValidationError} from "../src/monsterBase.ts";
import {projectProductionFivePartDate} from "../src/postStage55FivePartProjection.ts";
import {cutletNameByCanonicalIndex,monthNameByCanonicalIndex} from "../src/sourceLanguageCatalog.ts";
import {NormativeOracle} from "./normativeOracle.ts";

function ok(p:boolean,msg:string):void{if(!p)throw Error(msg);}
const oracle=new NormativeOracle();
const c=oracle.gateDay(1n)+1n;
const year=oracle.year5000(c);
const state=oracle.buildYearStructure(c,year);
const gates:bigint[]=[];
for(let i=year.openGateIndex;i<=year.closeGateIndex;i++)
  gates.push(oracle.gateDay(i));
const args=[
  year.number,gates,state.cutletPartition,state.cutletCanonicalIndices,
  state.monthLengths,state.monthWeaving,state.monthCanonicalIndices
] as const;
ok(year.number===5000n,"real Year5000 fixture");
ok(state.monthWeaving.length===5349,"Year5000 length");
ok(state.monthWeaving[238]!==44,"day239 is not a member of month44");
ok(state.monthWeaving.filter(id=>id===44).length===123,"month44 has exactly 123 members");
const prefix=Array<number>(state.monthCount).fill(0);
let checked=0,boundaries=0,holes=0;
for(let t=year.openGateDay+1n;t<=year.closeGateDay;t++){
  const offset=Number(t-year.openGateDay)-1;
  const id=state.monthWeaving[offset]!;
  prefix[id-1]!++;
  const reference=state.cutlets.find(k=>k.firstDay<=t&&t<=k.lastDay);
  if(!reference)throw Error("independent oracle cutlet missing");
  const expected=[
    year.number,cutletNameByCanonicalIndex(reference.canonicalIndex),
    t-reference.firstDay+1n,
    monthNameByCanonicalIndex(state.monthCanonicalIndices[id-1]!),
    BigInt(prefix[id-1]!)
  ] as const;
  const observed=projectProductionFivePartDate(
    args[0],t,args[1],args[2],args[3],args[4],args[5],args[6]);
  ok(observed.length===5&&Object.isFrozen(observed)&&
     observed.every((v,j)=>v===expected[j]),
     "five-part independently materialized differential at day "+(offset+1));
  if(t===reference.firstDay||t===reference.lastDay)boundaries++;
  if(id!==44&&offset+1>state.monthWeaving.indexOf(44)+1&&
     offset+1<state.monthWeaving.lastIndexOf(44)+1)holes++;
  checked++;
}
ok(checked===5349&&boundaries===2*state.cutletCount,"all days and boundaries");
ok(holes===4989,"real internal month44 non-members");
const first=year.openGateDay+1n;
const valid=projectProductionFivePartDate(
  args[0],first,args[1],args[2],args[3],args[4],args[5],args[6]);
const badName=[...state.monthCanonicalIndices];badName[1]=badName[0]!;
const badLength=[...state.monthLengths];badLength[0]=badLength[0]!+1n;
const badWeave=[...state.monthWeaving];badWeave[0]=0;
const badLast=[...state.monthWeaving];badLast[badLast.length-1]=1;
const badOrder=[...state.monthWeaving];badOrder[0]=2;
const invalid:unknown[][]=[
  [Number(year.number),first,gates,state.cutletPartition,state.cutletCanonicalIndices,state.monthLengths,state.monthWeaving,state.monthCanonicalIndices],
  [year.number,Number(first),gates,state.cutletPartition,state.cutletCanonicalIndices,state.monthLengths,state.monthWeaving,state.monthCanonicalIndices],
  [year.number,year.openGateDay,gates,state.cutletPartition,state.cutletCanonicalIndices,state.monthLengths,state.monthWeaving,state.monthCanonicalIndices],
  [year.number,first,gates,state.cutletPartition,state.cutletCanonicalIndices,null,state.monthWeaving,state.monthCanonicalIndices],
  [year.number,first,gates,state.cutletPartition,state.cutletCanonicalIndices,state.monthLengths,null,state.monthCanonicalIndices],
  [year.number,first,gates,state.cutletPartition,state.cutletCanonicalIndices,state.monthLengths,state.monthWeaving,null],
  [year.number,first,gates,state.cutletPartition,state.cutletCanonicalIndices,badLength,state.monthWeaving,state.monthCanonicalIndices],
  [year.number,first,gates,state.cutletPartition,state.cutletCanonicalIndices,state.monthLengths,state.monthWeaving,badName],
  [year.number,first,gates,state.cutletPartition,state.cutletCanonicalIndices,state.monthLengths,badWeave,state.monthCanonicalIndices],
  [year.number,first,gates,state.cutletPartition,state.cutletCanonicalIndices,state.monthLengths,badLast,state.monthCanonicalIndices],
  [year.number,first,gates,state.cutletPartition,state.cutletCanonicalIndices,state.monthLengths,badOrder,state.monthCanonicalIndices],
  [year.number,first,gates,state.cutletPartition,state.cutletCanonicalIndices,state.monthLengths,state.monthWeaving.slice(1),state.monthCanonicalIndices],
  [year.number,first,gates,state.cutletPartition,state.cutletCanonicalIndices,state.monthLengths,state.monthWeaving,[...state.monthCanonicalIndices,47]]
];
let rejected=0;
for(const input of invalid){
  try{
    projectProductionFivePartDate(...(input as Parameters<typeof projectProductionFivePartDate>));
  }catch(e){if(e instanceof MonsterValidationError)rejected++;}
}
ok(rejected===invalid.length,"all malformed inputs rejected");
const retry=projectProductionFivePartDate(
  args[0],first,args[1],args[2],args[3],args[4],args[5],args[6]);
ok(retry.every((v,i)=>v===valid[i])&&Object.isFrozen(retry),
   "fault-free replay uses fresh pure state");
console.log("POST_STAGE55_FIVE_PART_PURE_PROJECTION_PASS realYear="+year.number+
  " days="+checked+" cutletBoundaries="+boundaries+
  " month44Holes="+holes+" malformedRejected="+rejected+
  " pureRetry=1 additionalNativeCalls=0 apiEnabled=0");
