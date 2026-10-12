namespace PastafarianCalendar.Monster;

// الندبة الثانية عشرة: تُفهم هوية الوعاء التالي على أنها هوية ثابتة,
// بدلاً من الموضع الذي يلي الوعاء في ترتيب القطرة 46 المحفوظ.
public sealed class LegacyFixedNextBowl
{
    public int SelectByFixedIdentity(int queriedBowlId)
    {
        if (queriedBowlId is < 1 or > 6)
            throw new MonsterValidationException("هوية الوعاء المطلوبة خارج المجال.");
        return queriedBowlId == 6 ? 1 : queriedBowlId + 1;
    }
}

public sealed record LegacyFixedNextBowlCandidate(
    ProtectedDrop46SauceCandidate Sauce,
    int QueriedBowlId,
    int LegacyNextBowlId);

// المسار التاريخي يستعمل الصلصة المحمية الحقيقية ولا يُصلح اختيار الوعاء التالي.
public sealed class LegacyFixedNextBowlPhaseHandler
{
    private readonly ProtectedDrop46SaucePhaseHandler _sauce = new();
    private readonly LegacyFixedNextBowl _old = new();

    public LegacyFixedNextBowlCandidate Handle(MonsterContext context)
    {
        if (context.LegacyQueriedBowlId is not int id || id is < 1 or > 6 ||
            context.LegacyFixedNextBowlResult.HasValue ||
            context.PatchedSauceFinalBowls is not null ||
            context.PatchedVisibleDrops is not null)
            throw new MonsterValidationException("سياق السؤال التاريخي ناقص أو مشغول.");

        var sauce = _sauce.Handle(context);
        return new LegacyFixedNextBowlCandidate(
            sauce, id, _old.SelectByFixedIdentity(id));
    }
}
