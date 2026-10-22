using System.Numerics;
using PastafarianCalendar.Monster;
using PastafarianCalendar.Stage01Tests.Normative;

namespace PastafarianCalendar.Stage40Tests;

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
              "ملكية كل سياق منفصلة عن السؤال الآخر");
        var saved=(BigInteger[])b.PatchedSauceFinalBowls!.Clone();
        a.PatchedSauceFinalBowls![1]=0;
        Check(b.PatchedSauceFinalBowls!.SequenceEqual(saved) &&
              b.LegacyUpperPlaceBiasRankResult.HasValue &&
              b.PatchedDoubleOffsetWideRankResult.HasValue,
              "التعديل المحلي لا يلوّث سياقاً آخر");

        var dispatch=new MonsterDispatcher(new MonsterValidationManager(),
                                           new MonsterMetricsManager());
        var trace=b.BranchTrace.ToArray();
        var original=b.LegacyUpperPlaceBiasRankResult;
        var rejected=false;
        try{dispatch.DispatchLegacyUpperPlaceBias(b);}
        catch(MonsterValidationException){rejected=true;}
        Check(rejected && b.BranchTrace.SequenceEqual(trace) &&
              b.LegacyUpperPlaceBiasRankResult==original &&
              b.Metrics["legacy.upper.place.bias.dispatch"]==1,
              "رفض تكرار الالتزام دون تغيير");
        var f=NormativeScroll.FoundationDay;
        var m=NormativeScroll.M;
        var raw=new MonsterContext(f,f){
            LegacyQueriedBowlId=1,LegacyBowlQuestionSeal=21,
            LegacyWideFamilySize=m+1,LegacyAnswerStepIndex=0};
        rejected=false;
        try{dispatch.DispatchLegacyUpperPlaceBias(raw);}
        catch(MonsterValidationException){rejected=true;}
        Check(rejected && raw.Status=="NEW" &&
              raw.LegacyUpperPlaceBiasRankResult is null && raw.BranchTrace.Count==0,
              "رفض سياق غير مؤسس");

        foreach(var n in new BigInteger[]{-1,0,1,m})
        {
            rejected=false;
            try{new MonsterManager().ExecuteLegacyUpperPlaceBias(f,f,1,21,n);}
            catch(MonsterValidationException){rejected=true;}
            Check(rejected,"رفض أسرة ليست واسعة");
        }
        foreach(var id in new[]{-1,0,7})
        {
            rejected=false;
            try{new MonsterManager().ExecuteLegacyUpperPlaceBias(f,f,id,21,m+1);}
            catch(MonsterValidationException){rejected=true;}
            Check(rejected,"رفض وعاء غير قانوني");
        }
        foreach(var seal in new[]{0,20,22,30,32})
        {
            rejected=false;
            try{new MonsterManager().ExecuteLegacyUpperPlaceBias(f,f,1,seal,m+1);}
            catch(MonsterValidationException){rejected=true;}
            Check(rejected,"رفض حاتم غير قانوني");
        }

        var legacy=new LegacyUpperPlaceBias();
        foreach(var x in new (BigInteger R,BigInteger N)[]{
            (0,m+1),(-1,m+1),(m+2,m+1),(1,0),(1,m)})
        {
            rejected=false;
            try{legacy.Shift(x.R,x.N);}
            catch(MonsterValidationException){rejected=true;}
            Check(rejected,"رفض مرتبة ومقاس غير قانونيين");
        }

        var ready=new MonsterManager().Prepare(f,f);
        ready.LegacyQueriedBowlId=3;
        ready.LegacyBowlQuestionSeal=31;
        ready.LegacyAnswerStepIndex=BigInteger.Zero;
        ready.LegacyWideFamilySize=m+1;
        var candidate=new LegacyUpperPlaceBiasPhaseHandler().Handle(ready);
        var before=candidate.Previous;
        var output=before.Historical;
        var patched=output.Previous;
        var rejectedDirection=patched.Historical;
        var inclusive=rejectedDirection.Previous;
        var oldInclusive=inclusive.Historical;
        var wide=oldInclusive.Previous;
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
        v.ValidateLegacyInclusiveWideLimit(ready,oldInclusive);
        v.ValidatePatchedInclusiveWideLimit(ready,inclusive);
        v.ValidateLegacyWideRejectionDirection(ready,rejectedDirection);
        v.ValidatePatchedRejectionDirection(ready,patched);
        v.ValidateLegacyDoubleOffsetWideRank(ready,output);
        v.ValidatePatchedDoubleOffsetWideRank(ready,before);
        v.ValidateLegacyUpperPlaceBias(ready,candidate);
        Check(ready.Status=="BOOTSTRAP_READY" &&
              ready.LegacyUpperPlaceBiasRankResult is null &&
              ready.PatchedDoubleOffsetWideRankResult is null &&
              ready.PatchedSauceFinalBowls is null &&
              ready.BranchTrace.SequenceEqual(new[]{"BOOTSTRAP_VALIDATION"}),
              "كل المدققات تعمل قبل التزام الحالة الدلالية");

        void Reject(LegacyUpperPlaceBiasCandidate altered,string why)
        {
            var denied=false;
            try{v.ValidateLegacyUpperPlaceBias(ready,altered);}
            catch(MonsterValidationException){denied=true;}
            Check(denied && ready.Status=="BOOTSTRAP_READY" &&
                  ready.LegacyUpperPlaceBiasRankResult is null &&
                  ready.PatchedDoubleOffsetWideRankResult is null &&
                  ready.PatchedSauceFinalBowls is null &&
                  ready.BranchTrace.SequenceEqual(new[]{"BOOTSTRAP_VALIDATION"}),
                  "رفض التزوير قبل الالتزام "+why);
        }
        Reject(candidate with {Rank=0},"رتبة صفر");
        Reject(candidate with {Rank=candidate.Rank+1},"تعديل الرتبة القديمة");
        Reject(candidate with {Previous=before with {Rank=before.Rank+1}},
               "تغيير شاهد الرقعة التاسعة عشرة");
        Reject(candidate with {Previous=before with {
            Historical=output with {Rank=output.Rank+1}}},
            "تزييف الانحراف السابق");
        Reject(candidate with {Previous=before with {
            Historical=output with {Previous=patched with {
                Rank=patched.Rank+1}}}},
            "تحريف اتجاه الرفض المصحح");
    }
}
