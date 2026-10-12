using System.Numerics;
namespace PastafarianCalendar.Monster;

public sealed record LegacyOverwrittenSauceCandidate(
    VisibleDropsPatchCandidate Source,
    BigInteger[] BowlsAfterDrops,
    BigInteger[] FinalBowls,
    int[] DiagnosticDrop46Order,
    int[] OverwrittenQueryOrder,
    int[][] PostStirOrders);

// المسار التاريخي يبني جميع القطرات والمزائج، لكنه يفقد ترتيب آخر قطرة.
public sealed class LegacyOverwrittenDrop46Sauce
{
    private readonly VisibleDropsPatchPhaseHandler _visible=new();
    private readonly LegacyBowlFactory _factory=new();
    private readonly BowlOrderPatchWrapper _order=new();
    private readonly BowlAliasPatchWrapper _alias=new();
    private readonly ShadowBowlStirPatch _stir=new();
    private readonly LegacyPostStirRound _post=new();

    public LegacyOverwrittenSauceCandidate Evaluate(MonsterContext context)
    {
        if(context.LegacySauceFinalBowls is not null ||
           context.LegacyOverwrittenQueryOrder is not null ||
           context.PatchedVisibleDrops is not null)
            throw new MonsterValidationException("لا يعاد حساب الصلصة في سياق مستخدم.");

        var source=_visible.Handle(context);
        var bowls=_factory.InitialBowls(source.Counts);
        int[]? orderAt46Latch=null;
        int[]? diagnostic46=null;

        for(var i=1;i<=46;i++)
        {
            var drop=source.Visible[i];
            var order=_order.OrderPatchFromValue(drop).Order;
            var aliases=_alias.InstallOrderAliases(order);
            var pours=_alias.PatchedPours(i,drop,source.Stones,bowls,aliases);
            _stir.StirOneDropViaShadow(bowls,i,drop,source.Stones,order,pours);
            if(i==46)
            {
                diagnostic46=(int[])order.Clone();
                orderAt46Latch=order;
            }
        }

        var afterDrops=(BigInteger[])bowls.Clone();
        var postOrders=new int[13][];
        for(var stir=1;stir<=12;stir++)
        {
            var result=_post.Stir(bowls,stir);
            postOrders[stir]=(int[])result.Order.Clone();
            // العيب التاريخي: إعادة استعمال خانة ترتيب السؤال لكل تحريك لاحق.
            orderAt46Latch=(int[])result.Order.Clone();
        }

        return new LegacyOverwrittenSauceCandidate(
            source,afterDrops,(BigInteger[])bowls.Clone(),
            diagnostic46 ?? throw new MonsterValidationException("لم تصل القطرة 46."),
            orderAt46Latch ?? throw new MonsterValidationException("ترتيب السؤال مفقود."),
            postOrders);
    }
}
