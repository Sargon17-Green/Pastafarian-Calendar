using System.Numerics;

namespace PastafarianCalendar.Monster;

public sealed class SavePatchWrapper
{
    private static readonly BigInteger Modulus = (BigInteger.One << 127) - BigInteger.One;

    // أبقينا oldRemainder دون تعديل كي يبقى الخطأ التاريخي قابلاً للفحص.
    // نُصلح هنا حالة الباقي الصفري فقط، بعد استدعاء المسار القديم فعلياً.
    public BigInteger SavePatch(BigInteger value)
    {
        var remainder = LegacyRemainder.OldRemainder(value);
        if (remainder.IsZero)
            remainder = Modulus;
        return remainder;
    }
}
