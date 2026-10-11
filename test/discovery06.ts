import {
  bootstrapMonster, createMonsterContext, Discovery06PriorHandler, LegacyVisiblePriorAdapter,
  discoverLegacyPrior, MonsterStageError, MonsterValidationError,
  patch01Save, patch02DayTags, patch03Distance, patch04Stones, patch05HiddenDrops,
  calendarDateSpaghetti
} from "../src/index.ts";
import {
  FOUNDATION_DAY as F, M, STONES, SAVE, workCounts, buildHiddenDrops, buildVisibleDrops
} from "./normativeOracle.ts";

function check(ok:boolean, description:string):void { if(!ok) throw new Error(description); }
function rejects(task:()=>unknown, cls:typeof MonsterValidationError | typeof MonsterStageError):boolean {
  try{task()}catch(e){return e instanceof cls}
  return false;
}
const counts=workCounts(F,F),hidden=buildHiddenDrops(counts,STONES);
const visible=buildVisibleDrops(counts,STONES,hidden);
const adapter=new LegacyVisiblePriorAdapter();
const witnesses:readonly (readonly [number,1|3|7])[]=[
  [1,1],[1,3],[1,7],[2,3],[2,7],[3,3],[3,7],
  [4,7],[5,7],[6,7],[7,7],
  [2,1],[4,3],[8,7],[8,1]
];
let mismatches=0,matches=0,hiddenWitnesses=0,visibleWitnesses=0;
const contexts=new Set<object>();

for(const [i,back] of witnesses){
  const slot=i-back;
  const actual=discoverLegacyPrior(F,F,visible,i,back);
  const expected=slot>=1 ? visible[slot]! : hidden[1-slot]!;
  check(!contexts.has(actual.context),"context प्रत्येक वेळी स्वतंत्र हवा");
  contexts.add(actual.context);
  check(actual.dropIndex===i && actual.back===back && actual.historySlot===slot,
    "इतिहासातील 1-based स्लॉटचा हिशेब");
  check(actual.legacyValue===adapter.legacyPrior(visible,i,back),
    "प्रत्यक्ष इतिहासातील helper वापरावा");
  check(Object.isFrozen(actual) && Object.isFrozen(actual.inputVisibleStore),
    "निरीक्षण आणि दिसणाऱ्या थेंबांची प्रत frozen हवी");
  check(actual.context.status==="DISCOVERY_06_RECORDED" && actual.context.phase==="READY",
    "संदर्भ जीवनचक्र");
  check(actual.context.branchTrace.join(",")===[
    "BOOTSTRAP_VALIDATE","DISCOVERY_06_LEGACY_PRIOR_VISIBLE_ONLY",
    slot<1?"DISCOVERY_06_MISSING_HIDDEN_HISTORY":"DISCOVERY_06_VISIBLE_HISTORY_FOUND"
  ].join(","),"ऐतिहासिक शाखा नोंद");
  check(actual.context.metrics.get("bootstrap.calls")===1n &&
    actual.context.metrics.get("discovery06.calls")===1n &&
    (actual.context.metrics.get("discovery06.hidden_slots_not_supported")??0n)===BigInt(slot<1?1:0) &&
    (actual.context.metrics.get("discovery06.visible_slots_supported")??0n)===BigInt(slot>=1?1:0),
    "मापनात hidden/visible शाखा फरक");
  if(slot<1) {
    hiddenWitnesses++;
    check(actual.legacyValue===undefined && !actual.legacyFound,
      "legacy helper ने hidden थेंब शोधू नये");
    check(typeof expected==="bigint","नियमाधारित hidden इतिहास असला पाहिजे");
    mismatches++;
  } else {
    visibleWitnesses++;
    check(actual.legacyValue===expected && actual.legacyFound,
      "positive history slot मध्ये legacy helper बरोबर असावा");
    matches++;
  }
}
check(hiddenWitnesses===11 && visibleWitnesses===4 && mismatches===11 && matches===4,
  "मूळ 15 साक्षींमध्ये 11 अपयशी hidden व 4 योग्य visible");

const first=discoverLegacyPrior(F,F,visible,1,1);
const second=discoverLegacyPrior(F,F,visible,1,1);
first.context.logs.push("फक्त पहिल्या आवाहनात");
first.context.metrics.set("private",19n);
check(first.context!==second.context && first.inputVisibleStore!==second.inputVisibleStore &&
  second.context.logs.length===0 && !second.context.metrics.has("private"),
  "भिन्न आवाहनांचे mutable संदर्भ मिसळू नयेत");
check(first.inputVisibleStore[0]===undefined && first.inputVisibleStore[1]===visible[1],
  "visible storage ची मूळ 1-based रचना बदलू नये");

// जुनी क्रिया negative slots च्या ऐवजी hidden इतिहास कधीच शोधत नाही.
check(adapter.legacyPrior(visible,7,7)===undefined && hidden[1]!==undefined,
  "visible indexing विरुद्ध hidden1 अपेक्षित लाल पुरावा");
check(adapter.legacyPrior(visible,8,7)===visible[1],
  "पहिला visible history slot");

const handler=new Discovery06PriorHandler();
const raw=createMonsterContext(F,F);
check(rejects(()=>handler.run(raw,visible,1,1),MonsterStageError),
  "अतयार context नाकारावा");
check(raw.branchTrace.length===0 && raw.metrics.size===0 &&
  raw.status==="NEW","अपयशी संदर्भात बदल होऊ नये");
const ready=bootstrapMonster(F,F);
for(const pair of [[0,1],[47,1],[1,2],[1,0],[1,8],[1,1.5],[NaN,1]] as const){
  check(rejects(()=>handler.run(ready,visible,pair[0],pair[1] as 1|3|7),
    MonsterValidationError),"बेकायदा इतिहास पॅरामीटर नाकारावा");
}
check(rejects(()=>handler.run({...ready,calculationDay:"wrong" as unknown as bigint},visible,1,1),
  MonsterValidationError),"संदर्भातील गैर-bigint दिवस नाकारावा");
check(rejects(()=>handler.run(ready,[],8,7),MonsterValidationError),
  "गहाळ सकारात्मक visible slot नाकारावा");
check(ready.status==="VALIDATED" && ready.branchTrace.length===1 && ready.metrics.size===1,
  "पूर्व-पडताळणीमध्ये संदर्भ न बदलणे");
handler.run(ready,visible,1,7);
check(rejects(()=>handler.run(ready,visible,1,7),MonsterStageError),
  "वापरलेला संदर्भ पुन्हा नाकारावा");

// Stage 01–11 मधील सर्व दुरुस्त मार्ग अबाधित.
check(patch01Save(F,F,3n*M).savedValue===SAVE(3n*M),"PATCH 01");
check(patch02DayTags(F,F+1n).target.correctedTag===3n,"PATCH 02");
check(patch03Distance(F-2n,F+2n).distance===workCounts(F-2n,F+2n).distance,"PATCH 03");
check(patch04Stones(F,F,2n,STONES[1]!).correctedStone.every((v,j)=>v===STONES[2]![j]),
  "PATCH 04");
const canonicalHidden=Array.from({length:7},(_,j)=>hidden[j+1]!);
check(patch05HiddenDrops(F,F,canonicalHidden).correctedReads.every((v,j)=>v===canonicalHidden[j]),
  "PATCH 05");
check(rejects(()=>calendarDateSpaghetti(F,F),MonsterStageError),
  "Stage 54 चा दिनांक मार्ग अकाली सुरू होऊ नये");
console.log(`STAGE_12_DISCOVERY_06_GUARDS_PASS mismatches=${mismatches} matches=${matches} hidden=${hiddenWitnesses} visible=${visibleWitnesses}`);
