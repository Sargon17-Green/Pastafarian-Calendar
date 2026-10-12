using System.Numerics;
using PastafarianCalendar.Monster;
using PastafarianCalendar.Stage01Tests.Normative;

namespace PastafarianCalendar.Stage21Tests;

internal static partial class Program
{
    private static void VerifyAllPermutations()
    {
        var f=NormativeScroll.FoundationDay;
        var counts=NormativeScroll.WorkCountsFor(f,f+1);
        var bowls=NormativeScroll.InitialBowls(counts);
        var stones=NormativeScroll.BuildStones();
        var drop=NormativeScroll.Save((BigInteger.One<<8192)+93);
        var wrapper=new ShadowBowlStirPatch();
        var old=new LegacyInPlaceBowlStir();
        var alias=new BowlAliasPatchWrapper();

        for(var rank=1;rank<=720;rank++)
        {
            _permutations++;
            var order=NormativeScroll.PermutationUnrank1(rank);
            var mapping=alias.InstallOrderAliases(order);
            var pours=alias.PatchedPours(1,drop,stones,bowls,mapping);
            var oldLive=(BigInteger[])bowls.Clone();
            old.StirDirectlyIntoBowls(oldLive,1,drop,stones,order,pours);

            var live=(BigInteger[])bowls.Clone();
            var result=wrapper.StirOneDropViaShadow(
                live,1,drop,stones,order,pours);
            var expected=NormativeStir(bowls,1,drop,stones,order,pours);
            Check(result.VaultOld.SequenceEqual(bowls) &&
                  result.Pending.SequenceEqual(expected) &&
                  result.Committed.SequenceEqual(expected) &&
                  live.SequenceEqual(expected),
                "محاكاة كاملة لكل تبديل معجمي "+rank);
            Check(!ReferenceEquals(live,bowls) &&
                  !ReferenceEquals(result.VaultOld,result.Pending) &&
                  !ReferenceEquals(result.Committed,result.Pending) &&
                  !ReferenceEquals(result.Committed,result.VaultOld),
                "مخازن منفصلة ومستقلة لكل تبديل "+rank);
            Check(live[order[0]]==oldLive[order[0]],
                "الكتابة الأولى في القديم توافق الرقعة "+rank);
            if(!oldLive.SequenceEqual(expected))_permutationDifferences++;
            for(var id=1;id<=6;id++)
                Check(live[id]>=1 && live[id]<=NormativeScroll.M,
                    "حفظ كافة الأوعية بعد الالتزام "+rank+"/"+id);
        }
    }
}
