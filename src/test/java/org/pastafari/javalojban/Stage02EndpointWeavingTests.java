package org.pastafari.javalojban;

import java.math.BigInteger;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

public final class Stage02EndpointWeavingTests {
    private static int checks;

    public static void main(String[] args) {
        testOracleCount();
        testOracleUnrank();
        testConditionalPrefixes();
        testLongerMonthFamilies();
        testBinomialAndCatalanIdentities();
        testNearLimitDomain();
        testHigherBoundCountAndUnrank();
        testBoundsAndOwnership();
        System.out.println("STAGE_02_ENDPOINT_WEAVING_PASS checks=" + checks);
    }

    private static void testOracleCount() {
        for (int count = 1; count <= 5; count++) {
            int cases = 1;
            for (int j = 0; j < count; j++) cases *= 3;
            for (int code = 0; code < cases; code++) {
                int[] values = new int[count];
                int r = code;
                for (int i = 0; i < count; i++) {
                    values[i] = 1 + r % 3;
                    r /= 3;
                }
                BigInteger expected = new NormativeOracle.WeavingFamily(values).count();
                BigInteger actual = new MonsterWeavingEndpointDP(values).count();
                eq(expected, actual, "E_COUNT_ORACLE");
            }
        }
        for (int[] lengths : new int[][]{{4, 5, 6}, {4, 123, 4},
                {5, 5, 5, 5, 5}, {8, 6, 7, 5, 4, 6}}) {
            eq(new NormativeOracle.WeavingFamily(lengths).count(),
                new MonsterWeavingEndpointDP(lengths).count(), "E_MONTH_DOMAIN_ORACLE");
        }
    }

    private static void testOracleUnrank() {
        for (int[] lengths : new int[][]{{1}, {2, 2}, {2, 3, 2},
                {3, 2, 3, 2}, {4, 4, 4}, {4, 5, 6},
                {2, 2, 2, 2, 2, 2}}) {
            MonsterWeavingEndpointDP independent = new MonsterWeavingEndpointDP(lengths);
            NormativeOracle.WeavingFamily oracle = new NormativeOracle.WeavingFamily(lengths);
            BigInteger total = independent.count();
            for (BigInteger rank : sampled(total)) {
                arr(oracle.unrank1(rank), independent.unrank1(rank), "E_UNRANK_ORACLE");
            }
        }
    }

    private static void testConditionalPrefixes() {
        for (int[] lengths : new int[][]{{3, 3, 3}, {2, 3, 4, 2}, {4, 4, 4},
                {1, 2, 4}, {3, 4, 4}}) {
            MonsterWeavingEndpointDP independent = new MonsterWeavingEndpointDP(lengths);
            NormativeOracle.WeavingFamily oracle = new NormativeOracle.WeavingFamily(lengths);
            BigInteger total = oracle.count();
            List<int[]> prefixes = new ArrayList<>();
            prefixes.add(new int[0]);
            for (BigInteger rank : sampled(total)) {
                int[] sequence = oracle.unrank1(rank);
                for (int k = 1; k <= Math.min(6, sequence.length); k++) {
                    prefixes.add(Arrays.copyOf(sequence, k));
                }
            }
            for (int[] prefix : prefixes) {
                BigInteger expected = oraclePrefixCount(oracle, total, prefix);
                eq(expected, independent.countAfterPrefix(prefix), "E_PREFIX_ORACLE");
            }
        }
    }

    private static BigInteger oraclePrefixCount(NormativeOracle.WeavingFamily oracle,
                                                 BigInteger total, int[] prefix) {
        int max = total.intValueExact();
        if (max > 15000) throw new AssertionError("E_SAMPLE_TOO_LARGE");
        long matches = 0;
        for (int rank = 1; rank <= max; rank++) {
            int[] sequence = oracle.unrank1(BigInteger.valueOf(rank));
            if (sequence.length < prefix.length) continue;
            boolean same = true;
            for (int i = 0; i < prefix.length; i++) {
                if (sequence[i] != prefix[i]) { same = false; break; }
            }
            if (same) matches++;
        }
        return BigInteger.valueOf(matches);
    }

    private static void testLongerMonthFamilies() {
        for (int[] values : new int[][]{
                {40, 40, 40, 40, 40, 40},
                {4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4},
                {4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4},
                {9, 9, 9, 9, 9, 9, 9, 9, 9, 9}
        }) {
            MonsterWeavingEndpointDP dp = new MonsterWeavingEndpointDP(values);
            BigInteger count = dp.count();
            ok(count.signum() > 0, "E_LONG_POSITIVE");
            ok(count.bitLength() > 1, "E_LONG_MULTIPLE");
        }
        int[] fortySeven = new int[47];
        Arrays.fill(fortySeven, 4);
        BigInteger exact = new MonsterWeavingEndpointDP(fortySeven).count();
        ok(exact.signum() > 0, "E_47_MONTHS_COUNT");
    }


    private static BigInteger binomial(int n, int k) {
        BigInteger result = BigInteger.ONE;
        for (int j = 1; j <= k; j++) {
            result = result.multiply(BigInteger.valueOf(n - j + 1))
                .divide(BigInteger.valueOf(j));
        }
        return result;
    }

    private static void testBinomialAndCatalanIdentities() {
        for (int first : new int[]{2, 3, 4, 7, 17, 64, 123}) {
            for (int last : new int[]{2, 3, 4, 7, 17, 64, 123}) {
                int[] lengths = {first, last};
                BigInteger expected = binomial(first + last - 2, first - 1);
                eq(expected, new MonsterWeavingEndpointDP(lengths).count(),
                    "E_TWO_MONTH_BINOMIAL");
            }
        }
        for (int months = 1; months <= 47; months++) {
            int[] pairs = new int[months];
            int[] singletons = new int[months];
            Arrays.fill(pairs, 2);
            Arrays.fill(singletons, 1);
            BigInteger catalan = binomial(2 * months, months)
                .divide(BigInteger.valueOf(months + 1));
            eq(catalan, new MonsterWeavingEndpointDP(pairs).count(),
                "E_CATALAN_TWO_DAY_MONTHS");
            eq(BigInteger.ONE, new MonsterWeavingEndpointDP(singletons).count(),
                "E_SINGLETON_ORDER");
        }
    }

    private static void testNearLimitDomain() {
        int[] lengths = {123, 123, 123, 123};
        MonsterWeavingEndpointDP family = new MonsterWeavingEndpointDP(lengths);
        BigInteger count = family.count();
        ok(count.signum() > 0, "E_492_DAY_DOMAIN");
        ok(count.bitLength() > 100, "E_492_DAY_PRECISION");
        eq(count, family.countAfterPrefix(new int[0]),
            "E_492_DAY_EMPTY_PREFIX");
        eq(count, family.countAfterPrefix(new int[]{1}),
            "E_492_DAY_FIRST_MONTH");
    }


    private static void testHigherBoundCountAndUnrank() {
        int[] nearLimit = {123, 123, 123, 123, 123, 123};
        MonsterWeavingEndpointDP large = new MonsterWeavingEndpointDP(nearLimit);
        BigInteger count = large.count();
        ok(count.signum() > 0, "E_738_DAY_POSITIVE");
        ok(count.bitLength() > 1000, "E_738_DAY_BIGINTEGER");
        eq(count, large.countAfterPrefix(new int[]{1}), "E_738_DAY_PREFIX");
        for (int[] lengths : new int[][]{
                {4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4,
                 4, 4, 4, 4, 4},
                {36, 36, 36, 36}
        }) {
            MonsterWeavingEndpointDP family = new MonsterWeavingEndpointDP(lengths);
            BigInteger top = family.count();
            int[] first = family.unrank1(BigInteger.ONE);
            int[] last = family.unrank1(top);
            int[] frequencies = new int[lengths.length];
            for (int value : first) frequencies[value - 1]++;
            arr(lengths, frequencies, "E_UNRANK_LONG_FIRST");
            Arrays.fill(frequencies, 0);
            for (int value : last) frequencies[value - 1]++;
            arr(lengths, frequencies, "E_UNRANK_LONG_LAST");
            eq(BigInteger.ONE, family.countAfterPrefix(first), "E_LONG_FIRST_COMPLETES");
            eq(BigInteger.ONE, family.countAfterPrefix(last), "E_LONG_LAST_COMPLETES");
        }
    }

    private static void testBoundsAndOwnership() {
        int[] lengths = {4, 5, 6};
        MonsterWeavingEndpointDP dp = new MonsterWeavingEndpointDP(lengths);
        BigInteger first = dp.count();
        lengths[0] = 700;
        eq(first, dp.count(), "E_COPY_INPUT");
        fails("E_WEAVE_EMPTY", () -> new MonsterWeavingEndpointDP(new int[0]));
        fails("E_WEAVE_LENGTH", () -> new MonsterWeavingEndpointDP(new int[]{0, 5}));
        fails("E_WEAVE_LIMIT", () -> new MonsterWeavingEndpointDP(new int[]{769}));
        int[] longSet = new int[47];
        Arrays.fill(longSet, 17);
        fails("E_WEAVE_LIMIT", () -> new MonsterWeavingEndpointDP(longSet));
        fails("E_WEAVE_UNRANK_LIMIT", () -> new MonsterWeavingEndpointDP(
            new int[]{54, 54, 53}).unrank1(BigInteger.ONE));
        fails("E_WEAVE_RANK", () -> dp.unrank1(BigInteger.ZERO));
        fails("E_WEAVE_RANK", () -> dp.unrank1(dp.count().add(BigInteger.ONE)));
        fails("E_WEAVE_PREFIX", () -> dp.countAfterPrefix(new int[]{2}));
        fails("E_WEAVE_PREFIX", () -> dp.countAfterPrefix(new int[]{1, 1, 1, 1, 1}));
        eq(BigInteger.ONE, dp.countAfterPrefix(dp.unrank1(BigInteger.ONE)),
            "E_FINISHED_SUFFIX");
    }

    private static List<BigInteger> sampled(BigInteger total) {
        List<BigInteger> ranks = new ArrayList<>();
        ranks.add(BigInteger.ONE);
        for (BigInteger option : new BigInteger[]{total.add(BigInteger.ONE).divide(
                BigInteger.TWO), total}) {
            if (!ranks.contains(option)) ranks.add(option);
        }
        return ranks;
    }

    private static void fails(String code, Runnable task) {
        checks++;
        try { task.run(); }
        catch (IllegalArgumentException ex) {
            if (code.equals(ex.getMessage())) return;
            throw new AssertionError("E_WRONG_ERROR expected=" + code + " actual="
                + ex.getMessage(), ex);
        }
        throw new AssertionError("E_MISSING_ERROR " + code);
    }

    private static void eq(Object expected, Object actual, String code) {
        checks++;
        if (!expected.equals(actual)) {
            throw new AssertionError(code + " expected=" + expected + " actual=" + actual);
        }
    }

    private static void arr(int[] expected, int[] actual, String code) {
        checks++;
        if (!Arrays.equals(expected, actual)) {
            throw new AssertionError(code + " expected=" + Arrays.toString(expected)
                + " actual=" + Arrays.toString(actual));
        }
    }

    private static void ok(boolean condition, String code) {
        checks++;
        if (!condition) throw new AssertionError(code);
    }
}
