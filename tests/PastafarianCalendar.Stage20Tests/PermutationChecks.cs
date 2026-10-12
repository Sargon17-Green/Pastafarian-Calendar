using System.Numerics;
using PastafarianCalendar.Monster;
using PastafarianCalendar.Stage01Tests.Normative;

namespace PastafarianCalendar.Stage20Tests;

internal static partial class Program
{
    private static void VerifyPermutations()
    {
        var f=NormativeScroll.FoundationDay;
        var counts=NormativeScroll.WorkCountsFor(f,f+1);
        var initial=NormativeScroll.InitialBowls(counts);
        var stones=NormativeScroll.BuildStones();
        var drop=NormativeScroll.Save((BigInteger.One<<8192)+93);
        var alias=new BowlAliasPatchWrapper();
        var old=new LegacyInPlaceBowlStir();

        for(var rank=1;rank<=720;rank++)
        {
            _permutationSamples++;
            var order=NormativeScroll.PermutationUnrank1(rank);
            var mapping=alias.InstallOrderAliases(order);
            var pours=alias.PatchedPours(1,drop,stones,initial,mapping);
            var mutated=(BigInteger[])initial.Clone();
            old.StirDirectlyIntoBowls(mutated,1,drop,stones,order,pours);
            var expected=NormativeSingleDropStir(
                initial,1,drop,stones,order,pours);
            Check(mutated[0]==0 && mutated.Length==7,
                "الصبّ القديم لا يغيّر خانة الصفر "+rank);
            Check(mutated[order[0]]==expected[order[0]],
                "التحريك التاريخي الأول قبل التلوث "+rank);
            Check(initial[0]==0 && initial.Skip(1).All(x=>x>=1),
                "مصنع الأوعية الأولية مستقل عن التحوير "+rank);

            if(!mutated.SequenceEqual(expected))_permutationDivergences++;
            for(var position=1;position<=6;position++)
                Check(mutated[order[position-1]]>=1 &&
                    mutated[order[position-1]]<=NormativeScroll.M,
                    "جميع القيم القديمة محفوظة مع فسادها الدلالي "+rank);
        }
    }
}
