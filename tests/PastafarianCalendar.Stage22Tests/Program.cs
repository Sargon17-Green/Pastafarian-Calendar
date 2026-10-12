using System.Numerics;
using PastafarianCalendar.Monster;
using PastafarianCalendar.Stage01Tests.Normative;

namespace PastafarianCalendar.Stage22Tests;

internal static partial class Program
{
    private static int _passed,_unexpected,_sauces,_different,_same,_postOrders,_drops,_permutations,_badPermutations;
    private static readonly List<MonsterContext> Contexts=new();
    private static readonly List<LegacySauceResult> HistoricalOutputs=new();

    private static void Check(bool ok,string label)
    {
        if(ok){_passed++;return;}
        _unexpected++;
        Console.WriteLine("مخالفة غير متوقعة: "+label);
    }

    private static void Observe(BigInteger c,BigInteger t,int index)
    {
        _sauces++;
        var counts=NormativeScroll.WorkCountsFor(c,t);
        var hidden=NormativeScroll.BuildHiddenDrops(counts);
        var visible=NormativeScroll.BuildVisibleDrops(counts,hidden);
        var initial=NormativeScroll.InitialBowls(counts);
        var after=NormativeScroll.ApplyVisibleDropsToBowls(initial,visible);
        var expectedBowls=NormativeScroll.PostStir12(after.Bowls);
        var expectedSauce=NormativeScroll.Sauce(c,t);

        var context=new MonsterManager().ExecuteLegacyOverwrittenSauce(c,t);
        var actual=CalendarDateSpaghetti.EvaluateLegacyOverwrittenSauce(c,t);
        Contexts.Add(context);
        HistoricalOutputs.Add(actual);
        Check(context.Status=="LEGACY_OVERWRITTEN_DROP46_ORDER_COMPLETE" &&
              context.Phase=="LEGACY_OVERWRITTEN_DROP46_ORDER_COMPLETE" &&
              context.BranchTrace.SequenceEqual(new[]{
                  "BOOTSTRAP_VALIDATION","LEGACY_OVERWRITTEN_DROP46_ORDER"}) &&
              context.Metrics["legacy.overwritten.drop46.order.dispatch"]==1,
              "الإرسال الفعلي الملتزم "+index);
        Check(context.PatchedCountsResult is not null &&
              context.PatchedVisibleDrops is {Length:47} &&
              context.PatchedVisibleDrops.SequenceEqual(visible) &&
              context.PatchedStoneRows is {Length:47} &&
              context.LegacyHiddenReversed is {Length:8},
              "اتصال كافة طبقات حساب القطرات "+index);
        Check(context.LegacySauceBowlsAfterDrops is {Length:7} &&
              context.LegacySauceBowlsAfterDrops.SequenceEqual(after.Bowls),
              "أوعية بعد ست وأربعين قطرة صحيحة "+index);
        Check(context.LegacySauceFinalBowls is {Length:7} &&
              context.LegacySauceFinalBowls.SequenceEqual(expectedBowls) &&
              actual.Bowls.SequenceEqual(expectedBowls) &&
              expectedSauce.Bowls.SequenceEqual(expectedBowls),
              "الاثنتا عشرة دورة لا تفسد قيم الأوعية "+index);
        Check(context.LegacyDiagnosticDrop46Order is {Length:6} &&
              context.LegacyDiagnosticDrop46Order.SequenceEqual(after.OrderAtDrop46) &&
              expectedSauce.OrderAtDrop46.SequenceEqual(after.OrderAtDrop46),
              "شاهد تشخيصي لترتيب القطرة السادسة والأربعين "+index);
        Check(context.LegacyPostStirOrders is {Length:13} &&
              context.LegacyPostStirOrders[0] is null &&
              context.LegacyOverwrittenQueryOrder is {Length:6} &&
              context.LegacyOverwrittenQueryOrder.SequenceEqual(
                  context.LegacyPostStirOrders[12]) &&
              actual.QueryOrder.SequenceEqual(context.LegacyPostStirOrders[12]),
              "استخدام الترتيب الأخير بدلاً من الترتيب الملْتقط "+index);
        Check(!ReferenceEquals(context.LegacyOverwrittenQueryOrder,
                context.LegacyDiagnosticDrop46Order) &&
              !ReferenceEquals(context.LegacySauceFinalBowls,
                context.LegacySauceBowlsAfterDrops) &&
              !ReferenceEquals(actual.Bowls,context.LegacySauceFinalBowls),
              "فصل ملكية المصفوفات التاريخية "+index);

        var replay=(BigInteger[])after.Bowls.Clone();
        var post=new LegacyPostStirRound();
        for(var stir=1;stir<=12;stir++)
        {
            _postOrders++;
            var round=post.Stir(replay,stir);
            var history=context.LegacyPostStirOrders![stir];
            Check(history is {Length:6} &&
                  history.SequenceEqual(round.Order) &&
                  history.Distinct().Count()==6,
                  "ترتيب التحريك اللاحق من الوعاء المتجدد "+index+"/"+stir);
        }
        Check(replay.SequenceEqual(expectedBowls),
            "سلسلة التحريك من الإنتاج تنتهي في الأوعية المعيارية");

        for(var i=1;i<=46;i++)
        {
            _drops++;
            Check(context.PatchedVisibleDrops![i]==visible[i],
                "تطابق قطرة فعلية "+index+"/"+i);
        }

        if(actual.QueryOrder.SequenceEqual(after.OrderAtDrop46))_same++;
        else _different++;
    }

    private static int Main(string[] args)
    {
        Console.OutputEncoding=System.Text.Encoding.UTF8;
        var verify=args.Length==1 && args[0]=="--verify-expected-red";
        if(args.Length>0&&!verify)return 2;
        var f=NormativeScroll.FoundationDay;
        var giant=BigInteger.One<<8192;
        var pairs=new (BigInteger C,BigInteger T)[]{
            (f,f),(f-1,f+1),(f+1,f-1),(0,1),
            (1,0),(new BigInteger(-278522),f),
            (giant,-giant),(-giant+f,giant+f)
        };
        for(var i=0;i<pairs.Length;i++)
            Observe(pairs[i].C,pairs[i].T,i+1);
        VerifyPermutationOverwrite();
        if(verify)VerifyIsolationAndFailures();

        Console.WriteLine("الصلصات الكاملة: "+_sauces);
        Console.WriteLine("أوامر التحريك اللاحقة: "+_postOrders);
        Console.WriteLine("القطرات المنتجة: "+_drops);
        Console.WriteLine("الترتيبات الممحوة المختلفة: "+_different);
        Console.WriteLine("التطابقات العرضية: "+_same);
        Console.WriteLine("التباديل الافتراضية: "+_permutations);
        Console.WriteLine("التباديل التي تُمحى خطأً: "+_badPermutations);
        Console.WriteLine("التحققات الناجحة: "+_passed);
        Console.WriteLine("المخالفات غير المتوقعة: "+_unexpected);
        if(verify)
        {
            var pass=_unexpected==0 && _sauces==8 && _postOrders==96 &&
                _drops==368 && _different>=7 && _same+_different==8 &&
                _permutations==720 && _badPermutations==719;
            Console.WriteLine("توقيع اكتشاف مسح ترتيب القطرة 46: "+(pass?"PASS":"FAIL"));
            return pass?0:1;
        }
        return _unexpected==0 && _different==0 ? 0:1;
    }
}
