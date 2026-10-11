using System.Numerics;
using PastafarianCalendar.Monster;
using PastafarianCalendar.Stage01Tests.Normative;

namespace PastafarianCalendar.Stage10Tests;

internal static class Program
{
    private static int _compared;
    private static int _matches;
    private static int _divergences;
    private static int _unanticipated;

    private static void Check(bool condition, string description)
    {
        if (condition) return;
        _unanticipated++;
        Console.WriteLine("انحراف غير متوقع: " + description);
    }

    private static void CheckDates(BigInteger c, BigInteger t, string label)
    {
        var reference = NormativeScroll.BuildHiddenDrops(NormativeScroll.WorkCountsFor(c, t));
        var hidden = CalendarDateSpaghetti.EvaluateLegacyHiddenDrops(c, t);

        Check(hidden.Length == 8 && hidden[0] == 0, "بنية التخزين التاريخي " + label);
        for (var k = 1; k <= 7; k++)
        {
            var legacy = hidden[k]; // موضع قريب يظنه القديم صحيحاً؛ هو معكوس.
            var expected = reference[k];
            var different = legacy != expected;
            _compared++;
            if (different) _divergences++; else _matches++;

            Check(hidden[8 - k] == expected, "مكان كتابة القطرة المعكوسة " + k + "/" + label);
            Check(different == (k != 4), "توقيع الأجزاء المرآوية " + k + "/" + label);
            Check(legacy >= 1 && legacy <= NormativeScroll.M,
                "المجال العددي رغم ترتيب المواضع " + k + "/" + label);
            Check(!ReferenceEquals(hidden, reference), "استقلال الإنتاج عن المرجع " + label);
        }

        // نوع المرجع منفصل عن الإنتاج؛ حتى المدخلات البعيدة لا تختزل إلى أعداد عائمة.
        var patchedCounts = CalendarDateSpaghetti.EvaluateWorkCounts(c, t);
        var normCounts = NormativeScroll.WorkCountsFor(c, t);
        Check(patchedCounts.Action == normCounts.Action &&
            patchedCounts.Target == normCounts.Target &&
            patchedCounts.Distance == normCounts.Distance &&
            patchedCounts.Connection == normCounts.Connection &&
            patchedCounts.Direction == normCounts.Direction,
            "مقادير الأيام السابقة متطابقة " + label);
    }

    private static void CheckOwnership()
    {
        var manager = new MonsterManager();
        var f = NormativeScroll.FoundationDay;
        var contextA = manager.ExecuteLegacyHiddenDrops(f, f + 1);
        var contextB = manager.ExecuteLegacyHiddenDrops(f + 1, f);

        Check(!ReferenceEquals(contextA, contextB), "استقلال السياقين");
        Check(!ReferenceEquals(contextA.LegacyHiddenReversed, contextB.LegacyHiddenReversed),
            "استقلال مصفوفات التخزين");
        Check(!ReferenceEquals(contextA.Metrics, contextB.Metrics), "استقلال القياسات");
        Check(!ReferenceEquals(contextA.BranchTrace, contextB.BranchTrace), "استقلال سجل الفروع");
        Check(contextA.Status == "LEGACY_HIDDEN_REVERSED_COMPLETE" &&
            contextA.Phase == "LEGACY_HIDDEN_REVERSED_COMPLETE", "حالة تنفيذ معالج القطرات");
        Check(contextA.BranchTrace.SequenceEqual(
            new[] { "BOOTSTRAP_VALIDATION", "LEGACY_HIDDEN_REVERSED" }),
            "تشغيل المسار التاريخي من الموزّع");
        Check(contextA.Metrics.TryGetValue("legacy.hidden.reversed.dispatch", out var counter)
            && counter == 1, "قياس استدعاء التخزين القديم");
        Check(contextA.LegacyHiddenReversed![0] == BigInteger.Zero,
            "بقاء فهرس الصفر غير مستخدم");
        Check(contextA.PatchedCountsResult is null &&
            contextA.PatchedStoneRows is null &&
            contextA.PatchedSaveResult is null &&
            contextA.LegacyStoneRows is null,
            "عدم تلويث حقول المراحل السابقة");

        // الكتابة في مصفوفة سياق واحد لا تعدّل مخرجات الاستدعاء الثاني.
        var originalB = (BigInteger[])contextB.LegacyHiddenReversed!.Clone();
        contextA.LegacyHiddenReversed![1] = BigInteger.MinusOne;
        Check(contextB.LegacyHiddenReversed.SequenceEqual(originalB), "منع تسرب التعديل بين السياقات");

        var dispatcher = new MonsterDispatcher(new MonsterValidationManager(), new MonsterMetricsManager());
        var trace = contextA.BranchTrace.ToArray();
        var duplicateRejected = false;
        try { dispatcher.DispatchLegacyHiddenDrops(contextA); }
        catch (MonsterValidationException) { duplicateRejected = true; }
        Check(duplicateRejected && contextA.BranchTrace.SequenceEqual(trace) &&
            contextA.Metrics["legacy.hidden.reversed.dispatch"] == 1,
            "رفض إرسال المسار نفسه مرتين دون أثر");

        var unready = new MonsterContext(BigInteger.Zero, BigInteger.One);
        var prematureRejected = false;
        try { dispatcher.DispatchLegacyHiddenDrops(unready); }
        catch (MonsterValidationException) { prematureRejected = true; }
        Check(prematureRejected && unready.Status == "NEW" &&
            unready.LegacyHiddenReversed is null && unready.BranchTrace.Count == 0,
            "رفض الإدخال قبل التأسيس");

        var coeffs = new PatchedCounts().Calculate(f, f + 1);
        var stones = new StonePatchWrapper().BuildPatchedRows();
        var raw = LegacyHiddenDrops.BuildBackwardStorage(coeffs, stones);
        Check(raw.Length == 8 && raw[0] == BigInteger.Zero,
            "بناء مستقل للتخزين المعكوس دون تحويله إلى ترتيب القرب");
        foreach (var invalid in new[] { 0, 8, -1, int.MaxValue })
        {
            var rejected = false;
            try { LegacyHiddenDrops.MakeHiddenDrop(invalid, coeffs, stones); }
            catch (MonsterValidationException) { rejected = true; }
            Check(rejected, "رفض رقم قطرة خارج المجال " + invalid);
        }

        var shortStones = new BigInteger[7][];
        var invalidInputRejected = false;
        try { LegacyHiddenDrops.MakeHiddenDrop(1, coeffs, shortStones); }
        catch (MonsterValidationException) { invalidInputRejected = true; }
        Check(invalidInputRejected, "رفض مصفوفة أحجار ناقصة");
        Check(typeof(LegacyHiddenDrops).Assembly.GetType(
                "PastafarianCalendar.Monster.HiddenIndexPatch") is null,
            "غياب رقعة فهارس القطرات قبل الطور الحادي عشر");
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
        var cases = new (BigInteger Calculation, BigInteger Target)[]
        {
            (f, f),
            (f, f + 1),
            (f - 1, f + 1),
            (f - 7, f + 13),
            (f + huge, f - huge),
            (f - huge - 1, f + huge + 3)
        };
        for (var i = 0; i < cases.Length; i++)
            CheckDates(cases[i].Calculation, cases[i].Target, "حالة " + i);
        if (verify) CheckOwnership();

        Console.WriteLine("مواقع القطرات المقارنة: " + _compared);
        Console.WriteLine("مواقع القطرات المطابقة: " + _matches);
        Console.WriteLine("الاختلافات التاريخية المتوقعة: " + _divergences);
        Console.WriteLine("مخالفات التوقيع أو الملكية: " + _unanticipated);
        if (!verify)
            return _unanticipated == 0 && _divergences > 0 ? 1 : 2;

        if (_compared == 42 && _matches == 6 && _divergences == 36 && _unanticipated == 0)
        {
            Console.WriteLine("توقيع الاكتشاف الخامس: PASS؛ بقي ترتيب القطرات الخفية معكوساً.");
            return 0;
        }
        Console.WriteLine("توقيع الاكتشاف الخامس: FAIL");
        return 1;
    }
}
