import {
  bootstrapMonster, createMonsterContext, Discovery04StoneHandler,
  discoverLegacyStoneMutation, LegacySequentialStoneAdapter,
  MonsterStageError, MonsterValidationError, patch01Save
} from "../src/index.ts";
import { FOUNDATION_DAY as F, M, SAVE, STONES } from "./normativeOracle.ts";

function check(ok: boolean, reason: string): void { if (!ok) throw new Error(reason); }
function throwsType(fn: () => unknown, cls: typeof MonsterStageError | typeof MonsterValidationError): boolean {
  try { fn(); } catch (e) { return e instanceof cls; }
  return false;
}

const original = STONES[1]!;
const normal = STONES[2]!;
const observed = discoverLegacyStoneMutation(F, F, 2n, original);
let mismatches = 0;
let matches = 0;
for (let k = 0; k < 5; k++) {
  if (observed.legacyStone[k] === normal[k]) matches++; else mismatches++;
  check(observed.legacyStone[k]! >= 1n && observed.legacyStone[k]! <= M, "SAVE श्रेणी चुकीची");
}
check(mismatches === 4 && matches === 1, "पहिल्या पाच दगडांत नेमके चार फरक हवेत");
check(observed.legacyStone[0] === normal[0], "जुना w क्रम पहिल्या स्थितीत योग्य राहतो");
check(original.every((v,k) => v === observed.inputStone[k]), "मूळ immutable दगड जतन झाले नाहीत");
check(Object.isFrozen(observed) && Object.isFrozen(observed.inputStone) &&
  Object.isFrozen(observed.legacyStone), "निरीक्षण immutable असावे");
check(observed.context.status === "DISCOVERY_04_RECORDED" && observed.context.phase === "READY",
  "संदर्भाचा योग्य दर्जा हवा");
check(observed.context.branchTrace.join(",") ===
  "BOOTSTRAP_VALIDATE,DISCOVERY_04_SEQUENTIAL_STONE_MUTATION", "मागोव्याचा क्रम चुकीचा");
check(observed.context.metrics.get("bootstrap.calls") === 1n &&
  observed.context.metrics.get("discovery04.calls") === 1n &&
  observed.context.metrics.get("discovery04.stones_written") === 5n, "मोजणी चुकीची");

const mutation = new LegacySequentialStoneAdapter();
const mutable = [...original] as [bigint,bigint,bigint,bigint,bigint];
const alias = mutation.mutateStonesWrong(2n, mutable, F, F);
check(alias === mutable, "मूळ जुनी क्रिया in-place असली पाहिजे");
check(mutable.every((v,k) => v === observed.legacyStone[k]), "थेट mutation आणि production discovery वेगळे");
check(observed.inputStone.every((v,k) => v === original[k]), "बाह्य input बदलता कामा नये");

// संपूर्ण 46-पायरी इतिहास: नवीन दगड मागील चुकीच्या दगडांवर आधारित आहे.
let legacy = [...original] as [bigint,bigint,bigint,bigint,bigint];
let divergentSteps = 0;
let divergentCells = 0;
for (let step=2; step<=46; step++) {
  mutation.mutateStonesWrong(BigInt(step), legacy, F, F);
  let differences=0;
  for (let k=0;k<5;k++) if (legacy[k] !== STONES[step]![k]) differences++;
  if (differences > 0) divergentSteps++;
  divergentCells += differences;
}
check(divergentSteps === 45 && divergentCells >= 4, "संपूर्ण ऐतिहासिक साखळीने फरक दाखवला नाही");

// योग्य SAVE पुनर्वापरून इतर भूतकाळातील दुरुस्त्या कायम आहेत.
check(patch01Save(F,F,3n*M).savedValue === SAVE(3n*M), "पहिली SAVE दुरुस्ती बिघडली");
const raw = createMonsterContext(F,F);
const handler = new Discovery04StoneHandler();
check(throwsType(() => handler.run(raw,2n,original),MonsterStageError),
  "BOOTSTRAP मधील संदर्भ नाकारावा");
check(raw.branchTrace.length===0 && raw.metrics.size===0, "अवैध अवस्थेने mutation नको");
const ready=bootstrapMonster(F,F);
handler.run(ready,2n,original);
check(throwsType(() => handler.run(ready,2n,original),MonsterStageError),
  "आधी वापरलेला संदर्भ नाकारावा");
check(throwsType(() => discoverLegacyStoneMutation(F,F,1n,original),MonsterValidationError),
  "मर्यादेबाहेरचा निर्देशांक नाकारावा");
check(throwsType(() => discoverLegacyStoneMutation(F,F,2n,[1n,2n]),MonsterValidationError),
  "पाचपेक्षा कमी मूल्ये नाकारावीत");
check(throwsType(() => discoverLegacyStoneMutation(F,F,2n,[1n,2n,3n,4n,5 as unknown as bigint]),
  MonsterValidationError), "अवैध मूल्य नाकारावे");

console.log(`STAGE_08_DISCOVERY_04_GUARDS_PASS mismatches=${mismatches} matches=${matches} divergentSteps=${divergentSteps}`);
