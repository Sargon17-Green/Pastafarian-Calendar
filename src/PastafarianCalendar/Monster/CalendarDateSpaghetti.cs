using System.Numerics;

namespace PastafarianCalendar.Monster;

public static class CalendarDateSpaghetti
{
    public static MonsterContext BootstrapInvocation(BigInteger calculationDay, BigInteger targetDay)
    {
        var manager = new MonsterManager();
        return manager.Prepare(calculationDay, targetDay);
    }

    // مدخل إنتاجي حقيقي لمسار الحفظ القديم؛ ليس استدعاءً للمرجع الاختباري.
    public static BigInteger EvaluateLegacySave(BigInteger calculationDay, BigInteger targetDay, BigInteger value)
    {
        var manager = new MonsterManager();
        return manager.EvaluateLegacySave(calculationDay, targetDay, value);
    }

    // واجهة التنفيذ التاريخي لعدّ اليوم؛ تُظهر الخلل قبل إضافة الرقعة الثانية.
    public static BigInteger EvaluateLegacyDayTag(BigInteger calculationDay, BigInteger targetDay, BigInteger day)
    {
        var manager = new MonsterManager();
        return manager.EvaluateLegacyDayTag(calculationDay, targetDay, day);
    }

    // الواجهة المعتمدة لعدّ اليوم بعد الرقعة الثانية؛ ولا تتصل بمرجع الاختبار.
    public static BigInteger EvaluateDayTag(BigInteger calculationDay, BigInteger targetDay, BigInteger day)
    {
        var manager = new MonsterManager();
        return manager.EvaluateDayTag(calculationDay, targetDay, day);
    }

    // يُظهر المسار التاريخي الثالث فرق العدّادين، دون إضافة تصحيح المسافة.
    public static BigInteger EvaluateLegacyDistance(BigInteger calculationDay, BigInteger targetDay)
    {
        var manager = new MonsterManager();
        return manager.EvaluateLegacyDistance(calculationDay, targetDay);
    }

    // خماسية العدّ المصححة في الرقعة الثالثة، مع المحافظة على أثر المسافة القديمة.
    public static MonsterWorkCounts EvaluateWorkCounts(BigInteger calculationDay, BigInteger targetDay)
    {
        var manager = new MonsterManager();
        return manager.EvaluateWorkCounts(calculationDay, targetDay);
    }

    // المسار الإنتاجي للاكتشاف الرابع؛ يُبقي التحوير المتسلسل الخاطئ بلا تصحيح.
    public static BigInteger[][] EvaluateLegacyStones(BigInteger calculationDay, BigInteger targetDay)
    {
        var manager = new MonsterManager();
        return manager.EvaluateLegacyStones(calculationDay, targetDay);
    }

    // مسار إنتاج الرقعة الرابعة: يحفظ الطفرة التاريخية ويعيد الصفوف المصححة منفصلةً.
    public static BigInteger[][] EvaluatePatchedStones(BigInteger calculationDay, BigInteger targetDay)
    {
        var manager = new MonsterManager();
        return manager.EvaluatePatchedStones(calculationDay, targetDay);
    }

    // المسار التاريخي الخامس يترك القطرات المخفية محفوظة بالترتيب المعكوس.
    public static BigInteger[] EvaluateLegacyHiddenDrops(BigInteger calculationDay, BigInteger targetDay)
    {
        var manager = new MonsterManager();
        return manager.EvaluateLegacyHiddenDrops(calculationDay, targetDay);
    }

    // قراءة القطرة الخفية برتبة قربها؛ المخزن القديم باقٍ بالعكس دون أي قلب فعلي.
    public static BigInteger EvaluateHiddenDrop(BigInteger calculationDay, BigInteger targetDay, int k)
    {
        var manager = new MonsterManager();
        return manager.EvaluateHiddenDrop(calculationDay, targetDay, k);
    }

    // مسترجع القطرات السابق التاريخي، لا يصلح الفهارس غير الموجبة في هذا الطور.
    public static BigInteger EvaluateLegacyPrior(
        BigInteger calculationDay, BigInteger targetDay,
        BigInteger[] dropStore, int i, int back)
    {
        var manager = new MonsterManager();
        return manager.EvaluateLegacyPrior(calculationDay, targetDay, dropStore, i, back);
    }

    // المسار المعتمد للرجوع إلى القطرات السابقة مع بقاء استرجاع القديم كما هو.
    public static BigInteger EvaluatePrior(
        BigInteger calculationDay, BigInteger targetDay,
        BigInteger[] dropStore, int i, int back)
    {
        var manager = new MonsterManager();
        return manager.EvaluatePrior(calculationDay, targetDay, dropStore, i, back);
    }

    // يمرّ الاستعلام القديم للطحينات المرئية بالمدير والموزّع والمعالج الفعلي.
    // لا يحتوي هذا المدخل على صفّ الحارس الذي لا يظهر إلا في الرقعة السابعة.
    public static LegacyGrindRow EvaluateLegacyVisibleGrind(
        BigInteger calculationDay, BigInteger targetDay, int ordinal)
    {
        var manager = new MonsterManager();
        return manager.EvaluateLegacyVisibleGrind(calculationDay, targetDay, ordinal);
    }

    // المسار المُصحّح للقطرات الظاهرة يستخدم جدول الحارس ويبقي القارئ التاريخي.
    public static BigInteger[] EvaluateVisibleDrops(BigInteger calculationDay, BigInteger targetDay)
    {
        var manager = new MonsterManager();
        return manager.EvaluateVisibleDrops(calculationDay, targetDay);
    }

    public static BigInteger EvaluateVisibleDrop(BigInteger calculationDay, BigInteger targetDay, int ordinal)
    {
        var manager = new MonsterManager();
        return manager.EvaluateVisibleDrop(calculationDay, targetDay, ordinal);
    }

    // باب التاريخ لترتيب الأوعية: تُمرر الرتبة الواحدية خطأً إلى مفكك صفري.
    public static int[] EvaluateLegacyBowlOrder(
        BigInteger calculationDay, BigInteger targetDay, BigInteger dropValue)
    {
        return new MonsterManager().EvaluateLegacyBowlOrder(
            calculationDay, targetDay, dropValue);
    }

    // يختبر باباً إنتاجياً حقيقياً يبدأ من القطرة الظاهرة المصححة.
    public static int[] EvaluateLegacyBowlOrderFromVisibleDrop(
        BigInteger calculationDay, BigInteger targetDay, int index)
    {
        return new MonsterManager().EvaluateLegacyBowlOrderFromVisibleDrop(
            calculationDay, targetDay, index);
    }

    // مسار الحفظ المعتمد منذ الرقعة الأولى؛ لا يستدعي المرجع الاختباري.
    public static BigInteger EvaluateSave(BigInteger calculationDay, BigInteger targetDay, BigInteger value)
    {
        var manager = new MonsterManager();
        return manager.EvaluateSave(calculationDay, targetDay, value);
    }
}
