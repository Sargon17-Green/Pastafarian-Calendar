using System.Numerics;

namespace PastafarianCalendar.Monster;

// الرقعة الثامنة: مفكك الرتبة الصفري لا يتغيّر؛ ينتقل إليه الدليل المصحح فقط.
public sealed class BowlOrderPatchWrapper
{
    // هذه المراحل الثلاث مكتوبة صراحةً، ولا يُختزل الالتفاف التاريخي.
    public (int OneBased, int LegacyRank0, int[] Order) OrderPatchFromValue(
        BigInteger drop)
    {
        var remainder = (drop - BigInteger.One) % 720;
        if (remainder.Sign < 0) remainder += 720;

        var oneBased = (int)remainder + 1;
        var legacyRank0 = oneBased - 1;
        var order = LegacyBowlPermutation.OldPermutationUnrank0(legacyRank0);
        return (oneBased, legacyRank0, order);
    }
}
