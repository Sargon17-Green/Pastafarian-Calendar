package org.pastafari.javalojban;

import java.math.BigInteger;
import java.util.Arrays;
import java.util.List;
import java.util.concurrent.atomic.AtomicReference;

public final class Stage02IncrementalRouteTests {
    private static int checks;

    private Stage02IncrementalRouteTests() {}

    public static void main(String[] args) {
        exhaustiveOracleUnderSingleCountBudget();
        persistSkippedBranchesAcrossCalls();
        progressInFullYearInterior();
        binomialCacheCallOrderNeutrality();
        suffixCountCacheReuseAndEviction();
        partialDpReuseAcrossDistinctSuffixStates();
        concurrentSuffixCountNeutrality();
        multiCallFullYearInteriorWithOneCountPerCall();
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
        BigInteger partition = BigInteger.ZERO;
        for (int month = 1; month <= 4; month++) {
            int[] branch = Arrays.copyOf(prefix, prefix.length + 1);
            branch[branch.length - 1] = month;
            partition = partition.add(family.countAfterPrefix(branch));
        }
        eq(initial.remainingChoices(), partition, "E_EXACT_PARENT_PARTITION");
        MonsterWeavingLinearCounter.RankRoute current = initial;
        BigInteger lastSkipped = BigInteger.ZERO;
        for (int expectedProbes = 1; expectedProbes <= 2; expectedProbes++) {
            int priorIndex = current.probedBranches();
            BigInteger priorSkip = current.skippedChoices();
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
            eq(priorIndex, current.probedBranches(), "E_OLD_INDEX_UNCHANGED");
            eq(priorSkip, current.skippedChoices(), "E_OLD_SUM_UNCHANGED");
            lastSkipped = next.skippedChoices();
            current = next;
        }
        MonsterWeavingLinearCounter.RankRoute selected =
            family.advanceGlobalRankRoute(current, 1, 1);
        eq(5, selected.stepsCompleted(), "E_SELECTED_FIFTH_DAY");
        eq(0, selected.probedBranches(), "E_CLEAR_PROBES");
        eq(BigInteger.ZERO, selected.skippedChoices(), "E_CLEAR_SKIPS");
        eq(1, selected.lastCountCalls(), "E_FINAL_SPLIT_ONE_COUNT");
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


    private static void multiCallFullYearInteriorWithOneCountPerCall() {
        int[] lengths = new int[47];
        Arrays.fill(lengths, 123);
        lengths[46] = 120;
        MonsterWeavingLinearCounter family =
            new MonsterWeavingLinearCounter(lengths);
        BigInteger rank = family.count().add(BigInteger.ONE)
            .divide(BigInteger.TWO);
        MonsterWeavingLinearCounter.RankRoute route =
            family.beginGlobalRankRoute(rank, 512);
        eq(0, route.stepsCompleted(), "E_MULTICALL_MIDDLE_START");
        int totalMoved = 0;
        int totalCounts = 0;
        int callsWithPersistedProbes = 0;
        int auditCacheHits = 0;
        long started = System.nanoTime();
        long routeNanos = 0;
        long auditNanos = 0;

        for (int call = 0; call < 12; call++) {
            MonsterWeavingLinearCounter.RankRoute before = route;
            int[] originalPrefix = before.fixedPrefixCopy();
            int originalProbes = before.probedBranches();
            BigInteger originalSkipped = before.skippedChoices();
            long routeStarted = System.nanoTime();
            MonsterWeavingLinearCounter.RankRoute next =
                family.advanceGlobalRankRoute(before, 8, 1);
            routeNanos += System.nanoTime() - routeStarted;
            int moved = next.stepsCompleted() - before.stepsCompleted();
            ok(moved >= 0 && moved <= 8, "E_MULTICALL_STEP_BUDGET");
            ok(next.lastCountCalls() >= 0 && next.lastCountCalls() <= 1,
                "E_MULTICALL_COUNT_BUDGET");
            ok(moved > 0 || next.probedBranches() > originalProbes,
                "E_MULTICALL_NO_PROGRESS");
            eq(rank, next.globalRank(), "E_MULTICALL_RANK_IMMUTABLE");
            ok(next.lowerRank().compareTo(rank) <= 0
                    && rank.compareTo(next.upperRank()) <= 0,
                "E_MULTICALL_RANK_CONTAINED");
            long auditStarted = System.nanoTime();
            long hitsBeforeAudit = family.suffixCacheHitCount();
            BigInteger independentlyCounted =
                family.countAfterPrefix(next.fixedPrefixCopy());
            auditNanos += System.nanoTime() - auditStarted;
            if (family.suffixCacheHitCount() > hitsBeforeAudit) {
                auditCacheHits++;
            }
            eq(next.remainingChoices(), independentlyCounted,
                "E_MULTICALL_INTERVAL_EXACT");
            array(originalPrefix, before.fixedPrefixCopy(),
                "E_MULTICALL_PREVIOUS_PREFIX_IMMUTABLE");
            eq(originalProbes, before.probedBranches(),
                "E_MULTICALL_PREVIOUS_PROBES_IMMUTABLE");
            eq(originalSkipped, before.skippedChoices(),
                "E_MULTICALL_PREVIOUS_SKIPPED_IMMUTABLE");

            int[] exposed = next.fixedPrefixCopy();
            if (exposed.length > 0) {
                int first = exposed[0];
                exposed[0] = 0;
                eq(first, next.fixedPrefixCopy()[0],
                    "E_MULTICALL_PREFIX_DEFENSIVE_COPY");
            }
            if (next.probedBranches() > originalProbes) {
                callsWithPersistedProbes++;
            }
            totalMoved += moved;
            totalCounts += next.lastCountCalls();
            route = next;
        }
        ok(totalMoved > 0, "E_MULTICALL_MIDDLE_ADVANCED");
        ok(totalCounts <= 12, "E_MULTICALL_TOTAL_COUNT_BUDGET");
        ok(auditCacheHits > 0, "E_MULTICALL_AUDIT_CACHE_USED");
        ok(route.stepsCompleted() < 5778 - 512,
            "E_MULTICALL_NO_FALSE_COMPLETION");
        System.out.println("STAGE_02_MIDDLE_MULTICALL_PASS calls=12"
            + " prefix_days=" + route.stepsCompleted()
            + " branch_counts=" + totalCounts
            + " calls_with_saved_probes=" + callsWithPersistedProbes
            + " audit_cache_hits=" + auditCacheHits
            + " route_ms=" + routeNanos / 1000000
            + " audit_ms=" + auditNanos / 1000000
            + " elapsed_ms=" + (System.nanoTime() - started) / 1000000);
    }

    private static void binomialCacheCallOrderNeutrality() {
        int[] lengths = new int[47];
        Arrays.fill(lengths, 123);
        lengths[46] = 120;
        MonsterWeavingLinearCounter warm =
            new MonsterWeavingLinearCounter(lengths);
        MonsterWeavingLinearCounter cold =
            new MonsterWeavingLinearCounter(lengths);
        int[] first = warm.lexFirst();
        int[] last = warm.lexLast();
        int[] firstPrefix = Arrays.copyOf(first, 7);
        int[] lastPrefix = Arrays.copyOf(last, 7);

        BigInteger expectedFirst = cold.countAfterPrefix(firstPrefix);
        BigInteger expectedLast = cold.countAfterPrefix(lastPrefix);
        eq(expectedFirst, warm.countAfterPrefix(firstPrefix),
            "E_BINOMIAL_COLD_FIRST");
        eq(expectedLast, warm.countAfterPrefix(lastPrefix),
            "E_BINOMIAL_COLD_LAST");
        eq(expectedLast, warm.countAfterPrefix(lastPrefix),
            "E_BINOMIAL_WARM_LAST");
        eq(expectedFirst, warm.countAfterPrefix(firstPrefix),
            "E_BINOMIAL_WARM_FIRST");
        eq(expectedFirst, cold.countAfterPrefix(firstPrefix),
            "E_BINOMIAL_COLD_REVISIT_FIRST");
        eq(expectedLast, cold.countAfterPrefix(lastPrefix),
            "E_BINOMIAL_COLD_REVISIT_LAST");
        eq(cold.count(), warm.count(), "E_BINOMIAL_ROOT_CACHE_NEUTRAL");
    }

    private static void suffixCountCacheReuseAndEviction() {
        int[] lengths = new int[71];
        Arrays.fill(lengths, 1);
        MonsterWeavingLinearCounter warm =
            new MonsterWeavingLinearCounter(lengths);
        MonsterWeavingLinearCounter isolated =
            new MonsterWeavingLinearCounter(lengths);
        int[] full = warm.lexFirst();
        int[] first = Arrays.copyOf(full, 1);
        eq(BigInteger.ONE, isolated.countAfterPrefix(first),
            "E_SUFFIX_COLD_REFERENCE");
        eq(BigInteger.ONE, warm.countAfterPrefix(first),
            "E_SUFFIX_COLD_FIRST");
        long hits = warm.suffixCacheHitCount();
        eq(BigInteger.ONE, warm.countAfterPrefix(first),
            "E_SUFFIX_WARM_FIRST");
        eq(hits + 1, warm.suffixCacheHitCount(),
            "E_SUFFIX_IDENTICAL_STATE_HIT");
        eq(0L, isolated.suffixCacheHitCount(),
            "E_SUFFIX_INSTANCE_OWNERSHIP");

        for (int size = 2; size <= 70; size++) {
            eq(BigInteger.ONE,
                warm.countAfterPrefix(Arrays.copyOf(full, size)),
                "E_SUFFIX_EVICTION_VALUES");
        }
        eq(64, warm.suffixCacheEntryCount(),
            "E_SUFFIX_LRU_BOUND");
        hits = warm.suffixCacheHitCount();
        eq(BigInteger.ONE, warm.countAfterPrefix(Arrays.copyOf(full, 70)),
            "E_SUFFIX_MOST_RECENT_VALUE");
        eq(hits + 1, warm.suffixCacheHitCount(),
            "E_SUFFIX_MOST_RECENT_HIT");
        hits = warm.suffixCacheHitCount();
        eq(BigInteger.ONE, warm.countAfterPrefix(first),
            "E_SUFFIX_EVICTED_RECOMPUTE");
        eq(hits, warm.suffixCacheHitCount(),
            "E_SUFFIX_OLDEST_WAS_EVICTED");
        eq(64, warm.suffixCacheEntryCount(),
            "E_SUFFIX_REINSERT_STILL_BOUNDED");
        eq(0L, isolated.suffixCacheHitCount(),
            "E_SUFFIX_OTHER_INSTANCE_UNTOUCHED");
    }

    private static void partialDpReuseAcrossDistinctSuffixStates() {
        int[] lengths = new int[12];
        Arrays.fill(lengths, 48);
        MonsterWeavingLinearCounter shared =
            new MonsterWeavingLinearCounter(lengths);
        MonsterWeavingLinearCounter independent =
            new MonsterWeavingLinearCounter(lengths);
        int[] first = {1, 2, 3, 4, 5, 6, 7, 8, 9};
        int[] second = {1, 2, 3, 4, 5, 6, 7, 8, 9, 9};
        BigInteger expectedFirst = independent.countAfterPrefix(first);
        BigInteger actualFirst = shared.countAfterPrefix(first);
        eq(expectedFirst, actualFirst, "E_PARTIAL_DP_FIRST_EXACT");
        ok(shared.partialDpCacheEntryCount() > 0,
            "E_PARTIAL_DP_SNAPSHOT_CREATED");
        long hits = shared.partialDpReuseHitCount();
        long completeHits = shared.suffixCacheHitCount();
        BigInteger expectedSecond = independent.countAfterPrefix(second);
        BigInteger actualSecond = shared.countAfterPrefix(second);
        eq(expectedSecond, actualSecond, "E_PARTIAL_DP_SECOND_EXACT");
        ok(shared.partialDpReuseHitCount() > hits,
            "E_PARTIAL_DP_DISTINCT_STATE_REUSE");
        eq(completeHits, shared.suffixCacheHitCount(),
            "E_PARTIAL_DP_NOT_EXACT_STATE_HIT");
        ok(shared.partialDpCacheEntryCount() <= 4,
            "E_PARTIAL_DP_BOUNDED");
        eq(expectedFirst, shared.countAfterPrefix(first),
            "E_PARTIAL_DP_OLD_STATE_NEUTRAL");
        eq(0L, independent.partialDpReuseHitCount(),
            "E_PARTIAL_DP_INSTANCE_INDEPENDENCE");
    }

    private static void concurrentSuffixCountNeutrality() {
        int[] lengths = {2, 3, 2, 3, 2};
        int[][] prefixes = {
            {1}, {1, 1}, {1, 2}, {1, 2, 3},
            {1, 2, 3, 2}, {1, 2, 3, 2, 4}
        };
        MonsterWeavingLinearCounter reference =
            new MonsterWeavingLinearCounter(lengths);
        BigInteger[] expected = new BigInteger[prefixes.length];
        for (int i = 0; i < prefixes.length; i++) {
            expected[i] = reference.countAfterPrefix(prefixes[i]);
        }
        MonsterWeavingLinearCounter shared =
            new MonsterWeavingLinearCounter(lengths);
        AtomicReference<Throwable> failure = new AtomicReference<>();
        Thread[] workers = new Thread[6];
        for (int worker = 0; worker < workers.length; worker++) {
            final int workerNumber = worker;
            workers[worker] = new Thread(() -> {
                try {
                    for (int iteration = 0; iteration < 100; iteration++) {
                        int which = (iteration + workerNumber) % prefixes.length;
                        BigInteger answer =
                            shared.countAfterPrefix(prefixes[which]);
                        if (!expected[which].equals(answer)) {
                            throw new AssertionError("E_SUFFIX_CONCURRENT_VALUE");
                        }
                    }
                } catch (Throwable error) {
                    failure.compareAndSet(null, error);
                }
            });
            workers[worker].start();
        }
        for (Thread worker : workers) {
            try {
                worker.join();
            } catch (InterruptedException exception) {
                Thread.currentThread().interrupt();
                throw new AssertionError("E_SUFFIX_CONCURRENT_INTERRUPTED",
                    exception);
            }
        }
        Throwable problem = failure.get();
        if (problem != null) {
            throw new AssertionError("E_SUFFIX_CONCURRENT", problem);
        }
        ok(shared.suffixCacheHitCount() > 0,
            "E_SUFFIX_CONCURRENT_CACHE_HITS");
        ok(shared.suffixCacheEntryCount() <= 64,
            "E_SUFFIX_CONCURRENT_BOUNDED");
        eq(BigInteger.ONE,
            new MonsterWeavingLinearCounter(new int[]{1}).count(),
            "E_SUFFIX_CONCURRENT_NO_CROSS_OWNER_STATE");
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
