package org.pastafari.javalojban;

import java.math.BigInteger;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

public final class Stage02PrefixRankingTests {
    private static int checks;

    private Stage02PrefixRankingTests() {}

    public static void main(String[] args) {
        testExhaustiveSmallOracleSubtrees();
        testLargeRealYearInteriorSuffixes();
        testDiverseLegalFullYearPrefixes();
        testValidationAndOwnership();
        System.out.println("STAGE_02_PREFIX_RANKING_PASS checks=" + checks
            + " full_days=5778 suffix_limit="
            + MonsterWeavingLinearCounter.MAX_UNRANK_DAYS
            + " heap_mb=" + Runtime.getRuntime().maxMemory() / (1024 * 1024));
    }

    private static void testExhaustiveSmallOracleSubtrees() {
        for (int[] lengths : new int[][]{
                {1, 1, 1}, {2, 2, 2}, {3, 2, 2},
                {3, 3, 2}, {3, 3, 3}, {2, 3, 2, 2}
        }) {
            MonsterWeavingLinearCounter actual = new MonsterWeavingLinearCounter(lengths);
            NormativeOracle.WeavingFamily oracle = new NormativeOracle.WeavingFamily(lengths);
            int possibilities = oracle.count().intValueExact();
            List<int[]> complete = new ArrayList<>();
            for (int rank = 1; rank <= possibilities; rank++) {
                complete.add(oracle.unrank1(BigInteger.valueOf(rank)));
            }
            for (int[] witness : complete) {
                for (int depth : new int[]{0, 1, witness.length / 2, witness.length - 1, witness.length}) {
                    int[] prefix = Arrays.copyOf(witness, depth);
                    List<int[]> subtree = new ArrayList<>();
                    for (int[] candidate : complete) {
                        if (startsWith(candidate, prefix)) subtree.add(candidate);
                    }
                    eq(BigInteger.valueOf(subtree.size()),
                        actual.countAfterPrefix(prefix), "E_ORACLE_PREFIX_COUNT");
                    for (int rank = 1; rank <= subtree.size(); rank++) {
                        BigInteger r = BigInteger.valueOf(rank);
                        int[] chosen = actual.unrankAfterPrefix(prefix, r);
                        array(subtree.get(rank - 1), chosen, "E_ORACLE_PREFIX_UNRANK");
                        eq(r, actual.rankAfterPrefix(prefix, chosen), "E_ORACLE_PREFIX_RANK");
                    }
                }
            }
        }
    }

    private static void testLargeRealYearInteriorSuffixes() {
        int[] lengths = new int[47];
        Arrays.fill(lengths, 123);
        lengths[46] = 120;
        MonsterWeavingLinearCounter whole = new MonsterWeavingLinearCounter(lengths);
        int[] prefix = new int[43 * 123];
        int pos = 0;
        for (int month = 1; month <= 43; month++) {
            for (int day = 0; day < 123; day++) prefix[pos++] = month;
        }
        eq(5778 - 489, prefix.length, "E_FULL_PREFIX_DAYS");
        int[] tail = {123, 123, 123, 120};
        MonsterWeavingLinearCounter suffix = new MonsterWeavingLinearCounter(tail);
        BigInteger choices = whole.countAfterPrefix(prefix);
        eq(suffix.count(), choices, "E_FULL_PREFIX_REBASE_COUNT");
        ok(choices.compareTo(BigInteger.valueOf(1000)) > 0, "E_FULL_PREFIX_INTERIOR");
        for (BigInteger rank : new BigInteger[]{BigInteger.ONE, BigInteger.valueOf(17),
                choices.divide(BigInteger.valueOf(3)),
                choices.add(BigInteger.ONE).divide(BigInteger.TWO),
                choices.subtract(BigInteger.valueOf(16)), choices}) {
            int[] complete = whole.unrankAfterPrefix(prefix, rank);
            eq(5778, complete.length, "E_YEAR_5778");
            array(prefix, Arrays.copyOf(complete, prefix.length), "E_PRESERVED_PREFIX");
            eq(rank, whole.rankAfterPrefix(prefix, complete), "E_FULL_INVERSE");
            int[] expectedTail = suffix.unrank1(rank);
            int[] actualTail = Arrays.copyOfRange(complete, prefix.length, 5778);
            for (int i = 0; i < actualTail.length; i++) {
                eq(expectedTail[i] + 43, actualTail[i], "E_REBASED_MONTH_ID");
            }
            int[] counts = new int[47];
            for (int ordinal : complete) counts[ordinal - 1]++;
            array(lengths, counts, "E_FULL_MULTIPLICITIES");
        }
    }

    private static void testDiverseLegalFullYearPrefixes() {
        int[] lengths = new int[47];
        Arrays.fill(lengths, 123);
        lengths[46] = 120;
        MonsterWeavingLinearCounter whole = new MonsterWeavingLinearCounter(lengths);
        for (int[] extreme : List.of(whole.lexFirst(), whole.lexLast())) {
            for (int suffixDays : new int[]{0, 1, 31, 252, 512}) {
                int[] prefix = Arrays.copyOf(extreme, 5778 - suffixDays);
                BigInteger possibilities = whole.countAfterPrefix(prefix);
                ok(possibilities.signum() > 0, "E_EXTREME_PREFIX_COUNT");
                for (BigInteger rank : uniqueRanks(possibilities)) {
                    int[] completed = whole.unrankAfterPrefix(prefix, rank);
                    eq(rank, whole.rankAfterPrefix(prefix, completed), "E_EXTREME_ROUNDTRIP");
                    array(prefix, Arrays.copyOf(completed, prefix.length), "E_EXTREME_STABLE");
                }
            }
        }
    }

    private static void testValidationAndOwnership() {
        MonsterWeavingLinearCounter linear =
            new MonsterWeavingLinearCounter(new int[]{123, 123, 123, 123, 123});
        int[] prefix = new int[103];
        Arrays.fill(prefix, 1);
        fails("E_WEAVE_SUFFIX_LIMIT", () ->
            linear.unrankAfterPrefix(Arrays.copyOf(prefix, 100), BigInteger.ONE));
        BigInteger total = linear.countAfterPrefix(prefix);
        int[] result = linear.unrankAfterPrefix(prefix, total.add(BigInteger.ONE).divide(BigInteger.TWO));
        BigInteger middle = linear.rankAfterPrefix(prefix, result);
        eq(total.add(BigInteger.ONE).divide(BigInteger.TWO), middle, "E_512_BOUNDARY");
        int[] original = result.clone();
        prefix[0] = 5;
        array(original, result, "E_RESULT_OWNERSHIP");
        fails("E_WEAVE_PREFIX", () -> linear.unrankAfterPrefix(null, BigInteger.ONE));
        fails("E_WEAVE_PREFIX", () ->
            linear.unrankAfterPrefix(new int[]{2}, BigInteger.ONE));
        fails("E_WEAVE_SUFFIX_LIMIT", () ->
            linear.unrankAfterPrefix(new int[]{1}, BigInteger.ZERO));
        fails("E_WEAVE_RANK", () ->
            linear.unrankAfterPrefix(Arrays.copyOf(original, 103), BigInteger.ZERO));
        fails("E_WEAVE_RANK", () ->
            linear.unrankAfterPrefix(Arrays.copyOf(original, original.length),
                BigInteger.valueOf(2)));
        fails("E_WEAVE_PREFIX_MISMATCH", () ->
            linear.rankAfterPrefix(new int[]{1, 1}, linear.lexLast()));
        fails("E_WEAVE_SEQUENCE", () ->
            linear.rankAfterPrefix(new int[]{1}, new int[0]));
    }

    private static boolean startsWith(int[] sequence, int[] prefix) {
        if (sequence.length < prefix.length) return false;
        for (int i = 0; i < prefix.length; i++) {
            if (sequence[i] != prefix[i]) return false;
        }
        return true;
    }

    private static List<BigInteger> uniqueRanks(BigInteger count) {
        List<BigInteger> ranks = new ArrayList<>();
        ranks.add(BigInteger.ONE);
        BigInteger middle = count.add(BigInteger.ONE).divide(BigInteger.TWO);
        if (!ranks.contains(middle)) ranks.add(middle);
        if (!ranks.contains(count)) ranks.add(count);
        return ranks;
    }

    private static void eq(Object expected, Object actual, String code) {
        checks++;
        if (!expected.equals(actual)) {
            throw new AssertionError(code + " expected=" + expected + " actual=" + actual);
        }
    }

    private static void array(int[] expected, int[] actual, String code) {
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

    private static void fails(String code, Runnable action) {
        checks++;
        try {
            action.run();
        } catch (IllegalArgumentException e) {
            if (code.equals(e.getMessage())) return;
            throw new AssertionError("E_WRONG_ERROR wanted=" + code
                + " actual=" + e.getMessage(), e);
        }
        throw new AssertionError("E_MISSING_ERROR " + code);
    }
}
