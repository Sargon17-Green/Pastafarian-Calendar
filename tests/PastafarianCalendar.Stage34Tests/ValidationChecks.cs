using System.Numerics;
using PastafarianCalendar.Monster;
using PastafarianCalendar.Stage01Tests.Normative;

namespace PastafarianCalendar.Stage34Tests;

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
              "المصدر والوثائق مستقلة بين سياقين");
        var prior=(BigInteger[])b.PatchedSauceFinalBowls!.Clone();
        a.PatchedSauceFinalBowls![1]=0;
        Check(b.PatchedSauceFinalBowls!.SequenceEqual(prior) &&
              b.LegacyInclusiveWideLimitRankResult.HasValue &&
              b.PatchedWideRankResult.HasValue,
              "لا تسرّب عند تعديل سياق آخر");
        var before=b.BranchTrace.ToArray();var old=b.LegacyInclusiveWideLimitRankResult;
        var dispatch=new MonsterDispatcher(new MonsterValidationManager(),
                                            new MonsterMetricsManager());
        var rejected=false;
        try{dispatch.DispatchLegacyInclusiveWideLimit(b);}
        catch(MonsterValidationException){rejected=true;}
        Check(rejected && b.BranchTrace.SequenceEqual(before) &&
              b.LegacyInclusiveWideLimitRankResult==old,
              "رفض التزام مكرر دون كتابة");

        var f=NormativeScroll.FoundationDay;
        var m=NormativeScroll.M;
        var raw=new MonsterContext(f,f){
            LegacyQueriedBowlId=1,LegacyBowlQuestionSeal=21,
            LegacyAnswerStepIndex=0,LegacyWideFamilySize=m+1};
        rejected=false;
        try{dispatch.DispatchLegacyInclusiveWideLimit(raw);}
        catch(MonsterValidationException){rejected=true;}
        Check(rejected && raw.Status=="NEW" && raw.BranchTrace.Count==0 &&
              raw.LegacyInclusiveWideLimitRankResult is null,
              "رفض الحالة غير المؤسسة");

        foreach(var bad in new BigInteger[]{-1,0,1,m})
        {
            rejected=false;
            try{new MonsterManager().ExecuteLegacyInclusiveWideLimit(f,f,1,21,bad);}
            catch(MonsterValidationException){rejected=true;}
            Check(rejected,"رفض حجم عائلة قصير");
        }
        foreach(var id in new[]{-1,0,7})
        {
            rejected=false;
            try{new MonsterManager().ExecuteLegacyInclusiveWideLimit(f,f,id,21,m+1);}
            catch(MonsterValidationException){rejected=true;}
            Check(rejected,"رفض وعاء غير قانوني");
        }
        foreach(var seal in new[]{0,20,22,30,32})
        {
            rejected=false;
            try{new MonsterManager().ExecuteLegacyInclusiveWideLimit(f,f,1,seal,m+1);}
            catch(MonsterValidationException){rejected=true;}
            Check(rejected,"رفض حاتم غير قانوني");
        }
        var chooser=new LegacyInclusiveWideLimit();
        foreach(var stream in new[]{
            new LegacyBowlQuestionResult(0,1),
            new LegacyBowlQuestionResult(m+1,1),
            new LegacyBowlQuestionResult(1,0),
            new LegacyBowlQuestionResult(1,2)})
        {
            rejected=false;
            try{chooser.Choose(stream,m+1);}
            catch(MonsterValidationException){rejected=true;}
            Check(rejected,"رفض تيار غير قانوني");
        }

        var ready=new MonsterManager().Prepare(f,f);
        ready.LegacyQueriedBowlId=3;
        ready.LegacyBowlQuestionSeal=31;
        ready.LegacyAnswerStepIndex=BigInteger.Zero;
        ready.LegacyWideFamilySize=m*m-1;
        var candidate=new LegacyInclusiveWideLimitPhaseHandler().Handle(ready);
        var wide=candidate.Previous;
        var oldWide=wide.Historical;
        var step=oldWide.Step;
        var oneBased=step.Historical;
        var sealedQuestion=oneBased.Question;
        var oldQuestion=sealedQuestion.Historical;
        var next=oldQuestion.Historical;
        var oldNext=next.Historical;
        var v=new MonsterValidationManager();
        v.ValidateVisibleDropPatch(ready,oldNext.Sauce.Historical.Source);
        v.ValidateLegacyOverwrittenSauce(ready,oldNext.Sauce.Historical);
        v.ValidateProtectedDrop46Sauce(ready,oldNext.Sauce);
        v.ValidateLegacyFixedNextBowl(ready,oldNext);
        v.ValidatePatchedNextBowl(ready,next);
        v.ValidateLegacyUnsealedBowlQuestion(ready,oldQuestion);
        v.ValidatePatchedBowlQuestion(ready,sealedQuestion);
        v.ValidateLegacyOneBasedAnswerStep(ready,oneBased);
        v.ValidatePatchedAnswerStep(ready,step);
        v.ValidateLegacyReversedWideRank(ready,oldWide);
        v.ValidatePatchedWideRank(ready,wide);
        v.ValidateLegacyInclusiveWideLimit(ready,candidate);
        Check(ready.Status=="BOOTSTRAP_READY" &&
              ready.LegacyInclusiveWideLimitRankResult is null &&
              ready.PatchedWideRankResult is null &&
              ready.PatchedSauceFinalBowls is null &&
              ready.BranchTrace.SequenceEqual(new[]{"BOOTSTRAP_VALIDATION"}),
              "كل تدقيق يسبق تثبيت الحالة");

        void Reject(LegacyInclusiveWideLimitCandidate altered,string label)
        {
            var denied=false;
            try{v.ValidateLegacyInclusiveWideLimit(ready,altered);}
            catch(MonsterValidationException){denied=true;}
            Check(denied && ready.Status=="BOOTSTRAP_READY" &&
                  ready.LegacyInclusiveWideLimitRankResult is null &&
                  ready.PatchedWideRankResult is null &&
                  ready.PatchedSauceFinalBowls is null &&
                  ready.BranchTrace.SequenceEqual(new[]{"BOOTSTRAP_VALIDATION"}),
                  "رفض تزوير المرشح قبل الالتزام "+label);
        }
        Reject(candidate with {Rank=0},"رتبة صفرية");
        Reject(candidate with {Rank=candidate.Rank+1},"تغيّر الرتبة");
        Reject(candidate with {Previous=wide with {Rank=wide.Rank+1}},
              "تحريف الترتيب المصحح");
        Reject(candidate with {Previous=wide with {Historical=oldWide with {
            Rank=oldWide.Rank+1}}},"تغيير شاهد الترتيب المعكوس");
        Reject(candidate with {Previous=wide with {Historical=oldWide with {
            Step=step with {Value=0}}}},"طمس الجواب المصحح");
        Reject(candidate with {Previous=wide with {Historical=oldWide with {
            Step=step with {Historical=oneBased with {K=1}}}}},
            "تزييف موضع جواب التيار");
    }
}
