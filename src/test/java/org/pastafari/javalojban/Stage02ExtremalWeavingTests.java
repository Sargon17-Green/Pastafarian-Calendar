package org.pastafari.javalojban;

import java.math.BigInteger;
import java.util.Arrays;
import java.util.List;

public final class Stage02ExtremalWeavingTests {
    private static int checks;

    private Stage02ExtremalWeavingTests() {}

    public static void main(String[] args) {
        testOracleExtremes();
        testWideExactEndpoints();
        testCanonicalCalendarAtEndpoints();
        testResourceLimitsAndOwnership();
        System.out.println("STAGE_02_EXTREMAL_WEAVING_PASS checks=" + checks
            + " full_days=5778 heap_mb="
            + Runtime.getRuntime().maxMemory() / (1024 * 1024));
    }

    private static void testOracleExtremes() {
        for (int months = 1; months <= 5; months++) {
            int configurations = 1;
            for (int i = 0; i < months; i++) configurations *= 3;
            for (int code = 0; code < configurations; code++) {
                int[] lengths = new int[months];
                int n = code;
                for (int i = 0; i < months; i++) {
                    lengths[i] = 1 + n % 3;
                    n /= 3;
                }
                MonsterWeavingLinearCounter family = new MonsterWeavingLinearCounter(lengths);
                NormativeOracle.WeavingFamily oracle = new NormativeOracle.WeavingFamily(lengths);
                BigInteger count = oracle.count();
                eq(count, family.count(), "E_COUNT_ORACLE");
                array(oracle.unrank1(BigInteger.ONE), family.lexFirst(), "E_MIN_ORACLE");
                array(oracle.unrank1(count), family.lexLast(), "E_MAX_ORACLE");
                array(family.unrank1(BigInteger.ONE), family.lexFirst(), "E_MIN_EXISTING");
                array(family.unrank1(count), family.lexLast(), "E_MAX_EXISTING");
                eq(BigInteger.ONE, family.rank1(family.lexFirst()), "E_MIN_RANK");
                eq(count, family.rank1(family.lexLast()), "E_MAX_RANK");
                for (int[] result : List.of(family.lexFirst(), family.lexLast())) {
                    int[] multiplicities = new int[months];
                    for (int id : result) multiplicities[id - 1]++;
                    array(lengths, multiplicities, "E_EXACT_MULTIPLICITY");
                }
            }
        }
    }

    private static void testWideExactEndpoints() {
        int[] lengths = new int[47];
        Arrays.fill(lengths, 123);
        lengths[46] = 120;
        MonsterWeavingLinearCounter family = new MonsterWeavingLinearCounter(lengths);
        BigInteger total = family.count();
        positive(total, "E_FULL_COUNT");
        int[] first = family.unrank1(BigInteger.ONE);
        int[] last = family.unrank1(total);
        array(family.lexFirst(), first, "E_FULL_MIN");
        array(family.lexLast(), last, "E_FULL_MAX");
        eq(BigInteger.ONE, family.rank1(first), "E_FULL_MIN_RANK");
        eq(total, family.rank1(last), "E_FULL_MAX_RANK");
        eq(5778, first.length, "E_FULL_DAYS");
        eq(5778, last.length, "E_FULL_DAYS_END");
        ok(!Arrays.equals(first, last), "E_FULL_NONTRIVIAL");
        int[] sequence = new int[5778];
        int at = 0;
        for (int i = 0; i < 47; i++) {
            for (int j = 0; j < lengths[i]; j++) sequence[at++] = i + 1;
        }
        array(sequence, first, "E_FULL_FIRST_CONSECUTIVE");
        for (int[] weaving : List.of(first, last)) {
            int[] seen = new int[47];
            int[] names = new int[47];
            for (int i = 0; i < 47; i++) names[i] = i + 1;
            MonsterMonthIndex monthIndex = new MonsterMonthIndex(lengths, names, weaving);
            for (int day = 0; day < 5778; day++) {
                int ordinal = weaving[day];
                eq(ordinal, monthIndex.atOffset(day).monthOrdinal(), "E_FULL_ORDINAL");
                eq(++seen[ordinal - 1], monthIndex.atOffset(day).dayInMonth(), "E_FULL_DAY_INDEX");
            }
            array(lengths, seen, "E_FULL_MONTH_TOTALS");
        }
        fails("E_WEAVE_UNRANK_LIMIT", () ->
            family.unrank1(total.add(BigInteger.ONE).divide(BigInteger.TWO)));
        int[] interior = first.clone();
        for (int i = 0; i <= MonsterWeavingLinearCounter.MAX_EDGE_DISTANCE; i++) {
            interior = family.lexNext(interior);
        }
        final int[] interiorRank = interior;
        fails("E_WEAVE_RANK_LIMIT", () -> family.rank1(interiorRank));
        array(first, family.unrank1(BigInteger.ONE), "E_REENTRANT_FIRST");
        array(last, family.unrank1(total), "E_REENTRANT_LAST");
    }

    private static void testCanonicalCalendarAtEndpoints() {
        BigInteger foundation = MonsterArithmetic.FOUNDATION_DAY;
        MonsterYears.Year year = new MonsterYears().year5000(foundation);
        MonsterYearBlueprint plan = MonsterYearBlueprint.build(foundation, year);
        int[] lengths = plan.monthLengths();
        int days = Arrays.stream(lengths).sum();
        ok(days > MonsterWeavingLinearCounter.MAX_UNRANK_DAYS, "E_ACTUAL_LONG_YEAR");
        MonsterWeavingLinearCounter family = new MonsterWeavingLinearCounter(lengths);
        for (int[] weaving : List.of(family.lexFirst(), family.lexLast())) {
            MonsterCalendarResolver.ResolvedYear resolved =
                MonsterCalendarResolver.fromBlueprint(plan, weaving);
            eq(days, resolved.length(), "E_YEAR_LENGTH");
            for (int offset : new int[]{0, 1, days / 2, days - 2, days - 1}) {
                BigInteger target = year.openGateDay().add(BigInteger.valueOf(offset + 1L));
                MonsterCalendarResolver.CalendarDate result = resolved.atDay(target);
                MonsterYearBlueprint.Cutlet cutlet = plan.cutletAt(target);
                eq(year.number(), result.yearNumber(), "E_RESULT_YEAR");
                eq(cutlet.canonicalNameIndex(), result.canonicalCutletIndex(),
                    "E_RESULT_CUTLET_NAME");
                eq(target.subtract(cutlet.firstDay()).add(BigInteger.ONE),
                    result.dayInCutlet(), "E_RESULT_CUTLET_DAY");
            }
        }
    }

    private static void testResourceLimitsAndOwnership() {
        int[] initial = {123, 123, 123, 123, 123};
        MonsterWeavingLinearCounter family = new MonsterWeavingLinearCounter(initial);
        int[] original = family.lexLast();
        initial[0] = 1;
        family.lexLast()[0] = 0;
        array(original, family.lexLast(), "E_COPY_OWNERSHIP");
        BigInteger count = family.count();
        eq(count, family.rank1(original), "E_OWNED_MAX_RANK");
        eq(BigInteger.ONE, family.rank1(family.lexFirst()), "E_OWNED_MIN_RANK");
        fails("E_WEAVE_UNRANK_LIMIT", () ->
            family.unrank1(count.add(BigInteger.ONE).divide(BigInteger.TWO)));
        fails("E_WEAVE_RANK_LIMIT", () -> family.rank1(new int[0]));
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

    private static void ok(boolean condition, String code) {
        checks++;
        if (!condition) throw new AssertionError(code);
    }

    private static void positive(BigInteger value, String code) {
        ok(value.signum() > 0, code);
    }

    private static void fails(String expected, Runnable action) {
        checks++;
        try {
            action.run();
        } catch (IllegalArgumentException ex) {
            if (expected.equals(ex.getMessage())) return;
            throw new AssertionError("E_WRONG_ERROR " + expected + " actual=" + ex.getMessage(), ex);
        }
        throw new AssertionError("E_EXPECTED_FAILURE " + expected);
    }
}
