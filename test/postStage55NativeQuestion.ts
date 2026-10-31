import { MonsterValidationError } from "../src/monsterBase.ts";
import { createProductionPatch18Question } from "../src/postStage55NativeQuestion.ts";
import { FOUNDATION_DAY as F, STONES, workCounts, buildHiddenDrops, buildVisibleDrops, initialBowls } from "./normativeOracle.ts";
function requireTrue(condition:boolean,message:string):void {if(!condition)throw Error(message);}
const pairs:readonly (readonly [bigint,bigint])[]=[
 [F,F],[F,F+1n],[F,F-1n],[F+1n,F+1n],
 [F+1234n,F+9999n],[F-9000n,F+11111n],[-(1n<<256n),(1n<<256n)+77n]
];
let compared=0,exactValues=0;
for(const [c,t] of pairs){
 const input=createProductionPatch18Question(c,t);
 const counts=workCounts(c,t);
 const expectedDrops=buildVisibleDrops(counts,STONES,buildHiddenDrops(counts,STONES));
 const expectedBowls=initialBowls(counts);
 requireTrue(input.targetDay===t&&input.visible.length===47&&input.stones.length===47&&input.startBowls.length===6,"question shape");
 requireTrue(Object.isFrozen(input)&&Object.isFrozen(input.visible)&&Object.isFrozen(input.stones)&&Object.isFrozen(input.startBowls)&&input.stones.slice(1).every(Object.isFrozen),"deep freeze");
 for(let i=1;i<=46;i++){
  requireTrue(input.visible[i]===expectedDrops[i],"visible mismatch "+i);exactValues++;
  for(let j=0;j<5;j++){requireTrue(input.stones[i]![j]===STONES[i]![j],"stone mismatch "+i+"/"+j);exactValues++;}
 }
 for(let j=0;j<6;j++){requireTrue(input.startBowls[j]===expectedBowls[j],"bowl mismatch "+j);exactValues++;}
 const again=createProductionPatch18Question(c,t);
 requireTrue(again!==input&&again.visible!==input.visible&&again.stones!==input.stones&&again.startBowls!==input.startBowls,"fresh ownership");
 compared++;
}
let rejected=0;
for(const [c,t] of [[0,1n],[1n,1],[null,1n],[1n,NaN],["1",1n],[undefined,1n]] as unknown as [bigint,bigint][]) {
 try{createProductionPatch18Question(c,t);}catch(e){if(e instanceof MonsterValidationError)rejected++;}
}
requireTrue(rejected===6,"malformed runtime guards");
console.log("POST_STAGE55_NATIVE_QUESTION_PASS pairs="+compared+" exactValues="+exactValues+" malformedRejected="+rejected+" nativeCalls=0 sharedWrites=0");
