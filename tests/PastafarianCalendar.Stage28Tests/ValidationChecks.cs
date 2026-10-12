using System.Numerics;
using PastafarianCalendar.Monster;
using PastafarianCalendar.Stage01Tests.Normative;

namespace PastafarianCalendar.Stage28Tests;

internal static partial class Program
{
    private static void CheckOwnershipAndRejection()
    {
        var a=Contexts[0];
        var b=Contexts[1];
        Check(!ReferenceEquals(a,b) &&
              !ReferenceEquals(a.PatchedSauceFinalBowls,b.PatchedSauceFinalBowls) &&
              !ReferenceEquals(a.LegacySauceFinalBowls,b.LegacySauceFinalBowls) &&
              !ReferenceEquals(a.PatchedOrderAt46Latch,b.PatchedOrderAt46Latch) &&
              !ReferenceEquals(a.BranchTrace,b.BranchTrace) &&
              !ReferenceEquals(a.Metrics,b.Metrics),
              "ملكية كل سؤال مستقلة حتى مع الأخطاء القديمة");
        var bowlsB=(BigInteger[])b.PatchedSauceFinalBowls!.Clone();
        var orderB=(int[])b.PatchedOrderAt46Latch!.Clone();
        a.PatchedSauceFinalBowls![1]=0;
        a.PatchedOrderAt46Latch![0]=-19;
        Check(b.PatchedSauceFinalBowls!.SequenceEqual(bowlsB) &&
              b.PatchedOrderAt46Latch!.SequenceEqual(orderB) &&
              b.LegacyOneBasedAnswerAtResult is not null,
              "فساد مخزن سؤال لا يؤثر في سؤال آخر");

        var dispatcher=new MonsterDispatcher(
            new MonsterValidationManager(),new MonsterMetricsManager());
        var oldTrace=b.BranchTrace.ToArray();
        var oldAnswer=b.LegacyOneBasedAnswerAtResult;
        var rejected=false;
        try{dispatcher.DispatchLegacyOneBasedAnswer(b);}
        catch(MonsterValidationException){rejected=true;}
        Check(rejected && b.BranchTrace.SequenceEqual(oldTrace) &&
              b.LegacyOneBasedAnswerAtResult==oldAnswer &&
              b.Metrics["legacy.one.based.answer.step.dispatch"]==1,
              "التكرار مرفوض قبل التزام جديد");

        var f=NormativeScroll.FoundationDay;
        var raw=new MonsterContext(f,f){
            LegacyQueriedBowlId=1,LegacyBowlQuestionSeal=21,LegacyAnswerStepIndex=0};
        rejected=false;
        try{dispatcher.DispatchLegacyOneBasedAnswer(raw);}
        catch(MonsterValidationException){rejected=true;}
        Check(rejected && raw.Status=="NEW" && raw.BranchTrace.Count==0 &&
              raw.LegacyOneBasedAnswerAtResult is null,
              "رفض السياق غير المؤسس دون تغيير");

        foreach(var invalid in new[]{-1,0,7})
        {
            rejected=false;
            try{new MonsterManager().ExecuteLegacyOneBasedAnswer(f,f,invalid,21,0);}
            catch(MonsterValidationException){rejected=true;}
            Check(rejected,"رفض هوية وعاء باطلة "+invalid);
        }
        foreach(var invalid in new[]{0,22,30,32})
        {
            rejected=false;
            try{new MonsterManager().ExecuteLegacyOneBasedAnswer(f,f,1,invalid,0);}
            catch(MonsterValidationException){rejected=true;}
            Check(rejected,"رفض حاتم غير مشروع "+invalid);
        }
        rejected=false;
        try{new MonsterManager().ExecuteLegacyOneBasedAnswer(f,f,1,21,-1);}
        catch(MonsterValidationException){rejected=true;}
        Check(rejected,"رفض خطوة سالبة");

        var stepper=new LegacyOneBasedAnswerStep();
        foreach(var stream in new[]{
            new LegacyBowlQuestionResult(0,1),
            new LegacyBowlQuestionResult(NormativeScroll.M+1,1),
            new LegacyBowlQuestionResult(1,0),
            new LegacyBowlQuestionResult(1,2)})
        {
            rejected=false;
            try{stepper.At(stream,0);}
            catch(MonsterValidationException){rejected=true;}
            Check(rejected,"رفض مجرى إجابة غير صالح");
        }

        var ready=new MonsterManager().Prepare(f,f);
        ready.LegacyQueriedBowlId=2;
        ready.LegacyBowlQuestionSeal=31;
        ready.LegacyAnswerStepIndex=NormativeScroll.M+1;
        var candidate=new LegacyOneBasedAnswerPhaseHandler().Handle(ready);
        var patchedQ=candidate.Question;
        var oldQ=patchedQ.Historical;
        var patchedN=oldQ.Historical;
        var oldN=patchedN.Historical;
        var validator=new MonsterValidationManager();
        validator.ValidateVisibleDropPatch(ready,oldN.Sauce.Historical.Source);
        validator.ValidateLegacyOverwrittenSauce(ready,oldN.Sauce.Historical);
        validator.ValidateProtectedDrop46Sauce(ready,oldN.Sauce);
        validator.ValidateLegacyFixedNextBowl(ready,oldN);
        validator.ValidatePatchedNextBowl(ready,patchedN);
        validator.ValidateLegacyUnsealedBowlQuestion(ready,oldQ);
        validator.ValidatePatchedBowlQuestion(ready,patchedQ);
        validator.ValidateLegacyOneBasedAnswerStep(ready,candidate);
        Check(ready.Status=="BOOTSTRAP_READY" &&
              ready.LegacyOneBasedAnswerAtResult is null &&
              ready.PatchedBowlQuestionResult is null &&
              ready.PatchedSauceFinalBowls is null &&
              ready.BranchTrace.SequenceEqual(new[]{"BOOTSTRAP_VALIDATION"}),
              "كل تحقق سابق للالتزام لا يغيّر الحالة");

        void Reject(LegacyOneBasedAnswerCandidate altered,string label)
        {
            var denied=false;
            try{validator.ValidateLegacyOneBasedAnswerStep(ready,altered);}
            catch(MonsterValidationException){denied=true;}
            Check(denied && ready.Status=="BOOTSTRAP_READY" &&
                  ready.LegacyOneBasedAnswerAtResult is null &&
                  ready.PatchedBowlQuestionResult is null &&
                  ready.PatchedSauceFinalBowls is null &&
                  ready.BranchTrace.SequenceEqual(new[]{"BOOTSTRAP_VALIDATION"}),
                  "رفض مرشح غير صحيح قبل الالتزام "+label);
        }
        Reject(candidate with {Value=0},"جواب صفري");
        Reject(candidate with {Value=candidate.Value==NormativeScroll.M?
            BigInteger.One:candidate.Value+1},"التلاعب بالإجابة");
        Reject(candidate with {K=candidate.K+1},"تبديل رقم الخطوة");
        Reject(candidate with {Question=patchedQ with {
            Answer=patchedQ.Answer with {DirectionStep=-patchedQ.Answer.DirectionStep}}},
            "تبديل الاتجاه المصحح");
        Reject(candidate with {Question=patchedQ with {
            Historical=oldQ with {Seal=21}}},
            "تبديل حاتم السؤال");
    }
}
