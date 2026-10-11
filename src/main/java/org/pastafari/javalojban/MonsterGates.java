package org.pastafari.javalojban;

import java.math.BigInteger;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.NavigableMap;
import java.util.TreeMap;

public final class MonsterGates {
    private static final BigInteger ZERO = BigInteger.ZERO;
    private static final BigInteger ONE = BigInteger.ONE;
    private static final BigInteger RANGE = BigInteger.valueOf(922);
    private static final BigInteger OFFSET = BigInteger.valueOf(41);
    private final NavigableMap<BigInteger, BigInteger> indexedDays = new TreeMap<>();

    public MonsterGates() {
        indexedDays.put(ZERO, MonsterArithmetic.FOUNDATION_DAY);
    }

    public static BigInteger gap(boolean positive, BigInteger index) {
        if (index == null || index.signum() <= 0) {
            throw new IllegalArgumentException(positive ? "E_POS_GATE" : "E_NEG_GATE");
        }
        BigInteger foundation = MonsterArithmetic.FOUNDATION_DAY;
        BigInteger requestedDay = positive ? foundation.add(index) : foundation.subtract(index);
        MonsterSauceBowls.SauceResult sauce = MonsterSauceBowls.evaluate(foundation, requestedDay);
        BigInteger selected = MonsterSelectors.choose(
            MonsterSauceBowls.ask(sauce, 1, 1), RANGE);
        return OFFSET.add(selected);
    }

    public static BigInteger positiveGap(BigInteger index) {
        return gap(true, index);
    }

    public static BigInteger negativeGap(BigInteger index) {
        return gap(false, index);
    }

    public synchronized BigInteger gateAt(BigInteger index) {
        if (index == null) throw new IllegalArgumentException("E_NULL_GATE");
        while (indexedDays.lastKey().compareTo(index) < 0) {
            BigInteger next = indexedDays.lastKey().add(ONE);
            indexedDays.put(next, indexedDays.lastEntry().getValue().add(positiveGap(next)));
        }
        while (indexedDays.firstKey().compareTo(index) > 0) {
            BigInteger next = indexedDays.firstKey().subtract(ONE);
            indexedDays.put(next, indexedDays.firstEntry().getValue().subtract(negativeGap(next.negate())));
        }
        return indexedDays.get(index);
    }

    public synchronized void coverDays(BigInteger lower, BigInteger upper) {
        if (lower == null || upper == null || lower.compareTo(upper) > 0) {
            throw new IllegalArgumentException("E_GATE_RANGE");
        }
        while (indexedDays.firstEntry().getValue().compareTo(lower) > 0) {
            gateAt(indexedDays.firstKey().subtract(ONE));
        }
        while (indexedDays.lastEntry().getValue().compareTo(upper) < 0) {
            gateAt(indexedDays.lastKey().add(ONE));
        }
    }

    public synchronized BigInteger atOrBefore(BigInteger day) {
        if (day == null) throw new IllegalArgumentException("E_NULL_DAY");
        coverDays(day, day);
        BigInteger low = indexedDays.firstKey();
        BigInteger high = indexedDays.lastKey();
        while (low.compareTo(high) < 0) {
            BigInteger mid = low.add(high.subtract(low).add(ONE).divide(BigInteger.TWO));
            if (indexedDays.get(mid).compareTo(day) <= 0) {
                low = mid;
            } else {
                high = mid.subtract(ONE);
            }
        }
        return low;
    }

    public synchronized BigInteger exactGate(BigInteger day) {
        BigInteger index = atOrBefore(day);
        return gateAt(index).equals(day) ? index : null;
    }

    public synchronized Map<BigInteger, BigInteger> snapshot() {
        return Collections.unmodifiableMap(new LinkedHashMap<>(indexedDays));
    }
}
