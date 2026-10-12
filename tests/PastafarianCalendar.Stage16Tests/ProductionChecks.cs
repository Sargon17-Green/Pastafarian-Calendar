using System.Numerics;
using PastafarianCalendar.Monster;

namespace PastafarianCalendar.Stage16Tests;

internal static partial class Program
{
    private static void VerifyProductionLink()
    {
        var foundation = new BigInteger(-15055671);
        var giant = BigInteger.One << 8192;
        var pairs = new (BigInteger C, BigInteger T)[]
        {
            (foundation,foundation),
            (foundation-1,foundation+1),
            (giant,-giant),
            (-giant+foundation,giant+foundation)
        };

        foreach (var (c,t) in pairs)
        foreach (var index in new[] {1,7,23,46})
        {
            _linked++;
            var value = CalendarDateSpaghetti.EvaluateVisibleDrop(c,t,index);
            var rank = OneBasedRank(value);
            try
            {
                var ctx = new MonsterManager()
                    .ExecuteLegacyBowlOrderFromVisibleDrop(c,t,index);
                Check(rank < 720 &&
                    ctx.LegacyBowlOrderResult is not null &&
                    ctx.LegacyBowlOrderResult.SequenceEqual(All[rank]) &&
                    !ctx.LegacyBowlOrderResult.SequenceEqual(All[rank-1]) &&
                    ctx.LegacyBowlOrderInput == value &&
                    ctx.LegacyBowlOneBasedRank == rank &&
                    ctx.LegacyBowlVisibleIndex == index &&
                    ctx.BranchTrace.SequenceEqual(
                        new[] {"BOOTSTRAP_VALIDATION","LEGACY_BOWL_PERMUTATION"}) &&
                    ctx.Metrics["legacy.bowl.permutation.dispatch"] == 1,
                    "ترتيب خاطئ لقطرة إنتاجية صالحة " + index);
            }
            catch (ArgumentOutOfRangeException)
            {
                Check(rank == 720,"الفشل يجب أن يقتصر على الرتبة الأخيرة");
            }
        }
    }
}
