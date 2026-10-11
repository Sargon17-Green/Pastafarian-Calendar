using System.Numerics;
using PastafarianCalendar.Monster;
using PastafarianCalendar.Stage01Tests.Normative;

namespace PastafarianCalendar.Stage03Tests;

internal static class Program
{
    private static int _passed;
    private static int _failed;

    private static void Check(bool condition, string label)
    {
        if (condition)
        {
            _passed++;
            return;
        }
        _failed++;
        Console.WriteLine("فشل: " + label);
    }

    private static void TestValue(BigInteger value, string name)
    {
        var oracle = NormativeScroll.Save(value);
        var actual = CalendarDateSpaghetti.EvaluateSave(
            NormativeScroll.FoundationDay, NormativeScroll.FoundationDay + 1, value);
        Check(oracle == actual, name + ": مطابق للمرجع");
        Check(actual >= 1 && actual <= NormativeScroll.M, name + ": داخل المجال");

        var legacy = CalendarDateSpaghetti.EvaluateLegacySave(
            NormativeScroll.FoundationDay, NormativeScroll.FoundationDay + 1, value);
        var legacyMustDiffer = value % NormativeScroll.M == BigInteger.Zero;
        Check((legacy != actual) == legacyMustDiffer, name + ": ندبة المسار القديم");
        Check(legacy == (legacyMustDiffer ? BigInteger.Zero : actual),
            name + ": لم يتغير السلوك القديم");
    }

    private static void TestBoundaries()
    {
        TestValue(BigInteger.One, "الواحد");
        TestValue(NormativeScroll.M - 1, "قبل المنتهى");
        TestValue(NormativeScroll.M, "المنتهى");
        TestValue(NormativeScroll.M + 1, "بعد المنتهى");
        TestValue(2 * NormativeScroll.M, "ضعف المنتهى");
        TestValue(3 * NormativeScroll.M, "ثلاثة أمثال المنتهى");
        TestValue(BigInteger.Zero, "الصفر");
        TestValue(-NormativeScroll.M, "سالب المنتهى");
        TestValue(-BigInteger.One, "سالب الواحد");

        var probes = 0;
        for (var factor = -12; factor <= 12; factor++)
        {
            for (var displacement = -3; displacement <= 3; displacement++)
            {
                TestValue(factor * NormativeScroll.M + displacement, "شبكة " + factor + "/" + displacement);
                probes++;
            }
        }

        var huge = BigInteger.One << 1024;
        var extreme = new[]
        {
            huge, -huge, huge + NormativeScroll.M, -huge - NormativeScroll.M,
            huge * NormativeScroll.M, -(huge * NormativeScroll.M),
            huge * NormativeScroll.M + BigInteger.One,
            -(huge * NormativeScroll.M) - BigInteger.One,
            (BigInteger.One << 4096) * NormativeScroll.M,
            -((BigInteger.One << 4096) * NormativeScroll.M)
        };
        foreach (var value in extreme)
        {
            TestValue(value, "عدد طويل " + probes);
            probes++;
        }

        Console.WriteLine("حالات شبكة الحدود والمدخلات الطويلة: " + probes);
    }

    private static void TestOwnershipAndDispatch()
    {
        var manager = new MonsterManager();
        var first = manager.ExecuteSavePatched(BigInteger.Zero, BigInteger.One, NormativeScroll.M);
        var second = manager.ExecuteSavePatched(BigInteger.One, BigInteger.Zero, NormativeScroll.M + 1);

        Check(!ReferenceEquals(first, second), "السياقان مستقلان");
        Check(!ReferenceEquals(first.Metrics, second.Metrics), "قياسات مستقلة");
        Check(!ReferenceEquals(first.BranchTrace, second.BranchTrace), "أثر منفصل");
        Check(first.LegacySaveResult == 0 && first.PatchedSaveResult == NormativeScroll.M,
            "حُفظت الندبة والمخرج المصحح في السياق الأول");
        Check(second.LegacySaveResult == 1 && second.PatchedSaveResult == 1,
            "لم تتغير القيمة العادية في السياق الثاني");
        Check(first.Status == "SAVE_PATCH_COMPLETE" && second.Status == "SAVE_PATCH_COMPLETE",
            "اكتمال المسار المصحح");
        Check(first.Phase == "SAVE_PATCH_COMPLETE" && second.Phase == "SAVE_PATCH_COMPLETE",
            "مرحلة الحفظ المصحح");
        Check(first.BranchTrace.SequenceEqual(
            new[] { "BOOTSTRAP_VALIDATION", "LEGACY_SAVE", "SAVE_PATCH" }),
            "المسار القديم يعمل قبل الرقعة");
        Check(first.Metrics.TryGetValue("bootstrap.dispatch", out var bootstrap) && bootstrap == 1,
            "قياس التأسيس");
        Check(first.Metrics.TryGetValue("legacy.save.dispatch", out var legacy) && legacy == 1,
            "قياس المسار القديم");
        Check(first.Metrics.TryGetValue("save.patch.dispatch", out var patched) && patched == 1,
            "قياس الرقعة");

        var dispatcher = new MonsterDispatcher(new MonsterValidationManager(), new MonsterMetricsManager());
        var priorResult = first.PatchedSaveResult;
        var priorTrace = first.BranchTrace.ToArray();
        var priorMetric = first.Metrics["save.patch.dispatch"];
        var rejectedDuplicate = false;
        try { dispatcher.DispatchSavePatched(first); }
        catch (MonsterValidationException) { rejectedDuplicate = true; }
        Check(rejectedDuplicate, "رُفضت إعادة تنفيذ الرقعة");
        Check(first.PatchedSaveResult == priorResult
            && first.Metrics["save.patch.dispatch"] == priorMetric
            && first.BranchTrace.SequenceEqual(priorTrace),
            "لم يفسد الرفض النتيجة المكتملة");

        var missing = manager.Prepare(BigInteger.Zero, BigInteger.Zero);
        var rejectedMissing = false;
        try { dispatcher.DispatchSavePatched(missing); }
        catch (MonsterValidationException) { rejectedMissing = true; }
        Check(rejectedMissing, "رُفض إدخال الحفظ المفقود");
        Check(missing.Status == "BOOTSTRAP_READY" && missing.PatchedSaveResult is null,
            "لم يُثبت أي ناتج عند غياب الإدخال");
    }

    private static int Main()
    {
        Console.OutputEncoding = System.Text.Encoding.UTF8;
        TestBoundaries();
        TestOwnershipAndDispatch();

        Console.WriteLine("اختبارات الرقعة الناجحة: " + _passed);
        Console.WriteLine("اختبارات الرقعة الفاشلة: " + _failed);
        return _failed == 0 ? 0 : 1;
    }
}
