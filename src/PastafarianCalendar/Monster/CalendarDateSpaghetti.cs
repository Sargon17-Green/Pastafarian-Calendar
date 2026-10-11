using System.Numerics;

namespace PastafarianCalendar.Monster;

public static class CalendarDateSpaghetti
{
    public static MonsterContext BootstrapInvocation(BigInteger calculationDay, BigInteger targetDay)
    {
        var manager = new MonsterManager();
        return manager.Prepare(calculationDay, targetDay);
    }

    // مدخل إنتاجي حقيقي لمسار الحفظ القديم؛ ليس استدعاءً للمرجع الاختباري.
    public static BigInteger EvaluateLegacySave(BigInteger calculationDay, BigInteger targetDay, BigInteger value)
    {
        var manager = new MonsterManager();
        return manager.EvaluateLegacySave(calculationDay, targetDay, value);
    }
}
