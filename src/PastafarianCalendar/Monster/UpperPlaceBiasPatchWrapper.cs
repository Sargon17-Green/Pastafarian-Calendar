using System.Numerics;

namespace PastafarianCalendar.Monster;

// الرقعة العشرون: طرح وزن أعلى خانة من إخراج الشاهد دون محوه.
public sealed class UpperPlaceBiasPatchWrapper
{
    private static readonly BigInteger M=(BigInteger.One<<127)-BigInteger.One;

    public BigInteger RotateBack(BigInteger historicalRank,BigInteger familySize)
    {
        if(familySize<=M || historicalRank<1 || historicalRank>familySize)
            throw new MonsterValidationException("رتبة الأسرة الواسعة القديمة غير صالحة.");
        var space=M;
        var highWeight=BigInteger.One;
        while(space<familySize)
        {
            highWeight=space;
            space*=M;
        }
        var zeroBased=(historicalRank-BigInteger.One-highWeight)%familySize;
        if(zeroBased<0)zeroBased+=familySize;
        return zeroBased+BigInteger.One;
    }

    public BigInteger Patch(LegacyUpperPlaceBiasCandidate historical,
                            BigInteger familySize)
    {
        if(historical is null || historical.Previous is null ||
           familySize<=M ||
           historical.Previous.Rank<1 || historical.Previous.Rank>familySize ||
           historical.Rank<1 || historical.Rank>familySize)
            throw new MonsterValidationException("شاهد الخانة العليا غير صالح.");
        var unchanged=new LegacyUpperPlaceBias().Shift(
            historical.Previous.Rank,familySize);
        if(historical.Rank!=unchanged)
            throw new MonsterValidationException("تبدّل شاهد انحياز الخانة العليا.");
        var corrected=RotateBack(historical.Rank,familySize);
        if(corrected!=historical.Previous.Rank)
            throw new MonsterValidationException("الرتبة لا تطابق الرقعة التاسعة عشرة.");
        return corrected;
    }
}

public sealed record PatchedUpperPlaceBiasCandidate(
    LegacyUpperPlaceBiasCandidate Historical,BigInteger Rank);

public sealed class PatchedUpperPlaceBiasPhaseHandler
{
    private static readonly BigInteger M=(BigInteger.One<<127)-BigInteger.One;
    private readonly LegacyUpperPlaceBiasPhaseHandler _old=new();
    private readonly UpperPlaceBiasPatchWrapper _patch=new();

    public PatchedUpperPlaceBiasCandidate Handle(MonsterContext context)
    {
        if(context is null ||
           context.LegacyWideFamilySize is not BigInteger n || n<=M ||
           context.LegacyAnswerStepIndex is not BigInteger k || !k.IsZero ||
           context.LegacyQueriedBowlId is not int id || id is <1 or >6 ||
           context.LegacyBowlQuestionSeal is not int seal || seal is not (21 or 31) ||
           context.PatchedUpperPlaceBiasRankResult.HasValue ||
           context.LegacyUpperPlaceBiasRankResult.HasValue ||
           context.PatchedDoubleOffsetWideRankResult.HasValue ||
           context.LegacyDoubleOffsetWideRankResult.HasValue ||
           context.PatchedRejectionDirectionRankResult.HasValue ||
           context.PatchedSauceFinalBowls is not null ||
           context.PatchedVisibleDrops is not null)
            throw new MonsterValidationException("سياق الرقعة العشرين ناقص أو مستعمل.");
        var old=_old.Handle(context);
        return new PatchedUpperPlaceBiasCandidate(old,_patch.Patch(old,n));
    }
}
