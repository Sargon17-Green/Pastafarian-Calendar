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

    // رقعة ترتيب الأوعية الثامنة: يُستدعى المفكك القديم بعد تصحيح دليل الرتبة.
    public static int[] EvaluateBowlOrder(
        BigInteger calculationDay, BigInteger targetDay, BigInteger dropValue)
    {
        return new MonsterManager().EvaluateBowlOrder(
            calculationDay, targetDay, dropValue);
    }

    // المدخل المصحح من قطرة ظاهرة حقيقية وليس من مرجع الاختبار.
    public static int[] EvaluateBowlOrderFromVisibleDrop(
        BigInteger calculationDay, BigInteger targetDay, int index)
    {
        return new MonsterManager().EvaluateBowlOrderFromVisibleDrop(
            calculationDay, targetDay, index);
    }

    // الصبّ التاسع التاريخي يستخدم هويات الأوعية الثابتة لا ترتيب المواضع.
    public static BigInteger[] EvaluateLegacyFixedBowlPours(
        BigInteger calculationDay, BigInteger targetDay, int visibleIndex)
    {
        return new MonsterManager().EvaluateLegacyFixedBowlPours(
            calculationDay, targetDay, visibleIndex);
    }

    // رقعة الأسماء المؤقتة تجعل الموضع التاريخي يشير إلى هوية الوعاء في الترتيب.
    public static BigInteger[] EvaluatePatchedBowlPours(
        BigInteger calculationDay,BigInteger targetDay,int visibleIndex)
        => new MonsterManager().EvaluatePatchedBowlPours(
            calculationDay,targetDay,visibleIndex);

    // مسار التحريك التاريخي يكتب مباشرة في الأوعية الحيّة.
    public static BigInteger[] EvaluateLegacyInPlaceStir(
        BigInteger calculationDay,BigInteger targetDay,int visibleIndex)
        => new MonsterManager().EvaluateLegacyInPlaceStir(
            calculationDay,targetDay,visibleIndex);

    // رقعة الظل تقرأ جميع القيم قبل أن تثبت نتائج الأوعية الستة.
    public static BigInteger[] EvaluatePatchedBowlStir(
        BigInteger calculationDay,BigInteger targetDay,int visibleIndex)
        => new MonsterManager().EvaluatePatchedBowlStir(
            calculationDay,targetDay,visibleIndex);

    // مسار كامل تاريخي تعيد فيه التحريكات اللاحقة كتابة ترتيب سؤال القطرة 46.
    public static LegacySauceResult EvaluateLegacyOverwrittenSauce(
        BigInteger calculationDay,BigInteger targetDay)
        => new MonsterManager().EvaluateLegacyOverwrittenSauce(calculationDay,targetDay);

    // ترتيب القطرة 46 محفوظ قبل التحريكات ولا تعيد هذه الجولات الكتابة فيه.
    public static LegacySauceResult EvaluateLatchedSauce(
        BigInteger calculationDay,BigInteger targetDay)
        => new MonsterManager().EvaluateLatchedSauce(calculationDay,targetDay);

    // الندبة التاريخية الثانية عشرة: اختيار الوعاء التالي بهويته الثابتة بدلاً من ترتيب القطرة.
    public static int EvaluateLegacyFixedNextBowl(
        BigInteger calculationDay, BigInteger targetDay, int queriedBowlId)
        => new MonsterManager().EvaluateLegacyFixedNextBowl(
            calculationDay,targetDay,queriedBowlId);

    // رقعة الجار الثانية عشرة: اختيار التالي في ترتيب القطرة السادسة والأربعين.
    public static int EvaluateNextBowl(
        BigInteger calculationDay, BigInteger targetDay, int queriedBowlId)
        => new MonsterManager().EvaluateNextBowl(
            calculationDay,targetDay,queriedBowlId);

    // اكتشاف العيب الثالث عشر في سؤال الصلصة؛ لا تُجرى الرقعة حتى الطور 27.
    public static LegacyBowlQuestionResult EvaluateLegacyUnsealedBowlQuestion(
        BigInteger calculationDay,BigInteger targetDay,int queriedBowlId,int seal)
        => new MonsterManager().EvaluateLegacyUnsealedBowlQuestion(
            calculationDay,targetDay,queriedBowlId,seal);

    // الرقعة الثالثة عشرة: الجواب الأول والاتجاه مع الحاتم داخل المربع الصحيح.
    public static LegacyBowlQuestionResult EvaluateBowlQuestion(
        BigInteger calculationDay,BigInteger targetDay,int queriedBowlId,int seal)
        => new MonsterManager().EvaluateBowlQuestion(
            calculationDay,targetDay,queriedBowlId,seal);

    // الاكتشاف الرابع عشر: السطر التاريخي يستعمل k+1 قبل تقدّم التيار.
    public static BigInteger EvaluateLegacyOneBasedAnswer(
        BigInteger calculationDay,BigInteger targetDay,
        int queriedBowlId,int seal,BigInteger k)
        => new MonsterManager().EvaluateLegacyOneBasedAnswer(
            calculationDay,targetDay,queriedBowlId,seal,k);

    // الرقعة الرابعة عشرة: فهرس k الصفري يصون شاهد الانزياح التاريخي.
    public static BigInteger EvaluateAnswerAt(
        BigInteger calculationDay,BigInteger targetDay,
        int queriedBowlId,int seal,BigInteger k)
        => new MonsterManager().EvaluateAnswerAt(
            calculationDay,targetDay,queriedBowlId,seal,k);

    // اكتشاف العيب الخامس عشر: الخطأ في باقي x لا في بداية مجرى الإجابات.
    public static BigInteger EvaluateLegacyUnshiftedShortRank(
        BigInteger calculationDay,BigInteger targetDay,
        int queriedBowlId,int seal,BigInteger familySize)
        => new MonsterManager().EvaluateLegacyUnshiftedShortRank(
            calculationDay,targetDay,queriedBowlId,seal,familySize);

    // الرقعة الخامسة عشرة: تدور المرتبة القديمة خطوةً إلى الخلف لتبدأ من x-1.
    public static BigInteger EvaluateShortFamilyRank(
        BigInteger calculationDay,BigInteger targetDay,
        int queriedBowlId,int seal,BigInteger familySize)
        => new MonsterManager().EvaluateShortFamilyRank(
            calculationDay,targetDay,queriedBowlId,seal,familySize);

    // الاكتشاف السادس عشر: خطأ وزن أرقام الأسرة الواسعة في مسار مستقل.
    public static BigInteger EvaluateLegacyReversedWideRank(
        BigInteger calculationDay,BigInteger targetDay,
        int queriedBowlId,int seal,BigInteger familySize)
        => new MonsterManager().EvaluateLegacyReversedWideRank(
            calculationDay,targetDay,queriedBowlId,seal,familySize);

    // الرقعة السادسة عشرة: ترتيب الأرقام من الأقل وزناً مع صون المسار القديم.
    public static BigInteger EvaluateWideFamilyRank(
        BigInteger calculationDay,BigInteger targetDay,
        int queriedBowlId,int seal,BigInteger familySize)
        => new MonsterManager().EvaluateWideFamilyRank(
            calculationDay,targetDay,queriedBowlId,seal,familySize);

    // الاكتشاف السابع عشر: رفض المساواة عند حد قبول الأسرة الواسعة.
    public static BigInteger EvaluateLegacyInclusiveWideLimit(
        BigInteger calculationDay,BigInteger targetDay,
        int queriedBowlId,int seal,BigInteger familySize)
        => new MonsterManager().EvaluateLegacyInclusiveWideLimit(
            calculationDay,targetDay,queriedBowlId,seal,familySize);

    // مسار الحفظ المعتمد منذ الرقعة الأولى؛ لا يستدعي المرجع الاختباري.
    public static BigInteger EvaluateSave(BigInteger calculationDay, BigInteger targetDay, BigInteger value)
    {
        var manager = new MonsterManager();
        return manager.EvaluateSave(calculationDay, targetDay, value);
    }
}
