import {
  bootstrapMonster, calendarDateSpaghetti, createMonsterContext,
  discoverLegacyDistance, oldDistance, patch01Save, patch02DayTags,
  patch03Distance, Patch03DistanceHandler, MonsterStageError,
  MonsterValidationError
} from "../src/index.ts";
import { FOUNDATION_DAY as F, M, SAVE, workCounts } from "./normativeOracle.ts";

function check(value: boolean, message: string): void {
  if (!value) throw new Error(message);
}
function rejected(action: () => unknown, cls: typeof MonsterStageError | typeof MonsterValidationError): boolean {
  try { action(); } catch (error) { return error instanceof cls; }
  return false;
}
let pairs = 0;
let overrides = 0;
let preserved = 0;
let mismatches = 0;
const contexts = new Set<object>();

function verify(calculationDay: bigint, targetDay: bigint): void {
  const observation = patch03Distance(calculationDay, targetDay);
  const expected = workCounts(calculationDay, targetDay).distance;
  const difference = targetDay - calculationDay;
  const chronological = difference < 0n ? -difference : difference;
  const tags = patch02DayTags(calculationDay, targetDay);
  const tagDifference = tags.action.correctedTag - tags.target.correctedTag;
  const legacyExpected = tagDifference < 0n ? -tagDifference : tagDifference;
  const overrideExpected = legacyExpected !== chronological;

  pairs++;
  if (observation.distance !== expected) mismatches++;
  check(observation.distance === expected, "नियमाधारित अंतर चुकीचे आहे");
  check(observation.distance >= 1n, "अंतर 1 पेक्षा कमी असू शकत नाही");
  check(observation.calculationDay === calculationDay && observation.targetDay === targetDay,
    "दोन इनपुट दिवस बदलले जाऊ नयेत");
  check(observation.legacyDistance === legacyExpected, "जुना tag-अंतर पुरावा बदलला");
  check(observation.legacyDistance === oldDistance(calculationDay, targetDay), "ऐतिहासिक helper शी फरक");
  check(observation.chronologicalDistance === chronological, "खरे कालक्रम अंतर चुकीचे");
  check(observation.correctedDistanceBeforeOne === chronological, "तुलना-नंतरचे अंतर चुकीचे");
  check(observation.distance === observation.correctedDistanceBeforeOne + 1n, "शेवटचा +1 आवश्यक आहे");
  check(observation.legacyOverridden === overrideExpected, "जुन्या अंतराची तुलना चुकीची");
  check(Object.isFrozen(observation), "मूल्य-निरीक्षण frozen हवे");
  check(observation.context.phase === "READY" && observation.context.status === "PATCH_03_APPLIED",
    "संदर्भ जीवनचक्र चुकीचे");
  check(!contexts.has(observation.context), "आवाहनांमध्ये संदर्भ-विलगीकरण आवश्यक");
  contexts.add(observation.context);

  const expectedTrace = [
    "BOOTSTRAP_VALIDATE", "PATCH_03_LEGACY_TAG_DISTANCE",
    overrideExpected ? "PATCH_03_USE_CHRONOLOGICAL" : "PATCH_03_KEEP_LEGACY",
    "PATCH_03_PLUS_ONE"
  ];
  check(observation.context.branchTrace.join("|") === expectedTrace.join("|"), "शाखा-नोंद चुकीची");
  check(observation.context.metrics.get("bootstrap.calls") === 1n, "प्रारंभ मापन चुकीचे");
  check(observation.context.metrics.get("patch03.calls") === 1n, "दुरुस्तीची मोजणी चुकीची");
  check((observation.context.metrics.get("patch03.legacy_overridden") ?? 0n) ===
    (overrideExpected ? 1n : 0n), "बदली-मापन चुकीचे");
  check((observation.context.metrics.get("patch03.legacy_preserved") ?? 0n) ===
    (overrideExpected ? 0n : 1n), "जतन-मापन चुकीचे");
  if (overrideExpected) overrides++; else preserved++;
}

// पाच अचूक ऐतिहासिक साक्षी: Stage 06 मध्ये चार लाल, एक जुळणारी.
const witnesses = [
  [0n, 0n, 0n, 1n],
  [-1n, 0n, 1n, 2n],
  [-2n, 2n, 1n, 5n],
  [1n, 1n, 0n, 1n],
  [1n, 2n, 2n, 2n]
] as const;
for (const [c, t, oldResult, fixedResult] of witnesses) {
  verify(F + c, F + t);
  const oldObserved = discoverLegacyDistance(F + c, F + t);
  check(oldObserved.legacyDistance === oldResult, "Stage 06 लाल पुरावा गहाळ");
  check(patch03Distance(F + c, F + t).distance === fixedResult, "PATCH 03 सीमा-नमुना चुकला");
}

// उभय दिशांतील कालक्रम व पाया-दिवसाची उडी: 13×13.
for (let i = -6; i <= 6; i++) {
  for (let j = -6; j <= 6; j++) {
    verify(F + BigInt(i), F + BigInt(j));
  }
}

// अचूक महाकाय bigint, चिन्हे आणि 127/4096/16384 bit सीमा.
const huge = 1n << 16384n;
const deltas = [0n, 1n, -1n, 2n, -2n, 17n, -17n, M, -M,
  M + 1n, -(M + 1n), 1n << 4096n, -(1n << 4096n), huge, -huge];
for (const delta of deltas) {
  verify(F, F + delta);
  verify(F + delta, F);
  verify(F + delta, F - delta);
}

// निश्चित बीजापासून स्थानिकपणे व्युत्पन्न झालेल्या 512-bit जोड्या.
let state = 0x6a09e667f3bcc909n;
const mask = (1n << 512n) - 1n;
for (let i = 0; i < 1024; i++) {
  state = (state * 0x5851f42d4c957f2dn + 0x14057b7ef767814fn) & mask;
  const a = state - (1n << 511n);
  state = (state * 0x5851f42d4c957f2dn + 0x14057b7ef767814fn) & mask;
  const b = state - (1n << 511n);
  verify(F + a, F + b);
}

// अंतराची सममिती, समदिवस=1, आणि समान दिवस-स्थानांतर invariance.
for (const a of [-8n, -3n, -1n, 0n, 1n, 4n, 9n]) {
  for (const b of [-8n, -3n, 0n, 2n, 9n]) {
    const x = patch03Distance(F + a, F + b).distance;
    const y = patch03Distance(F + b, F + a).distance;
    const shifted = patch03Distance(F + a + 1000000n, F + b + 1000000n).distance;
    check(x === y && x === shifted, "सममिती / समान स्थानांतर नियम");
  }
  check(patch03Distance(F + a, F + a).distance === 1n, "समदिवसाचे अंतर 1");
}

const left = patch03Distance(F - 3n, F + 3n);
const right = patch03Distance(F + 3n, F - 3n);
left.context.logs.push("स्थानिक नोंद");
left.context.warnings.push("स्थानिक इशारा");
left.context.metrics.set("private", 101n);
check(right.context.logs.length === 0 && right.context.warnings.length === 0 &&
  !right.context.metrics.has("private"), "संदर्भांची mutable स्थिती मिसळते");

const handler = new Patch03DistanceHandler();
const unready = createMonsterContext(F, F);
check(rejected(() => handler.run(unready), MonsterStageError), "BOOTSTRAP संदर्भ नाकारावा");
check(unready.branchTrace.length === 0 && unready.metrics.size === 0, "अयशस्वी संदर्भात दुष्परिणाम नको");
const ready = bootstrapMonster(F, F);
check(rejected(() => handler.run({...ready, targetDay: 2 as unknown as bigint}), MonsterValidationError),
  "वैध स्थितीत अवैध bigint नाकारावा");
check(ready.status === "VALIDATED" && ready.branchTrace.length === 1, "अवैध प्रयत्नानंतर स्थिती जतन");
handler.run(ready);
check(rejected(() => handler.run(ready), MonsterStageError), "यशस्वी संदर्भ पुन्हा वापरू नये");
check(rejected(() => patch03Distance(0 as unknown as bigint, F), MonsterValidationError),
  "अवैध calculationDay");
check(rejected(() => patch03Distance(F, null as unknown as bigint), MonsterValidationError),
  "अवैध targetDay");

// आधीची दोन्ही दुरुस्त्या व अंतिम असमाविष्ट दिनांक-मार्ग अबाधित.
check(patch01Save(F, F, 3n * M).savedValue === SAVE(3n * M), "PATCH 01 बिघडली");
const patchedTags = patch02DayTags(F, F + 1n);
check(patchedTags.action.correctedTag === 1n && patchedTags.target.correctedTag === 3n,
  "PATCH 02 बिघडली");
check(rejected(() => calendarDateSpaghetti(F, F), MonsterStageError), "Stage 54 अकाली सुरू झाला");

check(pairs === 5 + 169 + 3 * deltas.length + 1024, "मोजलेल्या चाचणी-जोड्यांचा हिशेब");
check(overrides > 0 && preserved > 0 && mismatches === 0,
  "दोन्ही तुलना-शाखा व oracle जुळणी आवश्यक");
console.log(`STAGE_07_PATCH_03_PASS pairs=${pairs} overridden=${overrides} preserved=${preserved} mismatches=${mismatches}`);
