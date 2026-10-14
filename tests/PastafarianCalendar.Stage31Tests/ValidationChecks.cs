using System.Numerics;
using PastafarianCalendar.Monster;
using PastafarianCalendar.Stage01Tests.Normative;

namespace PastafarianCalendar.Stage31Tests;

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
              "الملكية مستقلة بين سياقين كاملين");
        var bowls=(BigInteger[])b.PatchedSauceFinalBowls!.Clone();
        var order=(int[])b.PatchedOrderAt46Latch!.Clone();
        a.PatchedSauceFinalBowls![1]=0;
        a.PatchedOrderAt46Latch![0]=-1;
        Check(b.PatchedSauceFinalBowls!.SequenceEqual(bowls) &&
              b.PatchedOrderAt46Latch!.SequenceEqual(order) &&
              b.PatchedShortFamilyRankResult.HasValue &&
              b.LegacyShortFamilyRankResult.HasValue,
              "المخزن المعدّل لا يلوّث سياقاً مستقلاً");

        var dispatcher=new MonsterDispatcher(
            new MonsterValidationManager(),new MonsterMetricsManager());
        var trace=b.BranchTrace.ToArray();
        var previous=b.LegacyShortFamilyRankResult;
        var fixedRank=b.PatchedShortFamilyRankResult;
        var rejected=false;
        try{dispatcher.DispatchPatchedShortRank(b);}
        catch(MonsterValidationException){rejected=true;}
        Check(rejected && b.BranchTrace.SequenceEqual(trace) &&
              b.LegacyShortFamilyRankResult==previous &&
              b.PatchedShortFamilyRankResult==fixedRank &&
              b.Metrics["patched.short.family.rank.dispatch"]==1,
              "التكرار مرفوض قبل أي تعديل");

        var f=NormativeScroll.FoundationDay;
        var raw=new MonsterContext(f,f){
            LegacyQueriedBowlId=1,LegacyBowlQuestionSeal=21,
            LegacyAnswerStepIndex=BigInteger.Zero,LegacyShortFamilySize=2};
        rejected=false;
        try{dispatcher.DispatchPatchedShortRank(raw);}
        catch(MonsterValidationException){rejected=true;}
        Check(rejected && raw.Status=="NEW" && raw.BranchTrace.Count==0 &&
              raw.PatchedShortFamilyRankResult is null,
              "لا يُقبل سؤال دون تأسيس");

        foreach(var bad in new[]{BigInteger.MinusOne,BigInteger.Zero,NormativeScroll.M+1})
        {
            rejected=false;
            try{new MonsterManager().ExecutePatchedShortRank(f,f,1,21,bad);}
            catch(MonsterValidationException){rejected=true;}
            Check(rejected,"حجم الأسرة غير القانوني");
        }
        foreach(var bad in new[]{-1,0,7})
        {
            rejected=false;
            try{new MonsterManager().ExecutePatchedShortRank(f,f,bad,21,2);}
            catch(MonsterValidationException){rejected=true;}
            Check(rejected,"هوية الوعاء غير القانونية "+bad);
        }
        foreach(var bad in new[]{0,20,22,30,32})
        {
            rejected=false;
            try{new MonsterManager().ExecutePatchedShortRank(f,f,1,bad,2);}
            catch(MonsterValidationException){rejected=true;}
            Check(rejected,"حاتم السؤال غير القانوني "+bad);
        }

        var wrapper=new ShortRankOffsetPatchWrapper();
        foreach(var tuple in new (BigInteger R,BigInteger N)[]{
            (0,2),(-1,2),(3,2),(1,0),(1,-1),(1,NormativeScroll.M+1)})
        {
            rejected=false;
            try{wrapper.Patch(tuple.R,tuple.N);}
            catch(MonsterValidationException){rejected=true;}
            Check(rejected,"الغلاف يرفض رتبة وحجم أسرة غير مقبولين");
        }
        Check(wrapper.Patch(1,1)==1 &&
              wrapper.Patch(1,NormativeScroll.M)==NormativeScroll.M &&
              wrapper.Patch(NormativeScroll.M,NormativeScroll.M)==
                  NormativeScroll.M-1,
              "حالات القيم 1 وM وحدود تدوير الرتبة");

        var ready=new MonsterManager().Prepare(f,f);
        ready.LegacyQueriedBowlId=3;
        ready.LegacyBowlQuestionSeal=31;
        ready.LegacyAnswerStepIndex=BigInteger.Zero;
        ready.LegacyShortFamilySize=31;
        var candidate=new PatchedShortRankPhaseHandler().Handle(ready);
        var prior=candidate.Historical;
        var step=prior.Step;
        var oldStep=step.Historical;
        var question=oldStep.Question;
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
        validator.ValidateLegacyOneBasedAnswerStep(ready,oldStep);
        validator.ValidatePatchedAnswerStep(ready,step);
        validator.ValidateLegacyUnshiftedShortRank(ready,prior);
        validator.ValidatePatchedShortRank(ready,candidate);
        Check(ready.Status=="BOOTSTRAP_READY" &&
              ready.LegacyShortFamilyRankResult is null &&
              ready.PatchedShortFamilyRankResult is null &&
              ready.PatchedSauceFinalBowls is null &&
              ready.BranchTrace.SequenceEqual(new[]{"BOOTSTRAP_VALIDATION"}),
              "كل المرشحات مفحوصة دون التزام جانبي");

        void MustReject(PatchedShortRankCandidate altered,string label)
        {
            var denied=false;
            try{validator.ValidatePatchedShortRank(ready,altered);}
            catch(MonsterValidationException){denied=true;}
            Check(denied && ready.Status=="BOOTSTRAP_READY" &&
                  ready.LegacyShortFamilyRankResult is null &&
                  ready.PatchedShortFamilyRankResult is null &&
                  ready.PatchedSauceFinalBowls is null &&
                  ready.BranchTrace.SequenceEqual(new[]{"BOOTSTRAP_VALIDATION"}),
                  "رفض تعديل مرشح قبل الالتزام "+label);
        }
        MustReject(candidate with {Rank=0},"الرتبة الصفرية");
        MustReject(candidate with {Rank=candidate.Rank==31?1:candidate.Rank+1},
                   "التلاعب بالمرتبة المصححة");
        MustReject(candidate with {Historical=prior with {FamilySize=30}},
                   "تغيير حجم الأسرة");
        MustReject(candidate with {Historical=prior with {
            Rank=prior.Rank==31?1:prior.Rank+1}},"محو الشاهد التاريخي");
        MustReject(candidate with {Historical=prior with {
            Step=step with {Value=0}}},"تزييف أول جواب");
        MustReject(candidate with {Historical=prior with {
            Step=step with {Historical=oldStep with {K=BigInteger.One}}}},
            "تغيير موضع k الصحيح");
        MustReject(candidate with {Historical=prior with {
            Step=step with {Historical=oldStep with {
                Question=question with {Answer=question.Answer with {
                    DirectionStep=-question.Answer.DirectionStep}}}}}},
            "تزييف اتجاه السؤال المختوم");
    }
}
