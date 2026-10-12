using System.Numerics;
using PastafarianCalendar.Monster;
using PastafarianCalendar.Stage01Tests.Normative;

namespace PastafarianCalendar.Stage23Tests;

internal static partial class Program
{
    private static void CheckOwnershipAndRejection()
    {
        var a=Contexts[0];
        var b=Contexts[1];
        Check(!ReferenceEquals(a,b) &&
              !ReferenceEquals(a.PatchedOrderAt46Latch,b.PatchedOrderAt46Latch) &&
              !ReferenceEquals(a.PatchedSauceFinalBowls,b.PatchedSauceFinalBowls) &&
              !ReferenceEquals(a.PatchedPostStirOrders,b.PatchedPostStirOrders) &&
              !ReferenceEquals(a.LegacyOverwrittenQueryOrder,b.LegacyOverwrittenQueryOrder) &&
              !ReferenceEquals(a.PatchedVisibleDrops,b.PatchedVisibleDrops) &&
              !ReferenceEquals(a.BranchTrace,b.BranchTrace) &&
              !ReferenceEquals(a.Metrics,b.Metrics),
              "ملكية الاستدعاء للالتقاط وللأوعية منفصلة.");

        var savedLatch=(int[])b.PatchedOrderAt46Latch!.Clone();
        var savedFinal=(BigInteger[])b.PatchedSauceFinalBowls!.Clone();
        var savedAfter=(BigInteger[])b.PatchedSauceBowlsAfterDrops!.Clone();
        var savedPost=(int[])b.PatchedPostStirOrders![12].Clone();
        var savedOld=(int[])b.LegacyOverwrittenQueryOrder!.Clone();

        a.PatchedOrderAt46Latch![0]=-7;
        a.PatchedSauceFinalBowls![1]=0;
        a.PatchedSauceBowlsAfterDrops![2]=0;
        a.PatchedPostStirOrders![12][3]=-7;
        a.LegacyOverwrittenQueryOrder![0]=-7;
        Check(b.PatchedOrderAt46Latch!.SequenceEqual(savedLatch) &&
              b.PatchedSauceFinalBowls!.SequenceEqual(savedFinal) &&
              b.PatchedSauceBowlsAfterDrops!.SequenceEqual(savedAfter) &&
              b.PatchedPostStirOrders![12].SequenceEqual(savedPost) &&
              b.LegacyOverwrittenQueryOrder!.SequenceEqual(savedOld),
              "كتابة استدعاء لا تُلوّث نسخة الاستدعاء الآخر.");

        var latchBeforeMutation=(int[])b.PatchedOrderAt46Latch.Clone();
        var oldPostBefore=(int[])b.LegacyPostStirOrders![12].Clone();
        b.PatchedPostStirOrders![12][0]=-7;
        Check(b.PatchedOrderAt46Latch.SequenceEqual(latchBeforeMutation) &&
              b.LegacyPostStirOrders[12].SequenceEqual(oldPostBefore),
              "سجل التحريك المحمي لا يشارك ذاكرة الالتقاط ولا القديم.");
        b.PatchedPostStirOrders[12][0]=savedPost[0];

        var dispatcher=new MonsterDispatcher(
            new MonsterValidationManager(),new MonsterMetricsManager());
        var trace=b.BranchTrace.ToArray();
        var rejected=false;
        try{dispatcher.DispatchProtectedDrop46Sauce(b);}
        catch(MonsterValidationException){rejected=true;}
        Check(rejected && b.Status=="PROTECTED_DROP46_ORDER_LATCH_COMPLETE" &&
              b.BranchTrace.SequenceEqual(trace) &&
              b.PatchedOrderAt46Latch.SequenceEqual(savedLatch) &&
              b.Metrics["protected.drop46.latch.dispatch"]==1,
              "رفض إعادة التنفيذ قبل تغيير السياق.");

        var f=NormativeScroll.FoundationDay;
        var fresh=new MonsterContext(f,f);
        rejected=false;
        try{dispatcher.DispatchProtectedDrop46Sauce(fresh);}
        catch(MonsterValidationException){rejected=true;}
        Check(rejected && fresh.Status=="NEW" &&
              fresh.BranchTrace.Count==0 &&
              fresh.PatchedOrderAt46Latch is null,
              "رفض سياق غير مؤسس دون أثر.");

        var manager=new MonsterManager();
        var prepared=manager.Prepare(f,f);
        var candidate=new ProtectedDrop46SaucePhaseHandler().Handle(prepared);
        var validator=new MonsterValidationManager();
        validator.ValidateVisibleDropPatch(prepared,candidate.Historical.Source);
        validator.ValidateLegacyOverwrittenSauce(prepared,candidate.Historical);
        validator.ValidateProtectedDrop46Sauce(prepared,candidate);
        Check(prepared.Status=="BOOTSTRAP_READY" &&
              prepared.BranchTrace.SequenceEqual(new[]{"BOOTSTRAP_VALIDATION"}) &&
              prepared.PatchedOrderAt46Latch is null &&
              prepared.PatchedSauceFinalBowls is null &&
              prepared.LegacyOverwrittenQueryOrder is null &&
              !prepared.Metrics.ContainsKey("protected.drop46.latch.dispatch"),
              "المرشح والماَفحص لا يلتزمان قبل التحقق النهائي.");

        void MustReject(ProtectedDrop46SauceCandidate bad,string label)
        {
            var denied=false;
            try{validator.ValidateProtectedDrop46Sauce(prepared,bad);}
            catch(MonsterValidationException){denied=true;}
            Check(denied && prepared.PatchedOrderAt46Latch is null &&
                  prepared.LegacySauceFinalBowls is null &&
                  prepared.PatchedSauceFinalBowls is null &&
                  prepared.BranchTrace.SequenceEqual(new[]{"BOOTSTRAP_VALIDATION"}),
                  "رفض مرشح دون كتابة جزئية: "+label);
        }

        var wrongLatch=(int[])candidate.Patched.OrderAt46Latch.Clone();
        (wrongLatch[0],wrongLatch[1])=(wrongLatch[1],wrongLatch[0]);
        MustReject(candidate with {Patched=candidate.Patched with {
            OrderAt46Latch=wrongLatch}}, "تبديل موضع الالتقاط");

        var wrongFinal=(BigInteger[])candidate.Patched.FinalBowls.Clone();
        wrongFinal[2]=0;
        MustReject(candidate with {Patched=candidate.Patched with {
            FinalBowls=wrongFinal}}, "تحريف الوعاء النهائي");

        var wrongAfter=(BigInteger[])candidate.Patched.BowlsAfterDrops.Clone();
        wrongAfter[3]=0;
        MustReject(candidate with {Patched=candidate.Patched with {
            BowlsAfterDrops=wrongAfter}}, "تحريف الأوعية بعد القطرات");

        var wrongOrders=(int[][])candidate.Patched.PostStirOrders.Clone();
        wrongOrders[6]=(int[])wrongOrders[6].Clone();
        (wrongOrders[6][0],wrongOrders[6][1])=
            (wrongOrders[6][1],wrongOrders[6][0]);
        MustReject(candidate with {Patched=candidate.Patched with {
            PostStirOrders=wrongOrders}}, "ترتيب تحريك محوّر");

        MustReject(candidate with {Patched=candidate.Patched with {
            OrderAt46Latch=candidate.Historical.DiagnosticDrop46Order}},
            "ذاكرة شاهدي الالتقاط مشتركة");
        MustReject(candidate with {Patched=candidate.Patched with {
            FinalBowls=candidate.Historical.FinalBowls}},
            "اشتراك المصفوفة التاريخية بالمصححة");

        var badOld=(int[])candidate.Historical.OverwrittenQueryOrder.Clone();
        (badOld[0],badOld[1])=(badOld[1],badOld[0]);
        rejected=false;
        try{validator.ValidateLegacyOverwrittenSauce(prepared,
            candidate.Historical with {OverwrittenQueryOrder=badOld});}
        catch(MonsterValidationException){rejected=true;}
        Check(rejected && prepared.LegacySauceFinalBowls is null,
            "لا يُسمح بتصحيح خطأ التاريخ عبر إفساد شهادته.");

        Check(b.PatchedOrderAt46Latch.SequenceEqual(savedLatch) &&
              b.PatchedSauceFinalBowls.SequenceEqual(savedFinal) &&
              b.LegacyOverwrittenQueryOrder.SequenceEqual(savedOld),
              "محاولات الرفض لا تُمسّ نتيجة منتهية في سياق آخر.");
    }
}
