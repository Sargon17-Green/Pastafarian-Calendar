using System.Numerics;

namespace PastafarianCalendar.Monster;

public sealed class MonsterContext
{
    public BigInteger CalculationDay { get; init; }
    public BigInteger TargetDay { get; init; }
    public string Phase { get; set; } = "BOOT";
    public string Status { get; set; } = "NEW";
    public int RetryBudget { get; set; }
    public int RecoveryDepth { get; set; }
    public List<string> BranchTrace { get; } = new();
    public Dictionary<string, long> Metrics { get; } = new(StringComparer.Ordinal);
    public List<string> Logs { get; } = new();
    public List<string> Diagnostics { get; } = new();
    public List<string> ValidationFailures { get; } = new();

    // تنتمي القيمتان إلى استدعاء واحد، ولا تمثلان سجلًا مشتركًا بين الاستدعاءات.
    public BigInteger? LegacySaveInput { get; set; }
    public BigInteger? LegacySaveResult { get; set; }

    // تُثبت النتيجة المصححة بعد فحصها؛ وتبقى النتيجة القديمة شاهداً مستقلاً.
    public BigInteger? PatchedSaveResult { get; set; }

    // حالة منفصلة لمسار العدّ التاريخي للطور الرابع؛ لا تَصحيح لنتيجته بعد.
    public BigInteger? LegacyDayInput { get; set; }
    public BigInteger? LegacyDayTagResult { get; set; }

    // تُضاف النتيجة المصححة من دون مسح شاهِد الخطأ التاريخي.
    public BigInteger? PatchedDayTagResult { get; set; }

    // ناتج المسافة التاريخية مستقل لكل استدعاء، وتبقى الرقعة الثالثة غير موجودة.
    public BigInteger? LegacyDistanceResult { get; set; }

    // تبقى المسافة التاريخية محفوظة، وتضاف الخماسية الحسابية المصححة في موضع مستقل.
    public MonsterWorkCounts? PatchedCountsResult { get; set; }

    // صفوف الأحجار المتعاقبة القديمة يملكها هذا الاستدعاء وحده.
    public BigInteger[][]? LegacyStoneRows { get; set; }

    // صفوف الرقعة الرابعة مستقلة عن صفوف الطفرة التاريخية وعن سائر السياقات.
    public BigInteger[][]? PatchedStoneRows { get; set; }

    // ترتيب القطرات المخفية القديم معكوس ويملك كل استدعاء مصفوفتَه الخاصة.
    public BigInteger[]? LegacyHiddenReversed { get; set; }

    // لا تُنسخ القطرات ولا تُقلب؛ يحتفظ غلاف القراءة بمخزنها القديم نفسه.
    public HiddenNearnessWrapper? PatchedHiddenAccess { get; set; }

    // تظل هذه البيانات مملوكة للاستدعاء، ولا تتضمن مواضع القطرة الخفية.
    public BigInteger[]? LegacyPriorDropStore { get; set; }
    public int? LegacyPriorVisibleIndex { get; set; }
    public int? LegacyPriorBack { get; set; }
    public BigInteger? LegacyPriorResult { get; set; }

    // تُثبت نتيجة الرجوع المصححة منفصلة عن أثر القراءة القديمة إن وجد.
    public BigInteger? PatchedPriorResult { get; set; }

    // يحتفظ هذا السياق برقم الطحن القديم والصفّ المقروء، دون أي حارس للطاحونة.
    public int? LegacyGrindOrdinal { get; set; }
    public int? LegacyGrindDirectIndex { get; set; }
    public LegacyGrindRow? LegacyGrindResult { get; set; }

    // الرقعة السابعة تترك الندبة في السياق وتضيف 46 قطرة مستقلة مكتملة.
    public BigInteger[]? PatchedVisibleDrops { get; set; }

    // مصفوفة ترتيب الأوعية التاريخية مملوكة للاستدعاء، مع رقم الرتبة الواحدي الخاطئ.
    public BigInteger? LegacyBowlOrderInput { get; set; }
    public int? LegacyBowlOneBasedRank { get; set; }
    public int[]? LegacyBowlOrderResult { get; set; }
    public int? LegacyBowlVisibleIndex { get; set; }

    // أثر القديم محفوظ: عند الرتبة 720 يُسجل فشله بدلاً من اختلاق ترتيب قديم.
    public bool LegacyBowlRankOutOfRange { get; set; }

    // الرتبة الواحدية والرتبة الصفرية المتعاقبتان لا تُختزلان في الرقعة الثامنة.
    public int? PatchedBowlOneBasedRank { get; set; }
    public int? PatchedBowlLegacyRank0 { get; set; }
    public int[]? PatchedBowlOrderResult { get; set; }

    // الصبّ التاريخي التاسع يستخدم أسماء الأوعية الثابتة لا مواضعها المتحركة.
    public int? LegacyPourVisibleIndex { get; set; }
    public BigInteger? LegacyPourDrop { get; set; }
    public BigInteger[]? LegacyPourInitialBowls { get; set; }
    public int[]? LegacyPourOrder { get; set; }
    public BigInteger[]? LegacyPoursResult { get; set; }

    // خريطة أسماء المواضع تُملَك لكل استدعاء؛ وتبقى الصبّات الثابتة في حقل مستقل.
    public int[]? BowlAliases { get; set; }
    public BigInteger[]? PatchedPoursResult { get; set; }

    // يبقى الإناء الذي غُيّر مباشرةً شاهداً على التلوث التاريخي.
    public BigInteger[]? LegacyStirredBowls { get; set; }

    // الصورة السابقة ونتيجة الانتظار مستقلتان عن الأوعية الملتزم بها.
    public BigInteger[]? StirVaultOld { get; set; }
    public BigInteger[]? StirPending { get; set; }
    public BigInteger[]? PatchedStirredBowls { get; set; }

    // شاهد ترتيب القطرة 46 التشخيصي؛ لا تستخدمه الواجهة التاريخية.
    public int[]? LegacyDiagnosticDrop46Order { get; set; }
    public int[]? LegacyOverwrittenQueryOrder { get; set; }
    public int[][]? LegacyPostStirOrders { get; set; }
    public BigInteger[]? LegacySauceBowlsAfterDrops { get; set; }
    public BigInteger[]? LegacySauceFinalBowls { get; set; }

    // الالتقاط الثابت بعد القطرة 46 لا تتصل به ترتيب التحريكات اللاحقة.
    public int[]? PatchedOrderAt46Latch { get; set; }
    public BigInteger[]? PatchedSauceBowlsAfterDrops { get; set; }
    public BigInteger[]? PatchedSauceFinalBowls { get; set; }
    public int[][]? PatchedPostStirOrders { get; set; }

    // شاهد السؤال التاريخي الثاني عشر؛ لا يُلغي ترتيب القطرة 46 المحمي.
    public int? LegacyQueriedBowlId { get; set; }
    public int? LegacyFixedNextBowlResult { get; set; }

    // نتيجة الرقعة الثانية عشرة مستقلة عن شاهد الجار ذي الهوية الثابتة.
    public int? PatchedNextBowlResult { get; set; }

    // الندبة الثالثة عشرة في سؤال الصلصة: يُحفظ الحاتم والشاهد القديم دون رقعة.
    public int? LegacyBowlQuestionSeal { get; set; }
    public LegacyBowlQuestionResult? LegacyUnsealedBowlQuestionResult { get; set; }

    // الرقعة الثالثة عشرة: الجواب المختوم الصحيح منفصل عن الشاهد القديم.
    public LegacyBowlQuestionResult? PatchedBowlQuestionResult { get; set; }

    // الخطأ التاريخي الرابع عشر: عدّ خطوات تيار الإجابات من واحد لا من صفر.
    public BigInteger? LegacyAnswerStepIndex { get; set; }
    public BigInteger? LegacyOneBasedAnswerAtResult { get; set; }

    // نتيجة الخطوة ذات الفهرسة الصفرية مستقلة عن شاهد الخطوة التاريخية.
    public BigInteger? PatchedAnswerAtResult { get; set; }

    public MonsterContext(BigInteger calculationDay, BigInteger targetDay)
    {
        CalculationDay = calculationDay;
        TargetDay = targetDay;
    }
}
