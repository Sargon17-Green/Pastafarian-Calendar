using System.Numerics;

namespace PastafarianCalendar.Monster;

// الرقعة التاسعة عشرة: إلغاء زيادة ثانية في خرج المرتبة، دون محو شاهدها.
// يبقى حساب الجواب والقبول واتجاه الرفض في جميع المعالجات السابقة كما كان.
public sealed class DoubleOffsetWideRankPatchWrapper
{
    private static readonly BigInteger M=(BigInteger.One<<127)-BigInteger.One;

    public BigInteger RotateBack(BigInteger historicalRank,BigInteger familySize)
    {
        if(familySize<=M || historicalRank<1 || historicalRank>familySize)
            throw new MonsterValidationException("رتبة الأسرة الواسعة التاريخية غير صالحة.");
        return historicalRank==BigInteger.One
            ? familySize
            : historicalRank-BigInteger.One;
    }

    public BigInteger Patch(LegacyDoubleOffsetWideRankCandidate historical,
                            BigInteger familySize)
    {
        if(historical is null || historical.Previous is null ||
           familySize<=M ||
           historical.Previous.Rank<1 || historical.Previous.Rank>familySize)
            throw new MonsterValidationException("شاهد الإزاحة التاريخية ناقص أو غير صالح.");
        var unchanged=new LegacyDoubleOffsetWideRank().Shift(
            historical.Previous,familySize);
        if(historical.Rank!=unchanged)
            throw new MonsterValidationException("تبدّل شاهد الإزاحة التاريخية.");
        var corrected=RotateBack(historical.Rank,familySize);
        if(corrected!=historical.Previous.Rank)
            throw new MonsterValidationException("الرتبة المصححة لا تطابق الرقعة السابقة.");
        return corrected;
    }
}

public sealed record PatchedDoubleOffsetWideRankCandidate(
    LegacyDoubleOffsetWideRankCandidate Historical,BigInteger Rank);

public sealed class PatchedDoubleOffsetWideRankPhaseHandler
{
    private readonly LegacyDoubleOffsetWideRankPhaseHandler _old=new();
    private readonly DoubleOffsetWideRankPatchWrapper _patch=new();

    public PatchedDoubleOffsetWideRankCandidate Handle(MonsterContext context)
    {
        if(context is null ||
           context.LegacyWideFamilySize is not BigInteger n ||
           n<=((BigInteger.One<<127)-BigInteger.One) ||
           context.LegacyAnswerStepIndex is not BigInteger k || !k.IsZero ||
           context.LegacyQueriedBowlId is not int id || id is <1 or >6 ||
           context.LegacyBowlQuestionSeal is not int seal || seal is not (21 or 31) ||
           context.LegacyDoubleOffsetWideRankResult.HasValue ||
           context.PatchedDoubleOffsetWideRankResult.HasValue ||
           context.PatchedRejectionDirectionRankResult.HasValue ||
           context.LegacyRejectionDirectionRankResult.HasValue ||
           context.PatchedInclusiveWideLimitRankResult.HasValue ||
           context.PatchedAnswerAtResult.HasValue ||
           context.PatchedBowlQuestionResult is not null ||
           context.PatchedSauceFinalBowls is not null ||
           context.PatchedVisibleDrops is not null)
            throw new MonsterValidationException("سياق الرقعة التاسعة عشرة ناقص أو مستعمل.");

        var historical=_old.Handle(context);
        return new PatchedDoubleOffsetWideRankCandidate(
            historical,_patch.Patch(historical,n));
    }
}
