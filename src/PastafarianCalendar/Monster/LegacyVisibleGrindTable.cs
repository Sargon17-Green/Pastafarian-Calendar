namespace PastafarianCalendar.Monster;

// صفّ المعاملات غير قابل للتغيير، ولا يُعاد ترقيم الجدول قبل مرحلة الرقعة السابعة.
public readonly record struct LegacyGrindRow(int A, int B, int C, int D, int StoneKind);

public static class LegacyVisibleGrindTable
{
    // إحدى عشرة سطراً حقيقياً بفهرسة فيزيائية من الصفر، بلا صفّ حارس.
    // السطر الفيزيائي 0 هو الطحن الأول، والسطر 10 هو الطحن الحادي عشر.
    private static readonly LegacyGrindRow[] PhysicalRows =
    {
        new(3, 5, 7, 11, 1),
        new(5, 7, 11, 13, 2),
        new(7, 11, 13, 17, 3),
        new(11, 13, 17, 19, 4),
        new(13, 17, 19, 23, 5),
        new(17, 19, 23, 29, 1),
        new(19, 23, 29, 31, 2),
        new(23, 29, 31, 37, 3),
        new(29, 31, 37, 41, 4),
        new(31, 37, 41, 43, 5),
        new(37, 41, 43, 47, 1)
    };

    // الفرضية الخاطئة: رقم الطحن الكنسي الواحدي يصلح مباشرةً فهرساً صفرياً.
    // لذلك يختار 1 السطر الثاني، وينتهي 11 إلى استثناء فهرسة مصفوفة.
    // يجب ألا تُضاف ترجمة (ordinal-1) ولا صفّ الحارس قبل الطور الخامس عشر.
    public static LegacyGrindRow LegacyGrindRow(int oneBasedOrdinal)
        => PhysicalRows[oneBasedOrdinal];
}

public sealed class LegacyGrindTableAdapter
{
    public LegacyGrindRow Read(int oneBasedOrdinal)
        => LegacyVisibleGrindTable.LegacyGrindRow(oneBasedOrdinal);
}

public sealed class LegacyVisibleGrindPhaseHandler
{
    private readonly LegacyGrindTableAdapter _adapter = new();

    // لا نُثبت أي نتيجة في السياق قبل نجاح فهرسة الجدول؛
    // الاستثناء التاريخي عند الرقم 11 يترك السياق بلا نتيجة معتمدة.
    public LegacyGrindRow Handle(MonsterContext context)
    {
        if (context.LegacyGrindOrdinal is not int ordinal)
            throw new MonsterValidationException("لم يُقدَّم رقم الطحن التاريخي.");
        if (context.LegacyGrindResult.HasValue)
            throw new MonsterValidationException("لا يجوز إثبات صفّ الطحن القديم مرتين.");
        return _adapter.Read(ordinal);
    }
}
