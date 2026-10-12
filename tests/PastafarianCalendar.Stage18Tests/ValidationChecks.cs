using System.Numerics;
using PastafarianCalendar.Monster;
using PastafarianCalendar.Stage01Tests.Normative;

namespace PastafarianCalendar.Stage18Tests;

internal static partial class Program
{
    private static void VerifyContextAndRejection()
    {
        var f = NormativeScroll.FoundationDay;
        var manager = new MonsterManager();
        var a = manager.ExecuteLegacyFixedBowlPours(f,f+1,1);
        var b = manager.ExecuteLegacyFixedBowlPours(f,f+1,1);
        Check(!ReferenceEquals(a,b) &&
            !ReferenceEquals(a.LegacyPoursResult,b.LegacyPoursResult) &&
            !ReferenceEquals(a.LegacyPourOrder,b.LegacyPourOrder) &&
            !ReferenceEquals(a.LegacyPourInitialBowls,b.LegacyPourInitialBowls) &&
            !ReferenceEquals(a.PatchedVisibleDrops,b.PatchedVisibleDrops) &&
            !ReferenceEquals(a.PatchedStoneRows,b.PatchedStoneRows) &&
            !ReferenceEquals(a.BranchTrace,b.BranchTrace) &&
            !ReferenceEquals(a.Metrics,b.Metrics),
            "السياقان لا يشتركان في نتائج أو أوعية أو قطرات أو سجلات.");

        var oldPours = (BigInteger[])b.LegacyPoursResult!.Clone();
        var oldBowls = (BigInteger[])b.LegacyPourInitialBowls!.Clone();
        var oldOrder = (int[])b.LegacyPourOrder!.Clone();
        var oldVisible = (BigInteger[])b.PatchedVisibleDrops!.Clone();
        a.LegacyPoursResult![1] = 0;
        a.LegacyPourInitialBowls![1] = 0;
        a.LegacyPourOrder![0] = -9;
        a.PatchedVisibleDrops![1] = 0;
        Check(b.LegacyPoursResult!.SequenceEqual(oldPours) &&
            b.LegacyPourInitialBowls!.SequenceEqual(oldBowls) &&
            b.LegacyPourOrder!.SequenceEqual(oldOrder) &&
            b.PatchedVisibleDrops!.SequenceEqual(oldVisible),
            "تغيير سياق واحد لا يلوّث الثاني.");

        var dispatcher = new MonsterDispatcher(
            new MonsterValidationManager(),new MonsterMetricsManager());
        var oldTrace = b.BranchTrace.ToArray();
        var denied = false;
        try { dispatcher.DispatchLegacyPours(b); }
        catch (MonsterValidationException) { denied = true; }
        Check(denied && b.Status == "LEGACY_FIXED_BOWL_POURS_COMPLETE" &&
            b.BranchTrace.SequenceEqual(oldTrace) &&
            b.LegacyPoursResult!.SequenceEqual(oldPours) &&
            b.Metrics["legacy.fixed.bowl.pours.dispatch"] == 1,
            "التنفيذ المكرر مرفوض قبل تعديل الحالة.");

        var withoutIndex = manager.Prepare(f,f+1);
        denied = false;
        try { dispatcher.DispatchLegacyPours(withoutIndex); }
        catch (MonsterValidationException) { denied = true; }
        Check(denied && withoutIndex.Status == "BOOTSTRAP_READY" &&
            withoutIndex.LegacyPoursResult is null &&
            withoutIndex.BranchTrace.SequenceEqual(new[] {"BOOTSTRAP_VALIDATION"}),
            "رفض عدم تقديم رتبة القطرة من غير التزام.");

        var newContext = new MonsterContext(f,f+1)
            { LegacyPourVisibleIndex = 1 };
        denied = false;
        try { dispatcher.DispatchLegacyPours(newContext); }
        catch (MonsterValidationException) { denied = true; }
        Check(denied && newContext.Status == "NEW" &&
            newContext.BranchTrace.Count == 0 &&
            newContext.LegacyPoursResult is null,
            "رفض السياق غير المؤسس بلا أثر.");

        foreach (var bad in new[] {-1,0,47,int.MaxValue})
        {
            denied = false;
            try { _ = CalendarDateSpaghetti.EvaluateLegacyFixedBowlPours(f,f+1,bad); }
            catch (MonsterValidationException) { denied = true; }
            Check(denied,"رفض رتبة صبّ غير صالحة قبل العمل " + bad);
        }

        var prepared = manager.Prepare(f,f+1);
        prepared.LegacyPourVisibleIndex = 1;
        var candidate = new LegacyPoursPhaseHandler().Handle(prepared);
        var validator = new MonsterValidationManager();
        validator.ValidateLegacyPours(prepared,candidate);
        Check(prepared.LegacyPoursResult is null &&
            prepared.Status == "BOOTSTRAP_READY" &&
            prepared.LegacyPourDrop is null &&
            prepared.BranchTrace.SequenceEqual(new[] {"BOOTSTRAP_VALIDATION"}),
            "التحقق من المرشح لا يكتب أي نتيجة.");

        var badPours = (BigInteger[])candidate.Pours.Clone();
        badPours[1] = 0;
        denied = false;
        try { validator.ValidateLegacyPours(
            prepared,candidate with { Pours = badPours }); }
        catch (MonsterValidationException) { denied = true; }
        Check(denied && prepared.LegacyPoursResult is null,
            "لا يُقبل تشويه الصبّ التاريخي.");

        var badOrder = (int[])candidate.Order.Clone();
        badOrder[0] = 9;
        denied = false;
        try { validator.ValidateLegacyPours(
            prepared,candidate with { Order = badOrder }); }
        catch (MonsterValidationException) { denied = true; }
        Check(denied && prepared.LegacyPoursResult is null,
            "لا يُقبل ترتيب أوعية غير مطابق للرقعة الثامنة.");

        var badBowls = (BigInteger[])candidate.InitialBowls.Clone();
        badBowls[2]++;
        denied = false;
        try { validator.ValidateLegacyPours(
            prepared,candidate with { InitialBowls = badBowls }); }
        catch (MonsterValidationException) { denied = true; }
        Check(denied && prepared.LegacyPoursResult is null,
            "لا يُقبل مصنَع أوعية محوّر.");

        Check(b.LegacyPoursResult!.SequenceEqual(oldPours) &&
            b.LegacyPourInitialBowls!.SequenceEqual(oldBowls),
            "فشل المرشح لا يمس نتائج سياق مكتمل.");
    }
}
