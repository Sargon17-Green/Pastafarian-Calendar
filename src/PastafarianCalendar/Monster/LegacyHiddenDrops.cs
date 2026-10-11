using System.Numerics;

namespace PastafarianCalendar.Monster;

public static class LegacyHiddenDrops
{
    // كُتبت معاملات القطرات في الجدول التاريخي من الأبعد إلى الأقرب.
    // تُستخرج معاملات القطرة k من موضعها في هذا الترتيب الغريب، بلا تغيير الجدول.
    private static readonly int[][] ReversedCoefficients =
    {
        new[] { 15, 22, 30, 32 },
        new[] { 13, 19, 26, 28 },
        new[] { 11, 16, 22, 24 },
        new[] { 9, 13, 18, 20 },
        new[] { 7, 10, 14, 16 },
        new[] { 5, 7, 10, 12 },
        new[] { 3, 4, 6, 8 }
    };

    // فهرس صفر للحارس، والطحنات الحقيقية تبدأ من الواحد.
    private static readonly int[] GrindStoneKinds = { 0, 1, 2, 3, 4, 5, 1, 2 };
    private static readonly SavePatchWrapper Save = new();

    public static BigInteger MakeHiddenDrop(int k, MonsterWorkCounts counts, BigInteger[][] stones)
    {
        if (k is < 1 or > 7)
            throw new MonsterValidationException("رقم القطرة الخفية خارج مجال القطرات السبع.");
        if (counts is null || stones is null || stones.Length != 47 ||
            stones[k] is not BigInteger[] row || row.Length != 6)
            throw new MonsterValidationException("مُدخلات الحجر أو العدّ غير مكتملة.");

        var coeff = ReversedCoefficients[7 - k];
        var x = counts.Action
                + coeff[0] * counts.Target
                + coeff[1] * counts.Distance
                + coeff[2] * counts.Connection
                + coeff[3] * counts.Direction;
        for (var kind = 1; kind <= 5; kind++)
            x += row[kind];

        x = Save.SavePatch(x);
        for (var grind = 1; grind <= 7; grind++)
        {
            var old = x;
            x = Save.SavePatch(old * old + 3 * old + row[GrindStoneKinds[grind]] + grind);
        }
        return x;
    }

    // تكتب هذه النسخة الخاطئة القطرات بالعكس: الخانة 1 تحمل الخفية 7.
    // لا يُنشأ في هذا الطور مترجمٌ عاماً لمواضع القراءة؛ ذلك من الرقعة الخامسة.
    public static BigInteger[] BuildBackwardStorage(MonsterWorkCounts counts, BigInteger[][] stones)
    {
        var storage = new BigInteger[8];
        for (var k = 1; k <= 7; k++)
            storage[8 - k] = MakeHiddenDrop(k, counts, stones);
        return storage;
    }
}

public sealed class LegacyHiddenDropsPhaseHandler
{
    private readonly PatchedCounts _counts = new();
    private readonly StonePatchWrapper _stones = new();

    public void Handle(MonsterContext context)
    {
        if (context.LegacyHiddenReversed is not null)
            throw new MonsterValidationException("لا تُثبَّت القطرات التاريخية مرتين في السياق.");

        // لا يوجد اتصال بمرجع الاختبار؛ كلا المسارين من الرقعتين القائمتين في الإنتاج.
        var counts = _counts.Calculate(context.CalculationDay, context.TargetDay);
        var stones = _stones.BuildPatchedRows();
        var pending = LegacyHiddenDrops.BuildBackwardStorage(counts, stones);
        context.LegacyHiddenReversed = pending;
    }
}
