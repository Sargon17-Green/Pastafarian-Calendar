package org.pastafari.javalojban;

import java.math.BigInteger;

public final class MonsterCalendarResolver {
    public record CalendarDate(BigInteger yearNumber, int canonicalCutletIndex,
                               String cutletName, BigInteger dayInCutlet,
                               int monthOrdinal, int canonicalMonthIndex,
                               String monthName, int dayInMonth) {}

    public static final class ResolvedYear {
        private final MonsterYearBlueprint blueprint;
        private final MonsterMonthIndex monthIndex;

        private ResolvedYear(MonsterYearBlueprint blueprint, MonsterMonthIndex monthIndex) {
            this.blueprint = blueprint;
            this.monthIndex = monthIndex;
        }

        public BigInteger yearNumber() {
            return blueprint.year().number();
        }

        public BigInteger openGateDay() {
            return blueprint.year().openGateDay();
        }

        public BigInteger closeGateDay() {
            return blueprint.year().closeGateDay();
        }

        public CalendarDate atDay(BigInteger targetDay) {
            if (targetDay == null) {
                throw new IllegalArgumentException("E_NULL_DAY");
            }
            MonsterYearBlueprint.Cutlet cutlet = blueprint.cutletAt(targetDay);
            MonsterMonthIndex.MonthDate month = monthIndex.atDay(openGateDay(), targetDay);
            BigInteger dayInCutlet = targetDay.subtract(cutlet.firstDay()).add(BigInteger.ONE);
            int cutletNameIndex = cutlet.canonicalNameIndex();
            return new CalendarDate(yearNumber(), cutletNameIndex,
                SourceLanguageCatalog.cutletName(cutletNameIndex), dayInCutlet,
                month.monthOrdinal(), month.canonicalMonthIndex(),
                month.monthName(), month.dayInMonth());
        }

        public int length() {
            return monthIndex.length();
        }
    }

    public static final class PrefixRankedYear {
        private final ResolvedYear resolved;
        private final int[] fixedPrefix;
        private final BigInteger localRank;
        private final BigInteger localPossibilities;

        private PrefixRankedYear(ResolvedYear resolved, int[] fixedPrefix,
                                 BigInteger localRank, BigInteger localPossibilities) {
            this.resolved = resolved;
            this.fixedPrefix = fixedPrefix.clone();
            this.localRank = localRank;
            this.localPossibilities = localPossibilities;
        }

        public BigInteger yearNumber() { return resolved.yearNumber(); }
        public BigInteger openGateDay() { return resolved.openGateDay(); }
        public BigInteger closeGateDay() { return resolved.closeGateDay(); }
        public int length() { return resolved.length(); }
        public int[] fixedPrefixCopy() { return fixedPrefix.clone(); }
        public int[] weavingCopy() { return resolved.monthIndex.weavingCopy(); }
        public BigInteger localRank() { return localRank; }
        public BigInteger localPossibilities() { return localPossibilities; }
        public CalendarDate atDay(BigInteger targetDay) { return resolved.atDay(targetDay); }
    }


    public static final class GlobalPrefixRankedYear {
        private final ResolvedYear resolved;
        private final int[] fixedPrefix;
        private final BigInteger globalRank;
        private final BigInteger lowerRank;
        private final BigInteger upperRank;

        private GlobalPrefixRankedYear(ResolvedYear resolved, int[] fixedPrefix,
                BigInteger globalRank, BigInteger lowerRank, BigInteger upperRank) {
            this.resolved = resolved;
            this.fixedPrefix = fixedPrefix.clone();
            this.globalRank = globalRank;
            this.lowerRank = lowerRank;
            this.upperRank = upperRank;
        }

        public BigInteger yearNumber() { return resolved.yearNumber(); }
        public BigInteger openGateDay() { return resolved.openGateDay(); }
        public BigInteger closeGateDay() { return resolved.closeGateDay(); }
        public int length() { return resolved.length(); }
        public int[] fixedPrefixCopy() { return fixedPrefix.clone(); }
        public int[] weavingCopy() { return resolved.monthIndex.weavingCopy(); }
        public BigInteger globalRank() { return globalRank; }
        public BigInteger blockFirstRank() { return lowerRank; }
        public BigInteger blockLastRank() { return upperRank; }
        public CalendarDate atDay(BigInteger targetDay) { return resolved.atDay(targetDay); }
    }

    private MonsterCalendarResolver() {}

    public static ResolvedYear fromBlueprint(MonsterYearBlueprint blueprint,
                                              int[] selectedWeaving) {
        if (blueprint == null) {
            throw new IllegalArgumentException("E_NULL_BLUEPRINT");
        }
        MonsterMonthIndex index = MonsterMonthIndex.fromBlueprint(blueprint, selectedWeaving);
        if (index.length() != blueprint.year().length().intValueExact()) {
            throw new IllegalStateException("E_YEAR_WEAVING_LENGTH");
        }
        return new ResolvedYear(blueprint, index);
    }

    public static PrefixRankedYear fromBlueprintWithPrefixRank(
            MonsterYearBlueprint blueprint, int[] fixedPrefix, BigInteger localRank) {
        if (blueprint == null) throw new IllegalArgumentException("E_NULL_BLUEPRINT");
        MonsterWeavingLinearCounter family =
            new MonsterWeavingLinearCounter(blueprint.monthLengths());
        int[] selected = family.unrankAfterPrefix(fixedPrefix, localRank);
        BigInteger localPossibilities = family.countAfterPrefix(fixedPrefix);
        return new PrefixRankedYear(fromBlueprint(blueprint, selected), fixedPrefix,
            localRank, localPossibilities);
    }

    public static GlobalPrefixRankedYear fromBlueprintWithGlobalPrefixRank(
            MonsterYearBlueprint blueprint, int[] fixedPrefix, BigInteger globalRank) {
        if (blueprint == null) throw new IllegalArgumentException("E_NULL_BLUEPRINT");
        MonsterWeavingLinearCounter family =
            new MonsterWeavingLinearCounter(blueprint.monthLengths());
        MonsterWeavingLinearCounter.BoundaryBlock block =
            family.globalBlockForPrefix(fixedPrefix);
        if (!block.contains(globalRank)) {
            throw new IllegalArgumentException("E_WEAVE_GLOBAL_RANK");
        }
        int[] weaving = family.unrankAfterPrefix(fixedPrefix,
            globalRank.subtract(block.lowerRank()).add(BigInteger.ONE));
        return new GlobalPrefixRankedYear(fromBlueprint(blueprint, weaving),
            fixedPrefix, globalRank, block.lowerRank(), block.upperRank());
    }


    public static GlobalPrefixRankedYear fromBlueprintWithCompletedGlobalRoute(
            MonsterYearBlueprint blueprint, MonsterWeavingLinearCounter family,
            MonsterWeavingLinearCounter.RankRoute route) {
        if (blueprint == null) throw new IllegalArgumentException("E_NULL_BLUEPRINT");
        if (family == null) throw new IllegalArgumentException("E_NULL_WEAVING_FAMILY");
        int[] weaving = family.finishGlobalRankRoute(route);
        return new GlobalPrefixRankedYear(fromBlueprint(blueprint, weaving),
            route.fixedPrefixCopy(), route.globalRank(),
            route.lowerRank(), route.upperRank());
    }

    public static GlobalPrefixRankedYear forTargetWithAutomaticBoundaryRank(
            BigInteger calculationDay, BigInteger targetDay, BigInteger globalRank) {
        if (calculationDay == null || targetDay == null) {
            throw new IllegalArgumentException("E_NULL_DAY");
        }
        MonsterYears.Year year = new MonsterYears().findTargetYear(
            calculationDay, targetDay);
        MonsterYearBlueprint blueprint = MonsterYearBlueprint.build(calculationDay, year);
        MonsterWeavingLinearCounter family =
            new MonsterWeavingLinearCounter(blueprint.monthLengths());
        MonsterWeavingLinearCounter.RankRoute route =
            family.beginGlobalRankRoute(globalRank,
                Math.min(MonsterWeavingLinearCounter.MAX_UNRANK_DAYS,
                    blueprint.year().length().intValueExact()));
        return fromBlueprintWithCompletedGlobalRoute(blueprint, family, route);
    }

    public static GlobalPrefixRankedYear forTargetWithGlobalPrefixRank(
            BigInteger calculationDay, BigInteger targetDay,
            int[] fixedPrefix, BigInteger globalRank) {
        if (calculationDay == null || targetDay == null) {
            throw new IllegalArgumentException("E_NULL_DAY");
        }
        MonsterYears.Year year = new MonsterYears().findTargetYear(calculationDay, targetDay);
        return fromBlueprintWithGlobalPrefixRank(
            MonsterYearBlueprint.build(calculationDay, year), fixedPrefix, globalRank);
    }

    public static PrefixRankedYear forTargetWithPrefixRank(
            BigInteger calculationDay, BigInteger targetDay,
            int[] fixedPrefix, BigInteger localRank) {
        if (calculationDay == null || targetDay == null) {
            throw new IllegalArgumentException("E_NULL_DAY");
        }
        MonsterYears years = new MonsterYears();
        MonsterYears.Year year = years.findTargetYear(calculationDay, targetDay);
        return fromBlueprintWithPrefixRank(
            MonsterYearBlueprint.build(calculationDay, year), fixedPrefix, localRank);
    }

    public static ResolvedYear forTarget(BigInteger calculationDay,
                                         BigInteger targetDay,
                                         int[] selectedWeaving) {
        if (calculationDay == null || targetDay == null) {
            throw new IllegalArgumentException("E_NULL_DAY");
        }
        MonsterYears years = new MonsterYears();
        MonsterYears.Year year = years.findTargetYear(calculationDay, targetDay);
        return fromBlueprint(MonsterYearBlueprint.build(calculationDay, year), selectedWeaving);
    }
}
