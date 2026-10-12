using System.Numerics;
using PastafarianCalendar.Monster;
using PastafarianCalendar.Stage01Tests.Normative;

namespace PastafarianCalendar.Stage27Tests;

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
              !ReferenceEquals(a.Metrics,b.Metrics) &&
              a.LegacyUnsealedBowlQuestionResult is not null &&
              b.LegacyUnsealedBowlQuestionResult is not null,
              "ملكية كاملة لكل حالة صلصة وسؤال مستقل");

        var bBowls=(BigInteger[])b.PatchedSauceFinalBowls!.Clone();
        var bOrder=(int[])b.PatchedOrderAt46Latch!.Clone();
        a.PatchedSauceFinalBowls![1]=0;
        a.PatchedOrderAt46Latch![0]=-99;
        Check(b.PatchedSauceFinalBowls!.SequenceEqual(bBowls) &&
              b.PatchedOrderAt46Latch!.SequenceEqual(bOrder) &&
              b.PatchedBowlQuestionResult is not null,
              "فساد سؤال لا يلوث مخزن سؤال آخر");

        var dispatcher=new MonsterDispatcher(
            new MonsterValidationManager(),new MonsterMetricsManager());
        var before=b.BranchTrace.ToArray();
        var fixedAnswer=b.PatchedBowlQuestionResult;
        var legacyAnswer=b.LegacyUnsealedBowlQuestionResult;
        var rejected=false;
        try{dispatcher.DispatchPatchedBowlQuestion(b);}
        catch(MonsterValidationException){rejected=true;}
        Check(rejected && b.BranchTrace.SequenceEqual(before) &&
              b.PatchedBowlQuestionResult==fixedAnswer &&
              b.LegacyUnsealedBowlQuestionResult==legacyAnswer &&
              b.Metrics["patched.sealed.bowl.question.dispatch"]==1,
              "منع التنفيذ الثاني قبل تغيير سجل أو نتيجة");

        var f=NormativeScroll.FoundationDay;
        var raw=new MonsterContext(f,f){
            LegacyQueriedBowlId=1,LegacyBowlQuestionSeal=21};
        rejected=false;
        try{dispatcher.DispatchPatchedBowlQuestion(raw);}
        catch(MonsterValidationException){rejected=true;}
        Check(rejected && raw.Status=="NEW" &&
              raw.BranchTrace.Count==0 && raw.PatchedBowlQuestionResult is null,
              "السياق بلا تأسيس يُرفض دون أثر");

        foreach(var badId in new[]{-1,0,7})
        {
            rejected=false;
            try{new MonsterManager().ExecutePatchedBowlQuestion(f,f,badId,21);}
            catch(MonsterValidationException){rejected=true;}
            Check(rejected,"رفض هوية وعاء خاطئة "+badId);
        }
        foreach(var badSeal in new[]{-1,0,20,22,30,32})
        {
            rejected=false;
            try{new MonsterManager().ExecutePatchedBowlQuestion(f,f,1,badSeal);}
            catch(MonsterValidationException){rejected=true;}
            Check(rejected,"رفض حاتم سؤال غير معتمد "+badSeal);
        }

        var wrapper=new BowlQuestionSealPatchWrapper();
        var bowls=new[]{BigInteger.Zero,BigInteger.One,new BigInteger(2),
                        new BigInteger(3),new BigInteger(4),
                        new BigInteger(5),new BigInteger(6)};
        foreach(var bad in new[]{-1,0,7})
        {
            rejected=false;
            try{wrapper.Patch(bowls,bad,2,21);}
            catch(MonsterValidationException){rejected=true;}
            Check(rejected,"رفض رقم غير صالح في الغلاف "+bad);
        }
        rejected=false;
        try{wrapper.Patch(bowls,2,2,21);}
        catch(MonsterValidationException){rejected=true;}
        Check(rejected,"الجار لا يساوي الوعاء نفسه");
        rejected=false;
        try{wrapper.Patch(new BigInteger[5],1,2,21);}
        catch(MonsterValidationException){rejected=true;}
        Check(rejected,"رفض مصفوفة أوعية ناقصة");
        rejected=false;
        try{wrapper.Patch(bowls,1,2,-1);}
        catch(MonsterValidationException){rejected=true;}
        Check(rejected,"رفض حاتم سالب في الغلاف");

        var ready=new MonsterManager().Prepare(f,f);
        ready.LegacyQueriedBowlId=3;
        ready.LegacyBowlQuestionSeal=31;
        var candidate=new PatchedBowlQuestionPhaseHandler().Handle(ready);
        var historical=candidate.Historical;
        var patched=historical.Historical;
        var oldNext=patched.Historical;
        var validation=new MonsterValidationManager();
        validation.ValidateVisibleDropPatch(ready,oldNext.Sauce.Historical.Source);
        validation.ValidateLegacyOverwrittenSauce(ready,oldNext.Sauce.Historical);
        validation.ValidateProtectedDrop46Sauce(ready,oldNext.Sauce);
        validation.ValidateLegacyFixedNextBowl(ready,oldNext);
        validation.ValidatePatchedNextBowl(ready,patched);
        validation.ValidateLegacyUnsealedBowlQuestion(ready,historical);
        validation.ValidatePatchedBowlQuestion(ready,candidate);
        Check(ready.Status=="BOOTSTRAP_READY" &&
              ready.PatchedBowlQuestionResult is null &&
              ready.LegacyUnsealedBowlQuestionResult is null &&
              ready.PatchedSauceFinalBowls is null &&
              ready.BranchTrace.SequenceEqual(new[]{"BOOTSTRAP_VALIDATION"}),
              "التحقق وحده لا يكتب حالة دلالية");

        void MustReject(PatchedBowlQuestionCandidate bad,string label)
        {
            var failed=false;
            try{validation.ValidatePatchedBowlQuestion(ready,bad);}
            catch(MonsterValidationException){failed=true;}
            Check(failed && ready.Status=="BOOTSTRAP_READY" &&
                  ready.PatchedBowlQuestionResult is null &&
                  ready.LegacyUnsealedBowlQuestionResult is null &&
                  ready.PatchedSauceFinalBowls is null &&
                  ready.BranchTrace.SequenceEqual(new[]{"BOOTSTRAP_VALIDATION"}),
                  "رفض المرشح قبل الالتزام "+label);
        }

        MustReject(candidate with {Answer=candidate.Answer with {First=0}},
                   "إجابة صفر");
        MustReject(candidate with {Answer=candidate.Answer with {
            First=candidate.Answer.First==NormativeScroll.M?1:
                  candidate.Answer.First+1}},"تبديل الجواب");
        MustReject(candidate with {Answer=candidate.Answer with {DirectionStep=0}},
                   "اتجاه صفر");
        MustReject(candidate with {Answer=candidate.Answer with {
            DirectionStep=-candidate.Answer.DirectionStep}},
                   "اتجاه معاكس");
        MustReject(candidate with {Historical=historical with {Seal=21}},
                   "تغيير الحاتم");
        MustReject(candidate with {Historical=historical with {
            Answer=historical.Answer with {First=0}}},
                   "محو النتيجة التاريخية");
        MustReject(candidate with {Historical=historical with {
            Historical=patched with {NextBowlId=patched.NextBowlId%6+1}}},
                   "تبديل الجار المصحح");
    }
}
