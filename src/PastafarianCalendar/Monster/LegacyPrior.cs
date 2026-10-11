using System.Numerics;

namespace PastafarianCalendar.Monster;

public static class LegacyPrior
{
    // الندبة التاريخية السادسة: لا يعرف هذا المسترجع وجود قطرات في المواضع
    // صفر و-1 ... -6؛ ولا يطلب أبداً بيانات المخزن الخفي المصحح.
    // لا تُضَف هنا حراسة تعيد تفسير الفهارس السالبة أو تستبدل الاستثناء.
    public static BigInteger Read(BigInteger[] dropStore, int i, int back)
        => dropStore[i - back];
}

public sealed class LegacyPriorPhaseHandler
{
    // لا يجوز تثبيت صفر بدلاً من نتيجة مرجعية للقطرات الخفية؛ نحتفظ
    // بصفر الموضع صفر التاريخي كما هو، والمواضع السالبة تُفشل القراءة.
    public BigInteger Handle(MonsterContext context)
    {
        if (context.LegacyPriorDropStore is not BigInteger[] store ||
            context.LegacyPriorVisibleIndex is not int row ||
            context.LegacyPriorBack is not int back)
            throw new MonsterValidationException("لم تُحضَّر مُدخلات قراءة القطرة القديمة.");
        return LegacyPrior.Read(store, row, back);
    }
}
