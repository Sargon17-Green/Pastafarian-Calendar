using System.Numerics;

namespace PastafarianCalendar.Monster;

// الرقعة الثامنة عشرة: إذا رُفض جواب واسع، ففي الاتجاه الموجب الرتبة 1
// وفي الاتجاه السالب الرتبة n. يبقى الشاهد القديم كما هو.
public sealed class RejectionDirectionPatchWrapper
{
    private static readonly BigInteger M=(BigInteger.One<<127)-BigInteger.One;
    private readonly AnswerStepZeroBasedPatchWrapper _answer=new();

    public BigInteger Patch(LegacyWideRejectionDirectionCandidate historical,BigInteger familySize)
    {
        if(historical is null || historical.Previous is null ||
           historical.Previous.Historical is null || familySize<=M ||
           historical.Rank<1 || historical.Rank>familySize ||
           historical.Previous.Rank<1 || historical.Previous.Rank>familySize)
            throw new MonsterValidationException("مرشح تصحيح اتجاه الرفض غير صالح.");

        var stream=historical.Previous.Historical.Previous.Historical.Step.Historical.Question.Answer;
        if(stream is null || stream.First<1 || stream.First>M ||
           stream.DirectionStep is not (1 or -1))
            throw new MonsterValidationException("تيار السؤال المصحح غير صالح.");

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
        var correct=wide>limit
            ? (stream.DirectionStep==1?BigInteger.One:familySize)
            : (wide-BigInteger.One)%familySize+BigInteger.One;

        if(correct!=historical.Previous.Rank)
            throw new MonsterValidationException("خالف تصحيح الاتجاه الرتبة المعتمدة سابقاً.");
        return correct;
    }
}

public sealed record PatchedRejectionDirectionCandidate(
    LegacyWideRejectionDirectionCandidate Historical,BigInteger Rank);

public sealed class PatchedRejectionDirectionPhaseHandler
{
    private readonly LegacyWideRejectionDirectionPhaseHandler _legacy=new();
    private readonly RejectionDirectionPatchWrapper _patch=new();

    public PatchedRejectionDirectionCandidate Handle(MonsterContext context)
    {
        if(context is null ||
           context.LegacyWideFamilySize is not BigInteger n || n<=((BigInteger.One<<127)-BigInteger.One) ||
           context.LegacyAnswerStepIndex is not BigInteger k || !k.IsZero ||
           context.LegacyQueriedBowlId is not int id || id is <1 or >6 ||
           context.LegacyBowlQuestionSeal is not int seal || seal is not (21 or 31) ||
           context.PatchedRejectionDirectionRankResult.HasValue ||
           context.LegacyRejectionDirectionRankResult.HasValue ||
           context.PatchedInclusiveWideLimitRankResult.HasValue ||
           context.LegacyInclusiveWideLimitRankResult.HasValue ||
           context.PatchedWideRankResult.HasValue ||
           context.PatchedAnswerAtResult.HasValue ||
           context.PatchedBowlQuestionResult is not null ||
           context.PatchedSauceFinalBowls is not null ||
           context.PatchedVisibleDrops is not null)
            throw new MonsterValidationException("سياق اتجاه الرفض غير مؤسس أو مستعمل.");
        var old=_legacy.Handle(context);
        return new PatchedRejectionDirectionCandidate(old,_patch.Patch(old,n));
    }
}
