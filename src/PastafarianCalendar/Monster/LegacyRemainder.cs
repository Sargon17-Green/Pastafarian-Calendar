using System.Numerics;

namespace PastafarianCalendar.Monster;

public static class LegacyRemainder
{
    private static readonly BigInteger Modulus = (BigInteger.One << 127) - BigInteger.One;

    // يفترض المسار القديم أن الباقي الصفري صالحٌ نتيجةً نهائيةً لعملية الحفظ.
    // تُترك هذه الفرضية كما هي في طور الاكتشاف، ولو خالفت المرجع المعياري.
    public static BigInteger OldRemainder(BigInteger value)
    {
        var remainder = value % Modulus;
        return remainder.Sign < 0 ? remainder + Modulus : remainder;
    }
}

public sealed class LegacySavePhaseHandler
{
    public void Handle(MonsterContext context)
    {
        if (context.LegacySaveInput is not BigInteger input)
            throw new MonsterValidationException("لم تُقدَّم قيمة لمسار الحفظ القديم.");
        if (context.LegacySaveResult.HasValue)
            throw new MonsterValidationException("لا يجوز إلحاق نتيجة ثانية بالسياق نفسه.");

        var pending = LegacyRemainder.OldRemainder(input);
        context.LegacySaveResult = pending;
    }
}
