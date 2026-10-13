using System.Numerics;
using PastafarianCalendar.Monster;
using PastafarianCalendar.Stage01Tests.Normative;

namespace PastafarianCalendar.Stage30Tests;

internal static partial class Program
{
    private static void ValidateAndOwnership()
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
        var savedB=(BigInteger[])b.PatchedSauceFinalBowls!.Clone();
        var savedOrder=(int[])b.PatchedOrderAt46Latch!.Clone();
        a.PatchedSauceFinalBowls![1]=0;
        a.PatchedOrderAt46Latch![0]=-1;
        Check(b.PatchedSauceFinalBowls!.SequenceEqual(savedB) &&
              b.PatchedOrderAt46Latch!.SequenceEqual(savedOrder) &&
              b.LegacyShortFamilyRankResult.HasValue,
              "التلف المحلي لا ينتقل إلى عملية أخرى");

        var dispatcher=new MonsterDispatcher(
            new MonsterValidationManager(),new MonsterMetricsManager());
        var beforeTrace=b.BranchTrace.ToArray();
        var beforeRank=b.LegacyShortFamilyRankResult;
        var rejected=false;
        try{dispatcher.DispatchLegacyUnshiftedShortRank(b);}
        catch(MonsterValidationException){rejected=true;}
        Check(rejected && beforeTrace.SequenceEqual(b.BranchTrace) &&
              b.LegacyShortFamilyRankResult==beforeRank &&
              b.Metrics["legacy.unshifted.short.family.rank.dispatch"]==1,
              "رفض التكرار قبل تثبيت أثر جديد");

        var f=NormativeScroll.FoundationDay;
        var raw=new MonsterContext(f,f){
            LegacyQueriedBowlId=1,LegacyBowlQuestionSeal=21,
            LegacyAnswerStepIndex=0,LegacyShortFamilySize=2};
        rejected=false;
        try{dispatcher.DispatchLegacyUnshiftedShortRank(raw);}
        catch(MonsterValidationException){rejected=true;}
        Check(rejected && raw.Status=="NEW" &&
              raw.BranchTrace.Count==0 && raw.LegacyShortFamilyRankResult is null,
              "رفض السياق غير المؤسس قبل أثر جانبي");

        foreach(var n in new[]{BigInteger.MinusOne,BigInteger.Zero,NormativeScroll.M+1})
        {
            rejected=false;
            try{new MonsterManager().ExecuteLegacyUnshiftedShortRank(f,f,1,21,n);}
            catch(MonsterValidationException){rejected=true;}
            Check(rejected,"رفض حجم أسرة خارج المدى");
        }
        foreach(var bad in new[]{0,7,-1})
        {
            rejected=false;
            try{new MonsterManager().ExecuteLegacyUnshiftedShortRank(f,f,bad,21,2);}
            catch(MonsterValidationException){rejected=true;}
            Check(rejected,"رفض هوية وعاء غير قانونية "+bad);
        }
        foreach(var bad in new[]{0,20,22,30,32})
        {
            rejected=false;
            try{new MonsterManager().ExecuteLegacyUnshiftedShortRank(f,f,1,bad,2);}
            catch(MonsterValidationException){rejected=true;}
            Check(rejected,"رفض حاتم غير قانوني "+bad);
        }

        var chooser=new LegacyUnshiftedShortRank();
        foreach(var invalid in new[]{
            new LegacyBowlQuestionResult(0,1),
            new LegacyBowlQuestionResult(NormativeScroll.M+1,1),
            new LegacyBowlQuestionResult(1,0),
            new LegacyBowlQuestionResult(1,2)})
        {
            rejected=false;
            try{chooser.Choose(invalid,2);}
            catch(MonsterValidationException){rejected=true;}
            Check(rejected,"رفض مسار جواب غير قانوني");
        }

        var ready=new MonsterManager().Prepare(f,f);
        ready.LegacyQueriedBowlId=2;
        ready.LegacyBowlQuestionSeal=31;
        ready.LegacyAnswerStepIndex=BigInteger.Zero;
        ready.LegacyShortFamilySize=31;
        var candidate=new LegacyUnshiftedShortRankPhaseHandler().Handle(ready);
        var step=candidate.Step;
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
        validator.ValidateLegacyUnshiftedShortRank(ready,candidate);
        Check(ready.Status=="BOOTSTRAP_READY" &&
              ready.LegacyShortFamilyRankResult is null &&
              ready.PatchedAnswerAtResult is null &&
              ready.PatchedSauceFinalBowls is null &&
              ready.BranchTrace.SequenceEqual(new[]{"BOOTSTRAP_VALIDATION"}),
              "جميع المدققات قبل أي كتابة دلالية");

        void MustReject(LegacyUnshiftedShortRankCandidate bad,string label)
        {
            var denied=false;
            try{validator.ValidateLegacyUnshiftedShortRank(ready,bad);}
            catch(MonsterValidationException){denied=true;}
            Check(denied && ready.Status=="BOOTSTRAP_READY" &&
                  ready.LegacyShortFamilyRankResult is null &&
                  ready.PatchedAnswerAtResult is null &&
                  ready.PatchedSauceFinalBowls is null &&
                  ready.BranchTrace.SequenceEqual(new[]{"BOOTSTRAP_VALIDATION"}),
                  "رفض المرشح المزوّر قبل الالتزام "+label);
        }
        MustReject(candidate with {Rank=0},"رتبة صفرية");
        MustReject(candidate with {Rank=candidate.Rank==31?1:candidate.Rank+1},
                   "تغيير الرتبة");
        MustReject(candidate with {FamilySize=30},"تغيير حجم الأسرة");
        MustReject(candidate with {Step=step with {Value=0}},"محو الخطوة المصححة");
        MustReject(candidate with {Step=step with {Historical=oneBased with {
            K=BigInteger.One}}},"تحوير موضع الخطوة");
        MustReject(candidate with {Step=step with {Historical=oneBased with {
            Question=question with {Answer=question.Answer with {
                DirectionStep=-question.Answer.DirectionStep}}}}},"تحوير اتجاه التيار");
    }
}
