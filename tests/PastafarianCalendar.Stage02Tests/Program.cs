using System.Numerics;
using PastafarianCalendar.Monster;
using PastafarianCalendar.Stage01Tests.Normative;

namespace PastafarianCalendar.Stage02Tests;

internal static class Program
{
    private sealed record Case(BigInteger Input, string Name, bool ExpectedDivergence);

    private static readonly Case[] Cases =
    {
        new(BigInteger.One, "حفظ الواحد", false),
        new(NormativeScroll.M - 1, "قبل المنتهى", false),
        new(NormativeScroll.M, "المنتهى", true),
        new(2 * NormativeScroll.M, "ضعف المنتهى", true),
        new(3 * NormativeScroll.M, "ثلاثة أمثال المنتهى", true),
        new(NormativeScroll.M + 1, "بعد المنتهى", false),
        new(BigInteger.Zero, "الصفر", true),
        new(-NormativeScroll.M, "سالب المنتهى", true),
        new(-BigInteger.One, "سالب الواحد", false)
    };

    private static int Main(string[] args)
    {
        Console.OutputEncoding = System.Text.Encoding.UTF8;
        var verifyExpectedRed = args.Length == 1 && args[0] == "--verify-expected-red";
        if (args.Length > 0 && !verifyExpectedRed)
        {
            Console.Error.WriteLine("وسيط تشغيل غير معروف.");
            return 2;
        }

        var matches = 0;
        var divergences = 0;
        var unexpected = 0;

        foreach (var item in Cases)
        {
            var expected = NormativeScroll.Save(item.Input);
            var actual = CalendarDateSpaghetti.EvaluateLegacySave(
                NormativeScroll.FoundationDay,
                NormativeScroll.FoundationDay,
                item.Input);

            var differs = expected != actual;
            if (differs) divergences++; else matches++;

            var correctClassification = differs == item.ExpectedDivergence;
            var correctSignature = !differs || (expected == NormativeScroll.M && actual.IsZero);
            if (verifyExpectedRed && (!correctClassification || !correctSignature))
                unexpected++;

            Console.WriteLine(
                (differs ? "فشل متوقع في الاكتشاف: " : "نجح: ")
                + item.Name
                + " | المرجع=" + expected
                + " | المسار القديم=" + actual);

            if (verifyExpectedRed && (!correctClassification || !correctSignature))
                Console.WriteLine("انحراف غير متوقع عن توقيع الاكتشاف: " + item.Name);
        }

        Console.WriteLine("التطابقات: " + matches);
        Console.WriteLine("الاختلافات: " + divergences);
        Console.WriteLine("الاختلافات غير المتوقعة: " + unexpected);

        if (verifyExpectedRed)
        {
            if (matches == 4 && divergences == 5 && unexpected == 0)
            {
                Console.WriteLine("تحقق توقيع الاكتشاف: PASS; الاختبار الاعتيادي يظل أحمر.");
                return 0;
            }

            Console.WriteLine("تحقق توقيع الاكتشاف: FAIL");
            return 1;
        }

        return divergences == 0 ? 0 : 1;
    }
}
