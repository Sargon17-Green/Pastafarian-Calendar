using System.Numerics;

namespace PastafarianCalendar.Monster;

// لا تُصحَّح دالة الصبّ القديمة؛ تُركَّب الأسماء المؤقتة بين المواضع وهويات الأوعية.
public sealed class BowlAliasPatchWrapper
{
    private readonly SavePatchWrapper _save = new();

    public int[] InstallOrderAliases(int[] order)
    {
        if (order is null || order.Length != 6 ||
            !order.OrderBy(x => x).SequenceEqual(new[] {1,2,3,4,5,6}))
            throw new MonsterValidationException("لا يُنشأ اسم بديل دون ترتيب كامل للأوعية.");

        var bowlAlias = new int[7];
        for (var position = 1; position <= 6; position++)
            bowlAlias[position] = order[position - 1];
        return bowlAlias;
    }

    public BigInteger BowlByLegacyPosition(BigInteger[] oldB, int[] bowlAlias, int position)
    {
        if (position is < 1 or > 6 || oldB is null || oldB.Length != 7 ||
            bowlAlias is null || bowlAlias.Length != 7 ||
            bowlAlias[0] != 0 ||
            !bowlAlias.Skip(1).OrderBy(x => x).SequenceEqual(new[] {1,2,3,4,5,6}))
            throw new MonsterValidationException("لا يمكن ترجمة موضع وعاء بغير خريطة بديلة سليمة.");
        var bowlId = bowlAlias[position];
        if (oldB[bowlId] < BigInteger.One)
            throw new MonsterValidationException("قيمة الوعاء ذي الاسم البديل غير صالحة.");
        return oldB[bowlId];
    }

    public BigInteger[] PatchedPours(
        int visibleIndex, BigInteger drop, BigInteger[][] stones,
        BigInteger[] oldB, int[] bowlAlias)
    {
        if (visibleIndex is < 1 or > 46 || stones is null ||
            stones.Length != 47 || stones[visibleIndex] is not BigInteger[] row ||
            row.Length != 6)
            throw new MonsterValidationException("صفّ أحجار القطرة اللازمة للصبّ غير مكتمل.");

        var pours = new BigInteger[7];
        pours[1] = _save.SavePatch(drop * drop +
            row[1] * BowlByLegacyPosition(oldB,bowlAlias,1) + 3*visibleIndex);
        pours[2] = _save.SavePatch(drop * drop +
            row[2] * BowlByLegacyPosition(oldB,bowlAlias,2) + 5*visibleIndex);
        pours[3] = _save.SavePatch(drop * drop +
            row[3] * BowlByLegacyPosition(oldB,bowlAlias,3) + 7*visibleIndex);
        return pours;
    }
}

public sealed record BowlAliasPatchCandidate(
    LegacyPoursCandidate Legacy,
    int[] Aliases,
    BigInteger[] PatchedPours);

public sealed class BowlAliasPatchPhaseHandler
{
    private readonly LegacyPoursPhaseHandler _old = new();
    private readonly BowlAliasPatchWrapper _alias = new();

    public BowlAliasPatchCandidate Handle(MonsterContext context)
    {
        // المعالج القديم يعمل أولاً لإثبات خطئه الفعلي، ولا تتغير دالته.
        var legacy = _old.Handle(context);
        var map = _alias.InstallOrderAliases(legacy.Order);
        var patched = _alias.PatchedPours(
            context.LegacyPourVisibleIndex!.Value,legacy.Drop,legacy.Source.Stones,
            legacy.InitialBowls,map);
        return new BowlAliasPatchCandidate(legacy,map,patched);
    }
}
