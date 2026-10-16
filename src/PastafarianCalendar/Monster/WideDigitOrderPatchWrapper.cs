using System.Numerics;

namespace PastafarianCalendar.Monster;

// الرقعة السادسة عشرة: ترتيب خانات القاعدة M يبدأ من الخانة الأقل وزناً.
// لا نمحو معالج التعبئة المعكوسة؛ تشغّله طبقة المعالجة أولاً.
public sealed class WideDigitOrderPatchWrapper
{
    private static readonly BigInteger M=(BigInteger.One<<127)-BigInteger.One;
    private readonly AnswerStepZeroBasedPatchWrapper _answer=new();

    public BigInteger Patch(LegacyBowlQuestionResult stream,BigInteger familySize)
    {
        if(stream is null || stream.First<1 || stream.First>M ||
           stream.DirectionStep is not (1 or -1) || familySize<=M)
            throw new MonsterValidationException("مجرى الأسرة الواسعة أو حجمها غير صالح.");

        var places=1;
        var space=M;
        while(space<familySize)
        {
            places++;
            space*=M;
        }

        BigInteger wide=BigInteger.One;
        BigInteger weight=BigInteger.One;
        for(var j=0;j<places;j++)
        {
            var digit=_answer.Patch(stream,new BigInteger(j));
            wide+=(digit-BigInteger.One)*weight;
            weight*=M;
        }

        var limit=space/familySize*familySize;
        if(wide>limit)
        {
            // العدّ المتسلسل بـ ±1 في فضاء M^places، مع قفزة حسابية آمنة
            // عبر المنطقة العلوية المرفوضة حتى أول رقم مقبول.
            var steps=stream.DirectionStep==1 ?
                space-wide+BigInteger.One : wide-limit;
            var moved=(wide-BigInteger.One)+stream.DirectionStep*steps;
            moved%=space;
            if(moved<0)moved+=space;
            wide=moved+BigInteger.One;
            if(wide>limit)
                throw new MonsterValidationException("لم تصل الرقعة إلى جواب واسع مقبول.");
        }
        return (wide-BigInteger.One)%familySize+BigInteger.One;
    }
}

public sealed record PatchedWideRankCandidate(
    LegacyReversedWideRankCandidate Historical,
    BigInteger Rank);

public sealed class PatchedWideRankPhaseHandler
{
    private readonly LegacyReversedWideRankPhaseHandler _legacy=new();
    private readonly WideDigitOrderPatchWrapper _patch=new();

    public PatchedWideRankCandidate Handle(MonsterContext context)
    {
        if(context is null ||
           context.LegacyWideFamilySize is not BigInteger n ||
           n<=((BigInteger.One<<127)-BigInteger.One) ||
           context.LegacyAnswerStepIndex is not BigInteger k || !k.IsZero ||
           context.LegacyQueriedBowlId is not int id || id is < 1 or > 6 ||
           context.LegacyBowlQuestionSeal is not int seal || seal is not (21 or 31) ||
           context.PatchedWideRankResult.HasValue ||
           context.LegacyReversedWideRankResult.HasValue ||
           context.PatchedAnswerAtResult.HasValue ||
           context.LegacyOneBasedAnswerAtResult.HasValue ||
           context.PatchedBowlQuestionResult is not null ||
           context.PatchedSauceFinalBowls is not null ||
           context.PatchedVisibleDrops is not null)
            throw new MonsterValidationException("سياق رقعة الأرقام الواسعة ناقص أو مستعمل.");

        var old=_legacy.Handle(context);
        return new PatchedWideRankCandidate(old,
            _patch.Patch(old.Step.Historical.Question.Answer,n));
    }
}
