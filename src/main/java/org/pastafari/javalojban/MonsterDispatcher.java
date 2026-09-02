package org.pastafari.javalojban;

public final class MonsterDispatcher {
    private final MonsterValidationManager validationManager;
    private final MonsterMetrics metrics;

    public MonsterDispatcher(MonsterValidationManager validationManager, MonsterMetrics metrics) {
        this.validationManager = validationManager;
        this.metrics = metrics;
    }

    public MonsterContext dispatchBootstrap(MonsterContext context) {
        context.phase = "ENTRY_VALIDATION";
        context.branchTrace.add("ENTRY_VALIDATION");
        validationManager.validateEntry(context);
        metrics.bump(context, "bootstrap.entry");

        context.phase = "BASE_CONTEXT_READY";
        context.branchTrace.add("BASE_CONTEXT_READY");
        validationManager.validateBootstrapState(context);
        metrics.bump(context, "bootstrap.context.ready");

        context.status = "READY";
        return context;
    }
}
