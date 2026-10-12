using System.Numerics;
using PastafarianCalendar.Monster;
using PastafarianCalendar.Stage01Tests.Normative;

namespace PastafarianCalendar.Stage22Tests;

internal static partial class Program
{
    private static void VerifyIsolationAndFailures()
    {
        var a=Contexts[0];
        var b=Contexts[1];
        Check(!ReferenceEquals(a,b) &&
              !ReferenceEquals(a.LegacySauceFinalBowls,b.LegacySauceFinalBowls) &&
              !ReferenceEquals(a.LegacySauceBowlsAfterDrops,b.LegacySauceBowlsAfterDrops) &&
              !ReferenceEquals(a.LegacyDiagnosticDrop46Order,b.LegacyDiagnosticDrop46Order) &&
              !ReferenceEquals(a.LegacyOverwrittenQueryOrder,b.LegacyOverwrittenQueryOrder) &&
              !ReferenceEquals(a.LegacyPostStirOrders,b.LegacyPostStirOrders) &&
              !ReferenceEquals(a.PatchedVisibleDrops,b.PatchedVisibleDrops) &&
              !ReferenceEquals(a.BranchTrace,b.BranchTrace) &&
              !ReferenceEquals(a.Metrics,b.Metrics),
              "لا تتشارك الاستدعاءات ذاكرة الصلصة أو أوامرها.");

        var last=(BigInteger[])b.LegacySauceFinalBowls!.Clone();
        var after=(BigInteger[])b.LegacySauceBowlsAfterDrops!.Clone();
        var order=(int[])b.LegacyOverwrittenQueryOrder!.Clone();
        var order46=(int[])b.LegacyDiagnosticDrop46Order!.Clone();
        var post=(int[])b.LegacyPostStirOrders![12].Clone();
        a.LegacySauceFinalBowls![1]=0;
        a.LegacySauceBowlsAfterDrops![2]=0;
        a.LegacyOverwrittenQueryOrder![0]=-9;
        a.LegacyDiagnosticDrop46Order![1]=-9;
        a.LegacyPostStirOrders![12][2]=-9;
        Check(b.LegacySauceFinalBowls!.SequenceEqual(last) &&
              b.LegacySauceBowlsAfterDrops!.SequenceEqual(after) &&
              b.LegacyOverwrittenQueryOrder!.SequenceEqual(order) &&
              b.LegacyDiagnosticDrop46Order!.SequenceEqual(order46) &&
              b.LegacyPostStirOrders![12].SequenceEqual(post),
              "لا ينتقل إفساد الذاكرة بين السياقات.");
        Check(HistoricalOutputs[0].Bowls[1]>0 &&
              HistoricalOutputs[0].QueryOrder.All(x=>x is >=1 and <=6),
              "المدخل العام يعيد نسخة منفصلة من السياق.");

        var dispatcher=new MonsterDispatcher(new MonsterValidationManager(),
            new MonsterMetricsManager());
        var trace=b.BranchTrace.ToArray();
        var denied=false;
        try{dispatcher.DispatchLegacyOverwrittenSauce(b);}
        catch(MonsterValidationException){denied=true;}
        Check(denied && b.LegacySauceFinalBowls!.SequenceEqual(last) &&
              b.BranchTrace.SequenceEqual(trace) &&
              b.Metrics["legacy.overwritten.drop46.order.dispatch"]==1,
              "رفض التنفيذ المكرر قبل أي أثر.");

        var f=NormativeScroll.FoundationDay;
        var fresh=new MonsterContext(f,f);
        denied=false;
        try{dispatcher.DispatchLegacyOverwrittenSauce(fresh);}
        catch(MonsterValidationException){denied=true;}
        Check(denied && fresh.Status=="NEW" &&
              fresh.LegacySauceFinalBowls is null &&
              fresh.BranchTrace.Count==0,
              "رفض السياق غير المؤسس.");

        var manager=new MonsterManager();
        var ready=manager.Prepare(f,f);
        var candidate=new LegacyOverwrittenDrop46Sauce().Evaluate(ready);
        var validator=new MonsterValidationManager();
        validator.ValidateVisibleDropPatch(ready,candidate.Source);
        validator.ValidateLegacyOverwrittenSauce(ready,candidate);
        Check(ready.Status=="BOOTSTRAP_READY" &&
              ready.BranchTrace.SequenceEqual(new[]{"BOOTSTRAP_VALIDATION"}) &&
              ready.LegacySauceFinalBowls is null &&
              ready.LegacyOverwrittenQueryOrder is null &&
              !ready.Metrics.ContainsKey("legacy.overwritten.drop46.order.dispatch"),
              "لا يلتزم التحقق بالنتائج أو السجلات.");

        void MustReject(LegacyOverwrittenSauceCandidate altered,string reason)
        {
            var failed=false;
            try{validator.ValidateLegacyOverwrittenSauce(ready,altered);}
            catch(MonsterValidationException){failed=true;}
            Check(failed && ready.LegacySauceFinalBowls is null &&
                  ready.LegacyOverwrittenQueryOrder is null,
                "رفض المرشح الفاسد بلا التزام: "+reason);
        }

        var wrong46=(int[])candidate.DiagnosticDrop46Order.Clone();
        (wrong46[0],wrong46[1])=(wrong46[1],wrong46[0]);
        MustReject(candidate with {DiagnosticDrop46Order=wrong46},
            "شاهد القطرة الأخيرة");
        var wrongOverwritten=(int[])candidate.OverwrittenQueryOrder.Clone();
        (wrongOverwritten[0],wrongOverwritten[1])=
            (wrongOverwritten[1],wrongOverwritten[0]);
        MustReject(candidate with {OverwrittenQueryOrder=wrongOverwritten},
            "ترتيب الاستعلام المطموس");
        var wrongBowls=(BigInteger[])candidate.FinalBowls.Clone();
        wrongBowls[1]=0;
        MustReject(candidate with {FinalBowls=wrongBowls},
            "قيم الأوعية النهائية");
        var wrongAfter=(BigInteger[])candidate.BowlsAfterDrops.Clone();
        wrongAfter[2]=0;
        MustReject(candidate with {BowlsAfterDrops=wrongAfter},
            "أوعية بعد اكتمال القطرات");
        var wrongTrace=(int[][])candidate.PostStirOrders.Clone();
        wrongTrace[5]=(int[])wrongTrace[5].Clone();
        (wrongTrace[5][0],wrongTrace[5][1])=
            (wrongTrace[5][1],wrongTrace[5][0]);
        MustReject(candidate with {PostStirOrders=wrongTrace},
            "سجل تحريك لاحق مفرد");
        MustReject(candidate with {FinalBowls=candidate.BowlsAfterDrops},
            "الذاكرة المشتركة بين النتيجتين");

        Check(b.LegacySauceFinalBowls!.SequenceEqual(last),
            "فشل المرشح لا يغير الاستدعاء المكتمل.");
    }
}
