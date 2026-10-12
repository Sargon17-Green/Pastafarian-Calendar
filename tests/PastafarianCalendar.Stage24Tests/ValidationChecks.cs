using System.Numerics;
using PastafarianCalendar.Monster;
using PastafarianCalendar.Stage01Tests.Normative;

namespace PastafarianCalendar.Stage24Tests;

internal static partial class Program
{
    private static void CheckOwnershipAndRejection()
    {
        var first = Contexts[0];
        var second = Contexts[1];
        Check(!ReferenceEquals(first, second) &&
              !ReferenceEquals(first.PatchedOrderAt46Latch, second.PatchedOrderAt46Latch) &&
              !ReferenceEquals(first.PatchedSauceFinalBowls, second.PatchedSauceFinalBowls) &&
              !ReferenceEquals(first.LegacySauceFinalBowls, second.LegacySauceFinalBowls) &&
              !ReferenceEquals(first.BranchTrace, second.BranchTrace) &&
              !ReferenceEquals(first.Metrics, second.Metrics),
              "ملكية السجلات والأوعية لكل سؤال مستقلة");
        var snapshot = (int[])second.PatchedOrderAt46Latch!.Clone();
        first.PatchedOrderAt46Latch![0] = -17;
        Check(second.PatchedOrderAt46Latch!.SequenceEqual(snapshot) &&
              second.LegacyFixedNextBowlResult.HasValue,
              "تخريب سؤال مستقل لا يؤثر في آخر");

        var dispatcher = new MonsterDispatcher(
            new MonsterValidationManager(), new MonsterMetricsManager());
        var trace = second.BranchTrace.ToArray();
        var rejected = false;
        try { dispatcher.DispatchLegacyFixedNextBowl(second); }
        catch (MonsterValidationException) { rejected = true; }
        Check(rejected && second.BranchTrace.SequenceEqual(trace) &&
              second.Metrics["legacy.fixed.next.bowl.dispatch"] == 1,
              "رفض تنفيذ مكرر قبل أي تغيير");

        var f = NormativeScroll.FoundationDay;
        var fresh = new MonsterContext(f, f) {LegacyQueriedBowlId = 1};
        rejected = false;
        try { dispatcher.DispatchLegacyFixedNextBowl(fresh); }
        catch (MonsterValidationException) { rejected = true; }
        Check(rejected && fresh.Status == "NEW" &&
              fresh.BranchTrace.Count == 0 && fresh.LegacyFixedNextBowlResult is null,
              "سياق لم يُؤسس لا يقبل السؤال");

        foreach (var invalid in new[]{0,7,-1})
        {
            rejected = false;
            try { new MonsterManager().ExecuteLegacyFixedNextBowl(f,f,invalid); }
            catch (MonsterValidationException) { rejected = true; }
            Check(rejected, "حارس مجال هوية الوعاء " + invalid);
        }

        var ready = new MonsterManager().Prepare(f, f);
        ready.LegacyQueriedBowlId = 1;
        var candidate = new LegacyFixedNextBowlPhaseHandler().Handle(ready);
        var validator = new MonsterValidationManager();
        validator.ValidateVisibleDropPatch(ready, candidate.Sauce.Historical.Source);
        validator.ValidateLegacyOverwrittenSauce(ready, candidate.Sauce.Historical);
        validator.ValidateProtectedDrop46Sauce(ready, candidate.Sauce);
        validator.ValidateLegacyFixedNextBowl(ready, candidate);
        Check(ready.Status == "BOOTSTRAP_READY" &&
              ready.LegacyFixedNextBowlResult is null &&
              ready.PatchedSauceFinalBowls is null &&
              ready.BranchTrace.SequenceEqual(new[]{"BOOTSTRAP_VALIDATION"}),
              "التحقق من المرشح قبل الالتزام لا يكتب الحالة");

        rejected = false;
        try {validator.ValidateLegacyFixedNextBowl(ready,
            candidate with {LegacyNextBowlId = 6});}
        catch (MonsterValidationException) {rejected = true;}
        Check(rejected && ready.LegacyFixedNextBowlResult is null &&
              ready.PatchedSauceFinalBowls is null &&
              ready.BranchTrace.SequenceEqual(new[]{"BOOTSTRAP_VALIDATION"}),
              "رفض إصلاح مزيف لنتيجة القديم دون التزام");

        rejected = false;
        try {validator.ValidateLegacyFixedNextBowl(ready,
            candidate with {QueriedBowlId = 2});}
        catch (MonsterValidationException) {rejected = true;}
        Check(rejected && ready.LegacyFixedNextBowlResult is null,
              "رفض تبديل السؤال في المرشح دون الالتزام");
    }
}
