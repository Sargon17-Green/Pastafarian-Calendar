package pastafari.monster;

class MonsterManager {
    public final dispatcher:MonsterDispatcher;
    public final validationManager:MonsterValidationManager;
    public final metrics:MonsterMetricsShell;

    public function new() {
        dispatcher = new MonsterDispatcher();
        validationManager = new MonsterValidationManager();
        metrics = new MonsterMetricsShell();
    }

    public function bootstrap(ctx:MonsterContext):MonsterContext {
        validationManager.validateContext(ctx);
        metrics.bump(ctx, "bootstrap.calls");
        dispatcher.dispatchBootstrap(ctx);
        validationManager.validateContext(ctx);
        metrics.bump(ctx, "bootstrap.success");
        return ctx;
    }
}
