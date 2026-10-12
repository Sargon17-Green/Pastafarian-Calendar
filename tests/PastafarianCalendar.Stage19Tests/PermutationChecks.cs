using System.Numerics;
using PastafarianCalendar.Monster;
using PastafarianCalendar.Stage01Tests.Normative;

namespace PastafarianCalendar.Stage19Tests;

internal static partial class Program
{
    private static void CheckAllPermutations()
    {
        var counts=NormativeScroll.WorkCountsFor(
            NormativeScroll.FoundationDay,NormativeScroll.FoundationDay+1);
        var bowls=NormativeScroll.InitialBowls(counts);
        var stones=NormativeScroll.BuildStones();
        var value=NormativeScroll.Save((BigInteger.One<<8192)+93);
        var wrapper=new BowlAliasPatchWrapper();
        var legacy=new LegacyFixedBowlPours();
        var fixedPours=legacy.PourIntoFixedIdentifiers(1,value,bowls,stones);
        Check(bowls.Skip(1).Distinct().Count()==6,
            "الأوعية الأولية لا تتساوى في فحص التبديلات.");

        for(var rank1=1;rank1<=720;rank1++)
        {
            _permutations++;
            var order=NormativeScroll.PermutationUnrank1(rank1);
            var alias=wrapper.InstallOrderAliases(order);
            var candidate=wrapper.PatchedPours(1,value,stones,bowls,alias);
            Check(alias[0]==0 && alias.Length==7 &&
                alias.Skip(1).SequenceEqual(order) &&
                alias.Skip(1).Distinct().Count()==6,
                "البصمة الكاملة لخريطة المواضع " + rank1);
            Check(candidate is {Length:7} &&
                candidate[0]==0 &&
                candidate[4]==0 && candidate[5]==0 && candidate[6]==0,
                "التزام الصبّ الثلاثي فقط " + rank1);

            for(var position=1;position<=6;position++)
                Check(wrapper.BowlByLegacyPosition(bowls,alias,position)==
                    bowls[order[position-1]],
                    "قراءة اسم وعاء متحرك " + rank1 + "/" + position);

            for(var position=1;position<=3;position++)
                Check(candidate[position]==ExpectedPour(
                    1,position,value,bowls,stones[1],order),
                    "الصبّ الصحيح لكل تبديل معجمي " + rank1 + "/" + position);

            var expectedFullMatch=order[0]==1 && order[1]==2 && order[2]==3;
            var matches= candidate.SequenceEqual(fixedPours);
            if(matches) _permutationMatching++;
            else _permutationDifference++;
            Check(matches==expectedFullMatch,
                "الخطأ التاريخي مع رتبة جميع التبديلات " + rank1);
        }

        foreach(var bad in new[]{
            Array.Empty<int>(),new[]{1,2,3,4,5,5},new[]{0,2,3,4,5,6},
            new[]{1,2,3,4,5,7}
        })
        {
            var denied=false;
            try { _=wrapper.InstallOrderAliases(bad); }
            catch(MonsterValidationException){denied=true;}
            Check(denied,"رفض خريطة غير تبادلية");
        }
        var ordinary=wrapper.InstallOrderAliases(new[]{2,3,4,5,6,1});
        foreach(var wrong in new[]{0,-1,7,int.MaxValue})
        {
            var denied=false;
            try { _=wrapper.BowlByLegacyPosition(bowls,ordinary,wrong); }
            catch(MonsterValidationException){denied=true;}
            Check(denied,"رفض موضع لا يقع بين الأوعية الستة");
        }
        var wrongAliases=(int[])ordinary.Clone();
        wrongAliases[1]=wrongAliases[2];
        var invalidRejected=false;
        try { _=wrapper.PatchedPours(1,value,stones,bowls,wrongAliases); }
        catch(MonsterValidationException){invalidRejected=true;}
        Check(invalidRejected,"رفض خريطة لا تخص ست هويات مستقلة");
    }
}
