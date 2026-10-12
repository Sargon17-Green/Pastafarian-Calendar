package org.pastafari.javalojban;

import java.math.BigInteger;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

public final class Stage02NearEdgeRoutingTests {
    private static int checks;

    private Stage02NearEdgeRoutingTests() {}

    public static void main(String[] args) {
        oracleNearEdgeRoutes();
        fullYearFirstAndLastNeighbors();
        interiorPrefixRouting();
        zeroBudgetAndOwnership();
        System.out.println("STAGE_02_NEAR_EDGE_ROUTING_PASS checks=" + checks
            + " full_days=5778 neighbor_distance="
            + MonsterWeavingLinearCounter.MAX_EDGE_DISTANCE
            + " heap_mb=" + Runtime.getRuntime().maxMemory() / 1048576);
    }

    private static void oracleNearEdgeRoutes() {
        for (int[] lengths : new int[][]{
                {2, 2, 2}, {2, 3, 2}, {3, 3, 3}, {2, 3, 3, 2}
        }) {
            MonsterWeavingLinearCounter family = new MonsterWeavingLinearCounter(lengths);
            NormativeOracle.WeavingFamily oracle = new NormativeOracle.WeavingFamily(lengths);
            int total = oracle.count().intValueExact();
            for (int r = 1; r <= total; r++) {
                if (r > MonsterWeavingLinearCounter.MAX_EDGE_DISTANCE + 1
                        && total - r > MonsterWeavingLinearCounter.MAX_EDGE_DISTANCE) {
                    continue;
                }
                BigInteger rank = BigInteger.valueOf(r);
                MonsterWeavingLinearCounter.RankRoute route =
                    family.beginGlobalRankRoute(rank, 0);
                for (int round = 0; !route.complete() && round < 30; round++) {
                    MonsterWeavingLinearCounter.RankRoute older = route;
                    route = family.advanceGlobalRankRoute(route, 2, 1);
                    ok(route.stepsCompleted() > older.stepsCompleted(),
                        "E_EDGE_ROUTE_PROGRESS");
                    ok(route.lastCountCalls() <= 1, "E_EDGE_ONE_COUNT");
                    eq(rank, route.globalRank(), "E_GLOBAL_RANK_STABLE");
                    MonsterWeavingLinearCounter.BoundaryBlock exact =
                        family.globalBlockForPrefix(route.fixedPrefixCopy());
                    eq(exact.lowerRank(), route.lowerRank(), "E_ORACLE_INTERVAL_LOWER");
                    eq(exact.upperRank(), route.upperRank(), "E_ORACLE_INTERVAL_UPPER");
                    ok(route.remainingChoices().signum() > 0, "E_POSITIVE_CHOICES");
                }
                ok(route.complete(), "E_EDGE_COMPLETE");
                array(oracle.unrank1(rank), family.finishGlobalRankRoute(route),
                    "E_ORACLE_NEIGHBORS");
            }
        }
    }

    private static void fullYearFirstAndLastNeighbors() {
        int[] lengths = new int[47];
        Arrays.fill(lengths, 123);
        lengths[46] = 120;
        MonsterWeavingLinearCounter family = new MonsterWeavingLinearCounter(lengths);
        BigInteger total = family.count();
        for (BigInteger rank : List.of(BigInteger.ONE, BigInteger.valueOf(5),
                total.subtract(BigInteger.valueOf(4)), total)) {
            MonsterWeavingLinearCounter.RankRoute initial =
                family.beginGlobalRankRoute(rank, 0);
            eq(0, initial.stepsCompleted(), "E_FULL_START_EMPTY");
            MonsterWeavingLinearCounter.RankRoute advanced =
                family.advanceGlobalRankRoute(initial, 512, 1);
            eq(512, advanced.stepsCompleted(), "E_FULL_ONE_CHUNK");
            eq(1, advanced.lastCountCalls(), "E_FULL_EXACT_SINGLE_COUNT");
            eq(rank, advanced.globalRank(), "E_FULL_RANK");
            int[] expected = family.unrank1(rank);
            array(Arrays.copyOf(expected, 512),
                advanced.fixedPrefixCopy(), "E_FULL_MATCH_EDGE_SEQUENCE");
            eq(family.countAfterPrefix(advanced.fixedPrefixCopy()),
                advanced.remainingChoices(), "E_FULL_SUFFIX_COUNT");
            ok(advanced.lowerRank().compareTo(rank) <= 0, "E_FULL_LOWER");
            ok(rank.compareTo(advanced.upperRank()) <= 0, "E_FULL_UPPER");
            ok(!advanced.complete(), "E_FULL_STILL_PARTIAL");
            MonsterWeavingLinearCounter.RankRoute deeper =
                family.advanceGlobalRankRoute(advanced, 512, 1);
            eq(1024, deeper.stepsCompleted(), "E_FULL_SECOND_CHUNK");
            eq(1, deeper.lastCountCalls(), "E_FULL_SECOND_COUNT");
            array(Arrays.copyOf(expected, 1024),
                deeper.fixedPrefixCopy(), "E_FULL_SECOND_PREFIX");
        }
    }

    private static void interiorPrefixRouting() {
        int[] lengths = new int[47];
        Arrays.fill(lengths, 123);
        lengths[46] = 120;
        MonsterWeavingLinearCounter family = new MonsterWeavingLinearCounter(lengths);
        int[] prefix = Arrays.copyOf(family.lexFirst(), 5778 - 525);
        prefix[prefix.length - 1]++;
        MonsterWeavingLinearCounter.BoundaryBlock block =
            family.globalBlockForPrefix(prefix);
        ok(block.size().compareTo(BigInteger.valueOf(25)) > 0,
            "E_INTERIOR_NONTRIVIAL");
        for (BigInteger rank : List.of(
                block.lowerRank().add(BigInteger.valueOf(3)),
                block.upperRank().subtract(BigInteger.valueOf(3)))) {
            MonsterWeavingLinearCounter.RankRoute original =
                family.beginGlobalRankRouteWithinPrefix(prefix, rank, 512);
            ok(!original.complete(), "E_INTERIOR_NEEDS_SUFFIX");
            MonsterWeavingLinearCounter.RankRoute complete =
                family.advanceGlobalRankRoute(original, 13, 1);
            eq(5778 - 512, complete.stepsCompleted(), "E_INTERIOR_CHUNK");
            eq(1, complete.lastCountCalls(), "E_INTERIOR_SINGLE_COUNT");
            ok(complete.complete(), "E_INTERIOR_READY");
            eq(rank, complete.globalRank(), "E_INTERIOR_RANK");
            MonsterWeavingLinearCounter.BoundaryBlock oracle =
                family.globalBlockForPrefix(complete.fixedPrefixCopy());
            eq(oracle.lowerRank(), complete.lowerRank(), "E_INTERIOR_EXACT_LOWER");
            eq(oracle.upperRank(), complete.upperRank(), "E_INTERIOR_EXACT_UPPER");
            int[] expected = family.unrankGlobalWithinPrefix(
                complete.fixedPrefixCopy(), rank);
            array(expected, family.finishGlobalRankRoute(complete),
                "E_INTERIOR_FULL_MATCH");
            ok(complete.lowerRank().compareTo(block.lowerRank()) >= 0,
                "E_INTERIOR_SUBBLOCK_LOWER");
            ok(complete.upperRank().compareTo(block.upperRank()) <= 0,
                "E_INTERIOR_SUBBLOCK_UPPER");
        }
    }

    private static void zeroBudgetAndOwnership() {
        MonsterWeavingLinearCounter family =
            new MonsterWeavingLinearCounter(new int[]{3, 3, 3});
        MonsterWeavingLinearCounter.RankRoute route =
            family.beginGlobalRankRoute(BigInteger.ONE, 0);
        MonsterWeavingLinearCounter.RankRoute noWork =
            family.advanceGlobalRankRoute(route, 0, 1);
        eq(0, noWork.stepsCompleted(), "E_ZERO_STEPS");
        eq(0, noWork.lastCountCalls(), "E_ZERO_COUNT");
        MonsterWeavingLinearCounter.RankRoute forced =
            family.advanceGlobalRankRoute(route, 2, 0);
        ok(forced.stepsCompleted() >= 1, "E_NO_COUNT_FORCED");
        eq(0, forced.lastCountCalls(), "E_NO_COUNT_COST");
        eq(0, route.stepsCompleted(), "E_ORIGINAL_UNCHANGED");
        MonsterWeavingLinearCounter.RankRoute accelerated =
            family.advanceGlobalRankRoute(route, 2, 1);
        eq(2, accelerated.stepsCompleted(), "E_EDGE_ACCELERATED");
        eq(1, accelerated.lastCountCalls(), "E_EDGE_BOUNDED");
        int[] external = accelerated.fixedPrefixCopy();
        external[0] = 0;
        eq(1, accelerated.fixedPrefixCopy()[0], "E_PREFIX_OWNED");
    }

    private static void eq(Object wanted, Object got, String code) {
        checks++;
        if (!wanted.equals(got)) {
            throw new AssertionError(code + " wanted=" + wanted + " got=" + got);
        }
    }

    private static void array(int[] wanted, int[] got, String code) {
        checks++;
        if (!Arrays.equals(wanted, got)) {
            throw new AssertionError(code);
        }
    }

    private static void ok(boolean pass, String code) {
        checks++;
        if (!pass) throw new AssertionError(code);
    }
}
