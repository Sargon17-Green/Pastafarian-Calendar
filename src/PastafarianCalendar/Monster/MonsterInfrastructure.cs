using System.Numerics;

namespace PastafarianCalendar.Monster;

public sealed class MonsterValidationException : Exception
{
    public MonsterValidationException(string message) : base(message) { }
}

public sealed class MonsterValidationManager
{
    public void ValidateBootstrapContext(MonsterContext context)
    {
        if (context.RetryBudget < 0)
            throw new MonsterValidationException("ميزانية الإعادة لا يجوز أن تكون سالبة.");
        if (!string.Equals(context.Status, "NEW", StringComparison.Ordinal))
            throw new MonsterValidationException("حالة البدء غير صحيحة.");
    }
}

public sealed class MonsterMetricsManager
{
    public void Bump(MonsterContext context, string key)
    {
        context.Metrics.TryGetValue(key, out var value);
        context.Metrics[key] = value + 1;
    }
}

public sealed class MonsterDispatcher
{
    private readonly MonsterValidationManager _validation;
    private readonly MonsterMetricsManager _metrics;
    private readonly LegacySavePhaseHandler _legacySave;

    public MonsterDispatcher(MonsterValidationManager validation, MonsterMetricsManager metrics)
    {
        _validation = validation;
        _metrics = metrics;
        _legacySave = new LegacySavePhaseHandler();
    }

    public void DispatchBootstrap(MonsterContext context)
    {
        context.Phase = "BOOTSTRAP_VALIDATION";
        context.BranchTrace.Add("BOOTSTRAP_VALIDATION");
        _validation.ValidateBootstrapContext(context);
        _metrics.Bump(context, "bootstrap.dispatch");
        context.Status = "BOOTSTRAP_READY";
        context.Phase = "BOOTSTRAP_READY";
    }

    public void DispatchLegacySave(MonsterContext context)
    {
        if (!string.Equals(context.Status, "BOOTSTRAP_READY", StringComparison.Ordinal))
            throw new MonsterValidationException("لم يكتمل تأسيس السياق قبل الحفظ القديم.");

        context.Phase = "LEGACY_SAVE";
        context.BranchTrace.Add("LEGACY_SAVE");
        _legacySave.Handle(context);
        _metrics.Bump(context, "legacy.save.dispatch");
        context.Status = "LEGACY_SAVE_COMPLETE";
        context.Phase = "LEGACY_SAVE_COMPLETE";
    }
}

public sealed class MonsterManager
{
    private readonly MonsterDispatcher _dispatcher;

    public MonsterManager()
    {
        var validation = new MonsterValidationManager();
        var metrics = new MonsterMetricsManager();
        _dispatcher = new MonsterDispatcher(validation, metrics);
    }

    public MonsterContext Prepare(BigInteger calculationDay, BigInteger targetDay)
    {
        var context = new MonsterContext(calculationDay, targetDay) { RetryBudget = 0 };
        _dispatcher.DispatchBootstrap(context);
        return context;
    }

    public BigInteger EvaluateLegacySave(BigInteger calculationDay, BigInteger targetDay, BigInteger value)
    {
        var context = Prepare(calculationDay, targetDay);
        context.LegacySaveInput = value;
        _dispatcher.DispatchLegacySave(context);
        return context.LegacySaveResult
            ?? throw new MonsterValidationException("لم يُنتج مسار الحفظ القديم قيمة.");
    }
}
