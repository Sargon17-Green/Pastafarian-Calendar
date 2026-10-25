using System.Numerics;

namespace PastafarianCalendar.Monster;

// الرقعة الثالثة والعشرون: لا يمكن معرفة هل الحارس 1 يعني 1 أو n
// من الشاهد القديم وحده. تُعتمد رتبة الرقعة الثانية والعشرين بعد التحقق.
public sealed class WideTerminalSentinelPatchWrapper
{
    private static readonly BigInteger M=(BigInteger.One<<127)-BigInteger.One;

    public BigInteger Restore(BigInteger historicalRank,BigInteger previousRank,
                              BigInteger familySize)
    {
        if(familySize<=M || previousRank<1 || previousRank>familySize ||
           historicalRank<1 || historicalRank>familySize)
            throw new MonsterValidationException("مدخل استرجاع الحارس النهائي غير صالح.");
        var expected=new LegacyWideTerminalSentinel().Collapse(previousRank,familySize);
        if(historicalRank!=expected)
            throw new MonsterValidationException("شاهد الحارس لا يتفق مع الرتبة الأصلية.");
        return previousRank;
    }

    public BigInteger Patch(LegacyWideTerminalSentinelCandidate historical,
                            BigInteger familySize)
    {
        if(historical is null || historical.Previous is null)
            throw new MonsterValidationException("شاهد حارس المرتبة النهائية مفقود.");
        return Restore(historical.Rank,historical.Previous.Rank,familySize);
    }
}

public sealed record PatchedWideTerminalSentinelCandidate(
    LegacyWideTerminalSentinelCandidate Historical,BigInteger Rank);

public sealed class PatchedWideTerminalSentinelPhaseHandler
{
    private static readonly BigInteger M=(BigInteger.One<<127)-BigInteger.One;
    private readonly LegacyWideTerminalSentinelPhaseHandler _historical=new();
    private readonly WideTerminalSentinelPatchWrapper _patch=new();

    public PatchedWideTerminalSentinelCandidate Handle(MonsterContext context)
    {
        if(context is null ||
           context.LegacyWideFamilySize is not BigInteger n || n<=M ||
           context.LegacyAnswerStepIndex is not BigInteger k || !k.IsZero ||
           context.LegacyQueriedBowlId is not int id || id is <1 or >6 ||
           context.LegacyBowlQuestionSeal is not int seal || seal is not (21 or 31) ||
           context.PatchedWideTerminalSentinelRankResult.HasValue ||
           context.LegacyWideTerminalSentinelRankResult.HasValue ||
           context.PatchedDescendingRankMirrorResult.HasValue ||
           context.LegacyDescendingRankMirrorResult.HasValue ||
           context.PatchedWideSlotTruncationRankResult.HasValue ||
           context.PatchedSauceFinalBowls is not null ||
           context.PatchedVisibleDrops is not null)
            throw new MonsterValidationException("سياق الرقعة الثالثة والعشرين ناقص أو مستعمل.");
        var old=_historical.Handle(context);
        return new PatchedWideTerminalSentinelCandidate(old,_patch.Patch(old,n));
    }
}
