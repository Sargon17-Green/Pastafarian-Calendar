package pastafari.monster;

class MonsterValidationManager {
    public function new() {}

    public function validateContext(ctx:MonsterContext):Void {
        if (ctx == null) throw "Kontexten saknas";
        if (ctx.calculationDay == null || ctx.targetDay == null) throw "En dag saknas i kontexten";
        if (ctx.phase == null || ctx.status == null) throw "Livscykeltillståndet är ofullständigt";
    }
}
