package org.pastafari.javalojban;

import java.math.BigInteger;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

public final class Stage02BoundaryBlocksTests {
    private static int checks;

    private Stage02BoundaryBlocksTests() {}

    public static void main(String[] args) {
        testSmallOracleProof();
        testAll513DayRanks();
        testFullYearBoundaryIntervals();
        testDisjointInteriorAndOwnership();
        System.out.println("STAGE_02_BOUNDARY_BLOCKS_PASS checks=" + checks
            + " days=5778 suffix_limit=" + MonsterWeavingLinearCounter.MAX_UNRANK_DAYS
            + " heap_mb=" + Runtime.getRuntime().maxMemory() / (1024 * 1024));
    }

    private static void testSmallOracleProof() {
        for (int[] lengths : new int[][]{{1, 2, 3}, {2, 2, 2},
                {3, 3, 3}, {4, 4, 4}, {2, 3, 4, 2}}) {
            MonsterWeavingLinearCounter linear = new MonsterWeavingLinearCounter(lengths);
            NormativeOracle.WeavingFamily oracle = new NormativeOracle.WeavingFamily(lengths);
            BigInteger total = oracle.count();
            int days = Arrays.stream(lengths).sum();
            for (int suffix : new int[]{0, 1, 2, 3, 4, days}) {
                if (suffix > days) continue;
                for (boolean end : new boolean[]{false, true}) {
                    MonsterWeavingLinearCounter.BoundaryBlock block =
                        linear.boundaryBlock(end, suffix);
                    eq(total, linear.count(), "E_ORACLE_TOTAL");
                    if (end) {
                        eq(total, block.upperRank(), "E_LAST_INTERVAL_END");
                    } else {
                        eq(BigInteger.ONE, block.lowerRank(), "E_FIRST_INTERVAL_START");
                    }
                    eq(block.size(), linear.countAfterPrefix(
                        block.fixedPrefixCopy()), "E_INTERVAL_CARDINALITY");
                    int[] anchor = oracle.unrank1(end ? total : BigInteger.ONE);
                    array(Arrays.copyOf(anchor, days - suffix),
                        block.fixedPrefixCopy(), "E_ORACLE_BOUNDARY_PREFIX");
                    for (BigInteger local : samples(block.size())) {
                        BigInteger global = block.lowerRank().add(local).subtract(BigInteger.ONE);
                        array(oracle.unrank1(global),
                            linear.unrankAfterPrefix(block.fixedPrefixCopy(), local),
                            "E_ORACLE_INTERVAL_GLOBAL");
                    }
                }
            }
        }
    }

    private static void testAll513DayRanks() {
        MonsterWeavingLinearCounter linear =
            new MonsterWeavingLinearCounter(new int[]{123, 123, 123, 123, 21});
        BigInteger total = linear.count();
        MonsterWeavingLinearCounter.BoundaryBlock first =
            linear.boundaryBlock(false, 512);
        MonsterWeavingLinearCounter.BoundaryBlock last =
            linear.boundaryBlock(true, 512);
        eq(total, first.size(), "E_513_ALL_FIRST");
        eq(total, last.size(), "E_513_ALL_LAST");
        for (BigInteger rank : samples(total)) {
            int[] chosen = linear.unrank1(rank);
            array(linear.unrankAfterPrefix(new int[]{1}, rank),
                chosen, "E_513_INDEPENDENT_PREFIX");
            eq(rank, linear.rank1(chosen), "E_513_INVERSE");
        }
    }

    private static void testFullYearBoundaryIntervals() {
        int[] lengths = new int[47];
        Arrays.fill(lengths, 123);
        lengths[46] = 120;
        MonsterWeavingLinearCounter linear = new MonsterWeavingLinearCounter(lengths);
        BigInteger total = linear.count();
        MonsterWeavingLinearCounter.BoundaryBlock first = linear.boundaryBlock(false, 512);
        MonsterWeavingLinearCounter.BoundaryBlock last = linear.boundaryBlock(true, 512);
        eq(5778 - 512, first.fixedPrefixCopy().length, "E_FIRST_PREFIX_DAYS");
        eq(5778 - 512, last.fixedPrefixCopy().length, "E_LAST_PREFIX_DAYS");
        eq(BigInteger.ONE, first.lowerRank(), "E_FIRST_START");
        eq(total, last.upperRank(), "E_LAST_END");
        ok(first.size().compareTo(BigInteger.valueOf(1000)) > 0,
            "E_NONTRIVIAL_FIRST_BLOCK");
        ok(last.size().signum() > 0, "E_NONTRIVIAL_LAST_BLOCK");
        for (MonsterWeavingLinearCounter.BoundaryBlock block : List.of(first, last)) {
            eq(linear.countAfterPrefix(block.fixedPrefixCopy()),
                block.size(), "E_COUNT_SUFFIX");
            for (BigInteger local : samples(block.size())) {
                BigInteger global = block.lowerRank().add(local).subtract(BigInteger.ONE);
                int[] weaving = linear.unrank1(global);
                array(linear.unrankAfterPrefix(block.fixedPrefixCopy(), local),
                    weaving, "E_FULL_INTERVAL_UNRANK");
                eq(global, linear.rank1(weaving), "E_FULL_GLOBAL_INVERSION");
                int[] tally = new int[47];
                for (int month : weaving) tally[month - 1]++;
                array(lengths, tally, "E_FULL_MULTIPLICITIES");
            }
        }
    }

    private static void testDisjointInteriorAndOwnership() {
        int[] lengths = new int[47];
        Arrays.fill(lengths, 123);
        lengths[46] = 120;
        MonsterWeavingLinearCounter linear = new MonsterWeavingLinearCounter(lengths);
        MonsterWeavingLinearCounter.BoundaryBlock first =
            linear.boundaryBlock(false, 512);
        MonsterWeavingLinearCounter.BoundaryBlock last =
            linear.boundaryBlock(true, 512);
        BigInteger total = linear.count();
        BigInteger middle = total.add(BigInteger.ONE).divide(BigInteger.TWO);
        ok(first.upperRank().compareTo(last.lowerRank()) < 0,
            "E_NO_OVERLAP_FULL_YEAR");
        ok(!first.contains(middle), "E_MIDDLE_OUTSIDE_FIRST");
        ok(!last.contains(middle), "E_MIDDLE_OUTSIDE_LAST");
        fails("E_WEAVE_UNRANK_LIMIT", () -> linear.unrank1(middle));
        int[] prefix = first.fixedPrefixCopy();
        int[] original = prefix.clone();
        prefix[0] = 999;
        array(original, first.fixedPrefixCopy(), "E_OWNED_BOUNDARY");
        MonsterWeavingLinearCounter.BoundaryBlock repeated =
            linear.boundaryBlock(false, 512);
        eq(first.lowerRank(), repeated.lowerRank(), "E_STABLE_FIRST_LOWER");
        eq(first.upperRank(), repeated.upperRank(), "E_STABLE_FIRST_UPPER");
        fails("E_WEAVE_SUFFIX_LIMIT", () -> linear.boundaryBlock(true, 513));
        fails("E_WEAVE_SUFFIX_LIMIT", () -> linear.boundaryBlock(false, -1));
    }

    private static List<BigInteger> samples(BigInteger possibilities) {
        List<BigInteger> found = new ArrayList<>();
        for (BigInteger rank : List.of(BigInteger.ONE,
                possibilities.add(BigInteger.ONE).divide(BigInteger.TWO),
                possibilities)) {
            if (!found.contains(rank)) found.add(rank);
        }
        return found;
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

    private static void ok(boolean accepted, String code) {
        checks++;
        if (!accepted) throw new AssertionError(code);
    }

    private static void fails(String code, Runnable action) {
        checks++;
        try {
            action.run();
        } catch (IllegalArgumentException ex) {
            if (code.equals(ex.getMessage())) return;
            throw new AssertionError("E_WRONG_ERROR " + ex.getMessage(), ex);
        }
        throw new AssertionError("E_EXPECTED_ERROR " + code);
    }
}
