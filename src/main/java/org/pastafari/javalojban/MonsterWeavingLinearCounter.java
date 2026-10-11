package org.pastafari.javalojban;

import java.math.BigInteger;
import java.util.Arrays;

public final class MonsterWeavingLinearCounter {
    public static final int MAX_DAYS = 5778;
    public static final int MAX_UNRANK_DAYS = 512;
    public static final int MAX_EDGE_DISTANCE = 8;
    public static final int MAX_GLOBAL_PREFIX_BRANCH_COUNTS = 64;
    private static final BigInteger ZERO = BigInteger.ZERO;
    private static final BigInteger ONE = BigInteger.ONE;

    private final int[] lengths;
    private final int totalDays;
    private BigInteger rootCount;
    private BoundaryBlock cachedFirstBlock;
    private BoundaryBlock cachedLastBlock;

    public static final class BoundaryBlock {
        private final int[] prefix;
        private final BigInteger lowerRank;
        private final BigInteger upperRank;

        private BoundaryBlock(int[] prefix, BigInteger lowerRank, BigInteger upperRank) {
            this.prefix = prefix.clone();
            this.lowerRank = lowerRank;
            this.upperRank = upperRank;
        }

        public int[] fixedPrefixCopy() { return prefix.clone(); }
        public BigInteger lowerRank() { return lowerRank; }
        public BigInteger upperRank() { return upperRank; }
        public BigInteger size() { return upperRank.subtract(lowerRank).add(ONE); }
        public boolean contains(BigInteger rank) {
            return rank != null && lowerRank.compareTo(rank) <= 0
                && rank.compareTo(upperRank) <= 0;
        }
    }

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
        State state = afterPrefix(prefix);
        if (prefix.length == 0) return count();
        return countSuffix(state);
    }


    private State afterPrefix(int[] prefix) {
        if (prefix == null || prefix.length > totalDays) {
            throw new IllegalArgumentException("E_WEAVE_PREFIX");
        }
        State state = new State(lengths);
        for (int id : prefix) state.take(id - 1, lengths);
        return state;
    }

    private int daysRemaining(State state) {
        int days = 0;
        for (int n : state.remaining) days += n;
        return days;
    }

    public int[] unrankAfterPrefix(int[] prefix, BigInteger localRank) {
        State state = afterPrefix(prefix);
        int suffixDays = daysRemaining(state);
        if (suffixDays > MAX_UNRANK_DAYS) {
            throw new IllegalArgumentException("E_WEAVE_SUFFIX_LIMIT");
        }
        BigInteger choices = prefix.length == 0 ? count() : countSuffix(state);
        if (localRank == null || localRank.signum() <= 0
                || localRank.compareTo(choices) > 0) {
            throw new IllegalArgumentException("E_WEAVE_RANK");
        }
        int[] sequence = new int[totalDays];
        System.arraycopy(prefix, 0, sequence, 0, prefix.length);
        BigInteger remainingRank = localRank;
        for (int pos = prefix.length; pos < totalDays; pos++) {
            boolean chosen = false;
            for (int month = state.closed; month < lengths.length; month++) {
                if (!state.canTake(month, lengths)) continue;
                State trial = new State(state);
                trial.take(month, lengths);
                BigInteger block = countSuffix(trial);
                if (remainingRank.compareTo(block) > 0) {
                    remainingRank = remainingRank.subtract(block);
                } else {
                    state = trial;
                    sequence[pos] = month + 1;
                    chosen = true;
                    break;
                }
            }
            if (!chosen) throw new IllegalStateException("E_WEAVE_UNRANK");
        }
        return sequence;
    }

    public BigInteger rankAfterPrefix(int[] prefix, int[] completeWeaving) {
        State state = afterPrefix(prefix);
        if (completeWeaving == null || completeWeaving.length != totalDays) {
            throw new IllegalArgumentException("E_WEAVE_SEQUENCE");
        }
        for (int i = 0; i < prefix.length; i++) {
            if (completeWeaving[i] != prefix[i]) {
                throw new IllegalArgumentException("E_WEAVE_PREFIX_MISMATCH");
            }
        }
        if (daysRemaining(state) > MAX_UNRANK_DAYS) {
            throw new IllegalArgumentException("E_WEAVE_SUFFIX_LIMIT");
        }
        BigInteger rank = ONE;
        for (int pos = prefix.length; pos < totalDays; pos++) {
            int month = completeWeaving[pos] - 1;
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


    private State[] prefixStates(int[] weaving) {
        if (weaving == null || weaving.length != totalDays) {
            throw new IllegalArgumentException("E_WEAVE_SEQUENCE");
        }
        State[] before = new State[totalDays];
        State current = new State(lengths);
        for (int i = 0; i < totalDays; i++) {
            int month = weaving[i] - 1;
            if (!current.canTake(month, lengths)) {
                throw new IllegalArgumentException("E_WEAVE_SEQUENCE");
            }
            before[i] = new State(current);
            current.take(month, lengths);
        }
        return before;
    }

    private int[] neighbor(int[] weaving, boolean forward) {
        State[] before = prefixStates(weaving);
        for (int pivot = totalDays - 1; pivot >= 0; pivot--) {
            State current = before[pivot];
            int begin = weaving[pivot] - 1 + (forward ? 1 : -1);
            int stop = forward ? lengths.length : -1;
            int step = forward ? 1 : -1;
            for (int month = begin; month != stop; month += step) {
                if (!current.canTake(month, lengths)) continue;
                int[] result = weaving.clone();
                result[pivot] = month + 1;
                current.take(month, lengths);
                for (int pos = pivot + 1; pos < totalDays; pos++) {
                    boolean selected = false;
                    if (forward) {
                        for (int next = current.closed; next < lengths.length; next++) {
                            if (!current.canTake(next, lengths)) continue;
                            result[pos] = next + 1;
                            current.take(next, lengths);
                            selected = true;
                            break;
                        }
                    } else {
                        for (int next = lengths.length - 1; next >= current.closed; next--) {
                            if (!current.canTake(next, lengths)) continue;
                            result[pos] = next + 1;
                            current.take(next, lengths);
                            selected = true;
                            break;
                        }
                    }
                    if (!selected) throw new IllegalStateException("E_WEAVE_NEIGHBOR");
                }
                return result;
            }
        }
        return null;
    }

    public int[] lexNext(int[] weaving) {
        return neighbor(weaving, true);
    }

    public int[] lexPrevious(int[] weaving) {
        return neighbor(weaving, false);
    }

    private int[] edgeUnrank(BigInteger rank, BigInteger total) {
        BigInteger firstLimit = BigInteger.valueOf(1L + MAX_EDGE_DISTANCE);
        boolean fromStart = rank.compareTo(firstLimit) <= 0;
        int steps = (fromStart ? rank.subtract(ONE) : total.subtract(rank)).intValueExact();
        int[] current = fromStart ? lexFirst() : lexLast();
        for (int i = 0; i < steps; i++) {
            current = neighbor(current, fromStart);
            if (current == null) throw new IllegalStateException("E_WEAVE_EDGE_SPACE");
        }
        return current;
    }

    private BigInteger edgeRank(int[] weaving) {
        if (weaving == null || weaving.length != totalDays) {
            throw new IllegalArgumentException("E_WEAVE_RANK_LIMIT");
        }
        BigInteger total = count();
        int[] low = lexFirst();
        int[] high = lexLast();
        for (int distance = 0; distance <= MAX_EDGE_DISTANCE; distance++) {
            if (Arrays.equals(weaving, low)) return BigInteger.valueOf(1L + distance);
            if (Arrays.equals(weaving, high)) {
                return total.subtract(BigInteger.valueOf(distance));
            }
            if (distance != MAX_EDGE_DISTANCE) {
                low = neighbor(low, true);
                high = neighbor(high, false);
                if (low == null || high == null) break;
            }
        }
        throw new IllegalArgumentException("E_WEAVE_RANK_LIMIT");
    }

    public int[] lexFirst() {
        return extremeWeaving(false);
    }

    public int[] lexLast() {
        return extremeWeaving(true);
    }


    public BoundaryBlock boundaryBlock(boolean latest, int suffixDays) {
        if (suffixDays < 0 || suffixDays > MAX_UNRANK_DAYS || suffixDays > totalDays) {
            throw new IllegalArgumentException("E_WEAVE_SUFFIX_LIMIT");
        }
        int[] full = latest ? lexLast() : lexFirst();
        int[] prefix = Arrays.copyOf(full, totalDays - suffixDays);
        BigInteger possible = countAfterPrefix(prefix);
        BigInteger start = latest ? count().subtract(possible).add(ONE) : ONE;
        return new BoundaryBlock(prefix, start, start.add(possible).subtract(ONE));
    }


    public BoundaryBlock globalBlockForPrefix(int[] fixedPrefix) {
        State state = afterPrefix(fixedPrefix);
        BigInteger size = fixedPrefix.length == 0 ? count() : countSuffix(state);
        if (sharesPrefix(lexFirst(), fixedPrefix)) {
            return new BoundaryBlock(fixedPrefix, ONE, size);
        }
        if (sharesPrefix(lexLast(), fixedPrefix)) {
            BigInteger start = count().subtract(size).add(ONE);
            return new BoundaryBlock(fixedPrefix, start, start.add(size).subtract(ONE));
        }
        state = new State(lengths);
        BigInteger firstRank = ONE;
        int examinedBranches = 0;
        for (int chosenId : fixedPrefix) {
            int chosen = chosenId - 1;
            if (!state.canTake(chosen, lengths)) {
                throw new IllegalArgumentException("E_WEAVE_PREFIX");
            }
            for (int candidate = state.closed; candidate < chosen; candidate++) {
                if (!state.canTake(candidate, lengths)) continue;
                if (++examinedBranches > MAX_GLOBAL_PREFIX_BRANCH_COUNTS) {
                    throw new IllegalArgumentException("E_WEAVE_GLOBAL_BUDGET");
                }
                State earlier = new State(state);
                earlier.take(candidate, lengths);
                firstRank = firstRank.add(countSuffix(earlier));
            }
            state.take(chosen, lengths);
        }
        return new BoundaryBlock(fixedPrefix, firstRank,
            firstRank.add(size).subtract(ONE));
    }

    public int[] unrankGlobalWithinPrefix(int[] fixedPrefix, BigInteger globalRank) {
        BoundaryBlock block = globalBlockForPrefix(fixedPrefix);
        if (!block.contains(globalRank)) {
            throw new IllegalArgumentException("E_WEAVE_GLOBAL_RANK");
        }
        return unrankAfterPrefix(fixedPrefix,
            globalRank.subtract(block.lowerRank()).add(ONE));
    }

    public BigInteger rankGlobalWithinPrefix(int[] fixedPrefix, int[] weaving) {
        BoundaryBlock block = globalBlockForPrefix(fixedPrefix);
        return block.lowerRank().subtract(ONE).add(rankAfterPrefix(fixedPrefix, weaving));
    }

    private synchronized BoundaryBlock defaultBoundary(boolean latest) {
        if (latest) {
            if (cachedLastBlock == null) {
                cachedLastBlock = boundaryBlock(true, MAX_UNRANK_DAYS);
            }
            return cachedLastBlock;
        }
        if (cachedFirstBlock == null) {
            cachedFirstBlock = boundaryBlock(false, MAX_UNRANK_DAYS);
        }
        return cachedFirstBlock;
    }

    private static boolean sharesPrefix(int[] sequence, int[] prefix) {
        if (sequence == null || sequence.length < prefix.length) return false;
        for (int i = 0; i < prefix.length; i++) {
            if (sequence[i] != prefix[i]) return false;
        }
        return true;
    }

    public int[] unrank1(BigInteger rank) {
        if (totalDays > MAX_UNRANK_DAYS) {
            BigInteger total = count();
            if (rank != null && rank.signum() > 0 && rank.compareTo(total) <= 0) {
                BoundaryBlock first = defaultBoundary(false);
                if (first.contains(rank)) {
                    return unrankAfterPrefix(first.fixedPrefixCopy(),
                        rank.subtract(first.lowerRank()).add(ONE));
                }
                BoundaryBlock last = defaultBoundary(true);
                if (last.contains(rank)) {
                    return unrankAfterPrefix(last.fixedPrefixCopy(),
                        rank.subtract(last.lowerRank()).add(ONE));
                }
                BigInteger edge = BigInteger.valueOf(1L + MAX_EDGE_DISTANCE);
                if (rank.compareTo(edge) <= 0
                    || total.subtract(rank).compareTo(BigInteger.valueOf(MAX_EDGE_DISTANCE)) <= 0) {
                    return edgeUnrank(rank, total);
                }
            }
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
                BoundaryBlock first = defaultBoundary(false);
                int[] prefix = first.fixedPrefixCopy();
                if (sharesPrefix(weaving, prefix)) {
                    return first.lowerRank().subtract(ONE).add(
                        rankAfterPrefix(prefix, weaving));
                }
                BoundaryBlock last = defaultBoundary(true);
                prefix = last.fixedPrefixCopy();
                if (sharesPrefix(weaving, prefix)) {
                    return last.lowerRank().subtract(ONE).add(
                        rankAfterPrefix(prefix, weaving));
                }
            }
            return edgeRank(weaving);
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
