using System.Numerics;
using PastafarianCalendar.Monster;
using PastafarianCalendar.Stage01Tests.Normative;

namespace PastafarianCalendar.Stage36Tests;

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
              "السياق وذاكرة كل استدعاء مستقلان");
        var oldBowls=(BigInteger[])b.PatchedSauceFinalBowls!.Clone();
        var saved=b.LegacyRejectionDirectionRankResult;
        a.PatchedSauceFinalBowls![1]=0;
        Check(b.PatchedSauceFinalBowls!.SequenceEqual(oldBowls) &&
              b.LegacyRejectionDirectionRankResult==saved,
              "عدم تسرّب التغيير من سياق آخر");

        var dispatch=new MonsterDispatcher(new MonsterValidationManager(),
                                             new MonsterMetricsManager());
        var trace=b.BranchTrace.ToArray();
        var denied=false;
        try{dispatch.DispatchLegacyWideRejectionDirection(b);}
        catch(MonsterValidationException){denied=true;}
        Check(denied && b.BranchTrace.SequenceEqual(trace) &&
              b.LegacyRejectionDirectionRankResult==saved,
              "رفض تكرار الالتزام دون كتابة");

        var f=NormativeScroll.FoundationDay;
        var m=NormativeScroll.M;
        var raw=new MonsterContext(f,f){
            LegacyQueriedBowlId=1,LegacyBowlQuestionSeal=21,
            LegacyAnswerStepIndex=0,LegacyWideFamilySize=m+1};
        denied=false;
        try{dispatch.DispatchLegacyWideRejectionDirection(raw);}
        catch(MonsterValidationException){denied=true;}
        Check(denied && raw.Status=="NEW" && raw.BranchTrace.Count==0 &&
              raw.LegacyRejectionDirectionRankResult is null,
              "عدم قبول سياق غير مؤسس");

        foreach(var size in new BigInteger[]{-1,0,1,m})
        {
            denied=false;
            try{new MonsterManager().ExecuteLegacyWideRejectionDirection(f,f,1,21,size);}
            catch(MonsterValidationException){denied=true;}
            Check(denied,"رفض حجم أسرة غير واسع");
        }
        foreach(var id in new[]{-1,0,7})
        {
            denied=false;
            try{new MonsterManager().ExecuteLegacyWideRejectionDirection(f,f,id,21,m+1);}
            catch(MonsterValidationException){denied=true;}
            Check(denied,"رفض هوية وعاء غير قانونية");
        }
        foreach(var seal in new[]{0,20,22,30,32})
        {
            denied=false;
            try{new MonsterManager().ExecuteLegacyWideRejectionDirection(f,f,1,seal,m+1);}
            catch(MonsterValidationException){denied=true;}
            Check(denied,"رفض حاتم السؤال غير القانوني");
        }
        var chooser=new LegacyWideRejectionDirection();
        foreach(var stream in new[]{
            new LegacyBowlQuestionResult(0,1),
            new LegacyBowlQuestionResult(m+1,1),
            new LegacyBowlQuestionResult(1,0),
            new LegacyBowlQuestionResult(1,2)})
        {
            denied=false;
            try{chooser.Choose(stream,m+1);}
            catch(MonsterValidationException){denied=true;}
            Check(denied,"رفض مجرى جواب غير صالح");
        }

        var ready=new MonsterManager().Prepare(f,f);
        ready.LegacyQueriedBowlId=3;
        ready.LegacyBowlQuestionSeal=31;
        ready.LegacyAnswerStepIndex=BigInteger.Zero;
        ready.LegacyWideFamilySize=m*m-1;
        var candidate=new LegacyWideRejectionDirectionPhaseHandler().Handle(ready);
        var repaired=candidate.Previous;
        var prior=repaired.Historical;
        var wide=prior.Previous;
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
        validator.ValidateLegacyInclusiveWideLimit(ready,prior);
        validator.ValidatePatchedInclusiveWideLimit(ready,repaired);
        validator.ValidateLegacyWideRejectionDirection(ready,candidate);
        Check(ready.Status=="BOOTSTRAP_READY" &&
              ready.LegacyRejectionDirectionRankResult is null &&
              ready.PatchedInclusiveWideLimitRankResult is null &&
              ready.PatchedSauceFinalBowls is null &&
              ready.BranchTrace.SequenceEqual(new[]{"BOOTSTRAP_VALIDATION"}),
              "جميع المدققات دون كتابة دلالية");

        void Reject(LegacyWideRejectionDirectionCandidate changed,string label)
        {
            var rejected=false;
            try{validator.ValidateLegacyWideRejectionDirection(ready,changed);}
            catch(MonsterValidationException){rejected=true;}
            Check(rejected && ready.Status=="BOOTSTRAP_READY" &&
                  ready.LegacyRejectionDirectionRankResult is null &&
                  ready.PatchedInclusiveWideLimitRankResult is null &&
                  ready.PatchedSauceFinalBowls is null &&
                  ready.BranchTrace.SequenceEqual(new[]{"BOOTSTRAP_VALIDATION"}),
                  "مرشح مبدّل يرفض قبل الالتزام "+label);
        }
        Reject(candidate with {Rank=0},"رتبة صفرية");
        Reject(candidate with {Rank=candidate.Rank+1},"تغيير النتيجة التاريخية");
        Reject(candidate with {Previous=repaired with {Rank=repaired.Rank+1}},
               "تغيّر الرتبة المصححة");
        Reject(candidate with {Previous=repaired with {Historical=prior with {
            Rank=prior.Rank+1}}},"تغيير شاهد رفض المساواة");
        Reject(candidate with {Previous=repaired with {Historical=prior with {
            Previous=wide with {Rank=wide.Rank+1}}}},"تغيير شاهد خانات M");
        Reject(candidate with {Previous=repaired with {Historical=prior with {
            Previous=wide with {Historical=oldWide with {
                Step=step with {Value=0}}}}}},"تحريف الجواب المصحح");
        Reject(candidate with {Previous=repaired with {Historical=prior with {
            Previous=wide with {Historical=oldWide with {
                Step=step with {Historical=oneBased with {K=1}}}}}}},
            "تغيير موضع التيار الصفري");
    }
}
