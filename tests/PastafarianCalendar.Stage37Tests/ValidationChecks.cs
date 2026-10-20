using System.Numerics;
using PastafarianCalendar.Monster;
using PastafarianCalendar.Stage01Tests.Normative;

namespace PastafarianCalendar.Stage37Tests;

internal static partial class Program
{
    private static void ValidationAndOwnership()
    {
        var a=Contexts[0];var b=Contexts[1];
        Check(!ReferenceEquals(a,b) &&
              !ReferenceEquals(a.PatchedSauceFinalBowls,b.PatchedSauceFinalBowls) &&
              !ReferenceEquals(a.LegacySauceFinalBowls,b.LegacySauceFinalBowls) &&
              !ReferenceEquals(a.PatchedOrderAt46Latch,b.PatchedOrderAt46Latch) &&
              !ReferenceEquals(a.Metrics,b.Metrics) &&
              !ReferenceEquals(a.BranchTrace,b.BranchTrace),
              "الطلبات لا تتشارك بيانات دلالية قابلة للتغيير");
        var bowls=(BigInteger[])b.PatchedSauceFinalBowls!.Clone();
        var preserved=b.PatchedRejectionDirectionRankResult;
        a.PatchedSauceFinalBowls![1]=0;
        Check(b.PatchedSauceFinalBowls!.SequenceEqual(bowls) &&
              b.PatchedRejectionDirectionRankResult==preserved,
              "التغيير المحلي لا يؤثر على سياق مستقل");

        var dispatcher=new MonsterDispatcher(
            new MonsterValidationManager(),new MonsterMetricsManager());
        var before=b.BranchTrace.ToArray();
        var oldResult=b.LegacyRejectionDirectionRankResult;
        var denied=false;
        try{dispatcher.DispatchPatchedRejectionDirection(b);}
        catch(MonsterValidationException){denied=true;}
        Check(denied && b.BranchTrace.SequenceEqual(before) &&
              b.LegacyRejectionDirectionRankResult==oldResult &&
              b.PatchedRejectionDirectionRankResult==preserved &&
              b.Metrics["patched.rejection.direction.dispatch"]==1,
              "رفض تكرار الالتزام قبل كتابة أي نتيجة");

        var f=NormativeScroll.FoundationDay;
        var m=NormativeScroll.M;
        var raw=new MonsterContext(f,f){
            LegacyQueriedBowlId=1,LegacyBowlQuestionSeal=21,
            LegacyAnswerStepIndex=BigInteger.Zero,LegacyWideFamilySize=m+1};
        denied=false;
        try{dispatcher.DispatchPatchedRejectionDirection(raw);}
        catch(MonsterValidationException){denied=true;}
        Check(denied && raw.Status=="NEW" && raw.BranchTrace.Count==0 &&
              raw.PatchedRejectionDirectionRankResult is null,
              "رفض سياق لم يُؤسس");

        foreach(var size in new BigInteger[]{-1,0,1,m})
        {
            denied=false;
            try{new MonsterManager().ExecutePatchedRejectionDirection(f,f,1,21,size);}
            catch(MonsterValidationException){denied=true;}
            Check(denied,"حجم أسرة غير واسع");
        }
        foreach(var id in new[]{-1,0,7})
        {
            denied=false;
            try{new MonsterManager().ExecutePatchedRejectionDirection(f,f,id,21,m+1);}
            catch(MonsterValidationException){denied=true;}
            Check(denied,"هوية وعاء غير قانونية");
        }
        foreach(var seal in new[]{0,20,22,30,32})
        {
            denied=false;
            try{new MonsterManager().ExecutePatchedRejectionDirection(f,f,1,seal,m+1);}
            catch(MonsterValidationException){denied=true;}
            Check(denied,"حاتم سؤال غير قانوني");
        }

        var ready=new MonsterManager().Prepare(f,f);
        ready.LegacyQueriedBowlId=3;
        ready.LegacyBowlQuestionSeal=31;
        ready.LegacyAnswerStepIndex=BigInteger.Zero;
        ready.LegacyWideFamilySize=m*m-1;
        var candidate=new PatchedRejectionDirectionPhaseHandler().Handle(ready);
        var legacy=candidate.Historical;
        var repaired=legacy.Previous;
        var oldLimit=repaired.Historical;
        var wide=oldLimit.Previous;
        var oldWide=wide.Historical;
        var step=oldWide.Step;
        var oneBased=step.Historical;
        var question=oneBased.Question;
        var oldQuestion=question.Historical;
        var next=oldQuestion.Historical;
        var oldNext=next.Historical;
        var validator=new MonsterValidationManager();
        validator.ValidateVisibleDropPatch(ready,oldNext.Sauce.Historical.Source);
        validator.ValidateLegacyOverwrittenSauce(ready,oldNext.Sauce.Historical);
        validator.ValidateProtectedDrop46Sauce(ready,oldNext.Sauce);
        validator.ValidateLegacyFixedNextBowl(ready,oldNext);
        validator.ValidatePatchedNextBowl(ready,next);
        validator.ValidateLegacyUnsealedBowlQuestion(ready,oldQuestion);
        validator.ValidatePatchedBowlQuestion(ready,question);
        validator.ValidateLegacyOneBasedAnswerStep(ready,oneBased);
        validator.ValidatePatchedAnswerStep(ready,step);
        validator.ValidateLegacyReversedWideRank(ready,oldWide);
        validator.ValidatePatchedWideRank(ready,wide);
        validator.ValidateLegacyInclusiveWideLimit(ready,oldLimit);
        validator.ValidatePatchedInclusiveWideLimit(ready,repaired);
        validator.ValidateLegacyWideRejectionDirection(ready,legacy);
        validator.ValidatePatchedRejectionDirection(ready,candidate);
        Check(ready.Status=="BOOTSTRAP_READY" &&
              ready.PatchedRejectionDirectionRankResult is null &&
              ready.LegacyRejectionDirectionRankResult is null &&
              ready.PatchedSauceFinalBowls is null &&
              ready.BranchTrace.SequenceEqual(new[]{"BOOTSTRAP_VALIDATION"}),
              "التحقق المسبق لا يكتب حالة دلالية");

        void Reject(PatchedRejectionDirectionCandidate changed,string label)
        {
            var rejected=false;
            try{validator.ValidatePatchedRejectionDirection(ready,changed);}
            catch(MonsterValidationException){rejected=true;}
            Check(rejected && ready.Status=="BOOTSTRAP_READY" &&
                  ready.PatchedRejectionDirectionRankResult is null &&
                  ready.LegacyRejectionDirectionRankResult is null &&
                  ready.PatchedSauceFinalBowls is null &&
                  ready.BranchTrace.SequenceEqual(new[]{"BOOTSTRAP_VALIDATION"}),
                  "رفض التزوير دون كتابة "+label);
        }
        Reject(candidate with {Rank=0},"رتبة صفرية");
        Reject(candidate with {Rank=candidate.Rank+1},"تغيير المرتبة الصحيحة");
        Reject(candidate with {Historical=legacy with {Rank=legacy.Rank+1}},
               "محو الشاهد التاريخي");
        Reject(candidate with {Historical=legacy with {
            Previous=repaired with {Rank=repaired.Rank+1}}},
            "تغيير نتيجة الرقعة السابعة عشرة");
        Reject(candidate with {Historical=legacy with {
            Previous=repaired with {Historical=oldLimit with {
                Rank=oldLimit.Rank+1}}}},
            "تزوير شاهد حد القبول");
        Reject(candidate with {Historical=legacy with {
            Previous=repaired with {Historical=oldLimit with {
                Previous=wide with {Rank=wide.Rank+1}}}}},
            "تزوير شاهد الخانات المصححة");
        Reject(candidate with {Historical=legacy with {
            Previous=repaired with {Historical=oldLimit with {
                Previous=wide with {Historical=oldWide with {
                    Step=step with {Value=0}}}}}}},
            "تزييف الجواب المصحح");
    }
}
