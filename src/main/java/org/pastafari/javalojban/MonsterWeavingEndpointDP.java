package org.pastafari.javalojban;

import java.math.BigInteger;
import java.util.Arrays;

public final class MonsterWeavingEndpointDP {
    public static final int MAX_COUNT_DAYS = 768;
    public static final int MAX_UNRANK_DAYS = 160;
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

    private static final class EndpointTable {
        private final int days;
        private final int newestMonthLength;
        private final BigInteger[][] rows;

        EndpointTable(int olderDays, int newMonthLength) {
            this.days = olderDays + newMonthLength;
            this.newestMonthLength = newMonthLength;
            this.rows = new BigInteger[olderDays + 2][];
            for (int first = 1; first <= olderDays + 1; first++) {
                int lastStart = first + newMonthLength - 1;
                if (lastStart <= days) {
                    rows[first] = new BigInteger[days - lastStart + 1];
                }
            }
        }

        void addColumnSums(int first, BigInteger[] columns) {
            if (first < 1 || first >= rows.length) return;
            BigInteger[] row = rows[first];
            if (row == null) return;
            int lastStart = first + newestMonthLength - 1;
            for (int j = 0; j < row.length; j++) {
                if (row[j] != null) {
                    int last = lastStart + j;
                    columns[last] = columns[last].add(row[j]);
                }
            }
        }

        BigInteger sum() {
            BigInteger total = ZERO;
            for (BigInteger[] row : rows) {
                if (row == null) continue;
                for (BigInteger value : row) {
                    if (value != null) total = total.add(value);
                }
            }
            return total;
        }
    }

    private static EndpointTable initialTable(int length) {
        EndpointTable first = new EndpointTable(0, length);
        first.rows[1][0] = ONE;
        return first;
    }

    private static BigInteger[] fixedBinomialColumn(int days, int width) {
        BigInteger[] column = new BigInteger[days + 1];
        BigInteger running = ONE;
        column[width] = running;
        for (int n = width + 1; n <= days; n++) {
            running = running.multiply(BigInteger.valueOf(n))
                .divide(BigInteger.valueOf(n - width));
            column[n] = running;
        }
        return column;
    }

    private static EndpointTable insert(EndpointTable previous, int oldLength,
                                        int add, boolean enforceFirstOrder) {
        EndpointTable next = new EndpointTable(oldLength, add);
        int currentLength = oldLength + add;
        BigInteger[] columns = new BigInteger[oldLength + 1];
        Arrays.fill(columns, ZERO);

        if (!enforceFirstOrder || add == 1) {
            for (int first = 1; first < previous.rows.length; first++) {
                previous.addColumnSums(first, columns);
            }
        }
        if (add == 1) {
            BigInteger cumulative = ZERO;
            int included = 0;
            for (int first = 1; first <= oldLength + 1; first++) {
                int boundary = Math.min(first - 1, oldLength);
                while (included < boundary) {
                    cumulative = cumulative.add(columns[++included]);
                }
                if (cumulative.signum() > 0) next.rows[first][0] = cumulative;
            }
            return next;
        }
        BigInteger[] binomial = fixedBinomialColumn(currentLength, add - 2);
        for (int first = 1; first <= oldLength + 1; first++) {
            if (enforceFirstOrder) previous.addColumnSums(first - 1, columns);
            BigInteger cumulative = ZERO;
            int included = 0;
            BigInteger[] row = next.rows[first];
            int lastStart = first + add - 1;
            for (int last = lastStart; last <= currentLength; last++) {
                int boundary = Math.min(last - add, oldLength);
                while (included < boundary) {
                    cumulative = cumulative.add(columns[++included]);
                }
                if (cumulative.signum() > 0) {
                    row[last - lastStart] = cumulative.multiply(binomial[last - first - 1]);
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
        EndpointTable table = initialTable(oldLength);
        for (int index = earliest + 1; index < lengths.length; index++) {
            int additional = state.remaining[index];
            if (additional <= 0) throw new IllegalStateException("E_WEAVE_STATE");
            boolean enforceFirstOrder = index - 1 >= state.opened;
            table = insert(table, oldLength, additional, enforceFirstOrder);
            oldLength += additional;
        }
        return table.sum();
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
