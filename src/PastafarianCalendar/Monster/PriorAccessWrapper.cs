using System.Numerics;

namespace PastafarianCalendar.Monster;

// غلاف الرقعة السادسة: لا تُمسّ الدالة القديمة؛ يُستدعى القديم للمواضع
// الظاهرة وحدها وتُقرأ المواضع الخفية عبر غلاف الرقعة الخامسة.
public sealed class PriorAccessWrapper
{
    public BigInteger Read(BigInteger[] dropStore, HiddenNearnessWrapper? hidden, int i, int back)
    {
        if (dropStore is null || dropStore.Length != 47 || dropStore[0] != BigInteger.Zero)
            throw new MonsterValidationException("مخزن القطرات الظاهرة ناقص أو فقد خانته الصفرية.");
        if (i is < 1 or > 46 || back is not (1 or 3 or 7))
            throw new MonsterValidationException("موضع القطرة أو مقدار الرجوع خارج المدى.");
        var slot = i - back;
        if (slot >= 1)
            return LegacyPrior.Read(dropStore, i, back);

        // slot=0 هو hidden1، وslot=-6 هو hidden7؛ لا ينعكس المخزن.
        var hiddenK = 1 - slot;
        if (hidden is null)
            throw new MonsterValidationException("يستلزم الموضع غير الموجب غلاف القطرات المخفية.");
        return hidden.HiddenByNearness(hiddenK);
    }
}
