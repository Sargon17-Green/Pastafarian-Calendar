using System.Numerics;
using PastafarianCalendar.Monster;
using PastafarianCalendar.Stage01Tests.Normative;

namespace PastafarianCalendar.Stage11Tests;

internal static class Program
{
    private static int _passed;
    private static int _failed;
    private static int _verifiedDrops;
    private static int _verifiedCases;
    private static int _legacyDivergences;

    private static void Check(bool condition, string description)
    {
        if (condition) { _passed++; return; }
        _failed++;
        Console.WriteLine("فشل: " + description);
    }

    private static void VerifyPair(BigInteger c, BigInteger t, string label, bool facade)
    {
        _verifiedCases++;
        var norm = NormativeScroll.BuildHiddenDrops(NormativeScroll.WorkCountsFor(c, t));
        var manager = new MonsterManager();
        var context = manager.ExecutePatchedHiddenAccess(c, t);
        var legacy = context.LegacyHiddenReversed!;
        var patch = context.PatchedHiddenAccess!;

        Check(legacy.Length == 8 && legacy[0] == BigInteger.Zero, label + ": بنية المخزن");
        Check(patch is not null, label + ": وجود غلاف الفهرسة");
        Check(context.PatchedStoneRows is null && context.PatchedCountsResult is null &&
            context.LegacyStoneRows is null, label + ": عدم تسرب حالة الأطوار السابقة");
        Check(context.Status == "HIDDEN_INDEX_PATCH_COMPLETE" &&
            context.Phase == "HIDDEN_INDEX_PATCH_COMPLETE", label + ": حالة الرقعة");
        Check(context.BranchTrace.SequenceEqual(new[]
            { "BOOTSTRAP_VALIDATION", "LEGACY_HIDDEN_REVERSED", "HIDDEN_INDEX_PATCH" }),
            label + ": استدعاء القديم قبل الغلاف");
        Check(context.Metrics.TryGetValue("bootstrap.dispatch", out var boot) && boot == 1 &&
            context.Metrics.TryGetValue("legacy.hidden.reversed.dispatch", out var old) && old == 1 &&
            context.Metrics.TryGetValue("hidden.index.patch.dispatch", out var patched) && patched == 1,
            label + ": حصر الاستدعاءات");

        for (var k = 1; k <= 7; k++)
        {
            _verifiedDrops++;
            var expected = norm[k];
            var result = patch.HiddenByNearness(k);
            Check(result == expected, label + ": تكافؤ القطرة " + k);
            Check(result == legacy[8 - k], label + ": خريطة الفهرس 8-k للقطرة " + k);
            Check(result >= BigInteger.One && result <= NormativeScroll.M,
                label + ": حفظ مجال القطرة " + k);
            Check(legacy[k] == norm[8 - k], label + ": عدم قلب المصفوفة التاريخية " + k);
            if (legacy[k] != expected) _legacyDivergences++;

            if (facade)
                Check(CalendarDateSpaghetti.EvaluateHiddenDrop(c, t, k) == expected,
                    label + ": واجهة الإنتاج العامة للقطرة " + k);
        }
    }

    private static void VerifyContexts()
    {
        var f = NormativeScroll.FoundationDay;
        var manager = new MonsterManager();
        var a = manager.ExecutePatchedHiddenAccess(f, f + 1);
        var b = manager.ExecutePatchedHiddenAccess(f + 1, f);
        var c = manager.ExecuteLegacyHiddenDrops(f, f + 1);
        Check(!ReferenceEquals(a, b) && !ReferenceEquals(a.Metrics, b.Metrics),
            "ملكية السياقات والقياسات");
        Check(!ReferenceEquals(a.BranchTrace, b.BranchTrace),
            "ملكية سجل الموزّع");
        Check(!ReferenceEquals(a.LegacyHiddenReversed, b.LegacyHiddenReversed),
            "استقلال المخازن التاريخية");
        Check(!ReferenceEquals(a.PatchedHiddenAccess, b.PatchedHiddenAccess),
            "استقلال أغلفة الرقعة");
        Check(a.LegacyHiddenReversed!.SequenceEqual(c.LegacyHiddenReversed!),
            "استمرار التخزين القديم من دون تغيير في المسار المصحح");
        Check(a.LegacyHiddenReversed[1] == a.PatchedHiddenAccess!.HiddenByNearness(7) &&
            a.LegacyHiddenReversed[7] == a.PatchedHiddenAccess.HiddenByNearness(1),
            "بقاء مؤشر القرب خارج ترتيب التخزين");
        var preserved = (BigInteger[])b.LegacyHiddenReversed!.Clone();
        a.LegacyHiddenReversed[2] = BigInteger.MinusOne;
        Check(b.LegacyHiddenReversed.SequenceEqual(preserved),
            "عدم تسرب الكتابة من سياق إلى آخر");
        var wasRejected = false;
        try { a.PatchedHiddenAccess.HiddenByNearness(6); }
        catch (MonsterValidationException) { wasRejected = true; }
        Check(wasRejected, "رفض قيمة تاريخية تالفة بعد ربط الغلاف");

        var dispatcher = new MonsterDispatcher(new MonsterValidationManager(),
            new MonsterMetricsManager());
        var trace = a.BranchTrace.ToArray();
        var didReject = false;
        try { dispatcher.DispatchPatchedHiddenAccess(a); }
        catch (MonsterValidationException) { didReject = true; }
        Check(didReject && a.BranchTrace.SequenceEqual(trace) &&
            a.Metrics["hidden.index.patch.dispatch"] == 1,
            "رفض تكرار استدعاء الرقعة دون أثر جديد");

        var unready = new MonsterContext(BigInteger.Zero, BigInteger.One);
        didReject = false;
        try { dispatcher.DispatchPatchedHiddenAccess(unready); }
        catch (MonsterValidationException) { didReject = true; }
        Check(didReject && unready.Status == "NEW" &&
            unready.PatchedHiddenAccess is null &&
            unready.LegacyHiddenReversed is null &&
            unready.BranchTrace.Count == 0,
            "رفض السياق غير المؤسس دون الالتزام");

        var occupied = manager.Prepare(0, 1);
        occupied.LegacyHiddenReversed = new BigInteger[8];
        var previousTrace = occupied.BranchTrace.ToArray();
        didReject = false;
        try { dispatcher.DispatchPatchedHiddenAccess(occupied); }
        catch (MonsterValidationException) { didReject = true; }
        Check(didReject && occupied.PatchedHiddenAccess is null &&
            occupied.BranchTrace.SequenceEqual(previousTrace),
            "منع إعادة استخدام تخزين غير مملوك للرقعة");

        var oldContext = manager.ExecuteLegacyHiddenDrops(f, f + 1);
        var validation = new MonsterValidationManager();
        var candidate = new HiddenNearnessWrapper(oldContext.LegacyHiddenReversed!);
        validation.ValidateHiddenNearnessWrapper(oldContext, candidate);
        Check(oldContext.PatchedHiddenAccess is null, "التحقق لا يثبت الحالة بنفسه");
        var staleOther = new HiddenNearnessWrapper(manager.ExecuteLegacyHiddenDrops(f, f + 1).LegacyHiddenReversed!);
        didReject = false;
        try { validation.ValidateHiddenNearnessWrapper(oldContext, staleOther); }
        catch (MonsterValidationException) { didReject = true; }
        Check(didReject && oldContext.PatchedHiddenAccess is null,
            "رفض غلاف فهرسة يرتبط بمخزن سياق مختلف");

        foreach (var k in new[] { -10, -1, 0, 8, 9, int.MinValue, int.MaxValue })
        {
            didReject = false;
            try { candidate.HiddenByNearness(k); }
            catch (MonsterValidationException) { didReject = true; }
            Check(didReject, "رفض رقم قرب غير مسموح " + k);
        }
        foreach (var badStorage in new[]
            { new BigInteger[0], new BigInteger[7], new BigInteger[9] })
        {
            didReject = false;
            try { _ = new HiddenNearnessWrapper(badStorage); }
            catch (MonsterValidationException) { didReject = true; }
            Check(didReject, "رفض طول مخزن غير صالح " + badStorage.Length);
        }
        didReject = false;
        try { _ = new HiddenNearnessWrapper(null!); }
        catch (MonsterValidationException) { didReject = true; }
        Check(didReject, "رفض مخزن معدوم");
        var wrongSentinel = (BigInteger[])oldContext.LegacyHiddenReversed!.Clone();
        wrongSentinel[0] = BigInteger.One;
        didReject = false;
        try { _ = new HiddenNearnessWrapper(wrongSentinel); }
        catch (MonsterValidationException) { didReject = true; }
        Check(didReject, "رفض خرق فهرس الصفر المحجوز");
        var wrongValue = (BigInteger[])oldContext.LegacyHiddenReversed.Clone();
        wrongValue[4] = (BigInteger.One << 127);
        didReject = false;
        try { _ = new HiddenNearnessWrapper(wrongValue); }
        catch (MonsterValidationException) { didReject = true; }
        Check(didReject, "رفض قيمة فوق المجال");

        // اختبار تركيبة اصطناعية يضمن أن الرقعة لا تعتمد على فرادة القطرات أو على فرزها.
        var synthetic = new BigInteger[] { 0, 11, 11, 3, 3, 11, 7, 7 };
        var wrapper = new HiddenNearnessWrapper(synthetic);
        for (var k = 1; k <= 7; k++)
            Check(wrapper.HiddenByNearness(k) == synthetic[8 - k],
                "قراءة خريطة الفهارس مع قيمة مكررة " + k);
        Check(synthetic.SequenceEqual(new BigInteger[] { 0, 11, 11, 3, 3, 11, 7, 7 }),
            "المصفوفة الصناعية لا تُقلب ولا تُعاد كتابتها");

        var legacyType = typeof(HiddenNearnessWrapper).Assembly.GetType(
            "PastafarianCalendar.Monster.PriorPatch");
        Check(legacyType is null, "لم يبدأ إصلاح استدعاءات القطرات السابقة في الطور الثاني عشر");
    }

    private static int Main()
    {
        Console.OutputEncoding = System.Text.Encoding.UTF8;
        var f = NormativeScroll.FoundationDay;
        var huge = BigInteger.One << 8192;
        var cases = new List<(BigInteger C, BigInteger T)>
        {
            (f, f), (f, f + 1), (f - 1, f + 1),
            (f - 7, f + 13), (f + huge, f - huge),
            (f - huge - 1, f + huge + 3),
            (f + huge + 1, f + huge + 7),
            (f - huge, f - huge - 5),
            (f + 8, f - 8), (f - 9, f + 17)
        };
        for (var c = -3; c <= 3; c++)
            for (var t = -3; t <= 3; t++)
                cases.Add((f + c, f + t));

        for (var i = 0; i < cases.Count; i++)
            VerifyPair(cases[i].C, cases[i].T, "زوج " + i, i < 4);
        VerifyContexts();

        Console.WriteLine("أزواج الأيام المفحوصة: " + _verifiedCases);
        Console.WriteLine("القطرات الخفية المصححة: " + _verifiedDrops);
        Console.WriteLine("اختلافات التخزين التاريخي: " + _legacyDivergences);
        Console.WriteLine("الاختبارات الناجحة: " + _passed);
        Console.WriteLine("الاختبارات الفاشلة: " + _failed);
        return _failed == 0 ? 0 : 1;
    }
}
