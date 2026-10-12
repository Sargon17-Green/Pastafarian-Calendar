using System.Numerics;
using PastafarianCalendar.Monster;
using PastafarianCalendar.Stage01Tests.Normative;

namespace PastafarianCalendar.Stage29Tests;

internal static partial class Program
{
    private static void ValidationAndOwnership()
    {
        var a=Contexts[0];
        var b=Contexts[1];
        Check(!ReferenceEquals(a,b) &&
              !ReferenceEquals(a.PatchedSauceFinalBowls,b.PatchedSauceFinalBowls) &&
              !ReferenceEquals(a.LegacySauceFinalBowls,b.LegacySauceFinalBowls) &&
              !ReferenceEquals(a.PatchedOrderAt46Latch,b.PatchedOrderAt46Latch) &&
              !ReferenceEquals(a.BranchTrace,b.BranchTrace) &&
              !ReferenceEquals(a.Metrics,b.Metrics),
              "ملكية كل سؤال مستقلة عن الأسئلة الأخرى");
        var savedB=(BigInteger[])b.PatchedSauceFinalBowls!.Clone();
        var savedOrder=(int[])b.PatchedOrderAt46Latch!.Clone();
        a.PatchedSauceFinalBowls![1]=0;
        a.PatchedOrderAt46Latch![0]=-1;
        Check(b.PatchedSauceFinalBowls!.SequenceEqual(savedB) &&
              b.PatchedOrderAt46Latch!.SequenceEqual(savedOrder) &&
              b.PatchedAnswerAtResult.HasValue &&
              b.LegacyOneBasedAnswerAtResult.HasValue,
              "تعديل سؤال لا يسرّب الفساد إلى سؤال ثان");

        var dispatcher=new MonsterDispatcher(
            new MonsterValidationManager(),new MonsterMetricsManager());
        var trace=b.BranchTrace.ToArray();
        var old=b.LegacyOneBasedAnswerAtResult;
        var repaired=b.PatchedAnswerAtResult;
        var rejected=false;
        try{dispatcher.DispatchPatchedAnswerStep(b);}
        catch(MonsterValidationException){rejected=true;}
        Check(rejected && trace.SequenceEqual(b.BranchTrace) &&
              b.LegacyOneBasedAnswerAtResult==old &&
              b.PatchedAnswerAtResult==repaired &&
              b.Metrics["patched.zero.based.answer.step.dispatch"]==1,
              "رفض محاولة الالتزام المكرر دون كتابة");

        var f=NormativeScroll.FoundationDay;
        var raw=new MonsterContext(f,f){
            LegacyQueriedBowlId=1,LegacyBowlQuestionSeal=21,LegacyAnswerStepIndex=0};
        rejected=false;
        try{dispatcher.DispatchPatchedAnswerStep(raw);}
        catch(MonsterValidationException){rejected=true;}
        Check(rejected && raw.Status=="NEW" &&
              raw.BranchTrace.Count==0 && raw.PatchedAnswerAtResult is null,
              "رفض حالة غير مهيأة دون التزام");

        foreach(var bad in new[]{-1,0,7})
        {
            rejected=false;
            try{new MonsterManager().ExecutePatchedAnswerStep(f,f,bad,21,0);}
            catch(MonsterValidationException){rejected=true;}
            Check(rejected,"رفض هوية وعاء غير قانونية "+bad);
        }
        foreach(var bad in new[]{0,20,22,30,32})
        {
            rejected=false;
            try{new MonsterManager().ExecutePatchedAnswerStep(f,f,1,bad,0);}
            catch(MonsterValidationException){rejected=true;}
            Check(rejected,"رفض حاتم غير مسموح "+bad);
        }
        rejected=false;
        try{new MonsterManager().ExecutePatchedAnswerStep(f,f,1,21,-1);}
        catch(MonsterValidationException){rejected=true;}
        Check(rejected,"رفض فهرس سالب في المدير");

        var wrapper=new AnswerStepZeroBasedPatchWrapper();
        foreach(var stream in new[]{
            new LegacyBowlQuestionResult(0,1),
            new LegacyBowlQuestionResult(NormativeScroll.M+1,1),
            new LegacyBowlQuestionResult(1,0),
            new LegacyBowlQuestionResult(1,2),
            new LegacyBowlQuestionResult(1,-2)})
        {
            rejected=false;
            try{wrapper.Patch(stream,0);}
            catch(MonsterValidationException){rejected=true;}
            Check(rejected,"رفض مجرى غير قانوني في الغلاف");
        }
        rejected=false;
        try{wrapper.Patch(new LegacyBowlQuestionResult(1,1),-1);}
        catch(MonsterValidationException){rejected=true;}
        Check(rejected,"رفض خطوة سالبة في الغلاف");

        var ready=new MonsterManager().Prepare(f,f);
        ready.LegacyQueriedBowlId=4;
        ready.LegacyBowlQuestionSeal=31;
        ready.LegacyAnswerStepIndex=NormativeScroll.M+1;
        var candidate=new PatchedAnswerStepPhaseHandler().Handle(ready);
        var oneBased=candidate.Historical;
        var sealedQuestion=oneBased.Question;
        var oldQuestion=sealedQuestion.Historical;
        var nextPatched=oldQuestion.Historical;
        var nextOld=nextPatched.Historical;
        var validator=new MonsterValidationManager();
        validator.ValidateVisibleDropPatch(ready,nextOld.Sauce.Historical.Source);
        validator.ValidateLegacyOverwrittenSauce(ready,nextOld.Sauce.Historical);
        validator.ValidateProtectedDrop46Sauce(ready,nextOld.Sauce);
        validator.ValidateLegacyFixedNextBowl(ready,nextOld);
        validator.ValidatePatchedNextBowl(ready,nextPatched);
        validator.ValidateLegacyUnsealedBowlQuestion(ready,oldQuestion);
        validator.ValidatePatchedBowlQuestion(ready,sealedQuestion);
        validator.ValidateLegacyOneBasedAnswerStep(ready,oneBased);
        validator.ValidatePatchedAnswerStep(ready,candidate);
        Check(ready.Status=="BOOTSTRAP_READY" &&
              ready.PatchedAnswerAtResult is null &&
              ready.LegacyOneBasedAnswerAtResult is null &&
              ready.PatchedBowlQuestionResult is null &&
              ready.PatchedSauceFinalBowls is null &&
              ready.BranchTrace.SequenceEqual(new[]{"BOOTSTRAP_VALIDATION"}),
              "التدقيق لا يكتب حالة دلالية");

        void Reject(PatchedAnswerStepCandidate bad,string reason)
        {
            var failed=false;
            try{validator.ValidatePatchedAnswerStep(ready,bad);}
            catch(MonsterValidationException){failed=true;}
            Check(failed && ready.Status=="BOOTSTRAP_READY" &&
                  ready.PatchedAnswerAtResult is null &&
                  ready.LegacyOneBasedAnswerAtResult is null &&
                  ready.PatchedSauceFinalBowls is null &&
                  ready.BranchTrace.SequenceEqual(new[]{"BOOTSTRAP_VALIDATION"}),
                  "رفض المرشح المحوّر قبل الالتزام "+reason);
        }

        Reject(candidate with {Value=0},"الجواب الصفري");
        Reject(candidate with {Value=candidate.Value==NormativeScroll.M?1:
               candidate.Value+1},"تغيير الجواب");
        Reject(candidate with {Historical=oneBased with {K=oneBased.K+1}},
               "تغيير رقم الخطوة القديمة");
        Reject(candidate with {Historical=oneBased with {
            Value=oneBased.Value==NormativeScroll.M?1:oneBased.Value+1}},
               "إزالة الشاهد التاريخي");
        Reject(candidate with {Historical=oneBased with {
            Question=sealedQuestion with {
                Answer=sealedQuestion.Answer with {
                    DirectionStep=-sealedQuestion.Answer.DirectionStep}}}},
               "تغيير الاتجاه المصحح");
        Reject(candidate with {Historical=oneBased with {
            Question=sealedQuestion with {
                Historical=oldQuestion with {Seal=21}}}},
               "تغيير الحاتم");
    }
}
