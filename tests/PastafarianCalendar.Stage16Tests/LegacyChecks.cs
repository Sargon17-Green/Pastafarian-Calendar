using System.Numerics;
using PastafarianCalendar.Monster;

namespace PastafarianCalendar.Stage16Tests;

internal static partial class Program
{
    private static void VerifyZeroBasedUnrank()
    {
        Check(All.Count == 720,"عدد التباديل المستقلة");
        for (var rank0 = 0; rank0 < 720; rank0++)
            Check(LegacyBowlPermutation.OldPermutationUnrank0(rank0)
                .SequenceEqual(All[rank0]),"المفكك الصفري " + rank0);

        foreach (var bad in new[] {-1,720,int.MaxValue})
        {
            var threw = false;
            try { _ = LegacyBowlPermutation.OldPermutationUnrank0(bad); }
            catch (ArgumentOutOfRangeException) { threw = true; }
            Check(threw,"رفض رتبة صفرية خارجة عن المجال");
        }
    }

    private static void VerifyContextOwnership()
    {
        var manager = new MonsterManager();
        var first = manager.ExecuteLegacyBowlOrder(0,1,1);
        var second = manager.ExecuteLegacyBowlOrder(1,0,2);
        Check(!ReferenceEquals(first,second) &&
            !ReferenceEquals(first.LegacyBowlOrderResult,second.LegacyBowlOrderResult) &&
            !ReferenceEquals(first.Metrics,second.Metrics) &&
            !ReferenceEquals(first.BranchTrace,second.BranchTrace),
            "لا تشارك للمصفوفات والسياقات والقياسات");

        var before = (int[])second.LegacyBowlOrderResult!.Clone();
        first.LegacyBowlOrderResult![0] = -99;
        Check(second.LegacyBowlOrderResult!.SequenceEqual(before),
            "لا تنتقل الكتابة بين الاستدعاءات");

        var dispatcher = new MonsterDispatcher(new MonsterValidationManager(),
            new MonsterMetricsManager());
        var trace = second.BranchTrace.ToArray();
        var refused = false;
        try { dispatcher.DispatchLegacyBowlOrder(second); }
        catch (MonsterValidationException) { refused = true; }
        Check(refused && second.LegacyBowlOrderResult!.SequenceEqual(before) &&
              second.BranchTrace.SequenceEqual(trace) &&
              second.Metrics["legacy.bowl.permutation.dispatch"] == 1,
            "منع إعادة الإرسال بعد اكتمال القراءة");

        var missing = manager.Prepare(0,0);
        refused = false;
        try { dispatcher.DispatchLegacyBowlOrder(missing); }
        catch (MonsterValidationException) { refused = true; }
        Check(refused && missing.Status == "BOOTSTRAP_READY" &&
              missing.LegacyBowlOrderResult is null &&
              missing.BranchTrace.SequenceEqual(new[] {"BOOTSTRAP_VALIDATION"}),
            "رفض قيمة قطرة مفقودة");

        var unprepared = new MonsterContext(0,0) { LegacyBowlOrderInput=2 };
        refused = false;
        try { dispatcher.DispatchLegacyBowlOrder(unprepared); }
        catch (MonsterValidationException) { refused = true; }
        Check(refused && unprepared.Status == "NEW" &&
              unprepared.BranchTrace.Count == 0,
            "رفض سياق غير مؤسس");

        var last = manager.Prepare(0,0);
        last.LegacyBowlOrderInput = 720;
        var failed = false;
        try { dispatcher.DispatchLegacyBowlOrder(last); }
        catch (ArgumentOutOfRangeException) { failed = true; }
        Check(failed && last.LegacyBowlOrderResult is null &&
              last.LegacyBowlOneBasedRank is null &&
              last.Status == "BOOTSTRAP_READY" &&
              last.Phase == "BOOTSTRAP_READY" &&
              last.BranchTrace.SequenceEqual(new[] {"BOOTSTRAP_VALIDATION"}) &&
              !last.Metrics.ContainsKey("legacy.bowl.permutation.dispatch"),
            "الفشل الأخير لا يثبت حالة جزئية");
    }
}
