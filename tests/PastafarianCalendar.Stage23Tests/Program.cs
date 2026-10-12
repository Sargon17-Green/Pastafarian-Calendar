using System.Numerics;
using PastafarianCalendar.Monster;
using PastafarianCalendar.Stage01Tests.Normative;

namespace PastafarianCalendar.Stage23Tests;

internal static partial class Program
{
    private static int _passed, _unexpected, _sauces, _drops, _postOrders;
    private static int _historicalDifferences, _historicalCoincidences, _publicReads;
    private static int _permutations, _historicalRankDifferences;
    private static readonly List<MonsterContext> Contexts=new();

    private static void Check(bool ok,string label)
    {
        if(ok){_passed++;return;}
        _unexpected++;
        Console.WriteLine("إخفاق الرقعة الحادية عشرة: "+label);
    }

    private static void CheckSauce(BigInteger calculation,BigInteger target,int sample)
    {
        _sauces++;
        var counts=NormativeScroll.WorkCountsFor(calculation,target);
        var hidden=NormativeScroll.BuildHiddenDrops(counts);
        var visible=NormativeScroll.BuildVisibleDrops(counts,hidden);
        var initial=NormativeScroll.InitialBowls(counts);
        var after=NormativeScroll.ApplyVisibleDropsToBowls(initial,visible);
        var normative=NormativeScroll.Sauce(calculation,target);
        var expectedFinal=NormativeScroll.PostStir12(after.Bowls);
        var manager=new MonsterManager();
        var context=manager.ExecuteProtectedDrop46Sauce(calculation,target);
        Contexts.Add(context);

        Check(context.Status=="PROTECTED_DROP46_ORDER_LATCH_COMPLETE" &&
              context.Phase=="PROTECTED_DROP46_ORDER_LATCH_COMPLETE" &&
              context.BranchTrace.SequenceEqual(new[]{
                  "BOOTSTRAP_VALIDATION",
                  "LEGACY_OVERWRITTEN_DROP46_ORDER_WITNESS",
                  "PROTECTED_DROP46_ORDER_LATCH"}) &&
              context.Metrics["legacy.overwritten.drop46.order.witness"]==1 &&
              context.Metrics["protected.drop46.latch.dispatch"]==1,
              "المدير والموزع وخطّ الشاهد القديم "+sample);
        Check(context.PatchedCountsResult is not null &&
              context.PatchedVisibleDrops is {Length:47} &&
              context.PatchedVisibleDrops.SequenceEqual(visible) &&
              context.LegacyHiddenReversed is {Length:8} &&
              context.PatchedStoneRows is {Length:47},
              "العدّ والأحجار والقطرات مترابطة "+sample);
        Check(context.PatchedOrderAt46Latch is {Length:6} &&
              context.PatchedOrderAt46Latch.SequenceEqual(after.OrderAtDrop46) &&
              context.PatchedOrderAt46Latch.SequenceEqual(normative.OrderAtDrop46) &&
              context.LegacyDiagnosticDrop46Order is {Length:6} &&
              context.LegacyDiagnosticDrop46Order.SequenceEqual(after.OrderAtDrop46),
              "موضع الالتقاط المحمي يوافق القطرة الأخيرة "+sample);
        Check(context.PatchedSauceBowlsAfterDrops is {Length:7} &&
              context.LegacySauceBowlsAfterDrops is {Length:7} &&
              context.PatchedSauceBowlsAfterDrops.SequenceEqual(after.Bowls) &&
              context.LegacySauceBowlsAfterDrops.SequenceEqual(after.Bowls),
              "سلامة الست والأربعين قطرة السابقة للتحريك "+sample);
        Check(context.PatchedSauceFinalBowls is {Length:7} &&
              context.LegacySauceFinalBowls is {Length:7} &&
              context.PatchedSauceFinalBowls.SequenceEqual(expectedFinal) &&
              context.PatchedSauceFinalBowls.SequenceEqual(normative.Bowls) &&
              context.LegacySauceFinalBowls.SequenceEqual(expectedFinal),
              "الأوعية النهائية صحيحة في المسارين "+sample);
        Check(context.PatchedPostStirOrders is {Length:13} &&
              context.LegacyPostStirOrders is {Length:13} &&
              context.PatchedPostStirOrders[0] is null &&
              context.LegacyPostStirOrders[0] is null &&
              context.LegacyOverwrittenQueryOrder is {Length:6} &&
              context.LegacyOverwrittenQueryOrder.SequenceEqual(
                  context.LegacyPostStirOrders[12]),
              "تبقى ندبة المحو التاريخي في ترتيب الجولة الأخيرة "+sample);
        Check(!ReferenceEquals(context.PatchedOrderAt46Latch,
                  context.LegacyDiagnosticDrop46Order) &&
              !ReferenceEquals(context.PatchedOrderAt46Latch,
                  context.LegacyOverwrittenQueryOrder) &&
              !ReferenceEquals(context.PatchedSauceFinalBowls,
                  context.LegacySauceFinalBowls) &&
              !ReferenceEquals(context.PatchedSauceBowlsAfterDrops,
                  context.LegacySauceBowlsAfterDrops) &&
              !ReferenceEquals(context.PatchedPostStirOrders,
                  context.LegacyPostStirOrders),
              "شهادة القديم منفصلة عن الالتقاط وأوعية الرقعة "+sample);

        var replay=(BigInteger[])after.Bowls.Clone();
        var post=new LegacyPostStirRound();
        for(var round=1;round<=12;round++)
        {
            _postOrders++;
            var expectedPost=post.Stir(replay,round);
            Check(context.PatchedPostStirOrders![round] is {Length:6} &&
                  context.PatchedPostStirOrders[round].SequenceEqual(expectedPost.Order) &&
                  context.LegacyPostStirOrders![round].SequenceEqual(expectedPost.Order) &&
                  !ReferenceEquals(context.PatchedOrderAt46Latch,
                      context.PatchedPostStirOrders[round]) &&
                  !ReferenceEquals(context.LegacyPostStirOrders[round],
                      context.PatchedPostStirOrders[round]),
                  "التحريك اللاحق لا يكتب في سجل ترتيب القطرة "+sample+"/"+round);
            Check(context.PatchedOrderAt46Latch!.SequenceEqual(after.OrderAtDrop46),
                  "الالتقاط باق بعد التحريك رقم "+round);
        }
        Check(replay.SequenceEqual(expectedFinal),
              "التحريك المتسلسل ينتهي بالقيم المعيارية "+sample);

        for(var index=1;index<=46;index++)
        {
            _drops++;
            Check(context.PatchedVisibleDrops![index]==visible[index],
                  "قطرة إنتاج مطابقة "+sample+"/"+index);
        }

        _publicReads++;
        var api=CalendarDateSpaghetti.EvaluateLatchedSauce(calculation,target);
        Check(api.QueryOrder.SequenceEqual(after.OrderAtDrop46) &&
              api.Bowls.SequenceEqual(expectedFinal) &&
              !ReferenceEquals(api.QueryOrder,context.PatchedOrderAt46Latch) &&
              !ReferenceEquals(api.Bowls,context.PatchedSauceFinalBowls),
              "واجهة الإنتاج تعيد صورة مستقلة ذات ترتيب ثابت "+sample);
        var historical=CalendarDateSpaghetti.EvaluateLegacyOverwrittenSauce(calculation,target);
        Check(historical.QueryOrder.SequenceEqual(context.LegacyOverwrittenQueryOrder) &&
              historical.Bowls.SequenceEqual(expectedFinal),
              "المسار التاريخي العام يظل موجوداً ومخطئاً "+sample);

        if(historical.QueryOrder.SequenceEqual(after.OrderAtDrop46))
            _historicalCoincidences++;
        else
            _historicalDifferences++;
    }

    private static int Main()
    {
        Console.OutputEncoding=System.Text.Encoding.UTF8;
        var f=NormativeScroll.FoundationDay;
        var huge=BigInteger.One << 8192;
        var cases=new (BigInteger Calculation,BigInteger Target)[]{
            (f,f),(f-1,f+1),(f+1,f-1),(0,1),
            (1,0),(new BigInteger(-278522),f),
            (huge,-huge),(-huge+f,huge+f)
        };
        for(var i=0;i<cases.Length;i++)
            CheckSauce(cases[i].Calculation,cases[i].Target,i+1);
        CheckAllRankChoices();
        CheckOwnershipAndRejection();

        Console.WriteLine("الصلصات المصححة: "+_sauces);
        Console.WriteLine("القطرات المنتجة: "+_drops);
        Console.WriteLine("ترتيبات التحريك اللاحق: "+_postOrders);
        Console.WriteLine("الندبات القديمة المختلفة: "+_historicalDifferences);
        Console.WriteLine("المطابقات القديمة العرضية: "+_historicalCoincidences);
        Console.WriteLine("التبديلات المفحوصة: "+_permutations);
        Console.WriteLine("التبديلات المخالفة للقديم: "+_historicalRankDifferences);
        Console.WriteLine("القراءات العامة المصححة: "+_publicReads);
        Console.WriteLine("اختبارات الرقعة الحادية عشرة الناجحة: "+_passed);
        Console.WriteLine("اختبارات الرقعة الحادية عشرة الفاشلة: "+_unexpected);

        return _unexpected==0 && _sauces==8 && _drops==368 &&
            _postOrders==96 && _historicalDifferences==8 &&
            _historicalCoincidences==0 && _publicReads==8 &&
            _permutations==720 && _historicalRankDifferences==719 ? 0:1;
    }
}
