import {
  bootstrapMonster, createMonsterContext, LegacyBackwardHiddenAdapter,
  discoverLegacyHiddenStorage, MonsterStageError, MonsterValidationError,
  Patch05HiddenHandler, patch05HiddenDrops, patch01Save, patch02DayTags,
  patch03Distance, patch04Stones, calendarDateSpaghetti
} from "../src/index.ts";
import {
  FOUNDATION_DAY as F, STONES, M, SAVE, workCounts, buildHiddenDrops
} from "./normativeOracle.ts";

function ensure(condition: boolean, message: string): void {
  if (!condition) throw Error(message);
}
function rejected(f: () => unknown, errorType: typeof MonsterStageError | typeof MonsterValidationError): boolean {
  try { f(); } catch (error) { return error instanceof errorType; }
  return false;
}
const adapter = new LegacyBackwardHiddenAdapter();
const handler = new Patch05HiddenHandler();
const contexts = new Set<object>();
let oracleCases = 0, oracleSlots = 0, oracleMismatches = 0, oracleMatches = 0;

function getOracle(c: bigint, t: bigint): readonly bigint[] {
  const values = buildHiddenDrops(workCounts(c,t),STONES);
  return Object.freeze(Array.from({length:7}, (_, j) => values[j+1]!));
}
function verify(c: bigint, t: bigint): void {
  const actual = getOracle(c,t);
  const before = [...actual];
  const observation = patch05HiddenDrops(c,t,actual);
  const previous = discoverLegacyHiddenStorage(c,t,actual);
  ensure(!contexts.has(observation.context),"नवीन context आवश्यक");
  contexts.add(observation.context);
  ensure(observation.calculationDay === c && observation.targetDay === t,"दिनांक स्वामित्व");
  ensure(Object.isFrozen(observation) && Object.isFrozen(observation.sourceInCanonicalOrder) &&
    Object.isFrozen(observation.backwardStored) && Object.isFrozen(observation.legacyReads) &&
    Object.isFrozen(observation.correctedReads) && Object.isFrozen(observation.correctedSlotsOneBased),
    "निरीक्षण आणि यादी immutable असाव्यात");
  ensure(observation.context.status === "PATCH_05_APPLIED" && observation.context.phase==="READY",
    "दुरुस्त संदर्भाचा lifecycle");
  ensure(observation.context.branchTrace.join("|")===[
    "BOOTSTRAP_VALIDATE","PATCH_05_LEGACY_STORE_HIDDEN_7_TO_1",
    "PATCH_05_REAL_LEGACY_READS","PATCH_05_CORRECTED_SLOT_8_MINUS_K"
  ].join("|"),"मूलभूत branchTrace बदलला");
  ensure(observation.context.metrics.get("bootstrap.calls")===1n &&
    observation.context.metrics.get("patch05.calls")===1n &&
    observation.context.metrics.get("patch05.legacy_reads")===7n &&
    observation.context.metrics.get("patch05.corrected_reads")===7n,"दुरुस्ती मोजणी");
  ensure(observation.backwardStored !== observation.sourceInCanonicalOrder &&
    previous.backwardStored !== observation.backwardStored,
    "storage आणि input चे प्रत स्वतंत्र हवेत");
  let repaired = 0;
  for(let k=1;k<=7;k++){
    const slot=k-1;
    oracleSlots++;
    ensure(actual[slot]===before[slot] && observation.sourceInCanonicalOrder[slot]===before[slot],
      "कॉलरचे मूळ थेंब न बदलणे");
    ensure(observation.backwardStored[slot]===before[7-k],"hidden storage उलटे राहावे");
    ensure(observation.correctedSlotsOneBased[slot]===8-k,"1-based corrected slot 8-k");
    ensure(observation.legacyReads[slot]===adapter.oldHiddenAt(observation.backwardStored,k) &&
      observation.legacyReads[slot]===previous.legacyReads[slot],
      "ऐतिहासिक वाचक प्रत्यक्ष कायम आहे");
    ensure(observation.correctedReads[slot]===handler.correctedHiddenAt(observation.backwardStored,k) &&
      observation.correctedReads[slot]===before[slot],
      "corrected index 7-k ने नेमकी नियमाधारित hidden k परत द्यावी");
    if(observation.legacyReads[slot]===observation.correctedReads[slot])oracleMatches++;
    else {repaired++;oracleMismatches++;}
  }
  ensure(observation.mismatchesRepaired===repaired &&
    (observation.context.metrics.get("patch05.legacy_mismatches")??0n)===BigInt(repaired),
    "जुन्या व नव्या वाचकांमधील फरकांची संख्या चुकीची");
  oracleCases++;
}

// पहिल्या साक्षीमध्ये hidden4 स्थिर; इतर सहा मुद्दाम चुकीच्या ठिकाणी.
verify(F,F);
ensure(oracleCases===1 && oracleMismatches===6 && oracleMatches===1,
  "पहिल्या ऐतिहासिक साक्षीचा 6:1 परिणाम");
for(const [c,t] of [
  [F-3n,F+1n],[F-1n,F],[F,F+1n],[F+1n,F-1n],
  [F+7n,F+19n],[F-31n,F-20n],[F+64n,F-77n],[F+123n,F+123n]
] as const) verify(c,t);

// दिवस-सममितीच्या वेगवेगळ्या भागांतून 96 आणखी स्वतंत्र वास्तविक oracle प्रयोग.
for(let i=0;i<96;i++){
  const c=F+BigInt((i*101)%307-153);
  const t=F+BigInt((i*67)%419-209);
  verify(c,t);
}
ensure(oracleCases===105 && oracleSlots===735 && oracleMismatches+oracleMatches===735,
  "normative 105 दिवस-जोड्यांचा हिशेब");
ensure(oracleMismatches>0 && oracleMatches>0,"दोन्ही legacy शाखा चाचणीत हव्यात");

// प्रत्यक्ष storage आणि oldHiddenAt यांना कधीही सरळ करू नये.
const sentinel=Object.freeze([11n,13n,17n,19n,23n,29n,31n] as const);
const inputCopy=[...sentinel];
const obs=patch05HiddenDrops(F,F,sentinel);
ensure(obs.backwardStored.join(",")==="31,29,23,19,17,13,11","उलटे storage बदलले");
ensure(obs.legacyReads.join(",")==="31,29,23,19,17,13,11","जुना वाचक चुकीचाच हवा");
ensure(obs.correctedReads.join(",")==="11,13,17,19,23,29,31","नव्या वाचकाचा क्रम चुकीचा");
ensure(obs.mismatchesRepaired===6,"मधल्या hidden4 वर बदल नाही");
ensure(sentinel.every((v,k)=>v===inputCopy[k]),"input बदलू नये");
ensure(handler.correctedHiddenAt(obs.backwardStored,4)===19n &&
  adapter.oldHiddenAt(obs.backwardStored,1)===31n,
  "मध्यभागी योग्य, जुन्या reader मध्ये दोष");

const a=patch05HiddenDrops(F,F,sentinel),b=patch05HiddenDrops(F,F,sentinel);
a.context.logs.push("स्वतंत्र");a.context.warnings.push("फक्त पहिले");a.context.metrics.set("personal",29n);
ensure(!b.context.logs.length && !b.context.warnings.length &&
  !b.context.metrics.has("personal") && a.context!==b.context &&
  a.backwardStored!==b.backwardStored,"आवाहनांची mutable स्थिती एकमेकांत गेली");

// संदर्भ life-cycle आणि अवैध argument यांना पूर्व-पडताळणी.
const unready=createMonsterContext(F,F);
ensure(rejected(()=>handler.run(unready,sentinel),MonsterStageError),"unready context स्वीकारला");
ensure(unready.status==="NEW" && unready.metrics.size===0 && unready.branchTrace.length===0,
  "अवैध context वापरून mutation झाले");
const ready=bootstrapMonster(F,F);
for(const invalid of [
  [1n,2n],[1n,2n,3n,4n,5n,6n,7n,8n],
  [1n,2n,3n,4n,5n,6n,"bad" as unknown as bigint],
  [1n,2n,3n,4n,5n,6n,undefined as unknown as bigint],
  Object.assign(new Array<bigint>(7),{0:1n,1:2n,2:3n,4:5n,5:6n,6:7n})
]){
  ensure(rejected(()=>handler.run(ready,invalid),MonsterValidationError),"अपूर्ण व चुकीचे input");
}
ensure(rejected(()=>handler.run({...ready,calculationDay:null as unknown as bigint},sentinel),
  MonsterValidationError),"बाहेरील context चा अवैध दिवस");
ensure(ready.status==="VALIDATED" && ready.metrics.size===1 &&
  ready.branchTrace.join(",")==="BOOTSTRAP_VALIDATE",
  "अयशस्वी input ने तयार context बदलला");
handler.run(ready,sentinel);
ensure(rejected(()=>handler.run(ready,sentinel),MonsterStageError),"एक context दोनदा वापरू नये");

const back=adapter.storeBackward(sentinel);
for(const invalidK of [0,8,-1,1.5,NaN,Infinity,"1" as unknown as number]){
  ensure(rejected(()=>handler.correctedHiddenAt(back,invalidK),MonsterValidationError),
    "दुरुस्त वाचकाने अवैध hidden k नाकारावे");
}
for(const bad of [[1n,2n],new Array<bigint>(7),[1n,2n,3n,4n,5n,6n,7 as unknown as bigint]]){
  ensure(rejected(()=>handler.correctedHiddenAt(bad,1),MonsterValidationError),
    "दुरुस्त वाचकाने अवैध storage नाकारावे");
}

// पूर्वीच्या PATCH आणि Stage 54 ची सीमा.
ensure(patch01Save(F,F,3n*M).savedValue===SAVE(3n*M),"PATCH 01");
ensure(patch02DayTags(F,F+1n).target.correctedTag===3n,"PATCH 02");
ensure(patch03Distance(F-2n,F+2n).distance===workCounts(F-2n,F+2n).distance,"PATCH 03");
ensure(patch04Stones(F,F,2n,STONES[1]!).correctedStone.every((v,k)=>v===STONES[2]![k]),
  "PATCH 04");
ensure(rejected(()=>calendarDateSpaghetti(F,F),MonsterStageError),"Stage 54 अकाली सुरू झाला");
console.log(`STAGE_11_PATCH_05_ORACLE_PASS cases=${oracleCases} slots=${oracleSlots} legacyDifferences=${oracleMismatches} legacyMatches=${oracleMatches} mismatches=0`);
