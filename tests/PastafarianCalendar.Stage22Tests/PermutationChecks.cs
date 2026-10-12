using PastafarianCalendar.Stage01Tests.Normative;

namespace PastafarianCalendar.Stage22Tests;
internal static partial class Program
{
    private static void VerifyPermutationOverwrite()
    {
        var lastOrder=Contexts[0].LegacyOverwrittenQueryOrder!;
        for(var rank=1;rank<=720;rank++)
        {
            _permutations++;
            var actualDropOrder=NormativeScroll.PermutationUnrank1(rank);
            var corrupted=!actualDropOrder.SequenceEqual(lastOrder);
            if(corrupted)_badPermutations++;
            Check(actualDropOrder.Length==6 && actualDropOrder.Distinct().Count()==6,
                "ترتيب معياري معجمي مستقل "+rank);
        }
        Check(_badPermutations==719,
              "الحارس القديم يطمس 719 ترتيباً مختلفاً للقطرة الأخيرة");
    }
}
