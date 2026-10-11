using System.Numerics;

namespace PastafarianCalendar.Monster;

public sealed class DayTagPatchWrapper
{
    private static readonly BigInteger FoundationDay = new(-15055671);

    // يبقى العدّ القديم خاطئاً عمداً؛ يُستدعى فعلياً من الغلاف ولا يُعدَّل في مصدره.
    public BigInteger Patch(BigInteger day)
    {
        var count = LegacyDayTag.OldDayTag(day);

        // على جانب التأسيس وما بعده تضيع الوحدة الأولى من العدّ القديم.
        if (day >= FoundationDay)
            count += BigInteger.One;

        // حارس تاريخي زائد يُحفظ بوصفه ندبةً مستقلةً عن التصحيح الأول.
        if (day == FoundationDay && count != BigInteger.One)
            count = BigInteger.One;

        return count;
    }
}
