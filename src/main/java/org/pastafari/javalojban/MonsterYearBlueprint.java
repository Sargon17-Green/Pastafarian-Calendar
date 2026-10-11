package org.pastafari.javalojban;

import java.math.BigInteger;
import java.util.ArrayList;
import java.util.List;

public final class MonsterYearBlueprint {
    private static final BigInteger ONE = BigInteger.ONE;
    private final MonsterYears.Year year;
    private final int[] cutletPartition;
    private final int[] cutletNames;
    private final List<Cutlet> cutlets;
    private final int[] monthLengths;
    private final int[] monthNames;

    public record Cutlet(int canonicalNameIndex, BigInteger openGateIndex,
            BigInteger closeGateIndex, BigInteger firstDay, BigInteger lastDay) {}

    private MonsterYearBlueprint(MonsterYears.Year year, int[] cutletPartition,
            int[] cutletNames, List<Cutlet> cutlets, int[] monthLengths, int[] monthNames) {
        this.year = year;
        this.cutletPartition = cutletPartition.clone();
        this.cutletNames = cutletNames.clone();
        this.cutlets = List.copyOf(cutlets);
        this.monthLengths = monthLengths.clone();
        this.monthNames = monthNames.clone();
    }

    public static MonsterYearBlueprint build(BigInteger calculationDay, MonsterYears.Year year) {
        if (calculationDay == null) throw new IllegalArgumentException("E_NULL_DAY");
        if (year == null || year.openGateIndex() == null || year.closeGateIndex() == null
                || year.openGateDay() == null || year.closeGateDay() == null
                || year.number() == null) {
            throw new IllegalArgumentException("E_YEAR_NULL");
        }
        MonsterGates gates = new MonsterGates();
        BigInteger gapCount = year.closeGateIndex().subtract(year.openGateIndex());
        BigInteger duration = year.closeGateDay().subtract(year.openGateDay());
        if (gapCount.compareTo(BigInteger.valueOf(6)) < 0
                || duration.compareTo(BigInteger.valueOf(252)) < 0
                || duration.compareTo(BigInteger.valueOf(5778)) > 0
                || !gates.gateAt(year.openGateIndex()).equals(year.openGateDay())
                || !gates.gateAt(year.closeGateIndex()).equals(year.closeGateDay())) {
            throw new IllegalArgumentException("E_YEAR_GATE");
        }
        int gaps = gapCount.intValueExact();
        int length = duration.intValueExact();
        BigInteger firstDay = year.openGateDay().add(ONE);
        MonsterSauceBowls.SauceResult sauce = MonsterSauceBowls.evaluate(calculationDay, firstDay);

        int maxCutlets = Math.min(17, gaps);
        int numberOfCutlets = 6 + MonsterSelectors.choose(
            MonsterSauceBowls.ask(sauce, 2, 20), BigInteger.valueOf(maxCutlets - 5L)
        ).intValueExact() - 1;

        Integer required = null;
        BigInteger exact = gates.exactGate(calculationDay);
        if (exact != null && exact.compareTo(year.openGateIndex()) > 0
                && exact.compareTo(year.closeGateIndex()) < 0) {
            required = exact.subtract(year.openGateIndex()).intValueExact();
        }
        MonsterFamilies.CutletPartitionFamily cuts =
            new MonsterFamilies.CutletPartitionFamily(gaps, numberOfCutlets, required);
        int[] partitions = cuts.unrank1(MonsterSelectors.choose(
            MonsterSauceBowls.ask(sauce, 2, 21), cuts.count()));
        BigInteger nameSpace = MonsterFamilies.fallingFactorial(17, numberOfCutlets);
        int[] names = MonsterFamilies.unrankDistinctIndices(17, numberOfCutlets,
            MonsterSelectors.choose(MonsterSauceBowls.ask(sauce, 5, 22), nameSpace));

        List<Cutlet> intervals = new ArrayList<>();
        BigInteger cursor = year.openGateIndex();
        for (int k = 0; k < partitions.length; k++) {
            BigInteger next = cursor.add(BigInteger.valueOf(partitions[k]));
            intervals.add(new Cutlet(names[k], cursor, next,
                gates.gateAt(cursor).add(ONE), gates.gateAt(next)));
            cursor = next;
        }
        if (!cursor.equals(year.closeGateIndex())) {
            throw new IllegalStateException("E_CUTLET_COVERAGE");
        }

        int minMonths = (length + 122) / 123;
        int maxMonths = Math.min(47, length / 4);
        if (minMonths < 3 || minMonths > maxMonths) {
            throw new IllegalStateException("E_MONTH_BOUNDS");
        }
        int numberOfMonths = minMonths + MonsterSelectors.choose(
            MonsterSauceBowls.ask(sauce, 3, 30),
            BigInteger.valueOf(maxMonths - minMonths + 1L)).intValueExact() - 1;
        MonsterFamilies.BoundedCompositionFamily months =
            new MonsterFamilies.BoundedCompositionFamily(length, numberOfMonths, 4, 123);
        int[] lengths = months.unrank1(MonsterSelectors.choose(
            MonsterSauceBowls.ask(sauce, 3, 31), months.count()));
        BigInteger monthNameSpace = MonsterFamilies.fallingFactorial(47, numberOfMonths);
        int[] monthIndices = MonsterFamilies.unrankDistinctIndices(47, numberOfMonths,
            MonsterSelectors.choose(MonsterSauceBowls.ask(sauce, 5, 33), monthNameSpace));
        return new MonsterYearBlueprint(year, partitions, names, intervals, lengths, monthIndices);
    }

    public MonsterYears.Year year() { return year; }
    public int cutletCount() { return cutletPartition.length; }
    public int[] cutletPartition() { return cutletPartition.clone(); }
    public int[] cutletNameIndices() { return cutletNames.clone(); }
    public List<Cutlet> cutlets() { return cutlets; }
    public int monthCount() { return monthLengths.length; }
    public int[] monthLengths() { return monthLengths.clone(); }
    public int[] monthNameIndices() { return monthNames.clone(); }

    public Cutlet cutletAt(BigInteger day) {
        if (day == null) throw new IllegalArgumentException("E_NULL_DAY");
        for (Cutlet cutlet : cutlets) {
            if (cutlet.firstDay().compareTo(day) <= 0
                    && day.compareTo(cutlet.lastDay()) <= 0) {
                return cutlet;
            }
        }
        throw new IllegalArgumentException("E_DAY_OUTSIDE_YEAR");
    }
}
