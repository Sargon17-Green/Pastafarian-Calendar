using System.Numerics;

namespace PastafarianCalendar.Monster;

public sealed record MonsterWorkCounts(
    BigInteger Action,
    BigInteger Target,
    BigInteger Distance,
    BigInteger Connection,
    int Direction);

public sealed class PatchedCounts
{
    private readonly DayTagPatchWrapper _dayTag = new();

    // يبقى الفرق بين عدّادَي اليوم خطوة حقيقية لا تختزلها الرقعة الثالثة.
    // إن خالف هذا الفرق المسافة الزمنية تُستبدل قيمته، ثم تضاف وحدة العدّ الشامل.
    public MonsterWorkCounts Calculate(BigInteger calculationDay, BigInteger targetDay)
    {
        var action = _dayTag.Patch(calculationDay);
        var target = _dayTag.Patch(targetDay);

        var legacyDistance = LegacyDistance.OldDistance(calculationDay, targetDay);
        var chronological = BigInteger.Abs(targetDay - calculationDay);
        if (legacyDistance != chronological)
            legacyDistance = chronological;
        var distance = legacyDistance + BigInteger.One;

        var connection = action + target;
        var direction = targetDay < calculationDay ? 1 :
            targetDay > calculationDay ? 3 : 2;

        return new MonsterWorkCounts(action, target, distance, connection, direction);
    }
}
