using System.Numerics;
using PastafarianCalendar.Monster;
using PastafarianCalendar.Stage01Tests.Normative;

namespace PastafarianCalendar.Stage17Tests;

internal static partial class Program
{
    private static void VerifyRealVisibleDrops()
    {
        var foundation = NormativeScroll.FoundationDay;
        var huge = BigInteger.One << 8192;
        var samples = new (BigInteger C, BigInteger T)[]
        {
            (foundation, foundation), (foundation-1, foundation+1),
            (foundation+7, foundation-7), (BigInteger.Zero, BigInteger.One),
            (BigInteger.One, BigInteger.Zero), (huge, -huge),
            (-huge, huge), (huge+foundation, -huge+foundation)
        };
        foreach (var (c,t) in samples)
        {
            _pairs++;
            var counts = NormativeScroll.WorkCountsFor(c,t);
            var hidden = NormativeScroll.BuildHiddenDrops(counts);
            var normativeVisible = NormativeScroll.BuildVisibleDrops(counts,hidden);
            var produced = CalendarDateSpaghetti.EvaluateVisibleDrops(c,t);
            Check(produced is { Length: 47 } &&
                  produced.SequenceEqual(normativeVisible),
                  "القطرات الظاهرة تأتي من مسار الإنتاج الصحيح");

            for (var i = 1; i <= 46; i++)
            {
                _visibleValues++;
                var result = new MonsterManager().ExecutePatchedBowlOrder(c,t,produced[i]);
                var oracle = NormativeScroll.BowlOrderFromDrop(normativeVisible[i]);
                var rank1 = (int)NormativeScroll.RegularMod(normativeVisible[i]-1,720)+1;
                Check(result.PatchedBowlOrderResult is not null &&
                      result.PatchedBowlOrderResult.SequenceEqual(oracle) &&
                      result.PatchedBowlOneBasedRank == rank1 &&
                      result.PatchedBowlLegacyRank0 == rank1-1,
                      "ترتيب القطرة المنتجة " + i);
                Check(result.LegacyBowlRankOutOfRange == (rank1 == 720) &&
                      (rank1 == 720
                          ? result.LegacyBowlOrderResult is null
                          : result.LegacyBowlOrderResult is not null &&
                            result.LegacyBowlOrderResult.SequenceEqual(
                                NormativeScroll.PermutationUnrank1(rank1+1))),
                      "الأثر التاريخي للقطرة المنتجة " + i);
            }

            foreach (var index in new[] {1,7,23,46})
            {
                _visibleLinked++;
                var context = new MonsterManager()
                    .ExecutePatchedBowlOrderFromVisibleDrop(c,t,index);
                var expected = NormativeScroll.BowlOrderFromDrop(normativeVisible[index]);
                var exposed = CalendarDateSpaghetti.EvaluateBowlOrderFromVisibleDrop(c,t,index);
                Check(context.LegacyBowlVisibleIndex == index &&
                      context.LegacyBowlOrderInput == produced[index] &&
                      context.PatchedBowlOrderResult is not null &&
                      context.PatchedBowlOrderResult.SequenceEqual(expected) &&
                      exposed.SequenceEqual(expected),
                      "مدخل ترتيب القطرة الظاهرة الفعلي " + index);
                Check(!ReferenceEquals(context.PatchedBowlOrderResult,exposed),
                      "ملكية مستقلة بين كل استدعاء من المدخل العام");
            }
        }
    }
}
