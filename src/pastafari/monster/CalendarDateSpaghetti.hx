package pastafari.monster;

import pastafari.math.BigInt;

class CalendarDateSpaghetti {
    public static function bootstrapContext(calculationDay:BigInt, targetDay:BigInt):MonsterContext {
        var manager = new MonsterManager();
        return manager.bootstrap(new MonsterContext(calculationDay, targetDay));
    }

    public static function calendarDateSpaghetti(calculationDay:BigInt, targetDay:BigInt):Dynamic {
        bootstrapContext(calculationDay, targetDay);
        throw "Produktionsvägen är avsiktligt bara ett neutralt skelett i steg 1";
    }
}
