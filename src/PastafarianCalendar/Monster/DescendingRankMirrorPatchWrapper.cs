using System.Numerics;

namespace PastafarianCalendar.Monster;

// الرقعة الثانية والعشرون: إزالة انعكاس إخراج الاتجاه النازل دون محو الشاهد.
public sealed class DescendingRankMirrorPatchWrapper
{
    private static readonly BigInteger M=(BigInteger.One<<127)-BigInteger.One;

    public BigInteger Unmirror(BigInteger historicalRank,BigInteger familySize,
                               int direction)
    {
        if(familySize<=M || historicalRank<1 || historicalRank>familySize ||
           direction is not (-1 or 1))
            throw new MonsterValidationException("معطيات إلغاء المرآة غير صالحة.");
        return direction==-1?familySize+BigInteger.One-historicalRank:historicalRank;
    }

    public BigInteger Patch(LegacyDescendingRankMirrorCandidate historical,
                            BigInteger familySize)
    {
        if(historical is null || historical.Previous is null)
            throw new MonsterValidationException("شاهد مرآة الاتجاه التاريخية مفقود.");
        if(DescendingRankDirectionWitness.Read(historical.Previous)!=historical.Direction)
            throw new MonsterValidationException("اتجاه المرآة لا يطابق السؤال المختوم.");
        var expectedOld=new LegacyDescendingRankMirror()
            .Reflect(historical.Previous.Rank,familySize,historical.Direction);
        if(expectedOld!=historical.Rank)
            throw new MonsterValidationException("شاهد المرآة القديمة لا يطابق الرتبة الصحيحة.");
        var restored=Unmirror(historical.Rank,familySize,historical.Direction);
        if(restored!=historical.Previous.Rank)
            throw new MonsterValidationException("المرتبة المصححة لا تطابق الرقعة الحادية والعشرين.");
        return restored;
    }
}

public sealed record PatchedDescendingRankMirrorCandidate(
    LegacyDescendingRankMirrorCandidate Historical,BigInteger Rank);

public sealed class PatchedDescendingRankMirrorPhaseHandler
{
    private static readonly BigInteger M=(BigInteger.One<<127)-BigInteger.One;
    private readonly LegacyDescendingRankMirrorPhaseHandler _previous=new();
    private readonly DescendingRankMirrorPatchWrapper _patch=new();

    public PatchedDescendingRankMirrorCandidate Handle(MonsterContext context)
    {
        if(context is null ||
           context.LegacyWideFamilySize is not BigInteger n || n<=M ||
           context.LegacyAnswerStepIndex is not BigInteger k || !k.IsZero ||
           context.LegacyQueriedBowlId is not int id || id is <1 or >6 ||
           context.LegacyBowlQuestionSeal is not int seal || seal is not (21 or 31) ||
           context.PatchedDescendingRankMirrorResult.HasValue ||
           context.LegacyDescendingRankMirrorResult.HasValue ||
           context.PatchedWideSlotTruncationRankResult.HasValue ||
           context.LegacyWideSlotTruncationRankResult.HasValue ||
           context.PatchedUpperPlaceBiasRankResult.HasValue ||
           context.PatchedSauceFinalBowls is not null ||
           context.PatchedVisibleDrops is not null)
            throw new MonsterValidationException("سياق الرقعة الثانية والعشرين ناقص أو مستعمل.");
        var historical=_previous.Handle(context);
        return new PatchedDescendingRankMirrorCandidate(
            historical,_patch.Patch(historical,n));
    }
}
