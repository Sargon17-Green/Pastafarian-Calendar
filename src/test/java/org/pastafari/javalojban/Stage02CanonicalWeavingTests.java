package org.pastafari.javalojban;

import java.math.BigInteger;
import java.util.Arrays;

public final class Stage02CanonicalWeavingTests {
    private static int checks;

    public static void main(String[] args) {
        testOracleSelections();
        testWideSelectorAndMinimumYear();
        testDefensiveCopiesAndFailures();
        System.out.println("STAGE_02_CANONICAL_WEAVING_PASS checks=" + checks);
    }

    private static void testOracleSelections() {
        BigInteger foundation = MonsterArithmetic.FOUNDATION_DAY;
        for (int[] lengths : new int[][]{{2, 2}, {3, 4, 3}, {4, 4, 4}, {4, 5, 6}}) {
            NormativeOracle.WeavingFamily reference = new NormativeOracle.WeavingFamily(lengths);
            for (int offset : new int[]{0, 1, 7}) {
                BigInteger c = foundation.add(BigInteger.valueOf(offset));
                BigInteger t = c.add(BigInteger.valueOf(29));
                MonsterCanonicalWeaving.Selection actual =
                    MonsterCanonicalWeaving.fromDays(c, t, lengths);
                NormativeOracle.SauceResult oracleSauce = NormativeOracle.sauce(c, t);
                BigInteger size = reference.count();
                BigInteger expectedRank = NormativeOracle.chooseRank(
                    NormativeOracle.askBowl(oracleSauce, 4, 32), size);
                eq(size, actual.possibilities(), "E_REF_SIZE");
                eq(expectedRank, actual.rank(), "E_REF_RANK");
                arr(reference.unrank1(expectedRank), actual.weavingCopy(), "E_REF_UNRANK");
            }
        }
    }

    private static void testWideSelectorAndMinimumYear() {
        BigInteger foundation = MonsterArithmetic.FOUNDATION_DAY;
        MonsterSauceBowls.SauceResult sauce =
            MonsterSauceBowls.evaluate(foundation, foundation);
        NormativeOracle.SauceResult oracleSauce =
            NormativeOracle.sauce(foundation, foundation);
        for (int[] lengths : new int[][]{{16, 16, 16, 16, 16, 16},
                                         {45, 45, 45, 45}, {84, 84, 84}}) {
            MonsterCanonicalWeaving.Selection actual =
                MonsterCanonicalWeaving.fromSauce(sauce, lengths);
            BigInteger total = new MonsterWeavingEndpointDP(lengths).count();
            BigInteger rank = NormativeOracle.chooseRank(
                NormativeOracle.askBowl(oracleSauce, 4, 32), total);
            eq(total, actual.possibilities(), "E_WIDE_TOTAL");
            eq(rank, actual.rank(), "E_WIDE_RANK");
            arr(new MonsterWeavingEndpointDP(lengths).unrank1(rank),
                actual.weavingCopy(), "E_SELECTED_UNRANK");
            int[] counts = new int[lengths.length];
            for (int id : actual.weavingCopy()) {
                ok(id >= 1 && id <= counts.length, "E_VALID_MONTH");
                counts[id - 1]++;
            }
            arr(lengths, counts, "E_SELECTED_COUNTS");
            if (actual.length() == 252) {
                MonsterMonthIndex index = new MonsterMonthIndex(
                    lengths, new int[]{1, 2, 3}, actual.weavingCopy());
                int[] series = actual.weavingCopy();
                for (int i = 0; i < index.length(); i++) {
                    eq(series[i], index.atOffset(i).monthOrdinal(), "E_SELECTED_INDEX");
                }
            }
        }
    }

    private static void testDefensiveCopiesAndFailures() {
        BigInteger foundation = MonsterArithmetic.FOUNDATION_DAY;
        MonsterSauceBowls.SauceResult sauce =
            MonsterSauceBowls.evaluate(foundation, foundation);
        int[] lengths = {4, 5, 6};
        MonsterCanonicalWeaving.Selection chosen =
            MonsterCanonicalWeaving.fromSauce(sauce, lengths);
        int[] original = chosen.weavingCopy();
        lengths[0] = 400;
        chosen.weavingCopy()[0] = 99;
        arr(original, chosen.weavingCopy(), "E_OWNED_RESULT");
        eq(chosen.rank(), MonsterCanonicalWeaving.fromSauce(sauce,
            new int[]{4, 5, 6}).rank(), "E_STABLE_RANK");
        fails("E_NULL_SAUCE", () -> MonsterCanonicalWeaving.fromSauce(null, new int[]{4}));
        fails("E_WEAVE_EMPTY", () -> MonsterCanonicalWeaving.fromSauce(sauce, new int[0]));
        fails("E_WEAVE_LENGTH", () -> MonsterCanonicalWeaving.fromSauce(sauce, new int[]{0}));
        fails("E_WEAVE_UNRANK_LIMIT", () -> MonsterCanonicalWeaving.fromSauce(
            sauce, new int[]{86, 85, 86}));
        fails("E_NULL_DAY", () -> MonsterCanonicalWeaving.fromDays(
            null, foundation, new int[]{4}));
    }

    private static void fails(String expected, Runnable task) {
        checks++;
        try { task.run(); }
        catch (IllegalArgumentException ex) {
            if (expected.equals(ex.getMessage())) return;
            throw new AssertionError("E_DIFFERENT_ERROR " + ex.getMessage(), ex);
        }
        throw new AssertionError("E_EXPECTED_ERROR " + expected);
    }

    private static void eq(Object wanted, Object actual, String code) {
        checks++;
        if (!wanted.equals(actual)) {
            throw new AssertionError(code + " wanted=" + wanted + " got=" + actual);
        }
    }

    private static void arr(int[] wanted, int[] actual, String code) {
        checks++;
        if (!Arrays.equals(wanted, actual)) {
            throw new AssertionError(code + " wanted=" + Arrays.toString(wanted)
                + " got=" + Arrays.toString(actual));
        }
    }

    private static void ok(boolean condition, String code) {
        checks++;
        if (!condition) throw new AssertionError(code);
    }
}
