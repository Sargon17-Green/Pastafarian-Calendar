using System.Numerics;
using PastafarianCalendar.Monster;
using PastafarianCalendar.Stage01Tests.Normative;

namespace PastafarianCalendar.Stage18Tests;

internal static partial class Program
{
    private static void VerifyAllPermutations()
    {
        // تنفّذ الدالة القديمة ثلاث صبّات ثابتة مهما تغيرت رتبة الأوعية.
        // من مجموع 720 تبديلاً يجب أن تتطابق فقط التبديلات الستة التي تبدأ 1،2،3.
        var f = NormativeScroll.FoundationDay;
        var counts = NormativeScroll.WorkCountsFor(f,f+1);
        var bowls = NormativeScroll.InitialBowls(counts);
        var stones = NormativeScroll.BuildStones();
        var drop = NormativeScroll.Save((BigInteger.One << 8192) + 93);
        const int i = 1;
        var producer = new LegacyFixedBowlPours();
        var fixedPours = producer.PourIntoFixedIdentifiers(i,drop,bowls,stones);

        Check(bowls.Skip(1).Distinct().Count() == 6,
            "لكل وعاء قيمة مختلفة كي يظهر عيب معرّفات المواضع.");
        Check(fixedPours.Length == 7 && fixedPours[4] == 0 &&
            fixedPours[5] == 0 && fixedPours[6] == 0,
            "الصبّ القديم لا ينشئ صبّات إضافية.");

        for (var rank1 = 1; rank1 <= 720; rank1++)
        {
            var order = NormativeScroll.PermutationUnrank1(rank1);
            var agrees = true;
            for (var position = 1; position <= 3; position++)
            {
                var expected = ExpectedAliasedPour(
                    i,position,drop,bowls,stones[i],order);
                if (expected != fixedPours[position]) agrees = false;
            }

            if (agrees) _permutationMatches++;
            else _permutationDifferences++;

            Check(agrees == (
                order[0] == 1 && order[1] == 2 && order[2] == 3),
                "البصمة التاريخية للترتيب المعجمي " + rank1);
        }
    }
}
