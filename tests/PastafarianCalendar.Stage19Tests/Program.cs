using System.Numerics;
using PastafarianCalendar.Monster;
using PastafarianCalendar.Stage01Tests.Normative;

namespace PastafarianCalendar.Stage19Tests;

internal static partial class Program
{
    private static int _passed, _failed;
    private static int _sampleCount, _correctedPours, _historicDifferences;
    private static int _historicMatchingSamples, _historicDifferingSamples;
    private static int _permutations, _permutationDifference, _permutationMatching;
    private static int _publicReads;

    private static void Check(bool valid,string label)
    {
        if (valid) { _passed++; return; }
        _failed++;
        Console.WriteLine("فشل رقعة الأسماء التاسعة: " + label);
    }

    private static BigInteger ExpectedPour(
        int index,int position,BigInteger drop,BigInteger[] bowls,
        BigInteger[] stoneRow,int[] order)
    {
        var multiplier=position==1 ? 3 : position==2 ? 5 : 7;
        return NormativeScroll.Save(drop*drop +
            stoneRow[position]*bowls[order[position-1]] + multiplier*index);
    }

    private static void CompareProduction(BigInteger c,BigInteger t,int sample)
    {
        var counts=NormativeScroll.WorkCountsFor(c,t);
        var hidden=NormativeScroll.BuildHiddenDrops(counts);
        var visible=NormativeScroll.BuildVisibleDrops(counts,hidden);
        var stones=NormativeScroll.BuildStones();
        var initial=NormativeScroll.InitialBowls(counts);
        var manager=new MonsterManager();

        for(var index=1;index<=46;index++)
        {
            _sampleCount++;
            var ctx=manager.ExecutePatchedBowlPours(c,t,index);
            var order=NormativeScroll.BowlOrderFromDrop(visible[index]);
            var patched=ctx.PatchedPoursResult;
            var historical=ctx.LegacyPoursResult;
            Check(patched is {Length:7} && historical is {Length:7},
                "مصفوفات الصبّ منفصلة " + sample + "/" + index);
            if(patched is not {Length:7} || historical is not {Length:7}) continue;

            Check(!ReferenceEquals(patched,historical) &&
                ctx.BowlAliases is {Length:7} &&
                ctx.LegacyPourOrder is {Length:6} &&
                ctx.LegacyPourOrder.SequenceEqual(order) &&
                ctx.LegacyPourInitialBowls is {Length:7} &&
                ctx.LegacyPourInitialBowls.SequenceEqual(initial) &&
                ctx.LegacyPourDrop==visible[index] &&
                ctx.LegacyPourVisibleIndex==index,
                "ترابط خريطة الصبّ مع المصدر الحقيقي " + sample + "/" + index);
            Check(ctx.PatchedVisibleDrops is {Length:47} &&
                ctx.PatchedVisibleDrops.SequenceEqual(visible) &&
                ctx.PatchedStoneRows is {Length:47} &&
                ctx.LegacyHiddenReversed is {Length:8},
                "الطبقات السابقة من حساب إنتاج حقيقي " + sample + "/" + index);
            Check(ctx.Status=="BOWL_ALIAS_PATCH_COMPLETE" &&
                ctx.Phase=="BOWL_ALIAS_PATCH_COMPLETE" &&
                ctx.BranchTrace.SequenceEqual(new[]{
                    "BOOTSTRAP_VALIDATION",
                    "LEGACY_FIXED_BOWL_POURS_WITNESS",
                    "BOWL_ALIAS_PATCH"}) &&
                ctx.Metrics["legacy.fixed.bowl.pours.witness"]==1 &&
                ctx.Metrics["bowl.alias.patch.dispatch"]==1,
                "شاهد القديم والالتزام بعد التحقق " + sample + "/" + index);

            for(var position=0;position<=6;position++)
            {
                if(position==0)
                {
                    Check(ctx.BowlAliases![0]==0 && patched[0]==0 &&
                          historical[0]==0,"فهرس الصفر محجوز");
                    continue;
                }
                Check(ctx.BowlAliases![position]==order[position-1],
                    "الهوية محفوظة تحت الموضع التاريخي " + position);
                if(position>3)
                {
                    Check(patched[position]==0 && historical[position]==0,
                        "لا تصبّ إلا المواضع الثلاثة الأولى");
                    continue;
                }
                var expected=ExpectedPour(index,position,visible[index],
                    initial,stones[index],order);
                var fixedExpected=NormativeScroll.Save(
                    visible[index]*visible[index]+
                    stones[index][position]*initial[position]+
                    (position==1?3:position==2?5:7)*index);
                _correctedPours++;
                Check(patched[position]==expected &&
                    patched[position]>=1 && patched[position]<=NormativeScroll.M,
                    "قيمة الصبّ المرجعية " + sample + "/" + index + "/" + position);
                Check(historical[position]==fixedExpected,
                    "قيمة الندبة القديمة لم تُمحَ " + sample + "/" + index + "/" + position);
                if(historical[position]!=expected)
                    _historicDifferences++;
            }

            var same=historical.SequenceEqual(patched);
            if(same) _historicMatchingSamples++;
            else _historicDifferingSamples++;
        }

        foreach(var i in new[]{1,7,23,46})
        {
            _publicReads++;
            var actual=CalendarDateSpaghetti.EvaluatePatchedBowlPours(c,t,i);
            var order=NormativeScroll.BowlOrderFromDrop(visible[i]);
            var expected=new BigInteger[7];
            for(var position=1;position<=3;position++)
                expected[position]=ExpectedPour(i,position,visible[i],
                    initial,stones[i],order);
            Check(actual.SequenceEqual(expected),
                "واجهة الصبّ العامة المرجعية " + sample + "/" + i);
        }
    }

    private static int Main()
    {
        Console.OutputEncoding=System.Text.Encoding.UTF8;
        var f=NormativeScroll.FoundationDay;
        var huge=BigInteger.One<<8192;
        var cases=new (BigInteger C,BigInteger T)[]{
            (f,f),(f-1,f+1),(f+1,f-1),(0,1),
            (1,0),(new BigInteger(-278522),f),
            (huge,-huge),(-huge+f,huge+f)
        };
        for(var i=0;i<cases.Length;i++)
            CompareProduction(cases[i].C,cases[i].T,i+1);
        CheckAllPermutations();
        CheckIsolationAndRejection();
        Console.WriteLine("حالات القطرات المنتجة: "+_sampleCount);
        Console.WriteLine("مواضع الصبّ المصححة: "+_correctedPours);
        Console.WriteLine("مواضع الخطأ القديم الباقية: "+_historicDifferences);
        Console.WriteLine("مجموعات الصبّ التاريخية المتطابقة: "+_historicMatchingSamples);
        Console.WriteLine("مجموعات الصبّ التاريخية المختلفة: "+_historicDifferingSamples);
        Console.WriteLine("التباديل المفحوصة: "+_permutations);
        Console.WriteLine("التباديل المخالفة للقديم: "+_permutationDifference);
        Console.WriteLine("التباديل المطابقة للقديم: "+_permutationMatching);
        Console.WriteLine("القراءات العامة المباشرة: "+_publicReads);
        Console.WriteLine("اختبارات رقعة الأسماء التاسعة الناجحة: "+_passed);
        Console.WriteLine("اختبارات رقعة الأسماء التاسعة الفاشلة: "+_failed);
        return _failed==0 && _sampleCount==368 && _correctedPours==1104 &&
            _historicDifferences==924 &&
            _historicMatchingSamples==2 && _historicDifferingSamples==366 &&
            _permutations==720 && _permutationMatching==6 &&
            _permutationDifference==714 && _publicReads==32 ? 0 : 1;
    }
}
