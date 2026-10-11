using System.Numerics;
using PastafarianCalendar.Monster;
using PastafarianCalendar.Stage01Tests.Normative;

namespace PastafarianCalendar.Stage08Tests;

internal static class Program
{
    private static int _matched;
    private static int _diverged;
    private static int _unexpected;
    private static int _compared;

    private static void Require(bool condition, string description)
    {
        if (condition) return;
        _unexpected++;
        Console.WriteLine("مخالفة غير متوقعة: " + description);
    }

    private static void VerifyHistoricalRows()
    {
        var canonical = NormativeScroll.BuildStones();
        var actual = CalendarDateSpaghetti.EvaluateLegacyStones(
            NormativeScroll.FoundationDay,
            NormativeScroll.FoundationDay + BigInteger.One);

        Require(actual.Length == 47, "عدد صفوف الأحجار التاريخية");
        var initial = LegacyStones.InitialStones();
        Require(initial.SequenceEqual(canonical[1]), "الأحجار الخمسة الأولية");

        for (var row = 1; row <= 46; row++)
        {
            Require(actual[row] is not null && actual[row].Length == 6,
                "شكل صف الأحجار " + row);
            for (var kind = 1; kind <= 5; kind++)
            {
                var differs = actual[row][kind] != canonical[row][kind];
                _compared++;
                if (differs) _diverged++; else _matched++;

                // الصف الأول صحيح، وفي الصف الثاني يصح الحجر الأول وحده.
                // جميع النتائج الباقية تتباعد لأن التحديث المتسلسل يقرأ القيم المستبدلة.
                var expectedDivergence = row >= 3 || (row == 2 && kind > 1);
                Require(differs == expectedDivergence,
                    "توقيع الصف " + row + " والحجر " + kind);
                Require(actual[row][kind] >= BigInteger.One &&
                    actual[row][kind] <= NormativeScroll.M,
                    "المدى الصحيح رغم خطأ القيمة " + row + "/" + kind);
            }
        }

        // نختبر التكرار الصفّي للفعل القديم باستعمال نسخ مستقلة فقط.
        var work = LegacyStones.InitialStones();
        for (var row = 2; row <= 46; row++)
        {
            var alias = LegacyStones.MutateStonesWrong(row, work);
            Require(ReferenceEquals(alias, work), "بقاء طفرة المصفوفة في موضعها " + row);
            Require(work.SequenceEqual(actual[row]), "تعاقب التحديث التاريخي " + row);
            Require(!ReferenceEquals(actual[row], actual[row - 1]),
                "كل صف محفوظ نسخة مستقلة " + row);
        }

        Console.WriteLine("خانات الأحجار المفحوصة: " + _compared);
        Console.WriteLine("خانات الأحجار المطابقة: " + _matched);
        Console.WriteLine("خانات الأحجار المختلفة: " + _diverged);
    }

    private static void VerifyMutationAndOwnership()
    {
        var canonical = NormativeScroll.BuildStones();
        var original = LegacyStones.InitialStones();
        var changed = (BigInteger[])original.Clone();
        var observed = LegacyStones.MutateStonesWrong(2, changed);
        Require(ReferenceEquals(observed, changed), "إرجاع هوية المصفوفة المطعّمة");
        Require(original.SequenceEqual(canonical[1]), "عدم مساس النسخة المدخلة الأصلية");
        Require(changed[1] == canonical[2][1], "الحجر الأول صحيح رغم التحوير");
        for (var k = 2; k <= 5; k++)
            Require(changed[k] != canonical[2][k], "الحجر " + k + " يستعمل قيمة جديدة");

        var rejectedRow = (BigInteger[])original.Clone();
        var rejected = false;
        try { LegacyStones.MutateStonesWrong(1, rejectedRow); }
        catch (MonsterValidationException) { rejected = true; }
        Require(rejected && rejectedRow.SequenceEqual(original),
            "رفض دورة غير صالحة قبل الطفرة");

        rejected = false;
        try { LegacyStones.MutateStonesWrong(2, new BigInteger[5]); }
        catch (MonsterValidationException) { rejected = true; }
        Require(rejected, "رفض غياب الفهرس السادس قبل الطفرة");

        // الأعداد الكبيرة تكشف فقدان الدقة لو استُخدمت أعداد عائمة.
        var huge = BigInteger.One << 4096;
        var enormous = new[] { BigInteger.Zero, huge, huge + 1, huge + 2, huge + 3, huge + 4 };
        var prior = (BigInteger[])enormous.Clone();
        LegacyStones.MutateStonesWrong(3, enormous);
        var expectedWheat = NormativeScroll.Save(prior[1] * prior[1] + 3 * prior[2] + 3);
        Require(enormous[1] == expectedWheat, "باقي الحفظ الصحيح للأعداد الهائلة");
        var expectedBarley = NormativeScroll.Save(prior[2] * prior[2] + 5 * prior[3] + enormous[1]);
        Require(enormous[2] == expectedBarley, "استخدام الحجر الأول المحدّث مع الأعداد الهائلة");
        for (var kind = 1; kind <= 5; kind++)
            Require(enormous[kind] >= 1 && enormous[kind] <= NormativeScroll.M,
                "تحديد المجال بعد حساب آلاف البتات " + kind);

        var manager = new MonsterManager();
        var first = manager.ExecuteLegacyStones(BigInteger.Zero, BigInteger.One);
        var second = manager.ExecuteLegacyStones(BigInteger.One, BigInteger.Zero);
        Require(!ReferenceEquals(first, second), "ملكية سياق كل استدعاء");
        Require(!ReferenceEquals(first.Metrics, second.Metrics), "ملكية القياسات");
        Require(!ReferenceEquals(first.BranchTrace, second.BranchTrace), "ملكية أثر الفروع");
        Require(!ReferenceEquals(first.LegacyStoneRows, second.LegacyStoneRows), "ملكية مصفوفات الصفوف");
        Require(!ReferenceEquals(first.LegacyStoneRows![24], second.LegacyStoneRows![24]),
            "الملكية العميقة للصفوف المحفوظة");
        Require(first.LegacyStoneRows![46].SequenceEqual(second.LegacyStoneRows![46]),
            "حياد النتائج عن عمر المدير وترتيب الاستدعاءات");
        Require(first.Status == "LEGACY_STONES_COMPLETE" &&
            first.Phase == "LEGACY_STONES_COMPLETE", "حالة الاكتمال التاريخي");
        Require(first.BranchTrace.SequenceEqual(
            new[] { "BOOTSTRAP_VALIDATION", "LEGACY_STONES_MUTATION" }),
            "مسار بناء الأحجار القديم");
        Require(first.Metrics.TryGetValue("legacy.stones.mutation.dispatch", out var calls)
            && calls == 1, "قياس الاستدعاء الواحد");
        Require(first.PatchedCountsResult is null && first.LegacyDistanceResult is null &&
            first.PatchedSaveResult is null, "عدم تغيير الحالة الدلالية للمراحل السابقة");

        var preserved = (BigInteger[])first.LegacyStoneRows![32].Clone();
        first.LegacyStoneRows[8][2] = BigInteger.One;
        Require(second.LegacyStoneRows![8][2] != first.LegacyStoneRows[8][2],
            "عدم تسريب الكتابة في سياق إلى سياق ثانٍ");
        Require(first.LegacyStoneRows[32].SequenceEqual(preserved),
            "عدم تسرب التعديل من صف إلى صف آخر");

        var dispatcher = new MonsterDispatcher(new MonsterValidationManager(),
            new MonsterMetricsManager());
        var trace = first.BranchTrace.ToArray();
        rejected = false;
        try { dispatcher.DispatchLegacyStones(first); }
        catch (MonsterValidationException) { rejected = true; }
        Require(rejected && first.BranchTrace.SequenceEqual(trace)
            && first.Metrics["legacy.stones.mutation.dispatch"] == 1,
            "رفض إعادة الإرسال دون إفساد السياق");

        var unprepared = new MonsterContext(BigInteger.Zero, BigInteger.Zero);
        rejected = false;
        try { dispatcher.DispatchLegacyStones(unprepared); }
        catch (MonsterValidationException) { rejected = true; }
        Require(rejected && unprepared.Status == "NEW" &&
            unprepared.BranchTrace.Count == 0 && unprepared.LegacyStoneRows is null,
            "رفض استدعاء غير مؤسس دون أي التزام");

        var futurePatchType = typeof(LegacyStones).Assembly.GetType(
            "PastafarianCalendar.Monster.StonePatch");
        Require(futurePatchType is null, "غياب غلاف التصحيح الذي ينتمي للطور التاسع");
    }

    private static int Main(string[] args)
    {
        Console.OutputEncoding = System.Text.Encoding.UTF8;
        var verify = args.Length == 1 && args[0] == "--verify-expected-red";
        if (args.Length != 0 && !verify)
        {
            Console.Error.WriteLine("وسيط اختبار مجهول.");
            return 2;
        }

        VerifyHistoricalRows();
        if (verify) VerifyMutationAndOwnership();

        Console.WriteLine("مخالفات التوقيع أو الملكية: " + _unexpected);
        if (!verify)
            return _unexpected == 0 && _diverged > 0 ? 1 : 2;

        if (_compared == 230 && _matched == 6 && _diverged == 224 && _unexpected == 0)
        {
            Console.WriteLine("توقيع الاكتشاف الرابع: PASS؛ بقي التحوير الخاطئ فاعلاً دون أي رقعة.");
            return 0;
        }

        Console.WriteLine("توقيع الاكتشاف الرابع: FAIL");
        return 1;
    }
}
