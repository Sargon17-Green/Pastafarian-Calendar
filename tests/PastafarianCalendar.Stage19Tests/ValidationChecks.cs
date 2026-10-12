using System.Numerics;
using PastafarianCalendar.Monster;
using PastafarianCalendar.Stage01Tests.Normative;

namespace PastafarianCalendar.Stage19Tests;

internal static partial class Program
{
    private static void CheckIsolationAndRejection()
    {
        var f=NormativeScroll.FoundationDay;
        var manager=new MonsterManager();
        var a=manager.ExecutePatchedBowlPours(f,f+1,1);
        var b=manager.ExecutePatchedBowlPours(f,f+1,1);
        Check(!ReferenceEquals(a,b) &&
            !ReferenceEquals(a.PatchedPoursResult,b.PatchedPoursResult) &&
            !ReferenceEquals(a.LegacyPoursResult,b.LegacyPoursResult) &&
            !ReferenceEquals(a.PatchedPoursResult,a.LegacyPoursResult) &&
            !ReferenceEquals(a.BowlAliases,b.BowlAliases) &&
            !ReferenceEquals(a.LegacyPourInitialBowls,b.LegacyPourInitialBowls) &&
            !ReferenceEquals(a.PatchedVisibleDrops,b.PatchedVisibleDrops) &&
            !ReferenceEquals(a.PatchedStoneRows,b.PatchedStoneRows) &&
            !ReferenceEquals(a.BranchTrace,b.BranchTrace) &&
            !ReferenceEquals(a.Metrics,b.Metrics),
            "كل سياق يملك المصفوفات والخرائط والسجلات بنفسه");

        var oldPatched=(BigInteger[])b.PatchedPoursResult!.Clone();
        var oldLegacy=(BigInteger[])b.LegacyPoursResult!.Clone();
        var oldAliases=(int[])b.BowlAliases!.Clone();
        var oldBowls=(BigInteger[])b.LegacyPourInitialBowls!.Clone();
        var oldVisible=(BigInteger[])b.PatchedVisibleDrops!.Clone();
        a.PatchedPoursResult![1]=0;
        a.LegacyPoursResult![1]=0;
        a.BowlAliases![1]=0;
        a.LegacyPourInitialBowls![1]=0;
        a.PatchedVisibleDrops![1]=0;
        Check(b.PatchedPoursResult!.SequenceEqual(oldPatched) &&
            b.LegacyPoursResult!.SequenceEqual(oldLegacy) &&
            b.BowlAliases!.SequenceEqual(oldAliases) &&
            b.LegacyPourInitialBowls!.SequenceEqual(oldBowls) &&
            b.PatchedVisibleDrops!.SequenceEqual(oldVisible),
            "لا تتسرّب الكتابة إلى استدعاء مجاور");

        var dispatcher=new MonsterDispatcher(
            new MonsterValidationManager(),new MonsterMetricsManager());
        var trace=b.BranchTrace.ToArray();
        var rejected=false;
        try { dispatcher.DispatchBowlAliasPatched(b); }
        catch(MonsterValidationException) {rejected=true;}
        Check(rejected && b.Status=="BOWL_ALIAS_PATCH_COMPLETE" &&
            b.BranchTrace.SequenceEqual(trace) &&
            b.PatchedPoursResult!.SequenceEqual(oldPatched) &&
            b.Metrics["bowl.alias.patch.dispatch"]==1,
            "التكرار مرفوض قبل تغيير النتائج أو القياسات");

        var missing=manager.Prepare(f,f);
        rejected=false;
        try { dispatcher.DispatchBowlAliasPatched(missing); }
        catch(MonsterValidationException) {rejected=true;}
        Check(rejected && missing.Status=="BOOTSTRAP_READY" &&
            missing.LegacyPoursResult is null &&
            missing.PatchedPoursResult is null &&
            missing.BowlAliases is null &&
            missing.BranchTrace.SequenceEqual(new[]{"BOOTSTRAP_VALIDATION"}),
            "مدخل غير محدد لا يثبت حالة جزئية");

        var notReady=new MonsterContext(f,f+1){LegacyPourVisibleIndex=1};
        rejected=false;
        try { dispatcher.DispatchBowlAliasPatched(notReady); }
        catch(MonsterValidationException) {rejected=true;}
        Check(rejected && notReady.Status=="NEW" &&
            notReady.BranchTrace.Count==0 && notReady.BowlAliases is null,
            "رفض السياق قبل التأسيس");

        foreach(var invalid in new[]{-1,0,47,int.MaxValue})
        {
            rejected=false;
            try { _=CalendarDateSpaghetti.EvaluatePatchedBowlPours(f,f+1,invalid); }
            catch(MonsterValidationException) {rejected=true;}
            Check(rejected,"رفض الموضع غير الصالح " + invalid);
        }

        var prepared=manager.Prepare(f,f);
        prepared.LegacyPourVisibleIndex=1;
        var candidate=new BowlAliasPatchPhaseHandler().Handle(prepared);
        var validator=new MonsterValidationManager();
        validator.ValidateLegacyPours(prepared,candidate.Legacy);
        validator.ValidateBowlAliasPatch(prepared,candidate);
        Check(prepared.LegacyPoursResult is null &&
            prepared.PatchedPoursResult is null &&
            prepared.BowlAliases is null &&
            prepared.Status=="BOOTSTRAP_READY" &&
            prepared.BranchTrace.SequenceEqual(new[]{"BOOTSTRAP_VALIDATION"}),
            "مدير التحقق لا يثبّت المرشح قبل الموزّع");

        var badMap=(int[])candidate.Aliases.Clone();
        (badMap[1],badMap[2])=(badMap[2],badMap[1]);
        rejected=false;
        try {validator.ValidateBowlAliasPatch(prepared,candidate with {Aliases=badMap});}
        catch(MonsterValidationException){rejected=true;}
        Check(rejected && prepared.PatchedPoursResult is null,
            "رفض خريطة المواضع المغايرة للترتيب");

        var badPours=(BigInteger[])candidate.PatchedPours.Clone();
        badPours[1]=BigInteger.Zero;
        rejected=false;
        try {validator.ValidateBowlAliasPatch(prepared,candidate with {PatchedPours=badPours});}
        catch(MonsterValidationException){rejected=true;}
        Check(rejected && prepared.PatchedPoursResult is null,
            "رفض قيم الصبّ المعدلة خارج الغلاف");

        var tamperedOld=(BigInteger[])candidate.Legacy.Pours.Clone();
        tamperedOld[1]=BigInteger.Zero;
        rejected=false;
        try {validator.ValidateLegacyPours(
            prepared,candidate.Legacy with {Pours=tamperedOld});}
        catch(MonsterValidationException){rejected=true;}
        Check(rejected && prepared.LegacyPoursResult is null,
            "رفض محو شاهد الخطأ التاريخي");

        Check(b.PatchedPoursResult!.SequenceEqual(oldPatched) &&
            b.LegacyPoursResult!.SequenceEqual(oldLegacy) &&
            b.BowlAliases!.SequenceEqual(oldAliases),
            "التحقق الفاشل لا يمس استدعاءات اكتملت");
    }
}
