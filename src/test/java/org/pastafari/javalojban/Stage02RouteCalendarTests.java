package org.pastafari.javalojban;

import java.math.BigInteger;
import java.util.Arrays;
import java.util.List;

public final class Stage02RouteCalendarTests {
    private static int checks;

    private Stage02RouteCalendarTests() {}

    public static void main(String[] args) {
        testSmallOracleRoutes();
        testActualFullYearGlobalPrefix();
        testIncompleteRoutesAndOwnership();
        System.out.println("STAGE_02_ROUTE_CALENDAR_PASS checks=" + checks
            + " full_days=5778 heap_mb="
            + Runtime.getRuntime().maxMemory() / 1048576);
    }

    private static void testSmallOracleRoutes() {
        for (int[] lengths : new int[][]{
                {2, 2, 2}, {2, 3, 2}, {3, 3, 3}, {2, 3, 3, 2}
        }) {
            MonsterWeavingLinearCounter family = new MonsterWeavingLinearCounter(lengths);
            NormativeOracle.WeavingFamily oracle = new NormativeOracle.WeavingFamily(lengths);
            int count = oracle.count().intValueExact();
            for (int r = 1; r <= count; r++) {
                BigInteger rank = BigInteger.valueOf(r);
                int[] expected = oracle.unrank1(rank);
                for (int prefixLength : new int[]{0, 1, expected.length / 2,
                        expected.length}) {
                    int[] prefix = Arrays.copyOf(expected, prefixLength);
                    MonsterWeavingLinearCounter.RankRoute partial =
                        family.beginGlobalRankRouteWithinPrefix(prefix, rank, 0);
                    eq(rank, partial.globalRank(), "E_STORED_GLOBAL");
                    eq(prefixLength, partial.stepsCompleted(), "E_PREFIX_DEPTH");
                    eq(family.countAfterPrefix(prefix),
                        partial.remainingChoices(), "E_PREFIX_INTERVAL_COUNT");
                    MonsterWeavingLinearCounter.RankRoute full =
                        family.advanceGlobalRankRoute(partial, 512, 64);
                    ok(full.complete(), "E_SMALL_COMPLETE");
                    array(expected, family.finishGlobalRankRoute(full),
                        "E_SMALL_ORACLE_WEAVING");
                    eq(rank, full.globalRank(), "E_SMALL_RANK_STABLE");
                }
            }
        }
    }

    private static void testActualFullYearGlobalPrefix() {
        BigInteger calculation = MonsterArithmetic.FOUNDATION_DAY;
        MonsterYears.Year year = new MonsterYears().year5000(calculation);
        MonsterYearBlueprint blueprint = MonsterYearBlueprint.build(calculation, year);
        MonsterWeavingLinearCounter family =
            new MonsterWeavingLinearCounter(blueprint.monthLengths());
        int yearDays = year.length().intValueExact();
        ok(yearDays > 512, "E_FULL_YEAR_LONG");
        int[] prefix = Arrays.copyOf(family.lexFirst(), yearDays - 512);
        prefix[prefix.length - 1]++;
        MonsterWeavingLinearCounter.BoundaryBlock block =
            family.globalBlockForPrefix(prefix);
        BigInteger rank = block.lowerRank().add(block.upperRank())
            .divide(BigInteger.TWO);
        MonsterWeavingLinearCounter.RankRoute route =
            family.beginGlobalRankRouteWithinPrefix(prefix, rank, 512);
        ok(route.complete(), "E_FULL_READY");
        eq(block.lowerRank(), route.lowerRank(), "E_FULL_LOWER");
        eq(block.upperRank(), route.upperRank(), "E_FULL_UPPER");
        eq(512, route.remainingDays(), "E_FULL_SUFFIX_DAYS");
        int[] expected = family.unrankGlobalWithinPrefix(prefix, rank);
        array(expected, family.finishGlobalRankRoute(route), "E_FULL_ROUTE_EQUALITY");
        MonsterCalendarResolver.GlobalPrefixRankedYear actual =
            MonsterCalendarResolver.fromBlueprintWithCompletedGlobalRoute(
                blueprint, family, route);
        MonsterCalendarResolver.GlobalPrefixRankedYear direct =
            MonsterCalendarResolver.fromBlueprintWithGlobalPrefixRank(
                blueprint, prefix, rank);
        eq(rank, actual.globalRank(), "E_FULL_GLOBAL_RANK");
        eq(block.lowerRank(), actual.blockFirstRank(), "E_FULL_BLOCK_START");
        eq(block.upperRank(), actual.blockLastRank(), "E_FULL_BLOCK_FINISH");
        array(expected, actual.weavingCopy(), "E_FULL_RESOLVED_WEAVING");
        eq(yearDays, actual.length(), "E_FULL_YEAR_DAYS");
        int[] occurrence = new int[blueprint.monthCount()];
        for (int month : expected) occurrence[month - 1]++;
        array(blueprint.monthLengths(), occurrence, "E_MONTH_COUNTS");
        for (int offset : new int[]{0, 1, yearDays / 2, yearDays - 513,
                yearDays - 512, yearDays - 2, yearDays - 1}) {
            BigInteger day = year.openGateDay().add(BigInteger.valueOf(offset + 1L));
            eq(direct.atDay(day), actual.atDay(day), "E_REAL_DATE_DIFFERENTIAL");
            MonsterYearBlueprint.Cutlet cutlet = blueprint.cutletAt(day);
            eq(cutlet.canonicalNameIndex(), actual.atDay(day).canonicalCutletIndex(),
                "E_REAL_CUTLET");
        }
        int[] immutable = route.fixedPrefixCopy();
        immutable[0] = 0;
        array(prefix, route.fixedPrefixCopy(), "E_ROUTE_OWNED_PREFIX");
        int[] returned = actual.weavingCopy();
        returned[0] = 0;
        array(expected, actual.weavingCopy(), "E_OWNED_WEAVING");
    }

    private static void testIncompleteRoutesAndOwnership() {
        BigInteger calc = MonsterArithmetic.FOUNDATION_DAY;
        MonsterYearBlueprint blueprint = MonsterYearBlueprint.build(calc,
            new MonsterYears().year5000(calc));
        MonsterWeavingLinearCounter family =
            new MonsterWeavingLinearCounter(blueprint.monthLengths());
        MonsterWeavingLinearCounter.RankRoute start =
            family.beginGlobalRankRoute(
                family.count().add(BigInteger.ONE).divide(BigInteger.TWO), 512);
        ok(!start.complete(), "E_INCOMPLETE");
        fails("E_WEAVE_ROUTE_INCOMPLETE", () ->
            MonsterCalendarResolver.fromBlueprintWithCompletedGlobalRoute(
                blueprint, family, start));
        fails("E_NULL_BLUEPRINT", () ->
            MonsterCalendarResolver.fromBlueprintWithCompletedGlobalRoute(
                null, family, start));
        fails("E_NULL_WEAVING_FAMILY", () ->
            MonsterCalendarResolver.fromBlueprintWithCompletedGlobalRoute(
                blueprint, null, start));
        fails("E_WEAVE_ROUTE_OWNER", () ->
            MonsterCalendarResolver.fromBlueprintWithCompletedGlobalRoute(
                blueprint, new MonsterWeavingLinearCounter(blueprint.monthLengths()),
                start));
        fails("E_WEAVE_GLOBAL_RANK", () ->
            family.beginGlobalRankRouteWithinPrefix(
                new int[]{1}, BigInteger.ZERO, 512));
        fails("E_WEAVE_ROUTE_TARGET", () ->
            family.beginGlobalRankRouteWithinPrefix(
                new int[]{1}, BigInteger.ONE, 513));
        fails("E_WEAVE_PREFIX", () ->
            family.beginGlobalRankRouteWithinPrefix(
                new int[]{2}, BigInteger.ONE, 512));
        MonsterWeavingLinearCounter.RankRoute ready =
            family.beginGlobalRankRouteWithinPrefix(
                Arrays.copyOf(family.lexFirst(),
                    blueprint.year().length().intValueExact() - 512),
                BigInteger.ONE, 512);
        ok(ready.complete(), "E_REUSABLE_READY");
        MonsterWeavingLinearCounter.RankRoute stillReady =
            family.advanceGlobalRankRoute(ready, 1, 0);
        eq(ready.stepsCompleted(), stillReady.stepsCompleted(), "E_READY_NOOP");
        eq(ready.localRank(), stillReady.localRank(), "E_READY_STABLE_RANK");
    }

    private static void array(int[] wanted, int[] got, String code) {
        checks++;
        if (!Arrays.equals(wanted, got)) throw new AssertionError(code);
    }

    private static void eq(Object wanted, Object got, String code) {
        checks++;
        if (!wanted.equals(got)) {
            throw new AssertionError(code + " wanted=" + wanted + " got=" + got);
        }
    }

    private static void ok(boolean value, String code) {
        checks++;
        if (!value) throw new AssertionError(code);
    }

    private static void fails(String code, Runnable task) {
        checks++;
        try {
            task.run();
        } catch (IllegalArgumentException ex) {
            if (code.equals(ex.getMessage())) return;
            throw new AssertionError("E_WRONG_ERROR " + ex.getMessage(), ex);
        }
        throw new AssertionError("E_EXPECTED_ERROR " + code);
    }
}
