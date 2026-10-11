using System.Numerics;
using PastafarianCalendar.Monster;
using PastafarianCalendar.Stage01Tests.Normative;

namespace PastafarianCalendar.Stage07Tests;

internal static class Program
{
    private static int _passed;
    private static int _failed;
    private static int _pairs;
    private static int _historicalMatches;
    private static int _historicalDivergences;

    private static void Check(bool condition, string description)
    {
        if (condition) { _passed++; return; }
        _failed++;
        Console.WriteLine("فشل: " + description);
    }

    private static void VerifyPair(BigInteger cOffset, BigInteger tOffset, string name)
    {
        var c = NormativeScroll.FoundationDay + cOffset;
        var t = NormativeScroll.FoundationDay + tOffset;
        var expected = NormativeScroll.WorkCountsFor(c, t);
        var actual = CalendarDateSpaghetti.EvaluateWorkCounts(c, t);
        var legacy = CalendarDateSpaghetti.EvaluateLegacyDistance(c, t);
        var chronological = BigInteger.Abs(t - c);
        _pairs++;

        Check(actual.Action == expected.Action, name + ": عدّ يوم العمل");
        Check(actual.Target == expected.Target, name + ": عدّ اليوم المطلوب");
        Check(actual.Distance == expected.Distance, name + ": المسافة الشاملة");
        Check(actual.Connection == expected.Connection, name + ": عدّ الاتصال");
        Check(actual.Direction == expected.Direction, name + ": عدّ الطريق");
        Check(actual.Connection == actual.Action + actual.Target, name + ": اتصال مشتق");
        Check(actual.Distance == chronological + 1 && actual.Distance >= 1, name + ": مسافة زمنية موجبة");
        Check(actual.Direction == (c < t ? 3 : c > t ? 1 : 2), name + ": جهة الطريق");

        // يجب أن يبقى الفرق التاريخي فعالاً ولا يجوز إخفاء تصحيحه في الإنتاج.
        var legacyFormula = BigInteger.Abs(NormativeScroll.DayCount(c) - NormativeScroll.DayCount(t));
        Check(legacy == legacyFormula, name + ": حفظ الجرح التاريخي");
        if (legacy == expected.Distance) _historicalMatches++;
        else _historicalDivergences++;

        var wasCorrected = legacy != chronological;
        Check(actual.Distance == (wasCorrected ? chronological : legacy) + 1,
            name + ": مقارنة المسافتين ثم إضافة الوحدة");
    }

    private static void VerifySymmetry(BigInteger a, BigInteger b, string name)
    {
        var x = CalendarDateSpaghetti.EvaluateWorkCounts(a, b);
        var y = CalendarDateSpaghetti.EvaluateWorkCounts(b, a);
        Check(x.Action == y.Target && x.Target == y.Action, name + ": تناظر العدّادين");
        Check(x.Distance == y.Distance, name + ": تناظر المسافة");
        Check(x.Connection == y.Connection, name + ": تناظر الاتصال");
        Check(x.Direction == 2 ? y.Direction == 2 : x.Direction + y.Direction == 4,
            name + ": تناظر عدّ الطريق");
    }

    private static void VerifyContextAndValidation()
    {
        var f = NormativeScroll.FoundationDay;
        var manager = new MonsterManager();
        var first = manager.ExecutePatchedCounts(f - 1, f + 1);
        var second = manager.ExecutePatchedCounts(f + 3, f + 4);
        var same = manager.ExecutePatchedCounts(f, f);

        Check(!ReferenceEquals(first, second) && !ReferenceEquals(first.Metrics, second.Metrics),
            "ملكية السياق المستقل والقياسات");
        Check(!ReferenceEquals(first.BranchTrace, second.BranchTrace), "ملكية أثر المسارات");
        Check(first.LegacyDistanceResult == 1 && first.PatchedCountsResult?.Distance == 3,
            "الاحتفاظ بمسافة عبور التأسيس وتصحيحها");
        Check(second.LegacyDistanceResult == 2 && second.PatchedCountsResult?.Distance == 2,
            "المسافة المطابقة في الحالة المجاورة");
        Check(same.LegacyDistanceResult == 0 && same.PatchedCountsResult?.Distance == 1,
            "اليوم الواحد: صفر تاريخي ومسافة شاملة");
        Check(first.PatchedCountsResult?.Action == 2 && first.PatchedCountsResult?.Target == 3,
            "عددَا يومَي العبور");
        Check(first.PatchedCountsResult?.Connection == 5 && first.PatchedCountsResult?.Direction == 3,
            "اتصال العبور واتجاهه");
        Check(first.Status == "COUNTS_PATCH_COMPLETE" && first.Phase == "COUNTS_PATCH_COMPLETE",
            "اكتمال مرحلة الرقعة الثالثة");
        Check(first.BranchTrace.SequenceEqual(
            new[] { "BOOTSTRAP_VALIDATION", "LEGACY_DISTANCE", "COUNTS_PATCH" }),
            "استدعاء المسار القديم داخل الرقعة");
        Check(first.Metrics.TryGetValue("bootstrap.dispatch", out var boot) && boot == 1 &&
            first.Metrics.TryGetValue("legacy.distance.dispatch", out var old) && old == 1 &&
            first.Metrics.TryGetValue("counts.patch.dispatch", out var patched) && patched == 1,
            "قياسات مستقلة للمراحل الثلاث");
        Check(first.LegacySaveResult is null && first.PatchedSaveResult is null &&
            first.PatchedDayTagResult is null, "عدم تلويث الأطوار السابقة");

        var dispatcher = new MonsterDispatcher(new MonsterValidationManager(), new MonsterMetricsManager());
        var trace = first.BranchTrace.ToArray();
        var oldValue = first.LegacyDistanceResult;
        var newValue = first.PatchedCountsResult;
        var rejected = false;
        try { dispatcher.DispatchPatchedCounts(first); }
        catch (MonsterValidationException) { rejected = true; }
        Check(rejected && first.LegacyDistanceResult == oldValue &&
            ReferenceEquals(first.PatchedCountsResult, newValue) &&
            first.BranchTrace.SequenceEqual(trace), "رفض تشغيل الرقعة مرة ثانية بلا تغيير");

        var unprepared = new MonsterContext(f, f + 1);
        rejected = false;
        try { dispatcher.DispatchPatchedCounts(unprepared); }
        catch (MonsterValidationException) { rejected = true; }
        Check(rejected && unprepared.LegacyDistanceResult is null &&
            unprepared.PatchedCountsResult is null && unprepared.Status == "NEW" &&
            unprepared.BranchTrace.Count == 0, "رفض السياق غير المؤسس دون أي التزام");

        var invalid = manager.Prepare(f, f + 1);
        invalid.LegacyDistanceResult = BigInteger.Zero;
        var state = invalid.BranchTrace.ToArray();
        rejected = false;
        try { dispatcher.DispatchPatchedCounts(invalid); }
        catch (MonsterValidationException) { rejected = true; }
        Check(rejected && invalid.PatchedCountsResult is null &&
            invalid.LegacyDistanceResult == 0 && invalid.BranchTrace.SequenceEqual(state),
            "منع استخدام نتيجة قديمة مسبقة متلاعب بها");

        var validator = new MonsterValidationManager();
        var good = manager.ExecutePatchedCounts(f - 5, f + 7);
        var saved = good.PatchedCountsResult!;
        var bad = saved with { Distance = BigInteger.Zero };
        var maliciousRejected = false;
        // لا يجوز لمدقق الإنتاج قبول خماسية ذات مسافة مصطنعة.
        var candidateContext = manager.ExecuteLegacyDistance(f - 5, f + 7);
        try { validator.ValidatePatchedCounts(candidateContext, bad); }
        catch (MonsterValidationException) { maliciousRejected = true; }
        Check(maliciousRejected && candidateContext.PatchedCountsResult is null,
            "رفض نتيجة مرشحة غير معيارية قبل الالتزام");
        validator.ValidatePatchedCounts(candidateContext, saved);
        Check(candidateContext.PatchedCountsResult is null,
            "التحقق وحده لا يثبّت نتيجة في السياق");
    }

    private static int Main()
    {
        Console.OutputEncoding = System.Text.Encoding.UTF8;
        for (var c = -24; c <= 24; c++)
            for (var t = -24; t <= 24; t++)
                VerifyPair(new BigInteger(c), new BigInteger(t), "شبكة " + c + "/" + t);

        var far = BigInteger.One << 8192;
        var longPairs = new (BigInteger C, BigInteger T)[]
        {
            (far, far), (-far, -far), (-far, far), (far, -far),
            (-far, far + 1), (far, -far - 1),
            (far, far + 1), (-far, -far + 1),
            (far, far + 2), (-far, -far - 2),
            (far + 1, far + 2), (-far - 1, -far - 2),
            (BigInteger.Zero, far), (BigInteger.Zero, -far),
            (far, BigInteger.Zero), (-far, BigInteger.Zero),
            (BigInteger.One << 1024, BigInteger.One << 4096),
            (-(BigInteger.One << 4096), BigInteger.One << 1024),
            (-129, 129), (-1000000, 1000000),
            (1000000000, 1000000001), (-1000000001, -1000000000)
        };
        foreach (var pair in longPairs)
            VerifyPair(pair.C, pair.T, "أيام بعيدة " + _pairs);

        VerifySymmetry(NormativeScroll.FoundationDay - 3, NormativeScroll.FoundationDay + 3,
            "عبور التأسيس");
        VerifySymmetry(NormativeScroll.FoundationDay, NormativeScroll.FoundationDay,
            "تماثل اليوم الواحد");
        VerifySymmetry(NormativeScroll.FoundationDay + far, NormativeScroll.FoundationDay - far,
            "تماثل الأعداد الهائلة");

        VerifyContextAndValidation();

        Console.WriteLine("أزواج الأيام المفحوصة: " + _pairs);
        Console.WriteLine("تطابقات المسافة التاريخية: " + _historicalMatches);
        Console.WriteLine("اختلافات المسافة التاريخية: " + _historicalDivergences);
        Console.WriteLine("فحوص الرقعة الثالثة الناجحة: " + _passed);
        Console.WriteLine("فحوص الرقعة الثالثة الفاشلة: " + _failed);
        return _failed == 0 ? 0 : 1;
    }
}
