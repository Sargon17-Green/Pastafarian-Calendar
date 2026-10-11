package org.pastafari.javalojban;

import java.math.BigInteger;
import java.util.Arrays;

public final class MonsterWeavingEndpointDP {
    public static final int MAX_COUNT_DAYS = 512;
    public static final int MAX_UNRANK_DAYS = 96;
    private static final BigInteger ZERO = BigInteger.ZERO;
    private static final BigInteger ONE = BigInteger.ONE;

    private final int[] lengths;
    private final int totalDays;

    public MonsterWeavingEndpointDP(int[] lengths) {
        if (lengths == null || lengths.length == 0) {
            throw new IllegalArgumentException("E_WEAVE_EMPTY");
        }
        this.lengths = lengths.clone();
        int sum = 0;
        for (int value : this.lengths) {
            if (value < 1) throw new IllegalArgumentException("E_WEAVE_LENGTH");
            if (value > MAX_COUNT_DAYS || sum > MAX_COUNT_DAYS - value) {
                throw new IllegalArgumentException("E_WEAVE_LIMIT");
            }
            sum += value;
        }
        this.totalDays = sum;
    }

    private static final class State {
        final int[] remaining;
        int opened;
        int closed;

        State(int[] original) {
            remaining = original.clone();
        }

        boolean canTake(int month, int[] original) {
            if (remaining[month] == 0) return false;
            if (remaining[month] == original[month] && month != opened) return false;
            return remaining[month] != 1 || month == closed;
        }

        void take(int month, int[] original) {
            boolean first = remaining[month] == original[month];
            remaining[month]--;
            if (first) opened = month + 1;
            if (remaining[month] == 0) closed = month + 1;
        }
    }

    private State afterPrefix(int[] prefix) {
        if (prefix == null) throw new IllegalArgumentException("E_WEAVE_PREFIX");
        State state = new State(lengths);
        for (int monthId : prefix) {
            int month = monthId - 1;
            if (month < 0 || month >= lengths.length
                    || !state.canTake(month, lengths)) {
                throw new IllegalArgumentException("E_WEAVE_PREFIX");
            }
            state.take(month, lengths);
        }
        return state;
    }

    public BigInteger count() {
        return countSuffix(new State(lengths));
    }

    public BigInteger countAfterPrefix(int[] prefix) {
        return countSuffix(afterPrefix(prefix));
    }

    private static BigInteger[][] initialTable(int count) {
        BigInteger[][] table = new BigInteger[count + 1][count + 1];
        table[1][count] = ONE;
        return table;
    }

    private static BigInteger[][] insert(BigInteger[][] previous, int oldLength,
                                         int add, boolean enforceFirstOrder) {
        int currentLength = oldLength + add;
        BigInteger[][] next = new BigInteger[currentLength + 1][currentLength + 1];
        BigInteger[] columns = new BigInteger[oldLength + 1];
        Arrays.fill(columns, ZERO);

        if (!enforceFirstOrder) {
            for (int first = 1; first <= oldLength; first++) {
                for (int last = first; last <= oldLength; last++) {
                    BigInteger value = previous[first][last];
                    if (value != null) columns[last] = columns[last].add(value);
                }
            }
        }
        if (add == 1) {
            BigInteger cumulative = ZERO;
            int included = 0;
            for (int first = 1; first <= currentLength; first++) {
                if (enforceFirstOrder && first - 1 >= 1 && first - 1 <= oldLength) {
                    for (int last = first - 1; last <= oldLength; last++) {
                        BigInteger value = previous[first - 1][last];
                        if (value != null) columns[last] = columns[last].add(value);
                    }
                }
                int boundary = Math.min(first - 1, oldLength);
                while (included < boundary) {
                    included++;
                    cumulative = cumulative.add(columns[included]);
                }
                if (cumulative.signum() > 0) next[first][first] = cumulative;
            }
            return next;
        }
        for (int first = 1; first <= oldLength + 1; first++) {
            if (enforceFirstOrder && first - 1 >= 1 && first - 1 <= oldLength) {
                for (int last = first - 1; last <= oldLength; last++) {
                    BigInteger value = previous[first - 1][last];
                    if (value != null) columns[last] = columns[last].add(value);
                }
            }
            BigInteger cumulative = ZERO;
            int included = 0;
            BigInteger interleavings = ONE;
            for (int last = first + add - 1; last <= currentLength; last++) {
                int boundary = Math.min(last - add, oldLength);
                while (included < boundary) {
                    included++;
                    cumulative = cumulative.add(columns[included]);
                }
                if (cumulative.signum() > 0) {
                    next[first][last] = cumulative.multiply(interleavings);
                }
                if (last != currentLength) {
                    long top = last - first;
                    long bottom = last - first - add + 2L;
                    interleavings = interleavings.multiply(BigInteger.valueOf(top))
                        .divide(BigInteger.valueOf(bottom));
                }
            }
        }
        return next;
    }

    private BigInteger countSuffix(State state) {
        int firstUnclosed = state.closed;
        if (firstUnclosed == lengths.length) return ONE;
        int earliest = firstUnclosed;
        int oldLength = state.remaining[earliest];
        BigInteger[][] table = initialTable(oldLength);
        for (int index = earliest + 1; index < lengths.length; index++) {
            int additional = state.remaining[index];
            if (additional <= 0) throw new IllegalStateException("E_WEAVE_STATE");
            boolean enforceFirstOrder = index - 1 >= state.opened;
            table = insert(table, oldLength, additional, enforceFirstOrder);
            oldLength += additional;
        }
        BigInteger total = ZERO;
        for (int first = 1; first <= oldLength; first++) {
            for (int last = first; last <= oldLength; last++) {
                if (table[first][last] != null) total = total.add(table[first][last]);
            }
        }
        return total;
    }

    public int[] unrank1(BigInteger rank) {
        if (totalDays > MAX_UNRANK_DAYS) {
            throw new IllegalArgumentException("E_WEAVE_UNRANK_LIMIT");
        }
        BigInteger count = count();
        if (rank == null || rank.signum() <= 0 || rank.compareTo(count) > 0) {
            throw new IllegalArgumentException("E_WEAVE_RANK");
        }
        State current = new State(lengths);
        int[] answer = new int[totalDays];
        BigInteger remainingRank = rank;
        for (int position = 0; position < totalDays; position++) {
            boolean selected = false;
            for (int month = current.closed; month < lengths.length; month++) {
                if (!current.canTake(month, lengths)) continue;
                State probe = new State(current.remaining);
                probe.opened = current.opened;
                probe.closed = current.closed;
                probe.take(month, lengths);
                BigInteger block = countSuffix(probe);
                if (remainingRank.compareTo(block) > 0) {
                    remainingRank = remainingRank.subtract(block);
                } else {
                    current = probe;
                    answer[position] = month + 1;
                    selected = true;
                    break;
                }
            }
            if (!selected) throw new IllegalStateException("E_WEAVE_UNRANK");
        }
        return answer;
    }
}
