using System.Numerics;
using PastafarianCalendar.Monster;
using PastafarianCalendar.Stage01Tests.Normative;

namespace PastafarianCalendar.Stage05Tests;

internal static class Program
{
    private static int _passed;
    private static int _failed;
    private static int _values;

    private static void Check(bool condition, string description)
    {
        if (condition)
        {
            _passed++;
            return;
        }
        _failed++;
        Console.WriteLine("فشل: " + description);
    }

    private static void VerifyDay(BigInteger offset)
    {
        var day = NormativeScroll.FoundationDay + offset;
        var foundation = NormativeScroll.FoundationDay;
        var canonical = NormativeScroll.DayCount(day);
        var actual = CalendarDateSpaghetti.EvaluateDayTag(foundation, foundation + BigInteger.One, day);
        var old = CalendarDateSpaghetti.EvaluateLegacyDayTag(foundation, foundation + BigInteger.One, day);
        _values++;

        Check(actual == canonical, "تكافؤ المرجع للإزاحة " + offset);
        Check(actual >= 1, "العدّ المعياري موجب للإزاحة " + offset);
        Check(old == 2 * BigInteger.Abs(offset), "بقاء العدّ القديم للإزاحة " + offset);
        Check(actual - old == (offset.Sign >= 0 ? BigInteger.One : BigInteger.Zero),
            "تطابق فارق الرقعة للإزاحة " + offset);
    }

    private static void VerifyContexts()
    {
        var manager = new MonsterManager();
        var foundation = NormativeScroll.FoundationDay;
        var first = manager.ExecuteDayTagPatched(BigInteger.Zero, BigInteger.One, foundation);
        var before = manager.ExecuteDayTagPatched(BigInteger.One, BigInteger.Zero, foundation - BigInteger.One);
        var after = manager.ExecuteDayTagPatched(BigInteger.Zero, BigInteger.Zero, foundation + BigInteger.One);

        Check(!ReferenceEquals(first, before) && !ReferenceEquals(before, after), "استقلال كائنات السياق");
        Check(!ReferenceEquals(first.BranchTrace, before.BranchTrace), "استقلال آثار الفروع");
        Check(!ReferenceEquals(first.Metrics, before.Metrics), "استقلال القياسات");
        Check(first.LegacyDayTagResult == BigInteger.Zero && first.PatchedDayTagResult == BigInteger.One,
            "الندبة عند التأسيس مع النتيجة المصححة");
        Check(before.LegacyDayTagResult == 2 && before.PatchedDayTagResult == 2,
            "الجانب السابق للتأسيس لا يحتاج وحدة زائدة");
        Check(after.LegacyDayTagResult == 2 && after.PatchedDayTagResult == 3,
            "اليوم التالي للتأسيس");
        Check(first.Phase == "DAY_TAG_PATCH_COMPLETE" && first.Status == "DAY_TAG_PATCH_COMPLETE",
            "حالة الاكتمال");
        Check(first.BranchTrace.SequenceEqual(
            new[] { "BOOTSTRAP_VALIDATION", "LEGACY_DAY_TAG", "DAY_TAG_PATCH" }),
            "بقاء تشغيل المعالج القديم قبل الرقعة");
        Check(first.Metrics.TryGetValue("legacy.day.tag.dispatch", out var oldCount) && oldCount == 1,
            "قياس تشغيل العدّ القديم");
        Check(first.Metrics.TryGetValue("day.tag.patch.dispatch", out var patchCount) && patchCount == 1,
            "قياس تشغيل الرقعة");
        Check(first.PatchedSaveResult is null && first.LegacySaveResult is null,
            "عدم اختلاط عدّ اليوم بالحفظ");

        var dispatcher = new MonsterDispatcher(new MonsterValidationManager(), new MonsterMetricsManager());
        var trace = first.BranchTrace.ToArray();
        var rejected = false;
        try { dispatcher.DispatchDayTagPatched(first); }
        catch (MonsterValidationException) { rejected = true; }
        Check(rejected, "منع تنفيذ الرقعة مرتين");
        Check(first.LegacyDayTagResult == 0 && first.PatchedDayTagResult == 1
            && first.BranchTrace.SequenceEqual(trace), "الرفض يبقي النتيجة على حالها");

        var missing = manager.Prepare(BigInteger.Zero, BigInteger.Zero);
        rejected = false;
        try { dispatcher.DispatchDayTagPatched(missing); }
        catch (MonsterValidationException) { rejected = true; }
        Check(rejected, "رفض مدخل اليوم المفقود");
        Check(missing.Status == "BOOTSTRAP_READY"
            && missing.LegacyDayTagResult is null
            && missing.PatchedDayTagResult is null
            && missing.BranchTrace.SequenceEqual(new[] { "BOOTSTRAP_VALIDATION" }),
            "الرفض المبكر لا يثبت الحالة الدلالية");
    }

    private static int Main()
    {
        Console.OutputEncoding = System.Text.Encoding.UTF8;
        for (var offset = -128; offset <= 128; offset++)
            VerifyDay(new BigInteger(offset));

        var huge = BigInteger.One << 4096;
        foreach (var offset in new[]
        {
            -huge, huge, -huge - 1, huge + 1, -huge + 1, huge - 1,
            new BigInteger(-1000000), new BigInteger(1000000),
            new BigInteger(-129), new BigInteger(129),
            new BigInteger(-1000000000), new BigInteger(1000000000)
        })
            VerifyDay(offset);

        VerifyContexts();

        Console.WriteLine("أيام الرقعة المفحوصة: " + _values);
        Console.WriteLine("اختبارات الرقعة الثانية الناجحة: " + _passed);
        Console.WriteLine("اختبارات الرقعة الثانية الفاشلة: " + _failed);
        return _failed == 0 ? 0 : 1;
    }
}
