package org.pastafari.javalojban;

import java.math.BigInteger;
import java.util.Arrays;
import java.util.List;

public final class Stage02EdgeWeavingTests {
    private static int checks;

    public static void main(String[] args) {
        testOracleSuccessorsAndPredecessors();
        testWideNeighborRank();
        testFullYearNeighborRank();
        testValidationAndCopyOwnership();
        System.out.println("STAGE_02_EDGE_WEAVING_PASS checks=" + checks
            + " full_days=5778 edge_distance=" + MonsterWeavingLinearCounter.MAX_EDGE_DISTANCE
            + " heap_mb=" + Runtime.getRuntime().maxMemory() / (1024 * 1024));
    }

    private static void testOracleSuccessorsAndPredecessors() {
        for (int months = 1; months <= 4; months++) {
            int cases = 1;
            for (int i = 0; i < months; i++) cases *= 3;
            for (int sample = 0; sample < cases; sample++) {
                int[] lengths = new int[months];
                int encoded = sample;
                for (int j = 0; j < months; j++) {
                    lengths[j] = encoded % 3 + 1;
                    encoded /= 3;
                }
                MonsterWeavingLinearCounter actual = new MonsterWeavingLinearCounter(lengths);
                NormativeOracle.WeavingFamily oracle = new NormativeOracle.WeavingFamily(lengths);
                int total = oracle.count().intValueExact();
                int[] forward = actual.lexFirst();
                array(oracle.unrank1(BigInteger.ONE), forward, "E_ORACLE_FIRST");
                nullValue(actual.lexPrevious(forward), "E_BEFORE_FIRST");
                for (int rank = 1; rank <= total; rank++) {
                    array(oracle.unrank1(BigInteger.valueOf(rank)), forward, "E_ORACLE_NEXT");
                    int[] next = actual.lexNext(forward);
                    if (rank == total) {
                        nullValue(next, "E_AFTER_LAST");
                    } else {
                        positiveLex(forward, next, "E_NEXT_SORT");
                        array(forward, actual.lexPrevious(next), "E_PREVIOUS_INVERSE");
                    }
                    forward = next;
                }
                int[] backward = actual.lexLast();
                for (int rank = total; rank >= 1; rank--) {
                    array(oracle.unrank1(BigInteger.valueOf(rank)), backward, "E_ORACLE_PREVIOUS");
                    backward = actual.lexPrevious(backward);
                }
                nullValue(backward, "E_BEFORE_FIRST_END");
            }
        }
    }

    private static void testWideNeighborRank() {
        for (int[] lengths : new int[][]{
                {123, 123, 123, 123, 25},
                {100, 100, 100, 100, 100, 100},
                {123, 123, 123, 123, 123}
        }) {
            MonsterWeavingLinearCounter linear = new MonsterWeavingLinearCounter(lengths);
            BigInteger total = linear.count();
            for (int distance : new int[]{0, 1, 2, 4, 8}) {
                BigInteger firstRank = BigInteger.valueOf(distance + 1L);
                BigInteger lastRank = total.subtract(BigInteger.valueOf(distance));
                int[] first = linear.unrank1(firstRank);
                int[] last = linear.unrank1(lastRank);
                eq(firstRank, linear.rank1(first), "E_WIDE_START_INVERSION");
                eq(lastRank, linear.rank1(last), "E_WIDE_END_INVERSION");
                eq(Arrays.stream(lengths).sum(), first.length, "E_WIDE_DURATION");
                eq(Arrays.stream(lengths).sum(), last.length, "E_WIDE_DURATION_END");
            }
            fails("E_WEAVE_UNRANK_LIMIT", () ->
                linear.unrank1(total.add(BigInteger.ONE).divide(BigInteger.TWO)));
        }
    }

    private static void testFullYearNeighborRank() {
        int[] lengths = new int[47];
        Arrays.fill(lengths, 123);
        lengths[46] = 120;
        MonsterWeavingLinearCounter full = new MonsterWeavingLinearCounter(lengths);
        BigInteger total = full.count();
        for (int distance : new int[]{0, 1, 2, 4, 8}) {
            BigInteger low = BigInteger.valueOf(distance + 1L);
            BigInteger high = total.subtract(BigInteger.valueOf(distance));
            int[] a = full.unrank1(low);
            int[] b = full.unrank1(high);
            eq(low, full.rank1(a), "E_FULL_FORWARD_RANK");
            eq(high, full.rank1(b), "E_FULL_BACKWARD_RANK");
            eq(5778, a.length, "E_FULL_DAY_COUNT");
            eq(5778, b.length, "E_FULL_DAY_COUNT_END");
            int[] occurrenceA = new int[47];
            int[] occurrenceB = new int[47];
            for (int pos = 0; pos < 5778; pos++) {
                occurrenceA[a[pos] - 1]++;
                occurrenceB[b[pos] - 1]++;
            }
            array(lengths, occurrenceA, "E_FULL_FIRST_MULTIPLICITIES");
            array(lengths, occurrenceB, "E_FULL_LAST_MULTIPLICITIES");
        }
        fails("E_WEAVE_UNRANK_LIMIT", () ->
            full.unrank1(total.add(BigInteger.ONE).divide(BigInteger.TWO)));
    }

    private static void testValidationAndCopyOwnership() {
        MonsterWeavingLinearCounter f = new MonsterWeavingLinearCounter(new int[]{2, 3, 4});
        fails("E_WEAVE_SEQUENCE", () -> f.lexNext(null));
        fails("E_WEAVE_SEQUENCE", () -> f.lexNext(new int[9]));
        fails("E_WEAVE_SEQUENCE", () -> f.lexPrevious(new int[]{1, 1, 1, 1, 2, 2, 2, 3, 3}));
        int[] first = f.lexFirst();
        int[] later = f.lexNext(first);
        int[] wanted = later.clone();
        first[0] = 999;
        array(wanted, later, "E_NEIGHBOR_OWNED");
        array(wanted, f.lexNext(f.lexFirst()), "E_NEIGHBOR_REENTRANT");
    }

    private static void nullValue(Object value, String code) {
        checks++;
        if (value != null) throw new AssertionError(code);
    }

    private static void positiveLex(int[] oldValue, int[] newValue, String code) {
        checks++;
        if (newValue == null) throw new AssertionError(code + " null");
        for (int i = 0; i < oldValue.length; i++) {
            if (oldValue[i] == newValue[i]) continue;
            if (oldValue[i] < newValue[i]) return;
            break;
        }
        throw new AssertionError(code);
    }

    private static void eq(Object expected, Object got, String code) {
        checks++;
        if (!expected.equals(got)) {
            throw new AssertionError(code + " expected=" + expected + " actual=" + got);
        }
    }

    private static void array(int[] expected, int[] got, String code) {
        checks++;
        if (!Arrays.equals(expected, got)) {
            throw new AssertionError(code + " expected=" + Arrays.toString(expected)
                + " actual=" + Arrays.toString(got));
        }
    }

    private static void fails(String expected, Runnable action) {
        checks++;
        try {
            action.run();
        } catch (IllegalArgumentException exception) {
            if (expected.equals(exception.getMessage())) return;
            throw new AssertionError("E_WRONG_ERROR " + exception.getMessage(), exception);
        }
        throw new AssertionError("E_EXPECTED_FAILURE " + expected);
    }
}
