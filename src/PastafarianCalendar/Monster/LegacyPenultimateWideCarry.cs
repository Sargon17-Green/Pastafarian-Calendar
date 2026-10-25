using System.Numerics;

namespace PastafarianCalendar.Monster;

// الندبة الرابعة والعشرون: ينفذ مُسلسِل المخرجات حملاً مبكراً
// في المرتبة n-1، فيحفظ n بدلاً منها. تبقى المرتبة الأخيرة n سليمة.
public sealed class LegacyPenultimateWideCarry
{
    private static readonly BigInteger M=(BigInteger.One<<127)-BigInteger.One;

    public BigInteger Carry(BigInteger correctRank,BigInteger familySize)
    {
        if(familySize<=M || correctRank<1 || correctRank>familySize)
            throw new MonsterValidationException("معطيات الحَمْل قبل الأخير غير صالحة.");
        return correctRank==familySize-BigInteger.One
            ? familySize : correctRank;
    }
}

public sealed record LegacyPenultimateWideCarryCandidate(
    PatchedWideTerminalSentinelCandidate Previous,BigInteger Rank);

public sealed class LegacyPenultimateWideCarryPhaseHandler
{
    private static readonly BigInteger M=(BigInteger.One<<127)-BigInteger.One;
    private readonly PatchedWideTerminalSentinelPhaseHandler _previous=new();
    private readonly LegacyPenultimateWideCarry _old=new();

    public LegacyPenultimateWideCarryCandidate Handle(MonsterContext context)
    {
        if(context is null ||
           context.LegacyWideFamilySize is not BigInteger n || n<=M ||
           context.LegacyAnswerStepIndex is not BigInteger k || !k.IsZero ||
           context.LegacyQueriedBowlId is not int id || id is <1 or >6 ||
           context.LegacyBowlQuestionSeal is not int seal || seal is not (21 or 31) ||
           context.LegacyPenultimateWideCarryRankResult.HasValue ||
           context.PatchedWideTerminalSentinelRankResult.HasValue ||
           context.LegacyWideTerminalSentinelRankResult.HasValue ||
           context.PatchedDescendingRankMirrorResult.HasValue ||
           context.PatchedSauceFinalBowls is not null ||
           context.PatchedVisibleDrops is not null)
            throw new MonsterValidationException("سياق شاهد الحَمْل قبل الأخير ناقص أو مستعمل.");
        var previous=_previous.Handle(context);
        return new LegacyPenultimateWideCarryCandidate(
            previous,_old.Carry(previous.Rank,n));
    }
}
