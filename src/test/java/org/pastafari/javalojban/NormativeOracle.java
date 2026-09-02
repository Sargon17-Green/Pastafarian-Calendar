package org.pastafari.javalojban;

import java.math.BigInteger;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Comparator;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

public final class NormativeOracle {
    public static final BigInteger ZERO = BigInteger.ZERO;
    public static final BigInteger ONE = BigInteger.ONE;
    public static final BigInteger TWO = BigInteger.TWO;
    public static final BigInteger M = TWO.pow(127).subtract(ONE);
    public static final BigInteger TABLETS_DAY = BigInteger.valueOf(-278522L);
    public static final BigInteger FOUNDATION_DAY = BigInteger.valueOf(-15055671L);
    public static final int GATE_GAP_MIN = 42;
    public static final int GATE_GAP_MAX = 963;
    public static final int YEAR_MIN_DAYS = 252;
    public static final int YEAR_MAX_DAYS = 5778;
    public static final int MIN_CUTLETS = 6;
    public static final int MAX_CUTLETS = 17;
    public static final int MIN_MONTHS = 3;
    public static final int MAX_MONTHS = 47;
    public static final int MIN_MONTH_DAYS = 4;
    public static final int MAX_MONTH_DAYS = 123;

    public static final int SEAL_GATE_GAP = 1;
    public static final int SEAL_YEAR_5000 = 10;
    public static final int SEAL_NEXT_YEAR = 11;
    public static final int SEAL_PREVIOUS_YEAR = 12;
    public static final int SEAL_CUTLET_COUNT = 20;
    public static final int SEAL_CUTLET_PARTITION = 21;
    public static final int SEAL_CUTLET_NAMES = 22;
    public static final int SEAL_MONTH_COUNT = 30;
    public static final int SEAL_MONTH_LENGTHS = 31;
    public static final int SEAL_MONTH_WEAVING = 32;
    public static final int SEAL_MONTH_NAMES = 33;

    private static final int WHEAT = 1;
    private static final int BARLEY = 2;
    private static final int SALT = 3;
    private static final int BITTER = 4;
    private static final int RED = 5;

    private static final int[][] HIDDEN_COEFF = {
        {},
        {3,4,6,8},
        {5,7,10,12},
        {7,10,14,16},
        {9,13,18,20},
        {11,16,22,24},
        {13,19,26,28},
        {15,22,30,32}
    };

    private static final int[] HIDDEN_GRIND_STONE = {0,WHEAT,BARLEY,SALT,BITTER,RED,WHEAT,BARLEY};

    private static final int[][] VISIBLE_GRINDS = {
        {},
        {3,5,7,11,WHEAT},
        {5,7,11,13,BARLEY},
        {7,11,13,17,SALT},
        {11,13,17,19,BITTER},
        {13,17,19,23,RED},
        {17,19,23,29,WHEAT},
        {19,23,29,31,BARLEY},
        {23,29,31,37,SALT},
        {29,31,37,41,BITTER},
        {31,37,41,43,RED},
        {37,41,43,47,WHEAT}
    };

    private static final int[] BOWL_PRIME = {0,17,19,23,29,31,37};
    private static final int[] BOWL_STIR_STONE_BY_POSITION = {0,WHEAT,BARLEY,SALT,BITTER,RED,WHEAT};
    private static final BigInteger[][] STONES = buildStones();

    private final GateCache gates = new GateCache();

    public record WorkCounts(BigInteger action, BigInteger target, BigInteger distance, BigInteger connection, int direction) {}
    public record SauceResult(BigInteger[] bowls, int[] orderAtDrop46) {}
    public record AnswerStream(BigInteger first, int directionStep) {}
    public record Year(BigInteger number, BigInteger openGateIndex, BigInteger closeGateIndex, BigInteger openGateDay, BigInteger closeGateDay) {}
    public record Cutlet(int canonicalNameIndex, BigInteger openGateIndex, BigInteger closeGateIndex, BigInteger firstDay, BigInteger lastDay) {}
    public record YearStructure(int cutletCount, int[] cutletPartition, int[] cutletNameIndices, List<Cutlet> cutlets, int monthCount, int[] monthLengths, int[] monthWeaving, int[] monthNameIndices) {}
    public record CalendarResult(BigInteger yearNumber, int cutletCanonicalIndex, String cutletName, BigInteger dayInCutlet, int monthCanonicalIndex, String monthName, int dayInMonth) {}

    public static BigInteger floorDiv(BigInteger a, BigInteger b) {
        if (b.signum() <= 0) throw new IllegalArgumentException("E_DIVISOR");
        BigInteger[] qr = a.divideAndRemainder(b);
        if (qr[1].signum() < 0) return qr[0].subtract(ONE);
        return qr[0];
    }

    public static BigInteger regularMod(BigInteger x, BigInteger d) {
        if (d.signum() <= 0) throw new IllegalArgumentException("E_MODULUS");
        return x.subtract(floorDiv(x, d).multiply(d));
    }

    public static BigInteger save(BigInteger x) {
        return ONE.add(regularMod(x.subtract(ONE), M));
    }

    public static BigInteger ceilDiv(BigInteger a, BigInteger b) {
        if (a.signum() < 0 || b.signum() <= 0) throw new IllegalArgumentException("E_CEILDIV");
        return floorDiv(a.add(b).subtract(ONE), b);
    }

    public static int wrap1(int position, int size) {
        if (size < 1) throw new IllegalArgumentException("E_WRAP_SIZE");
        int r = Math.floorMod(position - 1, size);
        return r + 1;
    }

    public static BigInteger dayCount(BigInteger day) {
        int cmp = day.compareTo(FOUNDATION_DAY);
        if (cmp == 0) return ONE;
        if (cmp > 0) return day.subtract(FOUNDATION_DAY).multiply(TWO).add(ONE);
        return FOUNDATION_DAY.subtract(day).multiply(TWO);
    }

    public static WorkCounts workCounts(BigInteger calculationDay, BigInteger targetDay) {
        BigInteger c = dayCount(calculationDay);
        BigInteger t = dayCount(targetDay);
        BigInteger distance = targetDay.subtract(calculationDay).abs().add(ONE);
        BigInteger connection = c.add(t);
        int direction = targetDay.compareTo(calculationDay) < 0 ? 1 : targetDay.equals(calculationDay) ? 2 : 3;
        return new WorkCounts(c,t,distance,connection,direction);
    }

    private static BigInteger[][] buildStones() {
        BigInteger[][] stone = new BigInteger[47][6];
        stone[1][WHEAT] = BigInteger.valueOf(17);
        stone[1][BARLEY] = BigInteger.valueOf(29);
        stone[1][SALT] = BigInteger.valueOf(43);
        stone[1][BITTER] = BigInteger.valueOf(71);
        stone[1][RED] = BigInteger.valueOf(101);
        for (int i = 2; i <= 46; i++) {
            BigInteger[] old = stone[i - 1];
            stone[i][WHEAT] = save(old[WHEAT].pow(2).add(old[BARLEY].multiply(BigInteger.valueOf(3))).add(BigInteger.valueOf(i)));
            stone[i][BARLEY] = save(old[BARLEY].pow(2).add(old[SALT].multiply(BigInteger.valueOf(5))).add(old[WHEAT]));
            stone[i][SALT] = save(old[SALT].pow(2).add(old[BITTER].multiply(BigInteger.valueOf(7))).add(old[BARLEY]));
            stone[i][BITTER] = save(old[BITTER].pow(2).add(old[RED].multiply(BigInteger.valueOf(11))).add(old[SALT]));
            stone[i][RED] = save(old[RED].pow(2).add(old[WHEAT].multiply(BigInteger.valueOf(13))).add(old[BITTER]));
        }
        return stone;
    }

    public static BigInteger[][] stoneTableCopy() {
        BigInteger[][] out = new BigInteger[47][6];
        for (int i = 1; i <= 46; i++) out[i] = STONES[i].clone();
        return out;
    }

    public static BigInteger[] buildHiddenDrops(WorkCounts counts) {
        BigInteger[] hidden = new BigInteger[8];
        for (int k = 1; k <= 7; k++) {
            int[] c = HIDDEN_COEFF[k];
            BigInteger x = counts.action()
                .add(counts.target().multiply(BigInteger.valueOf(c[0])))
                .add(counts.distance().multiply(BigInteger.valueOf(c[1])))
                .add(counts.connection().multiply(BigInteger.valueOf(c[2])))
                .add(BigInteger.valueOf((long)c[3] * counts.direction()));
            for (int kind = 1; kind <= 5; kind++) x = x.add(STONES[k][kind]);
            x = save(x);
            for (int grind = 1; grind <= 7; grind++) {
                BigInteger oldX = x;
                x = save(oldX.pow(2)
                    .add(oldX.multiply(BigInteger.valueOf(3)))
                    .add(STONES[k][HIDDEN_GRIND_STONE[grind]])
                    .add(BigInteger.valueOf(grind)));
            }
            hidden[k] = x;
        }
        return hidden;
    }

    public static BigInteger[] buildVisibleDrops(WorkCounts counts, BigInteger[] hidden) {
        Map<Integer,BigInteger> timeline = new HashMap<>();
        for (int k = 1; k <= 7; k++) timeline.put(1-k, hidden[k]);
        BigInteger[] visible = new BigInteger[47];
        for (int i = 1; i <= 46; i++) {
            BigInteger p1 = timeline.get(i-1);
            BigInteger p3 = timeline.get(i-3);
            BigInteger p7 = timeline.get(i-7);
            BigInteger x = STONES[i][WHEAT].multiply(counts.action())
                .add(STONES[i][BARLEY].multiply(counts.target()))
                .add(STONES[i][SALT].multiply(counts.distance()))
                .add(STONES[i][BITTER].multiply(counts.connection()))
                .add(STONES[i][RED].multiply(BigInteger.valueOf(counts.direction())))
                .add(p1)
                .add(p3.multiply(BigInteger.valueOf(3)))
                .add(p7.multiply(BigInteger.valueOf(5)))
                .add(BigInteger.valueOf(i));
            x = save(x);
            for (int grind = 1; grind <= 11; grind++) {
                int[] row = VISIBLE_GRINDS[grind];
                BigInteger oldX = x;
                x = save(oldX.pow(2)
                    .add(oldX.multiply(BigInteger.valueOf(row[0])))
                    .add(p1.multiply(BigInteger.valueOf(row[1])))
                    .add(p3.multiply(BigInteger.valueOf(row[2])))
                    .add(p7.multiply(BigInteger.valueOf(row[3])))
                    .add(STONES[i][row[4]]));
            }
            timeline.put(i, x);
            visible[i] = x;
        }
        return visible;
    }

    public static int[] permutationUnrank1(int rank1) {
        if (rank1 < 1 || rank1 > 720) throw new IllegalArgumentException("E_PERM_RANK");
        int rank0 = rank1 - 1;
        List<Integer> remaining = new ArrayList<>(List.of(1,2,3,4,5,6));
        int[] result = new int[6];
        for (int pos = 0; pos < 6; pos++) {
            int slotsLeft = 6 - pos;
            int block = factorialInt(slotsLeft - 1);
            int q = rank0 / block;
            rank0 = rank0 % block;
            result[pos] = remaining.remove(q);
        }
        return result;
    }

    private static int factorialInt(int n) {
        int r = 1;
        for (int i = 2; i <= n; i++) r *= i;
        return r;
    }

    public static int[] bowlOrderFromDrop(BigInteger drop) {
        int rank = regularMod(drop.subtract(ONE), BigInteger.valueOf(720)).intValueExact() + 1;
        return permutationUnrank1(rank);
    }

    public static BigInteger[] initialBowls(WorkCounts counts) {
        BigInteger[] bowls = new BigInteger[7];
        for (int id = 1; id <= 6; id++) {
            BigInteger s = counts.action()
                .add(counts.target().multiply(BigInteger.valueOf(id)))
                .add(counts.distance())
                .add(counts.connection())
                .add(BigInteger.valueOf(counts.direction()))
                .add(BigInteger.valueOf((long)BOWL_PRIME[id] * BOWL_PRIME[id]));
            bowls[id] = save(s.pow(2).add(BigInteger.valueOf(id)));
        }
        return bowls;
    }

    public static SauceResult sauce(BigInteger calculationDay, BigInteger targetDay) {
        WorkCounts counts = workCounts(calculationDay, targetDay);
        BigInteger[] hidden = buildHiddenDrops(counts);
        BigInteger[] visible = buildVisibleDrops(counts, hidden);
        BigInteger[] bowls = initialBowls(counts);
        int[] orderAt46 = null;
        for (int i = 1; i <= 46; i++) {
            BigInteger drop = visible[i];
            int[] order = bowlOrderFromDrop(drop);
            BigInteger[] old = bowls.clone();
            BigInteger[] pour = new BigInteger[7];
            Arrays.fill(pour, ZERO);
            int first = order[0], second = order[1], third = order[2];
            pour[1] = save(drop.pow(2).add(STONES[i][WHEAT].multiply(old[first])).add(BigInteger.valueOf(3L*i)));
            pour[2] = save(drop.pow(2).add(STONES[i][BARLEY].multiply(old[second])).add(BigInteger.valueOf(5L*i)));
            pour[3] = save(drop.pow(2).add(STONES[i][SALT].multiply(old[third])).add(BigInteger.valueOf(7L*i)));
            BigInteger[] next = new BigInteger[7];
            for (int position = 1; position <= 6; position++) {
                int id = order[position - 1];
                int prev = order[wrap1(position - 1,6)-1];
                int nxt = order[wrap1(position + 1,6)-1];
                int kind = BOWL_STIR_STONE_BY_POSITION[position];
                BigInteger s = old[id]
                    .add(old[prev].multiply(BigInteger.valueOf(2)))
                    .add(old[nxt].multiply(BigInteger.valueOf(3)))
                    .add(pour[position])
                    .add(drop)
                    .add(STONES[i][kind]);
                next[id] = save(s.pow(2)
                    .add(old[prev].multiply(old[nxt]).multiply(BigInteger.valueOf(5)))
                    .add(BigInteger.valueOf((long)i*position)));
            }
            bowls = next;
            if (i == 46) orderAt46 = order.clone();
        }
        for (int stir = 1; stir <= 12; stir++) {
            BigInteger[] old = bowls.clone();
            BigInteger savedBowlSum = ZERO;
            for (int id = 1; id <= 6; id++) savedBowlSum = savedBowlSum.add(old[id]);
            savedBowlSum = save(savedBowlSum.add(BigInteger.valueOf(149L*stir)));
            int orderNumber = regularMod(savedBowlSum.subtract(ONE), BigInteger.valueOf(720)).intValueExact() + 1;
            int[] order = permutationUnrank1(orderNumber);
            BigInteger[] next = new BigInteger[7];
            for (int position = 1; position <= 6; position++) {
                int id = order[position - 1];
                int prev = order[wrap1(position - 1,6)-1];
                int nxt = order[wrap1(position + 1,6)-1];
                BigInteger s = old[id]
                    .add(old[prev].multiply(BigInteger.valueOf(3)))
                    .add(old[nxt].multiply(BigInteger.valueOf(5)))
                    .add(savedBowlSum)
                    .add(BigInteger.valueOf(stir))
                    .add(BigInteger.valueOf((long)position*position));
                next[id] = save(s.pow(2).add(old[prev].multiply(old[nxt]).multiply(BigInteger.valueOf(7))));
            }
            bowls = next;
        }
        return new SauceResult(bowls, orderAt46);
    }

    public static int nextBowlInDrop46Order(SauceResult result, int queriedBowlId) {
        int[] order = result.orderAtDrop46();
        for (int p = 0; p < 6; p++) {
            if (order[p] == queriedBowlId) return order[(p + 1) % 6];
        }
        throw new IllegalArgumentException("E_BOWL_ID");
    }

    public static AnswerStream askBowl(SauceResult result, int queriedBowlId, int seal) {
        int nextId = nextBowlInDrop46Order(result, queriedBowlId);
        BigInteger first = save(result.bowls()[queriedBowlId]
            .add(BigInteger.valueOf(seal + 181L)).pow(2)
            .add(result.bowls()[nextId].multiply(BigInteger.valueOf(179)))
            .add(BigInteger.valueOf(seal)));
        BigInteger directionNumber = save(first
            .add(BigInteger.valueOf(seal + 194L)).pow(2)
            .add(first.multiply(BigInteger.valueOf(193)))
            .add(result.bowls()[6].multiply(BigInteger.valueOf(197))));
        int step = regularMod(directionNumber, TWO).equals(ONE) ? 1 : -1;
        return new AnswerStream(first, step);
    }

    public static BigInteger answerAt(AnswerStream stream, BigInteger k) {
        return ONE.add(regularMod(stream.first().subtract(ONE).add(k.multiply(BigInteger.valueOf(stream.directionStep()))), M));
    }

    public static BigInteger chooseRankShort(AnswerStream stream, BigInteger n) {
        if (n.signum() <= 0 || n.compareTo(M) > 0) throw new IllegalArgumentException("E_SHORT_N");
        BigInteger acceptanceLimit = floorDiv(M,n).multiply(n);
        BigInteger k = ZERO;
        while (true) {
            BigInteger x = answerAt(stream,k);
            if (x.compareTo(acceptanceLimit) <= 0) return regularMod(x.subtract(ONE),n).add(ONE);
            k = k.add(ONE);
        }
    }

    public static BigInteger chooseRankWide(AnswerStream stream, BigInteger n) {
        if (n.compareTo(M) <= 0) throw new IllegalArgumentException("E_WIDE_N");
        int places = 1;
        BigInteger space = M;
        while (space.compareTo(n) < 0) {
            places++;
            space = space.multiply(M);
        }
        BigInteger wide = ONE;
        BigInteger weight = ONE;
        for (int j = 0; j < places; j++) {
            wide = wide.add(answerAt(stream, BigInteger.valueOf(j)).subtract(ONE).multiply(weight));
            weight = weight.multiply(M);
        }
        BigInteger acceptanceLimit = floorDiv(space,n).multiply(n);
        while (wide.compareTo(acceptanceLimit) > 0) {
            wide = ONE.add(regularMod(wide.subtract(ONE).add(BigInteger.valueOf(stream.directionStep())), space));
        }
        return regularMod(wide.subtract(ONE),n).add(ONE);
    }

    public static BigInteger chooseRank(AnswerStream stream, BigInteger n) {
        if (n.signum() <= 0) throw new IllegalArgumentException("E_CHOOSE_N");
        return n.compareTo(M) <= 0 ? chooseRankShort(stream,n) : chooseRankWide(stream,n);
    }

    public static BigInteger fallingFactorial(int n, int k) {
        if (k < 0 || k > n) throw new IllegalArgumentException("E_FALLING");
        BigInteger r = ONE;
        for (int j = 0; j < k; j++) r = r.multiply(BigInteger.valueOf(n-j));
        return r;
    }

    public static int[] unrankDistinctIndices(int masterSize, int k, BigInteger rank1) {
        BigInteger total = fallingFactorial(masterSize,k);
        if (rank1.compareTo(ONE) < 0 || rank1.compareTo(total) > 0) throw new IllegalArgumentException("E_NAME_RANK");
        List<Integer> remaining = new ArrayList<>();
        for (int i = 1; i <= masterSize; i++) remaining.add(i);
        int[] out = new int[k];
        BigInteger r = rank1;
        for (int position = 0; position < k; position++) {
            int suffixLength = k-position-1;
            BigInteger block = fallingFactorial(remaining.size()-1,suffixLength);
            for (int candidate = 0; candidate < remaining.size(); candidate++) {
                if (r.compareTo(block) > 0) r = r.subtract(block);
                else {
                    out[position] = remaining.remove(candidate);
                    break;
                }
            }
        }
        return out;
    }

    public static final class BoundedCompositionFamily {
        private final int total;
        private final int slots;
        private final int lo;
        private final int hi;
        private final Map<Long,BigInteger> memo = new HashMap<>();

        public BoundedCompositionFamily(int total, int slots, int lo, int hi) {
            this.total = total;
            this.slots = slots;
            this.lo = lo;
            this.hi = hi;
        }

        private long key(int rem, int k) {
            return (((long)rem) << 32) ^ (k & 0xffffffffL);
        }

        private BigInteger countSuffix(int rem, int k) {
            if (k == 0) return rem == 0 ? ONE : ZERO;
            if (rem < k*lo || rem > k*hi) return ZERO;
            long key = key(rem,k);
            BigInteger old = memo.get(key);
            if (old != null) return old;
            BigInteger s = ZERO;
            for (int x = lo; x <= hi; x++) s = s.add(countSuffix(rem-x,k-1));
            memo.put(key,s);
            return s;
        }

        public BigInteger count() {
            return countSuffix(total,slots);
        }

        public int[] unrank1(BigInteger rank1) {
            if (rank1.compareTo(ONE) < 0 || rank1.compareTo(count()) > 0) throw new IllegalArgumentException("E_COMP_RANK");
            BigInteger r = rank1;
            int rem = total;
            int[] out = new int[slots];
            for (int position = 0; position < slots; position++) {
                for (int x = lo; x <= hi; x++) {
                    BigInteger block = countSuffix(rem-x,slots-position-1);
                    if (r.compareTo(block) > 0) r = r.subtract(block);
                    else {
                        out[position] = x;
                        rem -= x;
                        break;
                    }
                }
            }
            return out;
        }
    }

    public static final class CutletPartitionFamily {
        private final int total;
        private final int slots;
        private final Integer required;
        private final Map<CutletState,BigInteger> memo = new HashMap<>();

        public CutletPartitionFamily(int total, int slots, Integer required) {
            this.total = total;
            this.slots = slots;
            this.required = required;
        }

        private record CutletState(int rem, int slots, int cumulative, boolean hit) {}

        private BigInteger countState(int rem, int k, int cumulative, boolean hit) {
            if (k == 0) {
                if (rem != 0) return ZERO;
                if (required == null) return ONE;
                return hit ? ONE : ZERO;
            }
            if (rem < k) return ZERO;
            CutletState key = new CutletState(rem,k,cumulative,hit);
            BigInteger old = memo.get(key);
            if (old != null) return old;
            BigInteger totalCount = ZERO;
            int maxX = rem-(k-1);
            for (int x = 1; x <= maxX; x++) {
                int nextCum = cumulative+x;
                boolean nextHit = hit;
                if (required != null && !hit) {
                    if (nextCum == required) nextHit = true;
                    else if (nextCum > required) continue;
                }
                totalCount = totalCount.add(countState(rem-x,k-1,nextCum,nextHit));
            }
            memo.put(key,totalCount);
            return totalCount;
        }

        public BigInteger count() {
            return countState(total,slots,0,false);
        }

        public int[] unrank1(BigInteger rank1) {
            if (rank1.compareTo(ONE) < 0 || rank1.compareTo(count()) > 0) throw new IllegalArgumentException("E_CUTLET_PARTITION_RANK");
            BigInteger r = rank1;
            int rem = total;
            int k = slots;
            int cumulative = 0;
            boolean hit = false;
            int[] out = new int[slots];
            int position = 0;
            while (k > 0) {
                int maxX = rem-(k-1);
                for (int x = 1; x <= maxX; x++) {
                    int nextCum = cumulative+x;
                    boolean nextHit = hit;
                    if (required != null && !hit) {
                        if (nextCum == required) nextHit = true;
                        else if (nextCum > required) continue;
                    }
                    BigInteger block = countState(rem-x,k-1,nextCum,nextHit);
                    if (r.compareTo(block) > 0) r = r.subtract(block);
                    else {
                        out[position++] = x;
                        rem -= x;
                        k--;
                        cumulative = nextCum;
                        hit = nextHit;
                        break;
                    }
                }
            }
            return out;
        }
    }

    private static final class WeaveKey {
        private final int[] remaining;
        private final int opened;
        private final int closed;
        private final int hash;

        private WeaveKey(int[] remaining, int opened, int closed) {
            this.remaining = remaining.clone();
            this.opened = opened;
            this.closed = closed;
            this.hash = 31*(31*Arrays.hashCode(this.remaining)+opened)+closed;
        }

        @Override public boolean equals(Object o) {
            if (this == o) return true;
            if (!(o instanceof WeaveKey other)) return false;
            return opened == other.opened && closed == other.closed && Arrays.equals(remaining,other.remaining);
        }
        @Override public int hashCode() { return hash; }
    }

    public static final class WeavingFamily {
        private final int[] lengths;
        private final int m;
        private final Map<WeaveKey,BigInteger> memo = new HashMap<>();

        public WeavingFamily(int[] lengths) {
            if (lengths.length == 0) throw new IllegalArgumentException("E_WEAVE_EMPTY");
            this.lengths = lengths.clone();
            this.m = lengths.length;
            for (int x : lengths) if (x < 1) throw new IllegalArgumentException("E_WEAVE_LENGTH");
        }

        private boolean legal(int[] remaining, int opened, int closed, int j0) {
            if (remaining[j0] == 0) return false;
            int j = j0+1;
            boolean alreadyOpened = remaining[j0] < lengths[j0];
            if (!alreadyOpened && j != opened+1) return false;
            boolean willClose = remaining[j0] == 1;
            return !willClose || j == closed+1;
        }

        private BigInteger countState(int[] remaining, int opened, int closed) {
            boolean done = true;
            for (int x : remaining) if (x != 0) { done=false; break; }
            if (done) return ONE;
            WeaveKey key = new WeaveKey(remaining,opened,closed);
            BigInteger old = memo.get(key);
            if (old != null) return old;
            BigInteger total = ZERO;
            for (int j0 = 0; j0 < m; j0++) {
                if (!legal(remaining,opened,closed,j0)) continue;
                int[] next = remaining.clone();
                int nextOpened = opened;
                int nextClosed = closed;
                if (next[j0] == lengths[j0]) nextOpened = j0+1;
                next[j0]--;
                if (next[j0] == 0) nextClosed = j0+1;
                total = total.add(countState(next,nextOpened,nextClosed));
            }
            memo.put(key,total);
            return total;
        }

        public BigInteger count() {
            return countState(lengths.clone(),0,0);
        }

        public int[] unrank1(BigInteger rank1) {
            BigInteger total = count();
            if (rank1.compareTo(ONE) < 0 || rank1.compareTo(total) > 0) throw new IllegalArgumentException("E_WEAVE_RANK");
            int totalLength = Arrays.stream(lengths).sum();
            int[] remaining = lengths.clone();
            int opened=0, closed=0;
            int[] out = new int[totalLength];
            BigInteger r = rank1;
            for (int pos=0; pos<totalLength; pos++) {
                for (int j0=0; j0<m; j0++) {
                    if (!legal(remaining,opened,closed,j0)) continue;
                    int[] next = remaining.clone();
                    int no=opened,nc=closed;
                    if (next[j0] == lengths[j0]) no=j0+1;
                    next[j0]--;
                    if (next[j0] == 0) nc=j0+1;
                    BigInteger block = countState(next,no,nc);
                    if (r.compareTo(block) > 0) r=r.subtract(block);
                    else {
                        out[pos]=j0+1;
                        remaining=next;
                        opened=no;
                        closed=nc;
                        break;
                    }
                }
            }
            return out;
        }
    }

    private final class GateCache {
        private final Map<BigInteger,BigInteger> gate = new HashMap<>();
        private BigInteger min = ZERO;
        private BigInteger max = ZERO;

        private GateCache() {
            gate.put(ZERO,FOUNDATION_DAY);
        }

        BigInteger get(BigInteger index) {
            ensure(index);
            return gate.get(index);
        }

        void ensure(BigInteger k) {
            if (k.compareTo(max) > 0) {
                BigInteger n = max.add(ONE);
                while (n.compareTo(k) <= 0) {
                    BigInteger prev = gate.get(n.subtract(ONE));
                    BigInteger gap = positiveGateGap(n);
                    gate.put(n,prev.add(gap));
                    max=n;
                    n=n.add(ONE);
                }
            }
            if (k.compareTo(min) < 0) {
                BigInteger n = min.subtract(ONE);
                while (n.compareTo(k) >= 0) {
                    BigInteger next = gate.get(n.add(ONE));
                    BigInteger gap = negativeGateGap(n.abs());
                    gate.put(n,next.subtract(gap));
                    min=n;
                    n=n.subtract(ONE);
                }
            }
        }

        void cover(BigInteger lowDay, BigInteger highDay) {
            if (lowDay.compareTo(highDay) > 0) throw new IllegalArgumentException("E_GATE_RANGE");
            while (gate.get(min).compareTo(lowDay) > 0) ensure(min.subtract(ONE));
            while (gate.get(max).compareTo(highDay) < 0) ensure(max.add(ONE));
        }

        BigInteger atOrBefore(BigInteger day) {
            cover(day,day);
            BigInteger lo=min, hi=max;
            while (lo.compareTo(hi) < 0) {
                BigInteger mid = lo.add(hi.subtract(lo).add(ONE).divide(TWO));
                if (gate.get(mid).compareTo(day) <= 0) lo=mid;
                else hi=mid.subtract(ONE);
            }
            return lo;
        }

        BigInteger exact(BigInteger day) {
            BigInteger i = atOrBefore(day);
            return gate.get(i).equals(day) ? i : null;
        }
    }

    public BigInteger positiveGateGap(BigInteger n) {
        if (n.signum() <= 0) throw new IllegalArgumentException("E_POS_GATE");
        SauceResult r = sauce(FOUNDATION_DAY,FOUNDATION_DAY.add(n));
        BigInteger chosen = chooseRank(askBowl(r,1,SEAL_GATE_GAP),BigInteger.valueOf(922));
        return BigInteger.valueOf(41).add(chosen);
    }

    public BigInteger negativeGateGap(BigInteger n) {
        if (n.signum() <= 0) throw new IllegalArgumentException("E_NEG_GATE");
        SauceResult r = sauce(FOUNDATION_DAY,FOUNDATION_DAY.subtract(n));
        BigInteger chosen = chooseRank(askBowl(r,1,SEAL_GATE_GAP),BigInteger.valueOf(922));
        return BigInteger.valueOf(41).add(chosen);
    }

    private boolean validYearPair(BigInteger openIndex, BigInteger closeIndex) {
        if (closeIndex.subtract(openIndex).compareTo(BigInteger.valueOf(6)) < 0) return false;
        BigInteger len = gates.get(closeIndex).subtract(gates.get(openIndex));
        return len.compareTo(BigInteger.valueOf(YEAR_MIN_DAYS)) >= 0 && len.compareTo(BigInteger.valueOf(YEAR_MAX_DAYS)) <= 0;
    }

    public Year year5000(BigInteger calculationDay) {
        BigInteger bound=BigInteger.valueOf(YEAR_MAX_DAYS);
        gates.cover(calculationDay.subtract(bound),calculationDay.add(bound));
        List<BigInteger[]> candidates=new ArrayList<>();
        BigInteger i=gates.min;
        while (i.compareTo(gates.max)<0) {
            BigInteger j=i.add(BigInteger.valueOf(6));
            while (j.compareTo(gates.max)<=0) {
                BigInteger len=gates.get(j).subtract(gates.get(i));
                if (len.compareTo(BigInteger.valueOf(YEAR_MAX_DAYS))>0) break;
                if (validYearPair(i,j) && gates.get(i).compareTo(calculationDay)<0 && calculationDay.compareTo(gates.get(j))<=0) {
                    candidates.add(new BigInteger[]{i,j});
                }
                j=j.add(ONE);
            }
            i=i.add(ONE);
        }
        candidates.sort(Comparator.comparing((BigInteger[] a) -> gates.get(a[1]).subtract(gates.get(a[0])))
            .thenComparing(a -> gates.get(a[0])));
        if (candidates.isEmpty()) throw new IllegalStateException("E_YEAR5000_EMPTY");
        BigInteger rank=chooseRank(askBowl(sauce(calculationDay,calculationDay),1,SEAL_YEAR_5000),BigInteger.valueOf(candidates.size()));
        BigInteger[] c=candidates.get(rank.intValueExact()-1);
        return new Year(BigInteger.valueOf(5000),c[0],c[1],gates.get(c[0]),gates.get(c[1]));
    }

    public Year nextYear(BigInteger calculationDay, Year known) {
        BigInteger open=known.closeGateIndex();
        gates.cover(gates.get(open),gates.get(open).add(BigInteger.valueOf(YEAR_MAX_DAYS)));
        List<BigInteger> candidates=new ArrayList<>();
        BigInteger j=open.add(ONE);
        while (true) {
            BigInteger len=gates.get(j).subtract(gates.get(open));
            if (len.compareTo(BigInteger.valueOf(YEAR_MAX_DAYS))>0) break;
            if (validYearPair(open,j)) candidates.add(j);
            j=j.add(ONE);
        }
        candidates.sort(Comparator.comparing(x -> gates.get(x).subtract(gates.get(open))));
        BigInteger rank=chooseRank(askBowl(sauce(calculationDay,gates.get(open)),1,SEAL_NEXT_YEAR),BigInteger.valueOf(candidates.size()));
        BigInteger close=candidates.get(rank.intValueExact()-1);
        return new Year(known.number().add(ONE),open,close,gates.get(open),gates.get(close));
    }

    public Year previousYear(BigInteger calculationDay, Year known) {
        BigInteger close=known.openGateIndex();
        gates.cover(gates.get(close).subtract(BigInteger.valueOf(YEAR_MAX_DAYS)),gates.get(close));
        List<BigInteger> candidates=new ArrayList<>();
        BigInteger i=close.subtract(ONE);
        while (true) {
            BigInteger len=gates.get(close).subtract(gates.get(i));
            if (len.compareTo(BigInteger.valueOf(YEAR_MAX_DAYS))>0) break;
            if (validYearPair(i,close)) candidates.add(i);
            i=i.subtract(ONE);
        }
        candidates.sort(Comparator.comparing(x -> gates.get(close).subtract(gates.get(x))));
        BigInteger rank=chooseRank(askBowl(sauce(calculationDay,gates.get(close)),1,SEAL_PREVIOUS_YEAR),BigInteger.valueOf(candidates.size()));
        BigInteger open=candidates.get(rank.intValueExact()-1);
        return new Year(known.number().subtract(ONE),open,close,gates.get(open),gates.get(close));
    }

    public Year findTargetYear(BigInteger calculationDay, BigInteger targetDay) {
        Year y=year5000(calculationDay);
        while (targetDay.compareTo(y.closeGateDay())>0) y=nextYear(calculationDay,y);
        while (targetDay.compareTo(y.openGateDay())<=0) y=previousYear(calculationDay,y);
        if (!(y.openGateDay().compareTo(targetDay)<0 && targetDay.compareTo(y.closeGateDay())<=0)) throw new IllegalStateException("E_TARGET_YEAR");
        return y;
    }

    private int chooseCutletCount(SauceResult r, Year year) {
        int gaps=year.closeGateIndex().subtract(year.openGateIndex()).intValueExact();
        List<Integer> candidates=new ArrayList<>();
        for (int k=MIN_CUTLETS;k<=MAX_CUTLETS;k++) if (k<=gaps) candidates.add(k);
        BigInteger rank=chooseRank(askBowl(r,2,SEAL_CUTLET_COUNT),BigInteger.valueOf(candidates.size()));
        return candidates.get(rank.intValueExact()-1);
    }

    private int[] chooseCutletPartition(BigInteger calculationDay, SauceResult r, Year year, int cutletCount) {
        int g=year.closeGateIndex().subtract(year.openGateIndex()).intValueExact();
        BigInteger exact=gates.exact(calculationDay);
        Integer required=null;
        if (exact!=null && exact.compareTo(year.openGateIndex())>0 && exact.compareTo(year.closeGateIndex())<0) required=exact.subtract(year.openGateIndex()).intValueExact();
        CutletPartitionFamily family=new CutletPartitionFamily(g,cutletCount,required);
        BigInteger rank=chooseRank(askBowl(r,2,SEAL_CUTLET_PARTITION),family.count());
        return family.unrank1(rank);
    }

    private int[] chooseCutletNames(SauceResult r, int cutletCount) {
        BigInteger n=fallingFactorial(17,cutletCount);
        BigInteger rank=chooseRank(askBowl(r,5,SEAL_CUTLET_NAMES),n);
        return unrankDistinctIndices(17,cutletCount,rank);
    }

    private List<Cutlet> materializeCutlets(Year year, int[] partition, int[] names) {
        List<Cutlet> out=new ArrayList<>();
        BigInteger cursor=year.openGateIndex();
        for (int k=0;k<partition.length;k++) {
            BigInteger open=cursor;
            BigInteger close=cursor.add(BigInteger.valueOf(partition[k]));
            out.add(new Cutlet(names[k],open,close,gates.get(open).add(ONE),gates.get(close)));
            cursor=close;
        }
        return out;
    }

    private int chooseMonthCount(SauceResult r, Year year) {
        int len=year.closeGateDay().subtract(year.openGateDay()).intValueExact();
        int lo=(len+122)/123;
        int hi=Math.min(47,len/4);
        if (!(3<=lo && lo<=hi && hi<=47)) throw new IllegalStateException("E_MONTH_BOUNDS");
        BigInteger rank=chooseRank(askBowl(r,3,SEAL_MONTH_COUNT),BigInteger.valueOf(hi-lo+1L));
        return lo+rank.intValueExact()-1;
    }

    private int[] chooseMonthLengths(SauceResult r, Year year, int monthCount) {
        int len=year.closeGateDay().subtract(year.openGateDay()).intValueExact();
        BoundedCompositionFamily family=new BoundedCompositionFamily(len,monthCount,4,123);
        BigInteger rank=chooseRank(askBowl(r,3,SEAL_MONTH_LENGTHS),family.count());
        return family.unrank1(rank);
    }

    private int[] chooseMonthWeaving(SauceResult r, int[] lengths) {
        WeavingFamily family=new WeavingFamily(lengths);
        BigInteger rank=chooseRank(askBowl(r,4,SEAL_MONTH_WEAVING),family.count());
        return family.unrank1(rank);
    }

    private int[] chooseMonthNames(SauceResult r, int monthCount) {
        BigInteger n=fallingFactorial(47,monthCount);
        BigInteger rank=chooseRank(askBowl(r,5,SEAL_MONTH_NAMES),n);
        return unrankDistinctIndices(47,monthCount,rank);
    }

    public YearStructure buildYearStructure(BigInteger calculationDay, Year year) {
        BigInteger firstDay=year.openGateDay().add(ONE);
        SauceResult r=sauce(calculationDay,firstDay);
        int cutletCount=chooseCutletCount(r,year);
        int[] partition=chooseCutletPartition(calculationDay,r,year,cutletCount);
        int[] cutletNames=chooseCutletNames(r,cutletCount);
        List<Cutlet> cutlets=materializeCutlets(year,partition,cutletNames);
        int monthCount=chooseMonthCount(r,year);
        int[] lengths=chooseMonthLengths(r,year,monthCount);
        int[] weave=chooseMonthWeaving(r,lengths);
        int[] monthNames=chooseMonthNames(r,monthCount);
        return new YearStructure(cutletCount,partition,cutletNames,cutlets,monthCount,lengths,weave,monthNames);
    }

    public CalendarResult calendarDate(BigInteger calculationDay, BigInteger targetDay) {
        Year year=findTargetYear(calculationDay,targetDay);
        YearStructure s=buildYearStructure(calculationDay,year);
        Cutlet chosen=null;
        for (Cutlet c:s.cutlets()) {
            if (c.firstDay().compareTo(targetDay)<=0 && targetDay.compareTo(c.lastDay())<=0) { chosen=c; break; }
        }
        if (chosen==null) throw new IllegalStateException("E_CUTLET_NOT_FOUND");
        BigInteger dayInCutlet=targetDay.subtract(chosen.firstDay()).add(ONE);
        int yearOffset0=targetDay.subtract(year.openGateDay().add(ONE)).intValueExact();
        int monthId=s.monthWeaving()[yearOffset0];
        int dayInMonth=0;
        for (int p=0;p<=yearOffset0;p++) if (s.monthWeaving()[p]==monthId) dayInMonth++;
        int cutletCanonical=chosen.canonicalNameIndex();
        int monthCanonical=s.monthNameIndices()[monthId-1];
        return new CalendarResult(year.number(),cutletCanonical,SourceLanguageCatalog.cutletName(cutletCanonical),dayInCutlet,monthCanonical,SourceLanguageCatalog.monthName(monthCanonical),dayInMonth);
    }

    public Map<BigInteger,BigInteger> generatedGateSnapshot() {
        return new LinkedHashMap<>(gates.gate);
    }
}
