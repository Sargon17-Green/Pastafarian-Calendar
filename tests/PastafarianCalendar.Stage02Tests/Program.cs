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

    private static int Require(bool condition, string name)
    {
        if (condition) return 0;
        Console.WriteLine("فشل تحقق إضافي: " + name);
        return 1;
    }

    // شبكة حسابية ثابتة لا تستعمل العشوائية ولا تغيّر توقيع الاختبار الأحمر الأصلي.
    private static int VerifyWideBoundaryMesh()
    {
        var failures = 0;
        var probes = 0;
        var huge = BigInteger.Pow(new BigInteger(2), 1024);
        var additional = new[]
        {
            huge, huge + NormativeScroll.M, -huge,
            -huge - NormativeScroll.M, huge * NormativeScroll.M,
            -huge * NormativeScroll.M,
            huge * NormativeScroll.M + 1, -huge * NormativeScroll.M - 1
        };

        void Probe(BigInteger value)
        {
            probes++;
            var expected = NormativeScroll.Save(value);
            var actual = CalendarDateSpaghetti.EvaluateLegacySave(
                NormativeScroll.FoundationDay,
                NormativeScroll.FoundationDay + 1,
                value);
            var divisible = value % NormativeScroll.M == BigInteger.Zero;
            var correct = divisible
                ? expected == NormativeScroll.M && actual.IsZero
                : expected == actual;
            correct &= actual >= 0 && actual < NormativeScroll.M;
            correct &= expected >= 1 && expected <= NormativeScroll.M;
            if (!correct)
            {
                failures++;
                Console.WriteLine("فشل في شبكة الحدود عند " + value);
            }
        }

        for (var multiplier = -12; multiplier <= 12; multiplier++)
            for (var offset = -3; offset <= 3; offset++)
                Probe(multiplier * NormativeScroll.M + offset);

        foreach (var value in additional)
            Probe(value);

        Console.WriteLine("حالات شبكة الحدود المحققة: " + (probes - failures) + "/" + probes);
        return failures;
    }

    // يتحقق من ملكية السياق والقياسات الخاصة بكل استدعاء ومن منع الإرسال مرتين.
    private static int VerifyContextOwnership()
    {
        var manager = new MonsterManager();
        var first = manager.Prepare(NormativeScroll.FoundationDay, NormativeScroll.FoundationDay);
        var second = manager.Prepare(NormativeScroll.FoundationDay, NormativeScroll.FoundationDay + 1);
        var dispatcher = new MonsterDispatcher(new MonsterValidationManager(), new MonsterMetricsManager());

        var errors = 0;
        errors += Require(!ReferenceEquals(first, second), "استقلال السياقين");
        errors += Require(!ReferenceEquals(first.BranchTrace, second.BranchTrace), "استقلال سجل الفروع");
        errors += Require(!ReferenceEquals(first.Metrics, second.Metrics), "استقلال القياسات");

        first.LegacySaveInput = NormativeScroll.M;
        second.LegacySaveInput = NormativeScroll.M + 1;
        dispatcher.DispatchLegacySave(first);
        dispatcher.DispatchLegacySave(second);

        errors += Require(first.LegacySaveResult == 0, "نتيجة السياق الأول");
        errors += Require(second.LegacySaveResult == 1, "نتيجة السياق الثاني");
        errors += Require(first.Status == "LEGACY_SAVE_COMPLETE"
            && second.Status == "LEGACY_SAVE_COMPLETE", "اكتمال الحالتين");
        errors += Require(first.Metrics.TryGetValue("legacy.save.dispatch", out var a) && a == 1,
            "قياس الاستدعاء الأول");
        errors += Require(second.Metrics.TryGetValue("legacy.save.dispatch", out var b) && b == 1,
            "قياس الاستدعاء الثاني");
        errors += Require(first.BranchTrace.SequenceEqual(
            new[] { "BOOTSTRAP_VALIDATION", "LEGACY_SAVE" }), "أثر المسار الأول");
        errors += Require(second.BranchTrace.SequenceEqual(
            new[] { "BOOTSTRAP_VALIDATION", "LEGACY_SAVE" }), "أثر المسار الثاني");

        var duplicateRejected = false;
        try { dispatcher.DispatchLegacySave(first); }
        catch (MonsterValidationException) { duplicateRejected = true; }
        errors += Require(duplicateRejected, "رفض إعادة إرسال السياق المكتمل");

        var missing = manager.Prepare(BigInteger.Zero, BigInteger.Zero);
        var missingRejected = false;
        try { dispatcher.DispatchLegacySave(missing); }
        catch (MonsterValidationException) { missingRejected = true; }
        errors += Require(missingRejected, "رفض إدخال الحفظ المفقود");

        Console.WriteLine("أخطاء ملكية السياق: " + errors);
        return errors;
    }

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
            var additionalErrors = VerifyWideBoundaryMesh() + VerifyContextOwnership();
            if (matches == 4 && divergences == 5 && unexpected == 0 && additionalErrors == 0)
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
