package org.pastafari.javalojban;

import java.math.BigInteger;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.concurrent.Callable;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;

public final class Stage02CutletDateTests {
    private static int checks;

    public static void main(String[] args) throws Exception {
        testCrossYearOracle();
        testRequestIsolation();
        testConcurrentManager();
        testErrors();
        System.out.println("STAGE_02_CUTLET_DATE_PASS checks=" + checks);
    }

    private static void testCrossYearOracle() {
        BigInteger f = MonsterArithmetic.FOUNDATION_DAY;
        for (BigInteger calculation : List.of(f, f.add(BigInteger.valueOf(17)))) {
            NormativeOracle known = new NormativeOracle();
            NormativeOracle.Year anchor = known.year5000(calculation);
            List<BigInteger> targets = List.of(
                anchor.openGateDay(),
                anchor.openGateDay().add(BigInteger.ONE),
                calculation,
                anchor.closeGateDay(),
                anchor.closeGateDay().add(BigInteger.ONE));
            for (BigInteger target : targets) {
                MonsterCutletCalendar.CutletDate current =
                    MonsterCutletCalendar.convert(calculation, target);
                verifyNormative(calculation, target, current);
                MonsterCutletCalendar.CutletDate viaManager =
                    new MonsterManager().cutletDate(calculation, target);
                eq(current, viaManager, "E_MANAGER_OUTPUT");
                eq(SourceLanguageCatalog.cutletName(current.canonicalCutletIndex()),
                    current.cutletName(), "E_SOURCE_CATALOG");
                eq(target.subtract(current.firstDay()).add(BigInteger.ONE),
                    current.dayInCutlet(), "E_CUTLET_POSITION");
            }
        }
    }

    private static void verifyNormative(BigInteger calculation, BigInteger target,
            MonsterCutletCalendar.CutletDate actual) {
        NormativeOracle oracle = new NormativeOracle();
        NormativeOracle.Year year = oracle.findTargetYear(calculation, target);
        eq(year.number(), actual.yearNumber(), "E_YEAR_NUMBER");
        eq(year.openGateDay(), actual.yearOpenDay(), "E_YEAR_START");
        eq(year.closeGateDay(), actual.yearCloseDay(), "E_YEAR_FINISH");
        NormativeOracle.SauceResult sauce = NormativeOracle.sauce(
            calculation, year.openGateDay().add(BigInteger.ONE));
        int gaps = year.closeGateIndex().subtract(year.openGateIndex()).intValueExact();
        int count = 6 + NormativeOracle.chooseRank(
            NormativeOracle.askBowl(sauce, 2, 20),
            BigInteger.valueOf(Math.min(17, gaps) - 5L)).intValueExact() - 1;
        Map<BigInteger, BigInteger> gates = oracle.generatedGateSnapshot();
        Integer required = null;
        for (var entry : gates.entrySet()) {
            if (entry.getValue().equals(calculation)
                    && entry.getKey().compareTo(year.openGateIndex()) > 0
                    && entry.getKey().compareTo(year.closeGateIndex()) < 0) {
                required = entry.getKey().subtract(year.openGateIndex()).intValueExact();
            }
        }
        NormativeOracle.CutletPartitionFamily partitions =
            new NormativeOracle.CutletPartitionFamily(gaps, count, required);
        int[] segments = partitions.unrank1(NormativeOracle.chooseRank(
            NormativeOracle.askBowl(sauce, 2, 21), partitions.count()));
        int[] names = NormativeOracle.unrankDistinctIndices(17, count,
            NormativeOracle.chooseRank(NormativeOracle.askBowl(sauce, 5, 22),
            NormativeOracle.fallingFactorial(17, count)));
        BigInteger cursor = year.openGateIndex();
        boolean matched = false;
        for (int i = 0; i < segments.length; i++) {
            BigInteger next = cursor.add(BigInteger.valueOf(segments[i]));
            BigInteger first = gates.get(cursor).add(BigInteger.ONE);
            BigInteger last = gates.get(next);
            if (first.compareTo(target) <= 0 && target.compareTo(last) <= 0) {
                eq(names[i], actual.canonicalCutletIndex(), "E_CANONICAL_CUTLET");
                eq(first, actual.firstDay(), "E_CUTLET_FIRST");
                eq(last, actual.lastDay(), "E_CUTLET_LAST");
                eq(target.subtract(first).add(BigInteger.ONE), actual.dayInCutlet(), "E_DAY_IN_CUTLET");
                matched = true;
            }
            cursor = next;
        }
        ok(matched, "E_CUTLET_CONTAINS_TARGET");
        eq(year.closeGateIndex(), cursor, "E_ALL_CUTLETS_COVERED");
    }

    private static void testRequestIsolation() {
        BigInteger f = MonsterArithmetic.FOUNDATION_DAY;
        MonsterManager shared = new MonsterManager();
        MonsterCutletCalendar.CutletDate a = shared.cutletDate(f, f);
        MonsterCutletCalendar.CutletDate b = shared.cutletDate(f, f);
        ok(a != b, "E_INDEPENDENT_RESULTS");
        eq(a, b, "E_EQUAL_VALUES");
        eq("READY", shared.bootstrap(f, f).status, "E_BOOTSTRAP_UNCHANGED");
    }

    private static void testConcurrentManager() throws Exception {
        MonsterManager manager = new MonsterManager();
        ExecutorService pool = Executors.newFixedThreadPool(3);
        try {
            BigInteger f = MonsterArithmetic.FOUNDATION_DAY;
            List<Callable<MonsterCutletCalendar.CutletDate>> calls = new ArrayList<>();
            for (int i = 0; i < 6; i++) {
                int delta = i - 3;
                calls.add(() -> manager.cutletDate(f, f.add(BigInteger.valueOf(delta))));
            }
            List<Future<MonsterCutletCalendar.CutletDate>> futures = pool.invokeAll(calls);
            for (int i = 0; i < futures.size(); i++) {
                MonsterCutletCalendar.CutletDate expected =
                    manager.cutletDate(f, f.add(BigInteger.valueOf(i - 3)));
                eq(expected, futures.get(i).get(), "E_CONCURRENT_EQUAL");
            }
        } finally {
            pool.shutdownNow();
        }
    }

    private static void testErrors() {
        BigInteger f = MonsterArithmetic.FOUNDATION_DAY;
        fails("E_NULL_DAY", () -> MonsterCutletCalendar.convert(null, f));
        fails("E_NULL_DAY", () -> MonsterCutletCalendar.convert(f, null));
        fails("E_NULL_DAY", () -> new MonsterManager().cutletDate(null, f));
    }

    private static void fails(String code, Runnable action) {
        checks++;
        try { action.run(); }
        catch (IllegalArgumentException e) {
            if (code.equals(e.getMessage())) return;
            throw new AssertionError("E_WRONG_ERROR expected=" + code + " actual=" + e.getMessage(), e);
        }
        throw new AssertionError("E_EXPECTED_ERROR " + code);
    }
    private static void eq(Object expected, Object actual, String code) {
        checks++;
        if (!expected.equals(actual)) throw new AssertionError(code + " expected=" + expected + " actual=" + actual);
    }
    private static void ok(boolean condition, String code) {
        checks++;
        if (!condition) throw new AssertionError(code);
    }
}
