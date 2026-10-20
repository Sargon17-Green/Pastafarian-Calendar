using System.Numerics;

namespace PastafarianCalendar.Monster;

// الندبة الثامنة عشرة: عند رفض جواب واسع، يعيد المسار القديم الرتبة 1
// في الاتجاهين. وهو صحيح عند الزيادة، لكنه خاطئ عند النقصان:
// أول جواب مقبول بعد رفض مجال أعلى limit هو limit، ورتبته familySize.
public sealed class LegacyWideRejectionDirection
{
    private static readonly BigInteger M=(BigInteger.One<<127)-BigInteger.One;
    private readonly AnswerStepZeroBasedPatchWrapper _answer=new();

    public BigInteger Choose(LegacyBowlQuestionResult stream,BigInteger familySize)
    {
        if(stream is null || stream.First<1 || stream.First>M ||
           stream.DirectionStep is not (1 or -1) || familySize<=M)
            throw new MonsterValidationException("تيار العائلة الواسعة أو حجمها غير صالح.");

        var space=M;
        var places=1;
        while(space<familySize){space*=M;places++;}
        var wide=BigInteger.One;
        var weight=BigInteger.One;
        for(var j=0;j<places;j++)
        {
            wide+=(_answer.Patch(stream,new BigInteger(j))-BigInteger.One)*weight;
            weight*=M;
        }
        var limit=(space/familySize)*familySize;
        if(wide>limit)
        {
            // الخطأ التاريخي المقصود: يفرض أول رتبة دون اعتبار إشارة التيار.
            return BigInteger.One;
        }
        return (wide-BigInteger.One)%familySize+BigInteger.One;
    }
}

public sealed record LegacyWideRejectionDirectionCandidate(
    PatchedInclusiveWideLimitCandidate Previous,
    BigInteger Rank);

public sealed class LegacyWideRejectionDirectionPhaseHandler
{
    private readonly PatchedInclusiveWideLimitPhaseHandler _prior=new();
    private readonly LegacyWideRejectionDirection _legacy=new();

    public LegacyWideRejectionDirectionCandidate Handle(MonsterContext context)
    {
        if(context is null ||
           context.LegacyWideFamilySize is not BigInteger n ||
           n<=((BigInteger.One<<127)-BigInteger.One) ||
           context.LegacyAnswerStepIndex is not BigInteger k || !k.IsZero ||
           context.LegacyQueriedBowlId is not int id || id is < 1 or > 6 ||
           context.LegacyBowlQuestionSeal is not int seal || seal is not (21 or 31) ||
           context.LegacyRejectionDirectionRankResult.HasValue ||
           context.PatchedInclusiveWideLimitRankResult.HasValue ||
           context.LegacyInclusiveWideLimitRankResult.HasValue ||
           context.PatchedWideRankResult.HasValue ||
           context.LegacyReversedWideRankResult.HasValue ||
           context.PatchedAnswerAtResult.HasValue ||
           context.PatchedBowlQuestionResult is not null ||
           context.PatchedSauceFinalBowls is not null ||
           context.PatchedVisibleDrops is not null)
            throw new MonsterValidationException("سياق اكتشاف الاتجاه الثامن عشر ناقص أو مُستعمل.");

        var previous=_prior.Handle(context);
        var stream=previous.Historical.Previous.Historical.Step.Historical.Question.Answer;
        return new LegacyWideRejectionDirectionCandidate(
            previous,_legacy.Choose(stream,n));
    }
}
