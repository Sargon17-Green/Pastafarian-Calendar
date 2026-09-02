import std/[options, sets, strutils, tables, unittest]
import ../src/[exact_bigint, monster_base, pastafari_spaghetti, source_language_catalog]
import ./[bootstrap_fixtures, normative_oracle]

suite "Pontos egészaritmetikai alap":
  test "A nagy számláló pontos értéke":
    check $M == ExpectedMDecimal
    check parseBigInt(ExpectedMDecimal) == M

  test "A mentett maradék alapesetei":
    check save(initBigInt(1)) == initBigInt(1)
    check save(M - 1) == M - 1
    check save(M) == M
    check save(M + 1) == initBigInt(1)
    check save(M * 2) == M

  test "Negatív euklideszi maradék és lefelé osztás":
    check regularMod(initBigInt(-1), M) == M - 1
    check floorDiv(initBigInt(-1), M) == initBigInt(-1)
    check floorDiv(initBigInt(-10), initBigInt(3)) == initBigInt(-4)
    check regularMod(initBigInt(-10), initBigInt(3)) == initBigInt(2)

  test "Nagy egész szorzás és osztás visszaállítása":
    let a = parseBigInt("123456789012345678901234567890")
    let b = parseBigInt("9876543210987654321")
    let product = a * b
    check floorDiv(product, b) == a
    check regularMod(product, b).isZero

suite "Forrásnyelvi katalógus":
  test "A katalógus mérete és kanonikus indexei rögzítettek":
    check CutletCatalog.len == 17
    check MonthCatalog.len == 47
    for i, entry in CutletCatalog:
      check entry.canonicalIndex == i + 1
    for i, entry in MonthCatalog:
      check entry.canonicalIndex == i + 1

  test "A magyar forrásszövegek indexenként egyediek":
    var cutletTexts = initHashSet[string]()
    var monthTexts = initHashSet[string]()
    for entry in CutletCatalog:
      check entry.text notin cutletTexts
      cutletTexts.incl(entry.text)
    for entry in MonthCatalog:
      check entry.text notin monthTexts
      monthTexts.incl(entry.text)
    check cutletText(12) == "búza"
    check monthText(6) == "fogkrém"
    check monthText(44) == "só"

suite "A normatív referencia alapfüggvényei":
  test "Az alapítás körüli nap-számlálás":
    check dayCount(FoundationDay).toInt() == ExpectedFoundationDayCount
    check dayCount(FoundationDay - 1).toInt() == ExpectedDayBeforeFoundationCount
    check dayCount(FoundationDay + 1).toInt() == ExpectedDayAfterFoundationCount

  test "Azonos nap esetén a távolság egy és az irány kettő":
    let counts = workCounts(FoundationDay, FoundationDay)
    check counts.action == initBigInt(1)
    check counts.target == initBigInt(1)
    check counts.distance == initBigInt(1)
    check counts.connection == initBigInt(2)
    check counts.direction == 2

  test "A második kősor egyetlen régi pillanatképből készül":
    let stones = buildStones()
    for kind in 1..5:
      check stones[2][kind] == initBigInt(ExpectedStoneRow2[kind - 1])

  test "A tálpermutáció szélső rangjai lexikografikusak":
    let first = permutationUnrank1(1)
    let last = permutationUnrank1(720)
    for i in 1..6:
      check first[i] == ExpectedPermutationRank1[i - 1]
      check last[i] == ExpectedPermutationRank720[i - 1]

suite "Pontos rendezett családok":
  test "A korlátos kompozíció számlálása és rangfeloldása pontos":
    let family = newBoundedCompositionCounter(10, 2, 4, 6)
    check family.countAll() == initBigInt(3)
    check family.unrank1(initBigInt(1)) == @[4, 6]
    check family.unrank1(initBigInt(2)) == @[5, 5]
    check family.unrank1(initBigInt(3)) == @[6, 4]

  test "A kötelező belső határ szűrt lexikografikus családot ad":
    let family = newCutletPartitionCounter(8, 3, some(3))
    check family.countAll() == initBigInt(6)
    check family.unrank1(initBigInt(1)) == @[1, 2, 5]
    check family.unrank1(initBigInt(6)) == @[3, 4, 1]

  test "A kis szövési tér teljes rangsora pontos":
    let family = newWeavingCounter(@[2, 2])
    check family.countAll() == initBigInt(2)
    check family.unrank1(initBigInt(1)) == @[1, 1, 2, 2]
    check family.unrank1(initBigInt(2)) == @[1, 2, 1, 2]

  test "A különböző nevek rangfeloldása nem ismétel indexet":
    let row = unrankDistinctIndices(5, 3, initBigInt(17))
    check row.len == 3
    check row[0] != row[1]
    check row[0] != row[2]
    check row[1] != row[2]

suite "Semleges szörnyváz":
  test "Két meghívás kontextusa nem osztozik módosítható állapoton":
    let a = bootstrapContextOnly(FoundationDay, FoundationDay)
    let b = bootstrapContextOnly(FoundationDay, FoundationDay)
    check a != b
    check a.phase == mpReady
    check b.phase == mpReady
    a.metrics["helyi"] = 7
    check not b.metrics.hasKey("helyi")

  test "A Stage 1 termelési belépő még nem állít elő normatív eredményt":
    expect MonsterExecutionError:
      discard calendarDateSpaghetti(FoundationDay, FoundationDay)

suite "Történeti szakaszhatár":
  test "Jövőbeli foltkód nincs a termelési forrásban":
    let production = readFile("src/pastafari_spaghetti.nim") & "\n" &
                     readFile("src/monster_base.nim")
    let forbidden = [
      "oldRemainder", "savePatch", "oldDayTag", "oldDistance",
      "mutateStonesWrong", "LEGACY_YEAR_MAX", "orderAt46Latch",
      "VirtualLegacyList", "oldContiguousMonthDayGuess"
    ]
    for token in forbidden:
      check token notin production
