package org.pastafari.javalojban;

import java.math.BigInteger;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.concurrent.Callable;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;

public final class Stage02IntegrationTests {
    private static int checks;

    public static void main(String[] args) throws Exception {
        testOracleIntegration();
        testSnapshotIsolation();
        testFailureRecovery();
        testConcurrentManager();
        System.out.println("STAGE_02_INTEGRATION_PASS checks=" + checks);
    }

    private static void testOracleIntegration() {
        MonsterManager manager = new MonsterManager();
        BigInteger f = MonsterArithmetic.FOUNDATION_DAY;
        BigInteger huge = BigInteger.ONE.shiftLeft(4097).add(BigInteger.valueOf(31));
        List<BigInteger[]> dates = List.of(
            new BigInteger[]{f, f},
            new BigInteger[]{f.subtract(BigInteger.ONE), f.add(BigInteger.ONE)},
            new BigInteger[]{MonsterArithmetic.TABLETS_DAY, f},
            new BigInteger[]{f, MonsterArithmetic.TABLETS_DAY},
            new BigInteger[]{BigInteger.ZERO, BigInteger.ZERO},
            new BigInteger[]{huge.negate(), huge}
        );
        for (BigInteger[] pair : dates) {
            MonsterEvaluation actual = manager.runSauce(pair[0], pair[1]);
            NormativeOracle.SauceResult oracle = NormativeOracle.sauce(pair[0], pair[1]);
            eq("COMPLETE", actual.status(), "E_STATUS");
            eq("SAUCE_COMPLETE", actual.phase(), "E_PHASE");
            eq(pair[0], actual.calculationDay(), "E_ACTION");
            eq(pair[1], actual.targetDay(), "E_TARGET");
            eq(List.of("ENTRY_VALIDATION", "BASE_CONTEXT_READY",
                "SAUCE_EVALUATION", "SAUCE_COMPLETE"), actual.branchTrace(), "E_TRACE");
            eq(4, actual.metrics().size(), "E_METRIC_COUNT");
            for (String key : List.of("bootstrap.entry", "bootstrap.context.ready",
                "sauce.started", "sauce.completed")) {
                eq(BigInteger.ONE, actual.metrics().get(key), "E_METRIC");
            }
            eq(0, actual.diagnostics().size(), "E_DIAGNOSTIC_EMPTY");
            for (int id = 1; id <= 6; id++) {
                eq(oracle.bowls()[id], actual.sauce().bowl(id), "E_BOWL");
                NormativeOracle.AnswerStream expected =
                    NormativeOracle.askBowl(oracle, id, 21);
                for (BigInteger n : List.of(BigInteger.ONE, BigInteger.valueOf(720),
                    MonsterArithmetic.MODULUS.add(BigInteger.ONE))) {
                    BigInteger answer = NormativeOracle.chooseRank(expected, n);
                    eq(answer, actual.choose(id, 21, n), "E_SELECT");
                }
            }
            arr(oracle.orderAtDrop46(), actual.sauce().orderAtDrop46(), "E_ORDER");
        }
    }

    private static void testSnapshotIsolation() {
        MonsterManager manager = new MonsterManager();
        BigInteger f = MonsterArithmetic.FOUNDATION_DAY;
        MonsterEvaluation a = manager.runSauce(f, f);
        MonsterEvaluation b = manager.runSauce(f, f);
        ok(a != b, "E_RUN_ID");
        ok(a.sauce() != b.sauce(), "E_SAUCE_ID");
        eq(a.sauce().bowl(1), b.sauce().bowl(1), "E_SAUCE_DETERMINISM");
        List<String> trace = a.branchTrace();
        try {
            trace.add("tamper");
            throw new AssertionError("E_MUTABLE_TRACE");
        } catch (UnsupportedOperationException expected) {
            checks++;
        }
        try {
            a.metrics().put("tamper", BigInteger.ONE);
            throw new AssertionError("E_MUTABLE_METRICS");
        } catch (UnsupportedOperationException expected) {
            checks++;
        }
        BigInteger[] bowls = a.sauce().bowls();
        bowls[1] = BigInteger.ZERO;
        eq(b.sauce().bowl(1), a.sauce().bowl(1), "E_SNAPSHOT_BOWLS");
        eq(4, b.branchTrace().size(), "E_TRACE_ISOLATION");
        eq(4, b.metrics().size(), "E_METRICS_ISOLATION");
    }

    private static void testFailureRecovery() {
        MonsterManager manager = new MonsterManager();
        BigInteger f = MonsterArithmetic.FOUNDATION_DAY;
        fails("E_NULL_DAY", () -> manager.runSauce(null, f));
        fails("E_NULL_DAY", () -> manager.runSauce(f, null));
        MonsterEvaluation after = manager.runSauce(f, f);
        eq("COMPLETE", after.status(), "E_RECOVERY");
        fails("E_BOWL_ID", () -> after.choose(0, 21, BigInteger.ONE));
        fails("E_CHOOSE_N", () -> after.choose(1, 21, BigInteger.ZERO));
        eq("COMPLETE", after.status(), "E_FAILURE_NO_MUTATION");
    }

    private static void testConcurrentManager() throws Exception {
        MonsterManager manager = new MonsterManager();
        ExecutorService pool = Executors.newFixedThreadPool(4);
        try {
            BigInteger f = MonsterArithmetic.FOUNDATION_DAY;
            List<Callable<MonsterEvaluation>> tasks = new ArrayList<>();
            for (int i = 0; i < 12; i++) {
                int n = i % 4;
                tasks.add(() -> manager.runSauce(
                    f.add(BigInteger.valueOf(n)),
                    f.subtract(BigInteger.valueOf(2 * n + 1))));
            }
            List<Future<MonsterEvaluation>> concurrent = pool.invokeAll(tasks);
            for (int i = 0; i < concurrent.size(); i++) {
                int n = i % 4;
                MonsterEvaluation result = concurrent.get(i).get();
                MonsterEvaluation serial = manager.runSauce(
                    f.add(BigInteger.valueOf(n)),
                    f.subtract(BigInteger.valueOf(2 * n + 1)));
                eq("COMPLETE", result.status(), "E_PARALLEL_STATUS");
                eq(serial.sauce().bowl(6), result.sauce().bowl(6), "E_PARALLEL_VALUE");
                eq(serial.metrics(), result.metrics(), "E_PARALLEL_METRICS");
                ok(serial != result, "E_PARALLEL_ID");
            }
        } finally {
            pool.shutdownNow();
        }
    }

    private static void fails(String code, Runnable operation) {
        checks++;
        try {
            operation.run();
        } catch (IllegalArgumentException e) {
            if (code.equals(e.getMessage())) return;
            throw new AssertionError("E_WRONG_ERROR " + code + " actual=" + e.getMessage(), e);
        }
        throw new AssertionError("E_NO_ERROR " + code);
    }

    private static void arr(int[] expected, int[] actual, String code) {
        checks++;
        if (!Arrays.equals(expected, actual)) throw new AssertionError(code);
    }

    private static void eq(Object expected, Object actual, String code) {
        checks++;
        if (!expected.equals(actual)) throw new AssertionError(code + " expected=" + expected + " actual=" + actual);
    }

    private static void ok(boolean expected, String code) {
        checks++;
        if (!expected) throw new AssertionError(code);
    }
}
