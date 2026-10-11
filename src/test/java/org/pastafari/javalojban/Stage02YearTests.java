package org.pastafari.javalojban;

import java.math.BigInteger;
import java.util.Arrays;
import java.util.List;
import java.util.Map;

public final class Stage02YearTests {
    private static int checks;

    public static void main(String[] args) {
        testYear5000Oracle();
        testTransitions();
        testTargetLookup();
        testIsolation();
        testFailures();
        System.out.println("STAGE_02_YEARS_PASS checks=" + checks);
    }

    private static void testYear5000Oracle() {
        BigInteger f = MonsterArithmetic.FOUNDATION_DAY;
        for (int delta : new int[]{-800, -150, -1, 0, 1, 150, 800}) {
            BigInteger c = f.add(BigInteger.valueOf(delta));
            NormativeOracle o = new NormativeOracle();
            MonsterYears years = new MonsterYears();
            compare(o.year5000(c), years.year5000(c), "E_YEAR5000");
            ok(years.gateSnapshot().containsKey(BigInteger.ZERO), "E_GATE_F");
        }
        MonsterYears.Year fixture = new MonsterYears().year5000(f);
        eq(Stage01Fixtures.YEAR_5000_OPEN_INDEX_AT_FOUNDATION, fixture.openGateIndex(), "E_FIX_OPEN_IDX");
        eq(Stage01Fixtures.YEAR_5000_CLOSE_INDEX_AT_FOUNDATION, fixture.closeGateIndex(), "E_FIX_CLOSE_IDX");
        eq(Stage01Fixtures.YEAR_5000_OPEN_DAY_AT_FOUNDATION, fixture.openGateDay(), "E_FIX_OPEN_DAY");
        eq(Stage01Fixtures.YEAR_5000_CLOSE_DAY_AT_FOUNDATION, fixture.closeGateDay(), "E_FIX_CLOSE_DAY");
    }

    private static void testTransitions() {
        BigInteger f = MonsterArithmetic.FOUNDATION_DAY;
        for (BigInteger c : List.of(f, f.add(BigInteger.valueOf(211)),
                f.subtract(BigInteger.valueOf(317)))) {
            NormativeOracle oracle = new NormativeOracle();
            MonsterYears current = new MonsterYears();
            NormativeOracle.Year o = oracle.year5000(c);
            MonsterYears.Year y = current.year5000(c);
            for (int step = 0; step < 3; step++) {
                o = oracle.nextYear(c, o);
                y = current.nextYear(c, y);
                compare(o, y, "E_NEXT_ORACLE");
                ok(y.length().compareTo(BigInteger.valueOf(5778)) <= 0, "E_NEXT_LENGTH");
            }
            o = oracle.year5000(c);
            y = current.year5000(c);
            for (int step = 0; step < 3; step++) {
                o = oracle.previousYear(c, o);
                y = current.previousYear(c, y);
                compare(o, y, "E_PREVIOUS_ORACLE");
                ok(y.length().compareTo(BigInteger.valueOf(252)) >= 0, "E_PREVIOUS_LENGTH");
            }
        }
    }

    private static void testTargetLookup() {
        BigInteger c = MonsterArithmetic.FOUNDATION_DAY;
        NormativeOracle oracle = new NormativeOracle();
        MonsterYears current = new MonsterYears();
        NormativeOracle.Year reference = oracle.year5000(c);
        for (BigInteger t : List.of(c, reference.openGateDay(),
                reference.openGateDay().add(BigInteger.ONE),
                reference.closeGateDay(),
                reference.closeGateDay().add(BigInteger.ONE),
                c.subtract(BigInteger.valueOf(5300)),
                c.add(BigInteger.valueOf(5300)))) {
            MonsterYears.Year actual = current.findTargetYear(c, t);
            compare(oracle.findTargetYear(c, t), actual, "E_TARGET_ORACLE");
            ok(actual.openGateDay().compareTo(t) < 0, "E_TARGET_OPEN");
            ok(actual.closeGateDay().compareTo(t) >= 0, "E_TARGET_CLOSE");
        }
    }

    private static void testIsolation() {
        BigInteger f = MonsterArithmetic.FOUNDATION_DAY;
        MonsterYears a = new MonsterYears();
        MonsterYears b = new MonsterYears();
        MonsterYears.Year year = a.year5000(f);
        eq(1, b.gateSnapshot().size(), "E_OWNED_GATE_CACHE");
        Map<BigInteger,BigInteger> prior = a.gateSnapshot();
        MonsterYears.Year next = a.nextYear(f, year);
        compareValues(year, a.year5000(f), "E_CACHED_REPEAT");
        eq(year.closeGateIndex(), next.openGateIndex(), "E_CONTIGUOUS_YEAR");
        try {
            prior.put(BigInteger.ONE, BigInteger.ZERO);
            throw new AssertionError("E_MUTABLE_YEAR_SNAPSHOT");
        } catch (UnsupportedOperationException e) {
            checks++;
        }
        compareValues(year, b.year5000(f), "E_SEPARATE_INSTANCE");
    }

    private static void testFailures() {
        MonsterYears years = new MonsterYears();
        fails("E_NULL_DAY", () -> years.year5000(null));
        fails("E_NULL_DAY", () -> years.findTargetYear(null, BigInteger.ZERO));
        fails("E_YEAR_NULL", () -> years.nextYear(MonsterArithmetic.FOUNDATION_DAY, null));
        MonsterYears.Year corrupted = new MonsterYears.Year(BigInteger.valueOf(5000),
            BigInteger.ZERO, BigInteger.ONE, BigInteger.ZERO, BigInteger.ONE);
        fails("E_YEAR_GATE", () -> years.nextYear(MonsterArithmetic.FOUNDATION_DAY, corrupted));
    }

    private static void compare(NormativeOracle.Year oracle, MonsterYears.Year actual, String code) {
        eq(oracle.number(), actual.number(), code + " NUMBER");
        eq(oracle.openGateIndex(), actual.openGateIndex(), code + " OPEN_INDEX");
        eq(oracle.closeGateIndex(), actual.closeGateIndex(), code + " CLOSE_INDEX");
        eq(oracle.openGateDay(), actual.openGateDay(), code + " OPEN_DAY");
        eq(oracle.closeGateDay(), actual.closeGateDay(), code + " CLOSE_DAY");
    }

    private static void compareValues(MonsterYears.Year a, MonsterYears.Year b, String code) {
        eq(a, b, code);
    }

    private static void fails(String code, Runnable action) {
        checks++;
        try {
            action.run();
        } catch (IllegalArgumentException e) {
            if (code.equals(e.getMessage())) return;
            throw new AssertionError("E_WRONG_FAILURE " + code + " actual=" + e.getMessage(), e);
        }
        throw new AssertionError("E_EXPECTED_FAILURE " + code);
    }

    private static void eq(Object expected, Object actual, String code) {
        checks++;
        if (!expected.equals(actual)) {
            throw new AssertionError(code + " expected=" + expected + " actual=" + actual);
        }
    }

    private static void ok(boolean condition, String code) {
        checks++;
        if (!condition) throw new AssertionError(code);
    }
}
