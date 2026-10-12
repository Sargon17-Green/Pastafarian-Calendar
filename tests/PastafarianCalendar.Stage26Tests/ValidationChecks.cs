using System.Numerics;
using PastafarianCalendar.Monster;
using PastafarianCalendar.Stage01Tests.Normative;

namespace PastafarianCalendar.Stage26Tests;

internal static partial class Program
{
    private static void CheckOwnershipAndRejection()
    {
        var a=Contexts[0];
        var b=Contexts[1];
        Check(!ReferenceEquals(a,b) &&
              !ReferenceEquals(a.PatchedOrderAt46Latch,b.PatchedOrderAt46Latch) &&
              !ReferenceEquals(a.PatchedSauceFinalBowls,b.PatchedSauceFinalBowls) &&
              !ReferenceEquals(a.LegacySauceFinalBowls,b.LegacySauceFinalBowls) &&
              !ReferenceEquals(a.BranchTrace,b.BranchTrace) &&
              !ReferenceEquals(a.Metrics,b.Metrics),
              "البيانات تملكها سياقاتها دون تشارك");
        var beforeOrder=(int[])b.PatchedOrderAt46Latch!.Clone();
        var beforeBowls=(BigInteger[])b.PatchedSauceFinalBowls!.Clone();
        a.PatchedOrderAt46Latch![0]=-47;
        a.PatchedSauceFinalBowls![1]=0;
        Check(b.PatchedOrderAt46Latch!.SequenceEqual(beforeOrder) &&
              b.PatchedSauceFinalBowls!.SequenceEqual(beforeBowls) &&
              b.LegacyUnsealedBowlQuestionResult is not null,
              "الإفساد المحلي لا يتسرّب إلى جواب آخر");

        var dispatcher=new MonsterDispatcher(
            new MonsterValidationManager(),new MonsterMetricsManager());
        var trace=b.BranchTrace.ToArray();
        var record=b.LegacyUnsealedBowlQuestionResult;
        var rejected=false;
        try{dispatcher.DispatchLegacyUnsealedBowlQuestion(b);}
        catch(MonsterValidationException){rejected=true;}
        Check(rejected && b.BranchTrace.SequenceEqual(trace) &&
              b.LegacyUnsealedBowlQuestionResult==record &&
              b.Metrics["legacy.unsealed.bowl.question.dispatch"]==1,
              "إعادة تنفيذ السؤال مرفوضة قبل أي كتابة");
        var foundation=NormativeScroll.FoundationDay;
        var raw=new MonsterContext(foundation,foundation){
            LegacyQueriedBowlId=1,LegacyBowlQuestionSeal=21};
        rejected=false;
        try{dispatcher.DispatchLegacyUnsealedBowlQuestion(raw);}
        catch(MonsterValidationException){rejected=true;}
        Check(rejected && raw.Status=="NEW" && raw.BranchTrace.Count==0 &&
              raw.LegacyUnsealedBowlQuestionResult is null,
              "السياق غير المؤسس لا يقبل السؤال");

        foreach(var invalid in new[]{0,-1,7})
        {
            rejected=false;
            try{new MonsterManager().ExecuteLegacyUnsealedBowlQuestion(
                foundation,foundation,invalid,21);}
            catch(MonsterValidationException){rejected=true;}
            Check(rejected,"هوية وعاء باطلة "+invalid);
        }
        foreach(var invalid in new[]{0,-1,22,32})
        {
            rejected=false;
            try{new MonsterManager().ExecuteLegacyUnsealedBowlQuestion(
                foundation,foundation,1,invalid);}
            catch(MonsterValidationException){rejected=true;}
            Check(rejected,"رفض حاتم ليس 21 أو 31 "+invalid);
        }

        var ready=new MonsterManager().Prepare(foundation,foundation);
        ready.LegacyQueriedBowlId=3;
        ready.LegacyBowlQuestionSeal=31;
        var candidate=new LegacyUnsealedBowlQuestionPhaseHandler().Handle(ready);
        var valid=new MonsterValidationManager();
        var core=candidate.Historical.Historical.Sauce;
        valid.ValidateVisibleDropPatch(ready,core.Historical.Source);
        valid.ValidateLegacyOverwrittenSauce(ready,core.Historical);
        valid.ValidateProtectedDrop46Sauce(ready,core);
        valid.ValidateLegacyFixedNextBowl(ready,candidate.Historical.Historical);
        valid.ValidatePatchedNextBowl(ready,candidate.Historical);
        valid.ValidateLegacyUnsealedBowlQuestion(ready,candidate);
        Check(ready.Status=="BOOTSTRAP_READY" &&
              ready.LegacyUnsealedBowlQuestionResult is null &&
              ready.PatchedNextBowlResult is null &&
              ready.PatchedSauceFinalBowls is null &&
              ready.BranchTrace.SequenceEqual(new[]{"BOOTSTRAP_VALIDATION"}),
              "الفحص يسبق تثبيت جميع السجلات");

        void Reject(LegacyUnsealedBowlQuestionCandidate candidateBad,string label)
        {
            var failed=false;
            try{valid.ValidateLegacyUnsealedBowlQuestion(ready,candidateBad);}
            catch(MonsterValidationException){failed=true;}
            Check(failed && ready.LegacyUnsealedBowlQuestionResult is null &&
                  ready.PatchedNextBowlResult is null &&
                  ready.BranchTrace.SequenceEqual(new[]{"BOOTSTRAP_VALIDATION"}),
                  "رفض تعديل مرشح السؤال قبل الالتزام "+label);
        }
        Reject(candidate with {Seal=21},"تغيير الحاتم");
        Reject(candidate with {Answer=candidate.Answer with {First=BigInteger.Zero}},
               "إجابة صفرية");
        Reject(candidate with {Answer=candidate.Answer with {
            First=candidate.Answer.First+1}}, "إجابة محوّرة");
        Reject(candidate with {Answer=candidate.Answer with {
            DirectionStep=0}}, "اتجاه غير مقبول");
        Reject(candidate with {Historical=candidate.Historical with {
            NextBowlId=candidate.Historical.NextBowlId%6+1}},
            "تبديل نتيجة الرقعة الثانية عشرة");
    }
}
