package org.pastafari.javalojban;

import java.math.BigInteger;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Map;

public final class MonsterYears {
    public static final int MAX_YEAR_DAYS = 5778;
    public static final int MIN_YEAR_DAYS = 252;
    private static final BigInteger ONE = BigInteger.ONE;
    private static final BigInteger SIX = BigInteger.valueOf(6);
    private static final BigInteger MAX_LENGTH = BigInteger.valueOf(MAX_YEAR_DAYS);
    private static final BigInteger MIN_LENGTH = BigInteger.valueOf(MIN_YEAR_DAYS);
    private final MonsterGates gates = new MonsterGates();

    public record Year(BigInteger number, BigInteger openGateIndex,
        BigInteger closeGateIndex, BigInteger openGateDay, BigInteger closeGateDay) {
        public BigInteger length() {
            return closeGateDay.subtract(openGateDay);
        }
    }

    private record Candidate(BigInteger openIndex, BigInteger closeIndex,
                             BigInteger openDay, BigInteger closeDay) {
        BigInteger length() {
            return closeDay.subtract(openDay);
        }

        Year toYear(BigInteger number) {
            return new Year(number, openIndex, closeIndex, openDay, closeDay);
        }
    }

    private static final Comparator<Candidate> RANK_ORDER =
        Comparator.comparing(Candidate::length).thenComparing(Candidate::openDay);

    public synchronized Year year5000(BigInteger calculationDay) {
        if (calculationDay == null) throw new IllegalArgumentException("E_NULL_DAY");
        gates.coverDays(calculationDay.subtract(MAX_LENGTH), calculationDay.add(MAX_LENGTH));
        List<Map.Entry<BigInteger, BigInteger>> positions =
            new ArrayList<>(gates.snapshot().entrySet());
        List<Candidate> valid = new ArrayList<>();
        for (int i = 0; i < positions.size(); i++) {
            Map.Entry<BigInteger, BigInteger> start = positions.get(i);
            if (start.getValue().compareTo(calculationDay) >= 0) continue;
            for (int j = i + 6; j < positions.size(); j++) {
                Map.Entry<BigInteger, BigInteger> end = positions.get(j);
                BigInteger length = end.getValue().subtract(start.getValue());
                if (length.compareTo(MAX_LENGTH) > 0) break;
                if (length.compareTo(MIN_LENGTH) < 0
                    || calculationDay.compareTo(end.getValue()) > 0) continue;
                valid.add(new Candidate(start.getKey(), end.getKey(),
                    start.getValue(), end.getValue()));
            }
        }
        valid.sort(RANK_ORDER);
        if (valid.isEmpty()) throw new IllegalStateException("E_YEAR5000_EMPTY");
        MonsterSauceBowls.SauceResult sauce =
            MonsterSauceBowls.evaluate(calculationDay, calculationDay);
        BigInteger rank = MonsterSelectors.choose(
            MonsterSauceBowls.ask(sauce, 1, 10), BigInteger.valueOf(valid.size()));
        return valid.get(rank.intValueExact() - 1).toYear(BigInteger.valueOf(5000));
    }

    private void validate(Year year) {
        if (year == null || year.number() == null || year.openGateIndex() == null
            || year.closeGateIndex() == null || year.openGateDay() == null
            || year.closeGateDay() == null) {
            throw new IllegalArgumentException("E_YEAR_NULL");
        }
        if (year.closeGateIndex().subtract(year.openGateIndex()).compareTo(SIX) < 0
            || year.length().compareTo(MIN_LENGTH) < 0
            || year.length().compareTo(MAX_LENGTH) > 0
            || !gates.gateAt(year.openGateIndex()).equals(year.openGateDay())
            || !gates.gateAt(year.closeGateIndex()).equals(year.closeGateDay())) {
            throw new IllegalArgumentException("E_YEAR_GATE");
        }
    }

    public synchronized Year nextYear(BigInteger calculationDay, Year known) {
        if (calculationDay == null) throw new IllegalArgumentException("E_NULL_DAY");
        validate(known);
        BigInteger openIndex = known.closeGateIndex();
        BigInteger openDay = known.closeGateDay();
        gates.coverDays(openDay, openDay.add(MAX_LENGTH));
        List<Candidate> valid = new ArrayList<>();
        for (BigInteger index = openIndex.add(SIX); ; index = index.add(ONE)) {
            BigInteger closeDay = gates.gateAt(index);
            BigInteger length = closeDay.subtract(openDay);
            if (length.compareTo(MAX_LENGTH) > 0) break;
            if (length.compareTo(MIN_LENGTH) >= 0) {
                valid.add(new Candidate(openIndex, index, openDay, closeDay));
            }
        }
        if (valid.isEmpty()) throw new IllegalStateException("E_NEXT_YEAR_EMPTY");
        valid.sort(RANK_ORDER);
        MonsterSauceBowls.SauceResult sauce = MonsterSauceBowls.evaluate(calculationDay, openDay);
        BigInteger rank = MonsterSelectors.choose(
            MonsterSauceBowls.ask(sauce, 1, 11), BigInteger.valueOf(valid.size()));
        return valid.get(rank.intValueExact() - 1).toYear(known.number().add(ONE));
    }

    public synchronized Year previousYear(BigInteger calculationDay, Year known) {
        if (calculationDay == null) throw new IllegalArgumentException("E_NULL_DAY");
        validate(known);
        BigInteger closeIndex = known.openGateIndex();
        BigInteger closeDay = known.openGateDay();
        gates.coverDays(closeDay.subtract(MAX_LENGTH), closeDay);
        List<Candidate> valid = new ArrayList<>();
        for (BigInteger index = closeIndex.subtract(SIX); ; index = index.subtract(ONE)) {
            BigInteger openDay = gates.gateAt(index);
            BigInteger length = closeDay.subtract(openDay);
            if (length.compareTo(MAX_LENGTH) > 0) break;
            if (length.compareTo(MIN_LENGTH) >= 0) {
                valid.add(new Candidate(index, closeIndex, openDay, closeDay));
            }
        }
        if (valid.isEmpty()) throw new IllegalStateException("E_PREVIOUS_YEAR_EMPTY");
        valid.sort(RANK_ORDER);
        MonsterSauceBowls.SauceResult sauce = MonsterSauceBowls.evaluate(calculationDay, closeDay);
        BigInteger rank = MonsterSelectors.choose(
            MonsterSauceBowls.ask(sauce, 1, 12), BigInteger.valueOf(valid.size()));
        return valid.get(rank.intValueExact() - 1).toYear(known.number().subtract(ONE));
    }

    public synchronized Year findTargetYear(BigInteger calculationDay, BigInteger targetDay) {
        if (calculationDay == null || targetDay == null) {
            throw new IllegalArgumentException("E_NULL_DAY");
        }
        Year y = year5000(calculationDay);
        while (targetDay.compareTo(y.closeGateDay()) > 0) {
            y = nextYear(calculationDay, y);
        }
        while (targetDay.compareTo(y.openGateDay()) <= 0) {
            y = previousYear(calculationDay, y);
        }
        if (!(y.openGateDay().compareTo(targetDay) < 0
            && targetDay.compareTo(y.closeGateDay()) <= 0)) {
            throw new IllegalStateException("E_TARGET_YEAR");
        }
        return y;
    }

    public synchronized Map<BigInteger, BigInteger> gateSnapshot() {
        return gates.snapshot();
    }
}
