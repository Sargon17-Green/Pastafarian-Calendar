package org.pastafari.javalojban;

import java.math.BigInteger;
import java.util.Arrays;
import java.util.List;
import java.util.ArrayList;
import java.util.concurrent.Callable;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;

public final class Stage02DropsTests {
    private static int checks;

    public static void main(String[] args) throws Exception {
        testStoneTable();
        testFoundationFixtures();
        testDateMatrix();
        testExtremeNumbers();
        testOwnership();
        testErrors();
        testConcurrentCalls();
        System.out.println("STAGE_02_DROPS_PASS checks=" + checks);
    }

    private static void testStoneTable() {
        BigInteger[][] actual = MonsterSauceDrops.stonesCopy();
        BigInteger[][] expected = NormativeOracle.stoneTableCopy();
        eq(47, actual.length, "E_STONE_COUNT");
        for (int i = 1; i <= 46; i++) {
            for (int j = 1; j <= 5; j++) {
                eq(expected[i][j], actual[i][j], "E_STONE_VALUE_" + i + "_" + j);
                inRange(actual[i][j], "E_STONE_RANGE");
            }
        }
        actual[1][1] = BigInteger.ZERO;
        actual[46][5] = BigInteger.ZERO;
        eq(expected[1][1], MonsterSauceDrops.stonesCopy()[1][1], "E_STONE_DEFENSIVE_1");
        eq(expected[46][5], MonsterSauceDrops.stonesCopy()[46][5], "E_STONE_DEFENSIVE_46");
        ok(actual != MonsterSauceDrops.stonesCopy(), "E_STONE_ARRAY_ID");
        ok(actual[3] != MonsterSauceDrops.stonesCopy()[3], "E_STONE_ROW_ID");
    }

    private static void testFoundationFixtures() {
        BigInteger f = MonsterArithmetic.FOUNDATION_DAY;
        MonsterSauceDrops.Drops actual = MonsterSauceDrops.prepare(f, f);
        eq(Stage01Fixtures.HIDDEN_1_AT_FOUNDATION, actual.hiddenAt(1), "E_FIX_HIDDEN_1");
        eq(Stage01Fixtures.DROP_1_AT_FOUNDATION, actual.visibleAt(1), "E_FIX_VISIBLE_1");
        eq(Stage01Fixtures.DROP_46_AT_FOUNDATION, actual.visibleAt(46), "E_FIX_VISIBLE_46");
        eq(8, actual.hidden().length, "E_HIDDEN_LENGTH");
        eq(47, actual.visible().length, "E_VISIBLE_LENGTH");
        eq(null, actual.hidden()[0], "E_HIDDEN_SENTINEL");
        eq(null, actual.visible()[0], "E_VISIBLE_SENTINEL");
    }

    private static void compareDates(BigInteger c, BigInteger t) {
        MonsterArithmetic.WorkCounts actualCounts = MonsterArithmetic.workCounts(c, t);
        NormativeOracle.WorkCounts oracleCounts = NormativeOracle.workCounts(c, t);
        BigInteger[] oracleHidden = NormativeOracle.buildHiddenDrops(oracleCounts);
        BigInteger[] oracleVisible = NormativeOracle.buildVisibleDrops(oracleCounts, oracleHidden);
        MonsterSauceDrops.Drops prepared = MonsterSauceDrops.prepare(c, t);
        BigInteger[] directHidden = MonsterSauceDrops.hiddenDrops(actualCounts);
        BigInteger[] directVisible = MonsterSauceDrops.visibleDrops(actualCounts, directHidden);
        for (int i = 1; i <= 7; i++) {
            eq(oracleHidden[i], prepared.hiddenAt(i), "E_HIDDEN_ORACLE");
            eq(oracleHidden[i], directHidden[i], "E_HIDDEN_DIRECT");
            inRange(prepared.hiddenAt(i), "E_HIDDEN_RANGE");
        }
        for (int i = 1; i <= 46; i++) {
            eq(oracleVisible[i], prepared.visibleAt(i), "E_VISIBLE_ORACLE");
            eq(oracleVisible[i], directVisible[i], "E_VISIBLE_DIRECT");
            inRange(prepared.visibleAt(i), "E_VISIBLE_RANGE");
        }
        eq(oracleVisible[46], prepared.visible()[46], "E_FINAL_VISIBLE");
    }

    private static void testDateMatrix() {
        BigInteger f = MonsterArithmetic.FOUNDATION_DAY;
        BigInteger[] positions = {-6000, -2500, -46, -7, -1, 0, 1, 7, 46, 2500, 6000};
        for (int c : new int[]{-46, -7, -1, 0, 1, 7, 46}) {
            for (int t : new int[]{-46, -7, -1, 0, 1, 7, 46}) {
                compareDates(f.add(BigInteger.valueOf(c)), f.add(BigInteger.valueOf(t)));
            }
        }
        for (long p : new long[]{-6000, -2500, -46, -7, -1, 0, 1, 7, 46, 2500, 6000}) {
            compareDates(f.add(BigInteger.valueOf(p)), MonsterArithmetic.TABLETS_DAY);
            compareDates(MonsterArithmetic.TABLETS_DAY, f.add(BigInteger.valueOf(p)));
        }
        compareDates(BigInteger.ZERO, BigInteger.ZERO);
        compareDates(BigInteger.valueOf(-278522L), BigInteger.valueOf(-278522L));
    }

    private static void testExtremeNumbers() {
        BigInteger extreme = BigInteger.ONE.shiftLeft(3073).add(BigInteger.valueOf(901));
        BigInteger f = MonsterArithmetic.FOUNDATION_DAY;
        compareDates(extreme, extreme);
        compareDates(extreme.negate(), extreme);
        compareDates(extreme, extreme.negate());
        compareDates(f, extreme);
        compareDates(extreme.negate(), f);
        compareDates(extreme.add(BigInteger.ONE), extreme);
        compareDates(extreme.negate().subtract(BigInteger.ONE), extreme.negate());
    }

    private static void testOwnership() {
        BigInteger f = MonsterArithmetic.FOUNDATION_DAY;
        MonsterSauceDrops.Drops result = MonsterSauceDrops.prepare(f, f);
        BigInteger originalHidden = result.hiddenAt(7);
        BigInteger originalVisible = result.visibleAt(46);
        BigInteger[] hidden = result.hidden();
        BigInteger[] visible = result.visible();
        hidden[7] = BigInteger.ZERO;
        visible[46] = BigInteger.ZERO;
        eq(originalHidden, result.hiddenAt(7), "E_HIDDEN_RESULT_COPY");
        eq(originalVisible, result.visibleAt(46), "E_VISIBLE_RESULT_COPY");
        MonsterSauceDrops.Drops second = MonsterSauceDrops.prepare(f, f);
        eq(originalVisible, second.visibleAt(46), "E_CROSS_REQUEST_COPY");
        ok(result != second, "E_CROSS_REQUEST_ID");
        BigInteger[] supplied = MonsterSauceDrops.hiddenDrops(MonsterArithmetic.workCounts(f, f));
        BigInteger[] before = supplied.clone();
        MonsterSauceDrops.visibleDrops(MonsterArithmetic.workCounts(f, f), supplied);
        ok(Arrays.equals(before, supplied), "E_HIDDEN_INPUT_INTACT");
    }

    private static void testErrors() {
        BigInteger f = MonsterArithmetic.FOUNDATION_DAY;
        MonsterArithmetic.WorkCounts valid = MonsterArithmetic.workCounts(f, f);
        fails("E_NULL_DAY", () -> MonsterSauceDrops.prepare(null, f));
        fails("E_NULL_DAY", () -> MonsterSauceDrops.prepare(f, null));
        fails("E_NULL_COUNTS", () -> MonsterSauceDrops.hiddenDrops(null));
        fails("E_NULL_COUNTS", () -> MonsterSauceDrops.hiddenDrops(new MonsterArithmetic.WorkCounts(null, BigInteger.ONE, BigInteger.ONE, BigInteger.ONE, 2)));
        fails("E_DIRECTION", () -> MonsterSauceDrops.hiddenDrops(new MonsterArithmetic.WorkCounts(BigInteger.ONE, BigInteger.ONE, BigInteger.ONE, BigInteger.ONE, 4)));
        fails("E_NULL_HIDDEN", () -> MonsterSauceDrops.visibleDrops(valid, null));
        fails("E_HIDDEN_LENGTH", () -> MonsterSauceDrops.visibleDrops(valid, new BigInteger[7]));
        fails("E_NULL_HIDDEN_DROP", () -> MonsterSauceDrops.visibleDrops(valid, new BigInteger[8]));
        MonsterSauceDrops.Drops result = MonsterSauceDrops.prepare(f, f);
        fails("E_HIDDEN_INDEX", () -> result.hiddenAt(0));
        fails("E_HIDDEN_INDEX", () -> result.hiddenAt(8));
        fails("E_VISIBLE_INDEX", () -> result.visibleAt(0));
        fails("E_VISIBLE_INDEX", () -> result.visibleAt(47));
    }

    private static void testConcurrentCalls() throws Exception {
        ExecutorService pool = Executors.newFixedThreadPool(4);
        try {
            List<Callable<BigInteger>> jobs = new ArrayList<>();
            BigInteger f = MonsterArithmetic.FOUNDATION_DAY;
            for (int i = 0; i < 12; i++) {
                int index = i % 4;
                jobs.add(() -> MonsterSauceDrops.prepare(
                    f.add(BigInteger.valueOf(index - 2)),
                    f.add(BigInteger.valueOf(index + 3))
                ).visibleAt(46));
            }
            List<Future<BigInteger>> actual = pool.invokeAll(jobs);
            for (int i = 0; i < actual.size(); i++) {
                int index = i % 4;
                BigInteger expected = MonsterSauceDrops.prepare(
                    f.add(BigInteger.valueOf(index - 2)),
                    f.add(BigInteger.valueOf(index + 3))
                ).visibleAt(46);
                eq(expected, actual.get(i).get(), "E_CONCURRENT_" + i);
            }
        } finally {
            pool.shutdownNow();
        }
    }

    private static void inRange(BigInteger value, String code) {
        ok(value.signum() > 0 && value.compareTo(MonsterArithmetic.MODULUS) <= 0, code);
    }

    private static void fails(String code, Runnable action) {
        checks++;
        try {
            action.run();
        } catch (IllegalArgumentException ex) {
            if (code.equals(ex.getMessage())) return;
            throw new AssertionError("E_WRONG_ERROR expected=" + code + " actual=" + ex.getMessage(), ex);
        }
        throw new AssertionError("E_NO_FAILURE " + code);
    }

    private static void eq(Object expected, Object actual, String code) {
        checks++;
        if (expected == null ? actual != null : !expected.equals(actual)) {
            throw new AssertionError(code + " expected=" + expected + " actual=" + actual);
        }
    }

    private static void ok(boolean good, String code) {
        checks++;
        if (!good) throw new AssertionError(code);
    }
}
