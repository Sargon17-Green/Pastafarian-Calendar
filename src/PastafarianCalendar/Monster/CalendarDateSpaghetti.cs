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

    // واجهة التنفيذ التاريخي لعدّ اليوم؛ تُظهر الخلل قبل إضافة الرقعة الثانية.
    public static BigInteger EvaluateLegacyDayTag(BigInteger calculationDay, BigInteger targetDay, BigInteger day)
    {
        var manager = new MonsterManager();
        return manager.EvaluateLegacyDayTag(calculationDay, targetDay, day);
    }

    // الواجهة المعتمدة لعدّ اليوم بعد الرقعة الثانية؛ ولا تتصل بمرجع الاختبار.
    public static BigInteger EvaluateDayTag(BigInteger calculationDay, BigInteger targetDay, BigInteger day)
    {
        var manager = new MonsterManager();
        return manager.EvaluateDayTag(calculationDay, targetDay, day);
    }

    // مسار الحفظ المعتمد منذ الرقعة الأولى؛ لا يستدعي المرجع الاختباري.
    public static BigInteger EvaluateSave(BigInteger calculationDay, BigInteger targetDay, BigInteger value)
    {
        var manager = new MonsterManager();
        return manager.EvaluateSave(calculationDay, targetDay, value);
    }
}
