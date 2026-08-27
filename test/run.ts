import {
  CUTLET_CATALOG,
  MONTH_CATALOG,
  SourceLanguageCatalog,
  bootstrapMonster,
  calendarDateSpaghetti,
  MonsterStageError
} from "../src/index.ts";
import {
  FOUNDATION_DAY,
  M,
  SAVE,
  STONES,
  boundedCompositionFamily,
  bowlOrderFromNumber,
  dayCount,
  sauce,
  unrankDistinctIndices,
  weavingFamily,
  workCounts
} from "./normativeOracle.ts";
import { STAGE_01_FIXTURES } from "./fixtures.ts";

function fail(message: string): never {
  throw new Error(message);
}

function assert(condition: boolean, message: string): void {
  if (!condition) fail(message);
}

function assertBigInt(actual: bigint, expected: bigint, message: string): void {
  if (actual !== expected) fail(`${message}: ${actual} != ${expected}`);
}

function assertArray<T>(actual: readonly T[], expected: readonly T[], message: string): void {
  if (actual.length !== expected.length) fail(`${message}: लांबी जुळत नाही`);
  for (let i = 0; i < actual.length; i += 1) if (actual[i] !== expected[i]) fail(`${message}: स्थान ${i + 1} जुळत नाही`);
}

function testCatalog(): void {
  assert(SourceLanguageCatalog.language === "मराठी", "स्रोत भाषा मराठी असली पाहिजे");
  assert(SourceLanguageCatalog.version === "1.0.0", "कॅटलॉग आवृत्ती स्थिर असली पाहिजे");
  assert(CUTLET_CATALOG.length === 17, "सतरा कटलेट नावे आवश्यक आहेत");
  assert(MONTH_CATALOG.length === 47, "सत्तेचाळीस महिना नावे आवश्यक आहेत");
  assert(Object.isFrozen(SourceLanguageCatalog), "मुख्य कॅटलॉग गोठवलेला असला पाहिजे");
  assert(Object.isFrozen(CUTLET_CATALOG) && Object.isFrozen(MONTH_CATALOG), "नावांच्या याद्या गोठवलेल्या असल्या पाहिजेत");
  for (let i = 0; i < CUTLET_CATALOG.length; i += 1) assert(CUTLET_CATALOG[i]!.canonicalIndex === i + 1, "कटलेट canonicalIndex सलग असले पाहिजेत");
  for (let i = 0; i < MONTH_CATALOG.length; i += 1) assert(MONTH_CATALOG[i]!.canonicalIndex === i + 1, "महिना canonicalIndex सलग असले पाहिजेत");
  const allText = [...CUTLET_CATALOG, ...MONTH_CATALOG].map((x) => x.text).join(" ");
  assert(!/[\u0590-\u05ff]/u.test(allText), "कॅटलॉगमध्ये हिब्रू मजकूर राहू नये");
  assert(!/[A-Za-z]/u.test(allText), "कॅटलॉगच्या नावांत इंग्रजी अक्षरे राहू नयेत");
}

function testArithmeticAndCounts(): void {
  for (const fixture of STAGE_01_FIXTURES.save) assertBigInt(SAVE(fixture.input), fixture.expected, "SAVE अपेक्षित नमुना जुळला नाही");
  for (const fixture of STAGE_01_FIXTURES.dayCount) assertBigInt(dayCount(fixture.input), fixture.expected, "dayCount अपेक्षित नमुना जुळला नाही");
  const counts = workCounts(FOUNDATION_DAY, FOUNDATION_DAY);
  assertBigInt(counts.action, 1n, "पाया-दिवस action");
  assertBigInt(counts.target, 1n, "पाया-दिवस target");
  assertBigInt(counts.distance, 1n, "पाया-दिवस distance");
  assertBigInt(counts.connection, 2n, "पाया-दिवस connection");
  assertBigInt(counts.direction, 2n, "पाया-दिवस direction");
  assertBigInt(M, (1n << 127n) - 1n, "मोठी मोजणी");
}

function testStonesAndSauce(): void {
  assertArray(STONES[2]!, STAGE_01_FIXTURES.secondStone, "दुसऱ्या दगडांची ओळ");
  const result = sauce(FOUNDATION_DAY, FOUNDATION_DAY);
  assertArray(result.bowls, STAGE_01_FIXTURES.foundationSauce.bowls, "पाया-दिवस रस-गणनेतील वाट्या");
  assertArray(result.orderAtDrop46, STAGE_01_FIXTURES.foundationSauce.orderAtDrop46, "पाया-दिवस रस-गणनेतील छेचाळीसावा क्रम");
  const again = sauce(FOUNDATION_DAY, FOUNDATION_DAY);
  assertArray(again.bowls, result.bowls, "रस-गणनेची पुनरावृत्ती निर्धारक असली पाहिजे");
  assertArray(again.orderAtDrop46, result.orderAtDrop46, "क्रमाची पुनरावृत्ती निर्धारक असली पाहिजे");
}

function testOrderedFamilies(): void {
  assertArray(bowlOrderFromNumber(1n), [1, 2, 3, 4, 5, 6], "पहिला वाटी-क्रम");
  assertArray(bowlOrderFromNumber(720n), [6, 5, 4, 3, 2, 1], "सातशेविसावा वाटी-क्रम");
  assertArray(unrankDistinctIndices(4, 3, 1n), [1, 2, 3], "वेगळ्या नावांचा पहिला दर्जा");
  const composition = boundedCompositionFamily(5n, 2, 1n, 4n);
  assertBigInt(composition.count(), 4n, "बंधित रचनांची संख्या");
  assertArray(composition.unrank1(1n), [1n, 4n], "पहिली बंधित रचना");
  assertArray(composition.unrank1(4n), [4n, 1n], "शेवटची बंधित रचना");
  const weave = weavingFamily([2n, 2n]);
  assertBigInt(weave.count(), 2n, "लहान शजवणींची संख्या");
  assertArray(weave.unrank1(1n), [1, 1, 2, 2], "पहिली लहान शजवण");
  assertArray(weave.unrank1(2n), [1, 2, 1, 2], "दुसरी लहान शजवण");
}

function testBootstrapProduction(): void {
  const first = bootstrapMonster(FOUNDATION_DAY, FOUNDATION_DAY);
  const second = bootstrapMonster(FOUNDATION_DAY, FOUNDATION_DAY);
  assert(first !== second, "प्रत्येक आवाहनाला स्वतंत्र संदर्भ-अवस्था असली पाहिजे");
  first.logs.push("स्थानिक नोंद");
  assert(second.logs.length === 0, "एका आवाहनाची निरीक्षणीय स्थिती दुसऱ्या आवाहनात जाऊ नये");
  assert(first.status === "VALIDATED" && first.phase === "READY", "प्रारंभिक स्थिती वैध असली पाहिजे");
  let threw = false;
  try {
    calendarDateSpaghetti(FOUNDATION_DAY, FOUNDATION_DAY);
  } catch (error) {
    threw = error instanceof MonsterStageError;
  }
  assert(threw, "टप्पा 1 मध्ये अंतिम मुख्य मार्ग जाणीवपूर्वक उपलब्ध नसला पाहिजे");
}

function main(): void {
  testCatalog();
  testArithmeticAndCounts();
  testStonesAndSauce();
  testOrderedFamilies();
  testBootstrapProduction();
  console.log("STAGE_01_PASS");
}

main();
