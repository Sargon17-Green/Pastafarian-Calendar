package org.pastafari.javalojban;

import java.math.BigInteger;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

public final class Stage02FamiliesTests {
    private static int checks;

    public static void main(String[] args) {
        testDistinctNames();
        testBoundedCompositions();
        testCutletPartitions();
        testWeaving();
        testLargerDomains();
        testInvalidRanges();
        System.out.println("STAGE_02_FAMILIES_PASS checks=" + checks);
    }

    private static void testDistinctNames() {
        for (int n = 0; n <= 8; n++) {
            for (int k = 0; k <= n; k++) {
                BigInteger size = MonsterFamilies.fallingFactorial(n, k);
                eq(NormativeOracle.fallingFactorial(n, k), size, "E_NAMES_COUNT");
                Set<String> seen = new HashSet<>();
                for (int rank = 1; rank <= size.intValueExact(); rank++) {
                    BigInteger r = BigInteger.valueOf(rank);
                    int[] value = MonsterFamilies.unrankDistinctIndices(n, k, r);
                    arr(NormativeOracle.unrankDistinctIndices(n, k, r), value, "E_NAMES_ORACLE");
                    ok(seen.add(Arrays.toString(value)), "E_NAMES_UNIQUE");
                    eq(k, value.length, "E_NAMES_SIZE");
                }
                eq(size.intValueExact(), seen.size(), "E_NAMES_ALL");
            }
        }
        for (int n : new int[]{17, 47}) {
            for (int k : new int[]{0, 1, n / 2, n}) {
                BigInteger size = MonsterFamilies.fallingFactorial(n, k);
                for (BigInteger r : List.of(BigInteger.ONE, size, size.add(BigInteger.ONE).divide(BigInteger.TWO))) {
                    arr(NormativeOracle.unrankDistinctIndices(n, k, r),
                        MonsterFamilies.unrankDistinctIndices(n, k, r), "E_CANONICAL_NAMES");
                }
            }
        }
    }

    private static void testBoundedCompositions() {
        for (int total = 0; total <= 17; total++) {
            for (int slots = 0; slots <= 5; slots++) {
                for (int lo = 0; lo <= 3; lo++) {
                    for (int hi = lo; hi <= 5; hi++) {
                        MonsterFamilies.BoundedCompositionFamily current =
                            new MonsterFamilies.BoundedCompositionFamily(total, slots, lo, hi);
                        NormativeOracle.BoundedCompositionFamily oracle =
                            new NormativeOracle.BoundedCompositionFamily(total, slots, lo, hi);
                        BigInteger count = current.count();
                        eq(oracle.count(), count, "E_COMP_COUNT");
                        if (count.signum() == 0) continue;
                        for (BigInteger rank : sampleRanks(count)) {
                            int[] result = current.unrank1(rank);
                            arr(oracle.unrank1(rank), result, "E_COMP_ORACLE");
                            eq(total, Arrays.stream(result).sum(), "E_COMP_SUM");
                            for (int value : result) {
                                ok(value >= lo && value <= hi, "E_COMP_VALUE");
                            }
                        }
                        fails("E_COMP_RANK", () -> current.unrank1(BigInteger.ZERO));
                        fails("E_COMP_RANK", () -> current.unrank1(count.add(BigInteger.ONE)));
                    }
                }
            }
        }
    }

    private static void testCutletPartitions() {
        for (int total = 2; total <= 15; total++) {
            for (int slots = 1; slots <= Math.min(total, 5); slots++) {
                for (int marker = 0; marker < total; marker++) {
                    Integer required = marker == 0 ? null : marker;
                    MonsterFamilies.CutletPartitionFamily current =
                        new MonsterFamilies.CutletPartitionFamily(total, slots, required);
                    NormativeOracle.CutletPartitionFamily oracle =
                        new NormativeOracle.CutletPartitionFamily(total, slots, required);
                    BigInteger count = current.count();
                    eq(oracle.count(), count, "E_CUTLET_COUNT");
                    if (count.signum() == 0) continue;
                    for (BigInteger rank : sampleRanks(count)) {
                        int[] p = current.unrank1(rank);
                        arr(oracle.unrank1(rank), p, "E_CUTLET_ORACLE");
                        eq(total, Arrays.stream(p).sum(), "E_CUTLET_SUM");
                        int cumulative = 0;
                        boolean hit = required == null;
                        for (int value : p) {
                            ok(value >= 1, "E_CUTLET_POSITIVE");
                            cumulative += value;
                            if (required != null && cumulative == required) hit = true;
                        }
                        ok(hit, "E_CUTLET_REQUIRED");
                    }
                    fails("E_CUTLET_PARTITION_RANK", () -> current.unrank1(BigInteger.ZERO));
                }
            }
        }
    }

    private static void testWeaving() {
        for (int months = 1; months <= 4; months++) {
            int cases = 1;
            for (int i = 0; i < months; i++) cases *= 3;
            for (int code = 0; code < cases; code++) {
                int[] lengths = new int[months];
                int t = code;
                for (int j = 0; j < months; j++) {
                    lengths[j] = 1 + t % 3;
                    t /= 3;
                }
                MonsterFamilies.WeavingFamily actual = new MonsterFamilies.WeavingFamily(lengths);
                NormativeOracle.WeavingFamily expected = new NormativeOracle.WeavingFamily(lengths);
                BigInteger size = actual.count();
                eq(expected.count(), size, "E_WEAVE_COUNT");
                for (BigInteger rank : sampleRanks(size)) {
                    int[] sequence = actual.unrank1(rank);
                    arr(expected.unrank1(rank), sequence, "E_WEAVE_ORACLE");
                    eq(Arrays.stream(lengths).sum(), sequence.length, "E_WEAVE_LENGTH");
                    int[] seen = new int[months];
                    for (int month : sequence) seen[month - 1]++;
                    arr(lengths, seen, "E_WEAVE_MULTIPLICITIES");
                }
                int[] original = lengths.clone();
                MonsterFamilies.WeavingFamily stable = new MonsterFamilies.WeavingFamily(lengths);
                lengths[0] = 1000;
                eq(stable.count(), new MonsterFamilies.WeavingFamily(original).count(), "E_WEAVE_OWNERSHIP");
            }
        }
        MonsterFamilies.WeavingFamily small = new MonsterFamilies.WeavingFamily(new int[]{2,2,2});
        eq(BigInteger.valueOf(5), small.count(), "E_WEAVE_222_COUNT");
        arr(new int[]{1,1,2,2}, new MonsterFamilies.WeavingFamily(new int[]{2,2}).unrank1(BigInteger.ONE), "E_WEAVE_FIRST");
    }

    private static void testLargerDomains() {
        MonsterFamilies.BoundedCompositionFamily months =
            new MonsterFamilies.BoundedCompositionFamily(5778, 47, 4, 123);
        BigInteger count = months.count();
        ok(count.signum() > 0, "E_MONTHS_NONEMPTY");
        for (BigInteger rank : sampleRanks(count)) {
            int[] values = months.unrank1(rank);
            eq(5778, Arrays.stream(values).sum(), "E_MONTHS_SUM");
            eq(47, values.length, "E_MONTHS_COUNT");
            for (int value : values) ok(value >= 4 && value <= 123, "E_MONTHS_BOUNDS");
        }
        MonsterFamilies.CutletPartitionFamily large =
            new MonsterFamilies.CutletPartitionFamily(130, 15, 65);
        BigInteger total = large.count();
        ok(total.signum() > 0, "E_LARGE_CUTLETS");
        for (BigInteger rank : sampleRanks(total)) {
            int[] partition = large.unrank1(rank);
            eq(130, Arrays.stream(partition).sum(), "E_LARGE_CUTLET_SUM");
            int sum = 0;
            boolean found = false;
            for (int n : partition) {
                sum += n;
                if (sum == 65) found = true;
            }
            ok(found, "E_LARGE_CUTLET_GATE");
        }
    }

    private static void testInvalidRanges() {
        fails("E_FALLING", () -> MonsterFamilies.fallingFactorial(3, 4));
        fails("E_NAME_SIZE", () -> MonsterFamilies.unrankDistinctIndices(2, 3, BigInteger.ONE));
        fails("E_NAME_RANK", () -> MonsterFamilies.unrankDistinctIndices(2, 2, BigInteger.valueOf(3)));
        fails("E_COMP_BOUNDS", () -> new MonsterFamilies.BoundedCompositionFamily(1, 2, 5, 3));
        fails("E_CUTLET_BOUNDS", () -> new MonsterFamilies.CutletPartitionFamily(7, 2, 7));
        fails("E_WEAVE_EMPTY", () -> new MonsterFamilies.WeavingFamily(new int[]{}));
        fails("E_WEAVE_LENGTH", () -> new MonsterFamilies.WeavingFamily(new int[]{2,0}));
        fails("E_WEAVE_RANK", () -> new MonsterFamilies.WeavingFamily(new int[]{1,1}).unrank1(BigInteger.ZERO));
    }

    private static List<BigInteger> sampleRanks(BigInteger count) {
        List<BigInteger> ranks = new ArrayList<>();
        ranks.add(BigInteger.ONE);
        BigInteger middle = count.add(BigInteger.ONE).divide(BigInteger.TWO);
        if (!ranks.contains(middle)) ranks.add(middle);
        if (!ranks.contains(count)) ranks.add(count);
        return ranks;
    }

    private static void fails(String code, Runnable action) {
        checks++;
        try {
            action.run();
        } catch (IllegalArgumentException e) {
            if (code.equals(e.getMessage())) return;
            throw new AssertionError("E_ERROR_TYPE " + code + " actual=" + e.getMessage(), e);
        }
        throw new AssertionError("E_EXPECTED_ERROR " + code);
    }

    private static void eq(Object wanted, Object actual, String code) {
        checks++;
        if (!wanted.equals(actual)) {
            throw new AssertionError(code + " wanted=" + wanted + " actual=" + actual);
        }
    }

    private static void arr(int[] wanted, int[] actual, String code) {
        checks++;
        if (!Arrays.equals(wanted, actual)) {
            throw new AssertionError(code + " wanted=" + Arrays.toString(wanted)
                + " actual=" + Arrays.toString(actual));
        }
    }

    private static void ok(boolean yes, String code) {
        checks++;
        if (!yes) throw new AssertionError(code);
    }
}
