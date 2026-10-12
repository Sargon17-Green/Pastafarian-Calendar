using System.Numerics;

namespace PastafarianCalendar.Monster;

public static class LegacyBowlPermutation
{
    // هذه الدالة التاريخية صحيحة لدليل الرتبة الصفري 0..719 وحده.
    // لا تتولى تحويل قيمة القطرة من الرتبة الواحدية إلى الصفرية؛
    // إصلاح ذلك التحويل محظور إلى أن يحين موعد الرقعة الثامنة.
    public static int[] OldPermutationUnrank0(int rank0)
    {
        if (rank0 is < 0 or >= 720)
            throw new ArgumentOutOfRangeException(nameof(rank0),
                "رقم الترتيب الصفري التاريخي خارج المجال من الصفر إلى 719.");

        var available = new List<int> { 1, 2, 3, 4, 5, 6 };
        var pending = new int[6];
        var remaining = rank0;

        for (var position = 0; position < 6; position++)
        {
            var fact = 1;
            for (var factor = 2; factor <= 5 - position; factor++)
                fact *= factor;

            var index = remaining / fact;
            remaining %= fact;
            pending[position] = available[index];
            available.RemoveAt(index);
        }

        return pending;
    }

    // الافتراض الخاطئ: رتبة الترتيب المعطاة من القطرة تبدأ من الواحد،
    // ولكنها تُرسل كما هي إلى المفكك الصفري بلا طرح الواحد.
    public static int WrongOneBasedRank(BigInteger dropValue)
    {
        var remainder = (dropValue - BigInteger.One) % 720;
        if (remainder.Sign < 0) remainder += 720;
        return (int)remainder + 1;
    }
}

public sealed class LegacyBowlPermutationPhaseHandler
{
    public int[] Handle(MonsterContext context)
    {
        if (context.LegacyBowlOrderInput is not BigInteger drop)
            throw new MonsterValidationException("قيمة القطرة لترتيب الأوعية مفقودة.");
        if (context.LegacyBowlOrderResult is not null ||
            context.LegacyBowlOneBasedRank.HasValue)
            throw new MonsterValidationException("لا يُقرأ ترتيب الأوعية التاريخي مرتين.");

        var oneBased = LegacyBowlPermutation.WrongOneBasedRank(drop);
        // لا تُعدّل الرتبة هنا: القفزة الناقصة من الواحد إلى الصفر هي الندبة المقصودة.
        // في آخر رتبة (720) يُظهر المفكك استثناء المجال التاريخي بلا التزام.
        return LegacyBowlPermutation.OldPermutationUnrank0(oneBased);
    }
}
