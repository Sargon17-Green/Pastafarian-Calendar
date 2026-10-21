using System.Numerics;

namespace PastafarianCalendar.Monster;

// الندبة التاسعة عشرة: بعد اختيار مرتبة واسعة صحيحة 1..n
// يعيد المخرج القديم المرتبة التالية دورياً بتطبيق +1 مرتين.
// لا تتغير الدلالة الصحيحة للدفق أو قبول الجواب أو اتجاه الرفض.
public sealed class LegacyDoubleOffsetWideRank
{
    private static readonly BigInteger M=(BigInteger.One<<127)-BigInteger.One;
    public BigInteger Shift(PatchedRejectionDirectionCandidate corrected,BigInteger familySize)
    {
        if(corrected is null || corrected.Historical is null ||
           familySize<=M || corrected.Rank<1 || corrected.Rank>familySize)
            throw new MonsterValidationException("خرج الأسرة الواسعة التاريخي غير صالح.");
        // المعالج السابق يعطي أصلاً 1+mod(wide-1,n)، وهنا +1 غير مقصودة.
        return corrected.Rank==familySize ? BigInteger.One : corrected.Rank+BigInteger.One;
    }
}

public sealed record LegacyDoubleOffsetWideRankCandidate(
    PatchedRejectionDirectionCandidate Previous,BigInteger Rank);

public sealed class LegacyDoubleOffsetWideRankPhaseHandler
{
    private readonly PatchedRejectionDirectionPhaseHandler _prior=new();
    private readonly LegacyDoubleOffsetWideRank _old=new();

    public LegacyDoubleOffsetWideRankCandidate Handle(MonsterContext context)
    {
        if(context is null ||
           context.LegacyWideFamilySize is not BigInteger n ||
           n<=((BigInteger.One<<127)-BigInteger.One) ||
           context.LegacyAnswerStepIndex is not BigInteger k || !k.IsZero ||
           context.LegacyQueriedBowlId is not int id || id is <1 or >6 ||
           context.LegacyBowlQuestionSeal is not int seal || seal is not (21 or 31) ||
           context.LegacyDoubleOffsetWideRankResult.HasValue ||
           context.PatchedRejectionDirectionRankResult.HasValue ||
           context.LegacyRejectionDirectionRankResult.HasValue ||
           context.PatchedInclusiveWideLimitRankResult.HasValue ||
           context.PatchedAnswerAtResult.HasValue ||
           context.PatchedBowlQuestionResult is not null ||
           context.PatchedSauceFinalBowls is not null ||
           context.PatchedVisibleDrops is not null)
            throw new MonsterValidationException("سياق الاكتشاف التاسع عشر غير مؤسس أو مستعمل.");
        var corrected=_prior.Handle(context);
        return new LegacyDoubleOffsetWideRankCandidate(corrected,_old.Shift(corrected,n));
    }
}
