package org.pastafari.javalojban;

import java.math.BigInteger;
import java.util.List;

public final class Stage02Tests {
    private static int checks;

    public static void main(String[] args) {
        testAnchors();
        testEuclideanDivision();
        testCeilDivision();
        testSave();
        testDayCounting();
        testWorkCounting();
        testWrapping();
        testFailureBoundaries();
        System.out.println("STAGE_02_ARITHMETIC_PASS checks=" + checks);
    }

    private static void testAnchors() {
        eq(NormativeOracle.FOUNDATION_DAY, MonsterArithmetic.FOUNDATION_DAY, "E_ANCHOR_F");
        eq(NormativeOracle.TABLETS_DAY, MonsterArithmetic.TABLETS_DAY, "E_ANCHOR_T");
        eq(BigInteger.valueOf(14777149), MonsterArithmetic.TABLETS_DAY.subtract(MonsterArithmetic.FOUNDATION_DAY), "E_ANCHOR_GAP");
        eq(NormativeOracle.M, MonsterArithmetic.MODULUS, "E_MODULUS");
    }

    private static void testEuclideanDivision() {
        for (int a = -135; a <= 135; a++) {
            for (int b = 1; b <= 41; b++) {
                BigInteger x = BigInteger.valueOf(a);
                BigInteger y = BigInteger.valueOf(b);
                BigInteger q = MonsterArithmetic.floorDiv(x, y);
                BigInteger r = MonsterArithmetic.regularMod(x, y);
                eq(NormativeOracle.floorDiv(x, y), q, "E_DIV_ORACLE");
                eq(NormativeOracle.regularMod(x, y), r, "E_MOD_ORACLE");
                eq(x, q.multiply(y).add(r), "E_DIV_IDENTITY");
                ok(r.signum() >= 0 && r.compareTo(y) < 0, "E_MOD_RANGE");
            }
        }
        for (BigInteger x : hugeNumbers()) {
            for (BigInteger y : List.of(BigInteger.ONE, BigInteger.valueOf(17), MonsterArithmetic.MODULUS, BigInteger.ONE.shiftLeft(521).add(BigInteger.valueOf(19)))) {
                eq(NormativeOracle.floorDiv(x, y), MonsterArithmetic.floorDiv(x, y), "E_DIV_HUGE");
                eq(NormativeOracle.regularMod(x, y), MonsterArithmetic.regularMod(x, y), "E_MOD_HUGE");
            }
        }
    }

    private static void testCeilDivision() {
        for (int a = 0; a < 350; a++) {
            for (int b = 1; b <= 37; b++) {
                BigInteger x = BigInteger.valueOf(a);
                BigInteger y = BigInteger.valueOf(b);
                eq(NormativeOracle.ceilDiv(x, y), MonsterArithmetic.ceilDiv(x, y), "E_CEIL_ORACLE");
            }
        }
        BigInteger n = BigInteger.ONE.shiftLeft(2201).add(BigInteger.valueOf(99));
        eq(NormativeOracle.ceilDiv(n, BigInteger.valueOf(61)), MonsterArithmetic.ceilDiv(n, BigInteger.valueOf(61)), "E_CEIL_HUGE");
    }

    private static void testSave() {
        BigInteger m = MonsterArithmetic.MODULUS;
        for (int i = -250; i <= 250; i++) {
            BigInteger x = BigInteger.valueOf(i);
            BigInteger got = MonsterArithmetic.save(x);
            eq(NormativeOracle.save(x), got, "E_SAVE_ORACLE");
            eq(got, MonsterArithmetic.save(x.add(m)), "E_SAVE_PERIOD_PLUS");
            eq(got, MonsterArithmetic.save(x.subtract(m)), "E_SAVE_PERIOD_MINUS");
            ok(got.signum() > 0 && got.compareTo(m) <= 0, "E_SAVE_RANGE");
        }
        for (BigInteger x : hugeNumbers()) {
            eq(NormativeOracle.save(x), MonsterArithmetic.save(x), "E_SAVE_HUGE");
            eq(MonsterArithmetic.save(x), MonsterArithmetic.save(x.add(m.multiply(BigInteger.valueOf(997)))), "E_SAVE_HUGE_PERIOD");
        }
        eq(m, MonsterArithmetic.save(BigInteger.ZERO), "E_SAVE_ZERO");
        eq(m, MonsterArithmetic.save(m), "E_SAVE_M");
    }

    private static void testDayCounting() {
        BigInteger f = MonsterArithmetic.FOUNDATION_DAY;
        eq(BigInteger.ONE, MonsterArithmetic.dayCount(f), "E_DAY_FOUNDATION");
        for (int offset = -900; offset <= 900; offset++) {
            BigInteger d = f.add(BigInteger.valueOf(offset));
            BigInteger actual = MonsterArithmetic.dayCount(d);
            eq(NormativeOracle.dayCount(d), actual, "E_DAY_ORACLE");
            eq(BigInteger.valueOf(offset >= 0 ? 2L * offset + 1L : -2L * offset), actual, "E_DAY_BRANCH");
        }
        for (BigInteger x : hugeNumbers()) {
            eq(NormativeOracle.dayCount(x), MonsterArithmetic.dayCount(x), "E_DAY_HUGE");
        }
    }

    private static void testWorkCounting() {
        BigInteger f = MonsterArithmetic.FOUNDATION_DAY;
        for (int c = -50; c <= 50; c += 2) {
            for (int t = -51; t <= 51; t += 3) {
                BigInteger a = f.add(BigInteger.valueOf(c));
                BigInteger b = f.add(BigInteger.valueOf(t));
                NormativeOracle.WorkCounts expected = NormativeOracle.workCounts(a, b);
                MonsterArithmetic.WorkCounts actual = MonsterArithmetic.workCounts(a, b);
                eq(expected.action(), actual.action(), "E_WORK_A");
                eq(expected.target(), actual.target(), "E_WORK_T");
                eq(expected.distance(), actual.distance(), "E_WORK_D");
                eq(expected.connection(), actual.connection(), "E_WORK_C");
                eq(expected.direction(), actual.direction(), "E_WORK_W");
                eq(actual.distance(), MonsterArithmetic.workCounts(b, a).distance(), "E_WORK_SYMMETRY");
            }
        }
        BigInteger huge = BigInteger.ONE.shiftLeft(2501).add(BigInteger.valueOf(17));
        MonsterArithmetic.WorkCounts x = MonsterArithmetic.workCounts(huge.negate(), huge);
        eq(huge.shiftLeft(1).add(BigInteger.ONE), x.distance(), "E_WORK_HUGE_DISTANCE");
        eq(3, x.direction(), "E_WORK_HUGE_DIRECTION");
        eq(NormativeOracle.workCounts(huge.negate(), huge).connection(), x.connection(), "E_WORK_HUGE_CONNECTION");
        MonsterArithmetic.WorkCounts y = MonsterArithmetic.workCounts(huge.negate(), huge);
        ok(x != y, "E_WORK_OWNERSHIP");
        eq(x, y, "E_WORK_VALUE");
    }

    private static void testWrapping() {
        for (int size = 1; size <= 47; size++) {
            for (int i = -143; i <= 143; i++) {
                int result = MonsterArithmetic.wrap1(i, size);
                eq(NormativeOracle.wrap1(i, size), result, "E_WRAP_ORACLE");
                ok(result >= 1 && result <= size, "E_WRAP_RANGE");
            }
        }
        for (int size : new int[]{1, 2, 6, 47, 720, Integer.MAX_VALUE}) {
            for (int n : new int[]{Integer.MIN_VALUE, Integer.MAX_VALUE}) {
                int expected = (int) Math.floorMod((long) n - 1L, (long) size) + 1;
                eq(expected, MonsterArithmetic.wrap1(n, size), "E_WRAP_EXTREME");
            }
        }
    }

    private static void testFailureBoundaries() {
        fails("E_DIVISOR", () -> MonsterArithmetic.floorDiv(BigInteger.ONE, BigInteger.ZERO));
        fails("E_DIVISOR", () -> MonsterArithmetic.floorDiv(BigInteger.ONE, BigInteger.ONE.negate()));
        fails("E_MODULUS", () -> MonsterArithmetic.regularMod(BigInteger.ONE, BigInteger.ZERO));
        fails("E_CEILDIV", () -> MonsterArithmetic.ceilDiv(BigInteger.ONE.negate(), BigInteger.ONE));
        fails("E_CEILDIV", () -> MonsterArithmetic.ceilDiv(BigInteger.ZERO, BigInteger.ZERO));
        fails("E_WRAP_SIZE", () -> MonsterArithmetic.wrap1(0, 0));
        fails("E_NULL_DAY", () -> MonsterArithmetic.dayCount(null));
        fails("E_NULL_DAY", () -> MonsterArithmetic.workCounts(null, BigInteger.ONE));
        fails("E_NULL_DAY", () -> MonsterArithmetic.workCounts(BigInteger.ONE, null));
        fails("E_NULL_NUMBER", () -> MonsterArithmetic.save(null));
        fails("E_NULL_NUMBER", () -> MonsterArithmetic.floorDiv(null, BigInteger.ONE));
        fails("E_NULL_NUMBER", () -> MonsterArithmetic.regularMod(BigInteger.ONE, null));
        fails("E_NULL_NUMBER", () -> MonsterArithmetic.ceilDiv(BigInteger.ONE, null));
    }

    private static List<BigInteger> hugeNumbers() {
        BigInteger positive = BigInteger.ONE.shiftLeft(2049).add(BigInteger.valueOf(517));
        return List.of(positive, positive.negate(), positive.multiply(BigInteger.valueOf(19)), MonsterArithmetic.MODULUS.negate().multiply(BigInteger.valueOf(100_001)));
    }

    private static void fails(String code, Runnable action) {
        checks++;
        try {
            action.run();
        } catch (IllegalArgumentException e) {
            if (code.equals(e.getMessage())) return;
            throw new AssertionError("E_WRONG_FAILURE expected=" + code + " actual=" + e.getMessage(), e);
        }
        throw new AssertionError("E_EXPECTED_FAILURE " + code);
    }

    private static void eq(Object expected, Object actual, String code) {
        checks++;
        if (!expected.equals(actual)) throw new AssertionError(code + " expected=" + expected + " actual=" + actual);
    }

    private static void ok(boolean valid, String code) {
        checks++;
        if (!valid) throw new AssertionError(code);
    }
}
