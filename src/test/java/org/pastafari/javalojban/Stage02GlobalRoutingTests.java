package org.pastafari.javalojban;

import java.math.BigInteger;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

public final class Stage02GlobalRoutingTests {
    private static int checks;

    private Stage02GlobalRoutingTests() {}

    public static void main(String[] args) {
        testOracleAutomaticPaths();
        testBoundedResumptionAndOwnership();
        testFullYearBoundedNavigation();
        testErrors();
        System.out.println("STAGE_02_GLOBAL_ROUTING_PASS checks=" + checks
            + " days=5778 step_cap=" + MonsterWeavingLinearCounter.MAX_ROUTE_STEPS_PER_CALL
            + " count_cap=" + MonsterWeavingLinearCounter.MAX_ROUTE_BRANCH_COUNTS_PER_CALL
            + " heap_mb=" + Runtime.getRuntime().maxMemory() / 1048576);
    }

    private static void testOracleAutomaticPaths() {
        for (int[] lengths : new int[][]{
                {1, 1, 1}, {2, 2, 2}, {2, 3, 2},
                {3, 2, 3}, {2, 3, 3, 2}
        }) {
            MonsterWeavingLinearCounter family = new MonsterWeavingLinearCounter(lengths);
            NormativeOracle.WeavingFamily oracle = new NormativeOracle.WeavingFamily(lengths);
            int total = oracle.count().intValueExact();
            for (int rank = 1; rank <= total; rank++) {
                BigInteger global = BigInteger.valueOf(rank);
                MonsterWeavingLinearCounter.RankRoute route =
                    family.beginGlobalRankRoute(global, 0);
                for (int i = 0; !route.complete() && i < 25; i++) {
                    int earlier = route.stepsCompleted();
                    route = family.advanceGlobalRankRoute(route, 2, 64);
                    ok(route.stepsCompleted() > earlier, "E_SMALL_ROUTE_ADVANCE");
                    ok(route.lowerRank().compareTo(global) <= 0,
                        "E_SMALL_INTERVAL_BEGIN");
                    ok(route.upperRank().compareTo(global) >= 0,
                        "E_SMALL_INTERVAL_END");
                    eq(route.remainingChoices(), family.countAfterPrefix(
                        route.fixedPrefixCopy()), "E_SMALL_EXACT_INTERVAL");
                    ok(route.lastCountCalls() <= 64, "E_SMALL_BOUNDED_COUNTS");
                }
                ok(route.complete(), "E_SMALL_ROUTE_COMPLETE");
                int[] actual = family.finishGlobalRankRoute(route);
                array(oracle.unrank1(global), actual, "E_SMALL_ORACLE");
                eq(global, family.rank1(actual), "E_SMALL_GLOBAL_RANK");
                eq(global, route.lowerRank(), "E_FINAL_LOWER");
                eq(global, route.upperRank(), "E_FINAL_UPPER");
            }
        }
    }

    private static void testBoundedResumptionAndOwnership() {
        MonsterWeavingLinearCounter family =
            new MonsterWeavingLinearCounter(new int[]{3, 3, 3, 3});
        BigInteger count = family.count();
        BigInteger global = count.add(BigInteger.ONE).divide(BigInteger.TWO);
        MonsterWeavingLinearCounter.RankRoute start =
            family.beginGlobalRankRoute(global, 0);
        MonsterWeavingLinearCounter.RankRoute noWork =
            family.advanceGlobalRankRoute(start, 0, 0);
        eq(0, noWork.stepsCompleted(), "E_ZERO_STEPS");
        eq(count, noWork.remainingChoices(), "E_ZERO_CHOICES");
        MonsterWeavingLinearCounter.RankRoute forced =
            family.advanceGlobalRankRoute(start, 2, 0);
        ok(forced.stepsCompleted() >= 1, "E_FORCED_FIRST_MONTH");
        eq(global, start.globalRank(), "E_UNCHANGED_RANK");
        eq(0, start.stepsCompleted(), "E_UNCHANGED_START");
        fails("E_WEAVE_ROUTE_INCOMPLETE", () ->
            family.finishGlobalRankRoute(noWork));
        MonsterWeavingLinearCounter.RankRoute route = forced;
        int rounds = 0;
        while (!route.complete()) {
            route = family.advanceGlobalRankRoute(route, 3, 64);
            rounds++;
            ok(rounds < 20, "E_RESUME_TERMINATES");
        }
        array(family.unrank1(global), family.finishGlobalRankRoute(route),
            "E_RESUME_EXACT");
        int[] owned = route.fixedPrefixCopy();
        if (owned.length > 0) owned[0] = 0;
        array(family.unrank1(global), family.finishGlobalRankRoute(route),
            "E_RESUME_OWNERSHIP");
        MonsterWeavingLinearCounter other =
            new MonsterWeavingLinearCounter(new int[]{3, 3, 3, 3});
        final MonsterWeavingLinearCounter.RankRoute completed = route;
        fails("E_WEAVE_ROUTE_OWNER", () ->
            other.advanceGlobalRankRoute(completed, 1, 1));
        fails("E_WEAVE_ROUTE_OWNER", () -> other.finishGlobalRankRoute(completed));
    }

    private static void testFullYearBoundedNavigation() {
        int[] lengths = new int[47];
        Arrays.fill(lengths, 123);
        lengths[46] = 120;
        MonsterWeavingLinearCounter family = new MonsterWeavingLinearCounter(lengths);
        BigInteger total = family.count();
        for (BigInteger rank : List.of(BigInteger.ONE,
                total.add(BigInteger.ONE).divide(BigInteger.TWO))) {
            MonsterWeavingLinearCounter.RankRoute route =
                family.beginGlobalRankRoute(rank, 512);
            eq(total, route.remainingChoices(), "E_FULL_INITIAL_COUNT");
            MonsterWeavingLinearCounter.RankRoute first =
                family.advanceGlobalRankRoute(route, 1, 0);
            eq(1, first.stepsCompleted(), "E_FULL_FORCED_FIRST");
            eq(rank, first.globalRank(), "E_FULL_PRESERVED_RANK");
            eq(total, first.remainingChoices(), "E_FULL_FORCED_PRESERVES_COUNT");
            MonsterWeavingLinearCounter.RankRoute deeper =
                family.advanceGlobalRankRoute(first, 20, 4);
            ok(deeper.stepsCompleted() > 1, "E_FULL_ROUTE_PROGRESS");
            ok(deeper.stepsCompleted() <= 21, "E_FULL_STEP_BOUND");
            ok(deeper.lastCountCalls() <= 4, "E_FULL_COUNT_BOUND");
            ok(deeper.lowerRank().compareTo(rank) <= 0,
                "E_FULL_INTERVAL_CONTAINS_LOW");
            ok(deeper.upperRank().compareTo(rank) >= 0,
                "E_FULL_INTERVAL_CONTAINS_HIGH");
            eq(family.countAfterPrefix(deeper.fixedPrefixCopy()),
                deeper.remainingChoices(), "E_FULL_EXACT_SUFFIX_COUNT");
            eq(rank.subtract(deeper.lowerRank()).add(BigInteger.ONE),
                deeper.localRank(), "E_FULL_LOCAL_RANK");
            ok(!deeper.complete(), "E_FULL_PARTIAL_NOT_FINISHED");
            final MonsterWeavingLinearCounter.RankRoute pending = deeper;
            fails("E_WEAVE_ROUTE_INCOMPLETE", () ->
                family.finishGlobalRankRoute(pending));
        }
    }

    private static void testErrors() {
        MonsterWeavingLinearCounter family =
            new MonsterWeavingLinearCounter(new int[]{2, 3, 2});
        BigInteger max = family.count();
        fails("E_WEAVE_RANK", () -> family.beginGlobalRankRoute(null, 0));
        fails("E_WEAVE_RANK", () -> family.beginGlobalRankRoute(BigInteger.ZERO, 0));
        fails("E_WEAVE_RANK", () ->
            family.beginGlobalRankRoute(max.add(BigInteger.ONE), 0));
        fails("E_WEAVE_ROUTE_TARGET", () ->
            family.beginGlobalRankRoute(BigInteger.ONE, -1));
        fails("E_WEAVE_ROUTE_TARGET", () ->
            family.beginGlobalRankRoute(BigInteger.ONE, 8));
        MonsterWeavingLinearCounter.RankRoute ready =
            family.beginGlobalRankRoute(BigInteger.ONE, 0);
        fails("E_WEAVE_ROUTE_BUDGET", () ->
            family.advanceGlobalRankRoute(ready, -1, 0));
        fails("E_WEAVE_ROUTE_BUDGET", () ->
            family.advanceGlobalRankRoute(ready, 513, 0));
        fails("E_WEAVE_ROUTE_BUDGET", () ->
            family.advanceGlobalRankRoute(ready, 1, 65));
        fails("E_WEAVE_ROUTE_OWNER", () ->
            family.advanceGlobalRankRoute(null, 1, 1));
        fails("E_WEAVE_ROUTE_OWNER", () -> family.finishGlobalRankRoute(null));
    }

    private static void array(int[] expected, int[] actual, String code) {
        checks++;
        if (!Arrays.equals(expected, actual)) {
            throw new AssertionError(code + " expected="
                + Arrays.toString(expected) + " got=" + Arrays.toString(actual));
        }
    }

    private static void eq(Object expected, Object actual, String code) {
        checks++;
        if (!expected.equals(actual)) {
            throw new AssertionError(code + " expected=" + expected + " actual=" + actual);
        }
    }

    private static void ok(boolean yes, String code) {
        checks++;
        if (!yes) throw new AssertionError(code);
    }

    private static void fails(String wanted, Runnable action) {
        checks++;
        try {
            action.run();
        } catch (IllegalArgumentException err) {
            if (wanted.equals(err.getMessage())) return;
            throw new AssertionError("E_WRONG_ERROR wanted=" + wanted
                + " got=" + err.getMessage(), err);
        }
        throw new AssertionError("E_EXPECTED_FAILURE " + wanted);
    }
}
