using System.Numerics;
using System.Reflection;
using PastafarianCalendar.Monster;
using PastafarianCalendar.Stage01Tests.Normative;

namespace PastafarianCalendar.Stage15Tests;

internal static class Program
{
    private static int _passed, _failed, _pairs, _compared, _shifted, _oldFaults;

    private static void Check(bool condition, string name)
    {
        if (condition) { _passed++; return; }
        _failed++;
        Console.WriteLine("فشل الرقعة السابعة: " + name);
    }

    private static bool Same(LegacyGrindRow a, (int A, int B, int C, int D, int Kind) b)
        => a.A == b.A && a.B == b.B && a.C == b.C && a.D == b.D &&
           a.StoneKind == b.Kind;

    private static void VerifyTable()
    {
        // لا تُقرأ حقول المرجع الخاصة إلا في مشروع الاختبار.
        var normative = typeof(NormativeScroll).GetField("VisibleGrinds",
            BindingFlags.NonPublic | BindingFlags.Static)?.GetValue(null)
            as (int A, int B, int C, int D, int Kind)[];
        var old = typeof(LegacyVisibleGrindTable).GetField("PhysicalRows",
            BindingFlags.NonPublic | BindingFlags.Static)?.GetValue(null)
            as LegacyGrindRow[];
        var patched = typeof(SentinelVisibleGrindPatch).GetField("GRIND_TABLE_WITH_SENTINEL",
            BindingFlags.NonPublic | BindingFlags.Static)?.GetValue(null)
            as LegacyGrindRow[];
        Check(normative is { Length: 12 }, "جدول المرجع الاثنا عشري مع خانة صفر");
        Check(old is { Length: 11 }, "الجدول القديم غير معدل");
        Check(patched is { Length: 12 }, "صفّ حارس فعلي قبل الصفوف الحقيقية");
        if (normative is null || old is null || patched is null ||
            normative.Length != 12 || old.Length != 11 || patched.Length != 12)
            return;

        Check(patched[0] == SentinelVisibleGrindPatch.SENTINEL_GRIND_ROW &&
              patched[0] == default(LegacyGrindRow), "حارس الصفر لا يُحذف");

        for (var g = 1; g <= 11; g++)
        {
            var row = SentinelVisibleGrindPatch.GrindRowWithSentinel(g);
            Check(row == patched[g] && row == old[g - 1] &&
                  Same(row, normative[g]), "صفّ الطحن المرجعي ذو المعاملات الخمسة " + g);
            if (g <= 10)
            {
                var wrong = LegacyVisibleGrindTable.LegacyGrindRow(g);
                Check(wrong == old[g] && wrong != row &&
                      Same(wrong, normative[g + 1]), "بقاء انزياح الطحْن القديم " + g);
                _shifted++;
            }
            else
            {
                var fault = false;
                try { _ = LegacyVisibleGrindTable.LegacyGrindRow(11); }
                catch (IndexOutOfRangeException) { fault = true; }
                Check(fault, "بقاء استثناء الطحن الحادي عشر");
                if (fault) _oldFaults++;
            }
        }

        foreach (var invalid in new[] { -1, 0, 12, int.MaxValue })
        {
            var rejected = false;
            try { _ = SentinelVisibleGrindPatch.GrindRowWithSentinel(invalid); }
            catch (MonsterValidationException) { rejected = true; }
            Check(rejected, "حدود رتبة الطحن مع الحارس " + invalid);
        }
    }

    private static void VerifyPair(BigInteger c, BigInteger t, int sample)
    {
        var counts = NormativeScroll.WorkCountsFor(c, t);
        var hidden = NormativeScroll.BuildHiddenDrops(counts);
        var expected = NormativeScroll.BuildVisibleDrops(counts, hidden);
        var context = new MonsterManager().ExecutePatchedVisibleDrops(c, t);
        var actual = context.PatchedVisibleDrops;
        _pairs++;

        Check(actual is { Length: 47 }, "اكتمال السلسلة " + sample);
        if (actual is not { Length: 47 }) return;

        Check(actual[0] == BigInteger.Zero, "حجز فهرس الصفر " + sample);
        Check(context.Status == "VISIBLE_GRIND_SENTINEL_PATCH_COMPLETE" &&
              context.Phase == "VISIBLE_GRIND_SENTINEL_PATCH_COMPLETE",
            "التزام رقعة الطحن " + sample);
        Check(context.BranchTrace.SequenceEqual(new[] { "BOOTSTRAP_VALIDATION",
                "LEGACY_VISIBLE_GRIND_WITNESS", "VISIBLE_GRIND_SENTINEL_PATCH" }),
            "بقاء الندبة في مسار الإنتاج " + sample);
        Check(context.Metrics.TryGetValue("bootstrap.dispatch", out var bootstrap) &&
              bootstrap == 1 &&
              context.Metrics.TryGetValue("legacy.visible.grind.witness", out var scar) &&
              scar == 1 &&
              context.Metrics.TryGetValue("visible.grind.sentinel.patch", out var patched) &&
              patched == 1, "قياسات مستقلة عن معنى القطرة " + sample);
        Check(context.LegacyGrindOrdinal == 1 &&
              context.LegacyGrindResult == LegacyVisibleGrindTable.LegacyGrindRow(1),
            "الصفّ الخاطئ يبقى شاهداً في السياق " + sample);
        Check(context.PatchedCountsResult is not null &&
              context.PatchedCountsResult.Action == counts.Action &&
              context.PatchedCountsResult.Target == counts.Target &&
              context.PatchedCountsResult.Distance == counts.Distance &&
              context.PatchedCountsResult.Connection == counts.Connection &&
              context.PatchedCountsResult.Direction == counts.Direction,
            "تكافؤ العدادات السابقة " + sample);
        Check(context.LegacyHiddenReversed is { Length: 8 } &&
              context.PatchedHiddenAccess is not null &&
              context.PatchedStoneRows is { Length: 47 },
            "إعادة استخدام الطبقات السابقة " + sample);

        for (var i = 1; i <= 46; i++)
        {
            _compared++;
            Check(actual[i] == expected[i], "القطرة المرجعية " + sample + "/" + i);
            Check(actual[i] >= BigInteger.One && actual[i] <= NormativeScroll.M,
                "مجال القطرة " + sample + "/" + i);
        }
        for (var k = 1; k <= 7; k++)
            Check(context.PatchedHiddenAccess?.HiddenByNearness(k) == hidden[k],
                "القطرة المخفية المرجعية " + sample + "/" + k);

        var publicResult = CalendarDateSpaghetti.EvaluateVisibleDrops(c, t);
        Check(!ReferenceEquals(actual, publicResult) &&
              actual.SequenceEqual(publicResult),
            "استقلال المخرجات العامة " + sample);
        foreach (var i in new[] { 1, 7, 23, 46 })
            Check(CalendarDateSpaghetti.EvaluateVisibleDrop(c, t, i) == expected[i],
                "مدخل الإنتاج للقطرة المحددة " + sample + "/" + i);
    }

    private static void VerifyOwnership()
    {
        var f = NormativeScroll.FoundationDay;
        var manager = new MonsterManager();
        var first = manager.ExecutePatchedVisibleDrops(f, f + 1);
        var second = manager.ExecutePatchedVisibleDrops(f, f + 1);
        Check(!ReferenceEquals(first, second) &&
              !ReferenceEquals(first.PatchedVisibleDrops, second.PatchedVisibleDrops) &&
              !ReferenceEquals(first.LegacyHiddenReversed, second.LegacyHiddenReversed) &&
              !ReferenceEquals(first.PatchedStoneRows, second.PatchedStoneRows) &&
              !ReferenceEquals(first.Metrics, second.Metrics),
            "ملكية المخازن والسياقات");

        var untouched = (BigInteger[])second.PatchedVisibleDrops!.Clone();
        first.PatchedVisibleDrops![1] = BigInteger.Zero;
        first.LegacyHiddenReversed![1] = BigInteger.Zero;
        first.PatchedStoneRows![1][1] = BigInteger.Zero;
        Check(second.PatchedVisibleDrops!.SequenceEqual(untouched) &&
              second.LegacyHiddenReversed![1] >= 1 &&
              second.PatchedStoneRows![1][1] >= 1,
            "لا تسرب بين الاستدعاءات");

        var dispatcher = new MonsterDispatcher(new MonsterValidationManager(),
            new MonsterMetricsManager());
        var trace = second.BranchTrace.ToArray();
        var rejected = false;
        try { dispatcher.DispatchVisibleDropsPatched(second); }
        catch (MonsterValidationException) { rejected = true; }
        Check(rejected && second.BranchTrace.SequenceEqual(trace) &&
              second.PatchedVisibleDrops!.SequenceEqual(untouched),
            "رفض إعادة إرسال رقعة مكتملة دون كتابة");

        var newContext = new MonsterContext(f, f + 1);
        rejected = false;
        try { dispatcher.DispatchVisibleDropsPatched(newContext); }
        catch (MonsterValidationException) { rejected = true; }
        Check(rejected && newContext.Status == "NEW" &&
              newContext.PatchedVisibleDrops is null &&
              newContext.BranchTrace.Count == 0, "رفض سياق لم يؤسس");

        var occupied = manager.Prepare(f, f);
        occupied.LegacyGrindOrdinal = 1;
        trace = occupied.BranchTrace.ToArray();
        rejected = false;
        try { dispatcher.DispatchVisibleDropsPatched(occupied); }
        catch (MonsterValidationException) { rejected = true; }
        Check(rejected && occupied.PatchedVisibleDrops is null &&
              occupied.Status == "BOOTSTRAP_READY" &&
              occupied.BranchTrace.SequenceEqual(trace),
            "رفض حالة مشغولة دون التزام");

        foreach (var i in new[] { 0, -1, 47, int.MaxValue })
        {
            rejected = false;
            try { _ = CalendarDateSpaghetti.EvaluateVisibleDrop(f, f, i); }
            catch (MonsterValidationException) { rejected = true; }
            Check(rejected, "رفض رقم قطرة خارج المجال " + i);
        }
    }

    private static int Main()
    {
        Console.OutputEncoding = System.Text.Encoding.UTF8;
        VerifyTable();
        var f = NormativeScroll.FoundationDay;
        var huge = BigInteger.One << 8192;
        var pairs = new (BigInteger C, BigInteger T)[]
        {
            (f,f), (f-1,f+1), (f+1,f-1), (f-7,f+7),
            (BigInteger.Zero,BigInteger.One), (BigInteger.One,BigInteger.Zero),
            (new BigInteger(-278522),f), (f,new BigInteger(-278522)),
            (huge,-huge), (-huge,huge),
            (huge+f,-huge+f), (-huge-f,huge+f)
        };
        for (var p = 0; p < pairs.Length; p++)
            VerifyPair(pairs[p].C, pairs[p].T, p + 1);
        VerifyOwnership();

        Console.WriteLine("أزواج الأيام المفحوصة: " + _pairs);
        Console.WriteLine("القطرات الظاهرة المقارنة: " + _compared);
        Console.WriteLine("انزياحات القارئ التاريخي: " + _shifted);
        Console.WriteLine("استثناء الفهرسة المحفوظ: " + _oldFaults);
        Console.WriteLine("اختبارات الرقعة السابعة الناجحة: " + _passed);
        Console.WriteLine("اختبارات الرقعة السابعة الفاشلة: " + _failed);
        return _failed == 0 && _pairs == 12 && _compared == 552 &&
               _shifted == 10 && _oldFaults == 1 ? 0 : 1;
    }
}
