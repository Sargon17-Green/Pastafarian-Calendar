package pastafari.monster;

class MonsterDispatcher {
    public function new() {}

    public function dispatchBootstrap(ctx:MonsterContext):Void {
        ctx.previousHandler = ctx.currentHandler;
        ctx.currentHandler = "BootstrapHandler";
        ctx.branchTrace.push("BOOTSTRAP_ENTER");
        ctx.phase = "BOOTSTRAP_READY";
        ctx.status = "SKELETON_READY";
    }
}
