using System.Numerics;
using PastafarianCalendar.Monster;
using PastafarianCalendar.Stage01Tests.Normative;

namespace PastafarianCalendar.Stage21Tests;

internal static partial class Program
{
    private static int _passed, _failed, _samples, _bowls, _oldDifferences;
    private static int _oldFirstMatches, _permutations, _permutationDifferences, _publicReads;

    private static void Check(bool valid,string label)
    {
        if(valid){_passed++;return;}
        _failed++;
        Console.WriteLine("فشل الرقعة العاشرة: "+label);
    }

    // مرجع الاختبار مستقل عن الغلاف: كل القيم تُستخرج من مصفوفة قبل التحريك.
    private static BigInteger[] NormativeStir(
        BigInteger[] original,int i,BigInteger drop,BigInteger[][] stones,
        int[] order,BigInteger[] pours)
    {
        var old=(BigInteger[])original.Clone();
        var expected=new BigInteger[7];
        var kinds=new[]{0,1,2,3,4,5,1};
        for(var position=1;position<=6;position++)
        {
            var id=order[position-1];
            var prev=order[(position+4)%6];
            var next=order[position%6];
            var s=old[id]+2*old[prev]+3*old[next]+
                pours[position]+drop+stones[i][kinds[position]];
            expected[id]=NormativeScroll.Save(
                s*s+5*old[prev]*old[next]+i*position);
        }
        return expected;
    }

    private static void VerifyProduction(BigInteger c,BigInteger t,int sample)
    {
        var counts=NormativeScroll.WorkCountsFor(c,t);
        var hidden=NormativeScroll.BuildHiddenDrops(counts);
        var visible=NormativeScroll.BuildVisibleDrops(counts,hidden);
        var stones=NormativeScroll.BuildStones();
        var first=NormativeScroll.InitialBowls(counts);
        var manager=new MonsterManager();

        for(var i=1;i<=46;i++)
        {
            _samples++;
            var context=manager.ExecutePatchedBowlStir(c,t,i);
            var order=NormativeScroll.BowlOrderFromDrop(visible[i]);
            var pours=new BigInteger[7];
            for(var position=1;position<=3;position++)
            {
                var multiplier=position==1?3:position==2?5:7;
                pours[position]=NormativeScroll.Save(
                    visible[i]*visible[i]+stones[i][position]*
                    first[order[position-1]]+multiplier*i);
            }
            var expected=NormativeStir(first,i,visible[i],stones,order,pours);
            var old=context.LegacyStirredBowls;
            var got=context.PatchedStirredBowls;
            Check(old is {Length:7} && got is {Length:7},
                "نتيجتا التحريك القديم والمصحح "+sample+"/"+i);
            if(old is not {Length:7} || got is not {Length:7})continue;

            Check(context.LegacyPourDrop==visible[i] &&
                  context.LegacyPourVisibleIndex==i &&
                  context.LegacyPourOrder is {Length:6} &&
                  context.LegacyPourOrder.SequenceEqual(order) &&
                  context.LegacyPourInitialBowls is {Length:7} &&
                  context.LegacyPourInitialBowls.SequenceEqual(first) &&
                  context.PatchedPoursResult is {Length:7} &&
                  context.PatchedPoursResult.SequenceEqual(pours) &&
                  context.BowlAliases is {Length:7} &&
                  context.BowlAliases.Skip(1).SequenceEqual(order),
                "تسلسل المدخلات من المراحل السابقة "+sample+"/"+i);
            Check(context.PatchedVisibleDrops is {Length:47} &&
                  context.PatchedVisibleDrops.SequenceEqual(visible) &&
                  context.PatchedStoneRows is {Length:47} &&
                  context.LegacyHiddenReversed is {Length:8},
                "القطرات والأحجار من الإنتاج الفعلي");
            Check(context.Status=="SHADOW_BOWL_STIR_PATCH_COMPLETE" &&
                  context.Phase=="SHADOW_BOWL_STIR_PATCH_COMPLETE" &&
                  context.BranchTrace.SequenceEqual(new[]{
                      "BOOTSTRAP_VALIDATION",
                      "LEGACY_IN_PLACE_BOWL_STIR_WITNESS",
                      "SHADOW_BOWL_STIR_PATCH"}) &&
                  context.Metrics["legacy.in.place.bowl.stir.witness"]==1 &&
                  context.Metrics["shadow.bowl.stir.patch.dispatch"]==1,
                "التثبت من الشاهد التاريخي ومن قبول الرقعة");
            Check(context.StirVaultOld is {Length:7} &&
                  context.StirPending is {Length:7} &&
                  context.StirVaultOld.SequenceEqual(first) &&
                  context.StirPending.SequenceEqual(expected) &&
                  !ReferenceEquals(context.StirVaultOld,context.StirPending) &&
                  !ReferenceEquals(context.StirVaultOld,got) &&
                  !ReferenceEquals(context.StirPending,got) &&
                  !ReferenceEquals(old,got) &&
                  got.SequenceEqual(expected),
                "مخزن قديم مستقل ونتيجة مؤجلة مطابقة للمرجع");
            Check(old[0]==0 && got[0]==0 &&
                  context.StirVaultOld![0]==0 && context.StirPending![0]==0,
                "حراسة الفهرس الصفري");

            for(var position=1;position<=6;position++)
            {
                _bowls++;
                var id=order[position-1];
                Check(got[id]==expected[id] &&
                      got[id]>=1 && got[id]<=NormativeScroll.M,
                    "قراءة قديمة وكتابة مؤجلة صحيحتان "+sample+"/"+i+"/"+position);
                if(old[id]!=expected[id])_oldDifferences++;
                else if(position==1)_oldFirstMatches++;
                if(position==1)
                    Check(old[id]==expected[id],
                        "التحريك القديم لم يتلوث قبل أول كتابة");
            }
        }

        foreach(var i in new[]{1,7,23,46})
        {
            _publicReads++;
            var publicResult=CalendarDateSpaghetti.EvaluatePatchedBowlStir(c,t,i);
            var order=NormativeScroll.BowlOrderFromDrop(visible[i]);
            var pours=new BigInteger[7];
            for(var pos=1;pos<=3;pos++)
                pours[pos]=NormativeScroll.Save(
                    visible[i]*visible[i]+stones[i][pos]*first[order[pos-1]]+
                    (pos==1?3:pos==2?5:7)*i);
            var expected=NormativeStir(first,i,visible[i],stones,order,pours);
            Check(publicResult.SequenceEqual(expected),
                "واجهة التحريك العامة توافق المرجع "+sample+"/"+i);
        }
    }

    private static int Main()
    {
        Console.OutputEncoding=System.Text.Encoding.UTF8;
        var f=NormativeScroll.FoundationDay;
        var huge=BigInteger.One<<8192;
        var pairs=new (BigInteger C,BigInteger T)[]{
            (f,f),(f-1,f+1),(f+1,f-1),(0,1),
            (1,0),(new BigInteger(-278522),f),
            (huge,-huge),(-huge+f,huge+f)
        };
        for(var sample=0;sample<pairs.Length;sample++)
            VerifyProduction(pairs[sample].C,pairs[sample].T,sample+1);

        VerifyAllPermutations();
        VerifyOwnershipAndRejection();
        Console.WriteLine("القطرات المنتجة: "+_samples);
        Console.WriteLine("الأوعية المصححة والمقارنة: "+_bowls);
        Console.WriteLine("اختلافات التحريك القديم المحفوظة: "+_oldDifferences);
        Console.WriteLine("تطابقات موضع القديم الأول: "+_oldFirstMatches);
        Console.WriteLine("التباديل المفحوصة: "+_permutations);
        Console.WriteLine("التباديل المتضررة تاريخياً: "+_permutationDifferences);
        Console.WriteLine("القراءات العامة: "+_publicReads);
        Console.WriteLine("اختبارات الرقعة العاشرة الناجحة: "+_passed);
        Console.WriteLine("اختبارات الرقعة العاشرة الفاشلة: "+_failed);
        return _failed==0 && _samples==368 && _bowls==2208 &&
               _oldDifferences==1840 && _oldFirstMatches==368 &&
               _permutations==720 && _permutationDifferences==720 &&
               _publicReads==32 ? 0:1;
    }
}
