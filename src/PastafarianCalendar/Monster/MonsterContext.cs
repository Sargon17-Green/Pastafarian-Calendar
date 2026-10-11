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

    public MonsterContext(BigInteger calculationDay, BigInteger targetDay)
    {
        CalculationDay = calculationDay;
        TargetDay = targetDay;
    }
}
