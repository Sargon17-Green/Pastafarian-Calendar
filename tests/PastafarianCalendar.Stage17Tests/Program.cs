using System.Numerics;
using PastafarianCalendar.Monster;
using PastafarianCalendar.Stage01Tests.Normative;

namespace PastafarianCalendar.Stage17Tests;

internal static partial class Program
{
    private static int _passed;
    private static int _failed;
    private static int _ranks;
    private static int _oldShifted;
    private static int _oldFaults;
    private static int _visibleValues;
    private static int _visibleLinked;
    private static int _pairs;

    private static void Check(bool yes, string label)
    {
        if (yes) { _passed++; return; }
        _failed++;
        Console.WriteLine("فشل الرقعة الثامنة: " + label);
    }

    private static void CheckRank(BigInteger drop, int rank1)
    {
        var wrapper = new BowlOrderPatchWrapper();
        var result = wrapper.OrderPatchFromValue(drop);
        var expected = NormativeScroll.PermutationUnrank1(rank1);
        var context = new MonsterManager().ExecutePatchedBowlOrder(0, 1, drop);
        _ranks++;

        Check(result.OneBased == rank1 && result.LegacyRank0 == rank1 - 1 &&
              result.Order.SequenceEqual(expected),
              "سلسلة الرتبة الواحدية والصفرية " + rank1);
        Check(context.PatchedBowlOneBasedRank == rank1 &&
              context.PatchedBowlLegacyRank0 == rank1 - 1 &&
              context.PatchedBowlOrderResult is not null &&
              context.PatchedBowlOrderResult.SequenceEqual(expected) &&
              !ReferenceEquals(context.PatchedBowlOrderResult, context.LegacyBowlOrderResult),
              "الترتيب المصحح المنفصل " + rank1);
        Check(context.Status == "BOWL_ORDER_PATCH_COMPLETE" &&
              context.Phase == "BOWL_ORDER_PATCH_COMPLETE" &&
              context.LegacyBowlOrderInput == drop &&
              context.Metrics.TryGetValue("bowl.order.patch.dispatch", out var n) && n == 1,
              "التزام السياق والقياس " + rank1);

        if (rank1 < 720)
        {
            _oldShifted++;
            Check(!context.LegacyBowlRankOutOfRange &&
                context.LegacyBowlOneBasedRank == rank1 &&
                context.LegacyBowlOrderResult is not null &&
                context.LegacyBowlOrderResult.SequenceEqual(
                    NormativeScroll.PermutationUnrank1(rank1 + 1)) &&
                !context.LegacyBowlOrderResult.SequenceEqual(expected),
                "استمرار الإزاحة التاريخية " + rank1);
            Check(context.BranchTrace.SequenceEqual(new[]
                    { "BOOTSTRAP_VALIDATION",
                      "LEGACY_BOWL_PERMUTATION_WITNESS", "BOWL_ORDER_PATCH" }) &&
                  context.Metrics.TryGetValue("legacy.bowl.permutation.witness", out var witness) &&
                  witness == 1,
                "شهادة المعالج التاريخي الصحيح في خطئه " + rank1);
        }
        else
        {
            _oldFaults++;
            Check(context.LegacyBowlRankOutOfRange &&
                  context.LegacyBowlOneBasedRank == 720 &&
                  context.LegacyBowlOrderResult is null &&
                  context.PatchedBowlOrderResult is not null &&
                  context.PatchedBowlOrderResult.SequenceEqual(
                      NormativeScroll.PermutationUnrank1(720)),
                "تحويل استثناء 720 إلى ترتيب مرجعي صحيح");
            Check(context.BranchTrace.SequenceEqual(new[]
                    { "BOOTSTRAP_VALIDATION",
                      "LEGACY_BOWL_PERMUTATION_RANGE_WITNESS", "BOWL_ORDER_PATCH" }) &&
                  context.Metrics.TryGetValue(
                      "legacy.bowl.permutation.range.witness", out var fault) &&
                  fault == 1,
                "شهادة الاستثناء التاريخي دون تعطيل الرقعة");
        }
    }

    private static int Main()
    {
        Console.OutputEncoding = System.Text.Encoding.UTF8;
        var huge = BigInteger.One << 8192;
        var offsets = new BigInteger[] { 0, 1, -1, 720, huge, -huge };
        foreach (var offset in offsets)
            for (var rank = 1; rank <= 720; rank++)
                CheckRank(rank + 720 * offset, rank);

        VerifyRealVisibleDrops();
        VerifyOwnershipAndValidation();

        Console.WriteLine("الرتب المفحوصة: " + _ranks);
        Console.WriteLine("انزياحات القديم المحفوظة: " + _oldShifted);
        Console.WriteLine("استثناءات القديم المحفوظة: " + _oldFaults);
        Console.WriteLine("القطرات المربوطة بالطبقات الفعلية: " + _visibleValues);
        Console.WriteLine("طلبات القراءة العامة من القطرة: " + _visibleLinked);
        Console.WriteLine("أزواج الأيام: " + _pairs);
        Console.WriteLine("الاختبارات الناجحة: " + _passed);
        Console.WriteLine("الاختبارات الفاشلة: " + _failed);
        return _failed == 0 && _ranks == 4320 &&
               _oldShifted == 4314 && _oldFaults == 6 &&
               _visibleValues == 368 && _visibleLinked == 32 && _pairs == 8 ? 0 : 1;
    }
}
