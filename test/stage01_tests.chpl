use BigInteger;
use List;
use ExactMath;
use SourceLanguageCatalog;
use NormativeOracle;
use MonsterBootstrap;
use BootstrapFixtures;

var failures = 0;
var checks = 0;

proc check(condition: bool, label: string) {
  checks += 1;
  if condition then
    writeln("ГАРАЗД: ", label);
  else {
    failures += 1;
    writeln("ПОМИЛКА: ", label);
  }
}

proc sameIntArray(const ref a: [?DA] int, const ref b: [?DB] int): bool {
  if a.size != b.size then return false;
  for (x, y) in zip(a, b) do if x != y then return false;
  return true;
}

proc sameIntListArray(const ref a: list(int), const ref b: [?D] int): bool {
  if a.size != b.size then return false;
  for (x, y) in zip(a, b) do if x != y then return false;
  return true;
}

proc testExactMath() {
  check(M:string == EXPECTED_M_DECIMAL, "M дорівнює 2^127-1");
  check(TABLETS_DAY - FOUNDATION_DAY == EXPECTED_FOUNDATION_TO_TABLETS,
        "відстань від Заснування до Скрижалей точна");
  check(save(new bigint(1)) == 1, "SAVE(1)=1");
  check(save(M - 1) == M - 1, "SAVE(M-1)=M-1");
  check(save(M) == M, "SAVE(M)=M");
  check(save(M + 1) == 1, "SAVE(M+1)=1");
  check(save(2 * M) == M, "SAVE(2M)=M");
  check(save(new bigint(0)) == M, "SAVE(0)=M");
  check(regularMod(new bigint(-1), new bigint(7)) == 6,
        "евклідова остача від -1 за модулем 7 дорівнює 6");
  check(floorDiv(new bigint(-8), new bigint(7)) == -2,
        "floorDiv округлює до мінус нескінченності");
}

proc testCountsAndStones() {
  check(dayCount(FOUNDATION_DAY) == 1, "день Заснування має номер 1");
  check(dayCount(FOUNDATION_DAY + 1) == 3, "день після Заснування має номер 3");
  check(dayCount(FOUNDATION_DAY - 1) == 2, "день перед Заснуванням має номер 2");

  const same = workCounts(FOUNDATION_DAY, FOUNDATION_DAY);
  check(same.distance == 1 && same.direction == 2,
        "однакові дні дають відстань 1 і напрям 2");

  const later = workCounts(FOUNDATION_DAY, FOUNDATION_DAY + 1);
  check(later.action == 1 && later.target == 3 && later.distance == 2 &&
        later.connection == 4 && later.direction == 3,
        "множина лічильників для наступного дня точна");

  const stones = buildStones();
  check(stones[2].wheat == EXPECTED_STONE_2[1], "друга пшениця точна");
  check(stones[2].barley == EXPECTED_STONE_2[2], "другий ячмінь точний");
  check(stones[2].salt == EXPECTED_STONE_2[3], "друга сіль точна");
  check(stones[2].bitter == EXPECTED_STONE_2[4], "друга гірка речовина точна");
  check(stones[2].red == EXPECTED_STONE_2[5], "друга червона речовина точна");
}

proc testPermutationsAndSelectors() {
  check(sameIntArray(permutationUnrank1(1), EXPECTED_PERMUTATION_1),
        "ранг перестановки 1 є тотожним порядком");
  check(sameIntArray(permutationUnrank1(720), EXPECTED_PERMUTATION_720),
        "ранг перестановки 720 є оберненим порядком");

  var shortStream: AnswerStream;
  shortStream.first = 1;
  shortStream.directionStep = 1;
  check(chooseRankShort(shortStream, new bigint(10)) == 1,
        "короткий вибір приймає перше допустиме число");

  var rejectStream: AnswerStream;
  rejectStream.first = M;
  rejectStream.directionStep = 1;
  check(chooseRankShort(rejectStream, new bigint(10)) == 1,
        "короткий вибір після відхилення рухається тим самим кільцем");

  var wideStream: AnswerStream;
  wideStream.first = 1;
  wideStream.directionStep = 1;
  check(chooseRankWide(wideStream, M + 1) == M + 1,
        "широкий вибір для M+1 будує число з тих самих відповідей");
}

proc testOrderedFamilies() {
  check(fallingFactorialBig(17, 17) > M,
        "комбінаторний простір може бути більшим за M без переповнення");

  const firstNames = unrankDistinctNameIndices(3, 2, new bigint(1));
  const lastNames = unrankDistinctNameIndices(3, 2, new bigint(6));
  check(sameIntListArray(firstNames, [1,2]),
        "перший ранг різних назв лексикографічний");
  check(sameIntListArray(lastNames, [3,2]),
        "останній ранг різних назв лексикографічний");

  var bounded: BoundedCompositionCounter;
  bounded.totalValue = 9;
  bounded.slotsTotal = 2;
  bounded.lo = 4;
  bounded.hi = 5;
  check(bounded.countAll() == 2, "обмежені композиції 9 у два місця мають дві дороги");
  check(sameIntListArray(bounded.unrank1(new bigint(1)), [4,5]),
        "перша обмежена композиція точна");
  check(sameIntListArray(bounded.unrank1(new bigint(2)), [5,4]),
        "друга обмежена композиція точна");

  var cutlets: CutletPartitionCounter;
  cutlets.totalGaps = 7;
  cutlets.slotsTotal = 3;
  cutlets.requiredBoundary = 2;
  check(cutlets.countAll() == 5,
        "фільтр внутрішньої межі дає точну кількість малих композицій");
  check(sameIntListArray(cutlets.unrank1(new bigint(1)), [1,1,5]),
        "перший відфільтрований поділ котлет лексикографічний");
  check(sameIntListArray(cutlets.unrank1(new bigint(5)), [2,4,1]),
        "останній відфільтрований поділ котлет лексикографічний");

  var lengths = new list(int);
  lengths.pushBack(2);
  lengths.pushBack(2);
  var weaving: WeavingCounter;
  weaving.lengths = lengths;
  check(weaving.countAll() == 2, "для довжин 2,2 існують рівно два законні шитва");
  check(sameIntListArray(weaving.unrank1(new bigint(1)), [1,1,2,2]),
        "перше шитво 2,2 лексикографічне");
  check(sameIntListArray(weaving.unrank1(new bigint(2)), [1,2,1,2]),
        "друге шитво 2,2 лексикографічне");
}

proc testCatalog() {
  check(CUTLET_DOMAIN.size == 17, "каталог має 17 котлет");
  check(MONTH_DOMAIN.size == 47, "каталог має 47 місяців");
  check(cutletNameByCanonicalIndex(12) == "пшениця",
        "канонічний індекс 12 котлети означає пшеницю");
  check(monthNameByCanonicalIndex(44) == "сіль",
        "канонічний індекс 44 місяця означає сіль");

  var uniqueCutlets = true;
  for i in 1..17 do for j in (i + 1)..17 do
    if i < j && CUTLET_NAMES_UK[i] == CUTLET_NAMES_UK[j] then uniqueCutlets = false;
  check(uniqueCutlets, "усі 17 українських назв котлет різні");

  var uniqueMonths = true;
  for i in 1..47 do for j in (i + 1)..47 do
    if i < j && MONTH_NAMES_UK[i] == MONTH_NAMES_UK[j] then uniqueMonths = false;
  check(uniqueMonths, "усі 47 українських назв місяців різні");
}

proc testSauceDeterminism() {
  const first = sauce(FOUNDATION_DAY, FOUNDATION_DAY);
  const second = sauce(FOUNDATION_DAY, FOUNDATION_DAY);
  var same = true;
  for i in 1..6 do if first.bowls[i] != second.bowls[i] then same = false;
  for i in 1..6 do if first.orderAtDrop46[i] != second.orderAtDrop46[i] then same = false;
  check(same, "чистий нормативний соус детермінований при повторному виклику");

  var inRange = true;
  for i in 1..6 do if first.bowls[i] < 1 || first.bowls[i] > M then inRange = false;
  check(inRange, "усі кінцеві чаші лежать у 1..M");

  var seen: [1..6] bool;
  for i in 1..6 do seen[first.orderAtDrop46[i]] = true;
  var permutation = true;
  for i in 1..6 do if !seen[i] then permutation = false;
  check(permutation, "порядок 46-ї краплі є перестановкою шести чаш");
}

proc testNeutralMonsterBootstrap() {
  const ctx = makeBootstrapContext(FOUNDATION_DAY, FOUNDATION_DAY);
  check(ctx.status == MonsterStatus.bootstrapOnly,
        "виробничий каркас зупиняється на межі Bootstrap");
  check(ctx.phase == MonsterPhase.stoppedAtBootstrapBoundary,
        "виробничий каркас не переходить у майбутню історичну фазу");
  check(ctx.metrics.contains("bootstrap.calls") && ctx.metrics["bootstrap.calls"] == 1,
        "метрика початкового виклику є лише спостережуваністю");
  check(ctx.branchTrace.size == 1,
        "нейтральний диспетчер залишає один детермінований слід");
}

proc main() {
  writeln("Початок локальних перевірок етапу 1.");
  testExactMath();
  testCountsAndStones();
  testPermutationsAndSelectors();
  testOrderedFamilies();
  testCatalog();
  testSauceDeterminism();
  testNeutralMonsterBootstrap();

  writeln("Перевірок: ", checks, "; помилок: ", failures, ".");
  if failures != 0 then halt("Етап 1 має помилки.");
  writeln("STAGE_01_RESULT=PASS");
}
