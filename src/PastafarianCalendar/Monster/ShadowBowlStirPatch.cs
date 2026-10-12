using System.Numerics;

namespace PastafarianCalendar.Monster;

// الرقعة العاشرة: لا نغيّر التحريك التاريخي الملوَّث ولا نستبدله في مكانه.
public sealed record ShadowBowlStirResult(
    BigInteger[] VaultOld, BigInteger[] Pending, BigInteger[] Committed);

public sealed class ShadowBowlStirPatch
{
    private static readonly int[] StoneByPosition = { 0,1,2,3,4,5,1 };
    private readonly SavePatchWrapper _save = new();

    public ShadowBowlStirResult StirOneDropViaShadow(
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
            throw new MonsterValidationException("بيانات التحريك المصحح غير مكتملة.");

        for(var id=1;id<=6;id++)
            if(bowls[id]<1 || pours[id]<0)
                throw new MonsterValidationException("وعاء أو صبّة غير صالحين للتحريك.");

        // يثبت مخزن القراءة مرة واحدة قبل أول عملية مزج.
        var vaultOld=(BigInteger[])bowls.Clone();
        // لا تُكتب أي نتيجة إلى الأوعية الحية أثناء حساب المواضع الستة.
        var pending=(BigInteger[])bowls.Clone();

        for(var position=1;position<=6;position++)
        {
            var id=order[position-1];
            var prev=order[(position+4)%6];
            var next=order[position%6];
            var s=vaultOld[id]+2*vaultOld[prev]+3*vaultOld[next]+
                pours[position]+drop+row[StoneByPosition[position]];
            pending[id]=_save.SavePatch(
                s*s+5*vaultOld[prev]*vaultOld[next]+visibleIndex*position);
        }

        // التزام مُرجأ واحد بعد اكتمال جميع القيم؛ يبقى مخزن القراءة كما كان.
        for(var id=1;id<=6;id++)
            bowls[id]=pending[id];

        return new ShadowBowlStirResult(vaultOld,pending,bowls);
    }
}

public sealed record ShadowBowlStirCandidate(
    LegacyInPlaceStirCandidate Legacy, ShadowBowlStirResult Patched);

public sealed class ShadowBowlStirPhaseHandler
{
    private readonly LegacyInPlaceBowlStirPhaseHandler _old=new();
    private readonly ShadowBowlStirPatch _patch=new();

    public ShadowBowlStirCandidate Handle(MonsterContext context)
    {
        if(context.LegacyPourVisibleIndex is not int index ||
           index is < 1 or > 46 ||
           context.LegacyStirredBowls is not null ||
           context.PatchedStirredBowls is not null)
            throw new MonsterValidationException("القطرة غير محددة أو استُخدم السياق قبل الرقعة.");

        // يُستدعى المعالج القديم فعلياً، ولا تُزال شهادة التلوث التاريخي.
        var legacy=_old.Handle(context);
        // يستقبل الغلاف نسخة من الحالة الأولية، لا ذاكرة شهادة المخزن القديم.
        var target=(BigInteger[])legacy.Source.Legacy.InitialBowls.Clone();
        var patched=_patch.StirOneDropViaShadow(
            target,index,legacy.Source.Legacy.Drop,
            legacy.Source.Legacy.Source.Stones,legacy.Source.Legacy.Order,
            legacy.Source.PatchedPours);
        return new ShadowBowlStirCandidate(legacy,patched);
    }
}
