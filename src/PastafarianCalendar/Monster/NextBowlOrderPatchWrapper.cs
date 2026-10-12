namespace PastafarianCalendar.Monster;

// رقعة الجار الثانية عشرة: الهوية التالية في دورة ترتيب القطرة 46 المحمي، لا رقم الهوية التالي.
public sealed class NextBowlOrderPatchWrapper
{
    public int Patch(int[] orderAtDrop46, int queriedBowlId)
    {
        if (queriedBowlId is < 1 or > 6 ||
            orderAtDrop46 is null || orderAtDrop46.Length != 6 ||
            !orderAtDrop46.OrderBy(x => x).SequenceEqual(new[]{1,2,3,4,5,6}))
            throw new MonsterValidationException("سؤال الوعاء أو ترتيب القطرة الأخيرة غير صحيح.");

        var position = Array.IndexOf(orderAtDrop46, queriedBowlId);
        if (position < 0)
            throw new MonsterValidationException("الوعاء غير موجود في ترتيب السؤال.");
        return orderAtDrop46[(position + 1) % 6];
    }
}

public sealed record PatchedNextBowlCandidate(
    LegacyFixedNextBowlCandidate Historical,
    int NextBowlId);

public sealed class PatchedNextBowlPhaseHandler
{
    private readonly LegacyFixedNextBowlPhaseHandler _old = new();
    private readonly NextBowlOrderPatchWrapper _patch = new();

    public PatchedNextBowlCandidate Handle(MonsterContext context)
    {
        if (context is null || context.PatchedNextBowlResult.HasValue ||
            context.LegacyFixedNextBowlResult.HasValue ||
            context.LegacyQueriedBowlId is not int id || id is < 1 or > 6 ||
            context.PatchedSauceFinalBowls is not null ||
            context.PatchedVisibleDrops is not null)
            throw new MonsterValidationException("سياق رقعة الجار مشغول أو غير مهيأ.");

        // استدعاء التاريخ الحقيقي واجب، حتى لو اتفقت هويته الثابتة مصادفةً.
        var historical = _old.Handle(context);
        var corrected = _patch.Patch(historical.Sauce.Patched.OrderAt46Latch, id);
        return new PatchedNextBowlCandidate(historical, corrected);
    }
}
