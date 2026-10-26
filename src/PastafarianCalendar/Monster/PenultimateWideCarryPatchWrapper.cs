using System.Numerics;

namespace PastafarianCalendar.Monster;

// الرقعة الرابعة والعشرون: لا يُعكس الشاهد n وحده، إذ قد يدل على n أو n-1.
// تُسترجع الرتبة من مرشح الرقعة الثالثة والعشرين بعد التحقق من القديم.
public sealed class PenultimateWideCarryPatchWrapper
{
    private static readonly BigInteger M=(BigInteger.One<<127)-BigInteger.One;

    public BigInteger Restore(BigInteger historicalRank,BigInteger previousRank,
                              BigInteger familySize)
    {
        if(familySize<=M || previousRank<1 || previousRank>familySize ||
           historicalRank<1 || historicalRank>familySize)
            throw new MonsterValidationException("معطيات تصحيح الحمل قبل الأخير غير صالحة.");
        if(new LegacyPenultimateWideCarry().Carry(previousRank,familySize)!=historicalRank)
            throw new MonsterValidationException("شاهد الحمل لا يطابق مرتبة الرقعة الثالثة والعشرين.");
        return previousRank;
    }

    public BigInteger Patch(LegacyPenultimateWideCarryCandidate historical,
                            BigInteger familySize)
    {
        if(historical is null || historical.Previous is null)
            throw new MonsterValidationException("شاهد الحمل قبل الأخير مفقود.");
        return Restore(historical.Rank,historical.Previous.Rank,familySize);
    }
}

public sealed record PatchedPenultimateWideCarryCandidate(
    LegacyPenultimateWideCarryCandidate Historical,BigInteger Rank);

public sealed class PatchedPenultimateWideCarryPhaseHandler
{
    private static readonly BigInteger M=(BigInteger.One<<127)-BigInteger.One;
    private readonly LegacyPenultimateWideCarryPhaseHandler _historical=new();
    private readonly PenultimateWideCarryPatchWrapper _patch=new();

    public PatchedPenultimateWideCarryCandidate Handle(MonsterContext context)
    {
        if(context is null ||
           context.LegacyWideFamilySize is not BigInteger n || n<=M ||
           context.LegacyAnswerStepIndex is not BigInteger k || !k.IsZero ||
           context.LegacyQueriedBowlId is not int id || id is <1 or >6 ||
           context.LegacyBowlQuestionSeal is not int seal || seal is not (21 or 31) ||
           context.PatchedPenultimateWideCarryRankResult.HasValue ||
           context.LegacyPenultimateWideCarryRankResult.HasValue ||
           context.PatchedWideTerminalSentinelRankResult.HasValue ||
           context.LegacyWideTerminalSentinelRankResult.HasValue ||
           context.PatchedDescendingRankMirrorResult.HasValue ||
           context.PatchedSauceFinalBowls is not null ||
           context.PatchedVisibleDrops is not null)
            throw new MonsterValidationException("سياق الرقعة الرابعة والعشرين ناقص أو مستعمل.");
        var historical=_historical.Handle(context);
        return new PatchedPenultimateWideCarryCandidate(
            historical,_patch.Patch(historical,n));
    }
}
