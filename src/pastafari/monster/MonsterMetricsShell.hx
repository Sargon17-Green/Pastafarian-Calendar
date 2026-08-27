package pastafari.monster;

class MonsterMetricsShell {
    public function new() {}

    public function bump(ctx:MonsterContext, key:String):Void {
        var old = ctx.metrics.get(key);
        ctx.metrics.set(key, old == null ? 1 : old + 1);
    }
}
