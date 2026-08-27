package pastafari.monster;

import haxe.ds.StringMap;
import pastafari.math.BigInt;

class MonsterContext {
    public final calculationDay:BigInt;
    public final targetDay:BigInt;
    public var phase:String;
    public var subPhase:Int;
    public var mode:String;
    public var status:String;
    public var retryBudget:Int;
    public var recoveryDepth:Int;
    public var currentHandler:String;
    public var previousHandler:String;
    public final branchTrace:Array<String>;
    public final metrics:StringMap<Int>;
    public final logs:Array<String>;
    public final diagnostics:Array<String>;
    public final warnings:Array<String>;
    public var lastError:Null<String>;

    public function new(calculationDay:BigInt, targetDay:BigInt) {
        this.calculationDay = calculationDay.copy();
        this.targetDay = targetDay.copy();
        this.phase = "BOOTSTRAP";
        this.subPhase = 0;
        this.mode = "NEUTRAL";
        this.status = "NEW";
        this.retryBudget = 0;
        this.recoveryDepth = 0;
        this.currentHandler = "NONE";
        this.previousHandler = "NONE";
        this.branchTrace = [];
        this.metrics = new StringMap<Int>();
        this.logs = [];
        this.diagnostics = [];
        this.warnings = [];
        this.lastError = null;
    }
}
