package org.pastafari.javalojban;

import java.math.BigInteger;
import java.util.Arrays;
import java.util.List;

public final class Stage02FullRouteCompletionTests {
    private static int checks;

    private Stage02FullRouteCompletionTests() {}

    public static void main(String[] args) {
        completeMaximalYear();
        completeRealYearCalendar();
        System.out.println("STAGE_02_FULL_ROUTE_COMPLETION_PASS checks=" + checks
            + " max_days=5778 step_cap=512 count_cap=1"
            + " heap_mb=" + Runtime.getRuntime().maxMemory() / 1048576);
    }

    private static MonsterWeavingLinearCounter.RankRoute finishInChunks(
            MonsterWeavingLinearCounter family, BigInteger rank) {
        MonsterWeavingLinearCounter.RankRoute route =
            family.beginGlobalRankRoute(rank, 0);
        eq(0, route.stepsCompleted(), "E_EMPTY_INITIAL_PREFIX");
        int rounds = 0;
        while (!route.complete()) {
            MonsterWeavingLinearCounter.RankRoute old = route;
            route = family.advanceGlobalRankRoute(old, 512, 1);
            ok(route.stepsCompleted() > old.stepsCompleted(),
                "E_PROGRESS_EACH_CHUNK");
            ok(route.stepsCompleted() - old.stepsCompleted() <= 512,
                "E_BOUNDED_STEPS");
            eq(1, route.lastCountCalls(), "E_ONE_SUFFIX_COUNT_PER_CHUNK");
            eq(rank, route.globalRank(), "E_PRESERVED_GLOBAL_RANK");
            ok(route.lowerRank().compareTo(rank) <= 0,
                "E_INTERVAL_START");
            ok(rank.compareTo(route.upperRank()) <= 0,
                "E_INTERVAL_END");
            rounds++;
            ok(rounds <= 15, "E_FULL_YEAR_CHUNK_BOUND");
        }
        ok(rounds > 1, "E_MULTIPLE_CHUNKS");
        eq(0, route.remainingDays(), "E_NO_REMAINING_DAYS");
        eq(rank, route.lowerRank(), "E_SINGLETON_LOWER");
        eq(rank, route.upperRank(), "E_SINGLETON_UPPER");
        return route;
    }

    private static void completeMaximalYear() {
        int[] lengths = new int[47];
        Arrays.fill(lengths, 123);
        lengths[46] = 120;
        MonsterWeavingLinearCounter family =
            new MonsterWeavingLinearCounter(lengths);
        BigInteger total = family.count();
        for (BigInteger rank : List.of(BigInteger.valueOf(5),
                total.subtract(BigInteger.valueOf(4)))) {
            MonsterWeavingLinearCounter.RankRoute completed =
                finishInChunks(family, rank);
            int[] actual = family.finishGlobalRankRoute(completed);
            eq(5778, actual.length, "E_MAX_YEAR_DURATION");
            array(family.unrank1(rank), actual, "E_NO_PREFIX_UNRANK");
            eq(rank, family.rank1(actual), "E_EXACT_GLOBAL_RANK");
            int[] counts = new int[lengths.length];
            for (int ordinal : actual) counts[ordinal - 1]++;
            array(lengths, counts, "E_MAX_MULTIPLICITIES");
            int[] exposed = completed.fixedPrefixCopy();
            exposed[0] = 0;
            array(actual, completed.fixedPrefixCopy(), "E_TERMINAL_OWNERSHIP");
        }
    }

    private static void completeRealYearCalendar() {
        BigInteger calculation = MonsterArithmetic.FOUNDATION_DAY;
        MonsterYears.Year year = new MonsterYears().year5000(calculation);
        MonsterYearBlueprint plan =
            MonsterYearBlueprint.build(calculation, year);
        MonsterWeavingLinearCounter family =
            new MonsterWeavingLinearCounter(plan.monthLengths());
        ok(year.length().intValueExact() > 512, "E_ANCHOR_YEAR_LONG");
        BigInteger globalRank = BigInteger.valueOf(5);
        MonsterWeavingLinearCounter.RankRoute route =
            finishInChunks(family, globalRank);
        int[] selected = family.finishGlobalRankRoute(route);
        MonsterCalendarResolver.GlobalPrefixRankedYear fromRoute =
            MonsterCalendarResolver.fromBlueprintWithCompletedGlobalRoute(
                plan, family, route);
        MonsterCalendarResolver.ResolvedYear independently =
            MonsterCalendarResolver.fromBlueprint(plan, family.unrank1(globalRank));
        eq(globalRank, fromRoute.globalRank(), "E_REAL_YEAR_GLOBAL_RANK");
        array(selected, fromRoute.weavingCopy(), "E_REAL_YEAR_WEAVING");
        int length = year.length().intValueExact();
        for (int offset : new int[]{0, 1, length / 2, length - 2, length - 1}) {
            BigInteger date = year.openGateDay().add(BigInteger.valueOf(offset + 1L));
            eq(independently.atDay(date), fromRoute.atDay(date),
                "E_INDEPENDENT_CALENDAR_DATE");
            MonsterYearBlueprint.Cutlet cutlet = plan.cutletAt(date);
            eq(cutlet.canonicalNameIndex(),
                fromRoute.atDay(date).canonicalCutletIndex(),
                "E_REAL_CUTLET_NAME");
        }
    }

    private static void eq(Object wanted, Object actual, String code) {
        checks++;
        if (!wanted.equals(actual)) {
            throw new AssertionError(code + " wanted=" + wanted + " actual=" + actual);
        }
    }

    private static void array(int[] wanted, int[] actual, String code) {
        checks++;
        if (!Arrays.equals(wanted, actual)) throw new AssertionError(code);
    }

    private static void ok(boolean result, String code) {
        checks++;
        if (!result) throw new AssertionError(code);
    }
}
