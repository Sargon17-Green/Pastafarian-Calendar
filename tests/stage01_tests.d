module stage01_tests;

import std.bigint : BigInt;
import std.stdio : writeln;
import pastafari.catalog;
import pastafari.monster_base;
import normative_oracle;

static assert(is(typeof(MonsterContext.init.calculationDay) == BigInt));
static assert(is(typeof(Year.init.number) == BigInt));
static assert(is(typeof(Year.init.openGateIndex) == BigInt));
static assert(is(typeof(Year.init.openGateDay) == BigInt));
static assert(CalendarTuple.tupleof.length == 5);

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

    bool[string] cutletTexts;
    foreach (entry; cutletCatalog)
    {
        assert(entry.text.length > 0);
        assert(entry.text !in cutletTexts);
        cutletTexts[entry.text] = true;
        assert(cutletNameByIndex(entry.canonicalIndex) == entry.text);
    }
    assert(cutletTexts.length == 17);

    bool[string] monthTexts;
    foreach (entry; monthCatalog)
    {
        assert(entry.text.length > 0);
        assert(entry.text !in monthTexts);
        monthTexts[entry.text] = true;
        assert(monthNameByIndex(entry.canonicalIndex) == entry.text);
    }
    assert(monthTexts.length == 47);
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


void testArbitraryPrecisionDayAxis()
{
    auto huge = BigInt("10000000000000000000000000000000000000000");
    auto negativeHuge = -huge;

    auto positiveCount = dayCount(huge);
    auto expectedPositive = BigInt(2) * (huge - BigInt(FOUNDATION_DAY)) + 1;
    assert(positiveCount == expectedPositive);

    auto negativeCount = dayCount(negativeHuge);
    auto expectedNegative = BigInt(2) * (BigInt(FOUNDATION_DAY) - negativeHuge);
    assert(negativeCount == expectedNegative);

    auto counts = workCounts(negativeHuge, huge);
    assert(counts.distance == BigInt(2) * huge + 1);
    assert(counts.direction == 3);

    auto manager = new MonsterManager();
    auto calculation = negativeHuge;
    auto target = huge;
    auto ctx = manager.bootstrap(calculation, target);
    calculation += 7;
    target -= 11;
    assert(ctx.calculationDay == negativeHuge);
    assert(ctx.targetDay == huge);
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

    auto hugeOffset = BigInt("100000000000000000000000000000000000000000000000000");
    assert(answerAt(stream, hugeOffset) == BigInt(1) + regularMod(hugeOffset, M()));
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


void testYearNavigationSmoke()
{
    auto calculationDay = BigInt(FOUNDATION_DAY);
    auto oracle = new OracleCalendar();
    auto y = oracle.year5000(calculationDay);
    assert(y.number == 5000);
    assert(y.openGateDay < calculationDay);
    assert(calculationDay <= y.closeGateDay);
    auto length = y.closeGateDay - y.openGateDay;
    assert(length >= YEAR_MIN_DAYS);
    assert(length <= YEAR_MAX_DAYS);
    assert(y.closeGateIndex - y.openGateIndex >= MIN_GATE_GAPS_PER_YEAR);

    auto next = oracle.nextYear(calculationDay, y);
    assert(next.number == 5001);
    assert(next.openGateIndex == y.closeGateIndex);
    assert(next.openGateDay == y.closeGateDay);

    auto previous = oracle.previousYear(calculationDay, y);
    assert(previous.number == 4999);
    assert(previous.closeGateIndex == y.openGateIndex);
    assert(previous.closeGateDay == y.openGateDay);

    auto atClosing = oracle.findTargetYear(calculationDay, y.closeGateDay);
    assert(atClosing.number == 5000);
    auto atOpening = oracle.findTargetYear(calculationDay, y.openGateDay);
    assert(atOpening.number == 4999);
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


void testStateOwnershipIsolation()
{
    auto manager = new MonsterManager();
    auto firstContext = manager.bootstrap(FOUNDATION_DAY, FOUNDATION_DAY);
    auto secondContext = manager.bootstrap(FOUNDATION_DAY + 1, FOUNDATION_DAY - 1);

    assert(firstContext.branchTrace.ptr != secondContext.branchTrace.ptr);
    firstContext.branchTrace[0] = "EXTERNAL_MUTATION";
    firstContext.metrics.bump("external.mutation");
    assert(secondContext.branchTrace == ["BOOTSTRAP_DISPATCH"]);
    assert("external.mutation" !in secondContext.metrics.counters);
    assert(secondContext.metrics.counters["bootstrap.dispatch"] == 1);

    auto repeatedContext = manager.bootstrap(FOUNDATION_DAY, FOUNDATION_DAY);
    assert(repeatedContext.branchTrace == ["BOOTSTRAP_DISPATCH"]);
    assert("external.mutation" !in repeatedContext.metrics.counters);
    assert(repeatedContext.metrics.counters["bootstrap.dispatch"] == 1);

    auto stonesA = buildStones();
    auto stonesB = buildStones();
    auto untouchedStone = stonesB[1][0];
    auto nextRowBeforeMutation = stonesA[2][0];
    stonesA[1][0] = save(stonesA[1][0] + 1);
    assert(stonesB[1][0] == untouchedStone);
    assert(stonesA[2][0] == nextRowBeforeMutation);
    assert(stonesA[1].ptr != stonesA[2].ptr);
    assert(stonesA[1].ptr != stonesB[1].ptr);

    int[] callerLengths = [2,2];
    auto family = new WeavingFamily(callerLengths);
    callerLengths[0] = 1;
    assert(family.count() == 2);
    assert(family.unrank1(BigInt(1)) == [1,1,2,2]);
    assert(family.unrank1(BigInt(2)) == [1,2,1,2]);

    auto sauceA = sauce(FOUNDATION_DAY, FOUNDATION_DAY);
    auto sauceB = sauce(FOUNDATION_DAY, FOUNDATION_DAY);
    assert(sauceA.bowls == sauceB.bowls);
    assert(sauceA.orderAt46 == sauceB.orderAt46);
    auto preservedBowl = sauceB.bowls[1];
    auto preservedOrder = sauceB.orderAt46[0];
    sauceA.bowls[1] = save(sauceA.bowls[1] + 1);
    sauceA.orderAt46[0] = 99;
    assert(sauceB.bowls[1] == preservedBowl);
    assert(sauceB.orderAt46[0] == preservedOrder);

    auto gatesA = new OracleCalendar();
    auto gatesB = new OracleCalendar();
    auto positiveA = gatesA.ensureGateIndex(1);
    auto negativeA = gatesA.ensureGateIndex(-1);
    auto negativeB = gatesB.ensureGateIndex(-1);
    auto positiveB = gatesB.ensureGateIndex(1);
    assert(positiveA == positiveB);
    assert(negativeA == negativeB);
    assert(positiveA - FOUNDATION_DAY >= GATE_GAP_MIN);
    assert(positiveA - FOUNDATION_DAY <= GATE_GAP_MAX);
    assert(BigInt(FOUNDATION_DAY) - negativeA >= GATE_GAP_MIN);
    assert(BigInt(FOUNDATION_DAY) - negativeA <= GATE_GAP_MAX);

    assert(gatesA.gateIndexAtOrBefore(positiveA) == 1);
    assert(gatesA.gateIndexAtOrAfter(positiveA) == 1);
    auto exactPositive = gatesA.exactGateIndex(positiveA);
    assert(exactPositive.found);
    assert(exactPositive.index == 1);
    gatesA.ensureGatesForwardThroughDay(positiveA);
    gatesA.ensureGatesBackwardThroughDay(negativeA);

    auto sixthGate = gatesA.ensureGateIndex(6);
    assert(sixthGate > positiveA);
    assert(gatesA.validYearPair(BigInt(0), BigInt(6)));

    static assert(__traits(compiles, normativeCalendarDate(FOUNDATION_DAY, FOUNDATION_DAY)));
    static assert(__traits(compiles, normativeCalendarDate(BigInt(FOUNDATION_DAY), BigInt(FOUNDATION_DAY))));
}

int main()
{
    writeln("Փուլ 1. տեղային ստուգումները սկսվել են։");
    testCatalog();
    testArithmeticFixtures();
    testDayFixtures();
    testArbitraryPrecisionDayAxis();
    testStoneFixtures();
    testPermutationFixtures();
    testSelectionFixtures();
    testCombinatorialFixtures();
    testSauceStructuralInvariants();
    testYearNavigationSmoke();
    testNeutralMonsterBootstrap();
    testStateOwnershipIsolation();
    writeln("Փուլ 1. բոլոր տեղային ստուգումները հաջողությամբ ավարտվել են։");
    return 0;
}
