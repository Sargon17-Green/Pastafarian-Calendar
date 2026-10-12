using System.Numerics;
using PastafarianCalendar.Monster;

namespace PastafarianCalendar.Stage17Tests;

internal static partial class Program
{
    private static void VerifyOwnershipAndValidation()
    {
        var manager = new MonsterManager();
        var first = manager.ExecutePatchedBowlOrder(0,1,1);
        var second = manager.ExecutePatchedBowlOrder(0,1,1);
        Check(!ReferenceEquals(first,second) &&
              !ReferenceEquals(first.PatchedBowlOrderResult,second.PatchedBowlOrderResult) &&
              !ReferenceEquals(first.LegacyBowlOrderResult,second.LegacyBowlOrderResult) &&
              !ReferenceEquals(first.PatchedBowlOrderResult,first.LegacyBowlOrderResult) &&
              !ReferenceEquals(first.BranchTrace,second.BranchTrace) &&
              !ReferenceEquals(first.Metrics,second.Metrics),
              "فصل ملكية النتيجتين والسجلات والسياقات");
        var correct = (int[])second.PatchedBowlOrderResult!.Clone();
        var historical = (int[])second.LegacyBowlOrderResult!.Clone();
        first.PatchedBowlOrderResult![0] = -999;
        first.LegacyBowlOrderResult![0] = -888;
        Check(second.PatchedBowlOrderResult!.SequenceEqual(correct) &&
              second.LegacyBowlOrderResult!.SequenceEqual(historical),
              "لا تتسرّب الطفرة من سياق آخر");

        var dispatcher = new MonsterDispatcher(
            new MonsterValidationManager(),new MonsterMetricsManager());
        var trace = second.BranchTrace.ToArray();
        var before = second.Metrics["bowl.order.patch.dispatch"];
        var refused = false;
        try { dispatcher.DispatchBowlOrderPatched(second); }
        catch (MonsterValidationException) { refused = true; }
        Check(refused &&
              second.BranchTrace.SequenceEqual(trace) &&
              second.Metrics["bowl.order.patch.dispatch"] == before &&
              second.PatchedBowlOrderResult!.SequenceEqual(correct),
              "منع استدعاء الرقعة مرتين دون تغيير النتائج");

        var missing = manager.Prepare(0,0);
        refused = false;
        try { dispatcher.DispatchBowlOrderPatched(missing); }
        catch (MonsterValidationException) { refused = true; }
        Check(refused && missing.Status == "BOOTSTRAP_READY" &&
              missing.PatchedBowlOrderResult is null &&
              missing.LegacyBowlOrderResult is null &&
              missing.BranchTrace.SequenceEqual(new[] {"BOOTSTRAP_VALIDATION"}),
              "رفض الإدخال المفقود بلا التزام جزئي");

        var notReady = new MonsterContext(0,0) { LegacyBowlOrderInput=1 };
        refused = false;
        try { dispatcher.DispatchBowlOrderPatched(notReady); }
        catch (MonsterValidationException) { refused = true; }
        Check(refused && notReady.Status == "NEW" &&
              notReady.BranchTrace.Count == 0 &&
              notReady.PatchedBowlOrderResult is null,
              "رفض السياق غير المؤسس بلا أثر");

        var occupied = manager.Prepare(0,0);
        occupied.LegacyBowlOrderInput = 1;
        occupied.PatchedBowlOrderResult = new int[] {1,2,3,4,5,6};
        trace = occupied.BranchTrace.ToArray();
        refused = false;
        try { dispatcher.DispatchBowlOrderPatched(occupied); }
        catch (MonsterValidationException) { refused = true; }
        Check(refused && occupied.Status == "BOOTSTRAP_READY" &&
              occupied.BranchTrace.SequenceEqual(trace) &&
              !occupied.Metrics.ContainsKey("bowl.order.patch.dispatch"),
              "رفض الحالة المشغولة قبل الحساب");

        var validator = new MonsterValidationManager();
        var pure = manager.Prepare(0,0);
        pure.LegacyBowlOrderInput = 1;
        var wrapper = new BowlOrderPatchWrapper();
        var patch = wrapper.OrderPatchFromValue(1);
        var wrong = LegacyBowlPermutation.OldPermutationUnrank0(1);
        validator.ValidateBowlOrderPatch(
            pure,patch.OneBased,patch.LegacyRank0,patch.Order,wrong,false);
        Check(pure.PatchedBowlOrderResult is null &&
              pure.LegacyBowlOrderResult is null &&
              pure.Status == "BOOTSTRAP_READY",
              "التحقق لا يكتب الحالة");

        void MustReject(int oneBased,int rank0,int[] candidate,
                        int[]? witness,bool fault,string description)
        {
            var denied = false;
            try { validator.ValidateBowlOrderPatch(
                pure,oneBased,rank0,candidate,witness,fault); }
            catch (MonsterValidationException) { denied = true; }
            Check(denied &&
                  pure.PatchedBowlOrderResult is null &&
                  pure.LegacyBowlOrderResult is null,
                  "الرفض قبل الالتزام: " + description);
        }

        MustReject(1,1,patch.Order,wrong,false,"دليل صفري خطأ");
        MustReject(1,0,wrong,wrong,false,"نتيجة منزاحة بدلاً من المصححة");
        MustReject(1,0,new int[] {1,1,2,3,4,5},wrong,false,"تبديل مكرر");
        MustReject(1,0,patch.Order,patch.Order,false,"شاهد تاريخي مصحّح خطأ");
        MustReject(1,0,patch.Order,null,false,"شاهد تاريخي مفقود");
        MustReject(1,0,patch.Order,wrong,true,"استثناء مزعوم");

        var boundary = manager.Prepare(0,0);
        boundary.LegacyBowlOrderInput = 720;
        var last = wrapper.OrderPatchFromValue(720);
        validator.ValidateBowlOrderPatch(
            boundary,last.OneBased,last.LegacyRank0,last.Order,null,true);
        Check(last.OneBased == 720 && last.LegacyRank0 == 719 &&
              last.Order.SequenceEqual(
                  new[] {6,5,4,3,2,1}) &&
              boundary.PatchedBowlOrderResult is null,
              "رتبة 720 الأخيرة تتجاوز القديم بلا سقوط الرقعة");

        refused = false;
        try { validator.ValidateBowlOrderPatch(
            boundary,last.OneBased,last.LegacyRank0,last.Order,null,false); }
        catch (MonsterValidationException) { refused = true; }
        Check(refused,"الحارس يمنع إخفاء استثناء القديم للرتبة الأخيرة");

        foreach (var bad in new[] {0,-1,47,int.MaxValue})
        {
            refused = false;
            try { _ = CalendarDateSpaghetti.EvaluateBowlOrderFromVisibleDrop(0,1,bad); }
            catch (MonsterValidationException) { refused = true; }
            Check(refused,"رفض فهرس القطرة قبل حسابها: " + bad);
        }

        // لا يجري تعديل المفكك القديم، ويظل فشل رتبته 720 متاحاً في واجهته العامة.
        var oldFailed = false;
        try { _ = CalendarDateSpaghetti.EvaluateLegacyBowlOrder(0,1,720); }
        catch (ArgumentOutOfRangeException) { oldFailed = true; }
        Check(oldFailed &&
              CalendarDateSpaghetti.EvaluateBowlOrder(0,1,720)
                  .SequenceEqual(new[] {6,5,4,3,2,1}),
              "الفصل بين فشل القديم ونجاح المدخل المصحح");
    }
}
