import {
  bootstrapMonster,
  createMonsterContext,
  LEGACY_MODULUS,
  MonsterStageError,
  MonsterValidationError,
  patch01Save,
  Patch01SaveHandler
} from "../src/index.ts";
import { FOUNDATION_DAY, M, SAVE } from "./normativeOracle.ts";

function check(condition: boolean, message: string): void {
  if (!condition) throw new Error(message);
}

function throwsExactly(action: () => void, cls: typeof MonsterStageError | typeof MonsterValidationError): boolean {
  try { action(); } catch (error) { return error instanceof cls; }
  return false;
}

check(LEGACY_MODULUS === M, "शेष आणि नियमाधारित M एकसमान असले पाहिजेत");

const values: bigint[] = [
  0n, -1n, 1n, 2n, -2n,
  -3n * M - 1n, -3n * M, -3n * M + 1n,
  -2n * M - 1n, -2n * M, -2n * M + 1n,
  -M - 1n, -M, -M + 1n,
  M - 1n, M, M + 1n,
  2n * M - 1n, 2n * M, 2n * M + 1n,
  3n * M - 1n, 3n * M, 3n * M + 1n,
  (1n << 4096n) + 17n, -((1n << 4096n) + 17n),
  M * (1n << 2048n), -M * (1n << 2048n)
];

for (let center = -3; center <= 3; center += 1) {
  for (let offset = -9; offset <= 9; offset += 1) {
    values.push(BigInt(center) * M + BigInt(offset));
  }
}

// ठरवलेल्या सुरुवातीपासून तयार झालेले 256-bit नमुने, प्रत्येक चाचणीत तेच अंक.
let state = 0x9e3779b97f4a7c15n;
const mask = (1n << 256n) - 1n;
for (let i = 0; i < 512; i += 1) {
  state = (state * 0x5851f42d4c957f2dn + 0x14057b7ef767814fn) & mask;
  values.push((i % 2 === 0 ? 1n : -1n) * state);
}

let repairs = 0;
let mismatches = 0;
let unchanged = 0;
let checked = 0;
let previousContext: ReturnType<typeof patch01Save>["context"] | null = null;

for (const value of values) {
  const answer = patch01Save(FOUNDATION_DAY, FOUNDATION_DAY + 1n, value);
  const expected = SAVE(value);
  checked++;
  if (answer.savedValue !== expected) mismatches++;
  check(answer.input === value, "मूळ पूर्णांक जतन झाला पाहिजे");
  check(answer.savedValue >= 1n && answer.savedValue <= M, "SAVE सीमा 1..M मधे राहिली पाहिजे");
  check(answer.savedValue === (answer.legacyValue === 0n ? M : answer.legacyValue), "दुरुस्ती केवळ 0→M असली पाहिजे");
  check(answer.repairedZero === (answer.legacyValue === 0n), "दुरुस्तीची नोंद बरोबर असावी");
  check(answer.context.phase === "READY" && answer.context.status === "PATCH_01_APPLIED", "जीवनचक्र स्थिती स्थिर असावी");
  check(answer.context.branchTrace.join(",") ===
    `BOOTSTRAP_VALIDATE,PATCH_01_LEGACY_REMAINDER,${answer.repairedZero ? "PATCH_01_ZERO_TO_M" : "PATCH_01_UNCHANGED"}`,
    "नियमाधारित शाखा अनुक्रमात चुकीचे टप्पे येऊ नयेत");
  check(answer.context.metrics.get("bootstrap.calls") === 1n, "प्रत्येक आवाहनाची प्रारंभिक मोजणी");
  check(answer.context.metrics.get("patch01.calls") === 1n, "प्रत्येक आवाहनाची दुरुस्ती मोजणी");
  check((answer.context.metrics.get("patch01.zero_repaired") ?? 0n) === (answer.repairedZero ? 1n : 0n), "प्रत्येक आवाहनाची दुरुस्ती-विशिष्ट मोजणी");
  if (previousContext !== null) {
    check(previousContext !== answer.context, "दोन आवाहनांत सामायिक mutable context नसावा");
  }
  previousContext = answer.context;
  if (answer.repairedZero) repairs++; else unchanged++;
}

check(mismatches === 0, "नियमाधारित SAVE विरुद्ध कोणताही फरक उरू नये");
check(repairs > 0 && unchanged > 0, "शून्य-दुरुस्ती आणि न-दुरुस्ती दोन्ही मार्ग झाकले गेले पाहिजेत");

// कितीही मोठ्या गुणकाने M ची भर घातल्याने SAVE बदलता कामा नये.
for (const input of [-M - 1n, -1n, 0n, 1n, M - 1n, M, M + 1n]) {
  for (const factor of [-1000000n, -2n, -1n, 0n, 1n, 2n, 1000000n]) {
    check(patch01Save(FOUNDATION_DAY, FOUNDATION_DAY, input + factor * M).savedValue === SAVE(input),
      "पूर्ण M गुणकांवर वर्ग बदलू नये");
  }
}

// अगदी निराळ्या दिवस-इनपुटवरही SAVE चा परिणाम तोच आणि मोजणी निराळी असावी.
const a = patch01Save(FOUNDATION_DAY - 99n, FOUNDATION_DAY + 3n, M);
const b = patch01Save(FOUNDATION_DAY + 100n, FOUNDATION_DAY - 2n, M);
check(a.savedValue === b.savedValue && a.savedValue === M, "दिवस-इनपुटने SAVE ची किंमत बदलू नये");
a.context.logs.push("फक्त पहिल्या संदर्भात");
a.context.warnings.push("फक्त पहिल्या संदर्भात");
a.context.metrics.set("private", 12n);
check(b.context.logs.length === 0 && b.context.warnings.length === 0 && !b.context.metrics.has("private"),
  "निरीक्षणीय स्थिती दुसऱ्या आवाहनात झिरपू नये");

// अपूर्ण/आधीच वापरलेल्या context ला दुरुस्ती मार्गाने स्वीकारू नये.
const handler = new Patch01SaveHandler();
const uninitialized = createMonsterContext(FOUNDATION_DAY, FOUNDATION_DAY);
check(throwsExactly(() => { handler.run(uninitialized, M); }, MonsterStageError), "प्रारंभिक अवस्था नाकारली पाहिजे");
check(uninitialized.branchTrace.length === 0, "अवैध अवस्थेचा शाखा-मागोवा बदलता कामा नये");

const ctx = bootstrapMonster(FOUNDATION_DAY, FOUNDATION_DAY);
check(throwsExactly(() => { handler.run(ctx, 1 as unknown as bigint); }, MonsterValidationError), "number इनपुट नाकारला पाहिजे");
check(ctx.status === "VALIDATED" && ctx.branchTrace.length === 1, "अवैध संख्येने context बदलू नये");
handler.run(ctx, M);
check(throwsExactly(() => { handler.run(ctx, 1n); }, MonsterStageError), "आधी दुरुस्त केलेल्या संदर्भाचा पुनर्वापर नको");
check(throwsExactly(() => { patch01Save(1 as unknown as bigint, 2n, M); }, MonsterValidationError), "गणना-दिवस bigint नसल्यास नाकारावा");
check(throwsExactly(() => { patch01Save(1n, 2 as unknown as bigint, M); }, MonsterValidationError), "लक्ष्य-दिवस bigint नसल्यास नाकारावा");

// जुना दोष अजून दिसतो; PATCH 01 ने इतिहास मागाहून बदलू नये.
const archival = patch01Save(FOUNDATION_DAY, FOUNDATION_DAY, 3n * M);
check(archival.legacyValue === 0n && archival.savedValue === M, "ऐतिहासिक शून्याचा पुरावा हरवू नये");

console.log(`STAGE_03_PATCH_01_PASS cases=${checked} repairs=${repairs} unchanged=${unchanged} mismatches=${mismatches}`);
