package org.pastafari.javalojban;

import java.math.BigInteger;
import java.util.Arrays;

public final class MonsterWeavingLinearCounter {
    public static final int MAX_DAYS = 5778;
    private static final BigInteger ZERO = BigInteger.ZERO;
    private static final BigInteger ONE = BigInteger.ONE;

    private final int[] lengths;
    private BigInteger rootCount;

    private static final class State {
        final int[] remaining;
        int opened;
        int closed;

        State(int[] original) {
            remaining = original.clone();
        }

        void take(int month, int[] original) {
            if (month < 0 || month >= original.length || remaining[month] == 0
                    || remaining[month] == original[month] && month != opened
                    || remaining[month] == 1 && month != closed) {
                throw new IllegalArgumentException("E_WEAVE_PREFIX");
            }
            boolean first = remaining[month] == original[month];
            remaining[month]--;
            if (first) opened = month + 1;
            if (remaining[month] == 0) closed = month + 1;
        }
    }

    public MonsterWeavingLinearCounter(int[] values) {
        if (values == null || values.length == 0) {
            throw new IllegalArgumentException("E_WEAVE_EMPTY");
        }
        int days = 0;
        for (int value : values) {
            if (value < 1) throw new IllegalArgumentException("E_WEAVE_LENGTH");
            if (value > MAX_DAYS || days > MAX_DAYS - value) {
                throw new IllegalArgumentException("E_WEAVE_LIMIT");
            }
            days += value;
        }
        lengths = values.clone();
    }

    private static BigInteger[] chooseColumn(int total, int width) {
        BigInteger[] binomial = new BigInteger[total + 1];
        BigInteger current = ONE;
        binomial[width] = current;
        for (int n = width + 1; n <= total; n++) {
            current = current.multiply(BigInteger.valueOf(n))
                .divide(BigInteger.valueOf(n - width));
            binomial[n] = current;
        }
        return binomial;
    }

    private BigInteger countSuffix(State state) {
        if (state.closed == lengths.length) return ONE;
        int days = state.remaining[state.closed];
        BigInteger[] previous = new BigInteger[days + 2];
        previous[1] = ONE;
        BigInteger previousTotal = ONE;

        for (int month = state.closed + 1; month < lengths.length; month++) {
            int additional = state.remaining[month];
            if (additional < 1) throw new IllegalStateException("E_WEAVE_STATE");
            int newDays = days + additional;
            BigInteger[] next = new BigInteger[newDays + 2];
            BigInteger newTotal = ZERO;

            if (additional == 1) {
                next[days + 1] = previousTotal;
                newTotal = previousTotal;
            } else {
                boolean enforceOpen = month - 1 >= state.opened;
                BigInteger[] binomial = chooseColumn(newDays, additional - 2);
                BigInteger eligible = enforceOpen ? ZERO : previousTotal;
                for (int first = 1; first <= days + 1; first++) {
                    if (enforceOpen && first > 1) {
                        BigInteger preceding = previous[first - 1];
                        if (preceding != null) eligible = eligible.add(preceding);
                    }
                    if (eligible.signum() > 0) {
                        BigInteger ways = eligible.multiply(
                            binomial[newDays - first - 1]);
                        next[first] = ways;
                        newTotal = newTotal.add(ways);
                    }
                }
            }
            previous = next;
            previousTotal = newTotal;
            days = newDays;
        }
        return previousTotal;
    }

    public synchronized BigInteger count() {
        if (rootCount == null) rootCount = countSuffix(new State(lengths));
        return rootCount;
    }

    public BigInteger countAfterPrefix(int[] prefix) {
        if (prefix == null) throw new IllegalArgumentException("E_WEAVE_PREFIX");
        if (prefix.length == 0) return count();
        State state = new State(lengths);
        for (int id : prefix) state.take(id - 1, lengths);
        return countSuffix(state);
    }
}
