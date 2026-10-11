using System.Numerics;
using PastafarianCalendar.Monster;
using PastafarianCalendar.Stage01Tests.Normative;

namespace PastafarianCalendar.Stage02Tests;

internal static class Program
{
    private static int _passed;
    private static int _failed;

    private static void Check(BigInteger input, string name)
    {
        var expected = NormativeScroll.Save(input);
        var actual = CalendarDateSpaghetti.EvaluateLegacySave(
            NormativeScroll.FoundationDay,
            NormativeScroll.FoundationDay,
            input);

        if (actual == expected)
        {
            _passed++;
            Console.WriteLine("نجح: " + name);
        }
        else
        {
            _failed++;
            Console.WriteLine(
                "فشل متوقع في الاكتشاف: " + name
                + " | المرجع=" + expected
                + " | المسار القديم=" + actual);
        }
    }

    private static int Main()
    {
        Console.OutputEncoding = System.Text.Encoding.UTF8;

        // اختبارات الضبط تمر، بينما تكشف مضاعفات المنتهى عن الباقي الصفري.
        Check(BigInteger.One, "حفظ الواحد");
        Check(NormativeScroll.M - 1, "قبل المنتهى");
        Check(NormativeScroll.M, "المنتهى");
        Check(2 * NormativeScroll.M, "ضعف المنتهى");
        Check(3 * NormativeScroll.M, "ثلاثة أمثال المنتهى");
        Check(NormativeScroll.M + 1, "بعد المنتهى");
        Check(BigInteger.Zero, "الصفر");
        Check(-NormativeScroll.M, "سالب المنتهى");
        Check(-BigInteger.One, "سالب الواحد");

        Console.WriteLine("الاختبارات الناجحة: " + _passed);
        Console.WriteLine("الاختبارات الفاشلة: " + _failed);
        return _failed == 0 ? 0 : 1;
    }
}
