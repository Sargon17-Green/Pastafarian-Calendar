package org.pastafari.javalojban;

import java.math.BigInteger;

public final class MonsterMetrics {
    public void bump(MonsterContext context, String key) {
        context.metrics.merge(key, BigInteger.ONE, BigInteger::add);
    }
}
