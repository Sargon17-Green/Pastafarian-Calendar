package org.pastafari.javalojban;

import java.math.BigInteger;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.concurrent.Callable;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;

public final class Stage02CalendarResolverTests {
    private static int checks;

    public static void main(String[] args) throws Exception {
        testFullYearPositionMapping();
        testProvidedWeavingVariation();
        testManagerLevelCutletParity();
        testConcurrentResolution();
        testValidation();
        System.out.println("STAGE_02_CALENDAR_RESOLVER_PASS checks=" + checks);
    }

    private static MonsterYearBlueprint blueprint(BigInteger calculationDay) {
        return MonsterYearBlueprint.build(calculationDay,
            new MonsterYears().year5000(calculationDay));
    }

    private static int[] sequential(int[] lengths) {
        int[] weaving = new int[Arrays.stream(lengths).sum()];
        int cursor = 0;
        for (int month = 0; month < lengths.length; month++) {
            for (int j = 0; j < lengths[month]; j++) weaving[cursor++] = month + 1;
        }
        return weaving;
    }

    private static void testFullYearPositionMapping() {
        BigInteger calculation = MonsterArithmetic.FOUNDATION_DAY;
        MonsterYearBlueprint plan = blueprint(calculation);
        MonsterCalendarResolver.ResolvedYear result =
            MonsterCalendarResolver.fromBlueprint(plan, sequential(plan.monthLengths()));
        eq(plan.year().length().intValueExact(), result.length(), "E_LENGTH");
        eq(plan.year().number(), result.yearNumber(), "E_YEAR");
        int[] lengths = plan.monthLengths();
        int[] names = plan.monthNameIndices();
        int cumulative = 0;
        int month = 0;
        for (int day = 0; day < result.length(); day++) {
            while (day >= cumulative + lengths[month]) {
                cumulative += lengths[month++];
            }
            BigInteger target = result.openGateDay().add(BigInteger.valueOf(day + 1L));
            MonsterCalendarResolver.CalendarDate date = result.atDay(target);
            eq(plan.year().number(), date.yearNumber(), "E_YEAR_OF_DAY");
            eq(month + 1, date.monthOrdinal(), "E_MONTH_ORDINAL");
            eq(names[month], date.canonicalMonthIndex(), "E_MONTH_CANONICAL");
            eq(SourceLanguageCatalog.monthName(names[month]), date.monthName(), "E_MONTH_NAME");
            eq(day - cumulative + 1, date.dayInMonth(), "E_MONTH_DAY");
            MonsterYearBlueprint.Cutlet cutlet = plan.cutletAt(target);
            eq(cutlet.canonicalNameIndex(), date.canonicalCutletIndex(), "E_CUTLET_CANONICAL");
            eq(target.subtract(cutlet.firstDay()).add(BigInteger.ONE),
                date.dayInCutlet(), "E_CUTLET_DAY");
            eq(SourceLanguageCatalog.cutletName(cutlet.canonicalNameIndex()),
                date.cutletName(), "E_CUTLET_NAME");
        }
    }

    private static void testProvidedWeavingVariation() {
        BigInteger f = MonsterArithmetic.FOUNDATION_DAY;
        MonsterYearBlueprint blueprint = blueprint(f);
        int[] regular = sequential(blueprint.monthLengths());
        int[] alternative = regular.clone();
        int border = blueprint.monthLengths()[0] - 1;
        alternative[border] = 2;
        alternative[border + 1] = 1;
        MonsterCalendarResolver.ResolvedYear a =
            MonsterCalendarResolver.fromBlueprint(blueprint, regular);
        MonsterCalendarResolver.ResolvedYear b =
            MonsterCalendarResolver.fromBlueprint(blueprint, alternative);
        BigInteger beforeBorder = blueprint.year().openGateDay()
            .add(BigInteger.valueOf(border + 1L));
        eq(1, a.atDay(beforeBorder).monthOrdinal(), "E_BASELINE_ORDER");
        eq(2, b.atDay(beforeBorder).monthOrdinal(), "E_ALTERNATE_ORDER");
        eq(1, b.atDay(beforeBorder.add(BigInteger.ONE)).monthOrdinal(),
            "E_ALTERNATE_RETURN");
        eq(a.atDay(blueprint.year().closeGateDay()).yearNumber(),
            b.atDay(blueprint.year().closeGateDay()).yearNumber(), "E_YEAR_STABLE");
        alternative[border] = 0;
        eq(2, b.atDay(beforeBorder).monthOrdinal(), "E_COPY_INPUT");
    }

    private static void testManagerLevelCutletParity() {
        BigInteger f = MonsterArithmetic.FOUNDATION_DAY;
        MonsterYearBlueprint plan = blueprint(f);
        MonsterCalendarResolver.ResolvedYear resolved = MonsterCalendarResolver.forTarget(
            f, f, sequential(plan.monthLengths()));
        for (BigInteger target : List.of(f, plan.year().openGateDay().add(BigInteger.ONE),
                plan.year().closeGateDay())) {
            MonsterCalendarResolver.CalendarDate date = resolved.atDay(target);
            MonsterCutletCalendar.CutletDate cutlet =
                MonsterCutletCalendar.convert(f, target);
            eq(cutlet.yearNumber(), date.yearNumber(), "E_MANAGER_YEAR");
            eq(cutlet.canonicalCutletIndex(), date.canonicalCutletIndex(),
                "E_MANAGER_CUTLET_INDEX");
            eq(cutlet.dayInCutlet(), date.dayInCutlet(), "E_MANAGER_DAY");
            eq(cutlet.cutletName(), date.cutletName(), "E_MANAGER_CUTLET_NAME");
        }
    }

    private static void testConcurrentResolution() throws Exception {
        BigInteger f = MonsterArithmetic.FOUNDATION_DAY;
        MonsterYearBlueprint plan = blueprint(f);
        MonsterCalendarResolver.ResolvedYear shared =
            MonsterCalendarResolver.fromBlueprint(plan, sequential(plan.monthLengths()));
        ExecutorService pool = Executors.newFixedThreadPool(4);
        try {
            List<Callable<MonsterCalendarResolver.CalendarDate>> calls = new ArrayList<>();
            for (int i = 0; i < 20; i++) {
                int offset = (i * 67) % shared.length();
                calls.add(() -> shared.atDay(shared.openGateDay()
                    .add(BigInteger.valueOf(offset + 1L))));
            }
            List<Future<MonsterCalendarResolver.CalendarDate>> outcomes =
                pool.invokeAll(calls);
            for (int i = 0; i < outcomes.size(); i++) {
                int offset = (i * 67) % shared.length();
                eq(shared.atDay(shared.openGateDay().add(BigInteger.valueOf(offset + 1L))),
                    outcomes.get(i).get(), "E_PARALLEL");
            }
        } finally {
            pool.shutdownNow();
        }
    }

    private static void testValidation() {
        BigInteger f = MonsterArithmetic.FOUNDATION_DAY;
        MonsterYearBlueprint blueprint = blueprint(f);
        int[] good = sequential(blueprint.monthLengths());
        MonsterCalendarResolver.ResolvedYear resolved =
            MonsterCalendarResolver.fromBlueprint(blueprint, good);
        fails("E_NULL_BLUEPRINT", () -> MonsterCalendarResolver.fromBlueprint(null, good));
        fails("E_MONTH_NULL", () -> MonsterCalendarResolver.fromBlueprint(blueprint, null));
        fails("E_NULL_DAY", () -> resolved.atDay(null));
        fails("E_DAY_OUTSIDE_YEAR", () -> resolved.atDay(blueprint.year().openGateDay()));
        fails("E_DAY_OUTSIDE_YEAR", () -> resolved.atDay(
            blueprint.year().closeGateDay().add(BigInteger.ONE)));
        fails("E_NULL_DAY", () -> MonsterCalendarResolver.forTarget(null, f, good));
    }

    private static void fails(String code, Runnable action) {
        checks++;
        try { action.run(); }
        catch (IllegalArgumentException e) {
            if (code.equals(e.getMessage())) return;
            throw new AssertionError("E_WRONG_ERROR " + code + " actual=" + e.getMessage(), e);
        }
        throw new AssertionError("E_EXPECTED_ERROR " + code);
    }

    private static void eq(Object expected, Object actual, String code) {
        checks++;
        if (!expected.equals(actual)) {
            throw new AssertionError(code + " expected=" + expected + " actual=" + actual);
        }
    }
}
