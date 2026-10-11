package org.pastafari.javalojban;

import java.math.BigInteger;

public final class MonsterCanonicalWeaving {
    private static final int BOWL = 4;
    private static final int SEAL = 32;

    public static final class Selection {
        private final BigInteger rank;
        private final BigInteger possibilities;
        private final int[] weaving;

        private Selection(BigInteger rank, BigInteger possibilities, int[] weaving) {
            this.rank = rank;
            this.possibilities = possibilities;
            this.weaving = weaving.clone();
        }

        public BigInteger rank() { return rank; }
        public BigInteger possibilities() { return possibilities; }
        public int[] weavingCopy() { return weaving.clone(); }
        public int length() { return weaving.length; }
    }

    private MonsterCanonicalWeaving() {}

    public static Selection fromSauce(MonsterSauceBowls.SauceResult sauce, int[] lengths) {
        if (sauce == null) throw new IllegalArgumentException("E_NULL_SAUCE");
        MonsterWeavingEndpointDP family = new MonsterWeavingEndpointDP(lengths);
        int days = 0;
        for (int length : lengths) days += length;
        if (days > MonsterWeavingEndpointDP.MAX_UNRANK_DAYS) {
            throw new IllegalArgumentException("E_WEAVE_UNRANK_LIMIT");
        }
        BigInteger choices = family.count();
        BigInteger rank = MonsterSelectors.choose(
            MonsterSauceBowls.ask(sauce, BOWL, SEAL), choices);
        return new Selection(rank, choices, family.unrank1(rank));
    }

    public static Selection fromDays(BigInteger calculationDay, BigInteger firstYearDay,
                                     int[] lengths) {
        if (calculationDay == null || firstYearDay == null) {
            throw new IllegalArgumentException("E_NULL_DAY");
        }
        return fromSauce(MonsterSauceBowls.evaluate(calculationDay, firstYearDay), lengths);
    }
}
