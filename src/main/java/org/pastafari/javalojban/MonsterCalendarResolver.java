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
