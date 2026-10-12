using System.Numerics;

namespace PastafarianCalendar.Monster;

public static class SentinelVisibleGrindPatch
{
    // حارس غير قابل للحذف يبقى فعلياً في الخانة الصفرية.
    public static readonly LegacyGrindRow SENTINEL_GRIND_ROW = new(0, 0, 0, 0, 0);

    // نُعيد نسخ الصفوف الحقيقية نفسها خلف الحارس، ولا نصلح PhysicalRows القديمة.
    private static readonly LegacyGrindRow[] GRIND_TABLE_WITH_SENTINEL =
    {
        SENTINEL_GRIND_ROW,
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

    public static LegacyGrindRow GrindRowWithSentinel(int oneBasedGrind)
    {
        if (oneBasedGrind is < 1 or > 11)
            throw new MonsterValidationException("رقم الطحن خارج جدول الحارس ذي الطحْنات الإحدى عشرة.");

        var candidate = GRIND_TABLE_WITH_SENTINEL[oneBasedGrind];

        // القراءة القديمة لا تزال عملاً حقيقياً هنا بالفهرس الفيزيائي الأصلي.
        // تبقى الدالة القديمة خاطئة عند ورود الرقم الواحدي إليها مباشرةً.
        var historicalPhysicalRow = LegacyVisibleGrindTable.LegacyGrindRow(oneBasedGrind - 1);
        if (candidate != historicalPhysicalRow)
            throw new MonsterValidationException("صفّ الحارس يخالف صفّ الطحْن التاريخي الفيزيائي.");
        return candidate;
    }
}

// تظل السجلات والمصفوفات الناتجة مملوكة للسياق الذي أنشأها.
public sealed record VisibleDropsPatchCandidate(
    MonsterWorkCounts Counts,
    BigInteger[][] Stones,
    BigInteger[] ReversedHiddenStorage,
    HiddenNearnessWrapper HiddenAccessor,
    BigInteger[] Visible);

public sealed class LegacyVisibleDropBuilder
{
    private readonly PriorAccessWrapper _prior = new();
    private readonly SavePatchWrapper _save = new();

    // تُستخدم رقعات العدّ والأحجار والقطرات المخفية والرجوع الفعلية.
    // لا تدخل هنا أية خريطة أو قيمة متوقعة من مرجع الاختبار.
    public BigInteger[] VisibleDropThroughCurrentLayers(
        MonsterWorkCounts counts,
        BigInteger[][] stones,
        HiddenNearnessWrapper hidden)
    {
        if (counts is null || stones is null || stones.Length != 47 ||
            hidden is null)
            throw new MonsterValidationException("لا يمكن بناء القطرات قبل إكمال الطبقات السابقة.");

        var visible = new BigInteger[47];
        for (var i = 1; i <= 46; i++)
        {
            var row = stones[i];
            if (row is null || row.Length != 6)
                throw new MonsterValidationException("صفّ الأحجار المطلوب للقطرة ناقص.");

            // تُقرأ القطرات السابقة من الغلاف السادس، لا من مخزنٍ مجتزأ للقطرات.
            var prev1 = _prior.Read(visible, hidden, i, 1);
            var prev3 = _prior.Read(visible, hidden, i, 3);
            var prev7 = _prior.Read(visible, hidden, i, 7);

            var x = _save.SavePatch(
                row[1] * counts.Action +
                row[2] * counts.Target +
                row[3] * counts.Distance +
                row[4] * counts.Connection +
                row[5] * counts.Direction +
                prev1 + 3 * prev3 + 5 * prev7 + i);

            for (var grind = 1; grind <= 11; grind++)
            {
                var old = x;
                var coeff = SentinelVisibleGrindPatch.GrindRowWithSentinel(grind);
                x = _save.SavePatch(old * old +
                    coeff.A * old + coeff.B * prev1 +
                    coeff.C * prev3 + coeff.D * prev7 +
                    row[coeff.StoneKind]);
            }
            visible[i] = x;
        }
        return visible;
    }
}

public sealed class VisibleDropPatchPhaseHandler
{
    private readonly PatchedCounts _counts = new();
    private readonly StonePatchWrapper _stones = new();
    private readonly LegacyVisibleDropBuilder _builder = new();

    public VisibleDropsPatchCandidate Handle(MonsterContext context)
    {
        var counts = _counts.Calculate(context.CalculationDay, context.TargetDay);
        var stones = _stones.BuildPatchedRows();
        var historicalHidden = LegacyHiddenDrops.BuildBackwardStorage(counts, stones);
        var hidden = new HiddenNearnessWrapper(historicalHidden);
        var visible = _builder.VisibleDropThroughCurrentLayers(counts, stones, hidden);
        return new VisibleDropsPatchCandidate(counts, stones, historicalHidden, hidden, visible);
    }
}
