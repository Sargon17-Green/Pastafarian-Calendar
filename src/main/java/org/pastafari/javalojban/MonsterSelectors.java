package org.pastafari.javalojban;

import java.math.BigInteger;

public final class MonsterSelectors {
    private static final BigInteger ONE = BigInteger.ONE;
    private static final BigInteger M = MonsterArithmetic.MODULUS;

    private MonsterSelectors() {}

    private static void validate(MonsterSauceBowls.AnswerStream stream) {
        if (stream == null || stream.first() == null) {
            throw new IllegalArgumentException("E_NULL_ANSWER");
        }
        if (stream.directionStep() != 1 && stream.directionStep() != -1) {
            throw new IllegalArgumentException("E_ANSWER_STEP");
        }
    }

    private static BigInteger accept(BigInteger value, BigInteger limit,
                                     BigInteger choices, int direction) {
        BigInteger accepted = value.compareTo(limit) <= 0
            ? value : direction == 1 ? ONE : limit;
        return accepted.subtract(ONE).mod(choices).add(ONE);
    }

    public static BigInteger chooseShort(MonsterSauceBowls.AnswerStream stream,
                                         BigInteger choices) {
        validate(stream);
        if (choices == null || choices.signum() <= 0 || choices.compareTo(M) > 0) {
            throw new IllegalArgumentException("E_SHORT_N");
        }
        BigInteger limit = M.divide(choices).multiply(choices);
        BigInteger first = MonsterSauceBowls.answerAt(stream, BigInteger.ZERO);
        return accept(first, limit, choices, stream.directionStep());
    }

    public static BigInteger chooseWide(MonsterSauceBowls.AnswerStream stream,
                                        BigInteger choices) {
        validate(stream);
        if (choices == null || choices.compareTo(M) <= 0) {
            throw new IllegalArgumentException("E_WIDE_N");
        }
        BigInteger space = M;
        int places = 1;
        while (space.compareTo(choices) < 0) {
            space = space.multiply(M);
            places++;
        }
        BigInteger value = ONE;
        BigInteger weight = ONE;
        for (int j = 0; j < places; j++) {
            BigInteger digit = MonsterSauceBowls.answerAt(
                stream, BigInteger.valueOf(j)).subtract(ONE);
            value = value.add(digit.multiply(weight));
            weight = weight.multiply(M);
        }
        BigInteger limit = space.divide(choices).multiply(choices);
        return accept(value, limit, choices, stream.directionStep());
    }

    public static BigInteger choose(MonsterSauceBowls.AnswerStream stream,
                                    BigInteger choices) {
        validate(stream);
        if (choices == null || choices.signum() <= 0) {
            throw new IllegalArgumentException("E_CHOOSE_N");
        }
        return choices.compareTo(M) <= 0
            ? chooseShort(stream, choices) : chooseWide(stream, choices);
    }
}
