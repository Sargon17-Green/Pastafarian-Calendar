package org.pastafari.javalojban;

import java.math.BigInteger;
import java.util.Arrays;
import java.util.ArrayDeque;
import java.util.Iterator;
import java.util.LinkedHashMap;
import java.util.Map;

public final class MonsterWeavingLinearCounter {
    public static final int MAX_DAYS = 5778;
    public static final int MAX_UNRANK_DAYS = 512;
    public static final int MAX_EDGE_DISTANCE = 8;
    public static final int MAX_GLOBAL_PREFIX_BRANCH_COUNTS = 64;
    public static final int MAX_ROUTE_STEPS_PER_CALL = 512;
    public static final int MAX_ROUTE_BRANCH_COUNTS_PER_CALL = 64;
    private static final BigInteger ZERO = BigInteger.ZERO;
    private static final BigInteger ONE = BigInteger.ONE;

    private static final int MAX_CACHED_BINOMIAL_COLUMNS = 8;
    private final Map<Integer, BigInteger[]> binomialColumns =
        new LinkedHashMap<Integer, BigInteger[]>(16, 0.75f, true) {
            @Override
            protected boolean removeEldestEntry(Map.Entry<Integer, BigInteger[]> eldest) {
                return size() > MAX_CACHED_BINOMIAL_COLUMNS;
            }
        };


    private static final int MAX_CACHED_SUFFIX_STATES = 64;
    private final Map<SuffixKey, BigInteger> suffixCounts =
        new LinkedHashMap<SuffixKey, BigInteger>(64, 0.75f, true) {
            @Override
            protected boolean removeEldestEntry(Map.Entry<SuffixKey, BigInteger> eldest) {
                return size() > MAX_CACHED_SUFFIX_STATES;
            }
        };
    private long suffixCacheHits;

    private static final class SuffixKey {
        private final int[] remaining;
        private final int opened;
        private final int closed;
        private final int hash;

        SuffixKey(State state) {
            remaining = state.remaining.clone();
            opened = state.opened;
            closed = state.closed;
            int h = Arrays.hashCode(remaining);
            h = 31 * h + opened;
            hash = 31 * h + closed;
        }

        @Override
        public int hashCode() {
            return hash;
        }

        @Override
        public boolean equals(Object value) {
            if (this == value) return true;
            if (!(value instanceof SuffixKey)) return false;
            SuffixKey other = (SuffixKey) value;
            return opened == other.opened && closed == other.closed
                && Arrays.equals(remaining, other.remaining);
        }
    }

    long suffixCacheHitCount() {
        synchronized (suffixCounts) {
            return suffixCacheHits;
        }
    }

    int suffixCacheEntryCount() {
        synchronized (suffixCounts) {
            return suffixCounts.size();
        }
    }

    private static final int MAX_PARTIAL_DP_CACHE_ENTRIES = 4;
    private static final int MAX_PARTIAL_DP_DAYS = 2048;
    private final ArrayDeque<PartialDP> partialDps = new ArrayDeque<>();
    private long partialDpReuseHits;
    private long closedFormTransitions;
    private long partialDpEvictions;

    private static final class PartialDP {
        final int[] originalRemaining;
        final int opened;
        final int closed;
        final int lastMonth;
        final int days;
        final BigInteger[] previous;
        final BigInteger previousTotal;

        PartialDP(State state, int lastMonth, int days,
                BigInteger[] previous, BigInteger previousTotal) {
            originalRemaining = state.remaining.clone();
            opened = state.opened;
            closed = state.closed;
            this.lastMonth = lastMonth;
            this.days = days;
            this.previous = previous;
            this.previousTotal = previousTotal;
        }

        boolean matches(State state) {
            if (opened != state.opened || closed != state.closed) return false;
            for (int month = closed; month <= lastMonth; month++) {
                if (originalRemaining[month] != state.remaining[month]) return false;
            }
            return true;
        }
    }

    private PartialDP cachedPartial(State state) {
        synchronized (partialDps) {
            PartialDP selected = null;
            for (PartialDP entry : partialDps) {
                if (entry.matches(state) && (selected == null
                        || entry.lastMonth > selected.lastMonth)) {
                    selected = entry;
                }
            }
            if (selected != null) {
                partialDps.remove(selected);
                partialDps.addLast(selected);
                partialDpReuseHits++;
            }
            return selected;
        }
    }

    private void keepPartial(State state, int month, int days,
            BigInteger[] previous, BigInteger previousTotal) {
        if (days > MAX_PARTIAL_DP_DAYS
                || (month != state.closed + 7 && month != state.closed + 15)) {
            return;
        }
        synchronized (partialDps) {
            if (partialDps.size() == MAX_PARTIAL_DP_CACHE_ENTRIES) {
                partialDps.removeFirst();
                partialDpEvictions++;
            }
            partialDps.addLast(new PartialDP(
                state, month, days, previous, previousTotal));
        }
    }

    long partialDpReuseHitCount() {
        synchronized (partialDps) {
            return partialDpReuseHits;
        }
    }

    long closedFormTransitionCount() {
        synchronized (partialDps) {
            return closedFormTransitions;
        }
    }

    int partialDpCacheEntryCount() {
        synchronized (partialDps) {
            return partialDps.size();
        }
    }

    long partialDpEvictionCount() {
        synchronized (partialDps) {
            return partialDpEvictions;
        }
    }

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

    private BigInteger[] chooseColumn(int total, int width) {
        if (width < 0 || width > total || total > totalDays) {
            throw new IllegalStateException("E_WEAVE_BINOMIAL_BOUNDS");
        }
        synchronized (binomialColumns) {
            BigInteger[] cached = binomialColumns.get(width);
            if (cached != null) return cached;
            BigInteger[] column = new BigInteger[totalDays + 1];
            BigInteger current = ONE;
            column[width] = current;
            for (int n = width + 1; n <= totalDays; n++) {
                current = current.multiply(BigInteger.valueOf(n))
                    .divide(BigInteger.valueOf(n - width));
                column[n] = current;
            }
            binomialColumns.put(width, column);
            return column;
        }
    }

    private BigInteger countSuffix(State state) {
        if (state.closed == lengths.length) return ONE;
        SuffixKey key = new SuffixKey(state);
        synchronized (suffixCounts) {
            BigInteger found = suffixCounts.get(key);
            if (found != null) {
                suffixCacheHits++;
                return found;
            }
        }
        BigInteger result = countSuffixUncached(state);
        synchronized (suffixCounts) {
            suffixCounts.put(key, result);
        }
        return result;
    }

    private static BigInteger combinations(int total, int choose) {
        int width = Math.min(choose, total - choose);
        BigInteger result = ONE;
        for (int n = 1; n <= width; n++) {
            result = result.multiply(BigInteger.valueOf(total - width + n))
                .divide(BigInteger.valueOf(n));
        }
        return result;
    }

    private BigInteger countSuffixUncached(State state) {
        PartialDP partial = cachedPartial(state);
        int days;
        BigInteger[] previous;
        BigInteger previousTotal;
        int nextMonth;
        if (partial == null) {
            days = state.remaining[state.closed];
            previous = new BigInteger[days + 2];
            previous[1] = ONE;
            previousTotal = ONE;
            nextMonth = state.closed + 1;
        } else {
            days = partial.days;
            previous = partial.previous;
            previousTotal = partial.previousTotal;
            nextMonth = partial.lastMonth + 1;
        }

        for (int month = nextMonth; month < lengths.length; month++) {
            int additional = state.remaining[month];
            if (additional < 1) throw new IllegalStateException("E_WEAVE_STATE");
            int newDays = days + additional;
            boolean enforceOpen = month - 1 >= state.opened;
            boolean snapshotNeeded = newDays <= MAX_PARTIAL_DP_DAYS
                && (month == state.closed + 7 || month == state.closed + 15);
            boolean nextMonthEnforcesOpen = month >= state.opened;
            if (!enforceOpen && !snapshotNeeded
                    && !nextMonthEnforcesOpen) {
                previousTotal = previousTotal.multiply(
                    combinations(newDays - 1, additional - 1));
                days = newDays;
                synchronized (partialDps) {
                    closedFormTransitions++;
                }
                continue;
            }
            BigInteger[] next = new BigInteger[newDays + 2];
            BigInteger newTotal = ZERO;

            if (additional == 1) {
                next[days + 1] = previousTotal;
                newTotal = previousTotal;
            } else {
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
            keepPartial(state, month, days, previous, previousTotal);
        }
        return previousTotal;
    }

    public synchronized BigInteger count() {
        if (rootCount == null) rootCount = countSuffix(new State(lengths));
        return rootCount;
    }



    private static final class TailFunctional {
        final int cut;
        final int[] remainingTail;
        final int maximumPrefixDays;
        final BigInteger[] distanceWeights;

        TailFunctional(State parent, int cut, int maximumPrefixDays,
                BigInteger[] distanceWeights) {
            this.cut = cut;
            remainingTail = Arrays.copyOfRange(parent.remaining,
                cut, parent.remaining.length);
            this.maximumPrefixDays = maximumPrefixDays;
            this.distanceWeights = distanceWeights;
        }

        boolean matches(State parent, int cut, int prefixDays) {
            if (this.cut != cut || prefixDays > maximumPrefixDays) {
                return false;
            }
            for (int m = cut; m < parent.remaining.length; m++) {
                if (remainingTail[m - cut] != parent.remaining[m]) {
                    return false;
                }
            }
            return true;
        }
    }

    private final Object tailFunctionalLock = new Object();
    private TailFunctional cachedTailFunctional;
    private long tailFunctionalReuseHits;
    private long tailFunctionalBuilds;
    private long tailFunctionalBuildNanos;
    private long siblingPrefixDotNanos;
    private long siblingPrefixDotCalls;
    private long siblingPrefixMonthTransitions;
    private long siblingPrefixClosedFormTransitions;
    private long siblingPrefixSharedWeightHits;
    private long siblingScalarBatchBuilds;

    long tailFunctionalReuseHitCount() {
        synchronized (tailFunctionalLock) {
            return tailFunctionalReuseHits;
        }
    }

    long tailFunctionalBuildCount() {
        synchronized (tailFunctionalLock) {
            return tailFunctionalBuilds;
        }
    }

    long tailFunctionalBuildElapsedNanos() {
        synchronized (tailFunctionalLock) {
            return tailFunctionalBuildNanos;
        }
    }

    long siblingPrefixDotElapsedNanos() {
        synchronized (tailFunctionalLock) {
            return siblingPrefixDotNanos;
        }
    }

    long siblingPrefixDotCallCount() {
        synchronized (tailFunctionalLock) {
            return siblingPrefixDotCalls;
        }
    }

    long siblingPrefixMonthTransitionCount() {
        synchronized (tailFunctionalLock) {
            return siblingPrefixMonthTransitions;
        }
    }

    long siblingPrefixClosedFormTransitionCount() {
        synchronized (tailFunctionalLock) {
            return siblingPrefixClosedFormTransitions;
        }
    }

    long siblingPrefixSharedWeightHitCount() {
        synchronized (tailFunctionalLock) {
            return siblingPrefixSharedWeightHits;
        }
    }

    long siblingScalarBatchBuildCount() {
        synchronized (tailFunctionalLock) {
            return siblingScalarBatchBuilds;
        }
    }

    private BigInteger unconstrainedPrefixTotal(State child, int cut) {
        int days = child.remaining[child.closed];
        BigInteger total = ONE;
        for (int month = child.closed + 1; month < cut; month++) {
            int additional = child.remaining[month];
            int newDays = days + additional;
            total = total.multiply(
                combinations(newDays - 1, additional - 1));
            days = newDays;
        }
        return total;
    }

    private BigInteger[] unconstrainedSiblingScalars(State parent) {
        int cut = parent.opened;
        int closed = parent.closed;
        BigInteger[] scalars = new BigInteger[cut];
        if (closed >= cut) return scalars;
        int[] days = new int[cut];
        int running = 0;
        for (int month = closed; month < cut; month++) {
            running += parent.remaining[month];
            days[month] = running;
        }
        BigInteger base = unconstrainedPrefixTotal(parent, cut);
        BigInteger suffixNumerator = ONE;
        BigInteger suffixDenominator = ONE;
        for (int month = cut - 1; month >= closed; month--) {
            BigInteger numerator = base.multiply(suffixNumerator);
            BigInteger denominator = suffixDenominator;
            if (month > closed) {
                numerator = numerator.multiply(
                    BigInteger.valueOf(parent.remaining[month] - 1));
                denominator = denominator.multiply(
                    BigInteger.valueOf(days[month] - 1));
            }
            BigInteger[] quotient = numerator.divideAndRemainder(denominator);
            if (quotient[1].signum() != 0) {
                throw new IllegalStateException(
                    "E_WEAVE_SIBLING_SCALAR_RATIO");
            }
            scalars[month] = quotient[0];
            if (month > closed) {
                suffixNumerator = suffixNumerator.multiply(
                    BigInteger.valueOf(days[month]
                        - parent.remaining[month]));
                suffixDenominator = suffixDenominator.multiply(
                    BigInteger.valueOf(days[month] - 1));
            }
        }
        synchronized (tailFunctionalLock) {
            siblingScalarBatchBuilds++;
        }
        return scalars;
    }

    private TailFunctional commonSiblingTail(State parent,
            int cut, int prefixDays) {
        synchronized (tailFunctionalLock) {
            if (cachedTailFunctional != null
                    && cachedTailFunctional.matches(parent, cut, prefixDays)) {
                tailFunctionalReuseHits++;
                return cachedTailFunctional;
            }
        }
        long started = System.nanoTime();
        int fullDays = prefixDays;
        for (int month = cut; month < lengths.length; month++) {
            fullDays += parent.remaining[month];
        }
        BigInteger[] current = new BigInteger[fullDays + 1];
        Arrays.fill(current, ONE);
        for (int month = lengths.length - 1; month >= cut; month--) {
            int additional = parent.remaining[month];
            int oldDays = fullDays - additional;
            BigInteger[] prior = new BigInteger[oldDays + 1];
            if (additional == 1) {
                Arrays.fill(prior, current[1]);
            } else {
                BigInteger[] binomial = chooseColumn(fullDays, additional - 2);
                BigInteger running = ZERO;
                prior[0] = ZERO;
                for (int distance = 1; distance <= oldDays; distance++) {
                    int offset = distance - 1;
                    BigInteger weight = current[offset + additional];
                    if (weight != null && weight.signum() > 0) {
                        running = running.add(weight.multiply(
                            binomial[additional - 2 + offset]));
                    }
                    prior[distance] = running;
                }
            }
            current = prior;
            fullDays = oldDays;
        }
        TailFunctional built = new TailFunctional(
            parent, cut, prefixDays, current);
        synchronized (tailFunctionalLock) {
            cachedTailFunctional = built;
            tailFunctionalBuilds++;
            tailFunctionalBuildNanos += System.nanoTime() - started;
        }
        return built;
    }

    private BigInteger siblingPrefixDot(State child, int cut,
            TailFunctional coefficient) {
        long started = System.nanoTime();
        long monthTransitions = 0;
        long closedFormTransitions = 0;
        int days = child.remaining[child.closed];
        BigInteger[] previous = new BigInteger[days + 2];
        previous[1] = ONE;
        BigInteger previousTotal = ONE;
        for (int month = child.closed + 1; month < cut; month++) {
            monthTransitions++;
            int additional = child.remaining[month];
            int newDays = days + additional;
            boolean enforceOpen = month - 1 >= child.opened;
            boolean nextNeedsDistribution =
                month == cut - 1 || month >= child.opened;
            if (!enforceOpen && !nextNeedsDistribution) {
                previousTotal = previousTotal.multiply(
                    combinations(newDays - 1, additional - 1));
                days = newDays;
                closedFormTransitions++;
                continue;
            }
            BigInteger[] next = new BigInteger[newDays + 2];
            BigInteger newTotal = ZERO;
            if (additional == 1) {
                next[days + 1] = previousTotal;
                newTotal = previousTotal;
            } else {
                BigInteger[] binomial = chooseColumn(newDays, additional - 2);
                BigInteger eligible = enforceOpen ? ZERO : previousTotal;
                for (int first = 1; first <= days + 1; first++) {
                    if (enforceOpen && first > 1) {
                        BigInteger earlier = previous[first - 1];
                        if (earlier != null) eligible = eligible.add(earlier);
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
        if (days > coefficient.maximumPrefixDays) {
            throw new IllegalStateException("E_WEAVE_SIBLING_SHAPE");
        }
        BigInteger total = ZERO;
        for (int i = 1; i <= days + 1; i++) {
            BigInteger weight = coefficient.distanceWeights[days + 1 - i];
            if (previous[i] != null && weight != null) {
                total = total.add(previous[i].multiply(weight));
            }
        }
        synchronized (tailFunctionalLock) {
            siblingPrefixDotCalls++;
            siblingPrefixDotNanos += System.nanoTime() - started;
            siblingPrefixMonthTransitions += monthTransitions;
            siblingPrefixClosedFormTransitions += closedFormTransitions;
        }
        return total;
    }

    BigInteger[] countSiblingBranchSizes(int[] prefix) {
        return countSiblingBranchSizes(afterPrefix(prefix));
    }

    private BigInteger[] countSiblingBranchSizes(State parent) {
        BigInteger[] branchSizes = new BigInteger[lengths.length];
        Arrays.fill(branchSizes, ZERO);
        if (parent.closed == lengths.length) return branchSizes;
        if (parent.opened == lengths.length) {
            BigInteger[] scalars = unconstrainedSiblingScalars(parent);
            for (int month = parent.closed; month < lengths.length; month++) {
                if (parent.canTake(month, lengths)) {
                    branchSizes[month] = scalars[month];
                }
            }
            return branchSizes;
        }
        int cut = Math.min(lengths.length, parent.opened + 2);
        int prefixDays = -1;
        for (int month = parent.closed; month < cut; month++) {
            prefixDays += parent.remaining[month];
        }
        TailFunctional coefficient = commonSiblingTail(parent, cut, prefixDays);
        BigInteger sharedWeight = null;
        BigInteger[] sharedScalars = null;
        for (int month = parent.closed; month < lengths.length; month++) {
            if (!parent.canTake(month, lengths)) continue;
            State child = new State(parent);
            child.take(month, lengths);
            if (child.closed == lengths.length) {
                branchSizes[month] = ONE;
            } else if (month < parent.opened) {
                if (sharedScalars == null) {
                    sharedScalars = unconstrainedSiblingScalars(parent);
                }
                BigInteger scalar = sharedScalars[month];
                if (sharedWeight == null) {
                    BigInteger direct =
                        siblingPrefixDot(child, cut, coefficient);
                    BigInteger[] quotient = direct.divideAndRemainder(scalar);
                    if (quotient[1].signum() != 0) {
                        throw new IllegalStateException(
                            "E_WEAVE_SIBLING_SHARED_RATIO");
                    }
                    sharedWeight = quotient[0];
                    branchSizes[month] = direct;
                } else {
                    branchSizes[month] = sharedWeight.multiply(scalar);
                    synchronized (tailFunctionalLock) {
                        siblingPrefixSharedWeightHits++;
                    }
                }
            } else {
                branchSizes[month] =
                    siblingPrefixDot(child, cut, coefficient);
            }
        }
        return branchSizes;
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



    public static final class RankRoute {
        private final MonsterWeavingLinearCounter owner;
        private final State state;
        private final int[] prefix;
        private final BigInteger globalRank;
        private final BigInteger lower;
        private final BigInteger upper;
        private final int suffixTargetDays;
        private final int lastCountCalls;
        private final int lastSharedBatchCalls;
        private final int probedBranches;
        private final BigInteger skippedChoices;

        private RankRoute(MonsterWeavingLinearCounter owner, State state,
                int[] prefix, BigInteger globalRank, BigInteger lower,
                BigInteger upper, int suffixTargetDays, int lastCountCalls) {
            this(owner, state, prefix, globalRank, lower, upper,
                suffixTargetDays, lastCountCalls, 0, ZERO);
        }

        private RankRoute(MonsterWeavingLinearCounter owner, State state,
                int[] prefix, BigInteger globalRank, BigInteger lower,
                BigInteger upper, int suffixTargetDays, int lastCountCalls,
                int probedBranches, BigInteger skippedChoices) {
            this(owner, state, prefix, globalRank, lower, upper,
                suffixTargetDays, lastCountCalls, probedBranches,
                skippedChoices, 0);
        }

        private RankRoute(MonsterWeavingLinearCounter owner, State state,
                int[] prefix, BigInteger globalRank, BigInteger lower,
                BigInteger upper, int suffixTargetDays, int lastCountCalls,
                int probedBranches, BigInteger skippedChoices,
                int lastSharedBatchCalls) {
            this.owner = owner;
            this.state = new State(state);
            this.prefix = prefix.clone();
            this.globalRank = globalRank;
            this.lower = lower;
            this.upper = upper;
            this.suffixTargetDays = suffixTargetDays;
            this.lastCountCalls = lastCountCalls;
            this.lastSharedBatchCalls = lastSharedBatchCalls;
            this.probedBranches = probedBranches;
            this.skippedChoices = skippedChoices;
        }

        public int[] fixedPrefixCopy() { return prefix.clone(); }
        public BigInteger globalRank() { return globalRank; }
        public BigInteger lowerRank() { return lower; }
        public BigInteger upperRank() { return upper; }
        public BigInteger localRank() { return globalRank.subtract(lower).add(ONE); }
        public BigInteger remainingChoices() { return upper.subtract(lower).add(ONE); }
        public int remainingDays() { return owner.totalDays - prefix.length; }
        public int stepsCompleted() { return prefix.length; }
        public int suffixTargetDays() { return suffixTargetDays; }
        public int lastCountCalls() { return lastCountCalls; }
        public int lastSharedBatchCalls() { return lastSharedBatchCalls; }
        public int probedBranches() { return probedBranches; }
        public BigInteger skippedChoices() { return skippedChoices; }
        public boolean complete() { return remainingDays() <= suffixTargetDays; }
    }

    private static void validateRouteBudgets(int steps, int counts) {
        if (steps < 0 || steps > MAX_ROUTE_STEPS_PER_CALL
                || counts < 0 || counts > MAX_ROUTE_BRANCH_COUNTS_PER_CALL) {
            throw new IllegalArgumentException("E_WEAVE_ROUTE_BUDGET");
        }
    }

    public RankRoute beginGlobalRankRoute(BigInteger globalRank, int targetSuffixDays) {
        if (targetSuffixDays < 0 || targetSuffixDays > MAX_UNRANK_DAYS
                || targetSuffixDays > totalDays) {
            throw new IllegalArgumentException("E_WEAVE_ROUTE_TARGET");
        }
        BigInteger total = count();
        if (globalRank == null || globalRank.signum() <= 0
                || globalRank.compareTo(total) > 0) {
            throw new IllegalArgumentException("E_WEAVE_RANK");
        }
        if (totalDays > MAX_UNRANK_DAYS
                && targetSuffixDays == MAX_UNRANK_DAYS) {
            BoundaryBlock first = defaultBoundary(false);
            if (first.contains(globalRank)) {
                int[] prefix = first.fixedPrefixCopy();
                return new RankRoute(this, afterPrefix(prefix), prefix,
                    globalRank, first.lowerRank(), first.upperRank(),
                    targetSuffixDays, 0);
            }
            BoundaryBlock last = defaultBoundary(true);
            if (last.contains(globalRank)) {
                int[] prefix = last.fixedPrefixCopy();
                return new RankRoute(this, afterPrefix(prefix), prefix,
                    globalRank, last.lowerRank(), last.upperRank(),
                    targetSuffixDays, 0);
            }
        }
        return new RankRoute(this, new State(lengths), new int[0],
            globalRank, ONE, total, targetSuffixDays, 0);
    }


    public RankRoute beginGlobalRankRouteWithinPrefix(
            int[] fixedPrefix, BigInteger globalRank, int targetSuffixDays) {
        if (targetSuffixDays < 0 || targetSuffixDays > MAX_UNRANK_DAYS
                || targetSuffixDays > totalDays) {
            throw new IllegalArgumentException("E_WEAVE_ROUTE_TARGET");
        }
        BoundaryBlock block = globalBlockForPrefix(fixedPrefix);
        if (!block.contains(globalRank)) {
            throw new IllegalArgumentException("E_WEAVE_GLOBAL_RANK");
        }
        return new RankRoute(this, afterPrefix(fixedPrefix), fixedPrefix,
            globalRank, block.lowerRank(), block.upperRank(), targetSuffixDays, 0);
    }


    private int[] extremeFromRoute(RankRoute route, boolean latest) {
        int[] result = Arrays.copyOf(route.prefix, totalDays);
        State state = new State(route.state);
        for (int pos = route.prefix.length; pos < totalDays; pos++) {
            int chosen = -1;
            if (latest) {
                for (int month = lengths.length - 1; month >= state.closed; month--) {
                    if (state.canTake(month, lengths)) {
                        chosen = month;
                        break;
                    }
                }
            } else {
                for (int month = state.closed; month < lengths.length; month++) {
                    if (state.canTake(month, lengths)) {
                        chosen = month;
                        break;
                    }
                }
            }
            if (chosen < 0) throw new IllegalStateException("E_WEAVE_ROUTE_EXTREME");
            result[pos] = chosen + 1;
            state.take(chosen, lengths);
        }
        return result;
    }

    private RankRoute advanceNearEdge(RankRoute route, int maximumSteps,
            boolean fromLast, int distance) {
        int stop = Math.min(totalDays - route.suffixTargetDays,
            route.prefix.length + maximumSteps);
        int[][] neighbors = new int[distance + 1][];
        neighbors[0] = extremeFromRoute(route, fromLast);
        for (int i = 1; i <= distance; i++) {
            neighbors[i] = fromLast
                ? lexPrevious(neighbors[i - 1]) : lexNext(neighbors[i - 1]);
            if (neighbors[i] == null || !sharesPrefix(neighbors[i], route.prefix)) {
                throw new IllegalStateException("E_WEAVE_ROUTE_EDGE");
            }
        }
        int[] witness = neighbors[distance];
        int[] chosenPrefix = Arrays.copyOf(witness, stop);
        int firstShared = -1;
        for (int i = 0; i <= distance; i++) {
            if (sharesPrefix(neighbors[i], chosenPrefix)) {
                firstShared = i;
                break;
            }
        }
        if (firstShared < 0) throw new IllegalStateException("E_WEAVE_ROUTE_EDGE");
        State state = new State(route.state);
        for (int pos = route.prefix.length; pos < stop; pos++) {
            state.take(witness[pos] - 1, lengths);
        }
        BigInteger remaining = countSuffix(state);
        BigInteger lower = fromLast
            ? route.upper.subtract(BigInteger.valueOf(firstShared))
                .subtract(remaining).add(ONE)
            : route.lower.add(BigInteger.valueOf(firstShared));
        BigInteger upper = lower.add(remaining).subtract(ONE);
        if (lower.compareTo(route.globalRank) > 0
                || upper.compareTo(route.globalRank) < 0
                || lower.compareTo(route.lower) < 0
                || upper.compareTo(route.upper) > 0) {
            throw new IllegalStateException("E_WEAVE_ROUTE_EDGE_INTERVAL");
        }
        return new RankRoute(this, state, chosenPrefix, route.globalRank,
            lower, upper, route.suffixTargetDays, 1);
    }


    public RankRoute advanceGlobalRankRouteShared(RankRoute previous,
            int maximumSteps, int maximumSharedBatches) {
        if (previous == null || previous.owner != this) {
            throw new IllegalArgumentException("E_WEAVE_ROUTE_OWNER");
        }
        validateRouteBudgets(maximumSteps, maximumSharedBatches);
        State state = new State(previous.state);
        int[] prefix = Arrays.copyOf(previous.prefix,
            Math.min(totalDays, previous.prefix.length + maximumSteps));
        int size = previous.prefix.length;
        BigInteger lower = previous.lower;
        BigInteger blockSize = previous.upper.subtract(previous.lower).add(ONE);
        int probed = previous.probedBranches;
        BigInteger skipped = previous.skippedChoices;
        int batches = 0;
        int advanced = 0;
        while (totalDays - size > previous.suffixTargetDays
                && advanced < maximumSteps && batches < maximumSharedBatches) {
            BigInteger[] sizes = countSiblingBranchSizes(state);
            batches++;
            int[] eligible = new int[lengths.length];
            int options = 0;
            BigInteger partition = ZERO;
            for (int month = state.closed; month < lengths.length; month++) {
                if (!state.canTake(month, lengths)) continue;
                eligible[options++] = month;
                partition = partition.add(sizes[month]);
            }
            if (options == 0 || probed >= options
                    || !partition.equals(blockSize)) {
                throw new IllegalStateException("E_WEAVE_ROUTE_SHARED_PARTITION");
            }
            boolean chosen = false;
            for (int i = probed; i < options; i++) {
                int month = eligible[i];
                BigInteger possibilities = sizes[month];
                if (possibilities.signum() <= 0) {
                    throw new IllegalStateException("E_WEAVE_ROUTE_SHARED_BRANCH");
                }
                BigInteger start = lower.add(skipped);
                BigInteger end = start.add(possibilities);
                if (previous.globalRank.compareTo(end) < 0) {
                    State candidate = new State(state);
                    candidate.take(month, lengths);
                    state = candidate;
                    prefix[size++] = month + 1;
                    lower = start;
                    blockSize = possibilities;
                    probed = 0;
                    skipped = ZERO;
                    advanced++;
                    chosen = true;
                    break;
                }
                skipped = skipped.add(possibilities);
            }
            if (!chosen) {
                throw new IllegalStateException("E_WEAVE_ROUTE_SHARED_RANK");
            }
        }
        return new RankRoute(this, state, Arrays.copyOf(prefix, size),
            previous.globalRank, lower, lower.add(blockSize).subtract(ONE),
            previous.suffixTargetDays, 0, probed, skipped, batches);
    }

    public RankRoute advanceGlobalRankRoute(RankRoute previous,
            int maximumSteps, int maximumBranchCounts) {
        if (previous == null || previous.owner != this) {
            throw new IllegalArgumentException("E_WEAVE_ROUTE_OWNER");
        }
        validateRouteBudgets(maximumSteps, maximumBranchCounts);
        if (maximumSteps > 0 && maximumBranchCounts >= 1
                && !previous.complete() && previous.probedBranches == 0) {
            BigInteger fromFirst = previous.globalRank.subtract(previous.lower);
            BigInteger fromLast = previous.upper.subtract(previous.globalRank);
            BigInteger edge = BigInteger.valueOf(MAX_EDGE_DISTANCE);
            if (fromFirst.compareTo(edge) <= 0) {
                return advanceNearEdge(previous, maximumSteps,
                    false, fromFirst.intValueExact());
            }
            if (fromLast.compareTo(edge) <= 0) {
                return advanceNearEdge(previous, maximumSteps,
                    true, fromLast.intValueExact());
            }
        }
        State state = new State(previous.state);
        int[] prefix = Arrays.copyOf(previous.prefix,
            Math.min(totalDays, previous.prefix.length + maximumSteps));
        int size = previous.prefix.length;
        BigInteger lower = previous.lower;
        BigInteger blockSize = previous.upper.subtract(previous.lower).add(ONE);
        int countCalls = 0;
        int advanced = 0;
        int probed = previous.probedBranches;
        BigInteger skipped = previous.skippedChoices;
        boolean budgetReached = false;
        while (totalDays - size > previous.suffixTargetDays
                && advanced < maximumSteps && !budgetReached) {
            int[] eligible = new int[lengths.length];
            int options = 0;
            for (int month = state.closed; month < lengths.length; month++) {
                if (state.canTake(month, lengths)) eligible[options++] = month;
            }
            if (options == 0 || probed >= options) {
                throw new IllegalStateException("E_WEAVE_ROUTE_STATE");
            }
            boolean selected = false;
            for (int i = probed; i < options; i++) {
                if (i < options - 1 && countCalls >= maximumBranchCounts) {
                    probed = i;
                    budgetReached = true;
                    break;
                }
                int month = eligible[i];
                State trial = new State(state);
                trial.take(month, lengths);
                BigInteger sizeOfBranch;
                if (i == options - 1) {
                    sizeOfBranch = blockSize.subtract(skipped);
                } else {
                    sizeOfBranch = countSuffix(trial);
                    countCalls++;
                }
                if (sizeOfBranch.signum() <= 0) {
                    throw new IllegalStateException("E_WEAVE_ROUTE_BRANCH");
                }
                BigInteger start = lower.add(skipped);
                BigInteger end = start.add(sizeOfBranch);
                if (previous.globalRank.compareTo(end) < 0) {
                    lower = start;
                    blockSize = sizeOfBranch;
                    state = trial;
                    prefix[size] = month + 1;
                    size++;
                    advanced++;
                    probed = 0;
                    skipped = ZERO;
                    selected = true;
                    break;
                }
                skipped = skipped.add(sizeOfBranch);
                probed = i + 1;
            }
            if (!selected && !budgetReached) {
                throw new IllegalStateException("E_WEAVE_ROUTE_RANK");
            }
        }
        return new RankRoute(this, state, Arrays.copyOf(prefix, size),
            previous.globalRank, lower, lower.add(blockSize).subtract(ONE),
            previous.suffixTargetDays, countCalls, probed, skipped);
    }

    public int[] finishGlobalRankRoute(RankRoute route) {
        if (route == null || route.owner != this) {
            throw new IllegalArgumentException("E_WEAVE_ROUTE_OWNER");
        }
        if (!route.complete()) {
            throw new IllegalArgumentException("E_WEAVE_ROUTE_INCOMPLETE");
        }
        return unrankAfterPrefix(route.fixedPrefixCopy(), route.localRank());
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
