using System.Numerics;

namespace PastafarianCalendar.Monster;

// الندبة الثالثة عشرة: حذف الحاتم من داخل مربع جواب الصلصة الأول.
// الجار هنا مُصحَّح من الرقعة الثانية عشرة؛ الخلل مستقل عن ترتيب الأوعية.
public sealed record LegacyBowlQuestionResult(BigInteger First, int DirectionStep);

public sealed class LegacyUnsealedBowlQuestion
{
    private readonly SavePatchWrapper _save = new();

    public LegacyBowlQuestionResult Ask(
        BigInteger[] finalBowls, int queriedBowlId, int correctedNextBowlId, int seal)
    {
        if (finalBowls is null || finalBowls.Length != 7 ||
            finalBowls.Skip(1).Any(x => x < 1) ||
            queriedBowlId is < 1 or > 6 || correctedNextBowlId is < 1 or > 6 ||
            queriedBowlId == correctedNextBowlId || seal < 0)
            throw new MonsterValidationException("قيم سؤال الصلصة التاريخي غير صالحة.");

        // النص الصحيح يستعمل (B[id] + seal + 181)^2. المسار القديم يسقط seal هنا فقط.
        var brokenFirst = _save.SavePatch(
            BigInteger.Pow(finalBowls[queriedBowlId] + 181, 2) +
            179 * finalBowls[correctedNextBowlId] + seal);
        var directionNumber = _save.SavePatch(
            BigInteger.Pow(brokenFirst + seal + 1 + 193, 2) +
            193 * brokenFirst + 197 * finalBowls[6]);
        var step = directionNumber % 2 == 1 ? 1 : -1;
        return new LegacyBowlQuestionResult(brokenFirst,step);
    }
}

public sealed record LegacyUnsealedBowlQuestionCandidate(
    PatchedNextBowlCandidate Historical,
    int Seal,
    LegacyBowlQuestionResult Answer);

public sealed class LegacyUnsealedBowlQuestionPhaseHandler
{
    private readonly PatchedNextBowlPhaseHandler _next = new();
    private readonly LegacyUnsealedBowlQuestion _old = new();

    public LegacyUnsealedBowlQuestionCandidate Handle(MonsterContext context)
    {
        if (context is null ||
            context.LegacyQueriedBowlId is not int id || id is < 1 or > 6 ||
            context.LegacyBowlQuestionSeal is not int seal ||
            seal is not (21 or 31) ||
            context.LegacyUnsealedBowlQuestionResult is not null ||
            context.PatchedNextBowlResult.HasValue ||
            context.LegacyFixedNextBowlResult.HasValue ||
            context.PatchedVisibleDrops is not null ||
            context.PatchedSauceFinalBowls is not null)
            throw new MonsterValidationException("سياق سؤال الصلصة القديم ناقص أو مشغول.");

        // المسار القديم الكامل حتى الرقعة 12 يعمل قبل سؤال الصلصة.
        var corrected = _next.Handle(context);
        var answer = _old.Ask(
            corrected.Historical.Sauce.Patched.FinalBowls,
            id,corrected.NextBowlId,seal);
        return new LegacyUnsealedBowlQuestionCandidate(corrected,seal,answer);
    }
}
