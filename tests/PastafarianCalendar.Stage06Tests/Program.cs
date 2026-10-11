using System.Numerics;
using PastafarianCalendar.Monster;
using PastafarianCalendar.Stage01Tests.Normative;

namespace PastafarianCalendar.Stage06Tests;

internal static class Program
{
    private static int _matches;
    private static int _differences;
    private static int _unexpected;
    private static int _evaluated;

    private static void Require(bool condition, string title)
    {
        if (condition) return;
        _unexpected++;
        Console.WriteLine("فشل ضمان الاكتشاف: " + title);
    }

    private static void Probe(BigInteger cOffset, BigInteger tOffset, string label)
    {
        var c = NormativeScroll.FoundationDay + cOffset;
        var t = NormativeScroll.FoundationDay + tOffset;
        var expected = NormativeScroll.WorkCountsFor(c, t).Distance;
        var expectedLegacy = BigInteger.Abs(NormativeScroll.DayCount(c) - NormativeScroll.DayCount(t));
        var actual = CalendarDateSpaghetti.EvaluateLegacyDistance(c, t);
        _evaluated++;

        if (actual == expected) _matches++; else _differences++;
        Require(actual == expectedLegacy, "صيغة الفرق بين عدّادين " + label);
        Require(actual >= 0, "عدم سلبية الباقي القديم " + label);

        // الرقعة السابقة تعمل حقاً، ولا تُغفلها الصيغة التاريخية الثالثة.
        var productionCalculationTag = CalendarDateSpaghetti.EvaluateDayTag(c, t, c);
        var productionTargetTag = CalendarDateSpaghetti.EvaluateDayTag(c, t, t);
        Require(actual == BigInteger.Abs(productionCalculationTag - productionTargetTag),
            "المسافة مبنية على رقعة عدّ اليوم الثانية " + label);

        if (actual != expected && (_evaluated <= 8 || cOffset == tOffset))
            Console.WriteLine("فرق تاريخي: " + label + " | المرجع=" + expected + " | القديم=" + actual);
    }

    private static void VerifyContext()
    {
        var manager = new MonsterManager();
        var f = NormativeScroll.FoundationDay;
        var first = manager.ExecuteLegacyDistance(f - 1, f + 1);
        var second = manager.ExecuteLegacyDistance(f + 3, f + 4);

        Require(!ReferenceEquals(first, second), "السياقان منفصلان");
        Require(!ReferenceEquals(first.BranchTrace, second.BranchTrace), "آثار الفروع مستقلة");
        Require(!ReferenceEquals(first.Metrics, second.Metrics), "القياسات مستقلة");
        Require(first.LegacyDistanceResult == 1, "الاختلاف التاريخي عند عبور التأسيس");
        Require(second.LegacyDistanceResult == 2, "المسافة القديمة داخل جانب واحد");
        Require(first.CalculationDay == f - 1 && first.TargetDay == f + 1,
            "حفظ مدخلي الاستدعاء الأول");
        Require(first.Status == "LEGACY_DISTANCE_COMPLETE"
            && first.Phase == "LEGACY_DISTANCE_COMPLETE", "اكتمال حالة المسافة القديمة");
        Require(first.BranchTrace.SequenceEqual(
            new[] { "BOOTSTRAP_VALIDATION", "LEGACY_DISTANCE" }), "أثر المسار الثالث");
        Require(first.Metrics.TryGetValue("legacy.distance.dispatch", out var metric) && metric == 1,
            "قياس المعالج الثالث");
        Require(first.PatchedSaveResult is null && first.PatchedDayTagResult is null,
            "عدم تلويث نتائج الرقعتين السابقتين");

        var dispatcher = new MonsterDispatcher(new MonsterValidationManager(), new MonsterMetricsManager());
        var before = first.BranchTrace.ToArray();
        var duplicateRejected = false;
        try { dispatcher.DispatchLegacyDistance(first); }
        catch (MonsterValidationException) { duplicateRejected = true; }
        Require(duplicateRejected, "رفض تشغيل المسافة مرتين");
        Require(first.LegacyDistanceResult == 1 && first.BranchTrace.SequenceEqual(before),
            "ثبات نتيجة السياق بعد رفض التشغيل الثاني");

        var unfinished = new MonsterContext(f, f + 1);
        var prematureRejected = false;
        try { dispatcher.DispatchLegacyDistance(unfinished); }
        catch (MonsterValidationException) { prematureRejected = true; }
        Require(prematureRejected, "رفض المسار قبل التأسيس");
        Require(unfinished.Status == "NEW" && unfinished.LegacyDistanceResult is null
            && unfinished.BranchTrace.Count == 0, "رفض التنفيذ المبكر دون أثر");
    }

    private static int Main(string[] args)
    {
        Console.OutputEncoding = System.Text.Encoding.UTF8;
        var verify = args.Length == 1 && args[0] == "--verify-expected-red";
        if (args.Length != 0 && !verify)
        {
            Console.Error.WriteLine("وسيط اختبار غير معروف.");
            return 2;
        }

        var f = NormativeScroll.FoundationDay;
        var examples = new (BigInteger C, BigInteger T, string Name)[]
        {
            (BigInteger.Zero, BigInteger.Zero, "اليوم نفسه"),
            (BigInteger.Zero, BigInteger.One, "توافق يومي بعد التأسيس"),
            (-BigInteger.One, BigInteger.Zero, "اليوم السابق إلى التأسيس"),
            (-new BigInteger(3), new BigInteger(3), "عبور متماثل للتأسيس")
        };
        foreach (var example in examples)
            Probe(example.C, example.T, example.Name);

        for (var c = -8; c <= 8; c++)
            for (var t = -8; t <= 8; t++)
                Probe(new BigInteger(c), new BigInteger(t), "شبكة " + c + "/" + t);

        var far = BigInteger.One << 4096;
        var extra = new (BigInteger C, BigInteger T)[]
        {
            (-far, -far), (-far, far), (-far, far + 1),
            (far, -far), (far, far), (far, far + 1),
            (-1, 1), (-2, 2), (0, 0), (0, 1),
            (1, 2), (-1, 0), (-1, 1),
            (-far, -far + 1), (far, far + 2), (far + 1, far + 2)
        };
        foreach (var pair in extra)
            Probe(pair.C, pair.T, "أيام بعيدة");

        if (verify) VerifyContext();

        Console.WriteLine("الحالات المفحوصة: " + _evaluated);
        Console.WriteLine("حالات التطابق: " + _matches);
        Console.WriteLine("حالات الاختلاف: " + _differences);
        Console.WriteLine("مخالفات صيغة المسافة أو السياق: " + _unexpected);

        if (!verify)
            return _differences > 0 && _unexpected == 0 ? 1 : 2;

        // شبكة 17×17، وأربعة أمثلة مميزة، وست عشرة حالة في المجال الواسع.
        if (_evaluated == 309 && _matches == 46 && _differences == 263 && _unexpected == 0)
        {
            Console.WriteLine("توقيع اكتشاف المسافة الثالثة: PASS؛ بقيت الحالات الحمراء مقصودة.");
            return 0;
        }

        Console.WriteLine("توقيع اكتشاف المسافة الثالثة: FAIL");
        return 1;
    }
}
