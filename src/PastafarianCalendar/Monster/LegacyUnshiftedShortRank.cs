using System.Numerics;

namespace PastafarianCalendar.Monster;

// الندبة الخامسة عشرة: ترتيب الأسرة القصيرة يبدأ من باقي x لا من باقي x-1.
// يظلّ التيار عند k=0 صحيحًا؛ فلا تُعاد ندبة إزاحة الخطوة السابقة.
public sealed class LegacyUnshiftedShortRank
{
    private static readonly BigInteger Modulus=(BigInteger.One<<127)-BigInteger.One;
    private readonly AnswerStepZeroBasedPatchWrapper _answer=new();

    public BigInteger Choose(LegacyBowlQuestionResult stream,BigInteger familySize)
    {
        if (stream is null || stream.First<1 || stream.First>Modulus ||
            stream.DirectionStep is not (1 or -1) ||
            familySize<1 || familySize>Modulus)
            throw new MonsterValidationException("حجم الأسرة القصيرة أو تيار الإجابة غير صالح.");

        var acceptanceLimit=(Modulus/familySize)*familySize;
        var x=_answer.Patch(stream,BigInteger.Zero);
        if (x>acceptanceLimit)
        {
            // اتجاه الخطوة هو ±1؛ نتجاوز منطقة الرفض المتصلة حسابياً.
            // النتيجة تساوي أول إجابة مقبولة بعد الفحص التتابعي، بلا حلقة هائلة.
            var steps=stream.DirectionStep==1 ?
                Modulus-x+1 : x-acceptanceLimit;
            x=_answer.Patch(stream,steps);
            if(x>acceptanceLimit)
                throw new MonsterValidationException("فشل عبور حدّ القبول.");
        }

        // موضع العيب المقصود: الصحيح هو ((x-1) mod familySize)+1.
        return x%familySize+1;
    }
}

public sealed record LegacyUnshiftedShortRankCandidate(
    PatchedAnswerStepCandidate Step,
    BigInteger FamilySize,
    BigInteger Rank);

public sealed class LegacyUnshiftedShortRankPhaseHandler
{
    private readonly PatchedAnswerStepPhaseHandler _prior=new();
    private readonly LegacyUnshiftedShortRank _legacy=new();

    public LegacyUnshiftedShortRankCandidate Handle(MonsterContext context)
    {
        if(context is null ||
           context.LegacyShortFamilySize is not BigInteger n || n<1 ||
           n>((BigInteger.One<<127)-BigInteger.One) ||
           context.LegacyAnswerStepIndex is not BigInteger k || !k.IsZero ||
           context.LegacyQueriedBowlId is not int id || id is < 1 or > 6 ||
           context.LegacyBowlQuestionSeal is not int seal || seal is not (21 or 31) ||
           context.LegacyShortFamilyRankResult.HasValue ||
           context.PatchedAnswerAtResult.HasValue ||
           context.LegacyOneBasedAnswerAtResult.HasValue ||
           context.PatchedBowlQuestionResult is not null ||
           context.PatchedSauceFinalBowls is not null ||
           context.PatchedVisibleDrops is not null)
            throw new MonsterValidationException("سياق المرتبة القصيرة ناقص أو مشغول.");

        var step=_prior.Handle(context);
        return new LegacyUnshiftedShortRankCandidate(
            step,n,_legacy.Choose(step.Historical.Question.Answer,n));
    }
}
