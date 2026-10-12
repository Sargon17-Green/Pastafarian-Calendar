using PastafarianCalendar.Stage01Tests.Normative;
namespace PastafarianCalendar.Stage23Tests;

internal static partial class Program
{
    private static void CheckAllRankChoices()
    {
        var oldLast=Contexts[0].LegacyOverwrittenQueryOrder!;
        var latch=Contexts[0].PatchedOrderAt46Latch!;
        for(var rank=1;rank<=720;rank++)
        {
            _permutations++;
            var hypotheticalDrop46=NormativeScroll.PermutationUnrank1(rank);
            if(!hypotheticalDrop46.SequenceEqual(oldLast))_historicalRankDifferences++;
            Check(hypotheticalDrop46.Length==6 &&
                  hypotheticalDrop46.Distinct().Count()==6 &&
                  hypotheticalDrop46.All(x=>x is >=1 and <=6),
                  "قابلية حفظ أي ترتيب قطرة من 720 رتبة "+rank);
        }
        Check(_historicalRankDifferences==719 &&
              latch.SequenceEqual(Contexts[0].LegacyDiagnosticDrop46Order) &&
              !latch.SequenceEqual(oldLast),
              "فقدان 719 ترتيباً نتيجة استعمال ترتيب التحريك الأخير");
    }
}
