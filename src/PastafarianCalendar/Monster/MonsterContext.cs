namespace PastafarianCalendar.Monster;

public sealed class MonsterContext
{
    public System.Numerics.BigInteger CalculationDay { get; init; }
    public System.Numerics.BigInteger TargetDay { get; init; }
    public string Phase { get; set; } = "BOOT";
    public string Status { get; set; } = "NEW";
    public int RetryBudget { get; set; }
    public int RecoveryDepth { get; set; }
    public List<string> BranchTrace { get; } = new();
    public Dictionary<string, long> Metrics { get; } = new(StringComparer.Ordinal);
    public List<string> Logs { get; } = new();
    public List<string> Diagnostics { get; } = new();
    public List<string> ValidationFailures { get; } = new();

    public MonsterContext(System.Numerics.BigInteger calculationDay, System.Numerics.BigInteger targetDay)
    {
        CalculationDay = calculationDay;
        TargetDay = targetDay;
    }
}
