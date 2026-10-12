using System.Numerics;

namespace PastafarianCalendar.Monster;

// الالتقاط المحمي يتم عند اكتمال القطرة 46 لا بعد انتهاء التحريك.
public sealed record ProtectedDrop46SauceResult(
    int[] OrderAt46Latch,
    BigInteger[] BowlsAfterDrops,
    BigInteger[] FinalBowls,
    int[][] PostStirOrders);

public sealed class Drop46OrderLatchWrapper
{
    private readonly LegacyBowlFactory _factory = new();
    private readonly BowlOrderPatchWrapper _order = new();
    private readonly BowlAliasPatchWrapper _alias = new();
    private readonly ShadowBowlStirPatch _stir = new();
    private readonly LegacyPostStirRound _post = new();

    public ProtectedDrop46SauceResult Run(VisibleDropsPatchCandidate source)
    {
        if (source is null || source.Counts is null ||
            source.Visible is null || source.Visible.Length != 47 ||
            source.Stones is null || source.Stones.Length != 47)
            throw new MonsterValidationException("مصدر القطرات اللازمة لالتقاط الترتيب مفقود.");

        var bowls = _factory.InitialBowls(source.Counts);
        int[]? sealedLatch = null;

        for (var i = 1; i <= 46; i++)
        {
            var drop = source.Visible[i];
            var order = _order.OrderPatchFromValue(drop).Order;
            var aliases = _alias.InstallOrderAliases(order);
            var pours = _alias.PatchedPours(i, drop, source.Stones, bowls, aliases);
            _stir.StirOneDropViaShadow(bowls, i, drop, source.Stones, order, pours);
            if (i == 46)
            {
                // هذا هو الموضع الوحيد الذي يسند فيه الترتيب المحمي.
                sealedLatch = (int[])order.Clone();
            }
        }

        if (sealedLatch is null)
            throw new MonsterValidationException("لم يُلتقط ترتيب القطرة السادسة والأربعين.");

        var afterDrops = (BigInteger[])bowls.Clone();
        var postOrders = new int[13][];
        for (var round = 1; round <= 12; round++)
        {
            var result = _post.Stir(bowls, round);
            postOrders[round] = (int[])result.Order.Clone();
            // أوامر هذه الدورات تشخيصية، ولا تتصل بمتغير sealedLatch.
        }

        return new ProtectedDrop46SauceResult(
            sealedLatch, afterDrops, (BigInteger[])bowls.Clone(), postOrders);
    }
}

public sealed record ProtectedDrop46SauceCandidate(
    LegacyOverwrittenSauceCandidate Historical,
    ProtectedDrop46SauceResult Patched);

public sealed class ProtectedDrop46SaucePhaseHandler
{
    private readonly LegacyOverwrittenDrop46Sauce _old = new();
    private readonly Drop46OrderLatchWrapper _patch = new();

    public ProtectedDrop46SauceCandidate Handle(MonsterContext context)
    {
        if (context.PatchedOrderAt46Latch is not null ||
            context.PatchedSauceFinalBowls is not null ||
            context.LegacySauceFinalBowls is not null)
            throw new MonsterValidationException("سياق الصلصة المحمية مستعمل مسبقاً.");

        // يجري المسار التاريخي الكامل أولاً، مع إبقاء محو ترتيب الاستعلام.
        var historical = _old.Evaluate(context);
        var corrected = _patch.Run(historical.Source);
        return new ProtectedDrop46SauceCandidate(historical, corrected);
    }
}
