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

    public MonsterContext(BigInteger calculationDay, BigInteger targetDay)
    {
        CalculationDay = calculationDay;
        TargetDay = targetDay;
    }
}
