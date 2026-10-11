package org.pastafari.javalojban;

import java.math.BigInteger;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

public final class Stage02LinearWeavingTests {
    private static int checks;

    public static void main(String[] args) {
        testIndependentOracle();
        testSmallSuffixes();
        testMediumDifferential();
        testRankAgainstOracleAndExisting();
        testLongRankInversion();
        testFullYearCapacity();
        testFailuresAndOwnership();
        System.out.println("STAGE_02_LINEAR_WEAVING_PASS checks=" + checks);
    }

    private static void testIndependentOracle() {
        for (int months = 1; months <= 5; months++) {
            int cases = 1;
            for (int i = 0; i < months; i++) cases *= 3;
            for (int mask = 0; mask < cases; mask++) {
                int[] lengths = new int[months];
                int encoded = mask;
                for (int i = 0; i < months; i++) {
                    lengths[i] = encoded % 3 + 1;
                    encoded /= 3;
                }
                eq(new NormativeOracle.WeavingFamily(lengths).count(),
                    new MonsterWeavingLinearCounter(lengths).count(),
                    "E_ORACLE_TOTAL");
            }
        }
    }

    private static void testSmallSuffixes() {
        for (int[] lengths : new int[][]{
                {1, 2, 3}, {2, 2, 2}, {3, 3, 3},
                {2, 3, 2, 3}, {3, 3, 2, 2}
        }) {
            NormativeOracle.WeavingFamily oracle =
                new NormativeOracle.WeavingFamily(lengths);
            BigInteger total = oracle.count();
            int limit = total.intValueExact();
            int[] sample = new int[]{1, Math.max(1, limit / 2), limit};
            MonsterWeavingLinearCounter linear = new MonsterWeavingLinearCounter(lengths);
            for (int position : sample) {
                int[] sequence = oracle.unrank1(BigInteger.valueOf(position));
                for (int k = 0; k <= sequence.length; k++) {
                    int[] prefix = Arrays.copyOf(sequence, k);
                    int matching = 0;
                    for (int rank = 1; rank <= limit; rank++) {
                        int[] next = oracle.unrank1(BigInteger.valueOf(rank));
                        boolean valid = true;
                        for (int p = 0; p < k; p++) {
                            if (prefix[p] != next[p]) {
                                valid = false;
                                break;
                            }
                        }
                        if (valid) matching++;
                    }
                    eq(BigInteger.valueOf(matching),
                        linear.countAfterPrefix(prefix), "E_ORACLE_PREFIX");
                }
            }
        }
    }

    private static void testMediumDifferential() {
        for (int[] values : new int[][]{
                {4, 123, 4, 5}, {9, 8, 7, 6},
                {84, 84, 84}, {123, 123, 123, 123},
                {123, 123, 123, 123, 123, 123, 123, 123}
        }) {
            MonsterWeavingLinearCounter linear = new MonsterWeavingLinearCounter(values);
            MonsterWeavingEndpointDP established = new MonsterWeavingEndpointDP(values);
            BigInteger expected = established.count();
            eq(expected, linear.count(), "E_EXISTING_ENGINE");
            eq(expected, linear.countAfterPrefix(new int[]{1}), "E_FIRST_MONTH");
            eq(expected, linear.countAfterPrefix(new int[0]), "E_EMPTY_PREFIX");
        }
    }


    private static void testRankAgainstOracleAndExisting() {
        for (int[] lengths : new int[][]{
                {1, 1, 1}, {2, 2, 2}, {2, 3, 4, 2},
                {4, 5, 6}, {7, 8, 9}, {84, 84, 84},
                {96, 96, 96, 96}
        }) {
            MonsterWeavingLinearCounter linear = new MonsterWeavingLinearCounter(lengths);
            MonsterWeavingEndpointDP established = new MonsterWeavingEndpointDP(lengths);
            BigInteger total = linear.count();
            for (BigInteger rank : new BigInteger[]{
                    BigInteger.ONE, total.add(BigInteger.ONE).divide(BigInteger.TWO), total}) {
                int[] result = linear.unrank1(rank);
                arr(established.unrank1(rank), result, "E_EXISTING_UNRANK");
                eq(rank, linear.rank1(result), "E_EXISTING_RANK");
                if (Arrays.stream(lengths).sum() <= 16) {
                    arr(new NormativeOracle.WeavingFamily(lengths).unrank1(rank),
                        result, "E_ORACLE_RANK");
                }
            }
        }
    }

    private static void testLongRankInversion() {
        for (int[] lengths : new int[][]{
                {123, 123, 123, 123},
                {100, 100, 100, 100, 100},
                {123, 123, 123, 123, 20}
        }) {
            MonsterWeavingLinearCounter linear = new MonsterWeavingLinearCounter(lengths);
            BigInteger total = linear.count();
            for (BigInteger rank : new BigInteger[]{
                    BigInteger.ONE, total.add(BigInteger.ONE).divide(BigInteger.TWO), total}) {
                int[] sequence = linear.unrank1(rank);
                eq(Arrays.stream(lengths).sum(), sequence.length, "E_LONG_RANK_LENGTH");
                eq(rank, linear.rank1(sequence), "E_LONG_RANK_INVERSION");
                int[] seen = new int[lengths.length];
                for (int month : sequence) seen[month - 1]++;
                arr(lengths, seen, "E_LONG_RANK_COUNTS");
            }
        }
    }

    private static void testFullYearCapacity() {
        int[] lengths = new int[47];
        Arrays.fill(lengths, 123);
        lengths[46] = 120;
        eq(5778, Arrays.stream(lengths).sum(), "E_YEAR_CEILING");
        MonsterWeavingLinearCounter fullYear = new MonsterWeavingLinearCounter(lengths);
        BigInteger ways = fullYear.count();
        positive(ways, "E_FULL_YEAR_COUNT");
        positive(ways.subtract(BigInteger.ONE), "E_FULL_YEAR_NONTRIVIAL");
        eq(ways, fullYear.countAfterPrefix(new int[]{1}), "E_FULL_YEAR_FIRST");
        eq(ways, fullYear.count(), "E_FULL_YEAR_REPEAT");
    }

    private static void testFailuresAndOwnership() {
        int[] lengths = {3, 4, 5};
        MonsterWeavingLinearCounter stable = new MonsterWeavingLinearCounter(lengths);
        BigInteger count = stable.count();
        lengths[0] = 999;
        eq(count, stable.count(), "E_INPUT_DEFENSIVE_COPY");
        fails("E_WEAVE_EMPTY", () -> new MonsterWeavingLinearCounter(null));
        fails("E_WEAVE_LENGTH", () -> new MonsterWeavingLinearCounter(new int[]{0}));
        fails("E_WEAVE_LIMIT", () -> new MonsterWeavingLinearCounter(
            new int[]{5778, 1}));
        fails("E_WEAVE_PREFIX", () -> stable.countAfterPrefix(null));
        fails("E_WEAVE_PREFIX", () -> stable.countAfterPrefix(new int[]{2}));
        fails("E_WEAVE_PREFIX", () -> stable.countAfterPrefix(new int[]{1, 1, 1, 1}));
        fails("E_WEAVE_RANK", () -> stable.unrank1(BigInteger.ZERO));
        fails("E_WEAVE_RANK", () -> stable.unrank1(stable.count().add(BigInteger.ONE)));
        fails("E_WEAVE_SEQUENCE", () -> stable.rank1(new int[]{1, 2, 3}));
        MonsterWeavingLinearCounter longRange = new MonsterWeavingLinearCounter(
            new int[]{123, 123, 123, 123, 21});
        fails("E_WEAVE_UNRANK_LIMIT", () -> longRange.unrank1(
            longRange.count().add(BigInteger.ONE).divide(BigInteger.TWO)));
        fails("E_WEAVE_RANK_LIMIT", () -> longRange.rank1(new int[0]));
    }

    private static void arr(int[] expected, int[] actual, String code) {
        checks++;
        if (!Arrays.equals(expected, actual)) {
            throw new AssertionError(code);
        }
    }

    private static void eq(Object expected, Object actual, String code) {
        checks++;
        if (!expected.equals(actual)) throw new AssertionError(
            code + " expected=" + expected + " actual=" + actual);
    }

    private static void positive(BigInteger actual, String code) {
        checks++;
        if (actual.signum() <= 0) throw new AssertionError(code);
    }

    private static void fails(String expected, Runnable runnable) {
        checks++;
        try {
            runnable.run();
        } catch (IllegalArgumentException exception) {
            if (expected.equals(exception.getMessage())) return;
            throw new AssertionError(expected + " != " + exception.getMessage(), exception);
        }
        throw new AssertionError("E_MISSING_FAILURE " + expected);
    }
}
