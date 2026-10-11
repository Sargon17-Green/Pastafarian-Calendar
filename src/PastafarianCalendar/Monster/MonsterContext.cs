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

    public MonsterContext(BigInteger calculationDay, BigInteger targetDay)
    {
        CalculationDay = calculationDay;
        TargetDay = targetDay;
    }
}
