using System.Numerics;

namespace PastafarianCalendar.Monster;

// الرقعة الرابعة عشرة: k=0 يقرأ أول جواب، ويُصحّح الانزياح من دون تعديل القديم.
public sealed class AnswerStepZeroBasedPatchWrapper
{
    private readonly SavePatchWrapper _save = new();

    public BigInteger Patch(LegacyBowlQuestionResult stream, BigInteger k)
    {
        var modulus=(BigInteger.One<<127)-BigInteger.One;
        if (stream is null ||
            stream.First < BigInteger.One || stream.First > modulus ||
            stream.DirectionStep is not (1 or -1) || k < BigInteger.Zero)
            throw new MonsterValidationException("موضع التيار أو الجواب المختوم غير صالح.");

        // يُستدعى غلاف الحفظ الذي يُبقي الحساب التاريخي للباقي حياً.
        return _save.SavePatch(stream.First + stream.DirectionStep*k);
    }
}

public sealed record PatchedAnswerStepCandidate(
    LegacyOneBasedAnswerCandidate Historical,
    BigInteger Value);

public sealed class PatchedAnswerStepPhaseHandler
{
    private readonly LegacyOneBasedAnswerPhaseHandler _legacy = new();
    private readonly AnswerStepZeroBasedPatchWrapper _patch = new();

    public PatchedAnswerStepCandidate Handle(MonsterContext context)
    {
        if (context is null ||
            context.LegacyAnswerStepIndex is not BigInteger k || k<0 ||
            context.LegacyQueriedBowlId is not int id || id is < 1 or > 6 ||
            context.LegacyBowlQuestionSeal is not int seal || seal is not (21 or 31) ||
            context.PatchedAnswerAtResult.HasValue ||
            context.LegacyOneBasedAnswerAtResult.HasValue ||
            context.PatchedBowlQuestionResult is not null ||
            context.LegacyUnsealedBowlQuestionResult is not null ||
            context.PatchedNextBowlResult.HasValue ||
            context.PatchedSauceFinalBowls is not null ||
            context.PatchedVisibleDrops is not null)
            throw new MonsterValidationException("سياق رقعة تيار الإجابات ناقص أو مستعمل.");

        // نحفظ النتيجة الخاطئة الحقيقية من السلسلة كلها قبل حساب الإصلاح.
        var old=_legacy.Handle(context);
        var correct=_patch.Patch(old.Question.Answer,k);
        return new PatchedAnswerStepCandidate(old,correct);
    }
}
