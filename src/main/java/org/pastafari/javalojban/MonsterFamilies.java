package org.pastafari.javalojban;

import java.math.BigInteger;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public final class MonsterFamilies {
    private static final BigInteger ZERO = BigInteger.ZERO;
    private static final BigInteger ONE = BigInteger.ONE;

    private MonsterFamilies() {}

    public static BigInteger fallingFactorial(int n, int k) {
        if (n < 0 || k < 0 || k > n) throw new IllegalArgumentException("E_FALLING");
        BigInteger result = ONE;
        for (int j = 0; j < k; j++) result = result.multiply(BigInteger.valueOf(n - j));
        return result;
    }

    public static int[] unrankDistinctIndices(int masterSize, int count, BigInteger rank) {
        if (masterSize < 0 || count < 0 || count > masterSize) {
            throw new IllegalArgumentException("E_NAME_SIZE");
        }
        BigInteger total = fallingFactorial(masterSize, count);
        if (rank == null || rank.signum() <= 0 || rank.compareTo(total) > 0) {
            throw new IllegalArgumentException("E_NAME_RANK");
        }
        int[] available = new int[masterSize];
        for (int i = 0; i < masterSize; i++) available[i] = i + 1;
        int[] result = new int[count];
        BigInteger zeroRank = rank.subtract(ONE);
        for (int index = 0; index < count; index++) {
            BigInteger block = fallingFactorial(masterSize - index - 1, count - index - 1);
            BigInteger[] qr = zeroRank.divideAndRemainder(block);
            int selected = qr[0].intValueExact();
            result[index] = available[selected];
            int remaining = masterSize - index;
            System.arraycopy(available, selected + 1, available, selected, remaining - selected - 1);
            zeroRank = qr[1];
        }
        return result;
    }

    private static BigInteger binomial(int n, int k) {
        if (n < 0 || k < 0 || k > n) return ZERO;
        k = Math.min(k, n - k);
        BigInteger answer = ONE;
        for (int j = 1; j <= k; j++) {
            answer = answer.multiply(BigInteger.valueOf(n - j + 1))
                .divide(BigInteger.valueOf(j));
        }
        return answer;
    }

    public static final class BoundedCompositionFamily {
        private final int total;
        private final int slots;
        private final int lower;
        private final int upper;
        private final BigInteger[][] ways;

        public BoundedCompositionFamily(int total, int slots, int lower, int upper) {
            if (total < 0 || slots < 0 || lower < 0 || upper < lower) {
                throw new IllegalArgumentException("E_COMP_BOUNDS");
            }
            this.total = total;
            this.slots = slots;
            this.lower = lower;
            this.upper = upper;
            ways = new BigInteger[slots + 1][total + 1];
            Arrays.fill(ways[0], ZERO);
            ways[0][0] = ONE;
            for (int count = 1; count <= slots; count++) {
                BigInteger window = ZERO;
                for (int sum = 0; sum <= total; sum++) {
                    if (sum >= lower) window = window.add(ways[count - 1][sum - lower]);
                    if (sum > upper) window = window.subtract(ways[count - 1][sum - upper - 1]);
                    ways[count][sum] = window;
                }
            }
        }

        private BigInteger suffix(int remaining, int count) {
            if (remaining < 0 || remaining > total || count < 0 || count > slots) return ZERO;
            return ways[count][remaining];
        }

        public BigInteger count() {
            return suffix(total, slots);
        }

        public int[] unrank1(BigInteger rank) {
            if (rank == null || rank.signum() <= 0 || rank.compareTo(count()) > 0) {
                throw new IllegalArgumentException("E_COMP_RANK");
            }
            int[] chosen = new int[slots];
            int remaining = total;
            BigInteger r = rank;
            for (int index = 0; index < slots; index++) {
                boolean found = false;
                for (int value = lower; value <= upper; value++) {
                    BigInteger block = suffix(remaining - value, slots - index - 1);
                    if (r.compareTo(block) > 0) {
                        r = r.subtract(block);
                    } else {
                        chosen[index] = value;
                        remaining -= value;
                        found = true;
                        break;
                    }
                }
                if (!found) throw new IllegalStateException("E_COMP_UNRANK");
            }
            return chosen;
        }
    }

    public static final class CutletPartitionFamily {
        private final int total;
        private final int slots;
        private final Integer required;

        public CutletPartitionFamily(int total, int slots, Integer required) {
            if (total < 1 || slots < 1 || (required != null && (required <= 0 || required >= total))) {
                throw new IllegalArgumentException("E_CUTLET_BOUNDS");
            }
            this.total = total;
            this.slots = slots;
            this.required = required;
        }

        private static BigInteger compositions(int remaining, int count) {
            if (count == 0) return remaining == 0 ? ONE : ZERO;
            return remaining >= count ? binomial(remaining - 1, count - 1) : ZERO;
        }

        private BigInteger suffix(int remaining, int count, int cumulative, boolean hit) {
            if (remaining < count || count < 0) return ZERO;
            if (required == null || hit) return compositions(remaining, count);
            int prefix = required - cumulative;
            if (prefix < 1 || prefix >= remaining) return ZERO;
            BigInteger sum = ZERO;
            for (int leftSlots = 1; leftSlots < count; leftSlots++) {
                BigInteger a = compositions(prefix, leftSlots);
                BigInteger b = compositions(remaining - prefix, count - leftSlots);
                sum = sum.add(a.multiply(b));
            }
            return sum;
        }

        public BigInteger count() {
            return suffix(total, slots, 0, false);
        }

        public int[] unrank1(BigInteger rank) {
            if (rank == null || rank.signum() <= 0 || rank.compareTo(count()) > 0) {
                throw new IllegalArgumentException("E_CUTLET_PARTITION_RANK");
            }
            int[] result = new int[slots];
            int remaining = total;
            int sum = 0;
            boolean hit = false;
            BigInteger r = rank;
            for (int index = 0; index < slots; index++) {
                int leftSlots = slots - index;
                boolean found = false;
                for (int value = 1; value <= remaining - leftSlots + 1; value++) {
                    int nextSum = sum + value;
                    if (required != null && !hit && nextSum > required) break;
                    boolean nextHit = hit || required != null && nextSum == required;
                    BigInteger block = suffix(remaining - value, leftSlots - 1, nextSum, nextHit);
                    if (r.compareTo(block) > 0) {
                        r = r.subtract(block);
                    } else {
                        result[index] = value;
                        remaining -= value;
                        sum = nextSum;
                        hit = nextHit;
                        found = true;
                        break;
                    }
                }
                if (!found) throw new IllegalStateException("E_CUTLET_UNRANK");
            }
            return result;
        }
    }

    public static final class WeavingFamily {
        private final int[] lengths;
        private final int total;

        private static final class Key {
            private final int[] remaining;
            private final int opened;
            private final int closed;
            private final int hash;

            private Key(int[] remaining, int opened, int closed) {
                this.remaining = remaining.clone();
                this.opened = opened;
                this.closed = closed;
                this.hash = (31 * Arrays.hashCode(this.remaining) + opened) * 31 + closed;
            }

            @Override public boolean equals(Object other) {
                return other instanceof Key key
                    && opened == key.opened && closed == key.closed
                    && Arrays.equals(remaining, key.remaining);
            }

            @Override public int hashCode() {
                return hash;
            }
        }

        public WeavingFamily(int[] values) {
            if (values == null || values.length == 0) {
                throw new IllegalArgumentException("E_WEAVE_EMPTY");
            }
            int t = 0;
            for (int x : values) {
                if (x < 1) throw new IllegalArgumentException("E_WEAVE_LENGTH");
                t = Math.addExact(t, x);
            }
            lengths = values.clone();
            total = t;
        }

        private boolean legal(int[] remaining, int opened, int closed, int id) {
            if (remaining[id] == 0) return false;
            if (remaining[id] == lengths[id] && id != opened) return false;
            return remaining[id] != 1 || id == closed;
        }

        private BigInteger suffix(int[] remaining, int opened, int closed,
                                  Map<Key, BigInteger> memo) {
            boolean done = true;
            for (int count : remaining) {
                if (count != 0) {
                    done = false;
                    break;
                }
            }
            if (done) return ONE;
            Key key = new Key(remaining, opened, closed);
            BigInteger cached = memo.get(key);
            if (cached != null) return cached;
            BigInteger sum = ZERO;
            for (int id = 0; id < lengths.length; id++) {
                if (!legal(remaining, opened, closed, id)) continue;
                int[] after = remaining.clone();
                boolean opening = after[id] == lengths[id];
                after[id]--;
                boolean closing = after[id] == 0;
                sum = sum.add(suffix(after, opening ? id + 1 : opened,
                    closing ? id + 1 : closed, memo));
            }
            memo.put(key, sum);
            return sum;
        }

        public BigInteger count() {
            return suffix(lengths.clone(), 0, 0, new HashMap<>());
        }

        public int[] unrank1(BigInteger rank) {
            Map<Key, BigInteger> memo = new HashMap<>();
            int[] remaining = lengths.clone();
            BigInteger count = suffix(remaining, 0, 0, memo);
            if (rank == null || rank.signum() <= 0 || rank.compareTo(count) > 0) {
                throw new IllegalArgumentException("E_WEAVE_RANK");
            }
            int[] sequence = new int[total];
            int opened = 0;
            int closed = 0;
            BigInteger r = rank;
            for (int position = 0; position < total; position++) {
                boolean found = false;
                for (int id = 0; id < lengths.length; id++) {
                    if (!legal(remaining, opened, closed, id)) continue;
                    int[] after = remaining.clone();
                    boolean opening = after[id] == lengths[id];
                    after[id]--;
                    boolean closing = after[id] == 0;
                    int nextOpened = opening ? id + 1 : opened;
                    int nextClosed = closing ? id + 1 : closed;
                    BigInteger block = suffix(after, nextOpened, nextClosed, memo);
                    if (r.compareTo(block) > 0) {
                        r = r.subtract(block);
                    } else {
                        sequence[position] = id + 1;
                        remaining = after;
                        opened = nextOpened;
                        closed = nextClosed;
                        found = true;
                        break;
                    }
                }
                if (!found) throw new IllegalStateException("E_WEAVE_UNRANK");
            }
            return sequence;
        }
    }
}
