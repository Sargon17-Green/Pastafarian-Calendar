using System.Numerics;

namespace PastafarianCalendar.Monster;

// الاكتشاف السادس عشر: أرقام السؤال المتتابعة تُكتب في الأسرة الواسعة
// من الموضع الأعلى إلى الأدنى، بخلاف معيار الموضع الأول الأقل وزناً.
// يبقى مسار الخطوة الصفرية المصحح حياً، ولا تُصحح هذه الندبة قبل الطور 33.
public sealed class LegacyReversedWideDigits
{
    private static readonly BigInteger M=(BigInteger.One<<127)-BigInteger.One;
    private readonly AnswerStepZeroBasedPatchWrapper _answer=new();

    public BigInteger Choose(LegacyBowlQuestionResult stream,BigInteger familySize)
    {
        if(stream is null || stream.First<1 || stream.First>M ||
           stream.DirectionStep is not (1 or -1) || familySize<=M)
            throw new MonsterValidationException("تيار جواب الأسرة الواسعة أو حجمها غير صالح.");

        var places=1;
        var space=M;
        while(space<familySize)
        {
            places++;
            space*=M;
        }

        BigInteger wide=BigInteger.One;
        var weight=space/M;
        for(var j=0;j<places;j++)
        {
            var x=_answer.Patch(stream,new BigInteger(j));
            // الخطأ التاريخي الوحيد: وزن الرقم الأول هو الأعلى.
            wide+=(x-BigInteger.One)*weight;
            weight/=M;
        }

        var limit=space/familySize*familySize;
        if(wide>limit)
        {
            // تجاوز منطقة الرفض باستخدام نفس انتقال ±1 الدوري؛
            // القفز الحسابي مكافئ للاجتياز خطوة خطوة حتى أول جواب مقبول.
            BigInteger steps=stream.DirectionStep==1 ?
                space-wide+BigInteger.One : wide-limit;
            var moved=(wide-BigInteger.One)+stream.DirectionStep*steps;
            moved%=space;
            if(moved<0)moved+=space;
            wide=moved+BigInteger.One;
            if(wide>limit)
                throw new MonsterValidationException("فشل مسار تجاوز نطاق الرفض الواسع.");
        }
        return (wide-BigInteger.One)%familySize+BigInteger.One;
    }
}

public sealed record LegacyReversedWideRankCandidate(
    PatchedAnswerStepCandidate Step,
    BigInteger FamilySize,
    BigInteger Rank);

public sealed class LegacyReversedWideRankPhaseHandler
{
    private readonly PatchedAnswerStepPhaseHandler _prior=new();
    private readonly LegacyReversedWideDigits _legacy=new();

    public LegacyReversedWideRankCandidate Handle(MonsterContext context)
    {
        if(context is null ||
           context.LegacyWideFamilySize is not BigInteger n || n<=((BigInteger.One<<127)-BigInteger.One) ||
           context.LegacyAnswerStepIndex is not BigInteger k || !k.IsZero ||
           context.LegacyQueriedBowlId is not int id || id is < 1 or > 6 ||
           context.LegacyBowlQuestionSeal is not int seal || seal is not (21 or 31) ||
           context.LegacyReversedWideRankResult.HasValue ||
           context.LegacyShortFamilyRankResult.HasValue ||
           context.PatchedShortFamilyRankResult.HasValue ||
           context.PatchedAnswerAtResult.HasValue ||
           context.LegacyOneBasedAnswerAtResult.HasValue ||
           context.PatchedBowlQuestionResult is not null ||
           context.PatchedSauceFinalBowls is not null ||
           context.PatchedVisibleDrops is not null)
            throw new MonsterValidationException("مرشح الأسرة الواسعة غير مؤسس أو مشغول.");

        var step=_prior.Handle(context);
        return new LegacyReversedWideRankCandidate(
            step,n,_legacy.Choose(step.Historical.Question.Answer,n));
    }
}
