import {MonsterValidationError} from "../src/monsterBase.ts";
import {Patch14WideChoiceDispatcher} from "../src/patch14WideChoice.ts";
import {createProductionPatch18Question} from "../src/postStage55NativeQuestion.ts";
import {selectProductionMonthNames} from "../src/postStage55MonthNames.ts";
import {monthNameByCanonicalIndex} from "../src/sourceLanguageCatalog.ts";
import {NormativeOracle,sauce} from "./normativeOracle.ts";
function ok(x:boolean,message:string):void {if(!x)throw new Error(message);}
const oracle=new NormativeOracle();
const firstC=oracle.gateDay(1n)+1n;
const year=oracle.year5000(firstC);
const first=year.openGateDay+1n;
const cases=[
 {c:firstC,m:3},{c:firstC+1n,m:17},{c:firstC,m:47}
];
let compared=0, calls=0,writes=0n;
for(const {c,m} of cases){
 const q=createProductionPatch18Question(c,first);
 const actual=selectProductionMonthNames(c,q,m);
 const expected=oracle.chooseMonthNames(sauce(c,first),m);
 ok(actual.source==="PRODUCTION_NATIVE_SEAL33_DISTINCT_MONTH_NAMES"&&
    actual.nativeSelection.queriedBowlId===5&&actual.nativeSelection.seal===33n,
    "real Native Seal33 was invoked");
 ok(actual.correctedNameIndices.length===m&&actual.canonicalNames.length===m&&
    Object.isFrozen(actual)&&Object.isFrozen(actual.correctedNameIndices)&&
    Object.isFrozen(actual.canonicalNames),"immutable complete mapping");
 for(let i=0;i<m;i++){
   ok(actual.correctedNameIndices[i]===expected[i],"independent oracle index");
   ok(actual.canonicalNames[i]===monthNameByCanonicalIndex(expected[i]!),
      "canonical index is not the month position ID");
   compared++;
 }
 ok(actual.actualNativeCalls===1&&actual.actualSharedWrites===58n,
    "Native call and write budget");
 calls+=actual.actualNativeCalls;writes+=actual.actualSharedWrites;
 const replay=selectProductionMonthNames(c,createProductionPatch18Question(c,first),m);
 ok(replay.correctedNameIndices.join(",")===actual.correctedNameIndices.join(","),
    "deterministic clean independent repeat");
 calls++;writes+=replay.actualSharedWrites;
}
ok(writes===58n*BigInt(calls),"combined Native accounting");
const q=createProductionPatch18Question(firstC,first);
let invalid=0;
for(const args of [
 [Number(firstC),q,3],[firstC,q,2],[firstC,q,48],
 [firstC,q,3.2],[firstC,{...q,targetDay:"broken"},3],
 [firstC,{...q,calculationDay:firstC+1n},3]
] as unknown as [bigint,typeof q,number][]){
 try{selectProductionMonthNames(...args);}
 catch(e){if(e instanceof MonsterValidationError)invalid++;}
}
ok(invalid===6,"malformed inputs rejected");
const dispatch=Patch14WideChoiceDispatcher.prototype.dispatch;
let fault=false;
try{
 Patch14WideChoiceDispatcher.prototype.dispatch=function(...args:Parameters<typeof dispatch>){
  fault=true;
  throw new Error("SEAL33_DEEP_FAULT");
 };
 try{selectProductionMonthNames(firstC,q,3);throw new Error("not failed");}
 catch(e){ok(e instanceof Error&&e.message==="SEAL33_DEEP_FAULT",
   "deep Native fault propagates without publishing a selection");}
}finally{Patch14WideChoiceDispatcher.prototype.dispatch=dispatch;}
ok(fault&&selectProductionMonthNames(firstC,q,3).correctedNameIndices.length===3,
   "fresh retry is independent of failed owner");
console.log("POST_STAGE55_MONTH_NAMES_PASS cases="+cases.length+
 " independentNameComparisons="+compared+" nativeCalls="+(calls+1)+
 " sharedWrites="+(writes+58n)+" malformedRejected="+invalid+
 " deepFaults=1 cleanRetry=1");
