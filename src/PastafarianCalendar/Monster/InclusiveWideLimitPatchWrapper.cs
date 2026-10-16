using System.Numerics;

namespace PastafarianCalendar.Monster;

// الرقعة السابعة عشرة: المساواة بحدّ القبول مُجازة؛ الرفض يبدأ بعده.
// نستبقي كل طبقات المعالج التاريخي وشواهده ولا نُدخِل المرجع الاختباري.
public sealed class InclusiveWideLimitPatchWrapper
{
    private static readonly BigInteger M=(BigInteger.One<<127)-BigInteger.One;
    private readonly WideDigitOrderPatchWrapper _previous=new();

    public bool Accepts(BigInteger wide,BigInteger familySize,BigInteger space)
    {
        if(familySize<=M || familySize>space || space<M ||
           wide<1 || wide>space)
            throw new MonsterValidationException("مدخلات حدّ قبول الأسرة الواسعة غير صالحة.");
        var limit=(space/familySize)*familySize;
        return wide<=limit; // التصحيح المحدّد: <= بدلاً من <.
    }

    public BigInteger Patch(LegacyInclusiveWideLimitCandidate historical,
                            BigInteger familySize)
    {
        if(historical is null || historical.Previous is null ||
           historical.Previous.Historical is null ||
           familySize<=M ||
           historical.Rank<1 || historical.Rank>familySize ||
           historical.Previous.Rank<1 || historical.Previous.Rank>familySize)
            throw new MonsterValidationException("شاهد الحدود الواسعة غير صالح.");

        var stream=historical.Previous.Historical.Step.Historical.Question.Answer;
        // رقعة الخانات 16 سبق أن أثبتت التطابق بما فيه حد القبول الدقيق.
        // يعاد تشغيلها في غلاف الرقعة 17 لتثبيت الصلة بالمجرى الحقيقي.
        var repaired=_previous.Patch(stream,familySize);
        if(repaired!=historical.Previous.Rank)
            throw new MonsterValidationException("اختلف شاهد رقعة الخانات السابقة.");
        return repaired;
    }
}

public sealed record PatchedInclusiveWideLimitCandidate(
    LegacyInclusiveWideLimitCandidate Historical,
    BigInteger Rank);

public sealed class PatchedInclusiveWideLimitPhaseHandler
{
    private readonly LegacyInclusiveWideLimitPhaseHandler _legacy=new();
    private readonly InclusiveWideLimitPatchWrapper _patch=new();

    public PatchedInclusiveWideLimitCandidate Handle(MonsterContext context)
    {
        if(context is null ||
           context.LegacyWideFamilySize is not BigInteger n ||
           n<=((BigInteger.One<<127)-BigInteger.One) ||
           context.LegacyAnswerStepIndex is not BigInteger k || !k.IsZero ||
           context.LegacyQueriedBowlId is not int id || id is < 1 or > 6 ||
           context.LegacyBowlQuestionSeal is not int seal || seal is not (21 or 31) ||
           context.PatchedInclusiveWideLimitRankResult.HasValue ||
           context.LegacyInclusiveWideLimitRankResult.HasValue ||
           context.PatchedWideRankResult.HasValue ||
           context.LegacyReversedWideRankResult.HasValue ||
           context.PatchedAnswerAtResult.HasValue ||
           context.PatchedBowlQuestionResult is not null ||
           context.PatchedSauceFinalBowls is not null ||
           context.PatchedVisibleDrops is not null)
            throw new MonsterValidationException("سياق رقعة الحدّ الواسع غير مؤسس أو مستعمل.");

        var historical=_legacy.Handle(context);
        return new PatchedInclusiveWideLimitCandidate(historical,
                   _patch.Patch(historical,n));
    }
}
