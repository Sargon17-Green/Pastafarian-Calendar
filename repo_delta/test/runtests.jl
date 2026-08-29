using Test
using PastafariCalendarNewIthkuil

include("support/NormativeOracle.jl")
include("fixtures/BootstrapFixtures.jl")
using .NormativeOracle

@testset "SOURCE_LANGUAGE_CATALOG" begin
    @test SOURCE_LANGUAGE_CATALOG_VERSION == v"0.1.0"
    @test SOURCE_LANGUAGE_CODE == :new_ithkuil
    @test SOURCE_LANGUAGE_CATALOG_STATE == :COMPLETE
    @test length(CUTLET_SOURCE_CATALOG) == 17
    @test length(MONTH_SOURCE_CATALOG) == 47
    @test [entry.canonicalIndex for entry in CUTLET_SOURCE_CATALOG] == collect(1:17)
    @test [entry.canonicalIndex for entry in MONTH_SOURCE_CATALOG] == collect(1:47)
    @test all(entry -> entry.text !== nothing, CUTLET_SOURCE_CATALOG)
    @test all(entry -> entry.text !== nothing, MONTH_SOURCE_CATALOG)

    canonicalCutlets = (
        (1, :bronze, "aksvala amẓali’i ažprali’i"),
        (2, :fox, "ezvwala"),
        (3, :kidney, "epflala"),
        (4, :lagash, "lagaš"),
        (5, :thought, "aslela"),
        (6, :four_parts_of_nine, "apšala alẓilui"),
        (7, :palgurash, "palguraš"),
        (8, :papyrus, "eḑkyala"),
        (9, :cluster, "acyäla"),
        (10, :scorpion, "aggzaloubva"),
        (11, :ash, "ugçila ažxaloi"),
        (12, :wheat, "abtaleibva"),
        (13, :river, "elzala"),
        (14, :laughter, "ajwala"),
        (15, :akkad, "akkad"),
        (16, :horn, "unzgala"),
        (17, :empty_jug, "ašglila ešḑälä’ä"),
    )
    canonicalMonths = (
        (1, :mud, "andwaleuvsa"),
        (2, :pomegranate, "aňňpaleikca"),
        (3, :elbow, "hwecmala-aţřala"),
        (4, :envy, "ařřnala"),
        (5, :eridu, "eridu"),
        (6, :toothpaste, "egdräla adřalie"),
        (7, :three_parts_of_five, "azala astilui"),
        (8, :karshumab, "karšumab"),
        (9, :tiger, "arrwala"),
        (10, :tin, "ažprala"),
        (11, :fog, "hwekthaliá-ufthala"),
        (12, :frankincense, "uçplila aňsxwaloi"),
        (13, :spindle, "arpļalaičva"),
        (14, :rib, "olçflala"),
        (15, :carob, "ařtlaleikca"),
        (16, :uruk, "uruk"),
        (17, :shame, "avxwala"),
        (18, :camel, "oňļwala"),
        (19, :copper, "amẓala"),
        (20, :well, "eţrala"),
        (21, :yolk, "exwala aḑnwalei amlalä’ä"),
        (22, :star, "alxwala"),
        (23, :honey, "amnwala"),
        (24, :spleen, "upflala"),
        (25, :limestone, "agglala"),
        (26, :joy, "antrala"),
        (27, :fig, "ařçaleikca"),
        (28, :nineveh, "ninua"),
        (29, :frog, "anxlala"),
        (30, :pitch, "antçala"),
        (31, :candle, "ellwila amtçali’i"),
        (32, :closed_door, "apřaleigḑuňřa"),
        (33, :sesame, "ařžplala"),
        (34, :nape, "aňwaloukfa"),
        (35, :silver, "ařļala"),
        (36, :lily, "alswala"),
        (37, :storm, "efkhala"),
        (38, :donkey, "excala"),
        (39, :flour, "ačkwaliulksa"),
        (40, :regret, "azglala"),
        (41, :babylon, "babili"),
        (42, :tongue, "ankwala"),
        (43, :flax, "armçmala"),
        (44, :salt, "afdala"),
        (45, :pear, "unžaleikca"),
        (46, :bow, "ašxwala"),
        (47, :sand, "antfala"),
    )

    @test [(entry.canonicalIndex, entry.sourceKey, entry.text) for entry in CUTLET_SOURCE_CATALOG] == collect(canonicalCutlets)
    @test [(entry.canonicalIndex, entry.sourceKey, entry.text) for entry in MONTH_SOURCE_CATALOG] == collect(canonicalMonths)

    for (index, sourceKey, expected) in canonicalCutlets
        @test CUTLET_SOURCE_CATALOG[index].sourceKey == sourceKey
        @test cutletSourceName(index) == expected
    end
    for (index, sourceKey, expected) in canonicalMonths
        @test MONTH_SOURCE_CATALOG[index].sourceKey == sourceKey
        @test monthSourceName(index) == expected
    end
end

@testset "REFERENCE_EXACT_ARITHMETIC" begin
    @test NormativeOracle.M == FIXTURE_M
    @test NormativeOracle.TABLETS_DAY - NormativeOracle.FOUNDATION_DAY == 14777149
    @test NormativeOracle.SAVE(0) == NormativeOracle.M
    @test NormativeOracle.SAVE(NormativeOracle.M) == NormativeOracle.M
    @test NormativeOracle.SAVE(2 * NormativeOracle.M) == NormativeOracle.M
    @test NormativeOracle.SAVE(NormativeOracle.M + 1) == 1
    @test NormativeOracle.SAVE(1) == 1
end

@testset "DAY_AND_WORK_COUNTS" begin
    foundation = NormativeOracle.FOUNDATION_DAY
    @test NormativeOracle.dayCount(foundation) == 1
    @test NormativeOracle.dayCount(foundation + 1) == 3
    @test NormativeOracle.dayCount(foundation - 1) == 2
    counts = NormativeOracle.workCounts(foundation, foundation)
    @test counts.action == 1
    @test counts.target == 1
    @test counts.distance == 1
    @test counts.connection == 2
    @test counts.direction == 2
    before = NormativeOracle.workCounts(foundation + 5, foundation - 7)
    @test before.distance == 13
    @test before.direction == 1
end

@testset "STONE_SNAPSHOT" begin
    stones = NormativeOracle.buildStones()
    @test length(stones) == 46
    @test stones[1] == (BigInt(17), BigInt(29), BigInt(43), BigInt(71), BigInt(101))
    @test stones[2] == FIXTURE_STONE_2
end

@testset "LEXICOGRAPHIC_PERMUTATIONS" begin
    @test NormativeOracle.permutationUnrank1(1, collect(1:6)) == FIXTURE_PERMUTATION_FIRST
    @test NormativeOracle.permutationUnrank1(720, collect(1:6)) == FIXTURE_PERMUTATION_LAST
    @test NormativeOracle.bowlOrderFromNumber(1) == FIXTURE_PERMUTATION_FIRST
    @test NormativeOracle.bowlOrderFromDrop(720) == FIXTURE_PERMUTATION_LAST
end

@testset "EXACT_COMBINATORIAL_FAMILIES" begin
    @test NormativeOracle.fallingFactorial(17, 6) == 8910720
    @test NormativeOracle.countBoundedCompositions(5, 2, 1, 4) == 4
    @test NormativeOracle.unrankBoundedComposition(5, 2, 1, 4, 1) == [1, 4]
    @test NormativeOracle.unrankBoundedComposition(5, 2, 1, 4, 4) == [4, 1]
    @test NormativeOracle.countWeavings([2, 2]) == 2
    @test NormativeOracle.unrankWeaving([2, 2], 1) == FIXTURE_WEAVING_22_FIRST
    @test NormativeOracle.unrankWeaving([2, 2], 2) == FIXTURE_WEAVING_22_SECOND
end

@testset "NEUTRAL_MONSTER_SHELL" begin
    context = MonsterContext(7, -11)
    @test context.calculationDay == 7
    @test context.targetDay == -11
    @test context.phase == :BOOTSTRAP
    @test context.status == :NEW
    @test_throws StageIncompleteError calendarDateSpaghetti(7, -11)
end

@testset "REFERENCE_SELECTION_BOUNDARIES" begin
    shortStream = NormativeOracle.AnswerStream(BigInt(1), 1)
    @test NormativeOracle.chooseRankShort(shortStream, 1) == 1
    @test NormativeOracle.chooseRankShort(NormativeOracle.AnswerStream(NormativeOracle.M, -1), NormativeOracle.M) == NormativeOracle.M
    @test NormativeOracle.chooseRankWide(shortStream, NormativeOracle.M + 1) == NormativeOracle.M + 1
end

@testset "REFERENCE_LATCHED_QUERY_ORDER" begin
    synthetic = NormativeOracle.SauceResult(fill(BigInt(1), 6), [2, 3, 4, 5, 6, 1])
    @test NormativeOracle.nextBowlInDrop46Order(synthetic, 1) == 2
end

@testset "REFERENCE_CUTLET_BOUNDARY_FILTER" begin
    countAll, unrank1 = NormativeOracle.makeCutletPartitionFamily(4, 2, 2)
    @test countAll() == 1
    @test unrank1(1) == [2, 2]
end
