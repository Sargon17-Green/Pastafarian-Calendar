using System.Numerics;
using PastafarianCalendar.Monster;
using PastafarianCalendar.Stage01Tests.Normative;

namespace PastafarianCalendar.Stage32Tests;

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
              "ملكية كل سياق مستقلة");
        var oldBowls=(BigInteger[])b.PatchedSauceFinalBowls!.Clone();
        var oldOrder=(int[])b.PatchedOrderAt46Latch!.Clone();
        a.PatchedSauceFinalBowls![1]=0;
        a.PatchedOrderAt46Latch![0]=-1;
        Check(b.PatchedSauceFinalBowls!.SequenceEqual(oldBowls) &&
              b.PatchedOrderAt46Latch!.SequenceEqual(oldOrder) &&
              b.LegacyReversedWideRankResult.HasValue,
              "تغيير سياق لا يلوّث سياقاً آخر");

        var dispatcher=new MonsterDispatcher(
            new MonsterValidationManager(),new MonsterMetricsManager());
        var beforeTrace=b.BranchTrace.ToArray();
        var beforeResult=b.LegacyReversedWideRankResult;
        var rejected=false;
        try{dispatcher.DispatchLegacyReversedWideRank(b);}
        catch(MonsterValidationException){rejected=true;}
        Check(rejected && b.BranchTrace.SequenceEqual(beforeTrace) &&
              b.LegacyReversedWideRankResult==beforeResult &&
              b.Metrics["legacy.reversed.wide.digits.dispatch"]==1,
              "رفض الإعادة قبل أي التزام");

        var f=NormativeScroll.FoundationDay;
        var raw=new MonsterContext(f,f){
            LegacyQueriedBowlId=1,LegacyBowlQuestionSeal=21,
            LegacyAnswerStepIndex=0,LegacyWideFamilySize=NormativeScroll.M+1};
        rejected=false;
        try{dispatcher.DispatchLegacyReversedWideRank(raw);}
        catch(MonsterValidationException){rejected=true;}
        Check(rejected && raw.Status=="NEW" && raw.BranchTrace.Count==0 &&
              raw.LegacyReversedWideRankResult is null,
              "رفض سياق بلا تأسيس دون تغيير");

        foreach(var n in new BigInteger[]{-1,0,1,NormativeScroll.M})
        {
            rejected=false;
            try{new MonsterManager().ExecuteLegacyReversedWideRank(f,f,1,21,n);}
            catch(MonsterValidationException){rejected=true;}
            Check(rejected,"رفض حجم أسرة قصيرة في المسار الواسع");
        }
        foreach(var id in new[]{-1,0,7})
        {
            rejected=false;
            try{new MonsterManager().ExecuteLegacyReversedWideRank(
                f,f,id,21,NormativeScroll.M+1);}
            catch(MonsterValidationException){rejected=true;}
            Check(rejected,"رفض هوية وعاء خارج المدى");
        }
        foreach(var seal in new[]{0,20,22,30,32})
        {
            rejected=false;
            try{new MonsterManager().ExecuteLegacyReversedWideRank(
                f,f,1,seal,NormativeScroll.M+1);}
            catch(MonsterValidationException){rejected=true;}
            Check(rejected,"رفض حاتم سؤال غير مسموح");
        }
        var chooser=new LegacyReversedWideDigits();
        foreach(var bad in new[]{
            new LegacyBowlQuestionResult(0,1),
            new LegacyBowlQuestionResult(NormativeScroll.M+1,1),
            new LegacyBowlQuestionResult(1,0),
            new LegacyBowlQuestionResult(1,2)})
        {
            rejected=false;
            try{chooser.Choose(bad,NormativeScroll.M+1);}
            catch(MonsterValidationException){rejected=true;}
            Check(rejected,"رفض تيار غير صحيح في المعالج");
        }

        var ready=new MonsterManager().Prepare(f,f);
        ready.LegacyQueriedBowlId=3;
        ready.LegacyBowlQuestionSeal=31;
        ready.LegacyAnswerStepIndex=BigInteger.Zero;
        ready.LegacyWideFamilySize=NormativeScroll.M+1;
        var candidate=new LegacyReversedWideRankPhaseHandler().Handle(ready);
        var step=candidate.Step;
        var oldStep=step.Historical;
        var sealedQuestion=oldStep.Question;
        var oldQuestion=sealedQuestion.Historical;
        var next=oldQuestion.Historical;
        var oldNext=next.Historical;
        var validator=new MonsterValidationManager();
        validator.ValidateVisibleDropPatch(ready,oldNext.Sauce.Historical.Source);
        validator.ValidateLegacyOverwrittenSauce(ready,oldNext.Sauce.Historical);
        validator.ValidateProtectedDrop46Sauce(ready,oldNext.Sauce);
        validator.ValidateLegacyFixedNextBowl(ready,oldNext);
        validator.ValidatePatchedNextBowl(ready,next);
        validator.ValidateLegacyUnsealedBowlQuestion(ready,oldQuestion);
        validator.ValidatePatchedBowlQuestion(ready,sealedQuestion);
        validator.ValidateLegacyOneBasedAnswerStep(ready,oldStep);
        validator.ValidatePatchedAnswerStep(ready,step);
        validator.ValidateLegacyReversedWideRank(ready,candidate);
        Check(ready.Status=="BOOTSTRAP_READY" &&
              ready.LegacyReversedWideRankResult is null &&
              ready.PatchedAnswerAtResult is null &&
              ready.PatchedSauceFinalBowls is null &&
              ready.BranchTrace.SequenceEqual(new[]{"BOOTSTRAP_VALIDATION"}),
              "التدقيق قبل الالتزام لم يبدّل الحالة");

        void Reject(LegacyReversedWideRankCandidate bad,string label)
        {
            var denied=false;
            try{validator.ValidateLegacyReversedWideRank(ready,bad);}
            catch(MonsterValidationException){denied=true;}
            Check(denied && ready.Status=="BOOTSTRAP_READY" &&
                  ready.LegacyReversedWideRankResult is null &&
                  ready.PatchedSauceFinalBowls is null &&
                  ready.BranchTrace.SequenceEqual(new[]{"BOOTSTRAP_VALIDATION"}),
                  "رفض تزوير المرشح قبل تثبيت الحالة "+label);
        }
        Reject(candidate with {Rank=0},"رتبة صفرية");
        Reject(candidate with {Rank=candidate.Rank+1},"تغيير الرتبة");
        Reject(candidate with {FamilySize=candidate.FamilySize+1},"تغيير حجم الأسرة");
        Reject(candidate with {Step=step with {Value=0}},"محو الخطوة الصفرية");
        Reject(candidate with {Step=step with {Historical=oldStep with {K=1}}},
               "تغيير موضع الخطوة");
        Reject(candidate with {Step=step with {Historical=oldStep with {
            Question=sealedQuestion with {Answer=sealedQuestion.Answer with {
                DirectionStep=-sealedQuestion.Answer.DirectionStep}}}}},
               "تغيير اتجاه السؤال المختوم");
    }
}
