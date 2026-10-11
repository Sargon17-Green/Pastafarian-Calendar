using System.Numerics;

namespace PastafarianCalendar.Monster;

public sealed class StonePatchWrapper
{
    private readonly SavePatchWrapper _save = new();

    // تبقى الطفرة القديمة عملاً فعلياً؛ تُجرى على نسخة خاصة ثم تُستبدل نتائجها الخمس.
    // لا تقرأ الصيغ المصححة إلا الصورة القديمة المتجمدة قبل دورة التحديث.
    public BigInteger[] StonePatch(int row, BigInteger[] stones)
    {
        if (row < 2 || row > 46)
            throw new MonsterValidationException("رقم صف الرقعة الرابعة خارج المدى المحدد.");
        if (stones is null || stones.Length != 6)
            throw new MonsterValidationException("تتطلب رقعة الأحجار خمس قيم وفهرس الصفر.");

        var old = (BigInteger[])stones.Clone();
        var garbage = LegacyStones.MutateStonesWrong(row, (BigInteger[])stones.Clone());

        garbage[1] = _save.SavePatch(old[1] * old[1] + 3 * old[2] + row);
        garbage[2] = _save.SavePatch(old[2] * old[2] + 5 * old[3] + old[1]);
        garbage[3] = _save.SavePatch(old[3] * old[3] + 7 * old[4] + old[2]);
        garbage[4] = _save.SavePatch(old[4] * old[4] + 11 * old[5] + old[3]);
        garbage[5] = _save.SavePatch(old[5] * old[5] + 13 * old[1] + old[4]);

        return garbage;
    }

    // تُخزَّن صورة مستقلة لكل صف كي لا تنفذ الكتابة اللاحقة إلى الصف السابق.
    public BigInteger[][] BuildPatchedRows()
    {
        var rows = new BigInteger[47][];
        var current = LegacyStones.InitialStones();
        rows[1] = (BigInteger[])current.Clone();

        for (var row = 2; row <= 46; row++)
        {
            current = StonePatch(row, current);
            rows[row] = (BigInteger[])current.Clone();
        }

        return rows;
    }
}
