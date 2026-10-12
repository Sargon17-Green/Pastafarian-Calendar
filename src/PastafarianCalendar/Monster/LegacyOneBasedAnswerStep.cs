using System.Numerics;

namespace PastafarianCalendar.Monster;

// الندبة الرابعة عشرة: يبدأ عداد خطوات السؤال عند k=1، لا k=0.
// تُستعمل الإجابة الأولى والاتجاه الصحيحان من الرقعة الثالثة عشرة.
public sealed class LegacyOneBasedAnswerStep
{
    private readonly SavePatchWrapper _save = new();

    public BigInteger At(LegacyBowlQuestionResult stream, BigInteger k)
    {
        var modulus = (BigInteger.One << 127) - BigInteger.One;
        if (stream is null || stream.First < 1 || stream.First > modulus ||
            stream.DirectionStep is not (1 or -1) || k < 0)
            throw new MonsterValidationException("المجرى التاريخي أو موضع خطوته غير صالح.");

        // الخطأ المستقل: تستعمل هذه الدالة k+1 ولا تعدّل مجرى السؤال نفسه.
        return _save.SavePatch(stream.First + stream.DirectionStep * (k + 1));
    }
}

public sealed record LegacyOneBasedAnswerCandidate(
    PatchedBowlQuestionCandidate Question,
    BigInteger K,
    BigInteger Value);

public sealed class LegacyOneBasedAnswerPhaseHandler
{
    private readonly PatchedBowlQuestionPhaseHandler _question = new();
    private readonly LegacyOneBasedAnswerStep _legacy = new();

    public LegacyOneBasedAnswerCandidate Handle(MonsterContext context)
    {
        if (context is null ||
            context.LegacyAnswerStepIndex is not BigInteger k || k < 0 ||
            context.LegacyQueriedBowlId is not int id || id is < 1 or > 6 ||
            context.LegacyBowlQuestionSeal is not int seal || seal is not (21 or 31) ||
            context.LegacyOneBasedAnswerAtResult.HasValue ||
            context.PatchedBowlQuestionResult is not null ||
            context.LegacyUnsealedBowlQuestionResult is not null ||
            context.PatchedNextBowlResult.HasValue ||
            context.PatchedSauceFinalBowls is not null ||
            context.PatchedVisibleDrops is not null)
            throw new MonsterValidationException("مدخل السؤال التاريخي ناقص أو مستخدم.");

        var question = _question.Handle(context);
        return new LegacyOneBasedAnswerCandidate(
            question,k,_legacy.At(question.Answer,k));
    }
}
