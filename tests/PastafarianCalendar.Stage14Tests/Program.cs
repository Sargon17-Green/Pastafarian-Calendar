using System.Numerics;
using System.Reflection;
using PastafarianCalendar.Monster;
using PastafarianCalendar.Stage01Tests.Normative;

namespace PastafarianCalendar.Stage14Tests;

internal static class Program
{
    private static int _cases;
    private static int _matches;
    private static int _shifted;
    private static int _missing;
    private static int _unexpected;

    private static void Require(bool condition, string label)
    {
        if (condition) return;
        _unexpected++;
        Console.WriteLine("مخالفة غير متوقعة: " + label);
    }

    private static (int A, int B, int C, int D, int Kind)[] GetNormativeRows()
    {
        // لا يُستخدم الانعكاس إلا في مشروع الاختبار لاسترجاع الجدول المعياري المستقل.
        var field = typeof(NormativeScroll).GetField("VisibleGrinds",
            BindingFlags.NonPublic | BindingFlags.Static);
        var rows = field?.GetValue(null)
            as (int A, int B, int C, int D, int Kind)[];
        if (rows is null || rows.Length != 12)
            throw new InvalidOperationException("لا يتوفر الجدول المعياري المستقل للاختبار.");
        return rows;
    }

    private static bool Same(LegacyGrindRow actual,
        (int A, int B, int C, int D, int Kind) expected)
        => actual.A == expected.A && actual.B == expected.B &&
           actual.C == expected.C && actual.D == expected.D &&
           actual.StoneKind == expected.Kind;

    private static void InspectPhysicalTable(
        (int A, int B, int C, int D, int Kind)[] oracle)
    {
        // يثبت الفحص أن الجدول المادي حقيقي، وليس جدولاً مصلحاً ذا صفّ حارس.
        var field = typeof(LegacyVisibleGrindTable).GetField("PhysicalRows",
            BindingFlags.NonPublic | BindingFlags.Static);
        var rows = field?.GetValue(null) as LegacyGrindRow[];
        Require(rows is { Length: 11 }, "الجدول القديم يتكون من أحد عشر صفاً حقيقياً بلا حارس");
        if (rows is null || rows.Length != 11) return;

        for (var i = 0; i < rows.Length; i++)
            Require(Same(rows[i], oracle[i + 1]),
                "الموضع الفيزيائي " + i + " مطابق للسطر المعياري " + (i + 1));
        Require(Same(rows[0], oracle[1]), "لا يوجد صفّ حارس في البداية");
        Require(Same(rows[10], oracle[11]), "الصفّ الفيزيائي الأخير يمثل الطحن الحادي عشر");
    }

    private static void Observe(
        BigInteger calculationDay, BigInteger targetDay, int ordinal,
        (int A, int B, int C, int D, int Kind)[] oracle)
    {
        _cases++;
        try
        {
            var actual = CalendarDateSpaghetti.EvaluateLegacyVisibleGrind(
                calculationDay, targetDay, ordinal);
            if (Same(actual, oracle[ordinal]))
            {
                _matches++;
                Console.WriteLine("تطابق غير متوقع في الطحن " + ordinal);
                _unexpected++;
            }
            else if (ordinal < 11 && Same(actual, oracle[ordinal + 1]))
            {
                _shifted++;
                Console.WriteLine("فرق تاريخي: الطحن " + ordinal +
                    " قرأ سطر الطحن " + (ordinal + 1));
            }
            else
            {
                _unexpected++;
                Console.WriteLine("صفّ مختلف خارج توقيع الخطأ في الطحن " + ordinal);
            }
        }
        catch (IndexOutOfRangeException)
        {
            if (ordinal == 11)
            {
                _missing++;
                Console.WriteLine("خطأ الفهرس التاريخي المتوقع في الطحن الحادي عشر");
            }
            else
                _unexpected++;
        }
        catch (Exception error)
        {
            _unexpected++;
            Console.WriteLine("استثناء غير متوقع: " + error.GetType().Name);
        }
    }

    private static void CheckContextOwnership()
    {
        var manager = new MonsterManager();
        var first = manager.ExecuteLegacyVisibleGrind(BigInteger.Zero, BigInteger.One, 1);
        var second = manager.ExecuteLegacyVisibleGrind(BigInteger.One, BigInteger.Zero, 2);
        Require(!ReferenceEquals(first, second), "استقلال السياقين");
        Require(!ReferenceEquals(first.Metrics, second.Metrics), "استقلال القياسات");
        Require(!ReferenceEquals(first.BranchTrace, second.BranchTrace), "استقلال سجل الفروع");
        Require(first.LegacyGrindOrdinal == 1 && first.LegacyGrindDirectIndex == 1,
            "احتفاظ السياق برقم الطحن والفهرس الخاطئ");
        Require(first.LegacyGrindResult == LegacyVisibleGrindTable.LegacyGrindRow(1),
            "قيمة السياق مأخوذة من الدالة القديمة فعلياً");
        Require(first.Status == "LEGACY_VISIBLE_GRIND_COMPLETE"
            && first.Phase == "LEGACY_VISIBLE_GRIND_COMPLETE", "حالة المسار المنجَز");
        Require(first.BranchTrace.SequenceEqual(
            new[] { "BOOTSTRAP_VALIDATION", "LEGACY_VISIBLE_GRIND" }),
            "أثر المسار الإنتاجي");
        Require(first.Metrics.TryGetValue("legacy.visible.grind.dispatch", out var n)
            && n == 1, "عدد إرسال المعالج");
        Require(first.LegacyPriorResult is null && first.PatchedPriorResult is null &&
            first.LegacyHiddenReversed is null && first.PatchedHiddenAccess is null,
            "لم يتداخل الطحن القديم مع نتائج المراحل السابقة");

        var dispatcher = new MonsterDispatcher(new MonsterValidationManager(),
            new MonsterMetricsManager());
        var previousResult = first.LegacyGrindResult;
        var previousTrace = first.BranchTrace.ToArray();
        var duplicateRejected = false;
        try { dispatcher.DispatchLegacyVisibleGrind(first); }
        catch (MonsterValidationException) { duplicateRejected = true; }
        Require(duplicateRejected, "رفض إرسال الطحن مرتين");
        Require(first.LegacyGrindResult == previousResult
            && first.BranchTrace.SequenceEqual(previousTrace),
            "لم يتغير السياق المكتمل عند الرفض");

        var missing = manager.Prepare(BigInteger.Zero, BigInteger.Zero);
        var missingRejected = false;
        try { dispatcher.DispatchLegacyVisibleGrind(missing); }
        catch (MonsterValidationException) { missingRejected = true; }
        Require(missingRejected && missing.LegacyGrindResult is null &&
            missing.BranchTrace.SequenceEqual(new[] { "BOOTSTRAP_VALIDATION" }),
            "رفض رقم الطحن المفقود بلا التزام");

        foreach (var invalid in new[] { 0, -1, 12, int.MaxValue })
        {
            var context = manager.Prepare(BigInteger.Zero, BigInteger.Zero);
            context.LegacyGrindOrdinal = invalid;
            var rejected = false;
            try { dispatcher.DispatchLegacyVisibleGrind(context); }
            catch (MonsterValidationException) { rejected = true; }
            Require(rejected && context.LegacyGrindResult is null &&
                context.LegacyGrindDirectIndex is null &&
                context.Status == "BOOTSTRAP_READY" &&
                context.BranchTrace.SequenceEqual(new[] { "BOOTSTRAP_VALIDATION" }),
                "رفض رقم خارج المجال دون التزام: " + invalid);
        }

        var last = manager.Prepare(BigInteger.Zero, BigInteger.Zero);
        last.LegacyGrindOrdinal = 11;
        var outOfBounds = false;
        try { dispatcher.DispatchLegacyVisibleGrind(last); }
        catch (IndexOutOfRangeException) { outOfBounds = true; }
        Require(outOfBounds && last.LegacyGrindResult is null &&
            last.LegacyGrindDirectIndex is null &&
            last.Status == "BOOTSTRAP_READY" &&
            last.BranchTrace.SequenceEqual(new[] { "BOOTSTRAP_VALIDATION" }) &&
            !last.Metrics.ContainsKey("legacy.visible.grind.dispatch"),
            "الطحن الحادي عشر يفشل في القراءة قبل أي التزام");

        // لا تسرب للبيانات رغم تكرار استعمال المدير نفسه.
        Require(second.LegacyGrindOrdinal == 2 && second.LegacyGrindDirectIndex == 2 &&
            second.LegacyGrindResult.HasValue &&
            second.Metrics["legacy.visible.grind.dispatch"] == 1,
            "لا يتسرب السياق الأول إلى السياق الثاني");
    }

    private static int Main(string[] args)
    {
        Console.OutputEncoding = System.Text.Encoding.UTF8;
        var verification = args.Length == 1 && args[0] == "--verify-expected-red";
        if (args.Length > 0 && !verification)
        {
            Console.Error.WriteLine("وسيط غير معروف.");
            return 2;
        }

        var oracle = GetNormativeRows();
        InspectPhysicalTable(oracle);

        var foundation = NormativeScroll.FoundationDay;
        var extreme = BigInteger.One << 8192;
        var pairs = new (BigInteger C, BigInteger T)[]
        {
            (foundation, foundation),
            (foundation - 1, foundation + 1),
            (foundation + 1, foundation - 1),
            (BigInteger.Zero, BigInteger.One),
            (-extreme, extreme),
            (extreme + foundation, -extreme + foundation)
        };
        foreach (var pair in pairs)
            for (var ordinal = 1; ordinal <= 11; ordinal++)
                Observe(pair.C, pair.T, ordinal, oracle);

        if (verification) CheckContextOwnership();

        Console.WriteLine("حالات القراءة: " + _cases);
        Console.WriteLine("حالات التطابق: " + _matches);
        Console.WriteLine("صفوف متأخرة بخانة: " + _shifted);
        Console.WriteLine("قراءات فهرس خارج الحدود: " + _missing);
        Console.WriteLine("مخالفات غير متوقعة: " + _unexpected);

        if (verification)
        {
            if (_cases == 66 && _matches == 0 && _shifted == 60 &&
                _missing == 6 && _unexpected == 0)
            {
                Console.WriteLine("تحقق توقيع الاكتشاف السابع: PASS؛ بقي الخطأ التاريخي الأحمر محفوظاً.");
                return 0;
            }
            Console.WriteLine("تحقق توقيع الاكتشاف السابع: FAIL");
            return 1;
        }

        return _unexpected == 0 && _shifted == 0 && _missing == 0 ? 0 : 1;
    }
}
