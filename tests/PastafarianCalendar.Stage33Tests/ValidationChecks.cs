using System.Numerics;
using PastafarianCalendar.Monster;
using PastafarianCalendar.Stage01Tests.Normative;

namespace PastafarianCalendar.Stage33Tests;

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
              "السياقات لا تشارك الحالة الدلالية");
        var savedBowls=(BigInteger[])b.PatchedSauceFinalBowls!.Clone();
        var savedOrder=(int[])b.PatchedOrderAt46Latch!.Clone();
        a.PatchedSauceFinalBowls![1]=0;
        a.PatchedOrderAt46Latch![0]=-1;
        Check(b.PatchedSauceFinalBowls!.SequenceEqual(savedBowls) &&
              b.PatchedOrderAt46Latch!.SequenceEqual(savedOrder) &&
              b.PatchedWideRankResult.HasValue && b.LegacyReversedWideRankResult.HasValue,
              "فساد محلي لا يتسرّب إلى سياق مجاور");

        var dispatcher=new MonsterDispatcher(
            new MonsterValidationManager(),new MonsterMetricsManager());
        var trace=b.BranchTrace.ToArray();
        var previous=b.LegacyReversedWideRankResult;
        var repaired=b.PatchedWideRankResult;
        var rejected=false;
        try{dispatcher.DispatchPatchedWideRank(b);}
        catch(MonsterValidationException){rejected=true;}
        Check(rejected && b.BranchTrace.SequenceEqual(trace) &&
              b.LegacyReversedWideRankResult==previous &&
              b.PatchedWideRankResult==repaired &&
              b.Metrics["patched.wide.digit.order.dispatch"]==1,
              "إعادة الالتزام مرفوضة بلا تغيير");

        var foundation=NormativeScroll.FoundationDay;
        var m=NormativeScroll.M;
        var raw=new MonsterContext(foundation,foundation){
            LegacyQueriedBowlId=1,LegacyBowlQuestionSeal=21,
            LegacyAnswerStepIndex=0,LegacyWideFamilySize=m+1};
        rejected=false;
        try{dispatcher.DispatchPatchedWideRank(raw);}
        catch(MonsterValidationException){rejected=true;}
        Check(rejected && raw.Status=="NEW" && raw.BranchTrace.Count==0 &&
              raw.PatchedWideRankResult is null,
              "السياق غير المؤسس مرفوض");

        foreach(var size in new BigInteger[]{-1,0,1,m})
        {
            rejected=false;
            try{new MonsterManager().ExecutePatchedWideRank(
                foundation,foundation,1,21,size);}
            catch(MonsterValidationException){rejected=true;}
            Check(rejected,"حجم أسرة غير واسع");
        }
        foreach(var id in new[]{-1,0,7})
        {
            rejected=false;
            try{new MonsterManager().ExecutePatchedWideRank(
                foundation,foundation,id,21,m+1);}
            catch(MonsterValidationException){rejected=true;}
            Check(rejected,"هوية وعاء غير صالحة");
        }
        foreach(var seal in new[]{0,20,22,30,32})
        {
            rejected=false;
            try{new MonsterManager().ExecutePatchedWideRank(
                foundation,foundation,1,seal,m+1);}
            catch(MonsterValidationException){rejected=true;}
            Check(rejected,"حاتم سؤال غير صالح");
        }
        var chooser=new WideDigitOrderPatchWrapper();
        foreach(var invalid in new[]{
            new LegacyBowlQuestionResult(0,1),
            new LegacyBowlQuestionResult(m+1,1),
            new LegacyBowlQuestionResult(1,0),
            new LegacyBowlQuestionResult(1,2)})
        {
            rejected=false;
            try{chooser.Patch(invalid,m+1);}
            catch(MonsterValidationException){rejected=true;}
            Check(rejected,"الغلاف يرفض سؤالاً غير قانوني");
        }

        var ready=new MonsterManager().Prepare(foundation,foundation);
        ready.LegacyQueriedBowlId=3;
        ready.LegacyBowlQuestionSeal=31;
        ready.LegacyAnswerStepIndex=BigInteger.Zero;
        ready.LegacyWideFamilySize=m+1;
        var candidate=new PatchedWideRankPhaseHandler().Handle(ready);
        var oldWide=candidate.Historical;
        var step=oldWide.Step;
        var oneBased=step.Historical;
        var sealedQuestion=oneBased.Question;
        var oldQuestion=sealedQuestion.Historical;
        var correctedNext=oldQuestion.Historical;
        var oldNext=correctedNext.Historical;
        var validator=new MonsterValidationManager();
        validator.ValidateVisibleDropPatch(ready,oldNext.Sauce.Historical.Source);
        validator.ValidateLegacyOverwrittenSauce(ready,oldNext.Sauce.Historical);
        validator.ValidateProtectedDrop46Sauce(ready,oldNext.Sauce);
        validator.ValidateLegacyFixedNextBowl(ready,oldNext);
        validator.ValidatePatchedNextBowl(ready,correctedNext);
        validator.ValidateLegacyUnsealedBowlQuestion(ready,oldQuestion);
        validator.ValidatePatchedBowlQuestion(ready,sealedQuestion);
        validator.ValidateLegacyOneBasedAnswerStep(ready,oneBased);
        validator.ValidatePatchedAnswerStep(ready,step);
        validator.ValidateLegacyReversedWideRank(ready,oldWide);
        validator.ValidatePatchedWideRank(ready,candidate);
        Check(ready.Status=="BOOTSTRAP_READY" &&
              ready.PatchedWideRankResult is null &&
              ready.LegacyReversedWideRankResult is null &&
              ready.PatchedSauceFinalBowls is null &&
              ready.BranchTrace.SequenceEqual(new[]{"BOOTSTRAP_VALIDATION"}),
              "التحقق لا يغيّر حالة السياق");

        void Reject(PatchedWideRankCandidate altered,string label)
        {
            var denied=false;
            try{validator.ValidatePatchedWideRank(ready,altered);}
            catch(MonsterValidationException){denied=true;}
            Check(denied && ready.Status=="BOOTSTRAP_READY" &&
                  ready.PatchedWideRankResult is null &&
                  ready.LegacyReversedWideRankResult is null &&
                  ready.PatchedSauceFinalBowls is null &&
                  ready.BranchTrace.SequenceEqual(new[]{"BOOTSTRAP_VALIDATION"}),
                  "مرشح مغير مرفوض قبل الالتزام "+label);
        }
        Reject(candidate with {Rank=0},"رتبة صفرية");
        Reject(candidate with {Rank=candidate.Rank+1},"تغيير النتيجة");
        Reject(candidate with {Historical=oldWide with {FamilySize=oldWide.FamilySize+1}},
               "تغيير حجم الأسرة");
        Reject(candidate with {Historical=oldWide with {Rank=oldWide.Rank+1}},
               "حذف شاهد العيب");
        Reject(candidate with {Historical=oldWide with {Step=step with {Value=0}}},
               "تزييف الإجابة الأولى");
        Reject(candidate with {Historical=oldWide with {Step=step with {
            Historical=oneBased with {K=1}}}},"تعديل الموضع الصفري");
        Reject(candidate with {Historical=oldWide with {Step=step with {
            Historical=oneBased with {Question=sealedQuestion with {
                Answer=sealedQuestion.Answer with {
                    DirectionStep=-sealedQuestion.Answer.DirectionStep}}}}}},
               "تغيير اتجاه الجواب المختوم");
    }
}
