package org.pastafari.javalojban;

import java.math.BigInteger;
import java.util.ArrayList;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

public final class MonsterEvaluation {
    private final BigInteger calculationDay;
    private final BigInteger targetDay;
    private final String phase;
    private final String status;
    private final List<String> branchTrace;
    private final Map<String, BigInteger> metrics;
    private final List<String> diagnostics;
    private final MonsterSauceBowls.SauceResult sauce;

    MonsterEvaluation(MonsterContext context, MonsterSauceBowls.SauceResult sauce) {
        this.calculationDay = context.calculationDay;
        this.targetDay = context.targetDay;
        this.phase = context.phase;
        this.status = context.status;
        this.branchTrace = List.copyOf(context.branchTrace);
        this.metrics = Collections.unmodifiableMap(new LinkedHashMap<>(context.metrics));
        this.diagnostics = List.copyOf(context.diagnostics);
        this.sauce = sauce;
    }

    public BigInteger calculationDay() {
        return calculationDay;
    }

    public BigInteger targetDay() {
        return targetDay;
    }

    public String phase() {
        return phase;
    }

    public String status() {
        return status;
    }

    public List<String> branchTrace() {
        return branchTrace;
    }

    public Map<String, BigInteger> metrics() {
        return metrics;
    }

    public List<String> diagnostics() {
        return diagnostics;
    }

    public MonsterSauceBowls.SauceResult sauce() {
        return sauce;
    }

    public BigInteger choose(int bowlId, int seal, BigInteger choices) {
        return MonsterSelectors.choose(MonsterSauceBowls.ask(sauce, bowlId, seal), choices);
    }
}
