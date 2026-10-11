package org.pastafari.javalojban;

import java.math.BigInteger;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

public final class Stage02InternalGlobalBlocksTests {
    private static int checks;

    private Stage02InternalGlobalBlocksTests() {}

    public static void main(String[] args) {
        oraclePrefixBlockOrder();
        largeInteriorFullYear();
        actualYearCalendarIntegration();
        failureAndOwnership();
        System.out.println("STAGE_02_INTERNAL_GLOBAL_BLOCKS_PASS checks=" + checks
            + " days=5778 suffix_limit=" + MonsterWeavingLinearCounter.MAX_UNRANK_DAYS
            + " branch_limit=" + MonsterWeavingLinearCounter.MAX_GLOBAL_PREFIX_BRANCH_COUNTS
            + " heap_mb=" + Runtime.getRuntime().maxMemory() / 1048576);
    }

    private static void oraclePrefixBlockOrder() {
        for (int[] lengths : new int[][]{
                {1, 2, 3}, {2, 2, 2}, {3, 3, 2}, {2, 3, 3, 2}
        }) {
            MonsterWeavingLinearCounter actual = new MonsterWeavingLinearCounter(lengths);
            NormativeOracle.WeavingFamily oracle = new NormativeOracle.WeavingFamily(lengths);
            int total = oracle.count().intValueExact();
            List<int[]> sorted = new ArrayList<>();
            for (int r = 1; r <= total; r++) {
                sorted.add(oracle.unrank1(BigInteger.valueOf(r)));
            }
            for (int[] exemplar : sorted) {
                for (int depth : new int[]{0, 1, exemplar.length / 2,
                        exemplar.length - 1, exemplar.length}) {
                    int[] prefix = Arrays.copyOf(exemplar, depth);
                    int first = -1;
                    int last = -1;
                    for (int i = 0; i < sorted.size(); i++) {
                        if (!startsWith(sorted.get(i), prefix)) continue;
                        if (first == -1) first = i + 1;
                        last = i + 1;
                    }
                    MonsterWeavingLinearCounter.BoundaryBlock block =
                        actual.globalBlockForPrefix(prefix);
                    eq(BigInteger.valueOf(first), block.lowerRank(), "E_ORACLE_LOWER");
                    eq(BigInteger.valueOf(last), block.upperRank(), "E_ORACLE_UPPER");
                    eq(BigInteger.valueOf(last - first + 1), block.size(), "E_ORACLE_SIZE");
                    for (BigInteger r : rankSamples(block)) {
                        array(oracle.unrank1(r),
                            actual.unrankGlobalWithinPrefix(prefix, r),
                            "E_ORACLE_SELECTED");
                        eq(r, actual.rankGlobalWithinPrefix(prefix,
                            oracle.unrank1(r)), "E_ORACLE_RANK_INVERSION");
                    }
                }
            }
        }
    }

    private static void largeInteriorFullYear() {
        int[] lengths = new int[47];
        Arrays.fill(lengths, 123);
        lengths[46] = 120;
        MonsterWeavingLinearCounter family = new MonsterWeavingLinearCounter(lengths);
        int[] first = family.lexFirst();
        int[] prefix = Arrays.copyOf(first, 5778 - 512);
        MonsterWeavingLinearCounter.BoundaryBlock extreme =
            family.boundaryBlock(false, 512);
        prefix[prefix.length - 1]++;
        MonsterWeavingLinearCounter.BoundaryBlock interior =
            family.globalBlockForPrefix(prefix);
        eq(extreme.upperRank().add(BigInteger.ONE), interior.lowerRank(),
            "E_EXACT_FIRST_INTERIOR_OFFSET");
        ok(interior.size().compareTo(BigInteger.valueOf(1000)) > 0,
            "E_NONTRIVIAL_INTERNAL_INTERVAL");
        MonsterWeavingLinearCounter.BoundaryBlock far =
            family.boundaryBlock(true, 512);
        ok(interior.upperRank().compareTo(far.lowerRank()) < 0, "E_BLOCK_ORDER");
        for (BigInteger r : rankSamples(interior)) {
            int[] sequence = family.unrankGlobalWithinPrefix(prefix, r);
            eq(5778, sequence.length, "E_WHOLE_YEAR_LENGTH");
            array(prefix, Arrays.copyOf(sequence, prefix.length), "E_FIXED_PREFIX");
            eq(r, family.rankGlobalWithinPrefix(prefix, sequence),
                "E_GLOBAL_RANK_INVERSION");
            int[] seen = new int[47];
            for (int ordinal : sequence) seen[ordinal - 1]++;
            array(lengths, seen, "E_FULL_YEAR_MULTIPLICITY");
        }
        fails("E_WEAVE_GLOBAL_RANK", () ->
            family.unrankGlobalWithinPrefix(prefix,
                interior.lowerRank().subtract(BigInteger.ONE)));
        fails("E_WEAVE_GLOBAL_RANK", () ->
            family.unrankGlobalWithinPrefix(prefix,
                interior.upperRank().add(BigInteger.ONE)));
        fails("E_WEAVE_UNRANK_LIMIT", () ->
            family.unrank1(family.count().add(BigInteger.ONE).divide(BigInteger.TWO)));
    }

    private static void actualYearCalendarIntegration() {
        BigInteger calc = MonsterArithmetic.FOUNDATION_DAY;
        MonsterYears.Year year = new MonsterYears().year5000(calc);
        MonsterYearBlueprint blueprint = MonsterYearBlueprint.build(calc, year);
        MonsterWeavingLinearCounter family =
            new MonsterWeavingLinearCounter(blueprint.monthLengths());
        int totalDays = year.length().intValueExact();
        ok(totalDays > 512, "E_ANCHOR_YEAR_LONG");
        int[] prefix = Arrays.copyOf(family.lexFirst(), totalDays - 512);
        MonsterWeavingLinearCounter.BoundaryBlock original =
            family.boundaryBlock(false, 512);
        prefix[prefix.length - 1]++;
        MonsterWeavingLinearCounter.BoundaryBlock selected =
            family.globalBlockForPrefix(prefix);
        eq(original.upperRank().add(BigInteger.ONE), selected.lowerRank(),
            "E_ACTUAL_INTERIOR_START");
        BigInteger globalRank = selected.lowerRank().add(selected.upperRank())
            .divide(BigInteger.TWO);
        MonsterCalendarResolver.GlobalPrefixRankedYear resolved =
            MonsterCalendarResolver.fromBlueprintWithGlobalPrefixRank(
                blueprint, prefix, globalRank);
        eq(globalRank, resolved.globalRank(), "E_EXPLICIT_GLOBAL_RANK");
        eq(selected.lowerRank(), resolved.blockFirstRank(), "E_BLOCK_BEGIN");
        eq(selected.upperRank(), resolved.blockLastRank(), "E_BLOCK_FINISH");
        int[] weaving = resolved.weavingCopy();
        eq(globalRank, family.rankGlobalWithinPrefix(prefix, weaving),
            "E_ACTUAL_GLOBAL_RANK_INVERSE");
        for (int offset : new int[]{0, 1, totalDays / 3, totalDays / 2,
                totalDays - 513, totalDays - 512, totalDays - 1}) {
            BigInteger day = year.openGateDay().add(BigInteger.valueOf(offset + 1L));
            MonsterCalendarResolver.CalendarDate date = resolved.atDay(day);
            MonsterYearBlueprint.Cutlet cutlet = blueprint.cutletAt(day);
            eq(year.number(), date.yearNumber(), "E_YEAR_DATE");
            eq(cutlet.canonicalNameIndex(), date.canonicalCutletIndex(),
                "E_CUTLET_DATE");
            eq(day.subtract(cutlet.firstDay()).add(BigInteger.ONE),
                date.dayInCutlet(), "E_CUTLET_DAY");
            int ordinal = weaving[offset];
            eq(ordinal, date.monthOrdinal(), "E_MONTH_ORDINAL");
            eq(blueprint.monthNameIndices()[ordinal - 1], date.canonicalMonthIndex(),
                "E_MONTH_CANONICAL");
            int expectedDay = 0;
            for (int i = 0; i <= offset; i++) {
                if (weaving[i] == ordinal) expectedDay++;
            }
            eq(expectedDay, date.dayInMonth(), "E_MONTH_DAY");
        }
        for (BigInteger day : List.of(calc, year.closeGateDay())) {
            MonsterCalendarResolver.GlobalPrefixRankedYear viaTarget =
                MonsterCalendarResolver.forTargetWithGlobalPrefixRank(
                    calc, day, prefix, globalRank);
            eq(resolved.atDay(day), viaTarget.atDay(day), "E_VIA_TARGET");
        }
        int[] originalPrefix = resolved.fixedPrefixCopy();
        prefix[0] = 0;
        resolved.fixedPrefixCopy()[0] = 0;
        resolved.weavingCopy()[0] = 0;
        array(originalPrefix, resolved.fixedPrefixCopy(), "E_PREFIX_IMMUTABLE");
        eq(globalRank, resolved.globalRank(), "E_IMMUTABLE_RANK");
    }

    private static void failureAndOwnership() {
        MonsterWeavingLinearCounter small =
            new MonsterWeavingLinearCounter(new int[]{3, 3, 3});
        fails("E_WEAVE_PREFIX", () -> small.globalBlockForPrefix(null));
        fails("E_WEAVE_PREFIX", () -> small.globalBlockForPrefix(new int[]{2}));
        fails("E_WEAVE_GLOBAL_RANK", () ->
            small.unrankGlobalWithinPrefix(new int[]{1, 1},
                BigInteger.ZERO));
        fails("E_WEAVE_PREFIX_MISMATCH", () ->
            small.rankGlobalWithinPrefix(new int[]{1, 1}, small.lexLast()));
        fails("E_NULL_BLUEPRINT", () ->
            MonsterCalendarResolver.fromBlueprintWithGlobalPrefixRank(
                null, new int[]{1}, BigInteger.ONE));
        fails("E_NULL_DAY", () ->
            MonsterCalendarResolver.forTargetWithGlobalPrefixRank(
                null, BigInteger.ZERO, new int[]{1}, BigInteger.ONE));
        int[] lengths = new int[47];
        Arrays.fill(lengths, 3);
        MonsterWeavingLinearCounter capped = new MonsterWeavingLinearCounter(lengths);
        int[] manySkips = new int[47];
        for (int i = 0; i < 46; i++) manySkips[i] = i + 1;
        manySkips[46] = 1;
        fails("E_WEAVE_GLOBAL_BUDGET", () ->
            capped.globalBlockForPrefix(manySkips));
        int[] stored = manySkips.clone();
        manySkips[0] = 99;
        array(stored, stored.clone(), "E_LOCAL_COPY");
    }

    private static boolean startsWith(int[] sequence, int[] prefix) {
        if (sequence.length < prefix.length) return false;
        for (int i = 0; i < prefix.length; i++) {
            if (sequence[i] != prefix[i]) return false;
        }
        return true;
    }

    private static List<BigInteger> rankSamples(
            MonsterWeavingLinearCounter.BoundaryBlock block) {
        List<BigInteger> samples = new ArrayList<>();
        for (BigInteger rank : List.of(block.lowerRank(),
                block.lowerRank().add(block.upperRank()).divide(BigInteger.TWO),
                block.upperRank())) {
            if (!samples.contains(rank)) samples.add(rank);
        }
        return samples;
    }

    private static void array(int[] expected, int[] got, String code) {
        checks++;
        if (!Arrays.equals(expected, got)) {
            throw new AssertionError(code);
        }
    }

    private static void eq(Object expected, Object got, String code) {
        checks++;
        if (!expected.equals(got)) {
            throw new AssertionError(code + " expected=" + expected + " got=" + got);
        }
    }

    private static void ok(boolean yes, String code) {
        checks++;
        if (!yes) throw new AssertionError(code);
    }

    private static void fails(String expected, Runnable action) {
        checks++;
        try {
            action.run();
        } catch (IllegalArgumentException exception) {
            if (expected.equals(exception.getMessage())) return;
            throw new AssertionError("E_DIFFERENT_FAILURE " + exception.getMessage(), exception);
        }
        throw new AssertionError("E_EXPECTED_FAILURE " + expected);
    }
}
