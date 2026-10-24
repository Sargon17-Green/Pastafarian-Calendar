using System.Numerics;

namespace PastafarianCalendar.Monster;

// لا يمكن عكس فقدان الخانات من الشاهد المقطوع وحده.
// تؤخذ الرتبة الكاملة من الرقعة العشرين بعد تدقيق القطع التاريخي.
public sealed class WideSlotTruncationPatchWrapper
{
    private static readonly BigInteger M=(BigInteger.One<<127)-BigInteger.One;

    public BigInteger Restore(BigInteger historicalRank,BigInteger previousRank,
                              BigInteger familySize)
    {
        if(familySize<=M || previousRank<1 || previousRank>familySize ||
           historicalRank<1 || historicalRank>M)
            throw new MonsterValidationException("مدخل استرجاع المرتبة المقطوعة غير صالح.");
        if(new LegacyWideSlotTruncation().Fold(previousRank,familySize)!=historicalRank)
            throw new MonsterValidationException("شاهد القطع لا يطابق رتبة الرقعة العشرين.");
        return previousRank;
    }

    public BigInteger Patch(LegacyWideSlotTruncationCandidate historical,
                            BigInteger familySize)
    {
        if(historical is null || historical.Previous is null)
            throw new MonsterValidationException("شاهد القطع التاريخي مفقود.");
        return Restore(historical.Rank,historical.Previous.Rank,familySize);
    }
}

public sealed record PatchedWideSlotTruncationCandidate(
    LegacyWideSlotTruncationCandidate Historical,BigInteger Rank);

public sealed class PatchedWideSlotTruncationPhaseHandler
{
    private static readonly BigInteger M=(BigInteger.One<<127)-BigInteger.One;
    private readonly LegacyWideSlotTruncationPhaseHandler _old=new();
    private readonly WideSlotTruncationPatchWrapper _patch=new();

    public PatchedWideSlotTruncationCandidate Handle(MonsterContext context)
    {
        if(context is null ||
           context.LegacyWideFamilySize is not BigInteger n || n<=M ||
           context.LegacyAnswerStepIndex is not BigInteger k || !k.IsZero ||
           context.LegacyQueriedBowlId is not int id || id is <1 or >6 ||
           context.LegacyBowlQuestionSeal is not int seal || seal is not (21 or 31) ||
           context.PatchedWideSlotTruncationRankResult.HasValue ||
           context.LegacyWideSlotTruncationRankResult.HasValue ||
           context.PatchedUpperPlaceBiasRankResult.HasValue ||
           context.LegacyUpperPlaceBiasRankResult.HasValue ||
           context.PatchedDoubleOffsetWideRankResult.HasValue ||
           context.PatchedSauceFinalBowls is not null ||
           context.PatchedVisibleDrops is not null)
            throw new MonsterValidationException("سياق الرقعة الحادية والعشرين ناقص أو مستعمل.");
        var old=_old.Handle(context);
        return new PatchedWideSlotTruncationCandidate(old,_patch.Patch(old,n));
    }
}
