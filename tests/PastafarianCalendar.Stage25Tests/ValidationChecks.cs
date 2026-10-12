using System.Numerics;
using PastafarianCalendar.Monster;
using PastafarianCalendar.Stage01Tests.Normative;

namespace PastafarianCalendar.Stage25Tests;

internal static partial class Program
{
    private static void CheckOwnershipAndRejection()
    {
        var first=Contexts[0];
        var second=Contexts[1];
        Check(!ReferenceEquals(first,second) &&
              !ReferenceEquals(first.PatchedSauceFinalBowls,second.PatchedSauceFinalBowls) &&
              !ReferenceEquals(first.PatchedOrderAt46Latch,second.PatchedOrderAt46Latch) &&
              !ReferenceEquals(first.LegacySauceFinalBowls,second.LegacySauceFinalBowls) &&
              !ReferenceEquals(first.BranchTrace,second.BranchTrace) &&
              !ReferenceEquals(first.Metrics,second.Metrics),
              "المخازن والآثار مملوكة لكل سياق على حدة");

        var saved=(int[])second.PatchedOrderAt46Latch!.Clone();
        var final=(BigInteger[])second.PatchedSauceFinalBowls!.Clone();
        first.PatchedOrderAt46Latch![0]=-7;
        first.PatchedSauceFinalBowls![1]=0;
        Check(second.PatchedOrderAt46Latch!.SequenceEqual(saved) &&
              second.PatchedSauceFinalBowls!.SequenceEqual(final) &&
              second.PatchedNextBowlResult.HasValue,
              "فساد مخزن مستقل لا ينتقل إلى سياق آخر");

        var dispatcher=new MonsterDispatcher(
            new MonsterValidationManager(),new MonsterMetricsManager());
        var trace=second.BranchTrace.ToArray();
        var before=second.PatchedNextBowlResult;
        var rejected=false;
        try{dispatcher.DispatchPatchedNextBowl(second);}
        catch(MonsterValidationException){rejected=true;}
        Check(rejected && second.PatchedNextBowlResult==before &&
              second.BranchTrace.SequenceEqual(trace) &&
              second.Metrics["patched.next.bowl.order.dispatch"]==1,
              "رفض الطلب المكرر قبل تعديل السجلات");

        var f=NormativeScroll.FoundationDay;
        var raw=new MonsterContext(f,f){LegacyQueriedBowlId=1};
        rejected=false;
        try{dispatcher.DispatchPatchedNextBowl(raw);}
        catch(MonsterValidationException){rejected=true;}
        Check(rejected && raw.Status=="NEW" && raw.BranchTrace.Count==0 &&
              raw.PatchedNextBowlResult is null && raw.LegacyFixedNextBowlResult is null,
              "رفض السياق غير المؤسس دون أثر");

        foreach (var invalid in new[]{-1,0,7})
        {
            rejected=false;
            try{new MonsterManager().ExecutePatchedNextBowl(f,f,invalid);}
            catch(MonsterValidationException){rejected=true;}
            Check(rejected,"رفض هوية وعاء غير قانونية "+invalid);
        }

        var wrapper=new NextBowlOrderPatchWrapper();
        foreach(var invalid in new[]{-1,0,7})
        {
            rejected=false;
            try{wrapper.Patch(new[]{1,2,3,4,5,6},invalid);}
            catch(MonsterValidationException){rejected=true;}
            Check(rejected,"رفض معرّف غير قانوني في الغلاف "+invalid);
        }
        foreach (var badOrder in new int[][]{
            new[]{1,2,3,4,5,5},new[]{1,2,3,4,5,7},
            new[]{0,2,3,4,5,6},new[]{1,2,3}
        })
        {
            rejected=false;
            try{wrapper.Patch(badOrder,1);}
            catch(MonsterValidationException){rejected=true;}
            Check(rejected,"رفض تبديلة فاسدة أو ناقصة");
        }

        var ready=new MonsterManager().Prepare(f,f);
        ready.LegacyQueriedBowlId=1;
        var candidate=new PatchedNextBowlPhaseHandler().Handle(ready);
        var validator=new MonsterValidationManager();
        validator.ValidateVisibleDropPatch(ready,candidate.Historical.Sauce.Historical.Source);
        validator.ValidateLegacyOverwrittenSauce(ready,candidate.Historical.Sauce.Historical);
        validator.ValidateProtectedDrop46Sauce(ready,candidate.Historical.Sauce);
        validator.ValidatePatchedNextBowl(ready,candidate);
        Check(ready.Status=="BOOTSTRAP_READY" &&
              ready.PatchedNextBowlResult is null && ready.LegacyFixedNextBowlResult is null &&
              ready.PatchedSauceFinalBowls is null &&
              ready.BranchTrace.SequenceEqual(new[]{"BOOTSTRAP_VALIDATION"}),
              "التحقق من المرشح لا يلتزم قبل إصدار الموافقة");

        void MustReject(PatchedNextBowlCandidate bad,string label)
        {
            var denied=false;
            try{validator.ValidatePatchedNextBowl(ready,bad);}
            catch(MonsterValidationException){denied=true;}
            Check(denied && ready.Status=="BOOTSTRAP_READY" &&
                  ready.PatchedNextBowlResult is null &&
                  ready.LegacyFixedNextBowlResult is null &&
                  ready.PatchedSauceFinalBowls is null &&
                  ready.BranchTrace.SequenceEqual(new[]{"BOOTSTRAP_VALIDATION"}),
                  "رفض مرشح قبل الالتزام "+label);
        }

        MustReject(candidate with {NextBowlId=0},"جار صفري");
        MustReject(candidate with {NextBowlId=7},"جار خارج المجال");
        MustReject(candidate with {NextBowlId=(candidate.NextBowlId%6)+1},
            "جار مخالف للترتيب");

        var changedLegacy = candidate.Historical with {LegacyNextBowlId=6};
        MustReject(candidate with {Historical=changedLegacy},
            "لا يُسمح بإصلاح الشاهد القديم");
        MustReject(candidate with {
            Historical=candidate.Historical with {QueriedBowlId=2}},
            "لا يُسمح باستبدال معرف السؤال");

        var altered=(int[])candidate.Historical.Sauce.Patched.OrderAt46Latch.Clone();
        (altered[0],altered[1])=(altered[1],altered[0]);
        MustReject(candidate with {Historical=candidate.Historical with {
            Sauce=candidate.Historical.Sauce with {
                Patched=candidate.Historical.Sauce.Patched with {
                    OrderAt46Latch=altered}}}},
            "رفض ترتيب لا يطابق القطرة 46");
    }
}
