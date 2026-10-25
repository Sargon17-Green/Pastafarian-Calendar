using System.Numerics;

namespace PastafarianCalendar.Monster;

// الندبة الثالثة والعشرون: يخلط إخراج الأسرة الواسعة بين آخر رتبة
// مقبولة وبين الحارس الذي يدل على بداية مجال جديد.
// لا تُمس رتبة الرقعة الثانية والعشرين أو سياسة القبول والرفض.
public sealed class LegacyWideTerminalSentinel
{
    private static readonly BigInteger M=(BigInteger.One<<127)-BigInteger.One;

    public BigInteger Collapse(BigInteger rank,BigInteger familySize)
    {
        if(familySize<=M || rank<1 || rank>familySize)
            throw new MonsterValidationException("رتبة أو عائلة الحارس النهائي غير صالحة.");
        return rank==familySize?BigInteger.One:rank;
    }
}

public sealed record LegacyWideTerminalSentinelCandidate(
    PatchedDescendingRankMirrorCandidate Previous,BigInteger Rank);

public sealed class LegacyWideTerminalSentinelPhaseHandler
{
    private static readonly BigInteger M=(BigInteger.One<<127)-BigInteger.One;
    private readonly PatchedDescendingRankMirrorPhaseHandler _previous=new();
    private readonly LegacyWideTerminalSentinel _old=new();

    public LegacyWideTerminalSentinelCandidate Handle(MonsterContext context)
    {
        if(context is null ||
           context.LegacyWideFamilySize is not BigInteger n || n<=M ||
           context.LegacyAnswerStepIndex is not BigInteger k || !k.IsZero ||
           context.LegacyQueriedBowlId is not int id || id is <1 or >6 ||
           context.LegacyBowlQuestionSeal is not int seal || seal is not (21 or 31) ||
           context.LegacyWideTerminalSentinelRankResult.HasValue ||
           context.PatchedDescendingRankMirrorResult.HasValue ||
           context.LegacyDescendingRankMirrorResult.HasValue ||
           context.PatchedWideSlotTruncationRankResult.HasValue ||
           context.PatchedSauceFinalBowls is not null ||
           context.PatchedVisibleDrops is not null)
            throw new MonsterValidationException("سياق اكتشاف حارس الرتبة النهائية ناقص أو مستعمل.");
        var previous=_previous.Handle(context);
        return new LegacyWideTerminalSentinelCandidate(
            previous,_old.Collapse(previous.Rank,n));
    }
}
