using System.Numerics;

namespace PastafarianCalendar.Monster;

// الندبة الحادية والعشرون: ضياع الخانات العليا عند إخراج مرتبة واسعة.
public sealed class LegacyWideSlotTruncation
{
    private static readonly BigInteger M=(BigInteger.One<<127)-BigInteger.One;
    public BigInteger Fold(BigInteger rank,BigInteger familySize)
    {
        if(familySize<=M || rank<1 || rank>familySize)
            throw new MonsterValidationException("مدخل قطع المرتبة الواسعة غير صالح.");
        return BigInteger.One+(rank-BigInteger.One)%M;
    }
}

public sealed record LegacyWideSlotTruncationCandidate(
    PatchedUpperPlaceBiasCandidate Previous,BigInteger Rank);

public sealed class LegacyWideSlotTruncationPhaseHandler
{
    private static readonly BigInteger M=(BigInteger.One<<127)-BigInteger.One;
    private readonly PatchedUpperPlaceBiasPhaseHandler _previous=new();
    private readonly LegacyWideSlotTruncation _old=new();

    public LegacyWideSlotTruncationCandidate Handle(MonsterContext context)
    {
        if(context is null ||
           context.LegacyWideFamilySize is not BigInteger n || n<=M ||
           context.LegacyAnswerStepIndex is not BigInteger k || !k.IsZero ||
           context.LegacyQueriedBowlId is not int id || id is <1 or >6 ||
           context.LegacyBowlQuestionSeal is not int seal || seal is not (21 or 31) ||
           context.LegacyWideSlotTruncationRankResult.HasValue ||
           context.PatchedUpperPlaceBiasRankResult.HasValue ||
           context.LegacyUpperPlaceBiasRankResult.HasValue ||
           context.PatchedDoubleOffsetWideRankResult.HasValue ||
           context.PatchedSauceFinalBowls is not null ||
           context.PatchedVisibleDrops is not null)
            throw new MonsterValidationException("سياق شاهد القطع ناقص أو مستعمل.");
        var before=_previous.Handle(context);
        return new LegacyWideSlotTruncationCandidate(before,_old.Fold(before.Rank,n));
    }
}
