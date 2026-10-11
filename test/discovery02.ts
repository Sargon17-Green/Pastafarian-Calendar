import {
  bootstrapMonster, createMonsterContext, discoverLegacyDayTags,
  Discovery02DayTagHandler, LegacyDayTagAdapter, LEGACY_FOUNDATION_DAY,
  MonsterStageError, MonsterValidationError, patch01Save
} from "../src/index.ts";
import { FOUNDATION_DAY, M, SAVE, dayCount } from "./normativeOracle.ts";

function check(condition: boolean, message: string): void { if (!condition) throw new Error(message); }
function rejects(work: () => unknown, kind: typeof MonsterStageError | typeof MonsterValidationError): boolean {
  try { work(); } catch (e) { return e instanceof kind; }
  return false;
}
const F = FOUNDATION_DAY;
check(LEGACY_FOUNDATION_DAY === F, "ऐतिहासिक पाया-दिवस नियमाधारित पाया-दिवसाशी जुळला पाहिजे");

const witnesses = [
  [F - 2n, 4n, 4n], [F - 1n, 2n, 2n], [F, 0n, 1n],
  [F + 1n, 2n, 3n], [F + 2n, 4n, 5n]
] as const;
let mismatches = 0;
let matches = 0;
const contexts = [];
for (const [day, legacy, normative] of witnesses) {
  const o = discoverLegacyDayTags(day, day);
  check(o.calculationDay === day && o.targetDay === day, "मूळ दिवस बदलता कामा नये");
  check(o.legacyActionTag === legacy && o.legacyTargetTag === legacy, "दोन्ही ऐतिहासिक दिवस-चिन्हे अपेक्षित हवीत");
  check(dayCount(day) === normative, "नियमाधारित दिवस-नमुना अपेक्षित हवा");
  if (o.legacyActionTag === normative) matches++; else mismatches++;
  check(o.context.phase === "READY" && o.context.status === "DISCOVERY_02_RECORDED", "संदर्भ जीवनचक्र योग्य पाहिजे");
  check(o.context.branchTrace.join(",") === "BOOTSTRAP_VALIDATE,DISCOVERY_02_LEGACY_DAY_TAG", "शाखा-क्रम चुकीचा आहे");
  check(o.context.metrics.get("bootstrap.calls") === 1n, "प्रारंभ मापन गहाळ");
  check(o.context.metrics.get("discovery02.calls") === 1n, "दुसऱ्या शोधाची मोजणी गहाळ");
  check(o.context.metrics.get("discovery02.days") === 2n, "दोन दिवसांची मोजणी गहाळ");
  contexts.push(o.context);
}
check(mismatches === 3 && matches === 2, "नेमके तीन फरक आणि दोन जुळण्या हव्यात");

const forward = discoverLegacyDayTags(F - 7n, F + 12n);
const backward = discoverLegacyDayTags(F + 12n, F - 7n);
check(forward.legacyActionTag === 14n && forward.legacyTargetTag === 24n, "कर्म-दिवस व प्रश्न-दिवस वेगळे मोजावेत");
check(backward.legacyActionTag === 24n && backward.legacyTargetTag === 14n, "उलट दिवसांची ओळख राखावी");

const adapter = new LegacyDayTagAdapter();
const huge = (1n << 4096n) + 121n;
for (const delta of [0n, 1n, 2n, 13n, M, huge]) {
  check(adapter.oldDayTag(F - delta) === 2n * delta, "ऋण अंतराची ऐतिहासिक गणना बरोबर नाही");
  check(adapter.oldDayTag(F + delta) === 2n * delta, "धन अंतराची ऐतिहासिक गणना बरोबर नाही");
  check(dayCount(F + delta) === 2n * delta + 1n, "पाया-दिवसानंतरचा नियमाधारित नमुना बरोबर नाही");
  if (delta !== 0n) check(dayCount(F - delta) === 2n * delta, "पाया-दिवसाआधीचा नियमाधारित नमुना बरोबर नाही");
}

check(new Set(contexts).size === 5, "प्रत्येक आवाहनासाठी वेगळा संदर्भ हवा");
contexts[0]!.logs.push("खाजगी नोंद");
contexts[0]!.warnings.push("खाजगी इशारा");
contexts[0]!.metrics.set("private", 99n);
check(contexts[1]!.logs.length === 0 && contexts[1]!.warnings.length === 0 && !contexts[1]!.metrics.has("private"),
  "संदर्भांचे निरीक्षण परस्पर मिसळता कामा नये");

const handler = new Discovery02DayTagHandler();
const raw = createMonsterContext(F, F);
check(rejects(() => handler.run(raw), MonsterStageError), "तयार नसलेला संदर्भ नाकारावा");
check(raw.branchTrace.length === 0 && raw.metrics.size === 0, "नाकारलेल्या संदर्भात बदल नको");
const valid = bootstrapMonster(F, F);
handler.run(valid);
check(rejects(() => handler.run(valid), MonsterStageError), "दुसऱ्या वापराला मज्जाव हवा");
check(rejects(() => adapter.oldDayTag(42 as unknown as bigint), MonsterValidationError), "अवैध दिवस नाकारावा");
check(rejects(() => discoverLegacyDayTags(42 as unknown as bigint, F), MonsterValidationError), "अवैध पहिला दिवस नाकारावा");
check(rejects(() => discoverLegacyDayTags(F, "42" as unknown as bigint), MonsterValidationError), "अवैध दुसरा दिवस नाकारावा");

const patch01 = patch01Save(F, F + 1n, M);
check(patch01.savedValue === SAVE(M) && patch01.context.status === "PATCH_01_APPLIED", "पूर्वीची PATCH 01 सुधारणा कायम हवी");
console.log(`STAGE_04_DISCOVERY_02_GUARDS_PASS mismatches=${mismatches} matches=${matches} cases=${witnesses.length}`);
