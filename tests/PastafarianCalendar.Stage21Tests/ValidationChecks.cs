using System.Numerics;
using PastafarianCalendar.Monster;
using PastafarianCalendar.Stage01Tests.Normative;

namespace PastafarianCalendar.Stage21Tests;

internal static partial class Program
{
    private static void VerifyOwnershipAndRejection()
    {
        var f=NormativeScroll.FoundationDay;
        var manager=new MonsterManager();
        var first=manager.ExecutePatchedBowlStir(f,f+1,1);
        var second=manager.ExecutePatchedBowlStir(f,f+1,1);
        Check(!ReferenceEquals(first,second) &&
            !ReferenceEquals(first.PatchedStirredBowls,second.PatchedStirredBowls) &&
            !ReferenceEquals(first.LegacyStirredBowls,second.LegacyStirredBowls) &&
            !ReferenceEquals(first.StirVaultOld,second.StirVaultOld) &&
            !ReferenceEquals(first.StirPending,second.StirPending) &&
            !ReferenceEquals(first.PatchedPoursResult,second.PatchedPoursResult) &&
            !ReferenceEquals(first.PatchedVisibleDrops,second.PatchedVisibleDrops) &&
            !ReferenceEquals(first.BranchTrace,second.BranchTrace) &&
            !ReferenceEquals(first.Metrics,second.Metrics),
            "ملكية مستقلة لكل سياق وكل مخزن");

        var result=(BigInteger[])second.PatchedStirredBowls!.Clone();
        var historical=(BigInteger[])second.LegacyStirredBowls!.Clone();
        var vault=(BigInteger[])second.StirVaultOld!.Clone();
        var pending=(BigInteger[])second.StirPending!.Clone();

        first.PatchedStirredBowls![1]=0;
        first.LegacyStirredBowls![2]=0;
        first.StirVaultOld![3]=0;
        first.StirPending![4]=0;
        Check(second.PatchedStirredBowls!.SequenceEqual(result) &&
              second.LegacyStirredBowls!.SequenceEqual(historical) &&
              second.StirVaultOld!.SequenceEqual(vault) &&
              second.StirPending!.SequenceEqual(pending),
              "لا تتسرّب طفرة مخازن استدعاء إلى الاستدعاء المجاور");

        var beforeResult=(BigInteger[])second.PatchedStirredBowls.Clone();
        second.PatchedStirredBowls[1]=0;
        Check(second.StirPending!.SequenceEqual(pending) &&
              second.StirVaultOld!.SequenceEqual(vault),
            "المخزن الملتزم منفصل حتى عن pending وvaultOld");
        second.PatchedStirredBowls[1]=beforeResult[1];

        var dispatcher=new MonsterDispatcher(
            new MonsterValidationManager(),new MonsterMetricsManager());
        var trace=second.BranchTrace.ToArray();
        var rejected=false;
        try{dispatcher.DispatchShadowBowlStir(second);}
        catch(MonsterValidationException){rejected=true;}
        Check(rejected &&
              second.PatchedStirredBowls.SequenceEqual(result) &&
              second.BranchTrace.SequenceEqual(trace) &&
              second.Metrics["shadow.bowl.stir.patch.dispatch"]==1,
              "رفض تنفيذ الرقعة مرتين دون تغيير حالة أو عداد");

        var missing=manager.Prepare(f,f);
        rejected=false;
        try{dispatcher.DispatchShadowBowlStir(missing);}
        catch(MonsterValidationException){rejected=true;}
        Check(rejected && missing.PatchedStirredBowls is null &&
              missing.StirPending is null && missing.StirVaultOld is null &&
              missing.Status=="BOOTSTRAP_READY" &&
              missing.BranchTrace.SequenceEqual(new[]{"BOOTSTRAP_VALIDATION"}),
              "مدخل ناقص لا يثبت مخازن مؤقتة");

        var unprepared=new MonsterContext(f,f){LegacyPourVisibleIndex=1};
        rejected=false;
        try{dispatcher.DispatchShadowBowlStir(unprepared);}
        catch(MonsterValidationException){rejected=true;}
        Check(rejected && unprepared.Status=="NEW" &&
              unprepared.PatchedStirredBowls is null &&
              unprepared.BranchTrace.Count==0,
              "رفض السياق غير المؤسس");

        foreach(var index in new[]{-1,0,47,int.MaxValue})
        {
            rejected=false;
            try{_=CalendarDateSpaghetti.EvaluatePatchedBowlStir(f,f,index);}
            catch(MonsterValidationException){rejected=true;}
            Check(rejected,"رفض رتبة قطرة خارج المجال "+index);
        }

        var prepared=manager.Prepare(f,f);
        prepared.LegacyPourVisibleIndex=1;
        var candidate=new ShadowBowlStirPhaseHandler().Handle(prepared);
        var validator=new MonsterValidationManager();
        validator.ValidateLegacyPours(prepared,candidate.Legacy.Source.Legacy);
        validator.ValidateBowlAliasPatch(prepared,candidate.Legacy.Source);
        validator.ValidateLegacyInPlaceStir(prepared,candidate.Legacy);
        validator.ValidateShadowBowlStir(prepared,candidate);
        Check(prepared.PatchedStirredBowls is null &&
              prepared.StirVaultOld is null && prepared.StirPending is null &&
              prepared.LegacyStirredBowls is null &&
              prepared.Status=="BOOTSTRAP_READY" &&
              prepared.BranchTrace.SequenceEqual(new[]{"BOOTSTRAP_VALIDATION"}),
              "التحقق من المرشح لا يلتزم قبل اكتمال كل الطبقات");

        void MustReject(ShadowBowlStirCandidate altered,string reason)
        {
            var denied=false;
            try{validator.ValidateShadowBowlStir(prepared,altered);}
            catch(MonsterValidationException){denied=true;}
            Check(denied && prepared.PatchedStirredBowls is null &&
                  prepared.StirPending is null && prepared.StirVaultOld is null,
                  "رفض مرشح فاسد قبل الالتزام: "+reason);
        }

        var badPending=(BigInteger[])candidate.Patched.Pending.Clone();
        badPending[1]=0;
        MustReject(candidate with {Patched=candidate.Patched with {Pending=badPending}},
            "pending غير مطابق للمزج");
        var badVault=(BigInteger[])candidate.Patched.VaultOld.Clone();
        badVault[2]++;
        MustReject(candidate with {Patched=candidate.Patched with {VaultOld=badVault}},
            "vaultOld لا يمثل الحالة الأصلية");
        var badCommitted=(BigInteger[])candidate.Patched.Committed.Clone();
        badCommitted[3]=0;
        MustReject(candidate with {Patched=candidate.Patched with {Committed=badCommitted}},
            "الالتزام لا يساوي pending");
        MustReject(candidate with {Patched=candidate.Patched with {
            Pending=candidate.Patched.Committed}},
            "استخدام الذاكرة نفسها للكتابة الحية والمؤجلة");

        // الغلاف ذاته لا يغيّر مخزن المدخل إذا رُفضت المعطيات.
        var oldBowls=(BigInteger[])candidate.Legacy.Source.Legacy.InitialBowls.Clone();
        var wrongPours=(BigInteger[])candidate.Legacy.Source.PatchedPours.Clone();
        wrongPours[4]=1;
        rejected=false;
        try{_=new ShadowBowlStirPatch().StirOneDropViaShadow(
            oldBowls,1,candidate.Legacy.Source.Legacy.Drop,
            candidate.Legacy.Source.Legacy.Source.Stones,
            candidate.Legacy.Source.Legacy.Order,wrongPours);}
        catch(MonsterValidationException){rejected=true;}
        Check(rejected && oldBowls.SequenceEqual(
            candidate.Legacy.Source.Legacy.InitialBowls),
            "مدخل فاسد لا يكتب في مخزن المصدر");

        // يبقى الاختبار التاريخي المباشر أحمر لتلوث جميع المواضع التالية.
        Check(second.LegacyStirredBowls!.SequenceEqual(historical) &&
              second.PatchedStirredBowls!.SequenceEqual(result),
              "شهادة العيب القديم والنتيجة المصححة منفصلتان");
    }
}
