package org.pastafari.javalojban;

import java.math.BigInteger;
import java.util.Arrays;
import java.util.HashSet;
import java.util.Set;

public final class MonsterMonthIndex {
    public record MonthDate(int positionInYear, int monthOrdinal,
                            int canonicalMonthIndex, String monthName,
                            int dayInMonth) {}

    private final int[] monthByPosition;
    private final int[] dayInMonthByPosition;
    private final int[] nameIndices;
    private final int[] monthLengths;

    public MonsterMonthIndex(int[] monthLengths, int[] monthNames, int[] weaving) {
        if (monthLengths == null || monthNames == null || weaving == null) {
            throw new IllegalArgumentException("E_MONTH_NULL");
        }
        int count = monthLengths.length;
        if (count < 3 || count > 47 || monthNames.length != count) {
            throw new IllegalArgumentException("E_MONTH_COUNT");
        }
        this.monthLengths = monthLengths.clone();
        this.nameIndices = monthNames.clone();
        Set<Integer> uniqueNames = new HashSet<>();
        long duration = 0;
        for (int i = 0; i < count; i++) {
            if (monthLengths[i] < 4 || monthLengths[i] > 123) {
                throw new IllegalArgumentException("E_MONTH_LENGTH");
            }
            if (monthNames[i] < 1 || monthNames[i] > 47
                    || !uniqueNames.add(monthNames[i])) {
                throw new IllegalArgumentException("E_MONTH_NAME");
            }
            duration += monthLengths[i];
        }
        if (duration != weaving.length || duration < 252 || duration > 5778) {
            throw new IllegalArgumentException("E_WEAVE_DURATION");
        }
        monthByPosition = weaving.clone();
        dayInMonthByPosition = new int[weaving.length];
        int[] tallies = new int[count];
        int[] starts = new int[count];
        int[] ends = new int[count];
        Arrays.fill(starts, -1);
        for (int position = 0; position < weaving.length; position++) {
            int month = weaving[position] - 1;
            if (month < 0 || month >= count) {
                throw new IllegalArgumentException("E_WEAVE_MONTH");
            }
            if (starts[month] < 0) starts[month] = position;
            ends[month] = position;
            tallies[month]++;
            if (tallies[month] > monthLengths[month]) {
                throw new IllegalArgumentException("E_WEAVE_MULTIPLICITY");
            }
            dayInMonthByPosition[position] = tallies[month];
        }
        if (!Arrays.equals(tallies, monthLengths)) {
            throw new IllegalArgumentException("E_WEAVE_MULTIPLICITY");
        }
        for (int i = 1; i < count; i++) {
            if (starts[i - 1] >= starts[i] || ends[i - 1] >= ends[i]) {
                throw new IllegalArgumentException("E_WEAVE_ORDER");
            }
        }
    }

    public static MonsterMonthIndex fromBlueprint(MonsterYearBlueprint blueprint,
                                                   int[] weaving) {
        if (blueprint == null) {
            throw new IllegalArgumentException("E_NULL_BLUEPRINT");
        }
        return new MonsterMonthIndex(blueprint.monthLengths(),
                                     blueprint.monthNameIndices(), weaving);
    }

    public int length() {
        return monthByPosition.length;
    }

    public int[] weavingCopy() {
        return monthByPosition.clone();
    }

    public MonthDate atOffset(int yearOffsetZeroBased) {
        if (yearOffsetZeroBased < 0 || yearOffsetZeroBased >= monthByPosition.length) {
            throw new IllegalArgumentException("E_YEAR_OFFSET");
        }
        int ordinal = monthByPosition[yearOffsetZeroBased];
        int canonical = nameIndices[ordinal - 1];
        return new MonthDate(yearOffsetZeroBased + 1, ordinal, canonical,
                             SourceLanguageCatalog.monthName(canonical),
                             dayInMonthByPosition[yearOffsetZeroBased]);
    }

    public MonthDate atDay(BigInteger openingGateDay, BigInteger targetDay) {
        if (openingGateDay == null || targetDay == null) {
            throw new IllegalArgumentException("E_NULL_DAY");
        }
        BigInteger offset = targetDay.subtract(openingGateDay).subtract(BigInteger.ONE);
        if (offset.signum() < 0 || offset.compareTo(BigInteger.valueOf(length())) >= 0) {
            throw new IllegalArgumentException("E_YEAR_OFFSET");
        }
        return atOffset(offset.intValueExact());
    }
}
