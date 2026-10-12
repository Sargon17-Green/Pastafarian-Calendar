using System.Numerics;

namespace PastafarianCalendar.Monster;

// الخطأ العاشر: تُقرأ كل الجارات من وعاء حيّ سُجّل فيه ناتج الموضع السابق.
// يبقى هذا الخلل قائماً؛ لا توجد صورة vaultOld أو مصفوفة pending للكتابة هنا.
public sealed class LegacyInPlaceBowlStir
{
    private static readonly int[] StoneByPosition = { 0,1,2,3,4,5,1 };
    private readonly SavePatchWrapper _save = new();

    public void StirDirectlyIntoBowls(
        BigInteger[] bowls, int visibleIndex, BigInteger drop,
        BigInteger[][] stones, int[] order, BigInteger[] pours)
    {
        if (bowls is null || bowls.Length != 7 || bowls[0] != 0 ||
            stones is null || stones.Length != 47 ||
            visibleIndex is < 1 or > 46 ||
            stones[visibleIndex] is not BigInteger[] row || row.Length != 6 ||
            order is null || order.Length != 6 ||
            !order.OrderBy(x => x).SequenceEqual(new[] {1,2,3,4,5,6}) ||
            pours is null || pours.Length != 7 ||
            pours[0] != 0 || pours[4] != 0 || pours[5] != 0 || pours[6] != 0)
            throw new MonsterValidationException("مدخلات التحريك التاريخي ناقصة أو فاسدة.");

        for (var id=1; id<=6; id++)
            if (bowls[id] < BigInteger.One)
                throw new MonsterValidationException("وعاء حيّ غير صالح قبل التحريك.");

        for (var position=1; position<=6; position++)
        {
            var bowlId=order[position-1];
            var previousId=order[(position+4)%6];
            var nextId=order[position%6];

            // العيب: تقرأ هذه الصيغة B مباشرةً في جميع المواضع،
            // مع أن B[bowlId] قد كُتب بالفعل في دورة سابقة.
            var s=bowls[bowlId]+2*bowls[previousId]+3*bowls[nextId]+
                  pours[position]+drop+row[StoneByPosition[position]];
            bowls[bowlId]=_save.SavePatch(
                s*s+5*bowls[previousId]*bowls[nextId]+visibleIndex*position);
        }
    }
}

public sealed record LegacyInPlaceStirCandidate(
    BowlAliasPatchCandidate Source, BigInteger[] MutatedBowls);

public sealed class LegacyInPlaceBowlStirPhaseHandler
{
    private readonly BowlAliasPatchPhaseHandler _previous=new();
    private readonly LegacyInPlaceBowlStir _old=new();

    public LegacyInPlaceStirCandidate Handle(MonsterContext context)
    {
        if (context.LegacyPourVisibleIndex is not int index ||
            index is < 1 or > 46 ||
            context.LegacyStirredBowls is not null)
            throw new MonsterValidationException("لم تُحدَّد القطرة أو سبق التحريك القديم.");

        var source=_previous.Handle(context);
        // يُنسخ وعاء البداية لحماية شهادة المصنع، لا للاستخدام في قراءات التحريك.
        var live=(BigInteger[])source.Legacy.InitialBowls.Clone();
        _old.StirDirectlyIntoBowls(live,index,source.Legacy.Drop,
            source.Legacy.Source.Stones,source.Legacy.Order,source.PatchedPours);
        return new LegacyInPlaceStirCandidate(source,live);
    }
}
