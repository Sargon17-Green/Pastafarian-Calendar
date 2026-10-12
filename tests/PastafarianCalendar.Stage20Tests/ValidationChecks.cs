using System.Numerics;
using PastafarianCalendar.Monster;
using PastafarianCalendar.Stage01Tests.Normative;

namespace PastafarianCalendar.Stage20Tests;

internal static partial class Program
{
    private static void VerifyContextIsolation()
    {
        var f=NormativeScroll.FoundationDay;
        var manager=new MonsterManager();
        var first=manager.ExecuteLegacyInPlaceStir(f,f+1,1);
        var second=manager.ExecuteLegacyInPlaceStir(f,f+1,1);
        Check(!ReferenceEquals(first,second) &&
            !ReferenceEquals(first.LegacyStirredBowls,second.LegacyStirredBowls) &&
            !ReferenceEquals(first.LegacyStirredBowls,first.LegacyPourInitialBowls) &&
            !ReferenceEquals(first.LegacyPourInitialBowls,second.LegacyPourInitialBowls) &&
            !ReferenceEquals(first.PatchedPoursResult,second.PatchedPoursResult) &&
            !ReferenceEquals(first.PatchedVisibleDrops,second.PatchedVisibleDrops) &&
            !ReferenceEquals(first.BranchTrace,second.BranchTrace) &&
            !ReferenceEquals(first.Metrics,second.Metrics),
            "عزل مخازن التحريك والشواهد والسياقات");

        var untouched=(BigInteger[])second.LegacyStirredBowls!.Clone();
        var oldInitial=(BigInteger[])second.LegacyPourInitialBowls!.Clone();
        first.LegacyStirredBowls![1]=0;
        first.LegacyPourInitialBowls![2]=0;
        first.PatchedPoursResult![3]=0;
        Check(second.LegacyStirredBowls!.SequenceEqual(untouched) &&
            second.LegacyPourInitialBowls!.SequenceEqual(oldInitial) &&
            second.PatchedPoursResult![3]>=1,
            "طفرة سياق لا تلوّث سياقاً آخر");

        var dispatcher=new MonsterDispatcher(
            new MonsterValidationManager(),new MonsterMetricsManager());
        var trace=second.BranchTrace.ToArray();
        var rejected=false;
        try {dispatcher.DispatchLegacyInPlaceStir(second);}
        catch(MonsterValidationException){rejected=true;}
        Check(rejected && second.Status=="LEGACY_IN_PLACE_BOWL_STIR_COMPLETE" &&
            second.BranchTrace.SequenceEqual(trace) &&
            second.LegacyStirredBowls!.SequenceEqual(untouched) &&
            second.Metrics["legacy.in.place.bowl.stir.dispatch"]==1,
            "رفض إعادة التنفيذ دون تغيير السياق");

        var empty=manager.Prepare(f,f);
        rejected=false;
        try{dispatcher.DispatchLegacyInPlaceStir(empty);}
        catch(MonsterValidationException){rejected=true;}
        Check(rejected && empty.Status=="BOOTSTRAP_READY" &&
            empty.LegacyStirredBowls is null &&
            empty.PatchedPoursResult is null &&
            empty.BranchTrace.SequenceEqual(new[]{"BOOTSTRAP_VALIDATION"}),
            "رفض المدخل المفقود بلا أثر");

        var unprepared=new MonsterContext(f,f) {LegacyPourVisibleIndex=1};
        rejected=false;
        try{dispatcher.DispatchLegacyInPlaceStir(unprepared);}
        catch(MonsterValidationException){rejected=true;}
        Check(rejected && unprepared.Status=="NEW" &&
            unprepared.BranchTrace.Count==0 &&
            unprepared.LegacyStirredBowls is null,
            "رفض سياق غير مؤسس");

        foreach(var bad in new[]{-1,0,47,int.MaxValue})
        {
            rejected=false;
            try{_=CalendarDateSpaghetti.EvaluateLegacyInPlaceStir(f,f,bad);}
            catch(MonsterValidationException){rejected=true;}
            Check(rejected,"رفض فهرس قطرة غير صالح "+bad);
        }

        var prepared=manager.Prepare(f,f);
        prepared.LegacyPourVisibleIndex=1;
        var candidate=new LegacyInPlaceBowlStirPhaseHandler().Handle(prepared);
        var validator=new MonsterValidationManager();
        validator.ValidateLegacyPours(prepared,candidate.Source.Legacy);
        validator.ValidateBowlAliasPatch(prepared,candidate.Source);
        validator.ValidateLegacyInPlaceStir(prepared,candidate);
        Check(prepared.LegacyStirredBowls is null &&
            prepared.PatchedPoursResult is null &&
            prepared.Status=="BOOTSTRAP_READY" &&
            prepared.BranchTrace.SequenceEqual(new[]{"BOOTSTRAP_VALIDATION"}),
            "التحقق لا يُثبت نتيجة قبل الإرسال");

        var corrupt=(BigInteger[])candidate.MutatedBowls.Clone();
        corrupt[1]=0;
        rejected=false;
        try{validator.ValidateLegacyInPlaceStir(prepared,
            candidate with {MutatedBowls=corrupt});}
        catch(MonsterValidationException){rejected=true;}
        Check(rejected && prepared.LegacyStirredBowls is null,
            "رفض مرشح تحريك عُدّل بعد حسابه");

        var aliasWrong=(int[])candidate.Source.Aliases.Clone();
        (aliasWrong[1],aliasWrong[2])=(aliasWrong[2],aliasWrong[1]);
        rejected=false;
        try{validator.ValidateBowlAliasPatch(prepared,
            candidate.Source with {Aliases=aliasWrong});}
        catch(MonsterValidationException){rejected=true;}
        Check(rejected && prepared.PatchedPoursResult is null,
            "المسار السابق يرفض هوية وعاء محوّرة");

        Check(second.LegacyStirredBowls!.SequenceEqual(untouched),
            "رفض المرشح لا يغير حالة مكتملة");
    }
}
