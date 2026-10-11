package org.pastafari.javalojban;

import java.math.BigInteger;

public final class MonsterArithmetic {
    public static final BigInteger MODULUS = BigInteger.ONE.shiftLeft(127).subtract(BigInteger.ONE);
    public static final BigInteger TABLETS_DAY = BigInteger.valueOf(-278522L);
    public static final BigInteger FOUNDATION_DAY = BigInteger.valueOf(-15055671L);

    public record WorkCounts(
        BigInteger action,
        BigInteger target,
        BigInteger distance,
        BigInteger connection,
        int direction
    ) {}

    private MonsterArithmetic() {}

    public static BigInteger floorDiv(BigInteger dividend, BigInteger divisor) {
        if (dividend == null || divisor == null) {
            throw new IllegalArgumentException("E_NULL_NUMBER");
        }
        if (divisor.signum() <= 0) {
            throw new IllegalArgumentException("E_DIVISOR");
        }
        BigInteger[] parts = dividend.divideAndRemainder(divisor);
        return parts[1].signum() < 0 ? parts[0].subtract(BigInteger.ONE) : parts[0];
    }

    public static BigInteger regularMod(BigInteger value, BigInteger modulus) {
        if (value == null || modulus == null) {
            throw new IllegalArgumentException("E_NULL_NUMBER");
        }
        if (modulus.signum() <= 0) {
            throw new IllegalArgumentException("E_MODULUS");
        }
        return value.mod(modulus);
    }

    public static BigInteger save(BigInteger value) {
        if (value == null) {
            throw new IllegalArgumentException("E_NULL_NUMBER");
        }
        return value.subtract(BigInteger.ONE).mod(MODULUS).add(BigInteger.ONE);
    }

    public static BigInteger ceilDiv(BigInteger dividend, BigInteger divisor) {
        if (dividend == null || divisor == null) {
            throw new IllegalArgumentException("E_NULL_NUMBER");
        }
        if (dividend.signum() < 0 || divisor.signum() <= 0) {
            throw new IllegalArgumentException("E_CEILDIV");
        }
        BigInteger[] parts = dividend.divideAndRemainder(divisor);
        return parts[0].add(parts[1].signum() == 0 ? BigInteger.ZERO : BigInteger.ONE);
    }

    public static int wrap1(int position, int size) {
        if (size < 1) {
            throw new IllegalArgumentException("E_WRAP_SIZE");
        }
        return (int) Math.floorMod((long) position - 1L, (long) size) + 1;
    }

    public static BigInteger dayCount(BigInteger day) {
        if (day == null) {
            throw new IllegalArgumentException("E_NULL_DAY");
        }
        BigInteger delta = day.subtract(FOUNDATION_DAY);
        if (delta.signum() < 0) {
            return delta.negate().shiftLeft(1);
        }
        return delta.shiftLeft(1).add(BigInteger.ONE);
    }

    public static WorkCounts workCounts(BigInteger calculationDay, BigInteger targetDay) {
        if (calculationDay == null || targetDay == null) {
            throw new IllegalArgumentException("E_NULL_DAY");
        }
        int order = calculationDay.compareTo(targetDay);
        int direction = order > 0 ? 1 : (order == 0 ? 2 : 3);
        return new WorkCounts(
            dayCount(calculationDay),
            dayCount(targetDay),
            targetDay.subtract(calculationDay).abs().add(BigInteger.ONE),
            dayCount(calculationDay).add(dayCount(targetDay)),
            direction
        );
    }
}
