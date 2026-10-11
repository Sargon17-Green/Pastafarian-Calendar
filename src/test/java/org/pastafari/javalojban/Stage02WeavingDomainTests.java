package org.pastafari.javalojban;

import java.math.BigInteger;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

public final class Stage02WeavingDomainTests {
    private static int checks;

    public static void main(String[] args) {
        int[][] cases = {
            {4}, {4, 4}, {4, 5, 6}, {4, 123, 4},
            {123, 4, 4}, {4, 5, 6, 7}, {4, 4, 4, 4, 4},
            {4, 4, 4, 4, 4, 4}
        };
        for (int[] lengths : cases) check(lengths);
        testOwnership();
        System.out.println("STAGE_02_WEAVING_DOMAIN_PASS checks=" + checks);
    }

    private static void check(int[] lengths) {
        MonsterFamilies.WeavingFamily independent = new MonsterFamilies.WeavingFamily(lengths);
        NormativeOracle.WeavingFamily reference = new NormativeOracle.WeavingFamily(lengths);
        BigInteger count = independent.count();
        eq(reference.count(), count, "E_WEAVE_COUNT");
        ok(count.signum() > 0, "E_WEAVE_NONEMPTY");
        List<BigInteger> ranks = new ArrayList<>();
        ranks.add(BigInteger.ONE);
        BigInteger middle = count.add(BigInteger.ONE).divide(BigInteger.TWO);
        if (!ranks.contains(middle)) ranks.add(middle);
        if (!ranks.contains(count)) ranks.add(count);
        if (count.compareTo(BigInteger.valueOf(200)) <= 0) {
            ranks.clear();
            for (BigInteger rank = BigInteger.ONE; rank.compareTo(count) <= 0;
                    rank = rank.add(BigInteger.ONE)) {
                ranks.add(rank);
            }
        }
        Set<String> unique = new HashSet<>();
        for (BigInteger rank : ranks) {
            int[] actual = independent.unrank1(rank);
            arr(reference.unrank1(rank), actual, "E_WEAVE_ORACLE");
            ok(unique.add(Arrays.toString(actual)), "E_UNRANK_INJECTIVE");
            int[] tallies = new int[lengths.length];
            int[] firstPositions = new int[lengths.length];
            int[] lastPositions = new int[lengths.length];
            Arrays.fill(firstPositions, -1);
            int expectedLength = 0;
            for (int value : lengths) expectedLength += value;
            eq(expectedLength, actual.length, "E_WEAVE_DURATION");
            for (int index = 0; index < actual.length; index++) {
                int month = actual[index] - 1;
                ok(month >= 0 && month < lengths.length, "E_MONTH_DOMAIN");
                if (firstPositions[month] == -1) firstPositions[month] = index;
                lastPositions[month] = index;
                tallies[month]++;
            }
            arr(lengths, tallies, "E_MONTH_MULTIPLICITIES");
            for (int month = 1; month < lengths.length; month++) {
                ok(firstPositions[month - 1] < firstPositions[month], "E_OPEN_ORDER");
                ok(lastPositions[month - 1] < lastPositions[month], "E_CLOSE_ORDER");
            }
        }
        fails("E_WEAVE_RANK", () -> independent.unrank1(BigInteger.ZERO));
        fails("E_WEAVE_RANK", () -> independent.unrank1(count.add(BigInteger.ONE)));
    }

    private static void testOwnership() {
        int[] input = {4, 5, 6, 7};
        MonsterFamilies.WeavingFamily family = new MonsterFamilies.WeavingFamily(input);
        BigInteger count = family.count();
        input[0] = 1000;
        eq(count, family.count(), "E_FAMILY_INPUT_COPY");
        int[] first = family.unrank1(BigInteger.ONE);
        first[0] = 99;
        arr(new MonsterFamilies.WeavingFamily(new int[]{4, 5, 6, 7}).unrank1(BigInteger.ONE),
            family.unrank1(BigInteger.ONE), "E_FAMILY_RESULT_COPY");
    }

    private static void fails(String code, Runnable action) {
        checks++;
        try { action.run(); }
        catch (IllegalArgumentException e) {
            if (code.equals(e.getMessage())) return;
            throw new AssertionError("E_ERROR expected=" + code + " actual=" + e.getMessage(), e);
        }
        throw new AssertionError("E_EXPECTED_FAILURE " + code);
    }

    private static void eq(Object expected, Object actual, String code) {
        checks++;
        if (!expected.equals(actual)) throw new AssertionError(code + " expected=" + expected + " actual=" + actual);
    }
    private static void arr(int[] expected, int[] actual, String code) {
        checks++;
        if (!Arrays.equals(expected, actual)) throw new AssertionError(code + " expected="
            + Arrays.toString(expected) + " actual=" + Arrays.toString(actual));
    }
    private static void ok(boolean yes, String code) {
        checks++;
        if (!yes) throw new AssertionError(code);
    }
}
