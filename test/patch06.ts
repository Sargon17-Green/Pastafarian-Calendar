import {
  bootstrapMonster, createMonsterContext, LegacyBackwardHiddenAdapter,
  LegacyVisiblePriorAdapter, Patch06PriorHandler, Patch05HiddenHandler,
  MonsterStageError, MonsterValidationError, patch06Prior, discoverLegacyPrior,
  patch05HiddenDrops, patch01Save, patch02DayTags, patch03Distance, patch04Stones,
  calendarDateSpaghetti
} from "../src/index.ts";
import {
  FOUNDATION_DAY as F, M, STONES, SAVE, workCounts, buildHiddenDrops, buildVisibleDrops
} from "./normativeOracle.ts";

function check(ok: boolean, message: string): void { if (!ok) throw new Error(message); }
function rejects(fn: () => unknown, error: typeof MonsterStageError | typeof MonsterValidationError): boolean {
  try { fn(); } catch (actual) { return actual instanceof error; }
  return false;
}

const hiddenCanonical = buildHiddenDrops(workCounts(F,F),STONES);
const canonical = Object.freeze(Array.from({length:7},(_,j)=>hiddenCanonical[j+1]!));
const backwardStored = new LegacyBackwardHiddenAdapter().storeBackward(canonical);
const visible = buildVisibleDrops(workCounts(F,F),STONES,hiddenCanonical);
const witnesses: readonly (readonly [number,1|3|7])[] = [
  [1,1],[1,3],[1,7],[2,3],[2,7],[3,3],[3,7],
  [4,7],[5,7],[6,7],[7,7],
  [2,1],[4,3],[8,7],[8,1]
];
let cases=0,hiddenFallbacks=0,visibleLegacyCalls=0,mismatches=0;
const contexts = new Set<object>();
for(const [i,back] of witnesses) {
  const slot=i-back;
  const obs=patch06Prior(F,F,visible,backwardStored,i,back);
  const normative=slot>=1?visible[slot]!:hiddenCanonical[1-slot]!;
  const previous=discoverLegacyPrior(F,F,visible,i,back);
  cases++;
  if(obs.correctedValue!==normative)mismatches++;
  check(!contexts.has(obs.context),"प्रत्येक आवाहनासाठी स्वतंत्र context");
  contexts.add(obs.context);
  check(obs.dropIndex===i && obs.back===back && obs.historySlot===slot,"अचूक 1-based इतिहास क्रमांक");
  check(Object.isFrozen(obs) && Object.isFrozen(obs.inputVisibleStore) &&
    Object.isFrozen(obs.inputBackwardStored),"परिणाम आणि input snapshot अपरिवर्तनीय");
  check(obs.inputVisibleStore!==visible && obs.inputBackwardStored!==backwardStored,
    "visible व hidden स्वतंत्र snapshot मध्ये");
  check(obs.context.phase==="READY" && obs.context.status==="PATCH_06_APPLIED","जीवनचक्र");
  check(obs.context.branchTrace.join(",") === [
    "BOOTSTRAP_VALIDATE","PATCH_06_SELECT_HISTORY",
    slot>=1?"PATCH_06_REAL_LEGACY_VISIBLE":"PATCH_06_STAGE11_CORRECTED_HIDDEN"
  ].join(","),"इतिहास शाखेची प्रत्यक्ष नोंद");
  check(obs.context.metrics.get("bootstrap.calls")===1n &&
    obs.context.metrics.get("patch06.calls")===1n &&
    (obs.context.metrics.get("patch06.visible_legacy_calls")??0n)===BigInt(slot>=1?1:0) &&
    (obs.context.metrics.get("patch06.hidden_fallbacks")??0n)===BigInt(slot<1?1:0),
    "फक्त वापरलेल्या शाखेचे मापन");
  if(slot>=1) {
    visibleLegacyCalls++;
    check(obs.source==="VISIBLE_LEGACY" && obs.legacyCalled &&
      obs.hiddenK===null && obs.hiddenStorageIndexZeroBased===null,
      "positive slot ने जुना helper प्रत्यक्ष वापरावा");
    check(obs.legacyValue===new LegacyVisiblePriorAdapter().legacyPrior(visible,i,back) &&
      obs.legacyValue===normative && previous.legacyValue===normative,
      "जुन्या visible वाचनाचे अर्थ बदलू नयेत");
  } else {
    hiddenFallbacks++;
    const k=1-slot;
    check(obs.source==="HIDDEN_CORRECTED" && !obs.legacyCalled &&
      obs.hiddenK===k && obs.hiddenStorageIndexZeroBased===7-k,
      "hidden k आणि उलटा storage slot");
    check(obs.legacyValue===undefined && previous.legacyValue===undefined,
      "मुळच्या चुकीच्या reader कडून hidden इतिहास मिळू नये");
    check(obs.correctedValue===new Patch05HiddenHandler().correctedHiddenAt(backwardStored,k),
      "सुधारित Stage 11 reader मधूनच hidden value");
  }
}
check(cases===15 && hiddenFallbacks===11 && visibleLegacyCalls===4 && mismatches===0,
  "मूळ 15 लाल साक्षी पूर्ण हिरव्या व्हाव्यात");

// जुना प्रत्यक्ष method किती वेळा वापरला, याची instrumentation साक्ष.
const oldMethod=LegacyVisiblePriorAdapter.prototype.legacyPrior;
let actualLegacyCalls=0;
try {
  LegacyVisiblePriorAdapter.prototype.legacyPrior=function(store,i,back){
    actualLegacyCalls++;
    return oldMethod.call(this,store,i,back);
  };
  patch06Prior(F,F,visible,backwardStored,1,7);
  check(actualLegacyCalls===0,"hidden slot वर legacy call होऊ नये");
  patch06Prior(F,F,visible,backwardStored,8,7);
  check(actualLegacyCalls===1,"positive slot वर खऱ्या legacy method ची call झालीच पाहिजे");
} finally { LegacyVisiblePriorAdapter.prototype.legacyPrior=oldMethod; }

// input चे snapshots व state दुसऱ्या आवाहनात झिरपू नयेत.
const values=[11n,13n,17n,19n,23n,29n,31n];
const stored=new LegacyBackwardHiddenAdapter().storeBackward(values);
const visibleOwned:(bigint|undefined)[]=[undefined,29n,31n];
const first=patch06Prior(F,F,visibleOwned,stored,1,7);
const second=patch06Prior(F,F,visibleOwned,stored,1,7);
visibleOwned[1]=991n;
first.context.logs.push("पहिल्यापुरते");
first.context.metrics.set("private",11n);
check(first.correctedValue===31n && second.correctedValue===31n &&
  first.inputVisibleStore[1]===29n && second.inputVisibleStore[1]===29n &&
  first.inputBackwardStored[0]===31n && second.inputBackwardStored[0]===31n &&
  !second.context.logs.length && !second.context.metrics.has("private") &&
  first.context!==second.context && first.inputBackwardStored!==second.inputBackwardStored,
  "input आणि मोजणीचे स्वामित्व स्वतंत्र");
const hiddenOnly=patch06Prior(F,F,[],stored,1,7);
check(hiddenOnly.correctedValue===31n,"hidden साठी unrelated visible slot आवश्यक नाही");

// Preflight अपयश context, trace किंवा metrics बदलणार नाही.
const handler=new Patch06PriorHandler();
const raw=createMonsterContext(F,F);
check(rejects(()=>handler.run(raw,visible,stored,1,7),MonsterStageError) &&
  raw.status==="NEW" && !raw.branchTrace.length && !raw.metrics.size,
  "न तयार केलेला context अपरिवर्तित नाकारावा");
const ready=bootstrapMonster(F,F);
for(const [i,back] of [
  [0,1],[47,1],[1,2],[1,0],[1,8],[1,1.5],[NaN,1],[Infinity,1]
] as const) {
  check(rejects(()=>handler.run(ready,visible,stored,i,back as 1|3|7),MonsterValidationError),
    "अवैध i/back स्वीकारू नये");
}
for(const malformed of [
  [1n,2n],[1n,2n,3n,4n,5n,6n,7n,8n],
  [1n,2n,3n,4n,5n,6n,undefined],
  Object.assign(new Array<bigint>(7),{0:1n,1:2n,2:3n,4:5n,5:6n,6:7n}),
  [1n,2n,3n,4n,5n,6n,7 as unknown as bigint]
]) {
  check(rejects(()=>handler.run(ready,visible,malformed as bigint[],1,7),MonsterValidationError),
    "अवैध किंवा sparse hidden storage नाकारावा");
}
check(rejects(()=>handler.run(ready,[],stored,8,7),MonsterValidationError),
  "अनुपस्थित सकारात्मक visible slot नाकारावा");
check(rejects(()=>handler.run(ready,[undefined,1 as unknown as bigint],stored,2,1),
  MonsterValidationError),"सकारात्मक visible slot bigint असावा");
check(rejects(()=>handler.run(ready,{} as bigint[],stored,1,7),
  MonsterValidationError),"nonarray visible store");
check(rejects(()=>handler.run({...ready,targetDay:null as unknown as bigint},visible,stored,1,7),
  MonsterValidationError),"non-bigint context day");
check(ready.branchTrace.join(",")==="BOOTSTRAP_VALIDATE" &&
  ready.metrics.size===1 && ready.status==="VALIDATED",
  "अपयशी input नंतर context अपरिवर्तित");
handler.run(ready,visible,stored,1,7);
check(rejects(()=>handler.run(ready,visible,stored,2,1),MonsterStageError),
  "एकाच context वर पुन्हा call नको");

// आधीचे पाच patch आणि अंतिम Stage 54 चे प्रतिबंध बदललेले नाहीत.
check(patch01Save(F,F,3n*M).savedValue===SAVE(3n*M),"PATCH 01");
check(patch02DayTags(F,F+1n).target.correctedTag===3n,"PATCH 02");
check(patch03Distance(F-2n,F+2n).distance===workCounts(F-2n,F+2n).distance,"PATCH 03");
check(patch04Stones(F,F,2n,STONES[1]!).correctedStone.every((x,j)=>x===STONES[2]![j]),"PATCH 04");
check(patch05HiddenDrops(F,F,canonical).correctedReads.every((x,j)=>x===canonical[j]),"PATCH 05");
check(rejects(()=>calendarDateSpaghetti(F,F),MonsterStageError),"Stage 54 चे integration अजून नाही");

console.log(`STAGE_13_PATCH_06_GUARDS_PASS cases=${cases} hidden=${hiddenFallbacks} visible=${visibleLegacyCalls} mismatches=${mismatches}`);
