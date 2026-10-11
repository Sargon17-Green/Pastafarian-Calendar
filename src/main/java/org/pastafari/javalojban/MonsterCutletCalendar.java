package org.pastafari.javalojban;

import java.math.BigInteger;

public final class MonsterCutletCalendar {
    public record CutletDate(BigInteger yearNumber, int canonicalCutletIndex,
            String cutletName, BigInteger dayInCutlet, BigInteger firstDay,
            BigInteger lastDay, BigInteger yearOpenDay, BigInteger yearCloseDay) {}

    private MonsterCutletCalendar() {}

    public static CutletDate convert(BigInteger calculationDay, BigInteger targetDay) {
        if (calculationDay == null || targetDay == null) {
            throw new IllegalArgumentException("E_NULL_DAY");
        }
        MonsterYears years = new MonsterYears();
        MonsterYears.Year year = years.findTargetYear(calculationDay, targetDay);
        MonsterYearBlueprint blueprint = MonsterYearBlueprint.build(calculationDay, year);
        MonsterYearBlueprint.Cutlet cutlet = blueprint.cutletAt(targetDay);
        BigInteger position = targetDay.subtract(cutlet.firstDay()).add(BigInteger.ONE);
        if (position.signum() <= 0 || position.compareTo(
                cutlet.lastDay().subtract(cutlet.firstDay()).add(BigInteger.ONE)) > 0) {
            throw new IllegalStateException("E_CUTLET_DATE_POSITION");
        }
        int canonical = cutlet.canonicalNameIndex();
        return new CutletDate(year.number(), canonical,
            SourceLanguageCatalog.cutletName(canonical), position,
            cutlet.firstDay(), cutlet.lastDay(),
            year.openGateDay(), year.closeGateDay());
    }
}
