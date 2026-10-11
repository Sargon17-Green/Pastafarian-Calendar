using System.Numerics;

namespace PastafarianCalendar.Monster;

public static class LegacyStones
{
    private const int LastRow = 46;

    // الصف الأول ثابت، ولا يعتمد على الاستدعاء أو ذاكرة مشتركة بين السياقات.
    public static BigInteger[] InitialStones()
        => new BigInteger[] { BigInteger.Zero, 17, 29, 43, 71, 101 };

    // يُحدِّث المسار التاريخي الأحجار الخمسة في موضعها وبالترتيب.
    // يقرأ كل حجر متأخر القيم التي تغيّرت قبله في الدورة نفسها؛ وهذا هو الخلل المقصود.
    public static BigInteger[] MutateStonesWrong(int row, BigInteger[] stones)
    {
        if (row < 2 || row > LastRow)
            throw new MonsterValidationException("رقم دورة الأحجار القديمة خارج مجال الصفوف الثاني إلى السادس والأربعين.");
        if (stones is null || stones.Length != 6)
            throw new MonsterValidationException("يلزم مصفوفة من ست خانات للأحجار الخمسة وفهرس الصفر.");

        var save = new SavePatchWrapper();

        stones[1] = save.SavePatch(stones[1] * stones[1] + 3 * stones[2] + row);
        stones[2] = save.SavePatch(stones[2] * stones[2] + 5 * stones[3] + stones[1]);
        stones[3] = save.SavePatch(stones[3] * stones[3] + 7 * stones[4] + stones[2]);
        stones[4] = save.SavePatch(stones[4] * stones[4] + 11 * stones[5] + stones[3]);
        stones[5] = save.SavePatch(stones[5] * stones[5] + 13 * stones[1] + stones[4]);

        return stones;
    }

    // تُحفظ نسخة كل صف بعد وقوع التحوّل القديم؛ فلا تتبدل الصفوف المحفوظة لاحقاً.
    public static BigInteger[][] BuildWrongRows()
    {
        var rows = new BigInteger[LastRow + 1][];
        var current = InitialStones();
        rows[1] = (BigInteger[])current.Clone();
        for (var row = 2; row <= LastRow; row++)
        {
            MutateStonesWrong(row, current);
            rows[row] = (BigInteger[])current.Clone();
        }
        return rows;
    }
}

public sealed class LegacyStonesPhaseHandler
{
    public void Handle(MonsterContext context)
    {
        if (context.LegacyStoneRows is not null)
            throw new MonsterValidationException("لا يجوز بناء سلسلة الأحجار القديمة مرتين في السياق نفسه.");

        var pending = LegacyStones.BuildWrongRows();
        context.LegacyStoneRows = pending;
    }
}
