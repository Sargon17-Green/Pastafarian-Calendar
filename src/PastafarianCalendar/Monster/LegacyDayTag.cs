using System.Numerics;

namespace PastafarianCalendar.Monster;

public static class LegacyDayTag
{
    private static readonly BigInteger FoundationDay = new(-15055671);

    // ظنّ التنفيذ القديم أن المسافة المضاعفة تكفي لترقيم اليوم على كلا جانبي التأسيس.
    // لا تُضاف هنا وحدة التصحيح المطلوبة ابتداءً من التأسيس؛ فهي من شأن الطور الخامس.
    public static BigInteger OldDayTag(BigInteger day)
    {
        return 2 * BigInteger.Abs(day - FoundationDay);
    }
}

public sealed class LegacyDayTagPhaseHandler
{
    public void Handle(MonsterContext context)
    {
        if (context.LegacyDayInput is not BigInteger day)
            throw new MonsterValidationException("لم يُقدَّم اليوم المطلوب إلى عدّاد اليوم القديم.");
        if (context.LegacyDayTagResult.HasValue)
            throw new MonsterValidationException("لا يجوز إثبات عدّ اليوم القديم مرتين في السياق نفسه.");

        var pending = LegacyDayTag.OldDayTag(day);
        context.LegacyDayTagResult = pending;
    }
}
