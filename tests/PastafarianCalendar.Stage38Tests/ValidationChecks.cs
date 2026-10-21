using System.Numerics;
using PastafarianCalendar.Monster;
using PastafarianCalendar.Stage01Tests.Normative;

namespace PastafarianCalendar.Stage38Tests;

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
              "الملكية مستقلة بين سياقين");
        var saved=(BigInteger[])b.PatchedSauceFinalBowls!.Clone();
        var rank=b.LegacyDoubleOffsetWideRankResult;
        a.PatchedSauceFinalBowls![1]=0;
        Check(b.PatchedSauceFinalBowls!.SequenceEqual(saved) &&
              b.LegacyDoubleOffsetWideRankResult==rank,
              "البيانات القابلة للتعديل لا تتسرّب بين الاستدعاءات");

        var dispatch=new MonsterDispatcher(
            new MonsterValidationManager(),new MonsterMetricsManager());
        var trace=b.BranchTrace.ToArray();
        var denied=false;
        try{dispatch.DispatchLegacyDoubleOffsetWideRank(b);}
        catch(MonsterValidationException){denied=true;}
        Check(denied && b.BranchTrace.SequenceEqual(trace) &&
              b.LegacyDoubleOffsetWideRankResult==rank &&
              b.Metrics["legacy.double.offset.wide.rank.dispatch"]==1,
              "رفض التزام متكرر دون آثار إضافية");

        var foundation=NormativeScroll.FoundationDay;
        var m=NormativeScroll.M;
        var raw=new MonsterContext(foundation,foundation){
            LegacyQueriedBowlId=1,LegacyBowlQuestionSeal=21,
            LegacyAnswerStepIndex=BigInteger.Zero,LegacyWideFamilySize=m+1};
        denied=false;
        try{dispatch.DispatchLegacyDoubleOffsetWideRank(raw);}
        catch(MonsterValidationException){denied=true;}
        Check(denied && raw.Status=="NEW" && raw.BranchTrace.Count==0 &&
              raw.LegacyDoubleOffsetWideRankResult is null,
              "رفض السياق قبل التأسيس");

        foreach(var n in new BigInteger[]{-1,0,1,m})
        {
            denied=false;
            try{new MonsterManager().ExecuteLegacyDoubleOffsetWideRank(
                foundation,foundation,1,21,n);}
            catch(MonsterValidationException){denied=true;}
            Check(denied,"رفض أسرة غير واسعة");
        }
        foreach(var id in new[]{-1,0,7})
        {
            denied=false;
            try{new MonsterManager().ExecuteLegacyDoubleOffsetWideRank(
                foundation,foundation,id,21,m+1);}
            catch(MonsterValidationException){denied=true;}
            Check(denied,"رفض رقم وعاء غير قانوني");
        }
        foreach(var seal in new[]{0,20,22,30,32})
        {
            denied=false;
            try{new MonsterManager().ExecuteLegacyDoubleOffsetWideRank(
                foundation,foundation,1,seal,m+1);}
            catch(MonsterValidationException){denied=true;}
            Check(denied,"رفض حاتم غير قانوني");
        }

        var ready=new MonsterManager().Prepare(foundation,foundation);
        ready.LegacyQueriedBowlId=3;
        ready.LegacyBowlQuestionSeal=31;
        ready.LegacyAnswerStepIndex=BigInteger.Zero;
        ready.LegacyWideFamilySize=m*m-1;
        var candidate=new LegacyDoubleOffsetWideRankPhaseHandler().Handle(ready);
        var corrected=candidate.Previous;
        var rejected=corrected.Historical;
        var repaired=rejected.Previous;
        var oldLimit=repaired.Historical;
        var wide=oldLimit.Previous;
        var oldWide=wide.Historical;
        var step=oldWide.Step;
        var oneBased=step.Historical;
        var question=oneBased.Question;
        var oldQuestion=question.Historical;
        var next=oldQuestion.Historical;
        var oldNext=next.Historical;
        var v=new MonsterValidationManager();
        v.ValidateVisibleDropPatch(ready,oldNext.Sauce.Historical.Source);
        v.ValidateLegacyOverwrittenSauce(ready,oldNext.Sauce.Historical);
        v.ValidateProtectedDrop46Sauce(ready,oldNext.Sauce);
        v.ValidateLegacyFixedNextBowl(ready,oldNext);
        v.ValidatePatchedNextBowl(ready,next);
        v.ValidateLegacyUnsealedBowlQuestion(ready,oldQuestion);
        v.ValidatePatchedBowlQuestion(ready,question);
        v.ValidateLegacyOneBasedAnswerStep(ready,oneBased);
        v.ValidatePatchedAnswerStep(ready,step);
        v.ValidateLegacyReversedWideRank(ready,oldWide);
        v.ValidatePatchedWideRank(ready,wide);
        v.ValidateLegacyInclusiveWideLimit(ready,oldLimit);
        v.ValidatePatchedInclusiveWideLimit(ready,repaired);
        v.ValidateLegacyWideRejectionDirection(ready,rejected);
        v.ValidatePatchedRejectionDirection(ready,corrected);
        v.ValidateLegacyDoubleOffsetWideRank(ready,candidate);
        Check(ready.Status=="BOOTSTRAP_READY" &&
              ready.LegacyDoubleOffsetWideRankResult is null &&
              ready.PatchedRejectionDirectionRankResult is null &&
              ready.PatchedSauceFinalBowls is null &&
              ready.BranchTrace.SequenceEqual(new[]{"BOOTSTRAP_VALIDATION"}),
              "التحقق لا يكتب حالة قبل الالتزام");

        void Reject(LegacyDoubleOffsetWideRankCandidate changed,string label)
        {
            var failure=false;
            try{v.ValidateLegacyDoubleOffsetWideRank(ready,changed);}
            catch(MonsterValidationException){failure=true;}
            Check(failure && ready.Status=="BOOTSTRAP_READY" &&
                  ready.LegacyDoubleOffsetWideRankResult is null &&
                  ready.PatchedRejectionDirectionRankResult is null &&
                  ready.PatchedSauceFinalBowls is null &&
                  ready.BranchTrace.SequenceEqual(new[]{"BOOTSTRAP_VALIDATION"}),
                  "رفض المرشح المزيّف دون كتابة "+label);
        }
        Reject(candidate with {Rank=0},"الرتبة الصفرية");
        Reject(candidate with {Rank=candidate.Rank==m*m-1?1:candidate.Rank+1},
               "تحريف إزاحة الخرج");
        Reject(candidate with {Previous=corrected with {Rank=0}},
               "تحريف رتبة التصحيح الثامن عشر");
        Reject(candidate with {Previous=corrected with {
            Historical=rejected with {Rank=rejected.Rank+1}}},
            "طمس شاهد اتجاه الرفض");
        Reject(candidate with {Previous=corrected with {
            Historical=rejected with {Previous=repaired with {
                Rank=repaired.Rank+1}}}},
            "تغيير رقعة الحد السابقة");
        Reject(candidate with {Previous=corrected with {
            Historical=rejected with {Previous=repaired with {
                Historical=oldLimit with {Rank=oldLimit.Rank+1}}}}},
            "تغيير شاهد القبول القديم");
        Reject(candidate with {Previous=corrected with {
            Historical=rejected with {Previous=repaired with {
                Historical=oldLimit with {Previous=wide with {
                    Historical=oldWide with {Step=step with {Value=0}}}}}}}},
            "تحريف الجواب الأول");
    }
}
