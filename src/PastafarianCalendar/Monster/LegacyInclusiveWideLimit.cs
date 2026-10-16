using System.Numerics;

namespace PastafarianCalendar.Monster;

// الاكتشاف السابع عشر: الجواب المساوي لحد القبول يرفض بالخطأ.
// تظل أوزان الخانات المصححة من الرقعة السادسة عشرة كما هي.
public sealed class LegacyInclusiveWideLimit
{
    private static readonly BigInteger M=(BigInteger.One<<127)-BigInteger.One;
    private readonly AnswerStepZeroBasedPatchWrapper _answer=new();

    public BigInteger Choose(LegacyBowlQuestionResult stream, BigInteger familySize)
    {
        if(stream is null || stream.First<1 || stream.First>M ||
           stream.DirectionStep is not (1 or -1) || familySize<=M)
            throw new MonsterValidationException("حجم العائلة الواسعة أو تيار السؤال غير صالح.");

        var places=1;
        var space=M;
        while(space<familySize)
        {
            places++;
            space*=M;
        }
        var wide=BigInteger.One;
        var weight=BigInteger.One;
        for(var j=0;j<places;j++)
        {
            wide+=(_answer.Patch(stream,new BigInteger(j))-BigInteger.One)*weight;
            weight*=M;
        }

        var limit=space/familySize*familySize;
        // العيب المقصود: >= بدلاً من >؛ تُرفض القيمة المقبولة عند الحد ذاته.
        if(wide>=limit)
        {
            var steps=stream.DirectionStep==1 ?
                space-wide+BigInteger.One : wide-limit+BigInteger.One;
            var moved=(wide-BigInteger.One)+stream.DirectionStep*steps;
            moved%=space;
            if(moved<0)moved+=space;
            wide=moved+BigInteger.One;
            if(wide>=limit)
                throw new MonsterValidationException("فشل الانتقال التاريخي فوق حدّ القبول.");
        }
        return (wide-BigInteger.One)%familySize+BigInteger.One;
    }
}

public sealed record LegacyInclusiveWideLimitCandidate(
    PatchedWideRankCandidate Previous,
    BigInteger Rank);

public sealed class LegacyInclusiveWideLimitPhaseHandler
{
    private readonly PatchedWideRankPhaseHandler _prior=new();
    private readonly LegacyInclusiveWideLimit _legacy=new();

    public LegacyInclusiveWideLimitCandidate Handle(MonsterContext context)
    {
        if(context is null ||
           context.LegacyWideFamilySize is not BigInteger n ||
           n<=((BigInteger.One<<127)-BigInteger.One) ||
           context.LegacyAnswerStepIndex is not BigInteger k || !k.IsZero ||
           context.LegacyQueriedBowlId is not int id || id is < 1 or > 6 ||
           context.LegacyBowlQuestionSeal is not int seal || seal is not (21 or 31) ||
           context.LegacyInclusiveWideLimitRankResult.HasValue ||
           context.PatchedWideRankResult.HasValue ||
           context.LegacyReversedWideRankResult.HasValue ||
           context.PatchedAnswerAtResult.HasValue ||
           context.LegacyOneBasedAnswerAtResult.HasValue ||
           context.PatchedBowlQuestionResult is not null ||
           context.PatchedSauceFinalBowls is not null ||
           context.PatchedVisibleDrops is not null)
            throw new MonsterValidationException("سياق الاكتشاف السابع عشر غير مؤسس أو مشغول.");
        var previous=_prior.Handle(context);
        var answer=previous.Historical.Step.Historical.Question.Answer;
        return new LegacyInclusiveWideLimitCandidate(previous,_legacy.Choose(answer,n));
    }
}
