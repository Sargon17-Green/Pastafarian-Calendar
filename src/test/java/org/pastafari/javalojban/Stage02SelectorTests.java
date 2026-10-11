package org.pastafari.javalojban;

import java.math.BigInteger;
import java.util.List;

public final class Stage02SelectorTests {
    private static int checks;

    public static void main(String[] args) {
        BigInteger m = MonsterArithmetic.MODULUS;
        for (int step : new int[]{-1, 1}) {
            for (BigInteger first : List.of(BigInteger.ONE, BigInteger.TWO,
                    BigInteger.valueOf(7))) {
                MonsterSauceBowls.AnswerStream actual = new MonsterSauceBowls.AnswerStream(first, step);
                NormativeOracle.AnswerStream oracle = new NormativeOracle.AnswerStream(first, step);
                for (BigInteger n : List.of(BigInteger.ONE, BigInteger.TWO,
                        BigInteger.valueOf(3), BigInteger.valueOf(17),
                        BigInteger.valueOf(720), m.subtract(BigInteger.ONE), m)) {
                    eq(NormativeOracle.chooseRankShort(oracle, n),
                        MonsterSelectors.chooseShort(actual, n), "E_SHORT");
                    eq(MonsterSelectors.chooseShort(actual, n),
                        MonsterSelectors.choose(actual, n), "E_SHORT_DISPATCH");
                }
                for (BigInteger n : List.of(m.add(BigInteger.ONE),
                        m.multiply(m), m.pow(2).add(BigInteger.ONE),
                        m.pow(3).subtract(BigInteger.ONE), m.pow(3).add(BigInteger.valueOf(19)))) {
                    eq(NormativeOracle.chooseRankWide(oracle, n),
                        MonsterSelectors.chooseWide(actual, n), "E_WIDE");
                    eq(MonsterSelectors.chooseWide(actual, n),
                        MonsterSelectors.choose(actual, n), "E_WIDE_DISPATCH");
                }
            }
        }
        MonsterSauceBowls.AnswerStream backward = new MonsterSauceBowls.AnswerStream(m, -1);
        BigInteger shortSize = m.divide(BigInteger.TWO).add(BigInteger.ONE);
        BigInteger shortLimit = m.divide(shortSize).multiply(shortSize);
        eq(shortLimit.subtract(BigInteger.ONE).mod(shortSize).add(BigInteger.ONE),
            MonsterSelectors.chooseShort(backward, shortSize), "E_SHORT_LONG_REJECTION");
        BigInteger space = m.pow(2);
        BigInteger wideSize = space.divide(BigInteger.TWO).add(BigInteger.ONE);
        BigInteger wideLimit = space.divide(wideSize).multiply(wideSize);
        eq(wideLimit.subtract(BigInteger.ONE).mod(wideSize).add(BigInteger.ONE),
            MonsterSelectors.chooseWide(backward, wideSize), "E_WIDE_LONG_REJECTION");
        for (int p = 2; p <= 25; p++) {
            BigInteger n = m.pow(p).subtract(BigInteger.valueOf(p));
            BigInteger rank = MonsterSelectors.choose(backward, n);
            ok(rank.signum() > 0 && rank.compareTo(n) <= 0, "E_LARGE_RANGE");
        }
        MonsterSauceBowls.SauceResult bowls = MonsterSauceBowls.evaluate(
            MonsterArithmetic.FOUNDATION_DAY, MonsterArithmetic.TABLETS_DAY);
        for (int id = 1; id <= 6; id++) {
            for (int seal : new int[]{1, 10, 21, 31, 33}) {
                MonsterSauceBowls.AnswerStream answer = MonsterSauceBowls.ask(bowls, id, seal);
                for (BigInteger n : List.of(BigInteger.ONE, BigInteger.valueOf(720),
                        m, m.add(BigInteger.ONE), m.pow(2).add(BigInteger.ONE))) {
                    BigInteger rank = MonsterSelectors.choose(answer, n);
                    ok(rank.signum() > 0 && rank.compareTo(n) <= 0, "E_ACTUAL_STREAM");
                }
            }
        }
        fails("E_CHOOSE_N", () -> MonsterSelectors.choose(
            new MonsterSauceBowls.AnswerStream(BigInteger.ONE, 1), BigInteger.ZERO));
        fails("E_NULL_ANSWER", () -> MonsterSelectors.choose(null, BigInteger.ONE));
        fails("E_ANSWER_STEP", () -> MonsterSelectors.choose(
            new MonsterSauceBowls.AnswerStream(BigInteger.ONE, 0), BigInteger.ONE));
        fails("E_SHORT_N", () -> MonsterSelectors.chooseShort(
            new MonsterSauceBowls.AnswerStream(BigInteger.ONE, 1), m.add(BigInteger.ONE)));
        fails("E_WIDE_N", () -> MonsterSelectors.chooseWide(
            new MonsterSauceBowls.AnswerStream(BigInteger.ONE, 1), m));
        System.out.println("STAGE_02_SELECTORS_PASS checks=" + checks);
    }

    private static void fails(String code, Runnable action) {
        checks++;
        try {
            action.run();
        } catch (IllegalArgumentException e) {
            if (code.equals(e.getMessage())) return;
            throw new AssertionError("E_WRONG_FAILURE " + code + " actual=" + e.getMessage(), e);
        }
        throw new AssertionError("E_MISSING_FAILURE " + code);
    }

    private static void eq(Object want, Object have, String code) {
        checks++;
        if (!want.equals(have)) throw new AssertionError(code + " expected=" + want + " actual=" + have);
    }

    private static void ok(boolean yes, String code) {
        checks++;
        if (!yes) throw new AssertionError(code);
    }
}
