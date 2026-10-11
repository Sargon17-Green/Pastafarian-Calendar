package org.pastafari.javalojban;

import java.math.BigInteger;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.concurrent.Callable;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;

public final class Stage02BowlsTests {
    private static int checks;

    public static void main(String[] args) throws Exception {
        testAllPermutations();
        testInitialBowls();
        testSauceFixtures();
        testOracleMatrix();
        testWraparoundQueries();
        testOwnership();
        testErrors();
        testParallelism();
        System.out.println("STAGE_02_BOWLS_PASS checks=" + checks);
    }

    private static void testAllPermutations() {
        Set<String> seen = new HashSet<>();
        int[] previous = null;
        for (int rank = 1; rank <= 720; rank++) {
            int[] actual = MonsterSauceBowls.unrankPermutation(rank);
            arr(NormativeOracle.permutationUnrank1(rank), actual, "E_PERM_ORACLE");
            ok(seen.add(Arrays.toString(actual)), "E_PERM_UNIQUE");
            if (previous != null) {
                ok(lexLess(previous, actual), "E_PERM_ORDER");
            }
            previous = actual;
        }
        eq(720, seen.size(), "E_PERM_COUNT");
        for (BigInteger drop : List.of(BigInteger.ONE, BigInteger.valueOf(720), BigInteger.valueOf(721),
                BigInteger.ONE.shiftLeft(3072), BigInteger.ONE.shiftLeft(3072).negate())) {
            arr(NormativeOracle.bowlOrderFromDrop(drop), MonsterSauceBowls.orderFromDrop(drop), "E_DROP_ORDER");
        }
    }

    private static boolean lexLess(int[] left, int[] right) {
        for (int i = 0; i < left.length; i++) {
            if (left[i] != right[i]) return left[i] < right[i];
        }
        return false;
    }

    private static void testInitialBowls() {
        BigInteger f = MonsterArithmetic.FOUNDATION_DAY;
        for (BigInteger[] dates : List.of(
                new BigInteger[]{f, f},
                new BigInteger[]{f.subtract(BigInteger.ONE), f.add(BigInteger.ONE)},
                new BigInteger[]{MonsterArithmetic.TABLETS_DAY, f},
                new BigInteger[]{BigInteger.ONE.shiftLeft(2025), BigInteger.ONE.shiftLeft(2025).negate()})) {
            MonsterArithmetic.WorkCounts current = MonsterArithmetic.workCounts(dates[0], dates[1]);
            NormativeOracle.WorkCounts reference = NormativeOracle.workCounts(dates[0], dates[1]);
            BigInteger[] actual = MonsterSauceBowls.initialBowls(current);
            BigInteger[] oracle = NormativeOracle.initialBowls(reference);
            eq(7, actual.length, "E_INIT_COUNT");
            for (int id = 1; id <= 6; id++) {
                eq(oracle[id], actual[id], "E_INIT_ORACLE");
                inRange(actual[id], "E_INIT_RANGE");
            }
        }
    }

    private static void testSauceFixtures() {
        BigInteger f = MonsterArithmetic.FOUNDATION_DAY;
        MonsterSauceBowls.SauceResult actual = MonsterSauceBowls.evaluate(f, f);
        for (int id = 1; id <= 6; id++) {
            eq(Stage01Fixtures.FINAL_BOWLS_AT_FOUNDATION[id - 1], actual.bowl(id), "E_FIX_BOWL");
        }
        arr(Stage01Fixtures.ORDER_46_AT_FOUNDATION, actual.orderAtDrop46(), "E_FIX_46");
        eq(4, actual.nextBowl(1), "E_FIX_ADJACENCY");
        MonsterSauceBowls.AnswerStream answer = MonsterSauceBowls.ask(actual, 1, 10);
        eq(Stage01Fixtures.ASK_YEAR_5000_FIRST_AT_FOUNDATION, answer.first(), "E_FIX_ASK_FIRST");
        eq(Stage01Fixtures.ASK_YEAR_5000_DIRECTION_AT_FOUNDATION, answer.directionStep(), "E_FIX_ASK_STEP");
    }

    private static void compare(BigInteger c, BigInteger t) {
        MonsterSauceBowls.SauceResult result = MonsterSauceBowls.evaluate(c, t);
        NormativeOracle.SauceResult reference = NormativeOracle.sauce(c, t);
        for (int id = 1; id <= 6; id++) {
            eq(reference.bowls()[id], result.bowl(id), "E_SAUCE_ORACLE");
            inRange(result.bowl(id), "E_SAUCE_RANGE");
            eq(NormativeOracle.nextBowlInDrop46Order(reference, id), result.nextBowl(id), "E_NEXT_ORACLE");
            for (int seal : new int[]{1, 10, 21, 31, 33, Integer.MAX_VALUE, Integer.MIN_VALUE}) {
                NormativeOracle.AnswerStream expected = NormativeOracle.askBowl(reference, id, seal);
                MonsterSauceBowls.AnswerStream actual = MonsterSauceBowls.ask(result, id, seal);
                eq(expected.first(), actual.first(), "E_ASK_FIRST");
                eq(expected.directionStep(), actual.directionStep(), "E_ASK_STEP");
                for (BigInteger offset : List.of(BigInteger.ZERO, BigInteger.ONE,
                        BigInteger.valueOf(-1L), BigInteger.valueOf(721L),
                        BigInteger.ONE.shiftLeft(400), BigInteger.ONE.shiftLeft(400).negate())) {
                    eq(NormativeOracle.answerAt(expected, offset), MonsterSauceBowls.answerAt(actual, offset), "E_ANSWER_AT");
                }
            }
        }
        arr(reference.orderAtDrop46(), result.orderAtDrop46(), "E_ORDER_46");
    }

    private static void testOracleMatrix() {
        BigInteger f = MonsterArithmetic.FOUNDATION_DAY;
        compare(f, f);
        compare(f.add(BigInteger.ONE), f);
        compare(f, f.subtract(BigInteger.ONE));
        compare(f.subtract(BigInteger.valueOf(130)), f.add(BigInteger.valueOf(414)));
        compare(MonsterArithmetic.TABLETS_DAY, f);
        compare(f, MonsterArithmetic.TABLETS_DAY);
        compare(BigInteger.ZERO, BigInteger.ZERO);
        compare(BigInteger.valueOf(20261011L), BigInteger.valueOf(-7620607L));
        BigInteger huge = BigInteger.ONE.shiftLeft(2057).add(BigInteger.valueOf(71));
        compare(huge, huge.negate());
        compare(huge.negate(), huge);
    }

    private static void testWraparoundQueries() {
        BigInteger f = MonsterArithmetic.FOUNDATION_DAY;
        MonsterSauceBowls.SauceResult result = MonsterSauceBowls.evaluate(f, f);
        for (int bowl = 1; bowl <= 6; bowl++) {
            MonsterSauceBowls.AnswerStream stream = MonsterSauceBowls.ask(result, bowl, 21);
            BigInteger zero = MonsterSauceBowls.answerAt(stream, BigInteger.ZERO);
            eq(stream.first(), zero, "E_ZERO_OFFSET");
            eq(zero, MonsterSauceBowls.answerAt(stream, MonsterArithmetic.MODULUS), "E_PERIOD_POSITIVE");
            eq(zero, MonsterSauceBowls.answerAt(stream, MonsterArithmetic.MODULUS.negate()), "E_PERIOD_NEGATIVE");
            BigInteger next = MonsterSauceBowls.answerAt(stream, BigInteger.ONE);
            eq(NormativeOracle.save(stream.first().add(BigInteger.valueOf(stream.directionStep()))), next, "E_STEP");
        }
    }

    private static void testOwnership() {
        BigInteger f = MonsterArithmetic.FOUNDATION_DAY;
        MonsterSauceBowls.SauceResult result = MonsterSauceBowls.evaluate(f, f);
        BigInteger original = result.bowl(4);
        int[] order = result.orderAtDrop46();
        BigInteger[] bowls = result.bowls();
        order[0] = -100;
        bowls[4] = BigInteger.ZERO;
        eq(original, result.bowl(4), "E_BOWL_COPY");
        arr(Stage01Fixtures.ORDER_46_AT_FOUNDATION, result.orderAtDrop46(), "E_ORDER_COPY");
        eq(original, MonsterSauceBowls.evaluate(f, f).bowl(4), "E_REQUEST_NEUTRALITY");
        ok(result != MonsterSauceBowls.evaluate(f, f), "E_REQUEST_ID");
    }

    private static void testErrors() {
        BigInteger f = MonsterArithmetic.FOUNDATION_DAY;
        MonsterSauceBowls.SauceResult result = MonsterSauceBowls.evaluate(f, f);
        fails("E_PERM_RANK", () -> MonsterSauceBowls.unrankPermutation(0));
        fails("E_PERM_RANK", () -> MonsterSauceBowls.unrankPermutation(721));
        fails("E_NULL_DROP", () -> MonsterSauceBowls.orderFromDrop(null));
        fails("E_NULL_COUNTS", () -> MonsterSauceBowls.initialBowls(null));
        fails("E_DIRECTION", () -> MonsterSauceBowls.initialBowls(
                new MonsterArithmetic.WorkCounts(BigInteger.ONE, BigInteger.ONE, BigInteger.ONE, BigInteger.ONE, 0)));
        fails("E_NULL_DAY", () -> MonsterSauceBowls.evaluate(f, null));
        fails("E_BOWL_ID", () -> result.bowl(0));
        fails("E_BOWL_ID", () -> result.nextBowl(7));
        fails("E_BOWL_ID", () -> MonsterSauceBowls.ask(result, 0, 10));
        fails("E_NULL_SAUCE", () -> MonsterSauceBowls.ask(null, 1, 10));
        fails("E_NULL_ANSWER", () -> MonsterSauceBowls.answerAt(null, BigInteger.ZERO));
        fails("E_NULL_OFFSET", () -> MonsterSauceBowls.answerAt(new MonsterSauceBowls.AnswerStream(BigInteger.ONE, 1), null));
        fails("E_ANSWER_STEP", () -> MonsterSauceBowls.answerAt(new MonsterSauceBowls.AnswerStream(BigInteger.ONE, 0), BigInteger.ONE));
    }

    private static void testParallelism() throws Exception {
        ExecutorService pool = Executors.newFixedThreadPool(4);
        try {
            BigInteger f = MonsterArithmetic.FOUNDATION_DAY;
            List<Callable<BigInteger>> tasks = new ArrayList<>();
            for (int i = 0; i < 12; i++) {
                int n = i % 3;
                tasks.add(() -> MonsterSauceBowls.evaluate(f.add(BigInteger.valueOf(n)), f.subtract(BigInteger.valueOf(n + 1))).bowl(6));
            }
            List<Future<BigInteger>> results = pool.invokeAll(tasks);
            for (int i = 0; i < results.size(); i++) {
                int n = i % 3;
                eq(MonsterSauceBowls.evaluate(f.add(BigInteger.valueOf(n)), f.subtract(BigInteger.valueOf(n + 1))).bowl(6),
                    results.get(i).get(), "E_PARALLEL");
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
            throw new AssertionError("E_WRONG_FAILURE expected=" + code + " actual=" + ex.getMessage(), ex);
        }
        throw new AssertionError("E_EXPECTED_FAILURE " + code);
    }

    private static void arr(int[] expected, int[] actual, String code) {
        checks++;
        if (!Arrays.equals(expected, actual)) {
            throw new AssertionError(code + " expected=" + Arrays.toString(expected) + " actual=" + Arrays.toString(actual));
        }
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
