using System.Numerics;

namespace PastafarianCalendar.Monster;

// الندبة الثانية والعشرون: ترتيب الإخراج للرتبة النازلة معكوس.
// لا يتغير المصدر أو سياسة القبول أو نتيجة الرقعة الحادية والعشرين.
public sealed class LegacyDescendingRankMirror
{
    private static readonly BigInteger M=(BigInteger.One<<127)-BigInteger.One;

    public BigInteger Reflect(BigInteger correctRank,BigInteger familySize,int direction)
    {
        if(familySize<=M || correctRank<1 || correctRank>familySize ||
           direction is not (-1 or 1))
            throw new MonsterValidationException("رتبة أو اتجاه المرآة غير صالح.");
        return direction==-1?familySize+BigInteger.One-correctRank:correctRank;
    }
}

// اقرأ اتجاه سؤال الوعاء المختوم من مرشحه الحقيقي، لا من المرجع الاختباري.
public static class DescendingRankDirectionWitness
{
    public static int Read(PatchedWideSlotTruncationCandidate previous)
    {
        if(previous is null)
            throw new MonsterValidationException("مرشح السؤال المختوم مفقود.");
        var stage42=previous.Historical;
        var stage41=stage42.Previous;
        var stage40=stage41.Historical;
        var stage39=stage40.Previous;
        var stage38=stage39.Historical;
        var stage37=stage38.Previous;
        var stage36=stage37.Historical;
        var stage35=stage36.Previous;
        var stage34=stage35.Historical;
        var stage33=stage34.Previous;
        var stage32=stage33.Historical;
        var direction=stage32.Step.Historical.Question.Answer.DirectionStep;
        if(direction is not (-1 or 1))
            throw new MonsterValidationException("اتجاه السؤال المختوم غير صالح.");
        return direction;
    }
}

public sealed record LegacyDescendingRankMirrorCandidate(
    PatchedWideSlotTruncationCandidate Previous,BigInteger Rank,int Direction);

public sealed class LegacyDescendingRankMirrorPhaseHandler
{
    private static readonly BigInteger M=(BigInteger.One<<127)-BigInteger.One;
    private readonly PatchedWideSlotTruncationPhaseHandler _previous=new();
    private readonly LegacyDescendingRankMirror _old=new();

    public LegacyDescendingRankMirrorCandidate Handle(MonsterContext context)
    {
        if(context is null ||
           context.LegacyWideFamilySize is not BigInteger n || n<=M ||
           context.LegacyAnswerStepIndex is not BigInteger k || !k.IsZero ||
           context.LegacyQueriedBowlId is not int id || id is <1 or >6 ||
           context.LegacyBowlQuestionSeal is not int seal || seal is not (21 or 31) ||
           context.LegacyDescendingRankMirrorResult.HasValue ||
           context.PatchedWideSlotTruncationRankResult.HasValue ||
           context.LegacyWideSlotTruncationRankResult.HasValue ||
           context.PatchedUpperPlaceBiasRankResult.HasValue ||
           context.PatchedSauceFinalBowls is not null ||
           context.PatchedVisibleDrops is not null)
            throw new MonsterValidationException("سياق مرآة السؤال النازل ناقص أو مستعمل.");
        var previous=_previous.Handle(context);
        var direction=DescendingRankDirectionWitness.Read(previous);
        return new LegacyDescendingRankMirrorCandidate(
            previous,_old.Reflect(previous.Rank,n,direction),direction);
    }
}
