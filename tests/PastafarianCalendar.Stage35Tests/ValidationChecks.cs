using System.Numerics;
using PastafarianCalendar.Monster;
using PastafarianCalendar.Stage01Tests.Normative;

namespace PastafarianCalendar.Stage35Tests;

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
              "كل سياق يملك سجلاته ومصفوفاته");
        var bowls=(BigInteger[])b.PatchedSauceFinalBowls!.Clone();
        var rank=b.PatchedInclusiveWideLimitRankResult;
        a.PatchedSauceFinalBowls![1]=0;
        Check(b.PatchedSauceFinalBowls!.SequenceEqual(bowls) &&
              b.PatchedInclusiveWideLimitRankResult==rank,
              "التعديل المحلي لا يتسرّب إلى عملية أخرى");

        var dispatch=new MonsterDispatcher(
            new MonsterValidationManager(),new MonsterMetricsManager());
        var trace=b.BranchTrace.ToArray();var old=b.LegacyInclusiveWideLimitRankResult;
        var denied=false;
        try{dispatch.DispatchPatchedInclusiveWideLimit(b);}
        catch(MonsterValidationException){denied=true;}
        Check(denied && b.BranchTrace.SequenceEqual(trace) &&
              b.LegacyInclusiveWideLimitRankResult==old &&
              b.PatchedInclusiveWideLimitRankResult==rank &&
              b.Metrics["patched.inclusive.wide.limit.dispatch"]==1,
              "منع إعادة الالتزام دون كتابة");

        var foundation=NormativeScroll.FoundationDay;
        var m=NormativeScroll.M;
        var raw=new MonsterContext(foundation,foundation){
            LegacyQueriedBowlId=1,LegacyBowlQuestionSeal=21,
            LegacyAnswerStepIndex=0,LegacyWideFamilySize=m+1};
        denied=false;
        try{dispatch.DispatchPatchedInclusiveWideLimit(raw);}
        catch(MonsterValidationException){denied=true;}
        Check(denied && raw.Status=="NEW" && raw.BranchTrace.Count==0 &&
              raw.PatchedInclusiveWideLimitRankResult is null,
              "لا يُقبل سياق غير مؤسس");

        foreach(var size in new BigInteger[]{-1,0,1,m})
        {
            denied=false;
            try{new MonsterManager().ExecutePatchedInclusiveWideLimit(
                foundation,foundation,1,21,size);}
            catch(MonsterValidationException){denied=true;}
            Check(denied,"رفض حجم أسرة ليس واسعاً");
        }
        foreach(var id in new[]{-1,0,7})
        {
            denied=false;
            try{new MonsterManager().ExecutePatchedInclusiveWideLimit(
                foundation,foundation,id,21,m+1);}
            catch(MonsterValidationException){denied=true;}
            Check(denied,"رفض رقم وعاء غير صالح");
        }
        foreach(var seal in new[]{0,20,22,30,32})
        {
            denied=false;
            try{new MonsterManager().ExecutePatchedInclusiveWideLimit(
                foundation,foundation,1,seal,m+1);}
            catch(MonsterValidationException){denied=true;}
            Check(denied,"رفض حاتم غير صالح");
        }

        var patch=new InclusiveWideLimitPatchWrapper();
        foreach(var args in new (BigInteger X,BigInteger N,BigInteger Space)[]{
            (0,m+1,m*m),(m*m+1,m+1,m*m),(1,m,m*m),
            (1,m*m+1,m*m),(1,m+1,m-1)})
        {
            denied=false;
            try{patch.Accepts(args.X,args.N,args.Space);}
            catch(MonsterValidationException){denied=true;}
            Check(denied,"رفض حد قبول مُدخل خارج المدى");
        }

        var ready=new MonsterManager().Prepare(foundation,foundation);
        ready.LegacyQueriedBowlId=3;
        ready.LegacyBowlQuestionSeal=31;
        ready.LegacyAnswerStepIndex=BigInteger.Zero;
        ready.LegacyWideFamilySize=m*m-1;
        var candidate=new PatchedInclusiveWideLimitPhaseHandler().Handle(ready);
        var legacy=candidate.Historical;
        var wide=legacy.Previous;
        var oldWide=wide.Historical;
        var step=oldWide.Step;
        var oneBased=step.Historical;
        var sealedQuestion=oneBased.Question;
        var oldQuestion=sealedQuestion.Historical;
        var next=oldQuestion.Historical;
        var oldNext=next.Historical;
        var val=new MonsterValidationManager();
        val.ValidateVisibleDropPatch(ready,oldNext.Sauce.Historical.Source);
        val.ValidateLegacyOverwrittenSauce(ready,oldNext.Sauce.Historical);
        val.ValidateProtectedDrop46Sauce(ready,oldNext.Sauce);
        val.ValidateLegacyFixedNextBowl(ready,oldNext);
        val.ValidatePatchedNextBowl(ready,next);
        val.ValidateLegacyUnsealedBowlQuestion(ready,oldQuestion);
        val.ValidatePatchedBowlQuestion(ready,sealedQuestion);
        val.ValidateLegacyOneBasedAnswerStep(ready,oneBased);
        val.ValidatePatchedAnswerStep(ready,step);
        val.ValidateLegacyReversedWideRank(ready,oldWide);
        val.ValidatePatchedWideRank(ready,wide);
        val.ValidateLegacyInclusiveWideLimit(ready,legacy);
        val.ValidatePatchedInclusiveWideLimit(ready,candidate);
        Check(ready.Status=="BOOTSTRAP_READY" &&
              ready.LegacyInclusiveWideLimitRankResult is null &&
              ready.PatchedInclusiveWideLimitRankResult is null &&
              ready.PatchedSauceFinalBowls is null &&
              ready.BranchTrace.SequenceEqual(new[]{"BOOTSTRAP_VALIDATION"}),
              "جميع المدققات تعمل قبل الالتزام");

        void Reject(PatchedInclusiveWideLimitCandidate altered,string label)
        {
            var thrown=false;
            try{val.ValidatePatchedInclusiveWideLimit(ready,altered);}
            catch(MonsterValidationException){thrown=true;}
            Check(thrown && ready.Status=="BOOTSTRAP_READY" &&
                  ready.LegacyInclusiveWideLimitRankResult is null &&
                  ready.PatchedInclusiveWideLimitRankResult is null &&
                  ready.PatchedSauceFinalBowls is null &&
                  ready.BranchTrace.SequenceEqual(new[]{"BOOTSTRAP_VALIDATION"}),
                  "رفض مرشح مزيّف قبل الكتابة "+label);
        }
        Reject(candidate with {Rank=0},"رتبة صفرية");
        Reject(candidate with {Rank=candidate.Rank+1},"تغيير رتبة الرقعة");
        Reject(candidate with {Historical=legacy with {Rank=legacy.Rank+1}},
               "تغيير الشاهد القديم");
        Reject(candidate with {Historical=legacy with {
            Previous=wide with {Rank=wide.Rank+1}}},
            "تغيير شاهد الرقعة السابقة");
        Reject(candidate with {Historical=legacy with {
            Previous=wide with {Historical=oldWide with {Rank=oldWide.Rank+1}}}},
            "تزييف شاهد وزن الخانات");
        Reject(candidate with {Historical=legacy with {
            Previous=wide with {Historical=oldWide with {
                Step=step with {Value=0}}}}},"تغيير خطوة الجواب المصحح");
        Reject(candidate with {Historical=legacy with {
            Previous=wide with {Historical=oldWide with {
                Step=step with {Historical=oneBased with {K=1}}}}}},
            "تحريف فهرس السؤال الصفري");
    }
}
