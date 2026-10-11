import { discoverLegacyRemainder, LEGACY_MODULUS, MonsterValidationError } from "../src/index.ts";
import { FOUNDATION_DAY, M, SAVE } from "./normativeOracle.ts";

function assert(condition: boolean, message: string): void {
  if (!condition) throw new Error(message);
}

assert(LEGACY_MODULUS === M, "ऐतिहासिक भाजक नियमाधारित भाजकाशी समान असला पाहिजे");
const witnesses = [M, 2n * M, 3n * M, M + 1n] as const;
let mismatches = 0;
const observations = [];
for (const value of witnesses) {
  const observation = discoverLegacyRemainder(FOUNDATION_DAY, FOUNDATION_DAY, value);
  observations.push(observation);
  const expected = SAVE(value);
  const wrong = observation.legacyValue !== expected;
  mismatches += Number(wrong);
  assert(observation.input === value, "आवाहनाचा मूळ पूर्णांक बदलू नये");
  assert(observation.context.status === "DISCOVERY_01_RECORDED", "शोध स्थिती नोंदली पाहिजे");
  assert(observation.context.branchTrace.join(",") === "BOOTSTRAP_VALIDATE,DISCOVERY_01_LEGACY_REMAINDER", "शाखा-क्रम अचूक असला पाहिजे");
  assert(observation.context.metrics.get("bootstrap.calls") === 1n, "मूळ आवाहन मापन");
  assert(observation.context.metrics.get("discovery01.calls") === 1n, "ऐतिहासिक शोध मापन");
  assert(observation.legacyValue === (value === M + 1n ? 1n : 0n), "ऐतिहासिक शेष अपेक्षेप्रमाणे असावा");
  assert(expected === (value === M + 1n ? 1n : M), "नियमाधारित जतन अपेक्षेप्रमाणे असावे");
}
assert(mismatches === 3, "ठरवलेल्या साक्षींपैकी नेमके तीन फरक अपेक्षित आहेत");
assert(new Set(observations.map((x) => x.context)).size === 4, "आवाहनांचे संदर्भ परस्पर स्वतंत्र असले पाहिजेत");
observations[0]!.context.logs.push("स्वतंत्र नोंद");
assert(observations[1]!.context.logs.length === 0, "दुसऱ्या आवाहनात नोंदी झिरपू नयेत");
let rejected = false;
try {
  discoverLegacyRemainder(FOUNDATION_DAY, FOUNDATION_DAY, 3 as unknown as bigint);
} catch (error) {
  rejected = error instanceof MonsterValidationError;
}
assert(rejected, "bigint नसलेला शेष-इनपुट नाकारला पाहिजे");
console.log("STAGE_02_DISCOVERY_01_GUARDS_PASS mismatches=3 matches=1");
