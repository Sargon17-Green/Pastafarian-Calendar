namespace Pastafari.ProductionBaseline {
    import Pastafari.CanonicalCore.*;
    import Pastafari.MonsterInfrastructure.*;

    function CalendarDateSpaghetti(calculationDay : BigInt, targetDay : BigInt) : CalendarResult {
        let initialContext = NewBaseMonsterContext(calculationDay,targetDay);
        let dispatched = BaseDispatcher(initialContext);
        if not dispatched.Accepted {
            fail "Bootstrap ディスパッチャが呼び出しを拒否しました。";
        }
        if dispatched.Context.CommitToken != 1 {
            fail "Bootstrap コンテキストの commit token が不正です。";
        }
        return CalendarDateCore(calculationDay,targetDay);
    }
}
