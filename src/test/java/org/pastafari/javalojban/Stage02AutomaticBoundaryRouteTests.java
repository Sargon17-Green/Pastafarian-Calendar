package org.pastafari.javalojban;

import java.math.BigInteger;
import java.util.Arrays;
import java.util.List;

public final class Stage02AutomaticBoundaryRouteTests {
    private static int checks;

    public static void main(String[] args) {
        testFullYearIntervals();
        testActualYearManager();
        testGuardrails();
        System.out.println("STAGE_02_AUTOMATIC_BOUNDARY_ROUTE_PASS checks=" + checks
            + " days=5778 heap_mb=" + Runtime.getRuntime().maxMemory() / 1048576);
    }

    private static void testFullYearIntervals() {
        int[] lengths = new int[47];
        Arrays.fill(lengths, 123);
        lengths[46] = 120;
        MonsterWeavingLinearCounter family = new MonsterWeavingLinearCounter(lengths);
        for (boolean latest : new boolean[]{false, true}) {
            MonsterWeavingLinearCounter.BoundaryBlock block =
                family.boundaryBlock(latest, 512);
            for (BigInteger rank : List.of(block.lowerRank(),
                    block.lowerRank().add(block.upperRank()).divide(BigInteger.TWO),
                    block.upperRank())) {
                MonsterWeavingLinearCounter.RankRoute route =
                    family.beginGlobalRankRoute(rank, 512);
                ok(route.complete(), "E_EDGE_ROUTE_READY");
                eq(rank, route.globalRank(), "E_RANK");
                eq(block.lowerRank(), route.lowerRank(), "E_LOW");
                eq(block.upperRank(), route.upperRank(), "E_HIGH");
                eq(512, route.remainingDays(), "E_SUFFIX");
                array(block.fixedPrefixCopy(), route.fixedPrefixCopy(), "E_PREFIX");
                int[] actual = family.finishGlobalRankRoute(route);
                array(family.unrank1(rank), actual, "E_AUTOMATIC_UNRANK");
                eq(rank, family.rank1(actual), "E_INVERSE_RANK");
            }
        }
    }

    private static void testActualYearManager() {
        BigInteger f = MonsterArithmetic.FOUNDATION_DAY;
        MonsterYears.Year year = new MonsterYears().year5000(f);
        MonsterYearBlueprint blueprint = MonsterYearBlueprint.build(f, year);
        MonsterWeavingLinearCounter family =
            new MonsterWeavingLinearCounter(blueprint.monthLengths());
        int days = year.length().intValueExact();
        ok(days > 512, "E_REAL_YEAR_LENGTH");
        for (boolean latest : new boolean[]{false, true}) {
            MonsterWeavingLinearCounter.BoundaryBlock block =
                family.boundaryBlock(latest, 512);
            BigInteger rank = block.lowerRank().add(block.upperRank())
                .divide(BigInteger.TWO);
            MonsterCalendarResolver.GlobalPrefixRankedYear current =
                MonsterCalendarResolver.forTargetWithAutomaticBoundaryRank(f, f, rank);
            eq(rank, current.globalRank(), "E_CURRENT_RANK");
            eq(block.lowerRank(), current.blockFirstRank(), "E_CURRENT_FIRST");
            eq(block.upperRank(), current.blockLastRank(), "E_CURRENT_LAST");
            for (BigInteger target : List.of(
                    year.openGateDay().add(BigInteger.ONE),
                    f, year.closeGateDay())) {
                MonsterCalendarResolver.GlobalPrefixRankedYear managed =
                    new MonsterManager().calendarWithAutomaticBoundaryRank(f, target, rank);
                eq(current.atDay(target), managed.atDay(target), "E_MANAGER_DATE");
                eq(rank, managed.globalRank(), "E_MANAGER_RANK");
                MonsterYearBlueprint.Cutlet cutlet = blueprint.cutletAt(target);
                eq(cutlet.canonicalNameIndex(),
                    managed.atDay(target).canonicalCutletIndex(), "E_CUTLET_NAME");
                eq(target.subtract(cutlet.firstDay()).add(BigInteger.ONE),
                    managed.atDay(target).dayInCutlet(), "E_CUTLET_OFFSET");
            }
        }
    }

    private static void testGuardrails() {
        BigInteger f = MonsterArithmetic.FOUNDATION_DAY;
        MonsterYearBlueprint blueprint = MonsterYearBlueprint.build(f,
            new MonsterYears().year5000(f));
        MonsterWeavingLinearCounter family =
            new MonsterWeavingLinearCounter(blueprint.monthLengths());
        BigInteger middle = family.count().add(BigInteger.ONE).divide(BigInteger.TWO);
        MonsterWeavingLinearCounter.RankRoute pending =
            family.beginGlobalRankRoute(middle, 512);
        ok(!pending.complete(), "E_MIDDLE_PENDING");
        eq(0, pending.stepsCompleted(), "E_MIDDLE_UNRESOLVED");
        fails("E_WEAVE_ROUTE_INCOMPLETE", () ->
            MonsterCalendarResolver.forTargetWithAutomaticBoundaryRank(f, f, middle));
        fails("E_WEAVE_RANK", () ->
            MonsterCalendarResolver.forTargetWithAutomaticBoundaryRank(
                f, f, BigInteger.ZERO));
        fails("E_NULL_DAY", () ->
            new MonsterManager().calendarWithAutomaticBoundaryRank(
                f, null, BigInteger.ONE));
        MonsterWeavingLinearCounter.BoundaryBlock first =
            family.boundaryBlock(false, 512);
        MonsterWeavingLinearCounter.RankRoute ready =
            family.beginGlobalRankRoute(first.upperRank(), 512);
        int[] altered = ready.fixedPrefixCopy();
        altered[0] = 0;
        array(first.fixedPrefixCopy(), ready.fixedPrefixCopy(), "E_DEFENSIVE_COPY");
        MonsterWeavingLinearCounter different =
            new MonsterWeavingLinearCounter(blueprint.monthLengths());
        fails("E_WEAVE_ROUTE_OWNER", () -> different.finishGlobalRankRoute(ready));
        ok(!family.beginGlobalRankRoute(middle, 0).complete(),
            "E_ZERO_SUFFIX_NO_SHORTCUT");
    }

    private static void eq(Object wanted, Object got, String code) {
        checks++;
        if (!wanted.equals(got)) throw new AssertionError(code + ": " + wanted + " != " + got);
    }
    private static void array(int[] wanted, int[] got, String code) {
        checks++;
        if (!Arrays.equals(wanted, got)) throw new AssertionError(code);
    }
    private static void ok(boolean pass, String code) {
        checks++;
        if (!pass) throw new AssertionError(code);
    }
    private static void fails(String code, Runnable action) {
        checks++;
        try {
            action.run();
        } catch (IllegalArgumentException error) {
            if (code.equals(error.getMessage())) return;
            throw new AssertionError("E_ERROR " + error.getMessage(), error);
        }
        throw new AssertionError("E_MISSING_ERROR " + code);
    }
}
