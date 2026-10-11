package org.pastafari.javalojban;

import java.math.BigInteger;
import java.util.Arrays;

public final class MonsterSauceDrops {
    private static final int STONE_TYPES = 5;
    private static final int LAST_DROP = 46;
    private static final int HIDDEN_COUNT = 7;
    private static final int[][] HIDDEN_COEFFICIENTS = {
        {},
        {3, 4, 6, 8},
        {5, 7, 10, 12},
        {7, 10, 14, 16},
        {9, 13, 18, 20},
        {11, 16, 22, 24},
        {13, 19, 26, 28},
        {15, 22, 30, 32}
    };
    private static final int[] HIDDEN_STONES = {0, 1, 2, 3, 4, 5, 1, 2};
    private static final int[][] VISIBLE_GRINDS = {
        {},
        {3, 5, 7, 11, 1},
        {5, 7, 11, 13, 2},
        {7, 11, 13, 17, 3},
        {11, 13, 17, 19, 4},
        {13, 17, 19, 23, 5},
        {17, 19, 23, 29, 1},
        {19, 23, 29, 31, 2},
        {23, 29, 31, 37, 3},
        {29, 31, 37, 41, 4},
        {31, 37, 41, 43, 5},
        {37, 41, 43, 47, 1}
    };
    private static final BigInteger[][] STONES = makeStoneTable();

    public static final class Drops {
        private final BigInteger[] hidden;
        private final BigInteger[] visible;

        private Drops(BigInteger[] hidden, BigInteger[] visible) {
            this.hidden = hidden.clone();
            this.visible = visible.clone();
        }

        public BigInteger[] hidden() {
            return hidden.clone();
        }

        public BigInteger[] visible() {
            return visible.clone();
        }

        public BigInteger hiddenAt(int index) {
            if (index < 1 || index > HIDDEN_COUNT) {
                throw new IllegalArgumentException("E_HIDDEN_INDEX");
            }
            return hidden[index];
        }

        public BigInteger visibleAt(int index) {
            if (index < 1 || index > LAST_DROP) {
                throw new IllegalArgumentException("E_VISIBLE_INDEX");
            }
            return visible[index];
        }
    }

    private MonsterSauceDrops() {}

    private static BigInteger multiply(BigInteger x, long factor) {
        return x.multiply(BigInteger.valueOf(factor));
    }

    private static BigInteger saved(BigInteger x) {
        return MonsterArithmetic.save(x);
    }

    private static BigInteger[][] makeStoneTable() {
        BigInteger[][] stones = new BigInteger[LAST_DROP + 1][STONE_TYPES + 1];
        int[] seed = {0, 17, 29, 43, 71, 101};
        for (int kind = 1; kind <= STONE_TYPES; kind++) {
            stones[1][kind] = BigInteger.valueOf(seed[kind]);
        }
        int[] nextKind = {0, 2, 3, 4, 5, 1};
        int[] weight = {0, 3, 5, 7, 11, 13};
        for (int row = 2; row <= LAST_DROP; row++) {
            for (int kind = 1; kind <= STONE_TYPES; kind++) {
                BigInteger current = stones[row - 1][kind];
                BigInteger neighbor = stones[row - 1][nextKind[kind]];
                BigInteger extra = kind == 1 ? BigInteger.valueOf(row) : stones[row - 1][kind == 1 ? 1 : kind - 1];
                stones[row][kind] = saved(current.multiply(current).add(multiply(neighbor, weight[kind])).add(extra));
            }
        }
        return stones;
    }

    public static BigInteger[][] stonesCopy() {
        BigInteger[][] result = new BigInteger[STONES.length][];
        for (int i = 0; i < STONES.length; i++) {
            result[i] = STONES[i].clone();
        }
        return result;
    }

    private static void requireCounts(MonsterArithmetic.WorkCounts counts) {
        if (counts == null
                || counts.action() == null
                || counts.target() == null
                || counts.distance() == null
                || counts.connection() == null) {
            throw new IllegalArgumentException("E_NULL_COUNTS");
        }
        if (counts.direction() < 1 || counts.direction() > 3) {
            throw new IllegalArgumentException("E_DIRECTION");
        }
    }

    public static BigInteger[] hiddenDrops(MonsterArithmetic.WorkCounts counts) {
        requireCounts(counts);
        BigInteger[] result = new BigInteger[HIDDEN_COUNT + 1];
        for (int k = 1; k <= HIDDEN_COUNT; k++) {
            int[] coeff = HIDDEN_COEFFICIENTS[k];
            BigInteger x = counts.action()
                .add(multiply(counts.target(), coeff[0]))
                .add(multiply(counts.distance(), coeff[1]))
                .add(multiply(counts.connection(), coeff[2]))
                .add(BigInteger.valueOf((long) coeff[3] * counts.direction()));
            for (int kind = 1; kind <= STONE_TYPES; kind++) {
                x = x.add(STONES[k][kind]);
            }
            x = saved(x);
            for (int round = 1; round <= HIDDEN_COUNT; round++) {
                x = saved(x.multiply(x)
                    .add(multiply(x, 3))
                    .add(STONES[k][HIDDEN_STONES[round]])
                    .add(BigInteger.valueOf(round)));
            }
            result[k] = x;
        }
        return result;
    }

    public static BigInteger[] visibleDrops(MonsterArithmetic.WorkCounts counts, BigInteger[] hidden) {
        requireCounts(counts);
        if (hidden == null) {
            throw new IllegalArgumentException("E_NULL_HIDDEN");
        }
        if (hidden.length != HIDDEN_COUNT + 1) {
            throw new IllegalArgumentException("E_HIDDEN_LENGTH");
        }
        BigInteger[] timeline = new BigInteger[LAST_DROP + HIDDEN_COUNT];
        for (int k = 1; k <= HIDDEN_COUNT; k++) {
            if (hidden[k] == null) {
                throw new IllegalArgumentException("E_NULL_HIDDEN_DROP");
            }
            timeline[HIDDEN_COUNT - k] = hidden[k];
        }
        BigInteger[] visible = new BigInteger[LAST_DROP + 1];
        for (int i = 1; i <= LAST_DROP; i++) {
            BigInteger p1 = timeline[i + 5];
            BigInteger p3 = timeline[i + 3];
            BigInteger p7 = timeline[i - 1];
            BigInteger[] stone = STONES[i];
            BigInteger x = multiply(stone[1], 1).multiply(counts.action())
                .add(stone[2].multiply(counts.target()))
                .add(stone[3].multiply(counts.distance()))
                .add(stone[4].multiply(counts.connection()))
                .add(multiply(stone[5], counts.direction()))
                .add(p1)
                .add(multiply(p3, 3))
                .add(multiply(p7, 5))
                .add(BigInteger.valueOf(i));
            x = saved(x);
            for (int round = 1; round < VISIBLE_GRINDS.length; round++) {
                int[] coeff = VISIBLE_GRINDS[round];
                x = saved(x.multiply(x)
                    .add(multiply(x, coeff[0]))
                    .add(multiply(p1, coeff[1]))
                    .add(multiply(p3, coeff[2]))
                    .add(multiply(p7, coeff[3]))
                    .add(stone[coeff[4]]));
            }
            timeline[i + 6] = x;
            visible[i] = x;
        }
        return visible;
    }

    public static Drops prepare(BigInteger calculationDay, BigInteger targetDay) {
        MonsterArithmetic.WorkCounts counts = MonsterArithmetic.workCounts(calculationDay, targetDay);
        BigInteger[] hidden = hiddenDrops(counts);
        return new Drops(hidden, visibleDrops(counts, hidden));
    }
}
