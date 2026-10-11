package org.pastafari.javalojban;

import java.math.BigInteger;
import java.util.Arrays;

public final class MonsterSauceBowls {
    private static final BigInteger SEVEN_TWENTY = BigInteger.valueOf(720);
    private static final int[] BOWL_PRIMES = {0, 17, 19, 23, 29, 31, 37};
    private static final int[] STIR_STONE_KIND = {0, 1, 2, 3, 4, 5, 1};
    private static final int[] FACTORIAL_BLOCKS = {120, 24, 6, 2, 1, 1};

    public static final class SauceResult {
        private final BigInteger[] bowls;
        private final int[] orderAtDrop46;

        private SauceResult(BigInteger[] bowls, int[] orderAtDrop46) {
            this.bowls = bowls.clone();
            this.orderAtDrop46 = orderAtDrop46.clone();
        }

        public BigInteger[] bowls() {
            return bowls.clone();
        }

        public int[] orderAtDrop46() {
            return orderAtDrop46.clone();
        }

        public BigInteger bowl(int id) {
            if (id < 1 || id > 6) {
                throw new IllegalArgumentException("E_BOWL_ID");
            }
            return bowls[id];
        }

        public int nextBowl(int id) {
            if (id < 1 || id > 6) {
                throw new IllegalArgumentException("E_BOWL_ID");
            }
            for (int i = 0; i < orderAtDrop46.length; i++) {
                if (orderAtDrop46[i] == id) {
                    return orderAtDrop46[(i + 1) % orderAtDrop46.length];
                }
            }
            throw new IllegalStateException("E_MISSING_BOWL");
        }
    }

    public record AnswerStream(BigInteger first, int directionStep) {}

    private MonsterSauceBowls() {}

    private static BigInteger scalar(BigInteger n, long factor) {
        return n.multiply(BigInteger.valueOf(factor));
    }

    private static BigInteger save(BigInteger x) {
        return MonsterArithmetic.save(x);
    }

    public static int[] unrankPermutation(int rank) {
        if (rank < 1 || rank > 720) {
            throw new IllegalArgumentException("E_PERM_RANK");
        }
        int zeroRank = rank - 1;
        int[] available = {1, 2, 3, 4, 5, 6};
        int[] chosen = new int[6];
        int remaining = 6;
        for (int p = 0; p < 6; p++) {
            int digit = zeroRank / FACTORIAL_BLOCKS[p];
            zeroRank %= FACTORIAL_BLOCKS[p];
            chosen[p] = available[digit];
            System.arraycopy(available, digit + 1, available, digit, remaining - digit - 1);
            remaining--;
        }
        return chosen;
    }

    public static int[] orderFromDrop(BigInteger drop) {
        if (drop == null) {
            throw new IllegalArgumentException("E_NULL_DROP");
        }
        int rank = drop.subtract(BigInteger.ONE).mod(SEVEN_TWENTY).intValueExact() + 1;
        return unrankPermutation(rank);
    }

    public static BigInteger[] initialBowls(MonsterArithmetic.WorkCounts counts) {
        if (counts == null || counts.action() == null || counts.target() == null
                || counts.distance() == null || counts.connection() == null) {
            throw new IllegalArgumentException("E_NULL_COUNTS");
        }
        if (counts.direction() < 1 || counts.direction() > 3) {
            throw new IllegalArgumentException("E_DIRECTION");
        }
        BigInteger[] bowls = new BigInteger[7];
        for (int id = 1; id <= 6; id++) {
            BigInteger mixed = counts.action()
                .add(scalar(counts.target(), id))
                .add(counts.distance())
                .add(counts.connection())
                .add(BigInteger.valueOf(counts.direction()))
                .add(BigInteger.valueOf((long) BOWL_PRIMES[id] * BOWL_PRIMES[id]));
            bowls[id] = save(mixed.multiply(mixed).add(BigInteger.valueOf(id)));
        }
        return bowls;
    }

    public static SauceResult evaluate(BigInteger calculationDay, BigInteger targetDay) {
        MonsterArithmetic.WorkCounts counts = MonsterArithmetic.workCounts(calculationDay, targetDay);
        MonsterSauceDrops.Drops drops = MonsterSauceDrops.prepare(calculationDay, targetDay);
        BigInteger[][] stones = MonsterSauceDrops.stonesCopy();
        BigInteger[] bowls = initialBowls(counts);
        int[] orderAt46 = null;

        for (int i = 1; i <= 46; i++) {
            BigInteger drop = drops.visibleAt(i);
            BigInteger dropSquared = drop.multiply(drop);
            int[] order = orderFromDrop(drop);
            BigInteger[] old = bowls;
            BigInteger[] pours = new BigInteger[7];
            Arrays.fill(pours, BigInteger.ZERO);
            for (int p = 1; p <= 3; p++) {
                pours[p] = save(dropSquared.add(stones[i][p].multiply(old[order[p - 1]]))
                    .add(BigInteger.valueOf((long) (2 * p + 1) * i)));
            }
            BigInteger[] next = new BigInteger[7];
            for (int p = 1; p <= 6; p++) {
                int id = order[p - 1];
                int previous = order[(p + 4) % 6];
                int following = order[p % 6];
                BigInteger neighborProduct = old[previous].multiply(old[following]);
                BigInteger mixed = old[id]
                    .add(scalar(old[previous], 2))
                    .add(scalar(old[following], 3))
                    .add(pours[p])
                    .add(drop)
                    .add(stones[i][STIR_STONE_KIND[p]]);
                next[id] = save(mixed.multiply(mixed)
                    .add(scalar(neighborProduct, 5))
                    .add(BigInteger.valueOf((long) i * p)));
            }
            bowls = next;
            if (i == 46) {
                orderAt46 = order.clone();
            }
        }

        for (int round = 1; round <= 12; round++) {
            BigInteger[] old = bowls;
            BigInteger sum = BigInteger.valueOf(149L * round);
            for (int id = 1; id <= 6; id++) {
                sum = sum.add(old[id]);
            }
            BigInteger savedSum = save(sum);
            int rank = savedSum.subtract(BigInteger.ONE).mod(SEVEN_TWENTY).intValueExact() + 1;
            int[] order = unrankPermutation(rank);
            BigInteger[] next = new BigInteger[7];
            for (int p = 1; p <= 6; p++) {
                int id = order[p - 1];
                int previous = order[(p + 4) % 6];
                int following = order[p % 6];
                BigInteger mixed = old[id]
                    .add(scalar(old[previous], 3))
                    .add(scalar(old[following], 5))
                    .add(savedSum)
                    .add(BigInteger.valueOf((long) round + (long) p * p));
                next[id] = save(mixed.multiply(mixed)
                    .add(scalar(old[previous].multiply(old[following]), 7)));
            }
            bowls = next;
        }
        return new SauceResult(bowls, orderAt46);
    }

    public static AnswerStream ask(SauceResult result, int queriedBowlId, int seal) {
        if (result == null) {
            throw new IllegalArgumentException("E_NULL_SAUCE");
        }
        BigInteger firstBowl = result.bowl(queriedBowlId);
        BigInteger adjacentBowl = result.bowl(result.nextBowl(queriedBowlId));
        BigInteger firstMix = firstBowl.add(BigInteger.valueOf((long) seal + 181L));
        BigInteger first = save(firstMix.multiply(firstMix)
            .add(scalar(adjacentBowl, 179))
            .add(BigInteger.valueOf(seal)));
        BigInteger directionMix = first.add(BigInteger.valueOf((long) seal + 194L));
        BigInteger directionNumber = save(directionMix.multiply(directionMix)
            .add(scalar(first, 193))
            .add(scalar(result.bowl(6), 197)));
        int step = directionNumber.testBit(0) ? 1 : -1;
        return new AnswerStream(first, step);
    }

    public static BigInteger answerAt(AnswerStream stream, BigInteger offset) {
        if (stream == null || stream.first() == null) {
            throw new IllegalArgumentException("E_NULL_ANSWER");
        }
        if (offset == null) {
            throw new IllegalArgumentException("E_NULL_OFFSET");
        }
        if (stream.directionStep() != 1 && stream.directionStep() != -1) {
            throw new IllegalArgumentException("E_ANSWER_STEP");
        }
        return save(stream.first().add(scalar(offset, stream.directionStep())));
    }
}
