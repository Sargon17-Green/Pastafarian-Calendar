import {
  bootstrapMonster, createMonsterContext, discoverLegacyDistance,
  Discovery03DistanceHandler, MonsterStageError, MonsterValidationError,
  patch03Distance
} from "../src/index.ts";
import { FOUNDATION_DAY as F, workCounts } from "./normativeOracle.ts";

function check(value: boolean, message: string): void {
  if (!value) throw new Error(message);
}
function rejected(f: () => unknown, cls: typeof MonsterStageError | typeof MonsterValidationError): boolean {
  try { f(); } catch (error) { return error instanceof cls; }
  return false;
}
const handler = new Discovery03DistanceHandler();
const raw = createMonsterContext(F, F);
check(rejected(() => handler.run(raw), MonsterStageError), "BOOTSTRAP संदर्भ नाकारावा");
check(raw.status === "NEW" && raw.branchTrace.length === 0 && raw.metrics.size === 0,
  "पूर्वपडताळणी अयशस्वी झाल्यास संदर्भ बदलू नये");

const valid = bootstrapMonster(F - 2n, F + 2n);
const before = [...valid.branchTrace];
const invalid = { ...valid, calculationDay: 3 as unknown as bigint };
check(rejected(() => handler.run(invalid), MonsterValidationError), "अवैध bigint नाकारावा");
check(invalid.status === "VALIDATED" && invalid.branchTrace.join(",") === before.join(","),
  "चुकीच्या input नंतर mutation असू नये");

const observed = handler.run(valid);
check(Object.isFrozen(observed), "अवस्था-परिणाम frozen असला पाहिजे");
check(observed.legacyDistance === 1n, "ऐतिहासिक दोष बदलू नये");
check(observed.context.status === "DISCOVERY_03_RECORDED", "जीवनचक्र स्थिती नोंदली पाहिजे");
check(observed.context.branchTrace.join(",") ===
  "BOOTSTRAP_VALIDATE,DISCOVERY_03_TAG_DISTANCE", "ऐतिहासिक शाखा-क्रम बदलू नये");
check(observed.context.metrics.get("discovery03.calls") === 1n, "एका आवाहनाची मोजणी");
check(rejected(() => handler.run(valid), MonsterStageError), "वापरलेल्या संदर्भाला पुन्हा चालवू नये");
check(observed.context.metrics.get("discovery03.calls") === 1n, "दुसऱ्या अपयशानंतर metrics स्थिर असावेत");
check(observed.context.branchTrace.length === 2, "पुनर्वापराने branchTrace बदलू नये");

const second = discoverLegacyDistance(F - 2n, F + 2n);
check(second.context !== valid && second.legacyDistance === observed.legacyDistance,
  "नवीन आवाहन स्वायत्त पण नियमाधारित इतिहास जतन करणारे असावे");
check(patch03Distance(F - 2n, F + 2n).distance === workCounts(F - 2n, F + 2n).distance,
  "जुन्या handler सुरक्षेमुळे PATCH 03 बिघडू नये");

console.log("STAGE_06_DISCOVERY_03_LIFECYCLE_PASS");
