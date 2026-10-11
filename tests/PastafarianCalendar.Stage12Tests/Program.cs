using System.Numerics;
using PastafarianCalendar.Monster;
using PastafarianCalendar.Stage01Tests.Normative;

namespace PastafarianCalendar.Stage12Tests;

internal static class Program
{
    private static int _checked;
    private static int _positiveMatches;
    private static int _zeroSlots;
    private static int _negativeFaults;
    private static int _unexpected;
    private static int _fixturePairs;

    private static void Check(bool valid, string title)
    {
        if (valid) return;
        _unexpected++;
        Console.WriteLine("مخالفة خارج التوقيع: " + title);
    }

    private static void VerifyPair(BigInteger c, BigInteger t, string label)
    {
        _fixturePairs++;
        // المصدر الاختباري مستقل؛ لا يدخل مرجع الحساب في مكتبة الإنتاج.
        var counts = NormativeScroll.WorkCountsFor(c, t);
        var hidden = NormativeScroll.BuildHiddenDrops(counts);
        var visible = NormativeScroll.BuildVisibleDrops(counts, hidden);
        var store = (BigInteger[])visible.Clone();
        Check(store.Length == 47 && store[0] == BigInteger.Zero, "حجز فهرس الصفر " + label);

        for (var i = 1; i <= 46; i++)
        {
            foreach (var back in new[] { 1, 3, 7 })
            {
                var slot = i - back;
                var expected = slot >= 1 ? visible[slot] : hidden[1 - slot];
                var before = (BigInteger[])store.Clone();
                _checked++;

                try
                {
                    var result = CalendarDateSpaghetti.EvaluateLegacyPrior(c, t, store, i, back);
                    Check(slot >= 0, "قراءة غير متوقعة لفهرس سالب " + i + "/" + back);
                    if (slot > 0)
                    {
                        _positiveMatches++;
                        Check(result == expected && result == store[slot],
                            "المواضع الموجبة توافق المرجع " + label + "/" + i + "/" + back);
                        Check(result >= 1 && result <= NormativeScroll.M,
                            "المدى العددي للقطرة الظاهرة " + label + "/" + i + "/" + back);
                    }
                    else
                    {
                        _zeroSlots++;
                        Check(result.IsZero && expected >= BigInteger.One,
                            "القطرة المخفية الأولى ليست صفراً " + label + "/" + i + "/" + back);
                    }
                }
                catch (IndexOutOfRangeException)
                {
                    if (slot < 0)
                        _negativeFaults++;
                    else
                        Check(false, "استثناء فهرسة عند موضع غير سالب " + label + "/" + i + "/" + back);
                }
                catch (Exception ex)
                {
                    Check(false, "استثناء غير تاريخي " + ex.GetType().Name +
                        " " + label + "/" + i + "/" + back);
                }

                Check(store.SequenceEqual(before),
                    "المسار القديم لا يغيّر المدخل " + label + "/" + i + "/" + back);
            }
        }
    }

    private static void VerifyHistoricalOwnership()
    {
        var manager = new MonsterManager();
        var foundation = NormativeScroll.FoundationDay;
        var vals = new BigInteger[47];
        for (var i = 1; i <= 46; i++) vals[i] = i * i + 17;
        var original = (BigInteger[])vals.Clone();

        var first = manager.ExecuteLegacyPrior(foundation, foundation + 1, vals, 46, 7);
        var second = manager.ExecuteLegacyPrior(foundation + 1, foundation, vals, 46, 7);
        Check(first.LegacyPriorResult == vals[39] &&
            second.LegacyPriorResult == vals[39], "تأكيد قراءة الموضع الموجب");
        Check(first.BranchTrace.SequenceEqual(
            new[] { "BOOTSTRAP_VALIDATION", "LEGACY_PRIOR" }),
            "استدعاء معالج المسار التاريخي");
        Check(first.Phase == "LEGACY_PRIOR_COMPLETE" &&
            first.Status == "LEGACY_PRIOR_COMPLETE",
            "نتيجة حالة التزام المسار القديم");
        Check(first.Metrics.TryGetValue("legacy.prior.dispatch", out var oldCount) &&
            oldCount == 1, "مقياس تنفيذ الاستدعاء");
        Check(first.PatchedHiddenAccess is null && first.LegacyHiddenReversed is null &&
            first.PatchedStoneRows is null && first.PatchedCountsResult is null,
            "عدم تشغيل مسارات مستقبلية أو تسريب حالة المراحل السابقة");
        Check(!ReferenceEquals(first, second) &&
            !ReferenceEquals(first.LegacyPriorDropStore, second.LegacyPriorDropStore) &&
            !ReferenceEquals(first.LegacyPriorDropStore, vals) &&
            !ReferenceEquals(first.Metrics, second.Metrics) &&
            !ReferenceEquals(first.BranchTrace, second.BranchTrace),
            "ملكية السياق ونسخة المخزن والسجلات");
        first.LegacyPriorDropStore![25] = BigInteger.MinusOne;
        Check(vals.SequenceEqual(original) && second.LegacyPriorDropStore![25] == original[25],
            "منع تسرب الكتابة إلى المدخل وإلى الاستدعاء الثاني");

        var dispatcher = new MonsterDispatcher(new MonsterValidationManager(),
            new MonsterMetricsManager());
        var trace = first.BranchTrace.ToArray();
        var rejected = false;
        try { dispatcher.DispatchLegacyPrior(first); }
        catch (MonsterValidationException) { rejected = true; }
        Check(rejected && first.BranchTrace.SequenceEqual(trace) &&
            first.Metrics["legacy.prior.dispatch"] == 1,
            "رفض تنفيذ المعالج مرتين");

        var unprepared = new MonsterContext(BigInteger.Zero, BigInteger.One)
        {
            LegacyPriorDropStore = (BigInteger[])vals.Clone(),
            LegacyPriorVisibleIndex = 10,
            LegacyPriorBack = 7
        };
        rejected = false;
        try { dispatcher.DispatchLegacyPrior(unprepared); }
        catch (MonsterValidationException) { rejected = true; }
        Check(rejected && unprepared.BranchTrace.Count == 0 &&
            unprepared.Status == "NEW" && unprepared.LegacyPriorResult is null,
            "رفض سياق غير مؤسس دون التزام");

        // تُقذف القراءة التاريخية لفهرس سالب، ولا تغيّر حالة الاستدعاء.
        var failed = manager.Prepare(0, 1);
        failed.LegacyPriorDropStore = (BigInteger[])vals.Clone();
        failed.LegacyPriorVisibleIndex = 1;
        failed.LegacyPriorBack = 7;
        var priorTrace = failed.BranchTrace.ToArray();
        rejected = false;
        try { dispatcher.DispatchLegacyPrior(failed); }
        catch (IndexOutOfRangeException) { rejected = true; }
        Check(rejected && failed.Status == "BOOTSTRAP_READY" &&
            failed.Phase == "BOOTSTRAP_READY" &&
            failed.LegacyPriorResult is null &&
            failed.BranchTrace.SequenceEqual(priorTrace) &&
            !failed.Metrics.ContainsKey("legacy.prior.dispatch"),
            "عدم الالتزام الجزئي عند خطأ الفهرس التاريخي");

        // يصل الفهرس صفر إلى قيمة الصفر القديمة، لا إلى القطرة الخفية الأولى.
        var zero = manager.ExecuteLegacyPrior(0, 1, vals, 7, 7);
        Check(zero.LegacyPriorResult.HasValue && zero.LegacyPriorResult.Value.IsZero,
            "إرجاع خانة الصفر دون رقعة القطرات الخفية");
        Check(LegacyPrior.Read(vals, 46, 1) == vals[45],
            "الفهرسة التاريخية المباشرة لا تمرّ بغلاف مصحح");

        foreach (var invalid in new[]
        {
            (0, 1), (47, 1), (-1, 1), (1, 0), (1, 2), (1, 4), (1, 8)
        })
        {
            rejected = false;
            try { manager.ExecuteLegacyPrior(0, 1, vals, invalid.Item1, invalid.Item2); }
            catch (MonsterValidationException) { rejected = true; }
            Check(rejected, "رفض زوج فهرسة غير مسموح " + invalid);
        }
        foreach (var invalidLength in new[] { 0, 1, 46, 48 })
        {
            rejected = false;
            try { manager.ExecuteLegacyPrior(0, 1, new BigInteger[invalidLength], 2, 1); }
            catch (MonsterValidationException) { rejected = true; }
            Check(rejected, "رفض طول مخزن غير صالح " + invalidLength);
        }
        rejected = false;
        try { manager.ExecuteLegacyPrior(0, 1, null!, 2, 1); }
        catch (MonsterValidationException) { rejected = true; }
        Check(rejected, "رفض مخزن معدوم");
        var wrongSentinel = (BigInteger[])vals.Clone();
        wrongSentinel[0] = BigInteger.One;
        rejected = false;
        try { manager.ExecuteLegacyPrior(0, 1, wrongSentinel, 2, 1); }
        catch (MonsterValidationException) { rejected = true; }
        Check(rejected, "رفض خرق الخانة الصفرية المحجوزة");

        Check(typeof(LegacyPrior).Assembly.GetType("PastafarianCalendar.Monster.PriorPatch") is null,
            "غياب تصحيح استرجاع السابق في الطور الثالث عشر");
    }

    private static int Main(string[] args)
    {
        Console.OutputEncoding = System.Text.Encoding.UTF8;
        var verify = args.Length == 1 && args[0] == "--verify-expected-red";
        if (args.Length != 0 && !verify)
        {
            Console.Error.WriteLine("وسيط فحص غير معروف.");
            return 2;
        }

        var f = NormativeScroll.FoundationDay;
        var huge = BigInteger.One << 8192;
        var samples = new (BigInteger C, BigInteger T)[]
        {
            (f, f), (f - 1, f + 1), (f + 1, f - 1),
            (f + 12, f - 19), (f + huge, f - huge),
            (f - huge - 1, f + huge + 3)
        };
        for (var c = 0; c < samples.Length; c++)
            VerifyPair(samples[c].C, samples[c].T, "زوج " + c);
        if (verify) VerifyHistoricalOwnership();

        Console.WriteLine("قراءات القطرات السابقة المفحوصة: " + _checked);
        Console.WriteLine("القراءات الموجبة المطابقة: " + _positiveMatches);
        Console.WriteLine("قراءات الخانة صفر بدلاً من المخفية: " + _zeroSlots);
        Console.WriteLine("أخطاء الفهرس السالب التاريخية: " + _negativeFaults);
        Console.WriteLine("المخالفات غير المتوقعة: " + _unexpected);

        if (!verify)
            return _unexpected == 0 && _zeroSlots + _negativeFaults > 0 ? 1 : 2;
        if (_checked == 828 && _positiveMatches == 762 &&
            _zeroSlots == 18 && _negativeFaults == 48 && _unexpected == 0)
        {
            Console.WriteLine("توقيع الاكتشاف السادس: PASS؛ استرجاع السابق لا يعرف القطرات الخفية.");
            return 0;
        }
        Console.WriteLine("توقيع الاكتشاف السادس: FAIL");
        return 1;
    }
}
