package org.pastafari.javalojban;

import java.math.BigInteger;
import java.util.Map;
import java.util.NavigableMap;
import java.util.TreeMap;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.Callable;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;

public final class Stage02GateTests {
    private static int checks;

    public static void main(String[] args) throws Exception {
        testGapOracle();
        testGateCacheAndSearch();
        testSnapshotOwnership();
        testConcurrentReads();
        testFailureContract();
        System.out.println("STAGE_02_GATES_PASS checks=" + checks);
    }

    private static void testGapOracle() {
        NormativeOracle oracle = new NormativeOracle();
        for (int i = 1; i <= 36; i++) {
            BigInteger index = BigInteger.valueOf(i);
            eq(oracle.positiveGateGap(index), MonsterGates.positiveGap(index), "E_POS_ORACLE");
            eq(oracle.negativeGateGap(index), MonsterGates.negativeGap(index), "E_NEG_ORACLE");
            for (BigInteger g : List.of(MonsterGates.positiveGap(index), MonsterGates.negativeGap(index))) {
                ok(g.compareTo(BigInteger.valueOf(42)) >= 0, "E_MIN_GAP");
                ok(g.compareTo(BigInteger.valueOf(963)) <= 0, "E_MAX_GAP");
            }
        }
        eq(Stage01Fixtures.POSITIVE_GATE_GAP_1, MonsterGates.positiveGap(BigInteger.ONE), "E_POS_FIX");
        eq(Stage01Fixtures.NEGATIVE_GATE_GAP_1, MonsterGates.negativeGap(BigInteger.ONE), "E_NEG_FIX");
    }

    private static void testGateCacheAndSearch() {
        MonsterGates gates = new MonsterGates();
        BigInteger f = MonsterArithmetic.FOUNDATION_DAY;
        eq(f, gates.gateAt(BigInteger.ZERO), "E_FOUNDATION_GATE");
        gates.coverDays(f.subtract(BigInteger.valueOf(4500)),
            f.add(BigInteger.valueOf(4500)));
        Map<BigInteger,BigInteger> snapshot = gates.snapshot();
        BigInteger previous = null;
        for (Map.Entry<BigInteger,BigInteger> entry : snapshot.entrySet()) {
            if (previous != null) {
                BigInteger difference = entry.getValue().subtract(previous);
                ok(difference.compareTo(BigInteger.valueOf(42)) >= 0
                    && difference.compareTo(BigInteger.valueOf(963)) <= 0, "E_GAP_RANGE");
            }
            previous = entry.getValue();
            eq(entry.getKey(), gates.exactGate(entry.getValue()), "E_EXACT_GATE");
            eq(entry.getKey(), gates.atOrBefore(entry.getValue()), "E_AT_GATE");
            BigInteger priorDay = entry.getValue().subtract(BigInteger.ONE);
            if (!entry.getKey().equals(snapshot.keySet().iterator().next())) {
                eq(entry.getKey().subtract(BigInteger.ONE),
                    gates.atOrBefore(priorDay), "E_DAY_BEFORE_GATE");
            }
        }
        BigInteger min = snapshot.keySet().iterator().next();
        BigInteger max = min.add(BigInteger.valueOf(snapshot.size() - 1));
        eq(gates.gateAt(min), snapshot.get(min), "E_CACHE_LOW");
        eq(gates.gateAt(max), snapshot.get(max), "E_CACHE_HIGH");
        NormativeOracle oracle = new NormativeOracle();
        for (int i = -13; i <= 13; i++) {
            BigInteger index = BigInteger.valueOf(i);
            BigInteger expected = f;
            if (i > 0) {
                for (int n = 1; n <= i; n++) {
                    expected = expected.add(oracle.positiveGateGap(BigInteger.valueOf(n)));
                }
            } else {
                for (int n = 1; n <= -i; n++) {
                    expected = expected.subtract(oracle.negativeGateGap(BigInteger.valueOf(n)));
                }
            }
            eq(expected, gates.gateAt(index), "E_GATE_INDEX_ORACLE");
        }
    }

    private static void testSnapshotOwnership() {
        MonsterGates a = new MonsterGates();
        MonsterGates b = new MonsterGates();
        BigInteger f = MonsterArithmetic.FOUNDATION_DAY;
        a.gateAt(BigInteger.TEN);
        eq(1, b.snapshot().size(), "E_INSTANCE_ISOLATION");
        eq(f, b.snapshot().get(BigInteger.ZERO), "E_INSTANCE_FOUNDATION");
        Map<BigInteger,BigInteger> snap = a.snapshot();
        failsUnsupported(() -> snap.put(BigInteger.ZERO, BigInteger.ZERO));
        a.gateAt(BigInteger.valueOf(11));
        eq(11, snap.size(), "E_SNAPSHOT_NOT_LIVE");
        eq(f, snap.get(BigInteger.ZERO), "E_SNAPSHOT_VALUE");
    }

    private static void testConcurrentReads() throws Exception {
        MonsterGates shared = new MonsterGates();
        ExecutorService executor = Executors.newFixedThreadPool(4);
        try {
            List<Callable<BigInteger>> tasks = new ArrayList<>();
            for (int i = -12; i <= 12; i++) {
                int n = i;
                tasks.add(() -> shared.gateAt(BigInteger.valueOf(n)));
            }
            List<Future<BigInteger>> results = executor.invokeAll(tasks);
            MonsterGates independent = new MonsterGates();
            int i = -12;
            for (Future<BigInteger> result : results) {
                eq(independent.gateAt(BigInteger.valueOf(i)), result.get(),
                    "E_CONCURRENT_GATE");
                i++;
            }
        } finally {
            executor.shutdownNow();
        }
    }

    private static void testFailureContract() {
        fails("E_POS_GATE", () -> MonsterGates.positiveGap(BigInteger.ZERO));
        fails("E_NEG_GATE", () -> MonsterGates.negativeGap(BigInteger.valueOf(-1)));
        fails("E_NULL_GATE", () -> new MonsterGates().gateAt(null));
        fails("E_GATE_RANGE", () -> new MonsterGates().coverDays(BigInteger.ONE, BigInteger.ZERO));
        fails("E_NULL_DAY", () -> new MonsterGates().atOrBefore(null));
    }

    private static void failsUnsupported(Runnable task) {
        checks++;
        try {
            task.run();
        } catch (UnsupportedOperationException expected) {
            return;
        }
        throw new AssertionError("E_EXPECTED_IMMUTABLE");
    }

    private static void fails(String code, Runnable task) {
        checks++;
        try {
            task.run();
        } catch (IllegalArgumentException e) {
            if (code.equals(e.getMessage())) return;
            throw new AssertionError("E_ERROR " + code + " actual=" + e.getMessage(), e);
        }
        throw new AssertionError("E_EXPECTED_ERROR " + code);
    }

    private static void eq(Object wanted, Object got, String code) {
        checks++;
        if (!wanted.equals(got)) {
            throw new AssertionError(code + " wanted=" + wanted + " got=" + got);
        }
    }

    private static void ok(boolean yes, String code) {
        checks++;
        if (!yes) throw new AssertionError(code);
    }
}
