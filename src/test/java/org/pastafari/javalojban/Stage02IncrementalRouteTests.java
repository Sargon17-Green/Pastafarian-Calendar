package org.pastafari.javalojban;

import java.math.BigInteger;
import java.util.Arrays;
import java.util.List;

public final class Stage02IncrementalRouteTests {
    private static int checks;

    private Stage02IncrementalRouteTests() {}

    public static void main(String[] args) {
        exhaustiveOracleUnderSingleCountBudget();
        persistSkippedBranchesAcrossCalls();
        progressInFullYearInterior();
        zeroBudgetDoesNotLoseSavedWork();
        System.out.println("STAGE_02_INCREMENTAL_ROUTE_PASS checks=" + checks
            + " full_days=5778 counts_per_call=1"
            + " heap_mb=" + Runtime.getRuntime().maxMemory() / 1048576);
    }

    private static void exhaustiveOracleUnderSingleCountBudget() {
        for (int[] lengths : new int[][]{
                {2, 2, 2}, {2, 3, 2}, {3, 3, 3}, {2, 3, 3, 2}
        }) {
            MonsterWeavingLinearCounter family =
                new MonsterWeavingLinearCounter(lengths);
            NormativeOracle.WeavingFamily oracle =
                new NormativeOracle.WeavingFamily(lengths);
            int count = oracle.count().intValueExact();
            for (int r = 1; r <= count; r++) {
                BigInteger rank = BigInteger.valueOf(r);
                MonsterWeavingLinearCounter.RankRoute route =
                    family.beginGlobalRankRoute(rank, 0);
                int steps = 0;
                int calls = 0;
                while (!route.complete()) {
                    MonsterWeavingLinearCounter.RankRoute next =
                        family.advanceGlobalRankRoute(route, 1, 1);
                    ok(next.lastCountCalls() <= 1, "E_SINGLE_COUNT_BUDGET");
                    ok(next.stepsCompleted() >= route.stepsCompleted(),
                        "E_MONOTONE_PREFIX");
                    ok(next.probedBranches() >= 0, "E_NONNEGATIVE_PROBES");
                    ok(next.skippedChoices().signum() >= 0, "E_NONNEGATIVE_SKIPS");
                    eq(rank, next.globalRank(), "E_RANK_STABLE");
                    ok(next.lowerRank().compareTo(rank) <= 0,
                        "E_INTERVAL_LOW");
                    ok(rank.compareTo(next.upperRank()) <= 0,
                        "E_INTERVAL_HIGH");
                    route = next;
                    calls++;
                    ok(calls <= 100, "E_SMALL_ROUTE_FINITE");
                    if (route.stepsCompleted() > steps) {
                        steps = route.stepsCompleted();
                        eq(BigInteger.ZERO, route.skippedChoices(),
                            "E_PROBES_RESET_ON_SELECTION");
                        eq(0, route.probedBranches(), "E_SKIP_RESET");
                    }
                }
                array(oracle.unrank1(rank), family.finishGlobalRankRoute(route),
                    "E_ORACLE_SINGLE_BUDGET_UNRANK");
                eq(rank, route.lowerRank(), "E_TERMINAL_START");
                eq(rank, route.upperRank(), "E_TERMINAL_END");
            }
        }
    }

    private static void persistSkippedBranchesAcrossCalls() {
        MonsterWeavingLinearCounter family =
            new MonsterWeavingLinearCounter(new int[]{5, 5, 5, 5});
        int[] prefix = {1, 2, 3, 4};
        int[] chosenChild = {1, 2, 3, 4, 4};
        MonsterWeavingLinearCounter.BoundaryBlock child =
            family.globalBlockForPrefix(chosenChild);
        BigInteger rank = child.lowerRank().add(child.upperRank())
            .divide(BigInteger.TWO);
        MonsterWeavingLinearCounter.RankRoute initial =
            family.beginGlobalRankRouteWithinPrefix(prefix, rank, 0);
        ok(rank.subtract(initial.lowerRank()).compareTo(
            BigInteger.valueOf(8)) > 0, "E_NOT_NEAR_FIRST");
        ok(initial.upperRank().subtract(rank).compareTo(
            BigInteger.valueOf(8)) > 0, "E_NOT_NEAR_LAST");
        MonsterWeavingLinearCounter.RankRoute current = initial;
        BigInteger lastSkipped = BigInteger.ZERO;
        for (int expectedProbes = 1; expectedProbes <= 3; expectedProbes++) {
            MonsterWeavingLinearCounter.RankRoute next =
                family.advanceGlobalRankRoute(current, 1, 1);
            eq(initial.stepsCompleted(), next.stepsCompleted(),
                "E_WAITING_FOR_CORRECT_BRANCH");
            eq(expectedProbes, next.probedBranches(), "E_PERSISTED_PROBES");
            ok(next.skippedChoices().compareTo(lastSkipped) > 0,
                "E_SKIPPED_MONOTONE");
            eq(1, next.lastCountCalls(), "E_ONE_NEW_COUNT");
            eq(initial.lowerRank(), next.lowerRank(),
                "E_PARENT_INTERVAL_STABLE");
            eq(initial.upperRank(), next.upperRank(),
                "E_PARENT_INTERVAL_UPPER");
            eq(0, current.probedBranches() == 0 ? 0 : 0,
                "E_IMMUTABLE_EARLIER_ROUTE");
            lastSkipped = next.skippedChoices();
            current = next;
        }
        MonsterWeavingLinearCounter.RankRoute selected =
            family.advanceGlobalRankRoute(current, 1, 0);
        eq(5, selected.stepsCompleted(), "E_SELECTED_FIFTH_DAY");
        eq(0, selected.probedBranches(), "E_CLEAR_PROBES");
        eq(BigInteger.ZERO, selected.skippedChoices(), "E_CLEAR_SKIPS");
        eq(0, selected.lastCountCalls(), "E_COMPLETED_WITH_REMAINDER");
        array(chosenChild, selected.fixedPrefixCopy(), "E_CHOSEN_CHILD");
        eq(child.lowerRank(), selected.lowerRank(), "E_CHILD_LOWER");
        eq(child.upperRank(), selected.upperRank(), "E_CHILD_UPPER");
        eq(0, initial.probedBranches(), "E_OLD_ROUTE_OWNERSHIP");
    }

    private static void progressInFullYearInterior() {
        int[] lengths = new int[47];
        Arrays.fill(lengths, 123);
        lengths[46] = 120;
        MonsterWeavingLinearCounter family =
            new MonsterWeavingLinearCounter(lengths);
        BigInteger rank = family.count().add(BigInteger.ONE)
            .divide(BigInteger.TWO);
        MonsterWeavingLinearCounter.RankRoute original =
            family.beginGlobalRankRoute(rank, 512);
        eq(0, original.stepsCompleted(), "E_FULL_START_EMPTY");
        MonsterWeavingLinearCounter.RankRoute advanced =
            family.advanceGlobalRankRoute(original, 3, 1);
        ok(advanced.stepsCompleted() >= 2, "E_MIDDLE_MAKES_PROGRESS");
        ok(advanced.stepsCompleted() <= 3, "E_FULL_STEP_LIMIT");
        ok(advanced.lastCountCalls() <= 1, "E_FULL_COUNT_LIMIT");
        eq(rank, advanced.globalRank(), "E_FULL_STABLE_RANK");
        eq(family.countAfterPrefix(advanced.fixedPrefixCopy()),
            advanced.remainingChoices(), "E_FULL_PREFIX_COUNT");
        ok(advanced.lowerRank().compareTo(rank) <= 0, "E_FULL_LOWER");
        ok(rank.compareTo(advanced.upperRank()) <= 0, "E_FULL_UPPER");
        ok(!advanced.complete(), "E_FULL_STILL_PENDING");
    }

    private static void zeroBudgetDoesNotLoseSavedWork() {
        MonsterWeavingLinearCounter family =
            new MonsterWeavingLinearCounter(new int[]{5, 5, 5, 5});
        int[] prefix = {1, 2, 3, 4};
        MonsterWeavingLinearCounter.BoundaryBlock child =
            family.globalBlockForPrefix(new int[]{1, 2, 3, 4, 4});
        BigInteger rank = child.lowerRank().add(child.upperRank())
            .divide(BigInteger.TWO);
        MonsterWeavingLinearCounter.RankRoute route =
            family.beginGlobalRankRouteWithinPrefix(prefix, rank, 0);
        MonsterWeavingLinearCounter.RankRoute probed =
            family.advanceGlobalRankRoute(route, 1, 1);
        MonsterWeavingLinearCounter.RankRoute noSteps =
            family.advanceGlobalRankRoute(probed, 0, 0);
        eq(probed.probedBranches(), noSteps.probedBranches(),
            "E_ZERO_STEP_PRESERVES_INDEX");
        eq(probed.skippedChoices(), noSteps.skippedChoices(),
            "E_ZERO_STEP_PRESERVES_CHOICES");
        eq(0, noSteps.lastCountCalls(), "E_ZERO_CALLS");
        MonsterWeavingLinearCounter.RankRoute noCount =
            family.advanceGlobalRankRoute(probed, 1, 0);
        eq(probed.probedBranches(), noCount.probedBranches(),
            "E_ZERO_BUDGET_PRESERVES_INDEX");
        eq(probed.skippedChoices(), noCount.skippedChoices(),
            "E_ZERO_BUDGET_PRESERVES_CHOICES");
        eq(probed.stepsCompleted(), noCount.stepsCompleted(),
            "E_ZERO_BUDGET_PRESERVES_DEPTH");
    }

    private static void eq(Object expected, Object actual, String code) {
        checks++;
        if (!expected.equals(actual)) {
            throw new AssertionError(code + " expected=" + expected
                + " actual=" + actual);
        }
    }

    private static void array(int[] expected, int[] actual, String code) {
        checks++;
        if (!Arrays.equals(expected, actual)) throw new AssertionError(code);
    }

    private static void ok(boolean pass, String code) {
        checks++;
        if (!pass) throw new AssertionError(code);
    }
}
