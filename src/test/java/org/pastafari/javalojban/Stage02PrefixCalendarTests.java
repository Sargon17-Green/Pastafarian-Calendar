package org.pastafari.javalojban;

import java.math.BigInteger;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

public final class Stage02PrefixCalendarTests {
    private static int checks;

    private Stage02PrefixCalendarTests() {}

    public static void main(String[] args) {
        testIndependentYearAndCalendar();
        testTargetIntegrationAndFailurePaths();
        testMonthIndexAndDefensiveOwnership();
        System.out.println("STAGE_02_PREFIX_CALENDAR_PASS checks=" + checks
            + " suffix_limit=" + MonsterWeavingLinearCounter.MAX_UNRANK_DAYS
            + " heap_mb=" + Runtime.getRuntime().maxMemory() / (1024 * 1024));
    }

    private static void testIndependentYearAndCalendar() {
        BigInteger f = MonsterArithmetic.FOUNDATION_DAY;
        MonsterYears.Year year = new MonsterYears().year5000(f);
        MonsterYearBlueprint blueprint = MonsterYearBlueprint.build(f, year);
        int[] lengths = blueprint.monthLengths();
        int duration = year.length().intValueExact();
        eq(duration, Arrays.stream(lengths).sum(), "E_YEAR_DAYS");
        ok(duration > 512, "E_ACTUAL_BIG_YEAR");
        MonsterWeavingLinearCounter family = new MonsterWeavingLinearCounter(lengths);
        NormativeOracle oracle = new NormativeOracle();
        NormativeOracle.Year referenceYear = oracle.year5000(f);
        eq(referenceYear.number(), year.number(), "E_ORACLE_YEAR");
        eq(referenceYear.openGateDay(), year.openGateDay(), "E_ORACLE_OPEN");
        eq(referenceYear.closeGateDay(), year.closeGateDay(), "E_ORACLE_CLOSE");

        NormativeOracle.SauceResult sauce =
            NormativeOracle.sauce(f, year.openGateDay().add(BigInteger.ONE));
        BigInteger namesCount = NormativeOracle.fallingFactorial(47, lengths.length);
        int[] normativeNames = NormativeOracle.unrankDistinctIndices(47, lengths.length,
            NormativeOracle.chooseRank(NormativeOracle.askBowl(sauce, 5, 33),
                                       namesCount));
        array(normativeNames, blueprint.monthNameIndices(), "E_ORACLE_MONTH_NAMES");

        int explored = 0;
        for (int[] extreme : List.of(family.lexFirst(), family.lexLast())) {
            int[] prefix = Arrays.copyOf(extreme, duration - 480);
            BigInteger total = family.countAfterPrefix(prefix);
            ok(total.signum() > 0, "E_PREFIX_SPACE_POSITIVE");
            for (BigInteger rank : uniqueRanks(total)) {
                MonsterCalendarResolver.PrefixRankedYear converted =
                    MonsterCalendarResolver.fromBlueprintWithPrefixRank(
                        blueprint, prefix, rank);
                eq(year.number(), converted.yearNumber(), "E_YEAR_NUMBER");
                eq(year.openGateDay(), converted.openGateDay(), "E_OPEN_BOUND");
                eq(year.closeGateDay(), converted.closeGateDay(), "E_CLOSE_BOUND");
                eq(duration, converted.length(), "E_DURATION");
                eq(total, converted.localPossibilities(), "E_LOCAL_COUNT");
                eq(rank, converted.localRank(), "E_LOCAL_RANK");
                array(prefix, converted.fixedPrefixCopy(), "E_STORED_PREFIX");
                int[] weaving = converted.weavingCopy();
                array(prefix, Arrays.copyOf(weaving, prefix.length), "E_PREFIX_FIXED");
                eq(rank, family.rankAfterPrefix(prefix, weaving), "E_RANK_INVERSION");
                validateIndependentDates(blueprint, normativeNames, converted);
                explored++;
            }
        }
        ok(explored >= 4, "E_DIFFERENT_PREFIX_RANKS");
    }

    private static void validateIndependentDates(MonsterYearBlueprint blueprint,
              int[] oracleNames, MonsterCalendarResolver.PrefixRankedYear resolved) {
        int[] sequence = resolved.weavingCopy();
        int[] occurrences = new int[oracleNames.length];
        int[] expectedDayInMonth = new int[sequence.length];
        for (int position = 0; position < sequence.length; position++) {
            expectedDayInMonth[position] = ++occurrences[sequence[position] - 1];
        }
        array(blueprint.monthLengths(), occurrences, "E_MONTH_TOTALS");
        int duration = sequence.length;
        List<Integer> positions = new ArrayList<>();
        for (int p : new int[]{0, 1, duration / 4, duration / 2,
                duration - 2, duration - 1, duration - 481,
                duration - 480, duration - 479}) {
            if (p >= 0 && p < duration && !positions.contains(p)) positions.add(p);
        }
        for (int p = 0; p < duration; p += 97) positions.add(p);

        for (int position : positions) {
            BigInteger day = resolved.openGateDay().add(
                BigInteger.valueOf(position + 1L));
            MonsterCalendarResolver.CalendarDate date = resolved.atDay(day);
            MonsterYearBlueprint.Cutlet cutlet = blueprint.cutletAt(day);
            int ordinal = sequence[position];
            int name = oracleNames[ordinal - 1];
            eq(blueprint.year().number(), date.yearNumber(), "E_DATE_YEAR");
            eq(cutlet.canonicalNameIndex(), date.canonicalCutletIndex(), "E_DATE_CUTLET");
            eq(SourceLanguageCatalog.cutletName(cutlet.canonicalNameIndex()),
                    date.cutletName(), "E_DATE_CUTLET_NAME");
            eq(day.subtract(cutlet.firstDay()).add(BigInteger.ONE),
                    date.dayInCutlet(), "E_DAY_IN_CUTLET");
            eq(ordinal, date.monthOrdinal(), "E_DATE_MONTH_ORDINAL");
            eq(name, date.canonicalMonthIndex(), "E_DATE_MONTH_NAME_INDEX");
            eq(SourceLanguageCatalog.monthName(name),
                    date.monthName(), "E_DATE_MONTH_NAME");
            eq(expectedDayInMonth[position], date.dayInMonth(), "E_DATE_MONTH_DAY");
        }
    }

    private static void testTargetIntegrationAndFailurePaths() {
        BigInteger f = MonsterArithmetic.FOUNDATION_DAY;
        MonsterYears.Year y = new MonsterYears().year5000(f);
        MonsterYearBlueprint bp = MonsterYearBlueprint.build(f, y);
        MonsterWeavingLinearCounter family = new MonsterWeavingLinearCounter(bp.monthLengths());
        int days = y.length().intValueExact();
        int[] prefix = Arrays.copyOf(family.lexFirst(), days - 480);
        BigInteger count = family.countAfterPrefix(prefix);
        BigInteger rank = count.add(BigInteger.ONE).divide(BigInteger.TWO);
        for (BigInteger t : List.of(y.openGateDay().add(BigInteger.ONE), f,
                y.closeGateDay())) {
            MonsterCalendarResolver.PrefixRankedYear selected =
                MonsterCalendarResolver.forTargetWithPrefixRank(f, t, prefix, rank);
            eq(y.number(), selected.yearNumber(), "E_FOR_TARGET_YEAR");
            eq(MonsterCalendarResolver.fromBlueprintWithPrefixRank(bp, prefix, rank)
                    .atDay(t), selected.atDay(t), "E_FOR_TARGET_DATE");
        }

        fails("E_NULL_BLUEPRINT", () ->
            MonsterCalendarResolver.fromBlueprintWithPrefixRank(null, prefix, rank));
        fails("E_NULL_DAY", () ->
            MonsterCalendarResolver.forTargetWithPrefixRank(null, f, prefix, rank));
        fails("E_WEAVE_PREFIX", () ->
            MonsterCalendarResolver.fromBlueprintWithPrefixRank(bp,
                new int[]{2}, BigInteger.ONE));
        fails("E_WEAVE_SUFFIX_LIMIT", () ->
            MonsterCalendarResolver.fromBlueprintWithPrefixRank(bp,
                Arrays.copyOf(family.lexFirst(), days - 513), BigInteger.ONE));
        fails("E_WEAVE_RANK", () ->
            MonsterCalendarResolver.fromBlueprintWithPrefixRank(bp, prefix,
                BigInteger.ZERO));
        fails("E_WEAVE_RANK", () ->
            MonsterCalendarResolver.fromBlueprintWithPrefixRank(bp, prefix,
                count.add(BigInteger.ONE)));
    }

    private static void testMonthIndexAndDefensiveOwnership() {
        BigInteger f = MonsterArithmetic.FOUNDATION_DAY;
        MonsterYearBlueprint bp = MonsterYearBlueprint.build(f,
            new MonsterYears().year5000(f));
        MonsterWeavingLinearCounter family = new MonsterWeavingLinearCounter(bp.monthLengths());
        int[] prefix = Arrays.copyOf(family.lexLast(),
            bp.year().length().intValueExact() - 480);
        BigInteger count = family.countAfterPrefix(prefix);
        BigInteger rank = count.add(BigInteger.ONE).divide(BigInteger.TWO);
        MonsterCalendarResolver.PrefixRankedYear a =
            MonsterCalendarResolver.fromBlueprintWithPrefixRank(bp, prefix, rank);
        MonsterCalendarResolver.PrefixRankedYear b =
            MonsterCalendarResolver.fromBlueprintWithPrefixRank(bp, prefix, rank);
        int[] wanted = a.weavingCopy();
        prefix[0] = 999;
        a.weavingCopy()[0] = 999;
        a.fixedPrefixCopy()[0] = 999;
        array(wanted, a.weavingCopy(), "E_OWNED_WEAVING");
        eq(a.atDay(a.openGateDay().add(BigInteger.ONE)),
           b.atDay(b.openGateDay().add(BigInteger.ONE)), "E_REENTRANT_DATE");
        eq(rank, a.localRank(), "E_OWNED_RANK");
        eq(count, a.localPossibilities(), "E_OWNED_CHOICES");
        fails("E_NULL_DAY", () -> a.atDay(null));
        fails("E_DAY_OUTSIDE_YEAR", () -> a.atDay(a.openGateDay()));
        fails("E_DAY_OUTSIDE_YEAR", () ->
            a.atDay(a.closeGateDay().add(BigInteger.ONE)));
    }

    private static List<BigInteger> uniqueRanks(BigInteger choices) {
        List<BigInteger> ranks = new ArrayList<>();
        for (BigInteger candidate : List.of(BigInteger.ONE,
                choices.add(BigInteger.ONE).divide(BigInteger.TWO), choices)) {
            if (!ranks.contains(candidate)) ranks.add(candidate);
        }
        return ranks;
    }

    private static void array(int[] expected, int[] got, String code) {
        checks++;
        if (!Arrays.equals(expected, got)) {
            throw new AssertionError(code + " wanted="
                + Arrays.toString(expected) + " got=" + Arrays.toString(got));
        }
    }

    private static void eq(Object expected, Object got, String code) {
        checks++;
        if (!expected.equals(got)) {
            throw new AssertionError(code + " wanted=" + expected + " got=" + got);
        }
    }

    private static void ok(boolean value, String code) {
        checks++;
        if (!value) throw new AssertionError(code);
    }

    private static void fails(String wanted, Runnable action) {
        checks++;
        try {
            action.run();
        } catch (IllegalArgumentException e) {
            if (wanted.equals(e.getMessage())) return;
            throw new AssertionError("E_FAILURE wanted=" + wanted
                + " got=" + e.getMessage(), e);
        }
        throw new AssertionError("E_MISSING_FAILURE " + wanted);
    }
}
