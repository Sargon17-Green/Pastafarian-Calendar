module stage01_tests;

import std.bigint : BigInt;
import std.stdio : writeln;
import pastafari.catalog;
import pastafari.monster_base;
import normative_oracle;

void testCatalog()
{
    assert(sourceLanguageCatalogVersion == "1.0.0");
    assert(cutletCatalog.length == 17);
    assert(monthCatalog.length == 47);
    assert(catalogIndicesAreFrozenAndDense());
    assert(cutletNameByIndex(1) == "բրոնզ");
    assert(cutletNameByIndex(12) == "ցորեն");
    assert(cutletNameByIndex(17) == "դատարկ սափոր");
    assert(monthNameByIndex(1) == "կավ");
    assert(monthNameByIndex(47) == "ավազ");
}

void testArithmeticFixtures()
{
    auto m = M();
    assert(m == BigInt("170141183460469231731687303715884105727"));
    assert(save(BigInt(1)) == 1);
    assert(save(m - 1) == m - 1);
    assert(save(m) == m);
    assert(save(m + 1) == 1);
    assert(save(2 * m) == m);
    assert(save(3 * m) == m);
}

void testDayFixtures()
{
    assert(TABLETS_DAY - FOUNDATION_DAY == 14777149);
    assert(dayCount(FOUNDATION_DAY) == 1);
    assert(dayCount(FOUNDATION_DAY + 1) == 3);
    assert(dayCount(FOUNDATION_DAY - 1) == 2);
    auto same = workCounts(FOUNDATION_DAY, FOUNDATION_DAY);
    assert(same.action == 1);
    assert(same.target == 1);
    assert(same.distance == 1);
    assert(same.connection == 2);
    assert(same.direction == 2);
    auto cross = workCounts(FOUNDATION_DAY - 1, FOUNDATION_DAY + 1);
    assert(cross.distance == 3);
    assert(cross.direction == 3);
}

void testStoneFixtures()
{
    auto stones = buildStones();
    assert(stones.length == 47);
    assert(stones[1] == [BigInt(17), BigInt(29), BigInt(43), BigInt(71), BigInt(101)]);
    assert(stones[2] == [BigInt(378), BigInt(1073), BigInt(2375), BigInt(6195), BigInt(10493)]);
    foreach (i; 1 .. 47)
        foreach (x; stones[i])
            assert(x >= 1 && x <= M());
}

void testPermutationFixtures()
{
    assert(permutationUnrank1(1) == [1,2,3,4,5,6]);
    assert(permutationUnrank1(720) == [6,5,4,3,2,1]);
    assert(bowlOrderFromDrop(BigInt(720)) == [6,5,4,3,2,1]);
    assert(bowlOrderFromDrop(BigInt(721)) == [1,2,3,4,5,6]);
}

void testSelectionFixtures()
{
    AnswerStream stream;
    stream.first = BigInt(1);
    stream.step = 1;
    assert(chooseRankShort(stream, BigInt(1)) == 1);
    assert(chooseRankShort(stream, M()) == 1);
    auto wideN = M() + 1;
    assert(chooseRankWide(stream, wideN) == wideN);
}

void testCombinatorialFixtures()
{
    assert(fallingFactorial(5, 3) == 60);
    assert(unrankDistinctIndices(5, 3, BigInt(1)) == [1,2,3]);
    assert(unrankDistinctIndices(5, 3, BigInt(60)) == [5,4,3]);

    auto fixedFamily = new BoundedCompositionFamily(8, 2, 4, 4);
    assert(fixedFamily.count() == 1);
    assert(fixedFamily.unrank1(BigInt(1)) == [4,4]);

    auto smallFamily = new BoundedCompositionFamily(9, 2, 4, 5);
    assert(smallFamily.count() == 2);
    assert(smallFamily.unrank1(BigInt(1)) == [4,5]);
    assert(smallFamily.unrank1(BigInt(2)) == [5,4]);

    auto allPartitions = new CutletPartitionFamily(6, 3, -1);
    assert(allPartitions.count() == 10);
    assert(allPartitions.unrank1(BigInt(1)) == [1,1,4]);
    assert(allPartitions.unrank1(BigInt(10)) == [4,1,1]);

    auto boundaryPartitions = new CutletPartitionFamily(6, 3, 2);
    assert(boundaryPartitions.count() == 4);
    assert(boundaryPartitions.unrank1(BigInt(1)) == [1,1,4]);
    assert(boundaryPartitions.unrank1(BigInt(2)) == [2,1,3]);

    auto weave11 = new WeavingFamily([1,1]);
    assert(weave11.count() == 1);
    assert(weave11.unrank1(BigInt(1)) == [1,2]);

    auto weave22 = new WeavingFamily([2,2]);
    assert(weave22.count() == 2);
    assert(weave22.unrank1(BigInt(1)) == [1,1,2,2]);
    assert(weave22.unrank1(BigInt(2)) == [1,2,1,2]);
}

void testSauceStructuralInvariants()
{
    auto r = sauce(FOUNDATION_DAY, FOUNDATION_DAY);
    assert(r.bowls.length == 7);
    foreach (id; 1 .. 7)
        assert(r.bowls[id] >= 1 && r.bowls[id] <= M());
    assert(r.orderAt46.length == 6);
    bool[7] seen;
    foreach (id; r.orderAt46)
    {
        assert(id >= 1 && id <= 6);
        assert(!seen[id]);
        seen[id] = true;
    }
    foreach (id; 1 .. 7)
        assert(seen[id]);
    auto next = nextBowlInDrop46Order(r, r.orderAt46[$ - 1]);
    assert(next == r.orderAt46[0]);
}

void testNeutralMonsterBootstrap()
{
    auto manager = new MonsterManager();
    auto ctx = manager.bootstrap(FOUNDATION_DAY, FOUNDATION_DAY);
    assert(ctx.calculationDay == FOUNDATION_DAY);
    assert(ctx.targetDay == FOUNDATION_DAY);
    assert(ctx.phase == "BOOTSTRAP");
    assert(ctx.status == "READY");
    assert(ctx.branchTrace == ["BOOTSTRAP_DISPATCH"]);
    assert(ctx.metrics.counters["bootstrap.dispatch"] == 1);
}

int main()
{
    writeln("Փուլ 1. տեղային ստուգումները սկսվել են։");
    testCatalog();
    testArithmeticFixtures();
    testDayFixtures();
    testStoneFixtures();
    testPermutationFixtures();
    testSelectionFixtures();
    testCombinatorialFixtures();
    testSauceStructuralInvariants();
    testNeutralMonsterBootstrap();
    writeln("Փուլ 1. բոլոր տեղային ստուգումները հաջողությամբ ավարտվել են։");
    return 0;
}
