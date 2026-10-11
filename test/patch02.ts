import {
  bootstrapMonster, calendarDateSpaghetti, createMonsterContext,
  discoverLegacyDayTags, LEGACY_FOUNDATION_DAY, LegacyDayTagAdapter,
  MonsterStageError, MonsterValidationError, patch01Save,
  patch02DayTags, Patch02DayTagHandler
} from "../src/index.ts";
import type { Patch02DayEvidence } from "../src/index.ts";
import { FOUNDATION_DAY, M, SAVE, dayCount } from "./normativeOracle.ts";

function check(condition: boolean, message: string): void {
  if (!condition) throw new Error(message);
}
function rejects(work: () => unknown, cls: typeof MonsterStageError | typeof MonsterValidationError): boolean {
  try { work(); } catch (error) { return error instanceof cls; }
  return false;
}

const F = FOUNDATION_DAY;
check(F === LEGACY_FOUNDATION_DAY, "पाया-दिवस स्थिरांक एकच हवा");
let cases = 0, days = 0, increments = 0, scars = 0, forced = 0, mismatches = 0;
const contexts = new Set<object>();

function checkDay(v: Patch02DayEvidence, d: bigint): void {
  days++;
  const old = 2n * (d >= F ? d - F : F - d);
  check(Object.isFrozen(v), "दिवसाचा निष्कर्ष frozen हवा");
  check(v.inputDay === d && v.legacyTag === old, "ऐतिहासिक मूल्य बदलू नये");
  if (v.correctedTag !== dayCount(d)) mismatches++;
  check(v.correctedTag === dayCount(d) && v.correctedTag >= 1n, "नियमाधारित दिवस-चिन्ह चुकीचे आहे");
  check(v.incremented === (d >= F), "आवश्यक +1 सीमा चुकीची");
  check(v.foundationScarChecked === (d === F), "इतिहासातील scar तपासणी चुकीची");
  check(!v.foundationScarForced, "बरोबर अंकगणितात scar कृती निष्प्रभावी पाहिजे");
  check(v.correctedTag === v.legacyTag + (d >= F ? 1n : 0n), "एकमेव अंकगणित बदल +1 हवा");
  increments += Number(v.incremented);
  scars += Number(v.foundationScarChecked);
  forced += Number(v.foundationScarForced);
}
function trace(role: "ACTION"|"TARGET", day: Patch02DayEvidence): string[] {
  return [
    `PATCH_02_${role}_${day.incremented ? "PLUS_ONE" : "UNCHANGED"}`,
    ...(day.foundationScarChecked ? [`PATCH_02_${role}_FOUNDATION_SCAR_CHECK`] : [])
  ];
}
function verifyPair(a: bigint, b: bigint): void {
  const v = patch02DayTags(a,b);
  cases++;
  check(!contexts.has(v.context), "प्रत्येक आवाहनाला स्वतंत्र context हवा");
  contexts.add(v.context);
  check(Object.isFrozen(v), "निरीक्षण-वस्तू frozen हवी");
  check(v.calculationDay === a && v.targetDay === b, "दोन दिवसांची ओळख जतन करावी");
  checkDay(v.action,a);
  checkDay(v.target,b);
  const wanted = ["BOOTSTRAP_VALIDATE","PATCH_02_LEGACY_DAY_TAG",...trace("ACTION",v.action),...trace("TARGET",v.target)];
  check(v.context.branchTrace.join(",") === wanted.join(","), "branchTrace क्रम चुकीचा");
  check(v.context.phase === "READY" && v.context.status === "PATCH_02_APPLIED", "संदर्भ जीवनचक्र चुकले");
  check(v.context.metrics.get("bootstrap.calls") === 1n && v.context.metrics.get("patch02.calls") === 1n,
    "संदर्भाची प्रति-आवाहन मोजणी चुकली");
  check(v.context.metrics.get("patch02.days_evaluated") === 2n, "दोन्ही दिवसांची मोजणी पाहिजे");
  check((v.context.metrics.get("patch02.plus_one") ?? 0n) === BigInt(Number(a >= F)+Number(b >= F)),
    "पुढील दिवसांची मोजणी चुकीची");
  check((v.context.metrics.get("patch02.scar_checked") ?? 0n) === BigInt(Number(a === F)+Number(b === F)),
    "scar मापन चुकीचे");
  check(!v.context.metrics.has("patch02.scar_forced"), "निष्प्रभावी scar अयोग्यरीत्या सक्रिय");
}

// पाया-दिवसाच्या दोन्ही बाजूंवर प्रत्येक गणना-दिवस × प्रत्येक प्रश्न-दिवस.
for (const a of [-5n,-2n,-1n,0n,1n,2n,5n]) {
  for (const b of [-5n,-2n,-1n,0n,1n,2n,5n]) verifyPair(F+a,F+b);
}
const huge = (1n << 4096n) + 121n;
for (const d of [0n,1n,-1n,2n,-2n,123n,-123n,M,-M,huge,-huge,1n<<16384n,-(1n<<16384n)]) {
  verifyPair(F+d,F-d);
  verifyPair(F-d,F+d);
}

// स्वतःच्या निश्चित बीजापासून बनवलेले 1024 जोडी-नमुने.
let state = 0x8a5cd789635d2c7bn;
const mask = (1n << 512n) - 1n;
for (let i=0;i<1024;i++) {
  state=(state*0x5851f42d4c957f2dn+0x14057b7ef767814fn)&mask;
  const a=state-(1n<<511n);
  state=(state*0x5851f42d4c957f2dn+0x14057b7ef767814fn)&mask;
  const b=state-(1n<<511n);
  verifyPair(F+a,F+b);
}

// जुन्या सदोष API चा इतिहास आणि नवीन सुधारित API एकाच वेळी तपासा.
const legacy=new LegacyDayTagAdapter();
check(legacy.oldDayTag(F)===0n && legacy.oldDayTag(F+1n)===2n, "जुना ऐतिहासिक दोष बदलला");
const old=discoverLegacyDayTags(F,F+1n);
const fixed=patch02DayTags(F,F+1n);
check(old.legacyActionTag===0n && old.legacyTargetTag===2n, "जुना discovery API बदलला");
check(fixed.action.correctedTag===1n && fixed.target.correctedTag===3n, "दुरुस्त सीमांकन चुकीचे");
check(fixed.action.foundationScarChecked && !fixed.target.foundationScarChecked, "दोन स्वतंत्र scar मार्ग हवेत");

// वेगळ्या कॉलचा metrics / logs / warnings वर परिणाम होऊ नये.
const left=patch02DayTags(F-3n,F+5n);
const right=patch02DayTags(F+5n,F-3n);
left.context.logs.push("फक्त पहिली नोंद");
left.context.warnings.push("फक्त पहिली सूचना");
left.context.metrics.set("private",91n);
check(right.context.logs.length===0 && right.context.warnings.length===0 && !right.context.metrics.has("private"),
  "mutable निरीक्षण दुसऱ्या आवाहनात वाहू नये");

const handler=new Patch02DayTagHandler();
const fresh=createMonsterContext(F,F);
check(rejects(()=>handler.run(fresh),MonsterStageError), "BOOTSTRAP संदर्भ नाकारावा");
check(fresh.branchTrace.length===0 && fresh.metrics.size===0, "अयशस्वी संदर्भावर परिणाम नको");
const ready=bootstrapMonster(F,F);
handler.run(ready);
check(rejects(()=>handler.run(ready),MonsterStageError), "त्याच context वर पुन्हा दुरुस्ती नको");
check(rejects(()=>patch02DayTags(1 as unknown as bigint,F),MonsterValidationError), "अवैध calculationDay नाकारावा");
check(rejects(()=>patch02DayTags(F,1 as unknown as bigint),MonsterValidationError), "अवैध targetDay नाकारावा");
check(rejects(()=>patch02DayTags(F,null as unknown as bigint),MonsterValidationError), "null नाकारावा");

const saved=patch01Save(F,F+1n,3n*M);
check(saved.savedValue===SAVE(3n*M) && saved.savedValue===M, "PATCH 01 बिघडली");
check(saved.context.branchTrace.join(",")==="BOOTSTRAP_VALIDATE,PATCH_01_LEGACY_REMAINDER,PATCH_01_ZERO_TO_M",
  "PATCH 01 स्वतंत्र ठेवावी");
check(rejects(()=>calendarDateSpaghetti(F,F),MonsterStageError), "Stage 54 अकाली उपलब्ध नको");
check(days===2*cases && increments>0 && increments<days, "सर्व साक्षी आणि दोन्ही बाजू तपासाव्यात");
check(scars>0 && forced===0 && mismatches===0, "scar टिकावी आणि निकाल oracle शी जुळावा");

console.log(`STAGE_05_PATCH_02_PASS pairs=${cases} days=${days} plusOne=${increments} scarChecks=${scars} scarForces=${forced} mismatches=${mismatches}`);
