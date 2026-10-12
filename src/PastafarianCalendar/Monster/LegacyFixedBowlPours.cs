using System.Numerics;

namespace PastafarianCalendar.Monster;

// المصنَع القديم يثبت معرّفات الأوعية من 1 إلى 6؛ لا يخلطها بمواضع الترتيب.
public sealed class LegacyBowlFactory
{
    private static readonly int[] BowlPrimes = { 0, 17, 19, 23, 29, 31, 37 };
    private readonly SavePatchWrapper _save = new();

    public BigInteger[] InitialBowls(MonsterWorkCounts counts)
    {
        if (counts is null)
            throw new MonsterValidationException("خماسية العمل مفقودة من مصنَع الأوعية.");
        var bowls = new BigInteger[7];
        for (var id = 1; id <= 6; id++)
        {
            var initial = counts.Action + counts.Target * id +
                counts.Distance + counts.Connection + counts.Direction +
                BowlPrimes[id] * BowlPrimes[id];
            bowls[id] = _save.SavePatch(initial * initial + id);
        }
        return bowls;
    }
}

// العيب التاسع: ينظر القارئ القديم إلى الأسماء الثابتة 1 و2 و3
// ويظنّ أنها مواضع الصبّ الأولى في الترتيب المتبدّل.
// لا يُمرَّر order إلى الدالة عمداً، ولا توجد خريطة alias في الطور الثامن عشر.
public sealed class LegacyFixedBowlPours
{
    private readonly SavePatchWrapper _save = new();

    public BigInteger[] PourIntoFixedIdentifiers(
        int visibleIndex, BigInteger drop, BigInteger[] bowls, BigInteger[][] stones)
    {
        if (visibleIndex is < 1 or > 46 ||
            bowls is null || bowls.Length != 7 ||
            stones is null || stones.Length != 47 ||
            stones[visibleIndex] is not BigInteger[] row || row.Length != 6)
            throw new MonsterValidationException("مدخلات الصبّ القديم ناقصة أو خارج المجال.");
        for (var id = 1; id <= 6; id++)
            if (bowls[id] <= 0)
                throw new MonsterValidationException("وعاء أولي غير محفوظ أو غير صالح.");

        var pours = new BigInteger[7];
        pours[1] = _save.SavePatch(drop * drop + row[1] * bowls[1] + 3 * visibleIndex);
        pours[2] = _save.SavePatch(drop * drop + row[2] * bowls[2] + 5 * visibleIndex);
        pours[3] = _save.SavePatch(drop * drop + row[3] * bowls[3] + 7 * visibleIndex);
        return pours;
    }
}

public sealed record LegacyPoursCandidate(
    VisibleDropsPatchCandidate Source,
    BigInteger Drop,
    BigInteger[] InitialBowls,
    int[] Order,
    BigInteger[] Pours);

public sealed class LegacyPoursPhaseHandler
{
    private readonly VisibleDropPatchPhaseHandler _visible = new();
    private readonly BowlOrderPatchWrapper _order = new();
    private readonly LegacyBowlFactory _factory = new();
    private readonly LegacyFixedBowlPours _pours = new();

    public LegacyPoursCandidate Handle(MonsterContext context)
    {
        if (context.LegacyPourVisibleIndex is not int i || i is < 1 or > 46)
            throw new MonsterValidationException("رتبة القطرة المطلوبة للصبّ القديم غير صالحة.");
        if (context.LegacyPoursResult is not null)
            throw new MonsterValidationException("لا يجوز تنفيذ الصبّ التاريخي مرتين.");

        var visible = _visible.Handle(context);
        var drop = visible.Visible[i];
        var order = _order.OrderPatchFromValue(drop).Order;
        var bowls = _factory.InitialBowls(visible.Counts);
        var pours = _pours.PourIntoFixedIdentifiers(i, drop, bowls, visible.Stones);
        return new LegacyPoursCandidate(visible, drop, bowls, order, pours);
    }
}
