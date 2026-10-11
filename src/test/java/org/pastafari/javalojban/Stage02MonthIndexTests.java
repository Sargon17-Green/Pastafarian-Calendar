package org.pastafari.javalojban;

import java.math.BigInteger;
import java.util.Arrays;
import java.util.HashSet;
import java.util.Set;

public final class Stage02MonthIndexTests {
    private static int checks;

    public static void main(String[] args) {
        testActualYearBlueprint();
        testOracleSmallWeave();
        testDataOwnership();
        testAdversarialInputs();
        System.out.println("STAGE_02_MONTH_INDEX_PASS checks=" + checks);
    }

    private static MonsterYearBlueprint blueprint() {
        BigInteger f = MonsterArithmetic.FOUNDATION_DAY;
        return MonsterYearBlueprint.build(f, new MonsterYears().year5000(f));
    }

    private static int[] sequentialWeaving(int[] lengths) {
        int total = Arrays.stream(lengths).sum();
        int[] weave = new int[total];
        int index = 0;
        for (int month = 0; month < lengths.length; month++) {
            for (int position = 0; position < lengths[month]; position++) {
                weave[index++] = month + 1;
            }
        }
        return weave;
    }

    private static void testActualYearBlueprint() {
        MonsterYearBlueprint plan = blueprint();
        MonsterMonthIndex index = MonsterMonthIndex.fromBlueprint(
            plan, sequentialWeaving(plan.monthLengths()));
        int[] lengths = plan.monthLengths();
        int[] names = plan.monthNameIndices();
        eq(plan.year().length().intValueExact(), index.length(), "E_FULL_YEAR_COVERAGE");
        int offset = 0;
        for (int month = 0; month < lengths.length; month++) {
            for (int day = 1; day <= lengths[month]; day++) {
                MonsterMonthIndex.MonthDate date = index.atOffset(offset);
                eq(offset + 1, date.positionInYear(), "E_DAY_YEAR");
                eq(month + 1, date.monthOrdinal(), "E_MONTH_ORDINAL");
                eq(names[month], date.canonicalMonthIndex(), "E_CANONICAL_NAME");
                eq(SourceLanguageCatalog.monthName(names[month]), date.monthName(), "E_NAME_TEXT");
                eq(day, date.dayInMonth(), "E_DAY_IN_MONTH");
                eq(date, index.atDay(plan.year().openGateDay(),
                    plan.year().openGateDay().add(BigInteger.valueOf(offset + 1))),
                    "E_ABSOLUTE_DAY");
                offset++;
            }
        }
    }

    private static void testOracleSmallWeave() {
        int[] lengths = {84, 84, 84};
        int[] names = {47, 1, 27};
        MonsterFamilies.WeavingFamily f = new MonsterFamilies.WeavingFamily(lengths);
        NormativeOracle.WeavingFamily oracle = new NormativeOracle.WeavingFamily(lengths);
        BigInteger count = f.count();
        eq(oracle.count(), count, "E_SMALL_COUNT");
        for (BigInteger rank : new BigInteger[]{BigInteger.ONE,
                count.add(BigInteger.ONE).divide(BigInteger.TWO), count}) {
            int[] weave = f.unrank1(rank);
            arr(oracle.unrank1(rank), weave, "E_SMALL_UNRANK");
            MonsterMonthIndex index = new MonsterMonthIndex(lengths, names, weave);
            int[] seen = new int[lengths.length];
            for (int i = 0; i < weave.length; i++) {
                int month = weave[i] - 1;
                seen[month]++;
                eq(seen[month], index.atOffset(i).dayInMonth(), "E_WEAVE_DAY");
                eq(names[month], index.atOffset(i).canonicalMonthIndex(), "E_WEAVE_NAME");
            }
        }
    }

    private static void testDataOwnership() {
        MonsterYearBlueprint plan = blueprint();
        int[] lengths = plan.monthLengths();
        int[] names = plan.monthNameIndices();
        int[] weaving = sequentialWeaving(lengths);
        MonsterMonthIndex index = new MonsterMonthIndex(lengths, names, weaving);
        MonsterMonthIndex.MonthDate before = index.atOffset(0);
        lengths[0] = -7;
        names[0] = -7;
        weaving[0] = -7;
        index.weavingCopy()[0] = -7;
        eq(before, index.atOffset(0), "E_DEFENSIVE_INPUT");
        eq(before, index.atDay(plan.year().openGateDay(),
              plan.year().openGateDay().add(BigInteger.ONE)), "E_GREGORIAN_AXIS");
        fails("E_YEAR_OFFSET", () -> index.atOffset(-1));
        fails("E_YEAR_OFFSET", () -> index.atOffset(index.length()));
        fails("E_YEAR_OFFSET", () -> index.atDay(
            plan.year().openGateDay(), plan.year().openGateDay()));
    }

    private static void testAdversarialInputs() {
        MonsterYearBlueprint plan = blueprint();
        int[] lengths = plan.monthLengths();
        int[] names = plan.monthNameIndices();
        int[] baseline = sequentialWeaving(lengths);
        fails("E_MONTH_NULL", () -> new MonsterMonthIndex(null, names, baseline));
        fails("E_NULL_BLUEPRINT", () -> MonsterMonthIndex.fromBlueprint(null, baseline));
        fails("E_MONTH_COUNT", () -> new MonsterMonthIndex(lengths, new int[2], baseline));
        int[] invalidMonthLength = lengths.clone();
        invalidMonthLength[0] = 124;
        fails("E_MONTH_LENGTH", () -> new MonsterMonthIndex(invalidMonthLength, names, baseline));
        int[] invalidName = names.clone();
        invalidName[1] = names[0];
        fails("E_MONTH_NAME", () -> new MonsterMonthIndex(lengths, invalidName, baseline));
        fails("E_WEAVE_DURATION", () -> new MonsterMonthIndex(lengths, names,
            Arrays.copyOf(baseline, baseline.length - 1)));
        int[] outOfRange = baseline.clone();
        outOfRange[0] = 0;
        fails("E_WEAVE_MONTH", () -> new MonsterMonthIndex(lengths, names, outOfRange));
        int[] reversed = baseline.clone();
        int firstLength = lengths[0];
        reversed[0] = 2;
        reversed[firstLength] = 1;
        failsAny(() -> new MonsterMonthIndex(lengths, names, reversed),
                 Set.of("E_WEAVE_ORDER", "E_WEAVE_MULTIPLICITY"));
        int[] imbalanced = baseline.clone();
        imbalanced[0] = 2;
        fails("E_WEAVE_MULTIPLICITY", () -> new MonsterMonthIndex(lengths, names, imbalanced));
        MonsterMonthIndex valid = new MonsterMonthIndex(lengths, names, baseline);
        fails("E_NULL_DAY", () -> valid.atDay(null, BigInteger.ONE));
        fails("E_YEAR_OFFSET", () -> valid.atDay(
            BigInteger.ZERO, BigInteger.valueOf(valid.length() + 1L)));
    }

    private static void failsAny(Runnable action, Set<String> expected) {
        checks++;
        try {
            action.run();
        } catch (IllegalArgumentException ex) {
            if (expected.contains(ex.getMessage())) return;
            throw new AssertionError("E_UNEXPECTED_ERROR " + ex.getMessage(), ex);
        }
        throw new AssertionError("E_EXPECTED_ERROR");
    }

    private static void fails(String code, Runnable action) {
        checks++;
        try {
            action.run();
        } catch (IllegalArgumentException ex) {
            if (code.equals(ex.getMessage())) return;
            throw new AssertionError("E_WRONG_ERROR " + code + " actual=" + ex.getMessage(), ex);
        }
        throw new AssertionError("E_EXPECTED_ERROR " + code);
    }

    private static void eq(Object expected, Object actual, String code) {
        checks++;
        if (!expected.equals(actual)) throw new AssertionError(code +
            " expected=" + expected + " actual=" + actual);
    }

    private static void arr(int[] expected, int[] actual, String code) {
        checks++;
        if (!Arrays.equals(expected, actual)) throw new AssertionError(code);
    }
}
