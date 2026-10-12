using System.Numerics;
using PastafarianCalendar.Monster;
using PastafarianCalendar.Stage01Tests.Normative;

namespace PastafarianCalendar.Stage18Tests;

internal static partial class Program
{
    private static int _unexpected;
    private static int _cases;
    private static int _divergences;
    private static int _completeMatches;
    private static int _positionDifferences;
    private static int _assertions;
    private static int _permutationMatches;
    private static int _permutationDifferences;

    private static void Check(bool condition, string label)
    {
        if (condition) { _assertions++; return; }
        _unexpected++;
        Console.WriteLine("مخالفة غير متوقعة: " + label);
    }

    // المرجع يربط كل موضع بالهوية الواقعة فيه، لا بالرقم الثابت للوعاء.
    private static BigInteger ExpectedAliasedPour(
        int i, int position, BigInteger drop, BigInteger[] bowls,
        BigInteger[] stoneRow, int[] order)
    {
        var multipliers = new[] {0,3,5,7};
        return NormativeScroll.Save(
            drop * drop + stoneRow[position] * bowls[order[position - 1]] +
            multipliers[position] * i);
    }

    private static void ObservePair(BigInteger c, BigInteger t, int sample)
    {
        var counts = NormativeScroll.WorkCountsFor(c,t);
        var hidden = NormativeScroll.BuildHiddenDrops(counts);
        var visible = NormativeScroll.BuildVisibleDrops(counts,hidden);
        var stones = NormativeScroll.BuildStones();
        var bowls = NormativeScroll.InitialBowls(counts);
        var manager = new MonsterManager();

        for (var i = 1; i <= 46; i++)
        {
            _cases++;
            var context = manager.ExecuteLegacyFixedBowlPours(c,t,i);
            var order = NormativeScroll.BowlOrderFromDrop(visible[i]);
            var old = context.LegacyPoursResult;
            Check(old is { Length: 7 },"مصفوفة الصبّ التاريخي " + sample + "/" + i);
            if (old is not { Length: 7 }) continue;

            Check(context.Status == "LEGACY_FIXED_BOWL_POURS_COMPLETE" &&
                context.Phase == "LEGACY_FIXED_BOWL_POURS_COMPLETE" &&
                context.BranchTrace.SequenceEqual(new[]
                { "BOOTSTRAP_VALIDATION", "LEGACY_FIXED_BOWL_POURS" }) &&
                context.Metrics["legacy.fixed.bowl.pours.dispatch"] == 1,
                "المسار الإنتاجي الكامل " + sample + "/" + i);
            Check(context.LegacyPourVisibleIndex == i &&
                context.LegacyPourDrop == visible[i] &&
                context.LegacyPourOrder is not null &&
                context.LegacyPourOrder.SequenceEqual(order) &&
                context.LegacyPourInitialBowls is not null &&
                context.LegacyPourInitialBowls.SequenceEqual(bowls),
                "المصدر الصحيح للترتيب والأوعية الأولية " + sample + "/" + i);
            Check(context.PatchedVisibleDrops is {Length:47} &&
                context.PatchedVisibleDrops.SequenceEqual(visible) &&
                context.PatchedStoneRows is {Length:47} &&
                context.LegacyHiddenReversed is {Length:8},
                "حساب قطرات الإنتاج والأحجار قبل الصبّ " + sample + "/" + i);
            Check(old[0] == 0 && old[4] == 0 && old[5] == 0 && old[6] == 0,
                "لا يُصبّ سوى ثلاث كميات في المرحلة التاريخية");

            var differs = false;
            for (var position = 1; position <= 3; position++)
            {
                var coefficient = position == 1 ? 3 : position == 2 ? 5 : 7;
                var expectedOld = NormativeScroll.Save(
                    visible[i] * visible[i] +
                    stones[i][position] * bowls[position] + coefficient * i);
                var expectedNew = ExpectedAliasedPour(
                    i,position,visible[i],bowls,stones[i],order);
                Check(old[position] == expectedOld,
                    "الصبّ القديم مطابق تماماً لهوية الوعاء الثابتة " + sample + "/" + i + "/" + position);
                Check(old[position] >= 1 && old[position] <= NormativeScroll.M,
                    "قيم الصبّ المحفوظة " + sample + "/" + i + "/" + position);
                if (old[position] != expectedNew)
                {
                    _positionDifferences++;
                    differs = true;
                    Check(order[position-1] != position,
                        "المخالفة لا تحدث إذا طابق الموضع هويته");
                }
                else
                    Check(expectedOld == expectedNew,
                        "المطابقة لا تخفي انزياحاً إضافياً");
            }

            if (differs) _divergences++;
            else _completeMatches++;
        }
    }

    private static int Main(string[] args)
    {
        Console.OutputEncoding = System.Text.Encoding.UTF8;
        var verify = args.Length == 1 && args[0] == "--verify-expected-red";
        if (args.Length > 0 && !verify) return 2;

        var f = NormativeScroll.FoundationDay;
        var huge = BigInteger.One << 8192;
        var cases = new (BigInteger C,BigInteger T)[]
        {
            (f,f), (f-1,f+1), (f+1,f-1), (0,1),
            (1,0), (new BigInteger(-278522),f),
            (huge,-huge), (-huge+f,huge+f)
        };
        for (var k = 0; k < cases.Length; k++)
            ObservePair(cases[k].C,cases[k].T,k+1);

        VerifyAllPermutations();
        if (verify) VerifyContextAndRejection();

        Console.WriteLine("حالات القطرة الإنتاجية: " + _cases);
        Console.WriteLine("مزائج مختلفة بسبب هوية الوعاء: " + _divergences);
        Console.WriteLine("مزائج متطابقة: " + _completeMatches);
        Console.WriteLine("مواضع الصبّ المختلفة: " + _positionDifferences);
        Console.WriteLine("التباديل المتطابقة تماماً: " + _permutationMatches);
        Console.WriteLine("التباديل المختلفة: " + _permutationDifferences);
        Console.WriteLine("التحققات الناجحة: " + _assertions);
        Console.WriteLine("مخالفات غير متوقعة: " + _unexpected);

        if (verify)
        {
            var ok = _unexpected == 0 && _cases == 368 &&
                _divergences > 250 &&
                _completeMatches + _divergences == 368 &&
                _positionDifferences > 400 &&
                _permutationMatches == 6 &&
                _permutationDifferences == 714;
            Console.WriteLine("توقيع اكتشاف الصبّ الثابت التاسع: " + (ok ? "PASS" : "FAIL"));
            return ok ? 0 : 1;
        }
        return _unexpected == 0 && _divergences == 0 ? 0 : 1;
    }
}
