package org.pastafari.javalojban;

import java.math.BigInteger;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

public final class MonsterContext {
    public final BigInteger calculationDay;
    public final BigInteger targetDay;
    public String phase;
    public String status;
    public final List<String> branchTrace;
    public final Map<String, BigInteger> metrics;
    public final List<String> diagnostics;

    public MonsterContext(BigInteger calculationDay, BigInteger targetDay) {
        this.calculationDay = calculationDay;
        this.targetDay = targetDay;
        this.phase = "BOOT";
        this.status = "NEW";
        this.branchTrace = new ArrayList<>();
        this.metrics = new LinkedHashMap<>();
        this.diagnostics = new ArrayList<>();
    }
}
