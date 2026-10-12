using System.Numerics;

namespace PastafarianCalendar.Monster;

// الرقعة الثالثة عشرة: الحاتم داخل مربع الجواب الأول، لا في الحدّ الخارجي وحده.
public sealed class BowlQuestionSealPatchWrapper
{
    private readonly SavePatchWrapper _save = new();

    public LegacyBowlQuestionResult Patch(
        BigInteger[] finalBowls, int queriedBowlId, int correctedNextBowlId, int seal)
    {
        if (finalBowls is null || finalBowls.Length != 7 ||
            finalBowls.Skip(1).Any(x => x < BigInteger.One) ||
            queriedBowlId is < 1 or > 6 ||
            correctedNextBowlId is < 1 or > 6 ||
            queriedBowlId == correctedNextBowlId || seal < 0)
            throw new MonsterValidationException("قيم رقعة حاتم سؤال الصلصة غير صالحة.");

        // تحفظ SavePatchWrapper المجال [1,2^127-1] مع استدعاء مسار الباقي القديم.
        var first = _save.SavePatch(
            BigInteger.Pow(finalBowls[queriedBowlId] + seal + 181, 2) +
            179 * finalBowls[correctedNextBowlId] + seal);

        var directionNumber = _save.SavePatch(
            BigInteger.Pow(first + seal + 1 + 193, 2) +
            193 * first + 197 * finalBowls[6]);
        var step = directionNumber % 2 == 1 ? 1 : -1;
        return new LegacyBowlQuestionResult(first,step);
    }
}

// حامل الرقعة يبقي نتيجة العيب القديم كما حُسبت فعلاً، ولا يصلحه بأثر رجعي.
public sealed record PatchedBowlQuestionCandidate(
    LegacyUnsealedBowlQuestionCandidate Historical,
    LegacyBowlQuestionResult Answer);

public sealed class PatchedBowlQuestionPhaseHandler
{
    private readonly LegacyUnsealedBowlQuestionPhaseHandler _old = new();
    private readonly BowlQuestionSealPatchWrapper _patch = new();

    public PatchedBowlQuestionCandidate Handle(MonsterContext context)
    {
        if (context is null ||
            context.LegacyQueriedBowlId is not int id || id is < 1 or > 6 ||
            context.LegacyBowlQuestionSeal is not int seal ||
            seal is not (21 or 31) ||
            context.PatchedBowlQuestionResult is not null ||
            context.LegacyUnsealedBowlQuestionResult is not null ||
            context.PatchedNextBowlResult.HasValue ||
            context.PatchedSauceFinalBowls is not null ||
            context.PatchedVisibleDrops is not null)
            throw new MonsterValidationException("سياق الرقعة الثالثة عشرة ناقص أو مستخدم.");

        var historical = _old.Handle(context);
        var sauce = historical.Historical.Historical.Sauce.Patched;
        var corrected = _patch.Patch(
            sauce.FinalBowls,id,historical.Historical.NextBowlId,seal);
        return new PatchedBowlQuestionCandidate(historical,corrected);
    }
}
