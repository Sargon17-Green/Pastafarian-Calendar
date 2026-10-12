using System.Numerics;
using PastafarianCalendar.Monster;
using PastafarianCalendar.Stage01Tests.Normative;

namespace PastafarianCalendar.Stage20Tests;

internal static partial class Program
{
    private static int _passed, _unexpected, _samples, _compared, _matching, _diverging;
    private static int _firstPositionMatches, _otherPositionDifferences;
    private static int _permutationSamples, _permutationDivergences, _publicReads;

    private static void Check(bool yes,string label)
    {
        if(yes){_passed++;return;}
        _unexpected++;
        Console.WriteLine("مخالفة في الاكتشاف العاشر: "+label);
    }

    // مرجع الاختبار وحده ينفّذ قراءة متزامنة من قيم ما قبل التحريك.
    // لا يدخل مخزن old هذا إلى منتج التحريك التاريخي مطلقاً.
    private static BigInteger[] NormativeSingleDropStir(
        BigInteger[] initial,int index,BigInteger drop,BigInteger[][] stones,
        int[] order,BigInteger[] pours)
    {
        var old=(BigInteger[])initial.Clone();
        var next=new BigInteger[7];
        var stoneKind=new[]{0,1,2,3,4,5,1};
        for(var position=1;position<=6;position++)
        {
            var id=order[position-1];
            var previous=order[(position+4)%6];
            var following=order[position%6];
            var s=old[id]+2*old[previous]+3*old[following]+
                pours[position]+drop+stones[index][stoneKind[position]];
            next[id]=NormativeScroll.Save(
                s*s+5*old[previous]*old[following]+index*position);
        }
        return next;
    }

    private static void Observe(BigInteger c,BigInteger t,int sample)
    {
        var counts=NormativeScroll.WorkCountsFor(c,t);
        var hidden=NormativeScroll.BuildHiddenDrops(counts);
        var visible=NormativeScroll.BuildVisibleDrops(counts,hidden);
        var stones=NormativeScroll.BuildStones();
        var initial=NormativeScroll.InitialBowls(counts);
        var manager=new MonsterManager();

        for(var index=1;index<=46;index++)
        {
            _samples++;
            var ctx=manager.ExecuteLegacyInPlaceStir(c,t,index);
            var got=ctx.LegacyStirredBowls;
            var order=NormativeScroll.BowlOrderFromDrop(visible[index]);
            var expectedPours=new BigInteger[7];
            for(var position=1;position<=3;position++)
            {
                var coefficient=position==1?3:position==2?5:7;
                expectedPours[position]=NormativeScroll.Save(
                    visible[index]*visible[index]+
                    stones[index][position]*initial[order[position-1]]+
                    coefficient*index);
            }
            var expected=NormativeSingleDropStir(
                initial,index,visible[index],stones,order,expectedPours);
            Check(got is {Length:7}, "ستة أوعية حية في العينة "+sample+"/"+index);
            if(got is not {Length:7})continue;
            Check(ctx.LegacyPourVisibleIndex==index &&
                ctx.LegacyPourDrop==visible[index] &&
                ctx.LegacyPourInitialBowls is {Length:7} &&
                ctx.LegacyPourInitialBowls.SequenceEqual(initial) &&
                ctx.LegacyPourOrder is {Length:6} &&
                ctx.LegacyPourOrder.SequenceEqual(order) &&
                ctx.PatchedPoursResult is {Length:7} &&
                ctx.PatchedPoursResult.SequenceEqual(expectedPours) &&
                ctx.BowlAliases is {Length:7} &&
                ctx.BowlAliases.Skip(1).SequenceEqual(order),
                "الرقع السابقة تقدم ترتيباً وصبّاً صحيحين "+sample+"/"+index);
            Check(ctx.Status=="LEGACY_IN_PLACE_BOWL_STIR_COMPLETE" &&
                ctx.Phase=="LEGACY_IN_PLACE_BOWL_STIR_COMPLETE" &&
                ctx.BranchTrace.SequenceEqual(new[]{
                    "BOOTSTRAP_VALIDATION","LEGACY_IN_PLACE_BOWL_STIR"}) &&
                ctx.Metrics["legacy.in.place.bowl.stir.dispatch"]==1,
                "إنهاء المسار التاريخي من دون التزام جزئي "+sample+"/"+index);
            Check(ctx.PatchedVisibleDrops is {Length:47} &&
                ctx.PatchedVisibleDrops.SequenceEqual(visible) &&
                ctx.PatchedStoneRows is {Length:47} &&
                ctx.LegacyHiddenReversed is {Length:8} &&
                !ReferenceEquals(got,ctx.LegacyPourInitialBowls),
                "ملكيات مستقلة لسجلات الأوعية قبل التحريك وبعده");
            Check(got[0]==0,"الخانة الصفرية للأوعية لم تتغير");
            for(var position=1;position<=6;position++)
            {
                var id=order[position-1];
                _compared++;
                Check(got[id]>=1 && got[id]<=NormativeScroll.M,
                    "الحفظ الصحيح شكلياً للوعاء "+sample+"/"+index+"/"+position);
                if(got[id]==expected[id])
                {
                    _matching++;
                    if(position==1)_firstPositionMatches++;
                }
                else
                {
                    _diverging++;
                    if(position>1)_otherPositionDifferences++;
                }
                if(position==1)
                    Check(got[id]==expected[id],
                        "الكتابة الأولى توافق المرجع قبل تلوث المخزن");
            }
        }

        foreach(var index in new[]{1,7,23,46})
        {
            _publicReads++;
            var fromFacade=CalendarDateSpaghetti.EvaluateLegacyInPlaceStir(c,t,index);
            var fromManager=manager.EvaluateLegacyInPlaceStir(c,t,index);
            Check(fromFacade.SequenceEqual(fromManager) &&
                  !ReferenceEquals(fromFacade,fromManager),
                "المسار العام القديم يتصرف بلا مشاركة للنتائج");
        }
    }

    private static int Main(string[] args)
    {
        Console.OutputEncoding=System.Text.Encoding.UTF8;
        var verifier=args.Length==1 && args[0]=="--verify-expected-red";
        if(args.Length>0 && !verifier)return 2;
        var f=NormativeScroll.FoundationDay;
        var huge=BigInteger.One<<8192;
        var cases=new (BigInteger C,BigInteger T)[]{
            (f,f),(f-1,f+1),(f+1,f-1),(0,1),
            (1,0),(new BigInteger(-278522),f),
            (huge,-huge),(-huge+f,huge+f)
        };
        for(var sample=0;sample<cases.Length;sample++)
            Observe(cases[sample].C,cases[sample].T,sample+1);
        VerifyPermutations();
        if(verifier)VerifyContextIsolation();

        Console.WriteLine("حالات القطرات التاريخية: "+_samples);
        Console.WriteLine("الأوعية المفحوصة: "+_compared);
        Console.WriteLine("التطابقات: "+_matching);
        Console.WriteLine("الاختلافات بسبب الكتابة المباشرة: "+_diverging);
        Console.WriteLine("تطابق الموضع الأول: "+_firstPositionMatches);
        Console.WriteLine("اختلافات المواضع اللاحقة: "+_otherPositionDifferences);
        Console.WriteLine("التباديل المختبرة: "+_permutationSamples);
        Console.WriteLine("التباديل المتضررة: "+_permutationDivergences);
        Console.WriteLine("القراءات العامة: "+_publicReads);
        Console.WriteLine("التحققات الناجحة: "+_passed);
        Console.WriteLine("مخالفات غير متوقعة: "+_unexpected);

        if(verifier)
        {
            var pass=_unexpected==0 && _samples==368 && _compared==2208 &&
                _firstPositionMatches==368 && _diverging>1400 &&
                _permutationSamples==720 && _permutationDivergences==720 &&
                _publicReads==32;
            Console.WriteLine("توقيع التلوث التاريخي العاشر: "+(pass?"PASS":"FAIL"));
            return pass?0:1;
        }
        return _unexpected==0 && _samples==368 && _diverging==0?0:1;
    }
}
