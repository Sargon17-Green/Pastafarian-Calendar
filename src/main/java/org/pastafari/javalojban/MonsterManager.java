package org.pastafari.javalojban;

import java.math.BigInteger;

public final class MonsterManager {
    private final MonsterDispatcher dispatcher;
    private final MonsterErrorBoundary errorBoundary;

    public MonsterManager() {
        MonsterValidationManager validationManager = new MonsterValidationManager();
        MonsterMetrics metrics = new MonsterMetrics();
        this.dispatcher = new MonsterDispatcher(validationManager, metrics);
        this.errorBoundary = new MonsterErrorBoundary();
    }

    public MonsterContext bootstrap(BigInteger calculationDay, BigInteger targetDay) {
        MonsterContext context = new MonsterContext(calculationDay, targetDay);
        return errorBoundary.execute(() -> dispatcher.dispatchBootstrap(context));
    }
}
