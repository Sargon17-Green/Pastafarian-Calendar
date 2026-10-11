import {
  bootstrapMonster, createMonsterContext, Discovery05HiddenHandler,
  LegacyBackwardHiddenAdapter, discoverLegacyHiddenStorage, MonsterStageError,
  MonsterValidationError, patch01Save, patch02DayTags, patch03Distance,
  patch04Stones, calendarDateSpaghetti
} from "../src/index.ts";
import {
  FOUNDATION_DAY as F, STONES, M, SAVE, workCounts, buildHiddenDrops
} from "./normativeOracle.ts";

function check(ok: boolean, why: string): void {
  if (!ok) throw new Error(why);
}
function rejects(fn: () => unknown, errorType: typeof MonsterStageError | typeof MonsterValidationError): boolean {
  try { fn(); } catch (error) { return error instanceof errorType; }
  return false;
}
const adapter = new LegacyBackwardHiddenAdapter();
let oracleCases = 0;
let oracleMismatches = 0;
let oracleMatches = 0;
const trackedContexts = new Set<object>();

function hiddenFromOracle(c: bigint, t: bigint): readonly bigint[] {
  const hidden = buildHiddenDrops(workCounts(c,t), STONES);
  return Object.freeze(Array.from({ length: 7 }, (_, j) => hidden[j + 1]!));
}
function checkOracle(c: bigint, t: bigint): void {
  const expected = hiddenFromOracle(c,t);
  const observation = discoverLegacyHiddenStorage(c,t,expected);
  check(!trackedContexts.has(observation.context), "प्रत्येक आवाहनाला स्वतंत्र संदर्भ हवा");
  trackedContexts.add(observation.context);
  check(observation.calculationDay === c && observation.targetDay === t, "दोन दिवस बदलले");
  check(Object.isFrozen(observation) && Object.isFrozen(observation.sourceInCanonicalOrder) &&
    Object.isFrozen(observation.backwardStored) && Object.isFrozen(observation.legacyReads),
    "निरीक्षण आणि साठवण immutable असावेत");
  check(observation.context.phase === "READY" &&
    observation.context.status === "DISCOVERY_05_RECORDED", "लपवलेल्या थेंबांचे संदर्भ जीवनचक्र");
  check(observation.context.branchTrace.join(",") ===
    "BOOTSTRAP_VALIDATE,DISCOVERY_05_STORE_HIDDEN_7_TO_1,DISCOVERY_05_READ_UNCORRECTED_SLOTS",
    "जुन्या साठवणीचा शाखा-मागोवा");
  check(observation.context.metrics.get("bootstrap.calls") === 1n &&
    observation.context.metrics.get("discovery05.calls") === 1n &&
    observation.context.metrics.get("discovery05.hidden_stored") === 7n &&
    observation.context.metrics.get("discovery05.legacy_reads") === 7n,
    "प्रत्येक आवाहनातील नोंदणी");

  for(let k=1;k<=7;k++){
    const normal=expected[k-1]!;
    check(observation.sourceInCanonicalOrder[k-1]===normal, "नियमाधारित क्रम जतन");
    check(observation.backwardStored[k-1]===expected[7-k], "hidden7..hidden1 उलटा storage नाही");
    check(observation.legacyReads[k-1]===observation.backwardStored[k-1],
      "जुना सामान्य slot वापरच हवा");
    check(adapter.oldHiddenAt(observation.backwardStored,k)===observation.legacyReads[k-1],
      "संग्राहक व निरीक्षण यांची legacy वाचणे जुळावे");
    if(normal===observation.legacyReads[k-1])oracleMatches++;else oracleMismatches++;
  }
  oracleCases++;
}

// सविस्तर पहिली oracle साक्ष. 7 स्वतंत्र थेंबांमुळे 6 mismatches आणि मध्यभागी 1 match.
checkOracle(F,F);
check(oracleMismatches===6 && oracleMatches===1, "पहिली oracle साक्ष नेमकी 6:1 असावी");
for(const [c,t] of [[F-3n,F+1n],[F-1n,F],[F,F+1n],
                       [F+1n,F-1n],[F+7n,F+19n],[F-31n,F-20n],
                       [F+64n,F-77n],[F+123n,F+123n]] as const) {
  checkOracle(c,t);
}
check(oracleCases===9, "नऊ oracle प्रकरणे आवश्यक");

const sentinel = Object.freeze([11n,13n,17n,19n,23n,29n,31n] as const);
const pristine=[...sentinel];
const storage=adapter.storeBackward(sentinel);
check(storage.join(",")==="31,29,23,19,17,13,11", "सात वस्तूंचा storage प्रत्यक्ष उलटा हवा");
check(Object.isFrozen(storage) && Object.isFrozen(sentinel), "मूळ व जुना storage frozen");
check(sentinel.every((v,k)=>v===pristine[k]), "कॉलरचा input बदलू नये");
check(adapter.oldHiddenAt(storage,1)===31n && adapter.oldHiddenAt(storage,7)===11n,
  "legacy accessor ने चुकीचाच indexed slot वाचावा");

const first=discoverLegacyHiddenStorage(F,F,sentinel);
const second=discoverLegacyHiddenStorage(F,F,sentinel);
first.context.logs.push("पहिल्याचा log");
first.context.warnings.push("पहिल्याची सूचना");
first.context.metrics.set("private",87n);
check(second.context.logs.length===0 && second.context.warnings.length===0 &&
  !second.context.metrics.has("private"),"दोन वेगळ्या आवाहनांची स्थिती मिसळली");
check(first.backwardStored!==second.backwardStored && first.context!==second.context,
  "नवीन आवाहनाला स्वतंत्र मालकी");

const handler=new Discovery05HiddenHandler();
const unready=createMonsterContext(F,F);
check(rejects(()=>handler.run(unready,sentinel),MonsterStageError),"BOOTSTRAP संदर्भ नाकारावा");
check(unready.status==="NEW" && unready.metrics.size===0 && unready.branchTrace.length===0,
  "अयशस्वी context वर दुष्परिणाम नको");
const ready=bootstrapMonster(F,F);
for(const bad of [
  [1n,2n], [1n,2n,3n,4n,5n,6n,7n,8n],
  [1n,2n,3n,4n,5n,6n,7 as unknown as bigint],
  Array.from({length:7},(_,k)=>k===3 ? undefined as unknown as bigint:BigInt(k)),
  Object.assign(Array(7),{0:1n,1:2n,2:3n,4:5n,5:6n,6:7n}) as bigint[]
]) {
  check(rejects(()=>handler.run(ready,bad),MonsterValidationError),
    "अपूर्ण, गैर-bigint किंवा अवैध लांबी नाकारली पाहिजे");
}
check(ready.status==="VALIDATED" && ready.branchTrace.join(",")==="BOOTSTRAP_VALIDATE" &&
  ready.metrics.size===1,"अवैध डेटा संदर्भ बदलू नये");
check(rejects(()=>handler.run({...ready,targetDay:"not bigint" as unknown as bigint},sentinel),
  MonsterValidationError),"संदर्भातील अवैध दिवस नाकारावा");
handler.run(ready,sentinel);
check(rejects(()=>handler.run(ready,sentinel),MonsterStageError),
  "वापरलेला संदर्भ पुन्हा स्वीकारू नये");
for(const invalidK of [0,8,-1,1.5,NaN,Infinity]) {
  check(rejects(()=>adapter.oldHiddenAt(storage,invalidK),MonsterValidationError),
    "जुन्या slot कडे बेकायदा निर्देशांक");
}

// Stage 1–9: PATCH 01–04 व अजून-अनुपलब्ध अंतिम तारखेचा मार्ग जतन.
check(patch01Save(F,F,3n*M).savedValue===SAVE(3n*M),"PATCH 01");
check(patch02DayTags(F,F+1n).target.correctedTag===3n,"PATCH 02");
check(patch03Distance(F-2n,F+2n).distance===workCounts(F-2n,F+2n).distance,"PATCH 03");
const firstStones=patch04Stones(F,F,2n,STONES[1]!);
check(firstStones.correctedStone.every((v,k)=>v===STONES[2]![k]),"PATCH 04");
check(rejects(()=>calendarDateSpaghetti(F,F),MonsterStageError),"Stage 54 लवकर चालू नये");
console.log(`STAGE_10_DISCOVERY_05_GUARDS_PASS firstMismatches=6 firstMatches=1 oracleCases=${oracleCases} oracleMismatches=${oracleMismatches} oracleMatches=${oracleMatches}`);
