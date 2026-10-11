package org.pastafari.javalojban;

import java.math.BigInteger;
import java.util.Arrays;

public final class MonsterWeavingLinearCounter {
    public static final int MAX_DAYS = 5778;
    public static final int MAX_UNRANK_DAYS = 512;
    private static final BigInteger ZERO = BigInteger.ZERO;
    private static final BigInteger ONE = BigInteger.ONE;

    private final int[] lengths;
    private final int totalDays;
    private BigInteger rootCount;

    private static final class State {
        final int[] remaining;
        int opened;
        int closed;

        State(int[] original) {
            remaining = original.clone();
        }

        State(State previous) {
            remaining = previous.remaining.clone();
            opened = previous.opened;
            closed = previous.closed;
        }

        boolean canTake(int month, int[] original) {
            return month >= 0 && month < original.length
                && remaining[month] > 0
                && (remaining[month] != original[month] || month == opened)
                && (remaining[month] != 1 || month == closed);
        }

        void take(int month, int[] original) {
            if (!canTake(month, original)) {
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
        totalDays = days;
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

    private int[] extremeWeaving(boolean latest) {
        State state = new State(lengths);
        int[] order = new int[totalDays];
        for (int position = 0; position < totalDays; position++) {
            boolean found = false;
            if (latest) {
                for (int month = lengths.length - 1; month >= state.closed; month--) {
                    if (state.canTake(month, lengths)) {
                        state.take(month, lengths);
                        order[position] = month + 1;
                        found = true;
                        break;
                    }
                }
            } else {
                for (int month = state.closed; month < lengths.length; month++) {
                    if (state.canTake(month, lengths)) {
                        state.take(month, lengths);
                        order[position] = month + 1;
                        found = true;
                        break;
                    }
                }
            }
            if (!found) throw new IllegalStateException("E_WEAVE_EXTREME");
        }
        return order;
    }

    public int[] lexFirst() {
        return extremeWeaving(false);
    }

    public int[] lexLast() {
        return extremeWeaving(true);
    }

    public int[] unrank1(BigInteger rank) {
        if (totalDays > MAX_UNRANK_DAYS) {
            BigInteger total = count();
            if (ONE.equals(rank)) return lexFirst();
            if (total.equals(rank)) return lexLast();
            throw new IllegalArgumentException("E_WEAVE_UNRANK_LIMIT");
        }
        BigInteger total = count();
        if (rank == null || rank.signum() <= 0 || rank.compareTo(total) > 0) {
            throw new IllegalArgumentException("E_WEAVE_RANK");
        }
        State state = new State(lengths);
        int[] weaving = new int[totalDays];
        BigInteger remainingRank = rank;
        for (int position = 0; position < totalDays; position++) {
            boolean chosen = false;
            for (int month = state.closed; month < lengths.length; month++) {
                if (!state.canTake(month, lengths)) continue;
                State possible = new State(state);
                possible.take(month, lengths);
                BigInteger possibilities = countSuffix(possible);
                if (remainingRank.compareTo(possibilities) > 0) {
                    remainingRank = remainingRank.subtract(possibilities);
                } else {
                    state = possible;
                    weaving[position] = month + 1;
                    chosen = true;
                    break;
                }
            }
            if (!chosen) throw new IllegalStateException("E_WEAVE_UNRANK");
        }
        return weaving;
    }

    public BigInteger rank1(int[] weaving) {
        if (totalDays > MAX_UNRANK_DAYS) {
            if (weaving != null && weaving.length == totalDays) {
                if (Arrays.equals(weaving, lexFirst())) return ONE;
                if (Arrays.equals(weaving, lexLast())) return count();
            }
            throw new IllegalArgumentException("E_WEAVE_RANK_LIMIT");
        }
        if (weaving == null || weaving.length != totalDays) {
            throw new IllegalArgumentException("E_WEAVE_SEQUENCE");
        }
        State state = new State(lengths);
        BigInteger rank = ONE;
        for (int id : weaving) {
            int month = id - 1;
            if (!state.canTake(month, lengths)) {
                throw new IllegalArgumentException("E_WEAVE_SEQUENCE");
            }
            for (int earlier = state.closed; earlier < month; earlier++) {
                if (!state.canTake(earlier, lengths)) continue;
                State alternative = new State(state);
                alternative.take(earlier, lengths);
                rank = rank.add(countSuffix(alternative));
            }
            state.take(month, lengths);
        }
        return rank;
    }

}
