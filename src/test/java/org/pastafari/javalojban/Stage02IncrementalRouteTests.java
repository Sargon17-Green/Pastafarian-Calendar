package org.pastafari.javalojban;

import java.math.BigInteger;
import java.util.Arrays;
import java.util.List;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.concurrent.atomic.AtomicReference;
import java.util.concurrent.CountDownLatch;

public final class Stage02IncrementalRouteTests {
    private static int checks;

    private Stage02IncrementalRouteTests() {}

    public static void main(String[] args) {
        exhaustiveOracleUnderSingleCountBudget();
        siblingBackwardFunctionalOracleDifferential();
        siblingBackwardFunctionalFullYearProbe();
        persistSkippedBranchesAcrossCalls();
        progressInFullYearInterior();
        binomialCacheCallOrderNeutrality();
        suffixCountCacheReuseAndEviction();
        partialDpReuseAcrossDistinctSuffixStates();
        partialDpOpenedGuardAndBoundedEviction();
        closedFormTransitionsMatchSmallOracle();
        partialDpClosedGuardRejectsCrossBoundary();
        concurrentPartialDpReuse();
        concurrentSuffixCountNeutrality();
        multiCallFullYearInteriorWithOneCountPerCall();
        longerInteriorRouteUnderBoundedCalls();
        zeroBudgetDoesNotLoseSavedWork();
        System.out.println("STAGE_02_INCREMENTAL_ROUTE_PASS checks=" + checks
            + " full_days=5778 counts_per_call=1"
            + " heap_mb=" + Runtime.getRuntime().maxMemory() / 1048576);
    }


    private static void siblingBackwardFunctionalOracleDifferential() {
        for (int[] lengths : new int[][] {
                {2, 2, 2}, {2, 3, 2}, {3, 3, 3}, {2, 3, 3, 2}
        }) {
            MonsterWeavingLinearCounter family =
                new MonsterWeavingLinearCounter(lengths);
            NormativeOracle.WeavingFamily oracle =
                new NormativeOracle.WeavingFamily(lengths);
            int n = oracle.count().intValueExact();
            List<int[]> all = new ArrayList<>();
            for (int rank = 1; rank <= n; rank++) {
                all.add(oracle.unrank1(BigInteger.valueOf(rank)));
            }
            Map<String, int[]> prefixes = new LinkedHashMap<>();
            int[] sample = {0, n / 3, 2 * n / 3, n - 1};
            for (int index : sample) {
                int[] weaving = all.get(index);
                for (int size = 0; size <= Math.min(4, weaving.length - 1); size++) {
                    int[] prefix = Arrays.copyOf(weaving, size);
                    prefixes.put(Arrays.toString(prefix), prefix);
                }
            }
            for (int[] prefix : prefixes.values()) {
                BigInteger[] sibling = family.countSiblingBranchSizes(prefix);
                BigInteger total = BigInteger.ZERO;
                for (int month = 0; month < lengths.length; month++) {
                    int expected = 0;
                    for (int[] weaving : all) {
                        if (weaving[prefix.length] != month + 1) continue;
                        if (Arrays.equals(prefix,
                                Arrays.copyOf(weaving, prefix.length))) {
                            expected++;
                        }
                    }
                    eq(BigInteger.valueOf(expected), sibling[month],
                        "E_SIBLING_BACKWARD_ORACLE");
                    total = total.add(sibling[month]);
                }
                eq(family.countAfterPrefix(prefix), total,
                    "E_SIBLING_BACKWARD_PARENT_PARTITION");
            }
        }
    }

    private static void siblingBackwardFunctionalFullYearProbe() {
        int[] lengths = new int[47];
        Arrays.fill(lengths, 123);
        lengths[46] = 120;
        MonsterWeavingLinearCounter family =
            new MonsterWeavingLinearCounter(lengths);
        int[] prefix = {1, 2, 3, 4, 5};
        long started = System.nanoTime();
        BigInteger[] sizes = family.countSiblingBranchSizes(prefix);
        long sharedMillis = (System.nanoTime() - started) / 1000000;
        BigInteger total = BigInteger.ZERO;
        for (BigInteger size : sizes) total = total.add(size);
        eq(family.countAfterPrefix(prefix), total,
            "E_SIBLING_BACKWARD_5778_PARTITION");
        for (int month = 0; month < 3; month++) {
            int[] extended = Arrays.copyOf(prefix, prefix.length + 1);
            extended[prefix.length] = month + 1;
            eq(family.countAfterPrefix(extended), sizes[month],
                "E_SIBLING_BACKWARD_5778_DIRECT_COUNT");
        }
        System.out.println("STAGE_02_SIBLING_BACKWARD_PASS days=5778"
            + " prefix_days=5 branches=6 shared_ms=" + sharedMillis);
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
        BigInteger expectedSecond =
            new MonsterWeavingLinearCounter(lengths).countAfterPrefix(second);
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

    private static void closedFormTransitionsMatchSmallOracle() {
        for (int[] lengths : new int[][]{
                {2, 2, 2}, {2, 2, 2, 2}, {2, 3, 2, 2}
        }) {
            MonsterWeavingLinearCounter family =
                new MonsterWeavingLinearCounter(lengths);
            NormativeOracle.WeavingFamily oracle =
                new NormativeOracle.WeavingFamily(lengths);
            BigInteger total = oracle.count();
            int expected = total.intValueExact();
            int[] opened = new int[lengths.length];
            for (int i = 0; i < opened.length; i++) opened[i] = i + 1;
            BigInteger exact = BigInteger.ZERO;
            for (int rank = 1; rank <= expected; rank++) {
                int[] weaving = oracle.unrank1(BigInteger.valueOf(rank));
                if (weaving.length >= opened.length
                        && Arrays.equals(Arrays.copyOf(weaving,
                            opened.length), opened)) {
                    exact = exact.add(BigInteger.ONE);
                }
            }
            eq(exact, family.countAfterPrefix(opened),
                "E_CLOSED_FORM_ORACLE_EXACT");
            ok(family.closedFormTransitionCount() > 0,
                "E_CLOSED_FORM_ACTUALLY_USED");
            eq(exact, family.countAfterPrefix(opened),
                "E_CLOSED_FORM_REPEATED_EXACT");
        }
        int[] longer = new int[12];
        Arrays.fill(longer, 48);
        int[] prefix = {1, 2, 3, 4, 5, 6, 7, 8, 9};
        MonsterWeavingLinearCounter fast =
            new MonsterWeavingLinearCounter(longer);
        MonsterWeavingLinearCounter reverse =
            new MonsterWeavingLinearCounter(longer);
        eq(reverse.countAfterPrefix(prefix), fast.countAfterPrefix(prefix),
            "E_CLOSED_FORM_LONGER_REFERENCE");
        ok(fast.closedFormTransitionCount() > 0,
            "E_CLOSED_FORM_LONGER_USED");
    }

    private static void partialDpOpenedGuardAndBoundedEviction() {
        int[] lengths = new int[12];
        Arrays.fill(lengths, 48);
        MonsterWeavingLinearCounter family =
            new MonsterWeavingLinearCounter(lengths);
        for (int opened = 8; opened <= 12; opened++) {
            int[] prefix = new int[opened];
            for (int i = 0; i < opened; i++) prefix[i] = i + 1;
            long priorHits = family.partialDpReuseHitCount();
            BigInteger value = family.countAfterPrefix(prefix);
            if (opened == 8 || opened == 9) {
                eq(new MonsterWeavingLinearCounter(lengths)
                    .countAfterPrefix(prefix), value,
                    "E_PARTIAL_DP_OPENED_REFERENCE");
            }
            eq(priorHits, family.partialDpReuseHitCount(),
                "E_PARTIAL_DP_OPENED_MUST_NOT_REUSE");
            ok(family.partialDpCacheEntryCount() <= 4,
                "E_PARTIAL_DP_CACHE_BOUND_DURING_EVICTION");
        }
        ok(family.partialDpEvictionCount() > 0,
            "E_PARTIAL_DP_EVICTION_OBSERVED");
        eq(4, family.partialDpCacheEntryCount(),
            "E_PARTIAL_DP_CACHE_BOUND_AFTER_EVICTION");
    }

    private static void partialDpClosedGuardRejectsCrossBoundary() {
        int[] lengths = new int[12];
        Arrays.fill(lengths, 48);
        MonsterWeavingLinearCounter shared =
            new MonsterWeavingLinearCounter(lengths);
        int[] opened = {1, 2, 3, 4, 5, 6, 7, 8, 9};
        int[] closed = Arrays.copyOf(opened, opened.length + 47);
        Arrays.fill(closed, opened.length, closed.length, 1);

        BigInteger first = shared.countAfterPrefix(opened);
        ok(first.signum() > 0, "E_PARTIAL_DP_CLOSED_BASE");
        ok(shared.partialDpCacheEntryCount() > 0,
            "E_PARTIAL_DP_CLOSED_INITIAL_SNAPSHOT");
        long reused = shared.partialDpReuseHitCount();
        BigInteger reference = new MonsterWeavingLinearCounter(lengths)
            .countAfterPrefix(closed);
        BigInteger actual = shared.countAfterPrefix(closed);
        eq(reference, actual, "E_PARTIAL_DP_CLOSED_REFERENCE");
        eq(reused, shared.partialDpReuseHitCount(),
            "E_PARTIAL_DP_CLOSED_MUST_NOT_REUSE");
        ok(shared.partialDpCacheEntryCount() <= 4,
            "E_PARTIAL_DP_CLOSED_CAP");
        long sameStateHits = shared.suffixCacheHitCount();
        eq(actual, shared.countAfterPrefix(closed),
            "E_PARTIAL_DP_CLOSED_REPEAT");
        eq(sameStateHits + 1, shared.suffixCacheHitCount(),
            "E_PARTIAL_DP_CLOSED_EXACT_CACHE_HIT");
    }

    private static void concurrentPartialDpReuse() {
        int[] lengths = new int[12];
        Arrays.fill(lengths, 48);
        int[][] prefixes = new int[4][];
        BigInteger[] expected = new BigInteger[4];
        for (int i = 0; i < 4; i++) {
            prefixes[i] = new int[10 + i];
            for (int j = 0; j < 9; j++) prefixes[i][j] = j + 1;
            for (int j = 9; j < prefixes[i].length; j++) {
                prefixes[i][j] = 9;
            }
            expected[i] = new MonsterWeavingLinearCounter(lengths)
                .countAfterPrefix(prefixes[i]);
        }
        MonsterWeavingLinearCounter shared =
            new MonsterWeavingLinearCounter(lengths);
        shared.countAfterPrefix(new int[]{1, 2, 3, 4, 5, 6, 7, 8, 9});
        long hitBaseline = shared.partialDpReuseHitCount();
        CountDownLatch start = new CountDownLatch(1);
        AtomicReference<Throwable> failure = new AtomicReference<>();
        Thread[] workers = new Thread[4];
        for (int i = 0; i < 4; i++) {
            final int index = i;
            workers[i] = new Thread(() -> {
                try {
                    start.await();
                    for (int j = 0; j < 16; j++) {
                        BigInteger answer = shared.countAfterPrefix(prefixes[index]);
                        if (!expected[index].equals(answer)) {
                            throw new AssertionError("E_PARTIAL_DP_THREAD_VALUE");
                        }
                    }
                } catch (Throwable problem) {
                    failure.compareAndSet(null, problem);
                }
            });
            workers[i].start();
        }
        start.countDown();
        for (Thread worker : workers) {
            try {
                worker.join();
            } catch (InterruptedException problem) {
                Thread.currentThread().interrupt();
                throw new AssertionError("E_PARTIAL_DP_THREAD_INTERRUPTED",
                    problem);
            }
        }
        if (failure.get() != null) {
            throw new AssertionError("E_PARTIAL_DP_CONCURRENT", failure.get());
        }
        ok(shared.partialDpReuseHitCount() > hitBaseline,
            "E_PARTIAL_DP_CONCURRENT_REUSE");
        ok(shared.partialDpCacheEntryCount() <= 4,
            "E_PARTIAL_DP_CONCURRENT_CACHE_BOUND");
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

    private static void longerInteriorRouteUnderBoundedCalls() {
        int[] lengths = new int[47];
        Arrays.fill(lengths, 123);
        lengths[46] = 120;
        MonsterWeavingLinearCounter family =
            new MonsterWeavingLinearCounter(lengths);
        BigInteger target = family.count().add(BigInteger.ONE)
            .divide(BigInteger.TWO);
        MonsterWeavingLinearCounter.RankRoute current =
            family.beginGlobalRankRoute(target, 512);
        int moved = 0;
        int counted = 0;
        long partialHitsBefore = family.partialDpReuseHitCount();
        long exactHitsBefore = family.suffixCacheHitCount();
        long closedFormBefore = family.closedFormTransitionCount();
        long started = System.nanoTime();
        for (int call = 0; call < 24; call++) {
            MonsterWeavingLinearCounter.RankRoute before = current;
            MonsterWeavingLinearCounter.RankRoute next =
                family.advanceGlobalRankRoute(before, 16, 2);
            int advanced = next.stepsCompleted() - before.stepsCompleted();
            ok(advanced >= 0 && advanced <= 16,
                "E_LONG_ROUTE_STEP_BUDGET");
            ok(next.lastCountCalls() >= 0 && next.lastCountCalls() <= 2,
                "E_LONG_ROUTE_COUNT_BUDGET");
            eq(target, next.globalRank(), "E_LONG_ROUTE_RANK_STABLE");
            ok(next.lowerRank().compareTo(target) <= 0
                    && next.upperRank().compareTo(target) >= 0,
                "E_LONG_ROUTE_GLOBAL_INTERVAL");
            ok(next.lowerRank().compareTo(before.lowerRank()) >= 0
                    && next.upperRank().compareTo(before.upperRank()) <= 0,
                "E_LONG_ROUTE_NESTED_INTERVAL");
            ok(advanced > 0 || next.probedBranches() > before.probedBranches(),
                "E_LONG_ROUTE_PROGRESS");
            moved += advanced;
            counted += next.lastCountCalls();
            current = next;
        }
        eq(moved, current.stepsCompleted(),
            "E_LONG_ROUTE_PREFIX_TOTAL");
        ok(moved >= 5, "E_LONG_ROUTE_DISTINCT_PROGRESS");
        ok(counted <= 48, "E_LONG_ROUTE_TOTAL_COUNT_BUDGET");
        long afterRoute = System.nanoTime();
        long partialHits = family.partialDpReuseHitCount() - partialHitsBefore;
        long exactHits = family.suffixCacheHitCount() - exactHitsBefore;
        long closedFormSkips =
            family.closedFormTransitionCount() - closedFormBefore;
        eq(current.remainingChoices(),
            family.countAfterPrefix(current.fixedPrefixCopy()),
            "E_LONG_ROUTE_SUFFIX_EXACT");
        long afterAudit = System.nanoTime();
        ok(family.partialDpCacheEntryCount() <= 4,
            "E_LONG_ROUTE_PARTIAL_DP_CACHE_BUDGET");
        ok(!current.complete(), "E_LONG_ROUTE_NOT_FALSE_COMPLETION");
        System.out.println("STAGE_02_LONG_INTERIOR_ROUTE_PASS calls=24"
            + " prefix_days=" + moved + " counts=" + counted
            + " partial_dp_hits=" + partialHits
            + " exact_suffix_hits=" + exactHits
            + " closed_form_skips=" + closedFormSkips
            + " route_ms=" + (afterRoute - started) / 1000000
            + " audit_ms=" + (afterAudit - afterRoute) / 1000000
            + " elapsed_ms=" + (System.nanoTime() - started) / 1000000);
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
