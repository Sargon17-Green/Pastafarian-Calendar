package org.pastafari.javalojban;

import java.math.BigInteger;
import java.util.Arrays;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

public final class Stage02BlueprintTests {
    private static int checks;

    public static void main(String[] args) {
        BigInteger foundation = MonsterArithmetic.FOUNDATION_DAY;
        for (int offset : new int[]{-125, 0, 97}) {
            BigInteger calculation = foundation.add(BigInteger.valueOf(offset));
            MonsterYears generator = new MonsterYears();
            MonsterYears.Year year = generator.year5000(calculation);
            compare(calculation, year);
        }
        MonsterYears traversal = new MonsterYears();
        MonsterYears.Year anchor = traversal.year5000(foundation);
        compare(foundation, traversal.nextYear(foundation, anchor));
        compare(foundation, traversal.previousYear(foundation, anchor));
        testOwnership();
        testInputValidation();
        System.out.println("STAGE_02_BLUEPRINT_PASS checks=" + checks);
    }

    private static void compare(BigInteger calculation, MonsterYears.Year year) {
        MonsterYearBlueprint actual = MonsterYearBlueprint.build(calculation, year);
        NormativeOracle oracle = new NormativeOracle();
        NormativeOracle.Year referenceYear = oracle.findTargetYear(
            calculation, year.closeGateDay());
        eq(referenceYear.openGateDay(), year.openGateDay(), "E_YEAR_OPEN");
        eq(referenceYear.closeGateDay(), year.closeGateDay(), "E_YEAR_CLOSE");
        NormativeOracle.SauceResult sauce = NormativeOracle.sauce(
            calculation, year.openGateDay().add(BigInteger.ONE));
        int gaps = year.closeGateIndex().subtract(year.openGateIndex()).intValueExact();
        int cutletCount = 6 + NormativeOracle.chooseRank(
            NormativeOracle.askBowl(sauce, 2, 20),
            BigInteger.valueOf(Math.min(17, gaps) - 5L)).intValueExact() - 1;
        eq(cutletCount, actual.cutletCount(), "E_CUTLET_COUNT");
        Integer required = null;
        for (var e : oracle.generatedGateSnapshot().entrySet()) {
            if (e.getValue().equals(calculation)
                && e.getKey().compareTo(year.openGateIndex()) > 0
                && e.getKey().compareTo(year.closeGateIndex()) < 0) {
                required = e.getKey().subtract(year.openGateIndex()).intValueExact();
            }
        }
        NormativeOracle.CutletPartitionFamily family =
            new NormativeOracle.CutletPartitionFamily(gaps, cutletCount, required);
        int[] partition = family.unrank1(NormativeOracle.chooseRank(
            NormativeOracle.askBowl(sauce, 2, 21), family.count()));
        arr(partition, actual.cutletPartition(), "E_CUTLET_PARTITION");
        int[] names = NormativeOracle.unrankDistinctIndices(17, cutletCount,
            NormativeOracle.chooseRank(NormativeOracle.askBowl(sauce, 5, 22),
            NormativeOracle.fallingFactorial(17, cutletCount)));
        arr(names, actual.cutletNameIndices(), "E_CUTLET_NAMES");

        int length = year.length().intValueExact();
        int low = (length + 122) / 123;
        int high = Math.min(47, length / 4);
        int months = low + NormativeOracle.chooseRank(
            NormativeOracle.askBowl(sauce, 3, 30),
            BigInteger.valueOf(high - low + 1L)).intValueExact() - 1;
        eq(months, actual.monthCount(), "E_MONTH_COUNT");
        NormativeOracle.BoundedCompositionFamily monthFamily =
            new NormativeOracle.BoundedCompositionFamily(length, months, 4, 123);
        arr(monthFamily.unrank1(NormativeOracle.chooseRank(
            NormativeOracle.askBowl(sauce, 3, 31), monthFamily.count())),
            actual.monthLengths(), "E_MONTH_LENGTHS");
        arr(NormativeOracle.unrankDistinctIndices(47, months,
            NormativeOracle.chooseRank(NormativeOracle.askBowl(sauce, 5, 33),
            NormativeOracle.fallingFactorial(47, months))),
            actual.monthNameIndices(), "E_MONTH_NAMES");
        eq(length, Arrays.stream(actual.monthLengths()).sum(), "E_DAY_COVERAGE");
        Set<Integer> distinctNames = new HashSet<>();
        for (int name : actual.monthNameIndices()) {
            ok(name >= 1 && name <= 47, "E_MONTH_NAME_INDEX");
            ok(distinctNames.add(name), "E_MONTH_NAME_DISTINCT");
        }
        BigInteger next = year.openGateDay().add(BigInteger.ONE);
        BigInteger last = year.openGateDay();
        for (MonsterYearBlueprint.Cutlet cutlet : actual.cutlets()) {
            eq(next, cutlet.firstDay(), "E_CUTLET_CONTIGUOUS");
            eq(cutlet.canonicalNameIndex(), actual.cutletAt(next).canonicalNameIndex(), "E_CUTLET_LOOKUP");
            eq(cutlet.canonicalNameIndex(), actual.cutletAt(cutlet.lastDay()).canonicalNameIndex(), "E_CUTLET_END");
            ok(cutlet.lastDay().compareTo(cutlet.firstDay()) >= 0, "E_CUTLET_NONEMPTY");
            last = cutlet.lastDay();
            next = last.add(BigInteger.ONE);
        }
        eq(year.closeGateDay(), last, "E_CUTLET_LAST_DAY");
        eq(year.number(), actual.year().number(), "E_YEAR_NUMBER");
    }

    private static void testOwnership() {
        BigInteger f = MonsterArithmetic.FOUNDATION_DAY;
        MonsterYears.Year year = new MonsterYears().year5000(f);
        MonsterYearBlueprint a = MonsterYearBlueprint.build(f, year);
        MonsterYearBlueprint b = MonsterYearBlueprint.build(f, year);
        int[] partition = a.cutletPartition();
        int[] monthLengths = a.monthLengths();
        int[] monthNames = a.monthNameIndices();
        partition[0] = -100;
        monthLengths[0] = -100;
        monthNames[0] = -100;
        eq(b.cutletPartition()[0], a.cutletPartition()[0], "E_CUTLET_DEFENSIVE");
        eq(b.monthLengths()[0], a.monthLengths()[0], "E_MONTH_DEFENSIVE");
        eq(b.monthNameIndices()[0], a.monthNameIndices()[0], "E_NAMES_DEFENSIVE");
        failsUnsupported(() -> a.cutlets().clear());
        ok(a != b, "E_BLUEPRINT_PER_REQUEST");
        arr(a.cutletPartition(), b.cutletPartition(), "E_BLUEPRINT_DETERMINISM");
    }

    private static void testInputValidation() {
        BigInteger f = MonsterArithmetic.FOUNDATION_DAY;
        MonsterYears.Year good = new MonsterYears().year5000(f);
        fails("E_NULL_DAY", () -> MonsterYearBlueprint.build(null, good));
        fails("E_YEAR_NULL", () -> MonsterYearBlueprint.build(f, null));
        fails("E_YEAR_GATE", () -> MonsterYearBlueprint.build(f,
            new MonsterYears.Year(BigInteger.valueOf(5000), BigInteger.ZERO,
                BigInteger.ONE, f, f.add(BigInteger.ONE))));
        MonsterYearBlueprint blueprint = MonsterYearBlueprint.build(f, good);
        fails("E_DAY_OUTSIDE_YEAR", () -> blueprint.cutletAt(good.openGateDay()));
        fails("E_DAY_OUTSIDE_YEAR", () -> blueprint.cutletAt(good.closeGateDay().add(BigInteger.ONE)));
        fails("E_NULL_DAY", () -> blueprint.cutletAt(null));
    }

    private static void failsUnsupported(Runnable runnable) {
        checks++;
        try { runnable.run(); }
        catch (UnsupportedOperationException expected) { return; }
        throw new AssertionError("E_EXPECTED_IMMUTABLE");
    }
    private static void fails(String code, Runnable runnable) {
        checks++;
        try { runnable.run(); }
        catch (IllegalArgumentException e) {
            if (code.equals(e.getMessage())) return;
            throw new AssertionError("E_WRONG_ERROR expected=" + code + " actual=" + e.getMessage(), e);
        }
        throw new AssertionError("E_EXPECTED_ERROR " + code);
    }
    private static void arr(int[] expected, int[] actual, String code) {
        checks++;
        if (!Arrays.equals(expected, actual)) throw new AssertionError(code + " expected="
            + Arrays.toString(expected) + " actual=" + Arrays.toString(actual));
    }
    private static void eq(Object expected, Object actual, String code) {
        checks++;
        if (!expected.equals(actual)) throw new AssertionError(code + " expected=" + expected + " actual=" + actual);
    }
    private static void ok(boolean value, String code) {
        checks++;
        if (!value) throw new AssertionError(code);
    }
}
