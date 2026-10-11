using System.Numerics;
using PastafarianCalendar.Monster;
using PastafarianCalendar.Stage01Tests.Normative;

namespace PastafarianCalendar.Stage04Tests;

internal static class Program
{
    private static int _matching;
    private static int _diverging;
    private static int _unexpected;
    private static int _checked;

    private static void Check(BigInteger offset, string label)
    {
        var day = NormativeScroll.FoundationDay + offset;
        var expected = NormativeScroll.DayCount(day);
        var actual = CalendarDateSpaghetti.EvaluateLegacyDayTag(
            NormativeScroll.FoundationDay, NormativeScroll.FoundationDay, day);

        _checked++;
        var differs = expected != actual;
        if (differs) _diverging++; else _matching++;

        // النسخة القديمة تساوي المرجع قبل التأسيس، وتقلّ بوحدة واحدة عنده وبعده.
        var expectedDifference = offset.Sign >= 0;
        var exactDifference = expectedDifference
            ? expected == actual + BigInteger.One
            : expected == actual;
        var nonnegative = actual.Sign >= 0;
        if (differs != expectedDifference || !exactDifference || !nonnegative)
        {
            _unexpected++;
            Console.WriteLine("فرق غير متوقع: " + label
                + " | اليوم=" + day
                + " | المرجع=" + expected
                + " | القديم=" + actual);
        }
        else
        {
            Console.WriteLine((differs ? "اختلاف تاريخي مثبت: " : "تطابق: ")
                + label + " | المرجع=" + expected + " | القديم=" + actual);
        }
    }

    private static void Require(bool condition, string name)
    {
        if (!condition)
        {
            _unexpected++;
            Console.WriteLine("فشل ضمان السياق: " + name);
        }
    }

    private static void VerifyContextIsolation()
    {
        var manager = new MonsterManager();
        var foundation = manager.ExecuteLegacyDayTag(BigInteger.Zero, BigInteger.One,
            NormativeScroll.FoundationDay);
        var before = manager.ExecuteLegacyDayTag(BigInteger.One, BigInteger.Zero,
            NormativeScroll.FoundationDay - 1);

        Require(!ReferenceEquals(foundation, before), "استقلال السياق");
        Require(!ReferenceEquals(foundation.BranchTrace, before.BranchTrace), "استقلال سجل المسار");
        Require(!ReferenceEquals(foundation.Metrics, before.Metrics), "استقلال القياسات");
        Require(foundation.LegacyDayTagResult == 0, "جرح يوم التأسيس");
        Require(before.LegacyDayTagResult == 2, "صحة اليوم السابق للتأسيس");
        Require(foundation.Status == "LEGACY_DAY_TAG_COMPLETE"
            && foundation.Phase == "LEGACY_DAY_TAG_COMPLETE", "حالة التنفيذ التاريخي");
        Require(foundation.BranchTrace.SequenceEqual(
            new[] { "BOOTSTRAP_VALIDATION", "LEGACY_DAY_TAG" }), "مسار المعالج القديم");
        Require(foundation.Metrics.TryGetValue("legacy.day.tag.dispatch", out var n) && n == 1,
            "قياس المعالج القديم");
        Require(foundation.PatchedSaveResult is null
            && foundation.LegacySaveResult is null, "لا تداخل مع رقعة الحفظ السابقة");

        var dispatcher = new MonsterDispatcher(new MonsterValidationManager(),
            new MonsterMetricsManager());
        var previous = foundation.LegacyDayTagResult;
        var trace = foundation.BranchTrace.ToArray();
        var duplicateRejected = false;
        try { dispatcher.DispatchLegacyDayTag(foundation); }
        catch (MonsterValidationException) { duplicateRejected = true; }
        Require(duplicateRejected, "منع التنفيذ مرتين");
        Require(foundation.LegacyDayTagResult == previous
            && foundation.BranchTrace.SequenceEqual(trace), "الرفض لا يغيّر نتيجة سابقة");

        var missing = manager.Prepare(BigInteger.Zero, BigInteger.Zero);
        var missingRejected = false;
        try { dispatcher.DispatchLegacyDayTag(missing); }
        catch (MonsterValidationException) { missingRejected = true; }
        Require(missingRejected, "رفض غياب المدخل");
        Require(missing.Status == "BOOTSTRAP_READY"
            && missing.LegacyDayTagResult is null
            && missing.BranchTrace.SequenceEqual(new[] { "BOOTSTRAP_VALIDATION" }),
            "لا أثر دلالياً عند الرفض");
    }

    private static int Main(string[] args)
    {
        Console.OutputEncoding = System.Text.Encoding.UTF8;
        var verifyExpectedRed = args.Length == 1 && args[0] == "--verify-expected-red";
        if (args.Length > 0 && !verifyExpectedRed)
        {
            Console.Error.WriteLine("وسيط تشغيل مجهول.");
            return 2;
        }

        for (var displacement = -128; displacement <= 128; displacement++)
            Check(new BigInteger(displacement), "شبكة التأسيس " + displacement);

        var huge = BigInteger.One << 4096;
        var otherOffsets = new[]
        {
            -huge, huge, -huge + 1, huge + 1, -huge - 1, huge - 1,
            new BigInteger(-1000000), new BigInteger(1000000),
            new BigInteger(-129), new BigInteger(129),
            new BigInteger(-1000000000), new BigInteger(1000000000)
        };
        foreach (var offset in otherOffsets)
            Check(offset, "يوم بعيد بإزاحة " + offset);

        if (verifyExpectedRed) VerifyContextIsolation();

        Console.WriteLine("الحالات المفحوصة: " + _checked);
        Console.WriteLine("حالات المطابقة: " + _matching);
        Console.WriteLine("حالات الاختلاف: " + _diverging);
        Console.WriteLine("مخالفات التوقيع أو السياق: " + _unexpected);

        if (verifyExpectedRed)
        {
            if (_checked == 269 && _matching == 134 && _diverging == 135 && _unexpected == 0)
            {
                Console.WriteLine("توقيع الاكتشاف الثاني: PASS؛ بقيت حالات الاختلاف حمراء عمداً.");
                return 0;
            }
            Console.WriteLine("توقيع الاكتشاف الثاني: FAIL");
            return 1;
        }

        return _unexpected == 0 && _diverging == 0 ? 0 : 1;
    }
}
