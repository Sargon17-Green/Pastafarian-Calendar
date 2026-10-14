using System.Numerics;

namespace PastafarianCalendar.Monster;

// الرقعة الخامسة عشرة: تدوير الناتج الواحدي التاريخي إلى المرتبة الصحيحة.
// يتولى المسار القديم حد القبول، بما فيه تجاوز المنطقة المرفوضة.
public sealed class ShortRankOffsetPatchWrapper
{
    private static readonly BigInteger Modulus=(BigInteger.One<<127)-BigInteger.One;

    public BigInteger Patch(BigInteger historicalRank,BigInteger familySize)
    {
        if(familySize<1 || familySize>Modulus ||
           historicalRank<1 || historicalRank>familySize)
            throw new MonsterValidationException("مرتبة الأسرة القصيرة أو حجمها غير صالح.");

        // القديم = 1 + (x mod n)، بينما الصحيح = 1 + ((x-1) mod n).
        // بما أن القديم من 1 إلى n، فتدويره خطوة للخلف هو التصحيح الوحيد.
        return historicalRank==BigInteger.One ? familySize : historicalRank-BigInteger.One;
    }
}

public sealed record PatchedShortRankCandidate(
    LegacyUnshiftedShortRankCandidate Historical,
    BigInteger Rank);

public sealed class PatchedShortRankPhaseHandler
{
    private readonly LegacyUnshiftedShortRankPhaseHandler _legacy=new();
    private readonly ShortRankOffsetPatchWrapper _patch=new();

    public PatchedShortRankCandidate Handle(MonsterContext context)
    {
        if(context is null ||
           context.LegacyShortFamilySize is not BigInteger n || n<1 ||
           n>((BigInteger.One<<127)-BigInteger.One) ||
           context.LegacyAnswerStepIndex is not BigInteger k || !k.IsZero ||
           context.LegacyQueriedBowlId is not int id || id is < 1 or > 6 ||
           context.LegacyBowlQuestionSeal is not int seal || seal is not (21 or 31) ||
           context.PatchedShortFamilyRankResult.HasValue ||
           context.LegacyShortFamilyRankResult.HasValue ||
           context.PatchedAnswerAtResult.HasValue ||
           context.LegacyOneBasedAnswerAtResult.HasValue ||
           context.PatchedBowlQuestionResult is not null ||
           context.PatchedSauceFinalBowls is not null ||
           context.PatchedVisibleDrops is not null)
            throw new MonsterValidationException("سياق رقعة الأسرة القصيرة ناقص أو مستخدم.");

        // يُستدعى المعالج التاريخي فعلياً؛ لا يُعاد خلق نتيجته أو إخفاؤها.
        var old=_legacy.Handle(context);
        return new PatchedShortRankCandidate(old,_patch.Patch(old.Rank,n));
    }
}
