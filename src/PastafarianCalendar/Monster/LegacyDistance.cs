using System.Numerics;

namespace PastafarianCalendar.Monster;

public static class LegacyDistance
{
    // يظن الطريق القديم أن الفرق بين عدّادَي اليوم المصححين يساوي المسافة الزمنية.
    // لا تُستبدل هذه العملية بفارق اليومين؛ فذلك التصحيح محفوظ للطور السابع.
    public static BigInteger OldDistance(BigInteger calculationDay, BigInteger targetDay)
    {
        var dayCounter = new DayTagPatchWrapper();
        var calculationTag = dayCounter.Patch(calculationDay);
        var targetTag = dayCounter.Patch(targetDay);
        return BigInteger.Abs(calculationTag - targetTag);
    }
}

public sealed class LegacyDistancePhaseHandler
{
    public void Handle(MonsterContext context)
    {
        if (context.LegacyDistanceResult.HasValue)
            throw new MonsterValidationException("لا يجوز إثبات المسافة التاريخية مرتين في سياق واحد.");

        // لا تستعين دالة الإنتاج بالمرجع المعياري؛ بل تمر عبر رقعة عدّ اليوم الثانية.
        var pending = LegacyDistance.OldDistance(context.CalculationDay, context.TargetDay);
        context.LegacyDistanceResult = pending;
    }
}
