using System.Numerics;

namespace PastafarianCalendar.Monster;

// الندبة العشرون: يُضاف وزن الخانة العليا مرتين إلى رتبة صحيحة مسبقاً.
// لا تُمسّ نتيجة التطبيع السابقة ولا يُستدعى مرجع الاختبارات من الإنتاج.
public sealed class LegacyUpperPlaceBias
{
    private static readonly BigInteger M=(BigInteger.One<<127)-BigInteger.One;

    public BigInteger Shift(BigInteger correctRank, BigInteger familySize)
    {
        if(familySize<=M || correctRank<1 || correctRank>familySize)
            throw new MonsterValidationException("رتبة الأسرة الواسعة المعتمدة غير صالحة.");
        var space=M;
        var highWeight=BigInteger.One;
        while(space<familySize)
        {
            highWeight=space;
            space*=M;
        }
        // الخلل المقصود عند تسلسل المرتبة: زيادة وزن الخانة العليا.
        return (correctRank-BigInteger.One+highWeight)%familySize+BigInteger.One;
    }
}

public sealed record LegacyUpperPlaceBiasCandidate(
    PatchedDoubleOffsetWideRankCandidate Previous,
    BigInteger Rank);

public sealed class LegacyUpperPlaceBiasPhaseHandler
{
    private readonly PatchedDoubleOffsetWideRankPhaseHandler _previous=new();
    private readonly LegacyUpperPlaceBias _legacy=new();

    public LegacyUpperPlaceBiasCandidate Handle(MonsterContext context)
    {
        if(context is null ||
           context.LegacyWideFamilySize is not BigInteger n ||
           n<=((BigInteger.One<<127)-BigInteger.One) ||
           context.LegacyAnswerStepIndex is not BigInteger k || !k.IsZero ||
           context.LegacyQueriedBowlId is not int id || id is <1 or >6 ||
           context.LegacyBowlQuestionSeal is not int seal || seal is not (21 or 31) ||
           context.LegacyUpperPlaceBiasRankResult.HasValue ||
           context.PatchedDoubleOffsetWideRankResult.HasValue ||
           context.LegacyDoubleOffsetWideRankResult.HasValue ||
           context.PatchedRejectionDirectionRankResult.HasValue ||
           context.PatchedSauceFinalBowls is not null ||
           context.PatchedVisibleDrops is not null)
            throw new MonsterValidationException("سياق انحياز الخانة العليا غير صالح أو مستخدم.");
        var previous=_previous.Handle(context);
        return new LegacyUpperPlaceBiasCandidate(
            previous,_legacy.Shift(previous.Rank,n));
    }
}
