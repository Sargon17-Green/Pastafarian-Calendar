using System.Numerics;

namespace PastafarianCalendar.Monster;

public sealed class MonsterValidationException : Exception
{
    public MonsterValidationException(string message) : base(message) { }
}

public sealed class MonsterValidationManager
{
    public void ValidateBootstrapContext(MonsterContext context)
    {
        if (context.RetryBudget < 0)
            throw new MonsterValidationException("ميزانية الإعادة لا يجوز أن تكون سالبة.");
        if (!string.Equals(context.Status, "NEW", StringComparison.Ordinal))
            throw new MonsterValidationException("حالة البدء غير صحيحة.");
    }

    public void ValidateSavePatchResult(MonsterContext context, BigInteger candidate)
    {
        if (context.LegacySaveInput is null || context.LegacySaveResult is not BigInteger legacy)
            throw new MonsterValidationException("لم يكتمل المسار القديم قبل فحص رقعة الحفظ.");
        if (context.PatchedSaveResult.HasValue)
            throw new MonsterValidationException("لا يُسمح بتثبيت الحفظ المصحح مرتين.");

        var modulus = (BigInteger.One << 127) - BigInteger.One;
        if (legacy < 0 || legacy >= modulus)
            throw new MonsterValidationException("باقي الحفظ القديم خارج المجال المحدد.");
        if (candidate != (legacy.IsZero ? modulus : legacy))
            throw new MonsterValidationException("نتيجة الرقعة لا توافق تحويل الباقي القديم.");
    }

    // لا يستعير هذا التحقق النتيجة من المرجع الاختباري؛ يختبر الالتزام بمعنى الرقعة المحلية.
    public void ValidateDayTagPatchResult(MonsterContext context, BigInteger candidate)
    {
        if (context.LegacyDayInput is not BigInteger day ||
            context.LegacyDayTagResult is not BigInteger legacy)
            throw new MonsterValidationException("لم يكتمل العدّ التاريخي قبل التحقق من الرقعة.");
        if (context.PatchedDayTagResult.HasValue)
            throw new MonsterValidationException("لا يجوز تثبيت عدّ اليوم المصحح مرتين.");

        var foundation = new BigInteger(-15055671);
        if (legacy < 0)
            throw new MonsterValidationException("العدّ التاريخي غير صالح.");
        var expected = day >= foundation ? legacy + BigInteger.One : legacy;
        if (candidate != expected)
            throw new MonsterValidationException("رقعة عدّ اليوم لا توافق فارق العدّ التاريخي.");
        if (day == foundation && candidate != BigInteger.One)
            throw new MonsterValidationException("حارس التأسيس لم يثبت الواحد.");
    }

    // فحص نطاق التزام الرقعة الثالثة قبل كتابة الخماسية الحسابية في السياق.
    public void ValidatePatchedCounts(MonsterContext context, MonsterWorkCounts candidate)
    {
        if (context.LegacyDistanceResult is not BigInteger historical)
            throw new MonsterValidationException("لم يُشغّل مسار المسافة القديم قبل الرقعة الثالثة.");
        if (context.PatchedCountsResult is not null)
            throw new MonsterValidationException("لا يجوز تثبيت عدّ العمل المصحح مرتين.");
        if (historical != LegacyDistance.OldDistance(context.CalculationDay, context.TargetDay))
            throw new MonsterValidationException("تغيّرت قيمة المسافة القديمة بين مرحلتين.");

        var action = new DayTagPatchWrapper().Patch(context.CalculationDay);
        var target = new DayTagPatchWrapper().Patch(context.TargetDay);
        var chronological = BigInteger.Abs(context.TargetDay - context.CalculationDay);
        var expectedDistance = (historical != chronological ? chronological : historical) + BigInteger.One;
        var expectedDirection = context.TargetDay < context.CalculationDay ? 1 :
            context.TargetDay > context.CalculationDay ? 3 : 2;

        if (candidate.Action != action || candidate.Target != target ||
            candidate.Distance != expectedDistance || candidate.Connection != action + target ||
            candidate.Direction != expectedDirection)
            throw new MonsterValidationException("لا تطابق رقعة العدّ الثالثة مع مقادير السياق.");

        if (candidate.Distance < BigInteger.One || candidate.Direction is < 1 or > 3)
            throw new MonsterValidationException("أنتجت رقعة المسافة عدّاً خارج النطاق.");
    }

    // لا يتحقق هذا الحارس بواسطة المرجع الاختباري أو قلب المصفوفة القديمة.
    public void ValidateHiddenNearnessWrapper(MonsterContext context, HiddenNearnessWrapper candidate)
    {
        if (context.LegacyHiddenReversed is not BigInteger[] legacy)
            throw new MonsterValidationException("لم يُشغّل مخزن القطرات التاريخي قبل الرقعة الخامسة.");
        if (context.PatchedHiddenAccess is not null)
            throw new MonsterValidationException("لا يجوز تثبيت غلاف القطرات مرتين.");
        if (candidate is null || !candidate.UsesUnchangedLegacyStorage(legacy))
            throw new MonsterValidationException("لا تقبل الرقعة مخزناً غير المخزن التاريخي نفسه.");
        if (legacy.Length != 8 || legacy[0] != BigInteger.Zero)
            throw new MonsterValidationException("ترتيب الخانات التاريخية غير صالح.");

        for (var k = 1; k <= 7; k++)
            if (candidate.HiddenByNearness(k) != legacy[8 - k])
                throw new MonsterValidationException("انقلب المخزن نفسه عوضاً عن إصلاح مؤشر القراءة.");
    }

    // يتحقق من التزام الرقعة السادسة من دون استعمال مرجع الاختبار.
    public void ValidatePatchedPrior(MonsterContext context, BigInteger candidate)
    {
        if (context.PatchedPriorResult.HasValue)
            throw new MonsterValidationException("لا يجوز تثبيت نتيجة الرجوع المصححة مرتين.");
        if (context.LegacyPriorDropStore is not BigInteger[] store ||
            context.LegacyPriorVisibleIndex is not int i ||
            context.LegacyPriorBack is not int back)
            throw new MonsterValidationException("لم تُقدَّم مدخلات الرجوع إلى التحقق.");
        if (store.Length != 47 || store[0] != BigInteger.Zero ||
            i is < 1 or > 46 || back is not (1 or 3 or 7))
            throw new MonsterValidationException("مخزن الرجوع أو فهارسه غير صالحة.");

        var slot = i - back;
        BigInteger expected;
        if (slot >= 1)
        {
            if (context.LegacyPriorResult is not BigInteger historical ||
                context.LegacyHiddenReversed is not null ||
                context.PatchedHiddenAccess is not null)
                throw new MonsterValidationException("لم تُحفظ نتيجة القديم المنفردة للموضع الموجب.");
            expected = LegacyPrior.Read(store, i, back);
            if (historical != expected)
                throw new MonsterValidationException("نتيجة القراءة التاريخية تغيّرت أثناء الرقعة.");
        }
        else
        {
            if (context.LegacyPriorResult is not null ||
                context.LegacyHiddenReversed is not BigInteger[] storage ||
                context.PatchedHiddenAccess is not HiddenNearnessWrapper hidden ||
                !hidden.UsesUnchangedLegacyStorage(storage))
                throw new MonsterValidationException("يستلزم الرجوع غير الموجب تخزين القطرات الخفية نفسه.");
            expected = hidden.HiddenByNearness(1 - slot);
        }

        if (candidate != expected)
            throw new MonsterValidationException("نتيجة الرقعة السادسة لا توافق فرع القراءة الصحيح.");
    }

    // لا يستدعي هذا الحارس مرجع الاختبار؛ يفحص أثر القديم ومسار تحويل الرتبة.
    public void ValidateBowlOrderPatch(
        MonsterContext context,
        int oneBased, int legacyRank0,
        int[] candidate, int[]? historical, bool historicalFault)
    {
        if (context.LegacyBowlOrderInput is not BigInteger drop ||
            context.PatchedBowlOrderResult is not null ||
            context.PatchedBowlOneBasedRank.HasValue ||
            context.PatchedBowlLegacyRank0.HasValue ||
            context.LegacyBowlOrderResult is not null ||
            context.LegacyBowlOneBasedRank.HasValue ||
            context.LegacyBowlRankOutOfRange)
            throw new MonsterValidationException("سياق رقعة ترتيب الأوعية ليس خالياً.");

        if (oneBased is < 1 or > 720 || legacyRank0 != oneBased - 1 ||
            oneBased != LegacyBowlPermutation.WrongOneBasedRank(drop))
            throw new MonsterValidationException("سلسلة التحويل الواحدي ثم الصفري غير صحيحة.");

        if (candidate is null || candidate.Length != 6 ||
            !candidate.OrderBy(x => x).SequenceEqual(new[] { 1, 2, 3, 4, 5, 6 }))
            throw new MonsterValidationException("ترتيب الأوعية المصحح ليس تبديلاً كاملاً.");

        var expected = LegacyBowlPermutation.OldPermutationUnrank0(legacyRank0);
        if (!candidate.SequenceEqual(expected))
            throw new MonsterValidationException("الرقعة لا تستخدم مفكك الرتبة الصفري القديم.");

        if (oneBased == 720)
        {
            if (!historicalFault || historical is not null)
                throw new MonsterValidationException("لم يُحفظ فشل القديم عند الرتبة 720.");
        }
        else if (historicalFault || historical is null ||
            ReferenceEquals(historical, candidate) ||
            !historical.SequenceEqual(LegacyBowlPermutation.OldPermutationUnrank0(oneBased)))
            throw new MonsterValidationException("شاهد ترتيب الأوعية التاريخي غير مطابق للندبة.");
    }

    // فحص المرشح التاريخي لا يطبق alias؛ الصبّ الثابت يبقى أثر الخطأ التاسع.
    public void ValidateLegacyPours(MonsterContext context, LegacyPoursCandidate candidate)
    {
        if (context.LegacyPourVisibleIndex is not int i || i is < 1 or > 46 ||
            context.LegacyPoursResult is not null ||
            context.LegacyPourDrop.HasValue ||
            context.LegacyPourOrder is not null ||
            context.LegacyPourInitialBowls is not null ||
            context.PatchedVisibleDrops is not null)
            throw new MonsterValidationException("حالة الصبّ التاريخي ليست خالية أو رتبة القطرة غير صالحة.");

        if (candidate is null || candidate.Source is null ||
            candidate.Source.Visible is null || candidate.Source.Visible.Length != 47 ||
            candidate.Source.Stones is null || candidate.Source.Stones.Length != 47 ||
            candidate.Source.Counts is null ||
            candidate.Source.Visible[i] != candidate.Drop ||
            candidate.InitialBowls is null || candidate.InitialBowls.Length != 7 ||
            candidate.InitialBowls[0] != BigInteger.Zero ||
            candidate.Order is null || candidate.Order.Length != 6 ||
            !candidate.Order.OrderBy(x => x).SequenceEqual(new[] {1, 2, 3, 4, 5, 6}) ||
            candidate.Pours is null || candidate.Pours.Length != 7 ||
            candidate.Pours[0] != BigInteger.Zero ||
            candidate.Pours[4] != BigInteger.Zero ||
            candidate.Pours[5] != BigInteger.Zero ||
            candidate.Pours[6] != BigInteger.Zero)
            throw new MonsterValidationException("حزمة الصبّ التاريخية ليست مكتملة.");

        var order = new BowlOrderPatchWrapper().OrderPatchFromValue(candidate.Drop).Order;
        if (!candidate.Order.SequenceEqual(order))
            throw new MonsterValidationException("ترتيب القطرة لا يوافق الرقعة الثامنة.");

        var expectedBowls = new LegacyBowlFactory().InitialBowls(candidate.Source.Counts);
        if (!candidate.InitialBowls.SequenceEqual(expectedBowls))
            throw new MonsterValidationException("مصنَع الأوعية الأولي لا يوافق خماسية العمل.");

        var expectedPours = new LegacyFixedBowlPours().PourIntoFixedIdentifiers(
            i, candidate.Drop, candidate.InitialBowls, candidate.Source.Stones);
        if (!candidate.Pours.SequenceEqual(expectedPours))
            throw new MonsterValidationException("قيمة الصبّ القديم لا تطابق قراءة أسماء الأوعية الثابتة.");
    }

    // يفحص الحارس أن كل قراءة وعاء مصححة مرّت بخريطة المواضع، دون مرجع اختبار.
    public void ValidateBowlAliasPatch(MonsterContext context, BowlAliasPatchCandidate candidate)
    {
        if (context.BowlAliases is not null || context.PatchedPoursResult is not null ||
            context.LegacyPoursResult is not null || context.LegacyPourDrop.HasValue ||
            context.LegacyPourInitialBowls is not null ||
            context.LegacyPourOrder is not null)
            throw new MonsterValidationException("رقعة الأسماء البديلة تتطلب سياقاً خالياً.");

        if (candidate is null || candidate.Legacy is null ||
            candidate.Legacy.Order is null || candidate.Legacy.Order.Length != 6 ||
            candidate.Aliases is null || candidate.Aliases.Length != 7 ||
            candidate.Aliases[0] != 0 ||
            candidate.PatchedPours is null || candidate.PatchedPours.Length != 7 ||
            ReferenceEquals(candidate.PatchedPours,candidate.Legacy.Pours) ||
            candidate.PatchedPours[0] != 0 ||
            candidate.PatchedPours[4] != 0 ||
            candidate.PatchedPours[5] != 0 ||
            candidate.PatchedPours[6] != 0)
            throw new MonsterValidationException("مرشح أسماء الأوعية غير مكتمل.");

        for (var position=1; position<=6; position++)
            if (candidate.Aliases[position] != candidate.Legacy.Order[position-1])
                throw new MonsterValidationException("اسم الوعاء البديل لا يوافق موضع ترتيبه.");

        var wrapper = new BowlAliasPatchWrapper();
        var reference = wrapper.PatchedPours(
            context.LegacyPourVisibleIndex!.Value,candidate.Legacy.Drop,
            candidate.Legacy.Source.Stones,candidate.Legacy.InitialBowls,candidate.Aliases);
        if (!candidate.PatchedPours.SequenceEqual(reference))
            throw new MonsterValidationException("الصبّ المصحح لم يقرأ الأوعية عبر خريطة المواضع.");
        for(var position=1;position<=3;position++)
            if(candidate.PatchedPours[position]<1)
                throw new MonsterValidationException("الصبّ المصحح غير محفوظ.");
    }

    // فحص التحريك التاريخي لا يقارن المرجع النظيف ولا يضيف مخزن صورة قديمة.
    public void ValidateLegacyInPlaceStir(MonsterContext context, LegacyInPlaceStirCandidate candidate)
    {
        if (context.LegacyPourVisibleIndex is not int index || index is < 1 or > 46 ||
            context.LegacyStirredBowls is not null ||
            context.PatchedPoursResult is not null || context.LegacyPoursResult is not null ||
            context.BowlAliases is not null || context.PatchedVisibleDrops is not null)
            throw new MonsterValidationException("سياق التحريك القديم ليس جاهزاً.");

        if (candidate is null || candidate.Source is null ||
            candidate.Source.Legacy is null ||
            candidate.Source.Legacy.InitialBowls is null ||
            candidate.Source.Legacy.InitialBowls.Length != 7 ||
            candidate.MutatedBowls is null || candidate.MutatedBowls.Length != 7 ||
            ReferenceEquals(candidate.MutatedBowls,candidate.Source.Legacy.InitialBowls) ||
            candidate.MutatedBowls[0] != BigInteger.Zero)
            throw new MonsterValidationException("النتيجة القديمة لا تملك أوعية مستقلة.");

        for (var id=1;id<=6;id++)
            if (candidate.MutatedBowls[id] < BigInteger.One)
                throw new MonsterValidationException("وعاء بعد التحريك القديم خارج مجال الحفظ.");

        var replay=(BigInteger[])candidate.Source.Legacy.InitialBowls.Clone();
        new LegacyInPlaceBowlStir().StirDirectlyIntoBowls(
            replay,index,candidate.Source.Legacy.Drop,
            candidate.Source.Legacy.Source.Stones,candidate.Source.Legacy.Order,
            candidate.Source.PatchedPours);
        if (!candidate.MutatedBowls.SequenceEqual(replay))
            throw new MonsterValidationException("فُقدت بصمة الكتابة المباشرة في التحريك القديم.");
    }

    // يُثبت فحص الرقعة أن جميع القراءات من الصورة السابقة قبل الالتزام.
    public void ValidateShadowBowlStir(MonsterContext context, ShadowBowlStirCandidate candidate)
    {
        if (context.LegacyPourVisibleIndex is not int index || index is < 1 or > 46 ||
            context.StirVaultOld is not null || context.StirPending is not null ||
            context.PatchedStirredBowls is not null ||
            context.LegacyStirredBowls is not null ||
            context.PatchedPoursResult is not null ||
            context.LegacyPoursResult is not null ||
            context.BowlAliases is not null ||
            context.PatchedVisibleDrops is not null)
            throw new MonsterValidationException("حالة التحريك بالظل ليست خالية.");

        if (candidate is null || candidate.Legacy is null ||
            candidate.Legacy.Source is null ||
            candidate.Patched is null ||
            candidate.Patched.VaultOld is null ||
            candidate.Patched.Pending is null ||
            candidate.Patched.Committed is null ||
            candidate.Patched.VaultOld.Length != 7 ||
            candidate.Patched.Pending.Length != 7 ||
            candidate.Patched.Committed.Length != 7 ||
            candidate.Patched.VaultOld[0] != BigInteger.Zero ||
            candidate.Patched.Pending[0] != BigInteger.Zero ||
            candidate.Patched.Committed[0] != BigInteger.Zero ||
            ReferenceEquals(candidate.Patched.VaultOld,candidate.Patched.Pending) ||
            ReferenceEquals(candidate.Patched.VaultOld,candidate.Patched.Committed) ||
            ReferenceEquals(candidate.Patched.Pending,candidate.Patched.Committed) ||
            ReferenceEquals(candidate.Patched.Committed,candidate.Legacy.MutatedBowls) ||
            ReferenceEquals(candidate.Patched.VaultOld,candidate.Legacy.Source.Legacy.InitialBowls))
            throw new MonsterValidationException("مخازن التحريك المصحح غير مستقلة.");

        var oldBowls=candidate.Legacy.Source.Legacy.InitialBowls;
        if (!candidate.Patched.VaultOld.SequenceEqual(oldBowls))
            throw new MonsterValidationException("صورة الأوعية القديمة لا تطابق البداية.");

        var replay=(BigInteger[])oldBowls.Clone();
        var expected=new ShadowBowlStirPatch().StirOneDropViaShadow(
            replay,index,candidate.Legacy.Source.Legacy.Drop,
            candidate.Legacy.Source.Legacy.Source.Stones,candidate.Legacy.Source.Legacy.Order,
            candidate.Legacy.Source.PatchedPours);
        if(!candidate.Patched.Pending.SequenceEqual(expected.Pending) ||
           !candidate.Patched.Committed.SequenceEqual(expected.Committed) ||
           !candidate.Patched.Committed.SequenceEqual(candidate.Patched.Pending))
            throw new MonsterValidationException("نتيجة مزج الظل لا تطابق الالتزام المؤجل.");

        for(var id=1;id<=6;id++)
            if(candidate.Patched.Committed[id]<1)
                throw new MonsterValidationException("نتيجة وعاء غير محفوظة.");
    }

    // جميع الأوعية والترتيبات تُراجع قبل كتابة حالة المعنى أو القياسات.
    public void ValidateLegacyOverwrittenSauce(
        MonsterContext context, LegacyOverwrittenSauceCandidate candidate)
    {
        if(context.LegacySauceFinalBowls is not null ||
           context.LegacyOverwrittenQueryOrder is not null ||
           context.PatchedVisibleDrops is not null)
            throw new MonsterValidationException("سياق الصلصة التاريخية ليس خالياً.");
        if(candidate is null || candidate.Source is null ||
           candidate.Source.Visible is null || candidate.Source.Visible.Length!=47 ||
           candidate.Source.Stones is null || candidate.Source.Stones.Length!=47 ||
           candidate.DiagnosticDrop46Order is null ||
           candidate.OverwrittenQueryOrder is null ||
           candidate.PostStirOrders is null || candidate.PostStirOrders.Length!=13 ||
           candidate.BowlsAfterDrops is null || candidate.BowlsAfterDrops.Length!=7 ||
           candidate.FinalBowls is null || candidate.FinalBowls.Length!=7 ||
           candidate.BowlsAfterDrops[0]!=0 || candidate.FinalBowls[0]!=0 ||
           ReferenceEquals(candidate.FinalBowls,candidate.BowlsAfterDrops) ||
           candidate.DiagnosticDrop46Order.Length!=6 ||
           candidate.OverwrittenQueryOrder.Length!=6 ||
           ReferenceEquals(candidate.OverwrittenQueryOrder,candidate.DiagnosticDrop46Order))
            throw new MonsterValidationException("حزمة الصلصة القديمة غير مكتملة.");

        var unrank=new BowlOrderPatchWrapper();
        var expected46=unrank.OrderPatchFromValue(candidate.Source.Visible[46]).Order;
        if(!candidate.DiagnosticDrop46Order.SequenceEqual(expected46))
            throw new MonsterValidationException("الترتيب التشخيصي للقطرة الأخيرة غير صحيح.");
        if(!candidate.PostStirOrders[12].SequenceEqual(candidate.OverwrittenQueryOrder))
            throw new MonsterValidationException("لا تظهر ندبة محو ترتيب السؤال بالتحريك الأخير.");

        // أعد تشغيل المراحل التي نُفذت بالفعل، دون مرجع الاختبار.
        var bowls=new LegacyBowlFactory().InitialBowls(candidate.Source.Counts);
        var aliases=new BowlAliasPatchWrapper();
        var stir=new ShadowBowlStirPatch();
        for(var i=1;i<=46;i++)
        {
            var drop=candidate.Source.Visible[i];
            var order=unrank.OrderPatchFromValue(drop).Order;
            var map=aliases.InstallOrderAliases(order);
            var pour=aliases.PatchedPours(i,drop,candidate.Source.Stones,bowls,map);
            stir.StirOneDropViaShadow(bowls,i,drop,candidate.Source.Stones,order,pour);
        }
        if(!bowls.SequenceEqual(candidate.BowlsAfterDrops))
            throw new MonsterValidationException("أوعية القطرات الست والأربعين غير مطابقة.");

        var round=new LegacyPostStirRound();
        for(var ordinal=1;ordinal<=12;ordinal++)
        {
            var replay=round.Stir(bowls,ordinal);
            var trace=candidate.PostStirOrders[ordinal];
            if(trace is null || trace.Length!=6 ||
               !trace.SequenceEqual(replay.Order))
                throw new MonsterValidationException("تاريخ أوامر التحريك اللاحقة غير مطابق.");
        }
        if(!bowls.SequenceEqual(candidate.FinalBowls))
            throw new MonsterValidationException("الأوعية النهائية لا تطابق التحريك اللاحق.");
        if(candidate.FinalBowls.Skip(1).Any(x=>x<1))
            throw new MonsterValidationException("وعاء نهائي خارج الحفظ.");
    }

    // يُفحص الالتقاط المحمي من موضعه في الحلقة قبل تثبيت أي حالة.
    public void ValidateProtectedDrop46Sauce(
        MonsterContext context, ProtectedDrop46SauceCandidate candidate)
    {
        if (context.PatchedOrderAt46Latch is not null ||
            context.PatchedSauceFinalBowls is not null ||
            context.PatchedSauceBowlsAfterDrops is not null ||
            context.PatchedPostStirOrders is not null ||
            context.LegacySauceFinalBowls is not null ||
            context.LegacyOverwrittenQueryOrder is not null ||
            context.PatchedVisibleDrops is not null)
            throw new MonsterValidationException("سياق الصلصة المحمية مشغول مسبقاً.");

        if (candidate is null || candidate.Historical is null ||
            candidate.Patched is null ||
            candidate.Patched.OrderAt46Latch is null ||
            candidate.Patched.OrderAt46Latch.Length != 6 ||
            candidate.Patched.BowlsAfterDrops is null ||
            candidate.Patched.BowlsAfterDrops.Length != 7 ||
            candidate.Patched.FinalBowls is null ||
            candidate.Patched.FinalBowls.Length != 7 ||
            candidate.Patched.PostStirOrders is null ||
            candidate.Patched.PostStirOrders.Length != 13 ||
            candidate.Patched.BowlsAfterDrops[0] != BigInteger.Zero ||
            candidate.Patched.FinalBowls[0] != BigInteger.Zero ||
            !candidate.Patched.OrderAt46Latch.OrderBy(x => x)
                .SequenceEqual(new[]{1,2,3,4,5,6}) ||
            ReferenceEquals(candidate.Patched.OrderAt46Latch,
                candidate.Historical.DiagnosticDrop46Order) ||
            ReferenceEquals(candidate.Patched.OrderAt46Latch,
                candidate.Historical.OverwrittenQueryOrder) ||
            ReferenceEquals(candidate.Patched.FinalBowls,
                candidate.Historical.FinalBowls) ||
            ReferenceEquals(candidate.Patched.BowlsAfterDrops,
                candidate.Historical.BowlsAfterDrops) ||
            ReferenceEquals(candidate.Patched.FinalBowls,
                candidate.Patched.BowlsAfterDrops))
            throw new MonsterValidationException("المرشح المحمي لا يملك صوراً منفصلةً تامة.");

        // شاهد الالتقاط لا يُستخرج من ترتيب الجولة الثانية عشرة.
        var expectedDrop46 = new BowlOrderPatchWrapper()
            .OrderPatchFromValue(candidate.Historical.Source.Visible[46]).Order;
        if (!candidate.Patched.OrderAt46Latch.SequenceEqual(expectedDrop46) ||
            !candidate.Patched.OrderAt46Latch.SequenceEqual(
                candidate.Historical.DiagnosticDrop46Order))
            throw new MonsterValidationException("الالتقاط لا يساوي ترتيب القطرة 46.");

        var replay = new Drop46OrderLatchWrapper().Run(candidate.Historical.Source);
        if (!candidate.Patched.BowlsAfterDrops.SequenceEqual(replay.BowlsAfterDrops) ||
            !candidate.Patched.FinalBowls.SequenceEqual(replay.FinalBowls) ||
            !candidate.Patched.FinalBowls.SequenceEqual(candidate.Historical.FinalBowls) ||
            !candidate.Patched.BowlsAfterDrops.SequenceEqual(candidate.Historical.BowlsAfterDrops) ||
            !candidate.Patched.OrderAt46Latch.SequenceEqual(replay.OrderAt46Latch))
            throw new MonsterValidationException("الصلصة المصححة لا تطابق إعادة الحساب.");

        for(var stir=1;stir<=12;stir++)
        {
            var trace=candidate.Patched.PostStirOrders[stir];
            if(trace is null || trace.Length != 6 ||
               !trace.SequenceEqual(replay.PostStirOrders[stir]) ||
               !trace.SequenceEqual(candidate.Historical.PostStirOrders[stir]) ||
               ReferenceEquals(trace,candidate.Patched.OrderAt46Latch) ||
               ReferenceEquals(trace,candidate.Historical.PostStirOrders[stir]))
                throw new MonsterValidationException("ترتيب تحريك لاحق عُدّل أو يشارك ذاكرة الالتقاط.");
        }
        if(candidate.Patched.FinalBowls.Skip(1).Any(x=>x<1))
            throw new MonsterValidationException("وعاء نهائي غير محفوظ.");
    }

    // يُصان خلل الهوية الثابتة حتى يأتي غلاف الرقعة الثانية عشرة في الطور 25.
    public void ValidateLegacyFixedNextBowl(
        MonsterContext context, LegacyFixedNextBowlCandidate candidate)
    {
        if (context.LegacyFixedNextBowlResult.HasValue ||
            context.PatchedSauceFinalBowls is not null ||
            context.PatchedOrderAt46Latch is not null ||
            context.LegacySauceFinalBowls is not null ||
            context.PatchedVisibleDrops is not null ||
            context.LegacyQueriedBowlId is not int requested ||
            requested is < 1 or > 6 ||
            candidate is null || candidate.Sauce is null ||
            candidate.QueriedBowlId != requested ||
            candidate.LegacyNextBowlId != (requested == 6 ? 1 : requested + 1) ||
            candidate.Sauce.Patched.OrderAt46Latch is not {Length:6} ||
            !candidate.Sauce.Patched.OrderAt46Latch.Contains(requested))
            throw new MonsterValidationException("اختيار الوعاء التالي التاريخي ناقص أو محوّر.");

        // لا نُصحّح هذا العيب بمقارنة الجار الصحيح: المرجع حكر على الاختبار.
    }


    // يُتحقق من المرشح قبل تثبيت الجار في الحالة. المرجع الاختباري لا يدخل الإنتاج.
    public void ValidatePatchedNextBowl(
        MonsterContext context, PatchedNextBowlCandidate candidate)
    {
        if (context.PatchedNextBowlResult.HasValue ||
            context.LegacyFixedNextBowlResult.HasValue ||
            context.PatchedOrderAt46Latch is not null ||
            context.PatchedSauceFinalBowls is not null ||
            context.PatchedVisibleDrops is not null ||
            candidate is null || candidate.Historical is null ||
            candidate.Historical.Sauce is null ||
            candidate.Historical.Sauce.Historical is null ||
            candidate.Historical.Sauce.Patched is null ||
            candidate.Historical.Sauce.Patched.OrderAt46Latch is not {Length:6} ||
            candidate.Historical.Sauce.Historical.Source is null ||
            candidate.Historical.Sauce.Historical.Source.Visible is not {Length:47} ||
            candidate.NextBowlId is < 1 or > 6)
            throw new MonsterValidationException("مرشح رقعة الجار غير صالح أو السياق مشغول.");

        // التوقيع القديم لا يُحذف ولا يُستبدل بالنتيجة المصححة.
        ValidateLegacyFixedNextBowl(context,candidate.Historical);
        var protectedOrder=candidate.Historical.Sauce.Patched.OrderAt46Latch;
        var fromDrop46 = new BowlOrderPatchWrapper().OrderPatchFromValue(
            candidate.Historical.Sauce.Historical.Source.Visible[46]).Order;
        if (!protectedOrder.SequenceEqual(fromDrop46))
            throw new MonsterValidationException("ترتيب الجار غير مشتق من القطرة الأخيرة.");

        var expected = new NextBowlOrderPatchWrapper().Patch(
            protectedOrder,candidate.Historical.QueriedBowlId);
        if (candidate.NextBowlId != expected)
            throw new MonsterValidationException("اختيار الجار المصحح لا يطابق ترتيب القطرة.");
    }


    // هذا الحارس يصون العيب التاريخي ولا يستورد الصيغة النمطية من الاختبارات.
    public void ValidateLegacyUnsealedBowlQuestion(
        MonsterContext context, LegacyUnsealedBowlQuestionCandidate candidate)
    {
        if (context is null ||
            context.LegacyBowlQuestionSeal is not int seal ||
            seal is not (21 or 31) ||
            context.LegacyQueriedBowlId is not int queried ||
            queried is < 1 or > 6 ||
            context.LegacyUnsealedBowlQuestionResult is not null ||
            context.PatchedNextBowlResult.HasValue ||
            context.PatchedSauceFinalBowls is not null ||
            context.PatchedVisibleDrops is not null ||
            candidate is null || candidate.Historical is null ||
            candidate.Answer is null || candidate.Seal != seal)
            throw new MonsterValidationException("مرشح السؤال التاريخي غير صالح أو السياق مشغول.");

        ValidatePatchedNextBowl(context,candidate.Historical);
        var finalBowls=candidate.Historical.Historical.Sauce.Patched.FinalBowls;
        var correctNext=candidate.Historical.NextBowlId;
        var old = new LegacyUnsealedBowlQuestion().Ask(
            finalBowls,queried,correctNext,seal);
        if (candidate.Answer != old ||
            candidate.Answer.First < 1 ||
            candidate.Answer.DirectionStep is not (1 or -1))
            throw new MonsterValidationException("تغيّر شاهد الخطأ في سؤال الصلصة.");
    }


    // يُقارن المرشح بمسار الرقعة المحلي بعد إثبات صحة جميع الطبقات القديمة.
    // لا تُستخدم أبداً صيغة المرجع الاختباري داخل الإنتاج.
    public void ValidatePatchedBowlQuestion(
        MonsterContext context, PatchedBowlQuestionCandidate candidate)
    {
        if (context is null ||
            context.PatchedBowlQuestionResult is not null ||
            context.LegacyUnsealedBowlQuestionResult is not null ||
            context.LegacyFixedNextBowlResult.HasValue ||
            context.PatchedNextBowlResult.HasValue ||
            context.PatchedSauceFinalBowls is not null ||
            context.PatchedVisibleDrops is not null ||
            context.LegacyQueriedBowlId is not int queried || queried is < 1 or > 6 ||
            context.LegacyBowlQuestionSeal is not int seal || seal is not (21 or 31) ||
            candidate is null || candidate.Historical is null ||
            candidate.Answer is null ||
            candidate.Answer.First < 1 ||
            candidate.Answer.DirectionStep is not (1 or -1))
            throw new MonsterValidationException("مرشح رقعة السؤال مختل أو السياق مشغول.");

        // حفاظاً على العيب القديم، يُرفض تصحيح الشاهد القديم نفسه.
        ValidateLegacyUnsealedBowlQuestion(context,candidate.Historical);
        var historical=candidate.Historical;
        var sauce=historical.Historical.Historical.Sauce.Patched;
        var next=historical.Historical.NextBowlId;
        var correct=new BowlQuestionSealPatchWrapper().Patch(
            sauce.FinalBowls,queried,next,seal);
        if (candidate.Answer != correct)
            throw new MonsterValidationException("جواب الرقعة لا يطابق حاتم السؤال وترتيب الأوعية.");
    }


    // لا يحق للمدقق تعديل انزياح k+1 التاريخي، ولا يستدعي مرجع الاختبار.
    public void ValidateLegacyOneBasedAnswerStep(
        MonsterContext context, LegacyOneBasedAnswerCandidate candidate)
    {
        if (context is null ||
            context.LegacyAnswerStepIndex is not BigInteger k || k < 0 ||
            context.LegacyOneBasedAnswerAtResult.HasValue ||
            context.PatchedBowlQuestionResult is not null ||
            context.LegacyUnsealedBowlQuestionResult is not null ||
            context.PatchedSauceFinalBowls is not null ||
            context.PatchedVisibleDrops is not null ||
            candidate is null || candidate.Question is null ||
            candidate.K != k)
            throw new MonsterValidationException("مرشح الخطوة التاريخية ناقص أو السياق مستعمل.");

        ValidatePatchedBowlQuestion(context,candidate.Question);
        var expected = new LegacyOneBasedAnswerStep().At(candidate.Question.Answer,k);
        var modulus = (BigInteger.One << 127) - BigInteger.One;
        if (candidate.Value != expected ||
            candidate.Value < 1 || candidate.Value > modulus)
            throw new MonsterValidationException("تبدّلت صيغة الخطوة التاريخية دون رقعة.");
    }


    // يُفحص شاهد k+1 أولاً، ثم تُفحص نتيجة الرقعة من دون استيراد المرجع.
    public void ValidatePatchedAnswerStep(
        MonsterContext context, PatchedAnswerStepCandidate candidate)
    {
        if (context is null ||
            context.PatchedAnswerAtResult.HasValue ||
            context.LegacyOneBasedAnswerAtResult.HasValue ||
            context.PatchedBowlQuestionResult is not null ||
            context.LegacyUnsealedBowlQuestionResult is not null ||
            context.PatchedSauceFinalBowls is not null ||
            context.PatchedVisibleDrops is not null ||
            context.LegacyAnswerStepIndex is not BigInteger k || k<0 ||
            candidate is null || candidate.Historical is null)
            throw new MonsterValidationException("مرشح رقعة التيار غير صالح أو السياق مشغول.");

        ValidateLegacyOneBasedAnswerStep(context,candidate.Historical);
        var expected=new AnswerStepZeroBasedPatchWrapper().Patch(
            candidate.Historical.Question.Answer,k);
        var modulus=(BigInteger.One<<127)-BigInteger.One;
        if (candidate.Value!=expected ||
            candidate.Value<BigInteger.One || candidate.Value>modulus)
            throw new MonsterValidationException("موضع الخطوة المصحح لا يطابق تيار الإجابات.");
    }


    // حفظ عيب باقي x التاريخي دون إدخال صيغة المرجع إلى الإنتاج.
    public void ValidateLegacyUnshiftedShortRank(
        MonsterContext context, LegacyUnshiftedShortRankCandidate candidate)
    {
        if(context is null ||
           context.LegacyShortFamilySize is not BigInteger n || n<1 ||
           n>((BigInteger.One<<127)-BigInteger.One) ||
           context.LegacyAnswerStepIndex is not BigInteger k || !k.IsZero ||
           context.LegacyShortFamilyRankResult.HasValue ||
           context.PatchedAnswerAtResult.HasValue ||
           context.LegacyOneBasedAnswerAtResult.HasValue ||
           context.PatchedSauceFinalBowls is not null ||
           context.PatchedVisibleDrops is not null ||
           candidate is null || candidate.Step is null || candidate.FamilySize!=n)
            throw new MonsterValidationException("مرشح رتبة الأسرة القصيرة غير صالح.");

        ValidatePatchedAnswerStep(context,candidate.Step);
        var expected=new LegacyUnshiftedShortRank().Choose(
            candidate.Step.Historical.Question.Answer,n);
        if(candidate.Rank!=expected || candidate.Rank<1 || candidate.Rank>n)
            throw new MonsterValidationException("تغيّر عيب باقي الإجابة القديمة.");
    }


    // لا يُستورد المرجع الاختباري إلى الإنتاج؛ يُصحح الناتج القديم الموثّق فقط.
    public void ValidatePatchedShortRank(
        MonsterContext context, PatchedShortRankCandidate candidate)
    {
        if(context is null ||
           context.PatchedShortFamilyRankResult.HasValue ||
           context.LegacyShortFamilyRankResult.HasValue ||
           context.PatchedAnswerAtResult.HasValue ||
           context.LegacyOneBasedAnswerAtResult.HasValue ||
           context.PatchedSauceFinalBowls is not null ||
           context.PatchedVisibleDrops is not null ||
           context.LegacyShortFamilySize is not BigInteger n ||
           n<1 || n>((BigInteger.One<<127)-BigInteger.One) ||
           context.LegacyAnswerStepIndex is not BigInteger k || !k.IsZero ||
           candidate is null || candidate.Historical is null)
            throw new MonsterValidationException("مرشح رقعة الأسرة القصيرة مشغول أو ناقص.");

        ValidateLegacyUnshiftedShortRank(context,candidate.Historical);
        var expected=new ShortRankOffsetPatchWrapper().Patch(candidate.Historical.Rank,n);
        if(candidate.Rank!=expected || candidate.Rank<1 || candidate.Rank>n)
            throw new MonsterValidationException("نتيجة رتبة الرقعة تختلف عن تدوير الشاهد التاريخي.");
    }


    // يفحص الموزع شاهد الترتيب المعكوس الحقيقي، لا ناتج المرجع المعياري.
    public void ValidateLegacyReversedWideRank(
        MonsterContext context, LegacyReversedWideRankCandidate candidate)
    {
        if(context is null ||
           context.LegacyWideFamilySize is not BigInteger n ||
           n<=((BigInteger.One<<127)-BigInteger.One) ||
           context.LegacyAnswerStepIndex is not BigInteger k || !k.IsZero ||
           context.LegacyReversedWideRankResult.HasValue ||
           context.PatchedAnswerAtResult.HasValue ||
           context.PatchedBowlQuestionResult is not null ||
           context.PatchedSauceFinalBowls is not null ||
           context.PatchedVisibleDrops is not null ||
           candidate is null || candidate.Step is null || candidate.FamilySize!=n)
            throw new MonsterValidationException("مرشح تعبئة الأسرة الواسعة مشوّه أو السياق مستعمل.");

        ValidatePatchedAnswerStep(context,candidate.Step);
        var expected=new LegacyReversedWideDigits().Choose(
            candidate.Step.Historical.Question.Answer,n);
        if(candidate.Rank!=expected || candidate.Rank<1 || candidate.Rank>n)
            throw new MonsterValidationException("شاهد الأرقام الواسعة التاريخي قد تبدّل.");
    }


    // تدقيق جواب الرقعة مع الاحتفاظ بالشاهد القديم وبكل المرشحات السابقة.
    public void ValidatePatchedWideRank(
        MonsterContext context, PatchedWideRankCandidate candidate)
    {
        if(context is null ||
           context.LegacyWideFamilySize is not BigInteger n ||
           n<=((BigInteger.One<<127)-BigInteger.One) ||
           context.LegacyAnswerStepIndex is not BigInteger k || !k.IsZero ||
           context.PatchedWideRankResult.HasValue ||
           context.LegacyReversedWideRankResult.HasValue ||
           context.PatchedAnswerAtResult.HasValue ||
           context.LegacyOneBasedAnswerAtResult.HasValue ||
           context.PatchedSauceFinalBowls is not null ||
           context.PatchedVisibleDrops is not null ||
           candidate is null || candidate.Historical is null)
            throw new MonsterValidationException("رقعة أوزان الأرقام مفقودة أو السياق مستعمل.");

        ValidateLegacyReversedWideRank(context,candidate.Historical);
        var expected=new WideDigitOrderPatchWrapper().Patch(
            candidate.Historical.Step.Historical.Question.Answer,n);
        if(candidate.Rank!=expected || candidate.Rank<1 || candidate.Rank>n)
            throw new MonsterValidationException("تلف رتبة الأرقام الواسعة المصححة.");
    }


    // يُثبت شاهد رفض المساواة تاريخياً بعد جميع مدققات الرقع السابقة.
    public void ValidateLegacyInclusiveWideLimit(
        MonsterContext context, LegacyInclusiveWideLimitCandidate candidate)
    {
        if(context is null ||
           context.LegacyWideFamilySize is not BigInteger n ||
           n<=((BigInteger.One<<127)-BigInteger.One) ||
           context.LegacyAnswerStepIndex is not BigInteger k || !k.IsZero ||
           context.LegacyInclusiveWideLimitRankResult.HasValue ||
           context.PatchedWideRankResult.HasValue ||
           context.LegacyReversedWideRankResult.HasValue ||
           context.PatchedAnswerAtResult.HasValue ||
           context.PatchedSauceFinalBowls is not null ||
           context.PatchedVisibleDrops is not null ||
           candidate is null || candidate.Previous is null)
            throw new MonsterValidationException("الشاهد السابع عشر ناقص أو السياق مُستخدم.");

        ValidatePatchedWideRank(context,candidate.Previous);
        var expected=new LegacyInclusiveWideLimit().Choose(
            candidate.Previous.Historical.Step.Historical.Question.Answer,n);
        if(candidate.Rank!=expected || candidate.Rank<1 || candidate.Rank>n)
            throw new MonsterValidationException("نتيجة رفض الحدّ القديم مزوّرة.");
    }


    // شاهد المساواة الخاطئ يُفحص أولاً ثم تُفحص المرتبة الجديدة الصحيحة.
    public void ValidatePatchedInclusiveWideLimit(
        MonsterContext context,PatchedInclusiveWideLimitCandidate candidate)
    {
        if(context is null ||
           context.LegacyWideFamilySize is not BigInteger n ||
           n<=((BigInteger.One<<127)-BigInteger.One) ||
           context.LegacyAnswerStepIndex is not BigInteger k || !k.IsZero ||
           context.PatchedInclusiveWideLimitRankResult.HasValue ||
           context.LegacyInclusiveWideLimitRankResult.HasValue ||
           context.PatchedWideRankResult.HasValue ||
           context.PatchedSauceFinalBowls is not null ||
           context.PatchedVisibleDrops is not null ||
           candidate is null || candidate.Historical is null)
            throw new MonsterValidationException("مرشح رقعة المساواة غير صالح أو الحالة مستعملة.");
        ValidateLegacyInclusiveWideLimit(context,candidate.Historical);
        var expected=new InclusiveWideLimitPatchWrapper().Patch(candidate.Historical,n);
        if(candidate.Rank!=expected || candidate.Rank<1 || candidate.Rank>n)
            throw new MonsterValidationException("رُفضت رتبة تصحيح الحدّ المشوّهة.");
    }


    // إثبات انحراف اتجاه الرفض بعد فحص الرقعة الصحيحة السابعة عشرة.
    public void ValidateLegacyWideRejectionDirection(
        MonsterContext context,LegacyWideRejectionDirectionCandidate candidate)
    {
        if(context is null ||
           context.LegacyWideFamilySize is not BigInteger n ||
           n<=((BigInteger.One<<127)-BigInteger.One) ||
           context.LegacyAnswerStepIndex is not BigInteger k || !k.IsZero ||
           context.LegacyRejectionDirectionRankResult.HasValue ||
           context.PatchedInclusiveWideLimitRankResult.HasValue ||
           context.LegacyInclusiveWideLimitRankResult.HasValue ||
           context.PatchedWideRankResult.HasValue ||
           context.PatchedSauceFinalBowls is not null ||
           context.PatchedVisibleDrops is not null ||
           candidate is null || candidate.Previous is null)
            throw new MonsterValidationException("مرشح اتجاه الرفض القديم أو السياق غير صالح.");

        ValidatePatchedInclusiveWideLimit(context,candidate.Previous);
        var stream=candidate.Previous.Historical.Previous.Historical.Step.Historical.Question.Answer;
        var expected=new LegacyWideRejectionDirection().Choose(stream,n);
        if(candidate.Rank!=expected || candidate.Rank<1 || candidate.Rank>n)
            throw new MonsterValidationException("زُوّر شاهد اتجاه الرفض القديم.");
    }

    // يُدقّق التصحيح بعد فحص جميع الشواهد القديمة، ولا يكتب حالةً.
    public void ValidatePatchedRejectionDirection(
        MonsterContext context,PatchedRejectionDirectionCandidate candidate)
    {
        if(context is null ||
           context.LegacyWideFamilySize is not BigInteger n || n<=((BigInteger.One<<127)-BigInteger.One) ||
           context.LegacyAnswerStepIndex is not BigInteger k || !k.IsZero ||
           context.PatchedRejectionDirectionRankResult.HasValue ||
           context.LegacyRejectionDirectionRankResult.HasValue ||
           context.PatchedInclusiveWideLimitRankResult.HasValue ||
           context.PatchedSauceFinalBowls is not null ||
           context.PatchedVisibleDrops is not null ||
           candidate is null || candidate.Historical is null)
            throw new MonsterValidationException("مرشح الرقعة الثامنة عشرة غير صالح.");
        ValidateLegacyWideRejectionDirection(context,candidate.Historical);
        var actual=new RejectionDirectionPatchWrapper().Patch(candidate.Historical,n);
        if(candidate.Rank!=actual || candidate.Rank<1 || candidate.Rank>n)
            throw new MonsterValidationException("نتيجة اتجاه الرفض المصححة مزوّرة.");
    }


    // المدقق التاسع عشر يبقي المخرج القديم خاطئاً ويثبت علاقته بالمرتبة الصحيحة.
    public void ValidateLegacyDoubleOffsetWideRank(
        MonsterContext context,LegacyDoubleOffsetWideRankCandidate candidate)
    {
        if(context is null ||
           context.LegacyWideFamilySize is not BigInteger n ||
           n<=((BigInteger.One<<127)-BigInteger.One) ||
           context.LegacyAnswerStepIndex is not BigInteger k || !k.IsZero ||
           context.LegacyDoubleOffsetWideRankResult.HasValue ||
           context.PatchedRejectionDirectionRankResult.HasValue ||
           context.PatchedSauceFinalBowls is not null ||
           context.PatchedVisibleDrops is not null ||
           candidate is null || candidate.Previous is null)
            throw new MonsterValidationException("مرشح إخراج المرتبة التاسعة عشرة غير صالح.");
        ValidatePatchedRejectionDirection(context,candidate.Previous);
        var expected=new LegacyDoubleOffsetWideRank().Shift(candidate.Previous,n);
        if(candidate.Rank!=expected || candidate.Rank<1 || candidate.Rank>n)
            throw new MonsterValidationException("تغيّر شاهد الخرج القديم أو رتبته.");
    }


    // بعد تدقيق مسار +1 القديم، يدقّق الإرجاع إلى الرتبة المعتمدة سابقاً.
    public void ValidatePatchedDoubleOffsetWideRank(
        MonsterContext context,PatchedDoubleOffsetWideRankCandidate candidate)
    {
        if(context is null ||
           context.LegacyWideFamilySize is not BigInteger n ||
           n<=((BigInteger.One<<127)-BigInteger.One) ||
           context.LegacyAnswerStepIndex is not BigInteger k || !k.IsZero ||
           context.PatchedDoubleOffsetWideRankResult.HasValue ||
           context.LegacyDoubleOffsetWideRankResult.HasValue ||
           context.PatchedRejectionDirectionRankResult.HasValue ||
           context.PatchedSauceFinalBowls is not null ||
           context.PatchedVisibleDrops is not null ||
           candidate is null || candidate.Historical is null)
            throw new MonsterValidationException("مرشح تصحيح الإزاحة الثانية غير صالح.");

        ValidateLegacyDoubleOffsetWideRank(context,candidate.Historical);
        var expected=new DoubleOffsetWideRankPatchWrapper().Patch(candidate.Historical,n);
        if(candidate.Rank!=expected || candidate.Rank<1 || candidate.Rank>n)
            throw new MonsterValidationException("تزييف رتبة الخرج المصحّحة.");
    }

    // لا يُستخدم المرجع الاختباري في فحص المدى والملكية وإضافة الحارس.
    public void ValidateVisibleDropPatch(MonsterContext context, VisibleDropsPatchCandidate candidate)
    {
        if (context.PatchedVisibleDrops is not null ||
            context.LegacyGrindResult.HasValue ||
            context.PatchedCountsResult is not null)
            throw new MonsterValidationException("سياق بناء القطرات ليس خالياً قبل الالتزام.");
        if (candidate is null || candidate.Counts is null ||
            candidate.Stones is null || candidate.Stones.Length != 47 ||
            candidate.ReversedHiddenStorage is null || candidate.ReversedHiddenStorage.Length != 8 ||
            candidate.HiddenAccessor is null ||
            !candidate.HiddenAccessor.UsesUnchangedLegacyStorage(candidate.ReversedHiddenStorage) ||
            candidate.Visible is null || candidate.Visible.Length != 47 ||
            candidate.Visible[0] != BigInteger.Zero ||
            candidate.ReversedHiddenStorage[0] != BigInteger.Zero)
            throw new MonsterValidationException("حالة القطرات أو المخزن التاريخي غير مكتملة.");

        var modulus = (BigInteger.One << 127) - BigInteger.One;
        for (var i = 1; i <= 46; i++)
        {
            if (candidate.Visible[i] < BigInteger.One || candidate.Visible[i] > modulus)
                throw new MonsterValidationException("قطرة ظاهرة خارج مجال الحفظ.");
            if (candidate.Stones[i] is not BigInteger[] row || row.Length != 6)
                throw new MonsterValidationException("أحجار قطرة ظاهرة غير مكتملة.");
        }

        for (var grind = 1; grind <= 11; grind++)
        {
            var patched = SentinelVisibleGrindPatch.GrindRowWithSentinel(grind);
            var physical = LegacyVisibleGrindTable.LegacyGrindRow(grind - 1);
            if (patched != physical)
                throw new MonsterValidationException("أُزيل صفّ الحارس أو غُيّر ترتيب الطحْن.");
        }
    }

    // هذا الحارس لا يعيد إنتاج المرجع المعياري: يفحص الملكية والمدى وبنية الصفوف فقط.
    public void ValidatePatchedStones(MonsterContext context, BigInteger[][] candidate)
    {
        if (context.LegacyStoneRows is not BigInteger[][] historical)
            throw new MonsterValidationException("يجب تشغيل معالج الأحجار القديم قبل الرقعة.");
        if (context.PatchedStoneRows is not null)
            throw new MonsterValidationException("لا يُسمح بتثبيت صفوف الأحجار المصححة مرتين.");
        if (candidate is null || candidate.Length != 47 || historical.Length != 47)
            throw new MonsterValidationException("جدول الأحجار لا يحوي الصفوف الستة والأربعين.");
        if (candidate[0] is not null)
            throw new MonsterValidationException("فهرس الصفر محجوز خارج جدول الأحجار.");

        var initial = LegacyStones.InitialStones();
        if (candidate[1] is null || !candidate[1].SequenceEqual(initial) ||
            historical[1] is null || !historical[1].SequenceEqual(initial))
            throw new MonsterValidationException("بذرة الأحجار غير صحيحة.");
        var modulus = (BigInteger.One << 127) - BigInteger.One;
        for (var row = 1; row <= 46; row++)
        {
            if (candidate[row] is not BigInteger[] current || current.Length != 6 ||
                historical[row] is not BigInteger[] previous || previous.Length != 6)
                throw new MonsterValidationException("صف أحجار ناقص أو غير صالح.");
            if (ReferenceEquals(current, previous) ||
                (row > 1 && ReferenceEquals(current, candidate[row - 1])))
                throw new MonsterValidationException("تسرّب ملكية مصفوفة الأحجار بين الصفوف.");
            if (current[0] != BigInteger.Zero)
                throw new MonsterValidationException("يجب أن يظل فهرس الصفر بلا حجر.");
            for (var kind = 1; kind <= 5; kind++)
                if (current[kind] < BigInteger.One || current[kind] > modulus)
                    throw new MonsterValidationException("قيمة حجر مصحح خارج المجال.");
        }
    }
}

public sealed class MonsterMetricsManager
{
    public void Bump(MonsterContext context, string key)
    {
        context.Metrics.TryGetValue(key, out var value);
        context.Metrics[key] = value + 1;
    }
}

public sealed class MonsterDispatcher
{
    private readonly MonsterValidationManager _validation;
    private readonly MonsterMetricsManager _metrics;
    private readonly LegacySavePhaseHandler _legacySave;
    private readonly SavePatchWrapper _savePatch;
    private readonly LegacyDayTagPhaseHandler _legacyDayTag;
    private readonly DayTagPatchWrapper _dayTagPatch;
    private readonly LegacyDistancePhaseHandler _legacyDistance;
    private readonly PatchedCounts _patchedCounts;
    private readonly LegacyStonesPhaseHandler _legacyStones;
    private readonly StonePatchWrapper _stonePatch;
    private readonly LegacyHiddenDropsPhaseHandler _legacyHiddenDrops;
    private readonly LegacyPriorPhaseHandler _legacyPrior;
    private readonly PriorAccessWrapper _priorAccess;
    private readonly LegacyVisibleGrindPhaseHandler _legacyGrind;
    private readonly VisibleDropPatchPhaseHandler _visibleDropPatch;
    private readonly LegacyBowlPermutationPhaseHandler _legacyBowlPermutation;
    private readonly BowlOrderPatchWrapper _bowlOrderPatch;
    private readonly LegacyPoursPhaseHandler _legacyPours;
    private readonly BowlAliasPatchPhaseHandler _aliasPatch;
    private readonly LegacyInPlaceBowlStirPhaseHandler _legacyInPlaceStir;
    private readonly ShadowBowlStirPhaseHandler _shadowStir;
    private readonly LegacyOverwrittenDrop46Sauce _legacyOverwrittenSauce;
    private readonly ProtectedDrop46SaucePhaseHandler _protectedDrop46Sauce;
    private readonly LegacyFixedNextBowlPhaseHandler _legacyFixedNextBowl;
    private readonly PatchedNextBowlPhaseHandler _patchedNextBowl;
    private readonly LegacyUnsealedBowlQuestionPhaseHandler _legacyUnsealedQuestion;
    private readonly PatchedBowlQuestionPhaseHandler _patchedBowlQuestion;
    private readonly LegacyOneBasedAnswerPhaseHandler _legacyOneBasedAnswer;
    private readonly PatchedAnswerStepPhaseHandler _patchedAnswerStep;
    private readonly LegacyUnshiftedShortRankPhaseHandler _legacyShortRank;
    private readonly PatchedShortRankPhaseHandler _patchedShortRank;
    private readonly LegacyReversedWideRankPhaseHandler _legacyWideRank;
    private readonly PatchedWideRankPhaseHandler _patchedWideRank;
    private readonly LegacyInclusiveWideLimitPhaseHandler _inclusiveWideLimit;
    private readonly PatchedInclusiveWideLimitPhaseHandler _patchedInclusiveWideLimit;
    private readonly LegacyWideRejectionDirectionPhaseHandler _legacyRejectionDirection;
    private readonly PatchedRejectionDirectionPhaseHandler _patchedRejectionDirection;
    private readonly LegacyDoubleOffsetWideRankPhaseHandler _doubleOffsetWideRank;
    private readonly PatchedDoubleOffsetWideRankPhaseHandler _patchedDoubleOffsetWideRank;

    public MonsterDispatcher(MonsterValidationManager validation, MonsterMetricsManager metrics)
    {
        _validation = validation;
        _metrics = metrics;
        _legacySave = new LegacySavePhaseHandler();
        _savePatch = new SavePatchWrapper();
        _legacyDayTag = new LegacyDayTagPhaseHandler();
        _dayTagPatch = new DayTagPatchWrapper();
        _legacyDistance = new LegacyDistancePhaseHandler();
        _patchedCounts = new PatchedCounts();
        _legacyStones = new LegacyStonesPhaseHandler();
        _stonePatch = new StonePatchWrapper();
        _legacyHiddenDrops = new LegacyHiddenDropsPhaseHandler();
        _legacyPrior = new LegacyPriorPhaseHandler();
        _priorAccess = new PriorAccessWrapper();
        _legacyGrind = new LegacyVisibleGrindPhaseHandler();
        _visibleDropPatch = new VisibleDropPatchPhaseHandler();
        _legacyBowlPermutation = new LegacyBowlPermutationPhaseHandler();
        _bowlOrderPatch = new BowlOrderPatchWrapper();
        _legacyPours = new LegacyPoursPhaseHandler();
        _aliasPatch = new BowlAliasPatchPhaseHandler();
        _legacyInPlaceStir = new LegacyInPlaceBowlStirPhaseHandler();
        _shadowStir = new ShadowBowlStirPhaseHandler();
        _legacyOverwrittenSauce = new LegacyOverwrittenDrop46Sauce();
        _protectedDrop46Sauce = new ProtectedDrop46SaucePhaseHandler();
        _legacyFixedNextBowl = new LegacyFixedNextBowlPhaseHandler();
        _patchedNextBowl = new PatchedNextBowlPhaseHandler();
        _legacyUnsealedQuestion = new LegacyUnsealedBowlQuestionPhaseHandler();
        _patchedBowlQuestion = new PatchedBowlQuestionPhaseHandler();
        _legacyOneBasedAnswer = new LegacyOneBasedAnswerPhaseHandler();
        _patchedAnswerStep = new PatchedAnswerStepPhaseHandler();
        _legacyShortRank = new LegacyUnshiftedShortRankPhaseHandler();
        _patchedShortRank = new PatchedShortRankPhaseHandler();
        _legacyWideRank = new LegacyReversedWideRankPhaseHandler();
        _patchedWideRank = new PatchedWideRankPhaseHandler();
        _inclusiveWideLimit = new LegacyInclusiveWideLimitPhaseHandler();
        _patchedInclusiveWideLimit = new PatchedInclusiveWideLimitPhaseHandler();
        _legacyRejectionDirection = new LegacyWideRejectionDirectionPhaseHandler();
        _patchedRejectionDirection = new PatchedRejectionDirectionPhaseHandler();
        _doubleOffsetWideRank = new LegacyDoubleOffsetWideRankPhaseHandler();
        _patchedDoubleOffsetWideRank = new PatchedDoubleOffsetWideRankPhaseHandler();
    }

    public void DispatchBootstrap(MonsterContext context)
    {
        context.Phase = "BOOTSTRAP_VALIDATION";
        context.BranchTrace.Add("BOOTSTRAP_VALIDATION");
        _validation.ValidateBootstrapContext(context);
        _metrics.Bump(context, "bootstrap.dispatch");
        context.Status = "BOOTSTRAP_READY";
        context.Phase = "BOOTSTRAP_READY";
    }

    public void DispatchLegacySave(MonsterContext context)
    {
        if (!string.Equals(context.Status, "BOOTSTRAP_READY", StringComparison.Ordinal))
            throw new MonsterValidationException("لم يكتمل تأسيس السياق قبل الحفظ القديم.");

        context.Phase = "LEGACY_SAVE";
        context.BranchTrace.Add("LEGACY_SAVE");
        _legacySave.Handle(context);
        _metrics.Bump(context, "legacy.save.dispatch");
        context.Status = "LEGACY_SAVE_COMPLETE";
        context.Phase = "LEGACY_SAVE_COMPLETE";
    }

    public void DispatchLegacyDayTag(MonsterContext context)
    {
        if (!string.Equals(context.Status, "BOOTSTRAP_READY", StringComparison.Ordinal))
            throw new MonsterValidationException("يتطلب عدّ اليوم القديم سياقاً جديداً أتمّ التأسيس.");
        if (context.LegacyDayInput is null)
            throw new MonsterValidationException("يجب تقديم اليوم قبل إرسال معالج العدّ القديم.");
        if (context.LegacyDayTagResult.HasValue)
            throw new MonsterValidationException("سُجِّل عدّ قديم في هذا السياق من قبل.");

        context.Phase = "LEGACY_DAY_TAG";
        context.BranchTrace.Add("LEGACY_DAY_TAG");
        _legacyDayTag.Handle(context);
        _metrics.Bump(context, "legacy.day.tag.dispatch");
        context.Status = "LEGACY_DAY_TAG_COMPLETE";
        context.Phase = "LEGACY_DAY_TAG_COMPLETE";
    }

    public void DispatchDayTagPatched(MonsterContext context)
    {
        if (!string.Equals(context.Status, "BOOTSTRAP_READY", StringComparison.Ordinal))
            throw new MonsterValidationException("تتطلب الرقعة الثانية سياقاً جديداً أتمّ تأسيسه.");
        if (context.LegacyDayInput is not BigInteger day)
            throw new MonsterValidationException("لم يُقدَّم اليوم إلى الرقعة الثانية.");

        // يستمر استدعاء المعالج القديم؛ وتبقى قيمته الخاطئة مرئية في السياق.
        DispatchLegacyDayTag(context);

        // لا تلتزم الرقعة بنتيجة حتى تفحصها طبقة التحقق بعد الحساب.
        context.Phase = "DAY_TAG_PATCH_VALIDATION";
        var pending = _dayTagPatch.Patch(day);
        _validation.ValidateDayTagPatchResult(context, pending);
        context.PatchedDayTagResult = pending;

        context.BranchTrace.Add("DAY_TAG_PATCH");
        _metrics.Bump(context, "day.tag.patch.dispatch");
        context.Status = "DAY_TAG_PATCH_COMPLETE";
        context.Phase = "DAY_TAG_PATCH_COMPLETE";
    }

    public void DispatchLegacyDistance(MonsterContext context)
    {
        if (!string.Equals(context.Status, "BOOTSTRAP_READY", StringComparison.Ordinal))
            throw new MonsterValidationException("يتطلب حساب المسافة القديم سياقاً مستعداً جديداً.");
        if (context.LegacyDistanceResult.HasValue)
            throw new MonsterValidationException("لا يجوز حساب مسافة تاريخية ثانية في السياق نفسه.");

        context.Phase = "LEGACY_DISTANCE";
        context.BranchTrace.Add("LEGACY_DISTANCE");
        _legacyDistance.Handle(context);
        _metrics.Bump(context, "legacy.distance.dispatch");
        context.Status = "LEGACY_DISTANCE_COMPLETE";
        context.Phase = "LEGACY_DISTANCE_COMPLETE";
    }

    public void DispatchPatchedCounts(MonsterContext context)
    {
        if (!string.Equals(context.Status, "BOOTSTRAP_READY", StringComparison.Ordinal))
            throw new MonsterValidationException("تتطلب رقعة المسافة سياقاً جاهزاً جديداً.");
        if (context.LegacyDistanceResult.HasValue || context.PatchedCountsResult is not null)
            throw new MonsterValidationException("لا يجوز إعادة ربط مسافة قديمة بسياق مصحح.");

        // تلتزم الندبة القديمة أولاً، ولا تُمحى إذا اختار الغلاف القيمة الزمنية.
        DispatchLegacyDistance(context);

        context.Phase = "COUNTS_PATCH_VALIDATION";
        var pending = _patchedCounts.Calculate(context.CalculationDay, context.TargetDay);
        _validation.ValidatePatchedCounts(context, pending);
        context.PatchedCountsResult = pending;

        context.BranchTrace.Add("COUNTS_PATCH");
        _metrics.Bump(context, "counts.patch.dispatch");
        context.Status = "COUNTS_PATCH_COMPLETE";
        context.Phase = "COUNTS_PATCH_COMPLETE";
    }

    public void DispatchLegacyStones(MonsterContext context)
    {
        if (!string.Equals(context.Status, "BOOTSTRAP_READY", StringComparison.Ordinal))
            throw new MonsterValidationException("يتطلب التحول القديم للأحجار سياقاً جديداً أُنجز تأسيسه.");
        if (context.LegacyStoneRows is not null)
            throw new MonsterValidationException("لا يجوز إعادة بناء الأحجار في هذا السياق.");

        context.Phase = "LEGACY_STONES_MUTATION";
        context.BranchTrace.Add("LEGACY_STONES_MUTATION");
        _legacyStones.Handle(context);
        _metrics.Bump(context, "legacy.stones.mutation.dispatch");
        context.Status = "LEGACY_STONES_COMPLETE";
        context.Phase = "LEGACY_STONES_COMPLETE";
    }

    public void DispatchPatchedStones(MonsterContext context)
    {
        if (!string.Equals(context.Status, "BOOTSTRAP_READY", StringComparison.Ordinal))
            throw new MonsterValidationException("تتطلب الرقعة الرابعة سياقاً مستعداً جديداً.");
        if (context.LegacyStoneRows is not null || context.PatchedStoneRows is not null)
            throw new MonsterValidationException("لا يجوز استعارة صفوف أحجار ملتزم بها من قبل.");

        // يبقى مسار الخطأ التاريخي دليلاً منفصلاً في هذا السياق.
        DispatchLegacyStones(context);

        context.Phase = "STONE_PATCH_VALIDATION";
        var pending = _stonePatch.BuildPatchedRows();
        _validation.ValidatePatchedStones(context, pending);
        context.PatchedStoneRows = pending;

        context.BranchTrace.Add("STONE_PATCH");
        _metrics.Bump(context, "stone.patch.dispatch");
        context.Status = "STONE_PATCH_COMPLETE";
        context.Phase = "STONE_PATCH_COMPLETE";
    }

    public void DispatchLegacyHiddenDrops(MonsterContext context)
    {
        if (!string.Equals(context.Status, "BOOTSTRAP_READY", StringComparison.Ordinal))
            throw new MonsterValidationException("يتطلب تخزين القطرات المقلوب سياقاً جديداً جاهزاً.");
        if (context.LegacyHiddenReversed is not null)
            throw new MonsterValidationException("لا يجوز بناء القطرات التاريخية مرتين.");

        context.Phase = "LEGACY_HIDDEN_REVERSED";
        context.BranchTrace.Add("LEGACY_HIDDEN_REVERSED");
        _legacyHiddenDrops.Handle(context);
        _metrics.Bump(context, "legacy.hidden.reversed.dispatch");
        context.Status = "LEGACY_HIDDEN_REVERSED_COMPLETE";
        context.Phase = "LEGACY_HIDDEN_REVERSED_COMPLETE";
    }

    public void DispatchPatchedHiddenAccess(MonsterContext context)
    {
        if (!string.Equals(context.Status, "BOOTSTRAP_READY", StringComparison.Ordinal))
            throw new MonsterValidationException("تتطلب رقعة الفهرس الخامسة سياقاً جاهزاً جديداً.");
        if (context.LegacyHiddenReversed is not null || context.PatchedHiddenAccess is not null)
            throw new MonsterValidationException("لا يجوز استعارة مخزن قطرات من سياق التزم بالفعل.");

        // يُشغَّل المسار القديم كاملاً أولاً، لا يُعاد ترتيب نتائجه.
        DispatchLegacyHiddenDrops(context);

        context.Phase = "HIDDEN_INDEX_PATCH_VALIDATION";
        var pending = new HiddenNearnessWrapper(context.LegacyHiddenReversed!);
        _validation.ValidateHiddenNearnessWrapper(context, pending);
        context.PatchedHiddenAccess = pending;

        context.BranchTrace.Add("HIDDEN_INDEX_PATCH");
        _metrics.Bump(context, "hidden.index.patch.dispatch");
        context.Status = "HIDDEN_INDEX_PATCH_COMPLETE";
        context.Phase = "HIDDEN_INDEX_PATCH_COMPLETE";
    }

    public void DispatchLegacyPrior(MonsterContext context)
    {
        if (!string.Equals(context.Status, "BOOTSTRAP_READY", StringComparison.Ordinal))
            throw new MonsterValidationException("لا يقرأ المسار القديم القطرات قبل تأسيس السياق.");
        if (context.LegacyPriorResult.HasValue)
            throw new MonsterValidationException("لا يجوز تثبيت قراءة تاريخية ثانية.");
        if (context.LegacyPriorDropStore is not BigInteger[] store ||
            store.Length != 47 || store[0] != BigInteger.Zero)
            throw new MonsterValidationException("مخزن القطرات الظاهرة ليس في البنية التاريخية المطلوبة.");
        if (context.LegacyPriorVisibleIndex is not int row || row is < 1 or > 46 ||
            context.LegacyPriorBack is not int back || back is not (1 or 3 or 7))
            throw new MonsterValidationException("رقم القطرة أو مقدار الرجوع خارج العقد القديم.");

        // القراءة التاريخية نفسها مباشرة؛ سلبية الفهرس ترمي استثناء المصفوفة.
        // لا نغيّر سجلات الحالة ولا نلتزم بقيمة إن تعثرت تلك القراءة.
        var result = _legacyPrior.Handle(context);
        context.LegacyPriorResult = result;
        context.BranchTrace.Add("LEGACY_PRIOR");
        _metrics.Bump(context, "legacy.prior.dispatch");
        context.Status = "LEGACY_PRIOR_COMPLETE";
        context.Phase = "LEGACY_PRIOR_COMPLETE";
    }

    public void DispatchPatchedPrior(MonsterContext context)
    {
        if (!string.Equals(context.Status, "BOOTSTRAP_READY", StringComparison.Ordinal))
            throw new MonsterValidationException("تتطلب الرقعة السادسة سياقاً جديداً مؤسساً.");
        if (context.PatchedPriorResult.HasValue || context.LegacyPriorResult.HasValue ||
            context.LegacyHiddenReversed is not null || context.PatchedHiddenAccess is not null)
            throw new MonsterValidationException("لا يجوز استعارة نتيجة سابقة من استدعاء آخر.");

        if (context.LegacyPriorDropStore is not BigInteger[] store ||
            context.LegacyPriorVisibleIndex is not int i ||
            context.LegacyPriorBack is not int back ||
            store.Length != 47 || store[0] != BigInteger.Zero ||
            i is < 1 or > 46 || back is not (1 or 3 or 7))
            throw new MonsterValidationException("مدخلات الرقعة السادسة غير سليمة.");

        var slot = i - back;
        if (slot >= 1)
        {
            // حفظ شاهد مسار القراءة القديم أولاً؛ يستدعي الغلاف القديم فعلياً أيضاً.
            DispatchLegacyPrior(context);
        }
        else
        {
            // يتعذر على القديم أن يقرأ الخفية؛ تُنشأ عبر المسار التاريخي الخامس.
            DispatchLegacyHiddenDrops(context);
            var access = new HiddenNearnessWrapper(context.LegacyHiddenReversed!);
            _validation.ValidateHiddenNearnessWrapper(context, access);
            context.PatchedHiddenAccess = access;
        }

        context.Phase = "PRIOR_ACCESS_PATCH_VALIDATION";
        var pending = _priorAccess.Read(store, context.PatchedHiddenAccess, i, back);
        _validation.ValidatePatchedPrior(context, pending);
        context.PatchedPriorResult = pending;

        context.BranchTrace.Add("PRIOR_ACCESS_PATCH");
        _metrics.Bump(context, "prior.access.patch.dispatch");
        context.Status = "PRIOR_ACCESS_PATCH_COMPLETE";
        context.Phase = "PRIOR_ACCESS_PATCH_COMPLETE";
    }

    public void DispatchLegacyVisibleGrind(MonsterContext context)
    {
        if (!string.Equals(context.Status, "BOOTSTRAP_READY", StringComparison.Ordinal))
            throw new MonsterValidationException("لا يجوز بدء الطحن التاريخي قبل اكتمال التأسيس.");
        if (context.LegacyGrindOrdinal is not int ordinal || ordinal is < 1 or > 11)
            throw new MonsterValidationException("رقم الطحن التاريخي خارج المجال من واحد إلى أحد عشر.");
        if (context.LegacyGrindResult.HasValue || context.LegacyGrindDirectIndex.HasValue)
            throw new MonsterValidationException("لا تُنفّذ قراءة الطحن التاريخي مرتين في السياق.");

        // قد ترمي القراءة فهرساً خارج الحدود عند الطحن 11؛ لا تسجيل ولا التزام قبلها.
        var pending = _legacyGrind.Handle(context);
        context.LegacyGrindDirectIndex = ordinal;
        context.LegacyGrindResult = pending;
        context.BranchTrace.Add("LEGACY_VISIBLE_GRIND");
        _metrics.Bump(context, "legacy.visible.grind.dispatch");
        context.Status = "LEGACY_VISIBLE_GRIND_COMPLETE";
        context.Phase = "LEGACY_VISIBLE_GRIND_COMPLETE";
    }

    public void DispatchVisibleDropsPatched(MonsterContext context)
    {
        if (!string.Equals(context.Status, "BOOTSTRAP_READY", StringComparison.Ordinal))
            throw new MonsterValidationException("لا يُبنى تسلسل القطرات المصحح في سياقٍ غير مؤسس.");
        if (context.PatchedVisibleDrops is not null ||
            context.LegacyGrindResult.HasValue || context.LegacyGrindOrdinal.HasValue ||
            context.PatchedStoneRows is not null || context.LegacyHiddenReversed is not null ||
            context.PatchedHiddenAccess is not null || context.PatchedCountsResult is not null)
            throw new MonsterValidationException("لا يقبل مسار الطحن المصحح حالةً دلاليةً سابقة.");

        // يُنشأ الناتج الكامل في الذاكرة المحلية أولاً؛ لا كتابة جزئية في السياق.
        var pending = _visibleDropPatch.Handle(context);
        _validation.ValidateVisibleDropPatch(context, pending);

        // يُستدعى القارئ التاريخي فعلياً، وتُحفظ ندبته على نحو مستقل.
        var wrongRow = _legacyGrindRowForWitness();
        context.LegacyGrindOrdinal = 1;
        context.LegacyGrindDirectIndex = 1;
        context.LegacyGrindResult = wrongRow;

        context.PatchedCountsResult = pending.Counts;
        context.PatchedStoneRows = pending.Stones;
        context.LegacyHiddenReversed = pending.ReversedHiddenStorage;
        context.PatchedHiddenAccess = pending.HiddenAccessor;
        context.PatchedVisibleDrops = pending.Visible;

        context.BranchTrace.Add("LEGACY_VISIBLE_GRIND_WITNESS");
        context.BranchTrace.Add("VISIBLE_GRIND_SENTINEL_PATCH");
        _metrics.Bump(context, "legacy.visible.grind.witness");
        _metrics.Bump(context, "visible.grind.sentinel.patch");
        context.Status = "VISIBLE_GRIND_SENTINEL_PATCH_COMPLETE";
        context.Phase = "VISIBLE_GRIND_SENTINEL_PATCH_COMPLETE";
    }

    private LegacyGrindRow _legacyGrindRowForWitness()
        => LegacyVisibleGrindTable.LegacyGrindRow(1);

    public void DispatchLegacyBowlOrder(MonsterContext context)
    {
        if (!string.Equals(context.Status, "BOOTSTRAP_READY", StringComparison.Ordinal))
            throw new MonsterValidationException("ترتيب الأوعية التاريخي يحتاج سياقاً مؤسساً.");
        if (context.LegacyBowlOrderInput is null ||
            context.LegacyBowlOrderResult is not null ||
            context.LegacyBowlOneBasedRank.HasValue)
            throw new MonsterValidationException("قيمة القطرة مفقودة أو حُفظ ترتيب قديم من قبل.");

        // لا نغيّر الحالة أو السجلات قبل نجاح المفكك؛ الرتبة 720 ترمي استثناءً.
        var pending = _legacyBowlPermutation.Handle(context);
        var rank = LegacyBowlPermutation.WrongOneBasedRank(context.LegacyBowlOrderInput.Value);
        context.LegacyBowlOneBasedRank = rank;
        context.LegacyBowlOrderResult = pending;
        context.BranchTrace.Add("LEGACY_BOWL_PERMUTATION");
        _metrics.Bump(context, "legacy.bowl.permutation.dispatch");
        context.Status = "LEGACY_BOWL_PERMUTATION_COMPLETE";
        context.Phase = "LEGACY_BOWL_PERMUTATION_COMPLETE";
    }

    public void DispatchBowlOrderPatched(MonsterContext context)
    {
        if (!string.Equals(context.Status, "BOOTSTRAP_READY", StringComparison.Ordinal))
            throw new MonsterValidationException("تحتاج رقعة الترتيب سياقاً مؤسساً جديداً.");
        if (context.LegacyBowlOrderInput is null ||
            context.LegacyBowlOrderResult is not null ||
            context.LegacyBowlOneBasedRank.HasValue ||
            context.LegacyBowlRankOutOfRange ||
            context.PatchedBowlOrderResult is not null ||
            context.PatchedBowlOneBasedRank.HasValue ||
            context.PatchedBowlLegacyRank0.HasValue)
            throw new MonsterValidationException("ترتيب الأوعية غير معطى أو سبق إثباته.");

        // حساب كامل قبل تثبيت أي حالة: ترتيب مصحح وشاهد تاريخي منفصل.
        var pending = _bowlOrderPatch.OrderPatchFromValue(context.LegacyBowlOrderInput.Value);
        int[]? historical = null;
        var historicalFault = false;
        try
        {
            // استدعاء المعالج التاريخي نفسه مقصود، بما في ذلك خطأ الرتبة 720.
            historical = _legacyBowlPermutation.Handle(context);
        }
        catch (ArgumentOutOfRangeException)
        {
            if (pending.OneBased != 720)
                throw;
            historicalFault = true;
        }

        _validation.ValidateBowlOrderPatch(
            context, pending.OneBased, pending.LegacyRank0,
            pending.Order, historical, historicalFault);

        context.LegacyBowlOneBasedRank = pending.OneBased;
        context.LegacyBowlOrderResult = historical;
        context.LegacyBowlRankOutOfRange = historicalFault;
        context.PatchedBowlOneBasedRank = pending.OneBased;
        context.PatchedBowlLegacyRank0 = pending.LegacyRank0;
        context.PatchedBowlOrderResult = pending.Order;

        context.BranchTrace.Add(historicalFault
            ? "LEGACY_BOWL_PERMUTATION_RANGE_WITNESS"
            : "LEGACY_BOWL_PERMUTATION_WITNESS");
        context.BranchTrace.Add("BOWL_ORDER_PATCH");
        _metrics.Bump(context, historicalFault
            ? "legacy.bowl.permutation.range.witness"
            : "legacy.bowl.permutation.witness");
        _metrics.Bump(context, "bowl.order.patch.dispatch");
        context.Status = "BOWL_ORDER_PATCH_COMPLETE";
        context.Phase = "BOWL_ORDER_PATCH_COMPLETE";
    }

    public void DispatchLegacyPours(MonsterContext context)
    {
        if (!string.Equals(context.Status, "BOOTSTRAP_READY", StringComparison.Ordinal))
            throw new MonsterValidationException("لا يجوز صبّ الأوعية التاريخي قبل تأسيس السياق.");
        if (context.LegacyPourVisibleIndex is not int i || i is < 1 or > 46 ||
            context.LegacyPoursResult is not null ||
            context.LegacyPourDrop.HasValue ||
            context.LegacyPourOrder is not null ||
            context.LegacyPourInitialBowls is not null ||
            context.PatchedVisibleDrops is not null)
            throw new MonsterValidationException("سياق الصبّ القديم ناقص أو مشغول مسبقاً.");

        // تُحسب كل الطبقات الثمانية السابقة والقيم التاريخية في متغيرات محلية.
        var candidate = _legacyPours.Handle(context);
        _validation.ValidateLegacyPours(context, candidate);

        context.PatchedCountsResult = candidate.Source.Counts;
        context.PatchedStoneRows = candidate.Source.Stones;
        context.LegacyHiddenReversed = candidate.Source.ReversedHiddenStorage;
        context.PatchedHiddenAccess = candidate.Source.HiddenAccessor;
        context.PatchedVisibleDrops = candidate.Source.Visible;
        context.LegacyPourDrop = candidate.Drop;
        context.LegacyPourInitialBowls = candidate.InitialBowls;
        context.LegacyPourOrder = candidate.Order;
        context.LegacyPoursResult = candidate.Pours;

        context.BranchTrace.Add("LEGACY_FIXED_BOWL_POURS");
        _metrics.Bump(context, "legacy.fixed.bowl.pours.dispatch");
        context.Phase = "LEGACY_FIXED_BOWL_POURS_COMPLETE";
        context.Status = "LEGACY_FIXED_BOWL_POURS_COMPLETE";
    }

    public void DispatchBowlAliasPatched(MonsterContext context)
    {
        if (!string.Equals(context.Status,"BOOTSTRAP_READY",StringComparison.Ordinal))
            throw new MonsterValidationException("لا تُركّب خريطة الأوعية قبل تأسيس سياق الاستدعاء.");
        if (context.LegacyPourVisibleIndex is not int ordinal || ordinal is < 1 or > 46 ||
            context.LegacyPoursResult is not null || context.PatchedPoursResult is not null ||
            context.BowlAliases is not null || context.LegacyPourDrop.HasValue ||
            context.LegacyPourOrder is not null || context.LegacyPourInitialBowls is not null ||
            context.PatchedVisibleDrops is not null)
            throw new MonsterValidationException("رقعة الأوعية تحتاج قطرة محددة وسياقاً خالياً.");

        // كل المرشحات والشواهد والمطابقة تُحتسب قبل التزام أية نتيجة.
        var candidate = _aliasPatch.Handle(context);
        _validation.ValidateLegacyPours(context,candidate.Legacy);
        _validation.ValidateBowlAliasPatch(context,candidate);

        context.PatchedCountsResult = candidate.Legacy.Source.Counts;
        context.PatchedStoneRows = candidate.Legacy.Source.Stones;
        context.LegacyHiddenReversed = candidate.Legacy.Source.ReversedHiddenStorage;
        context.PatchedHiddenAccess = candidate.Legacy.Source.HiddenAccessor;
        context.PatchedVisibleDrops = candidate.Legacy.Source.Visible;
        context.LegacyPourDrop = candidate.Legacy.Drop;
        context.LegacyPourInitialBowls = candidate.Legacy.InitialBowls;
        context.LegacyPourOrder = candidate.Legacy.Order;
        context.LegacyPoursResult = candidate.Legacy.Pours;
        context.BowlAliases = candidate.Aliases;
        context.PatchedPoursResult = candidate.PatchedPours;

        context.BranchTrace.Add("LEGACY_FIXED_BOWL_POURS_WITNESS");
        context.BranchTrace.Add("BOWL_ALIAS_PATCH");
        _metrics.Bump(context,"legacy.fixed.bowl.pours.witness");
        _metrics.Bump(context,"bowl.alias.patch.dispatch");
        context.Phase = "BOWL_ALIAS_PATCH_COMPLETE";
        context.Status = "BOWL_ALIAS_PATCH_COMPLETE";
    }

    public void DispatchLegacyInPlaceStir(MonsterContext context)
    {
        if (!string.Equals(context.Status,"BOOTSTRAP_READY",StringComparison.Ordinal))
            throw new MonsterValidationException("التحريك القديم يحتاج سياقاً مؤسساً.");
        if (context.LegacyPourVisibleIndex is not int ordinal || ordinal is < 1 or > 46 ||
            context.LegacyStirredBowls is not null ||
            context.LegacyPoursResult is not null || context.PatchedPoursResult is not null ||
            context.BowlAliases is not null || context.LegacyPourDrop.HasValue ||
            context.LegacyPourOrder is not null || context.LegacyPourInitialBowls is not null ||
            context.PatchedVisibleDrops is not null)
            throw new MonsterValidationException("سياق التحريك القديم ناقص أو مشغول.");

        var candidate=_legacyInPlaceStir.Handle(context);
        _validation.ValidateLegacyPours(context,candidate.Source.Legacy);
        _validation.ValidateBowlAliasPatch(context,candidate.Source);
        _validation.ValidateLegacyInPlaceStir(context,candidate);

        context.PatchedCountsResult=candidate.Source.Legacy.Source.Counts;
        context.PatchedStoneRows=candidate.Source.Legacy.Source.Stones;
        context.LegacyHiddenReversed=candidate.Source.Legacy.Source.ReversedHiddenStorage;
        context.PatchedHiddenAccess=candidate.Source.Legacy.Source.HiddenAccessor;
        context.PatchedVisibleDrops=candidate.Source.Legacy.Source.Visible;
        context.LegacyPourDrop=candidate.Source.Legacy.Drop;
        context.LegacyPourInitialBowls=candidate.Source.Legacy.InitialBowls;
        context.LegacyPourOrder=candidate.Source.Legacy.Order;
        context.LegacyPoursResult=candidate.Source.Legacy.Pours;
        context.BowlAliases=candidate.Source.Aliases;
        context.PatchedPoursResult=candidate.Source.PatchedPours;
        context.LegacyStirredBowls=candidate.MutatedBowls;

        context.BranchTrace.Add("LEGACY_IN_PLACE_BOWL_STIR");
        _metrics.Bump(context,"legacy.in.place.bowl.stir.dispatch");
        context.Phase="LEGACY_IN_PLACE_BOWL_STIR_COMPLETE";
        context.Status="LEGACY_IN_PLACE_BOWL_STIR_COMPLETE";
    }

    public void DispatchShadowBowlStir(MonsterContext context)
    {
        if(!string.Equals(context.Status,"BOOTSTRAP_READY",StringComparison.Ordinal))
            throw new MonsterValidationException("التحريك بالظل يحتاج سياقاً مؤسساً.");
        if(context.LegacyPourVisibleIndex is not int index || index is < 1 or > 46 ||
           context.LegacyStirredBowls is not null ||
           context.PatchedStirredBowls is not null ||
           context.StirVaultOld is not null || context.StirPending is not null ||
           context.PatchedPoursResult is not null ||
           context.LegacyPoursResult is not null ||
           context.BowlAliases is not null ||
           context.LegacyPourDrop.HasValue ||
           context.LegacyPourOrder is not null ||
           context.LegacyPourInitialBowls is not null ||
           context.PatchedVisibleDrops is not null)
            throw new MonsterValidationException("سياق رقعة الظل ناقص أو مشغول.");

        // الشهادة القديمة وحساب الظل والتحقق تتم كلها قبل تثبيت أي حالة.
        var candidate=_shadowStir.Handle(context);
        _validation.ValidateLegacyPours(context,candidate.Legacy.Source.Legacy);
        _validation.ValidateBowlAliasPatch(context,candidate.Legacy.Source);
        _validation.ValidateLegacyInPlaceStir(context,candidate.Legacy);
        _validation.ValidateShadowBowlStir(context,candidate);

        context.PatchedCountsResult=candidate.Legacy.Source.Legacy.Source.Counts;
        context.PatchedStoneRows=candidate.Legacy.Source.Legacy.Source.Stones;
        context.LegacyHiddenReversed=candidate.Legacy.Source.Legacy.Source.ReversedHiddenStorage;
        context.PatchedHiddenAccess=candidate.Legacy.Source.Legacy.Source.HiddenAccessor;
        context.PatchedVisibleDrops=candidate.Legacy.Source.Legacy.Source.Visible;
        context.LegacyPourDrop=candidate.Legacy.Source.Legacy.Drop;
        context.LegacyPourInitialBowls=candidate.Legacy.Source.Legacy.InitialBowls;
        context.LegacyPourOrder=candidate.Legacy.Source.Legacy.Order;
        context.LegacyPoursResult=candidate.Legacy.Source.Legacy.Pours;
        context.BowlAliases=candidate.Legacy.Source.Aliases;
        context.PatchedPoursResult=candidate.Legacy.Source.PatchedPours;
        context.LegacyStirredBowls=candidate.Legacy.MutatedBowls;
        context.StirVaultOld=candidate.Patched.VaultOld;
        context.StirPending=candidate.Patched.Pending;
        context.PatchedStirredBowls=candidate.Patched.Committed;

        context.BranchTrace.Add("LEGACY_IN_PLACE_BOWL_STIR_WITNESS");
        context.BranchTrace.Add("SHADOW_BOWL_STIR_PATCH");
        _metrics.Bump(context,"legacy.in.place.bowl.stir.witness");
        _metrics.Bump(context,"shadow.bowl.stir.patch.dispatch");
        context.Phase="SHADOW_BOWL_STIR_PATCH_COMPLETE";
        context.Status="SHADOW_BOWL_STIR_PATCH_COMPLETE";
    }

    public void DispatchLegacyOverwrittenSauce(MonsterContext context)
    {
        if(!string.Equals(context.Status,"BOOTSTRAP_READY",StringComparison.Ordinal))
            throw new MonsterValidationException("تتطلب الصلصة القديمة سياقاً مؤسساً.");
        if(context.LegacySauceFinalBowls is not null ||
           context.LegacyOverwrittenQueryOrder is not null ||
           context.LegacyDiagnosticDrop46Order is not null ||
           context.LegacyPostStirOrders is not null ||
           context.PatchedVisibleDrops is not null)
            throw new MonsterValidationException("حالة الصلصة القديمة مشغولة.");

        var candidate=_legacyOverwrittenSauce.Evaluate(context);
        _validation.ValidateVisibleDropPatch(context,candidate.Source);
        _validation.ValidateLegacyOverwrittenSauce(context,candidate);

        context.PatchedCountsResult=candidate.Source.Counts;
        context.PatchedStoneRows=candidate.Source.Stones;
        context.LegacyHiddenReversed=candidate.Source.ReversedHiddenStorage;
        context.PatchedHiddenAccess=candidate.Source.HiddenAccessor;
        context.PatchedVisibleDrops=candidate.Source.Visible;
        context.LegacyDiagnosticDrop46Order=candidate.DiagnosticDrop46Order;
        context.LegacyOverwrittenQueryOrder=candidate.OverwrittenQueryOrder;
        context.LegacyPostStirOrders=candidate.PostStirOrders;
        context.LegacySauceBowlsAfterDrops=candidate.BowlsAfterDrops;
        context.LegacySauceFinalBowls=candidate.FinalBowls;
        context.BranchTrace.Add("LEGACY_OVERWRITTEN_DROP46_ORDER");
        _metrics.Bump(context,"legacy.overwritten.drop46.order.dispatch");
        context.Phase="LEGACY_OVERWRITTEN_DROP46_ORDER_COMPLETE";
        context.Status="LEGACY_OVERWRITTEN_DROP46_ORDER_COMPLETE";
    }

    public void DispatchProtectedDrop46Sauce(MonsterContext context)
    {
        if(!string.Equals(context.Status,"BOOTSTRAP_READY",StringComparison.Ordinal))
            throw new MonsterValidationException("التقاط الترتيب يحتاج سياقاً مؤسساً.");
        if(context.PatchedOrderAt46Latch is not null ||
           context.PatchedSauceFinalBowls is not null ||
           context.PatchedSauceBowlsAfterDrops is not null ||
           context.PatchedPostStirOrders is not null ||
           context.LegacySauceFinalBowls is not null ||
           context.LegacyDiagnosticDrop46Order is not null ||
           context.LegacyOverwrittenQueryOrder is not null ||
           context.LegacyPostStirOrders is not null ||
           context.PatchedVisibleDrops is not null)
            throw new MonsterValidationException("سياق الالتقاط غير خالٍ.");

        var candidate=_protectedDrop46Sauce.Handle(context);
        _validation.ValidateVisibleDropPatch(context,candidate.Historical.Source);
        _validation.ValidateLegacyOverwrittenSauce(context,candidate.Historical);
        _validation.ValidateProtectedDrop46Sauce(context,candidate);

        context.PatchedCountsResult=candidate.Historical.Source.Counts;
        context.PatchedStoneRows=candidate.Historical.Source.Stones;
        context.LegacyHiddenReversed=candidate.Historical.Source.ReversedHiddenStorage;
        context.PatchedHiddenAccess=candidate.Historical.Source.HiddenAccessor;
        context.PatchedVisibleDrops=candidate.Historical.Source.Visible;

        context.LegacyDiagnosticDrop46Order=candidate.Historical.DiagnosticDrop46Order;
        context.LegacyOverwrittenQueryOrder=candidate.Historical.OverwrittenQueryOrder;
        context.LegacyPostStirOrders=candidate.Historical.PostStirOrders;
        context.LegacySauceBowlsAfterDrops=candidate.Historical.BowlsAfterDrops;
        context.LegacySauceFinalBowls=candidate.Historical.FinalBowls;

        context.PatchedOrderAt46Latch=candidate.Patched.OrderAt46Latch;
        context.PatchedSauceBowlsAfterDrops=candidate.Patched.BowlsAfterDrops;
        context.PatchedSauceFinalBowls=candidate.Patched.FinalBowls;
        context.PatchedPostStirOrders=candidate.Patched.PostStirOrders;

        context.BranchTrace.Add("LEGACY_OVERWRITTEN_DROP46_ORDER_WITNESS");
        context.BranchTrace.Add("PROTECTED_DROP46_ORDER_LATCH");
        _metrics.Bump(context,"legacy.overwritten.drop46.order.witness");
        _metrics.Bump(context,"protected.drop46.latch.dispatch");
        context.Phase="PROTECTED_DROP46_ORDER_LATCH_COMPLETE";
        context.Status="PROTECTED_DROP46_ORDER_LATCH_COMPLETE";
    }


    public void DispatchLegacyFixedNextBowl(MonsterContext context)
    {
        if (!string.Equals(context.Status,"BOOTSTRAP_READY",StringComparison.Ordinal))
            throw new MonsterValidationException("اختيار الجار القديم يتطلب سياقاً مؤسساً.");
        if (context.LegacyQueriedBowlId is not int queried || queried is < 1 or > 6 ||
            context.LegacyFixedNextBowlResult.HasValue ||
            context.PatchedSauceFinalBowls is not null ||
            context.LegacySauceFinalBowls is not null ||
            context.PatchedVisibleDrops is not null)
            throw new MonsterValidationException("طلب الجار القديم ناقص أو مشغول.");

        var candidate = _legacyFixedNextBowl.Handle(context);
        _validation.ValidateVisibleDropPatch(context,candidate.Sauce.Historical.Source);
        _validation.ValidateLegacyOverwrittenSauce(context,candidate.Sauce.Historical);
        _validation.ValidateProtectedDrop46Sauce(context,candidate.Sauce);
        _validation.ValidateLegacyFixedNextBowl(context,candidate);

        var source = candidate.Sauce.Historical.Source;
        var history = candidate.Sauce.Historical;
        var patched = candidate.Sauce.Patched;
        context.PatchedCountsResult = source.Counts;
        context.PatchedStoneRows = source.Stones;
        context.LegacyHiddenReversed = source.ReversedHiddenStorage;
        context.PatchedHiddenAccess = source.HiddenAccessor;
        context.PatchedVisibleDrops = source.Visible;
        context.LegacyDiagnosticDrop46Order = history.DiagnosticDrop46Order;
        context.LegacyOverwrittenQueryOrder = history.OverwrittenQueryOrder;
        context.LegacyPostStirOrders = history.PostStirOrders;
        context.LegacySauceBowlsAfterDrops = history.BowlsAfterDrops;
        context.LegacySauceFinalBowls = history.FinalBowls;
        context.PatchedOrderAt46Latch = patched.OrderAt46Latch;
        context.PatchedSauceBowlsAfterDrops = patched.BowlsAfterDrops;
        context.PatchedSauceFinalBowls = patched.FinalBowls;
        context.PatchedPostStirOrders = patched.PostStirOrders;
        context.LegacyFixedNextBowlResult = candidate.LegacyNextBowlId;

        context.BranchTrace.Add("LEGACY_OVERWRITTEN_DROP46_ORDER_WITNESS");
        context.BranchTrace.Add("PROTECTED_DROP46_ORDER_LATCH_WITNESS");
        context.BranchTrace.Add("LEGACY_FIXED_NEXT_BOWL");
        _metrics.Bump(context,"legacy.fixed.next.bowl.dispatch");
        context.Status = "LEGACY_FIXED_NEXT_BOWL_COMPLETE";
        context.Phase = context.Status;
    }


    public void DispatchPatchedNextBowl(MonsterContext context)
    {
        if (!string.Equals(context.Status,"BOOTSTRAP_READY",StringComparison.Ordinal))
            throw new MonsterValidationException("تحتاج رقعة الجار سياقاً مؤسساً.");
        if (context.LegacyQueriedBowlId is not int id || id is < 1 or > 6 ||
            context.LegacyFixedNextBowlResult.HasValue ||
            context.PatchedNextBowlResult.HasValue ||
            context.LegacySauceFinalBowls is not null ||
            context.PatchedSauceFinalBowls is not null ||
            context.PatchedOrderAt46Latch is not null ||
            context.PatchedVisibleDrops is not null)
            throw new MonsterValidationException("سياق رقعة الجار غير خالٍ أو السؤال ناقص.");

        var candidate = _patchedNextBowl.Handle(context);
        var historical = candidate.Historical;
        _validation.ValidateVisibleDropPatch(context,historical.Sauce.Historical.Source);
        _validation.ValidateLegacyOverwrittenSauce(context,historical.Sauce.Historical);
        _validation.ValidateProtectedDrop46Sauce(context,historical.Sauce);
        _validation.ValidateLegacyFixedNextBowl(context,historical);
        _validation.ValidatePatchedNextBowl(context,candidate);

        // لا تغيير دلالي ولا تسجيل تشخيص قبل أن تنجح جميع التحققات.
        var source = historical.Sauce.Historical.Source;
        var sauceOld = historical.Sauce.Historical;
        var saucePatched = historical.Sauce.Patched;
        context.PatchedCountsResult = source.Counts;
        context.PatchedStoneRows = source.Stones;
        context.LegacyHiddenReversed = source.ReversedHiddenStorage;
        context.PatchedHiddenAccess = source.HiddenAccessor;
        context.PatchedVisibleDrops = source.Visible;
        context.LegacyDiagnosticDrop46Order = sauceOld.DiagnosticDrop46Order;
        context.LegacyOverwrittenQueryOrder = sauceOld.OverwrittenQueryOrder;
        context.LegacyPostStirOrders = sauceOld.PostStirOrders;
        context.LegacySauceBowlsAfterDrops = sauceOld.BowlsAfterDrops;
        context.LegacySauceFinalBowls = sauceOld.FinalBowls;
        context.PatchedOrderAt46Latch = saucePatched.OrderAt46Latch;
        context.PatchedSauceBowlsAfterDrops = saucePatched.BowlsAfterDrops;
        context.PatchedSauceFinalBowls = saucePatched.FinalBowls;
        context.PatchedPostStirOrders = saucePatched.PostStirOrders;
        context.LegacyFixedNextBowlResult = historical.LegacyNextBowlId;
        context.PatchedNextBowlResult = candidate.NextBowlId;

        context.BranchTrace.Add("LEGACY_OVERWRITTEN_DROP46_ORDER_WITNESS");
        context.BranchTrace.Add("PROTECTED_DROP46_ORDER_LATCH_WITNESS");
        context.BranchTrace.Add("LEGACY_FIXED_NEXT_BOWL_WITNESS");
        context.BranchTrace.Add("PATCHED_NEXT_BOWL_ORDER");
        _metrics.Bump(context,"legacy.fixed.next.bowl.witness");
        _metrics.Bump(context,"patched.next.bowl.order.dispatch");
        context.Status = "PATCHED_NEXT_BOWL_ORDER_COMPLETE";
        context.Phase = context.Status;
    }


    public void DispatchLegacyUnsealedBowlQuestion(MonsterContext context)
    {
        if (!string.Equals(context.Status,"BOOTSTRAP_READY",StringComparison.Ordinal))
            throw new MonsterValidationException("سؤال الصلصة التاريخي يحتاج سياقاً مؤسساً.");
        if (context.LegacyQueriedBowlId is not int id || id is < 1 or > 6 ||
            context.LegacyBowlQuestionSeal is not int seal ||
            seal is not (21 or 31) ||
            context.LegacyUnsealedBowlQuestionResult is not null ||
            context.PatchedNextBowlResult.HasValue ||
            context.LegacyFixedNextBowlResult.HasValue ||
            context.PatchedSauceFinalBowls is not null ||
            context.LegacySauceFinalBowls is not null ||
            context.PatchedVisibleDrops is not null)
            throw new MonsterValidationException("سؤال الصلصة التاريخي مشغول أو معرّفاته باطلة.");

        var candidate=_legacyUnsealedQuestion.Handle(context);
        var patched=candidate.Historical;
        var historical=patched.Historical;
        _validation.ValidateVisibleDropPatch(context,historical.Sauce.Historical.Source);
        _validation.ValidateLegacyOverwrittenSauce(context,historical.Sauce.Historical);
        _validation.ValidateProtectedDrop46Sauce(context,historical.Sauce);
        _validation.ValidateLegacyFixedNextBowl(context,historical);
        _validation.ValidatePatchedNextBowl(context,patched);
        _validation.ValidateLegacyUnsealedBowlQuestion(context,candidate);

        // تثبيت ذري بعد فحص جميع السلاسل؛ لا تمس الرقع أو الندوب السابقة.
        var source=historical.Sauce.Historical.Source;
        var sauceOld=historical.Sauce.Historical;
        var sauceCorrect=historical.Sauce.Patched;
        context.PatchedCountsResult=source.Counts;
        context.PatchedStoneRows=source.Stones;
        context.LegacyHiddenReversed=source.ReversedHiddenStorage;
        context.PatchedHiddenAccess=source.HiddenAccessor;
        context.PatchedVisibleDrops=source.Visible;
        context.LegacyDiagnosticDrop46Order=sauceOld.DiagnosticDrop46Order;
        context.LegacyOverwrittenQueryOrder=sauceOld.OverwrittenQueryOrder;
        context.LegacyPostStirOrders=sauceOld.PostStirOrders;
        context.LegacySauceBowlsAfterDrops=sauceOld.BowlsAfterDrops;
        context.LegacySauceFinalBowls=sauceOld.FinalBowls;
        context.PatchedOrderAt46Latch=sauceCorrect.OrderAt46Latch;
        context.PatchedSauceBowlsAfterDrops=sauceCorrect.BowlsAfterDrops;
        context.PatchedSauceFinalBowls=sauceCorrect.FinalBowls;
        context.PatchedPostStirOrders=sauceCorrect.PostStirOrders;
        context.LegacyFixedNextBowlResult=historical.LegacyNextBowlId;
        context.PatchedNextBowlResult=patched.NextBowlId;
        context.LegacyUnsealedBowlQuestionResult=candidate.Answer;

        context.BranchTrace.Add("LEGACY_OVERWRITTEN_DROP46_ORDER_WITNESS");
        context.BranchTrace.Add("PROTECTED_DROP46_ORDER_LATCH_WITNESS");
        context.BranchTrace.Add("LEGACY_FIXED_NEXT_BOWL_WITNESS");
        context.BranchTrace.Add("PATCHED_NEXT_BOWL_ORDER_WITNESS");
        context.BranchTrace.Add("LEGACY_UNSEALED_BOWL_QUESTION");
        _metrics.Bump(context,"legacy.unsealed.bowl.question.dispatch");
        context.Status="LEGACY_UNSEALED_BOWL_QUESTION_COMPLETE";
        context.Phase=context.Status;
    }


    public void DispatchPatchedBowlQuestion(MonsterContext context)
    {
        if (context is null ||
            !string.Equals(context.Status,"BOOTSTRAP_READY",StringComparison.Ordinal))
            throw new MonsterValidationException("رقعة السؤال تتطلب تأسيس السياق.");
        if (context.LegacyQueriedBowlId is not int id || id is < 1 or > 6 ||
            context.LegacyBowlQuestionSeal is not int seal || seal is not (21 or 31) ||
            context.PatchedBowlQuestionResult is not null ||
            context.LegacyUnsealedBowlQuestionResult is not null ||
            context.LegacyFixedNextBowlResult.HasValue ||
            context.PatchedNextBowlResult.HasValue ||
            context.LegacySauceFinalBowls is not null ||
            context.PatchedSauceFinalBowls is not null ||
            context.PatchedVisibleDrops is not null)
            throw new MonsterValidationException("سؤال الرقعة الثالثة عشرة غير صالح أو مكرر.");

        var candidate=_patchedBowlQuestion.Handle(context);
        var questionOld=candidate.Historical;
        var nextPatched=questionOld.Historical;
        var nextOld=nextPatched.Historical;
        var source=nextOld.Sauce.Historical.Source;
        var sauceOld=nextOld.Sauce.Historical;
        var sauceCorrect=nextOld.Sauce.Patched;

        _validation.ValidateVisibleDropPatch(context,source);
        _validation.ValidateLegacyOverwrittenSauce(context,sauceOld);
        _validation.ValidateProtectedDrop46Sauce(context,nextOld.Sauce);
        _validation.ValidateLegacyFixedNextBowl(context,nextOld);
        _validation.ValidatePatchedNextBowl(context,nextPatched);
        _validation.ValidateLegacyUnsealedBowlQuestion(context,questionOld);
        _validation.ValidatePatchedBowlQuestion(context,candidate);

        // كل المعالجة قبل الالتزام. يتحول السياق في خطوة واحدة إلى نتيجة الرقعة.
        context.PatchedCountsResult=source.Counts;
        context.PatchedStoneRows=source.Stones;
        context.LegacyHiddenReversed=source.ReversedHiddenStorage;
        context.PatchedHiddenAccess=source.HiddenAccessor;
        context.PatchedVisibleDrops=source.Visible;
        context.LegacyDiagnosticDrop46Order=sauceOld.DiagnosticDrop46Order;
        context.LegacyOverwrittenQueryOrder=sauceOld.OverwrittenQueryOrder;
        context.LegacyPostStirOrders=sauceOld.PostStirOrders;
        context.LegacySauceBowlsAfterDrops=sauceOld.BowlsAfterDrops;
        context.LegacySauceFinalBowls=sauceOld.FinalBowls;
        context.PatchedOrderAt46Latch=sauceCorrect.OrderAt46Latch;
        context.PatchedSauceBowlsAfterDrops=sauceCorrect.BowlsAfterDrops;
        context.PatchedSauceFinalBowls=sauceCorrect.FinalBowls;
        context.PatchedPostStirOrders=sauceCorrect.PostStirOrders;
        context.LegacyFixedNextBowlResult=nextOld.LegacyNextBowlId;
        context.PatchedNextBowlResult=nextPatched.NextBowlId;
        context.LegacyUnsealedBowlQuestionResult=questionOld.Answer;
        context.PatchedBowlQuestionResult=candidate.Answer;

        context.BranchTrace.Add("LEGACY_OVERWRITTEN_DROP46_ORDER_WITNESS");
        context.BranchTrace.Add("PROTECTED_DROP46_ORDER_LATCH_WITNESS");
        context.BranchTrace.Add("LEGACY_FIXED_NEXT_BOWL_WITNESS");
        context.BranchTrace.Add("PATCHED_NEXT_BOWL_ORDER_WITNESS");
        context.BranchTrace.Add("LEGACY_UNSEALED_BOWL_QUESTION_WITNESS");
        context.BranchTrace.Add("PATCHED_SEALED_BOWL_QUESTION");
        _metrics.Bump(context,"legacy.unsealed.bowl.question.witness");
        _metrics.Bump(context,"patched.sealed.bowl.question.dispatch");
        context.Status="PATCHED_SEALED_BOWL_QUESTION_COMPLETE";
        context.Phase=context.Status;
    }


    public void DispatchLegacyOneBasedAnswer(MonsterContext context)
    {
        if (context is null ||
            !string.Equals(context.Status,"BOOTSTRAP_READY",StringComparison.Ordinal))
            throw new MonsterValidationException("لا تُنفذ الخطوة التاريخية دون سياق مؤسس.");
        if (context.LegacyQueriedBowlId is not int id || id is < 1 or > 6 ||
            context.LegacyBowlQuestionSeal is not int seal || seal is not (21 or 31) ||
            context.LegacyAnswerStepIndex is not BigInteger k || k < 0 ||
            context.LegacyOneBasedAnswerAtResult.HasValue ||
            context.PatchedBowlQuestionResult is not null ||
            context.LegacyUnsealedBowlQuestionResult is not null ||
            context.LegacyFixedNextBowlResult.HasValue ||
            context.PatchedNextBowlResult.HasValue ||
            context.LegacySauceFinalBowls is not null ||
            context.PatchedSauceFinalBowls is not null ||
            context.PatchedVisibleDrops is not null)
            throw new MonsterValidationException("سؤال الخطوة التاريخية مشغول أو غير صالح.");

        var candidate=_legacyOneBasedAnswer.Handle(context);
        var correctQuestion=candidate.Question;
        var oldQuestion=correctQuestion.Historical;
        var correctNext=oldQuestion.Historical;
        var oldNext=correctNext.Historical;
        var source=oldNext.Sauce.Historical.Source;
        var sauceOld=oldNext.Sauce.Historical;
        var saucePatched=oldNext.Sauce.Patched;

        _validation.ValidateVisibleDropPatch(context,source);
        _validation.ValidateLegacyOverwrittenSauce(context,sauceOld);
        _validation.ValidateProtectedDrop46Sauce(context,oldNext.Sauce);
        _validation.ValidateLegacyFixedNextBowl(context,oldNext);
        _validation.ValidatePatchedNextBowl(context,correctNext);
        _validation.ValidateLegacyUnsealedBowlQuestion(context,oldQuestion);
        _validation.ValidatePatchedBowlQuestion(context,correctQuestion);
        _validation.ValidateLegacyOneBasedAnswerStep(context,candidate);

        // تُثبَّت الأدلة السابقة كلها بعد قبول المرشح، لا أثناء حسابه.
        context.PatchedCountsResult=source.Counts;
        context.PatchedStoneRows=source.Stones;
        context.LegacyHiddenReversed=source.ReversedHiddenStorage;
        context.PatchedHiddenAccess=source.HiddenAccessor;
        context.PatchedVisibleDrops=source.Visible;
        context.LegacyDiagnosticDrop46Order=sauceOld.DiagnosticDrop46Order;
        context.LegacyOverwrittenQueryOrder=sauceOld.OverwrittenQueryOrder;
        context.LegacyPostStirOrders=sauceOld.PostStirOrders;
        context.LegacySauceBowlsAfterDrops=sauceOld.BowlsAfterDrops;
        context.LegacySauceFinalBowls=sauceOld.FinalBowls;
        context.PatchedOrderAt46Latch=saucePatched.OrderAt46Latch;
        context.PatchedSauceBowlsAfterDrops=saucePatched.BowlsAfterDrops;
        context.PatchedSauceFinalBowls=saucePatched.FinalBowls;
        context.PatchedPostStirOrders=saucePatched.PostStirOrders;
        context.LegacyFixedNextBowlResult=oldNext.LegacyNextBowlId;
        context.PatchedNextBowlResult=correctNext.NextBowlId;
        context.LegacyUnsealedBowlQuestionResult=oldQuestion.Answer;
        context.PatchedBowlQuestionResult=correctQuestion.Answer;
        context.LegacyOneBasedAnswerAtResult=candidate.Value;

        context.BranchTrace.Add("LEGACY_OVERWRITTEN_DROP46_ORDER_WITNESS");
        context.BranchTrace.Add("PROTECTED_DROP46_ORDER_LATCH_WITNESS");
        context.BranchTrace.Add("LEGACY_FIXED_NEXT_BOWL_WITNESS");
        context.BranchTrace.Add("PATCHED_NEXT_BOWL_ORDER_WITNESS");
        context.BranchTrace.Add("LEGACY_UNSEALED_BOWL_QUESTION_WITNESS");
        context.BranchTrace.Add("PATCHED_SEALED_BOWL_QUESTION_WITNESS");
        context.BranchTrace.Add("LEGACY_ONE_BASED_ANSWER_STEP");
        _metrics.Bump(context,"legacy.one.based.answer.step.dispatch");
        context.Status="LEGACY_ONE_BASED_ANSWER_STEP_COMPLETE";
        context.Phase=context.Status;
    }


    public void DispatchPatchedAnswerStep(MonsterContext context)
    {
        if (context is null ||
            !string.Equals(context.Status,"BOOTSTRAP_READY",StringComparison.Ordinal))
            throw new MonsterValidationException("رقعة تيار الإجابات تتطلب سياقاً مؤسساً.");
        if (context.LegacyQueriedBowlId is not int id || id is < 1 or > 6 ||
            context.LegacyBowlQuestionSeal is not int seal || seal is not (21 or 31) ||
            context.LegacyAnswerStepIndex is not BigInteger k || k < 0 ||
            context.PatchedAnswerAtResult.HasValue ||
            context.LegacyOneBasedAnswerAtResult.HasValue ||
            context.PatchedBowlQuestionResult is not null ||
            context.LegacyUnsealedBowlQuestionResult is not null ||
            context.LegacyFixedNextBowlResult.HasValue ||
            context.PatchedNextBowlResult.HasValue ||
            context.LegacySauceFinalBowls is not null ||
            context.PatchedSauceFinalBowls is not null ||
            context.PatchedVisibleDrops is not null)
            throw new MonsterValidationException("رقعة الإجابات مكررة أو السؤال ناقص.");

        var candidate=_patchedAnswerStep.Handle(context);
        var oneBased=candidate.Historical;
        var sealedQuestion=oneBased.Question;
        var oldQuestion=sealedQuestion.Historical;
        var correctedNext=oldQuestion.Historical;
        var oldNext=correctedNext.Historical;
        var source=oldNext.Sauce.Historical.Source;
        var sauceOld=oldNext.Sauce.Historical;
        var sauceCorrect=oldNext.Sauce.Patched;

        _validation.ValidateVisibleDropPatch(context,source);
        _validation.ValidateLegacyOverwrittenSauce(context,sauceOld);
        _validation.ValidateProtectedDrop46Sauce(context,oldNext.Sauce);
        _validation.ValidateLegacyFixedNextBowl(context,oldNext);
        _validation.ValidatePatchedNextBowl(context,correctedNext);
        _validation.ValidateLegacyUnsealedBowlQuestion(context,oldQuestion);
        _validation.ValidatePatchedBowlQuestion(context,sealedQuestion);
        _validation.ValidateLegacyOneBasedAnswerStep(context,oneBased);
        _validation.ValidatePatchedAnswerStep(context,candidate);

        // بعد اكتمال كل الفحوص تُحفظ السلسلة والشواهد دون كتابة مبكرة.
        context.PatchedCountsResult=source.Counts;
        context.PatchedStoneRows=source.Stones;
        context.LegacyHiddenReversed=source.ReversedHiddenStorage;
        context.PatchedHiddenAccess=source.HiddenAccessor;
        context.PatchedVisibleDrops=source.Visible;
        context.LegacyDiagnosticDrop46Order=sauceOld.DiagnosticDrop46Order;
        context.LegacyOverwrittenQueryOrder=sauceOld.OverwrittenQueryOrder;
        context.LegacyPostStirOrders=sauceOld.PostStirOrders;
        context.LegacySauceBowlsAfterDrops=sauceOld.BowlsAfterDrops;
        context.LegacySauceFinalBowls=sauceOld.FinalBowls;
        context.PatchedOrderAt46Latch=sauceCorrect.OrderAt46Latch;
        context.PatchedSauceBowlsAfterDrops=sauceCorrect.BowlsAfterDrops;
        context.PatchedSauceFinalBowls=sauceCorrect.FinalBowls;
        context.PatchedPostStirOrders=sauceCorrect.PostStirOrders;
        context.LegacyFixedNextBowlResult=oldNext.LegacyNextBowlId;
        context.PatchedNextBowlResult=correctedNext.NextBowlId;
        context.LegacyUnsealedBowlQuestionResult=oldQuestion.Answer;
        context.PatchedBowlQuestionResult=sealedQuestion.Answer;
        context.LegacyOneBasedAnswerAtResult=oneBased.Value;
        context.PatchedAnswerAtResult=candidate.Value;

        context.BranchTrace.Add("LEGACY_OVERWRITTEN_DROP46_ORDER_WITNESS");
        context.BranchTrace.Add("PROTECTED_DROP46_ORDER_LATCH_WITNESS");
        context.BranchTrace.Add("LEGACY_FIXED_NEXT_BOWL_WITNESS");
        context.BranchTrace.Add("PATCHED_NEXT_BOWL_ORDER_WITNESS");
        context.BranchTrace.Add("LEGACY_UNSEALED_BOWL_QUESTION_WITNESS");
        context.BranchTrace.Add("PATCHED_SEALED_BOWL_QUESTION_WITNESS");
        context.BranchTrace.Add("LEGACY_ONE_BASED_ANSWER_STEP_WITNESS");
        context.BranchTrace.Add("PATCHED_ZERO_BASED_ANSWER_STEP");
        _metrics.Bump(context,"legacy.one.based.answer.step.witness");
        _metrics.Bump(context,"patched.zero.based.answer.step.dispatch");
        context.Status="PATCHED_ZERO_BASED_ANSWER_STEP_COMPLETE";
        context.Phase=context.Status;
    }


    public void DispatchLegacyUnshiftedShortRank(MonsterContext context)
    {
        if(context is null ||
           !string.Equals(context.Status,"BOOTSTRAP_READY",StringComparison.Ordinal))
            throw new MonsterValidationException("تتطلب المرتبة التاريخية سياقاً مؤسساً.");
        if(context.LegacyQueriedBowlId is not int id || id is < 1 or > 6 ||
           context.LegacyBowlQuestionSeal is not int seal || seal is not (21 or 31) ||
           context.LegacyShortFamilySize is not BigInteger n || n<1 ||
           n>((BigInteger.One<<127)-BigInteger.One) ||
           context.LegacyAnswerStepIndex is not BigInteger k || !k.IsZero ||
           context.LegacyShortFamilyRankResult.HasValue ||
           context.PatchedAnswerAtResult.HasValue ||
           context.LegacyOneBasedAnswerAtResult.HasValue ||
           context.PatchedBowlQuestionResult is not null ||
           context.LegacyUnsealedBowlQuestionResult is not null ||
           context.PatchedNextBowlResult.HasValue ||
           context.LegacySauceFinalBowls is not null ||
           context.PatchedSauceFinalBowls is not null ||
           context.PatchedVisibleDrops is not null)
            throw new MonsterValidationException("المرتبة القصيرة غير صالحة أو مُكررة.");

        var candidate=_legacyShortRank.Handle(context);
        var step=candidate.Step;
        var oneBased=step.Historical;
        var sealedQuestion=oneBased.Question;
        var oldQuestion=sealedQuestion.Historical;
        var correctedNext=oldQuestion.Historical;
        var oldNext=correctedNext.Historical;
        var source=oldNext.Sauce.Historical.Source;
        var sauceOld=oldNext.Sauce.Historical;
        var sauceCorrect=oldNext.Sauce.Patched;

        _validation.ValidateVisibleDropPatch(context,source);
        _validation.ValidateLegacyOverwrittenSauce(context,sauceOld);
        _validation.ValidateProtectedDrop46Sauce(context,oldNext.Sauce);
        _validation.ValidateLegacyFixedNextBowl(context,oldNext);
        _validation.ValidatePatchedNextBowl(context,correctedNext);
        _validation.ValidateLegacyUnsealedBowlQuestion(context,oldQuestion);
        _validation.ValidatePatchedBowlQuestion(context,sealedQuestion);
        _validation.ValidateLegacyOneBasedAnswerStep(context,oneBased);
        _validation.ValidatePatchedAnswerStep(context,step);
        _validation.ValidateLegacyUnshiftedShortRank(context,candidate);

        context.PatchedCountsResult=source.Counts;
        context.PatchedStoneRows=source.Stones;
        context.LegacyHiddenReversed=source.ReversedHiddenStorage;
        context.PatchedHiddenAccess=source.HiddenAccessor;
        context.PatchedVisibleDrops=source.Visible;
        context.LegacyDiagnosticDrop46Order=sauceOld.DiagnosticDrop46Order;
        context.LegacyOverwrittenQueryOrder=sauceOld.OverwrittenQueryOrder;
        context.LegacyPostStirOrders=sauceOld.PostStirOrders;
        context.LegacySauceBowlsAfterDrops=sauceOld.BowlsAfterDrops;
        context.LegacySauceFinalBowls=sauceOld.FinalBowls;
        context.PatchedOrderAt46Latch=sauceCorrect.OrderAt46Latch;
        context.PatchedSauceBowlsAfterDrops=sauceCorrect.BowlsAfterDrops;
        context.PatchedSauceFinalBowls=sauceCorrect.FinalBowls;
        context.PatchedPostStirOrders=sauceCorrect.PostStirOrders;
        context.LegacyFixedNextBowlResult=oldNext.LegacyNextBowlId;
        context.PatchedNextBowlResult=correctedNext.NextBowlId;
        context.LegacyUnsealedBowlQuestionResult=oldQuestion.Answer;
        context.PatchedBowlQuestionResult=sealedQuestion.Answer;
        context.LegacyOneBasedAnswerAtResult=oneBased.Value;
        context.PatchedAnswerAtResult=step.Value;
        context.LegacyShortFamilyRankResult=candidate.Rank;

        context.BranchTrace.Add("LEGACY_OVERWRITTEN_DROP46_ORDER_WITNESS");
        context.BranchTrace.Add("PROTECTED_DROP46_ORDER_LATCH_WITNESS");
        context.BranchTrace.Add("LEGACY_FIXED_NEXT_BOWL_WITNESS");
        context.BranchTrace.Add("PATCHED_NEXT_BOWL_ORDER_WITNESS");
        context.BranchTrace.Add("LEGACY_UNSEALED_BOWL_QUESTION_WITNESS");
        context.BranchTrace.Add("PATCHED_SEALED_BOWL_QUESTION_WITNESS");
        context.BranchTrace.Add("LEGACY_ONE_BASED_ANSWER_STEP_WITNESS");
        context.BranchTrace.Add("PATCHED_ZERO_BASED_ANSWER_STEP_WITNESS");
        context.BranchTrace.Add("LEGACY_UNSHIFTED_SHORT_FAMILY_RANK");
        _metrics.Bump(context,"legacy.unshifted.short.family.rank.dispatch");
        context.Status="LEGACY_UNSHIFTED_SHORT_FAMILY_RANK_COMPLETE";
        context.Phase=context.Status;
    }


    public void DispatchPatchedShortRank(MonsterContext context)
    {
        if(context is null ||
           !string.Equals(context.Status,"BOOTSTRAP_READY",StringComparison.Ordinal))
            throw new MonsterValidationException("رقعة الأسرة القصيرة تحتاج سياقاً مؤسساً.");
        if(context.LegacyQueriedBowlId is not int id || id is < 1 or > 6 ||
           context.LegacyBowlQuestionSeal is not int seal || seal is not (21 or 31) ||
           context.LegacyShortFamilySize is not BigInteger n || n<1 ||
           n>((BigInteger.One<<127)-BigInteger.One) ||
           context.LegacyAnswerStepIndex is not BigInteger k || !k.IsZero ||
           context.PatchedShortFamilyRankResult.HasValue ||
           context.LegacyShortFamilyRankResult.HasValue ||
           context.PatchedAnswerAtResult.HasValue ||
           context.LegacyOneBasedAnswerAtResult.HasValue ||
           context.PatchedBowlQuestionResult is not null ||
           context.LegacyUnsealedBowlQuestionResult is not null ||
           context.PatchedNextBowlResult.HasValue ||
           context.LegacySauceFinalBowls is not null ||
           context.PatchedSauceFinalBowls is not null ||
           context.PatchedVisibleDrops is not null)
            throw new MonsterValidationException("سياق الرقعة الخامسة عشرة غير صالح أو مكرر.");

        var candidate=_patchedShortRank.Handle(context);
        var unshifted=candidate.Historical;
        var step=unshifted.Step;
        var oneBased=step.Historical;
        var sealedQuestion=oneBased.Question;
        var oldQuestion=sealedQuestion.Historical;
        var correctedNext=oldQuestion.Historical;
        var oldNext=correctedNext.Historical;
        var source=oldNext.Sauce.Historical.Source;
        var sauceOld=oldNext.Sauce.Historical;
        var sauceCorrect=oldNext.Sauce.Patched;

        _validation.ValidateVisibleDropPatch(context,source);
        _validation.ValidateLegacyOverwrittenSauce(context,sauceOld);
        _validation.ValidateProtectedDrop46Sauce(context,oldNext.Sauce);
        _validation.ValidateLegacyFixedNextBowl(context,oldNext);
        _validation.ValidatePatchedNextBowl(context,correctedNext);
        _validation.ValidateLegacyUnsealedBowlQuestion(context,oldQuestion);
        _validation.ValidatePatchedBowlQuestion(context,sealedQuestion);
        _validation.ValidateLegacyOneBasedAnswerStep(context,oneBased);
        _validation.ValidatePatchedAnswerStep(context,step);
        _validation.ValidateLegacyUnshiftedShortRank(context,unshifted);
        _validation.ValidatePatchedShortRank(context,candidate);

        // لا تثبيت لأي شاهد أو أداة قياس قبل إتمام جميع المدققات.
        context.PatchedCountsResult=source.Counts;
        context.PatchedStoneRows=source.Stones;
        context.LegacyHiddenReversed=source.ReversedHiddenStorage;
        context.PatchedHiddenAccess=source.HiddenAccessor;
        context.PatchedVisibleDrops=source.Visible;
        context.LegacyDiagnosticDrop46Order=sauceOld.DiagnosticDrop46Order;
        context.LegacyOverwrittenQueryOrder=sauceOld.OverwrittenQueryOrder;
        context.LegacyPostStirOrders=sauceOld.PostStirOrders;
        context.LegacySauceBowlsAfterDrops=sauceOld.BowlsAfterDrops;
        context.LegacySauceFinalBowls=sauceOld.FinalBowls;
        context.PatchedOrderAt46Latch=sauceCorrect.OrderAt46Latch;
        context.PatchedSauceBowlsAfterDrops=sauceCorrect.BowlsAfterDrops;
        context.PatchedSauceFinalBowls=sauceCorrect.FinalBowls;
        context.PatchedPostStirOrders=sauceCorrect.PostStirOrders;
        context.LegacyFixedNextBowlResult=oldNext.LegacyNextBowlId;
        context.PatchedNextBowlResult=correctedNext.NextBowlId;
        context.LegacyUnsealedBowlQuestionResult=oldQuestion.Answer;
        context.PatchedBowlQuestionResult=sealedQuestion.Answer;
        context.LegacyOneBasedAnswerAtResult=oneBased.Value;
        context.PatchedAnswerAtResult=step.Value;
        context.LegacyShortFamilyRankResult=unshifted.Rank;
        context.PatchedShortFamilyRankResult=candidate.Rank;

        context.BranchTrace.Add("LEGACY_OVERWRITTEN_DROP46_ORDER_WITNESS");
        context.BranchTrace.Add("PROTECTED_DROP46_ORDER_LATCH_WITNESS");
        context.BranchTrace.Add("LEGACY_FIXED_NEXT_BOWL_WITNESS");
        context.BranchTrace.Add("PATCHED_NEXT_BOWL_ORDER_WITNESS");
        context.BranchTrace.Add("LEGACY_UNSEALED_BOWL_QUESTION_WITNESS");
        context.BranchTrace.Add("PATCHED_SEALED_BOWL_QUESTION_WITNESS");
        context.BranchTrace.Add("LEGACY_ONE_BASED_ANSWER_STEP_WITNESS");
        context.BranchTrace.Add("PATCHED_ZERO_BASED_ANSWER_STEP_WITNESS");
        context.BranchTrace.Add("LEGACY_UNSHIFTED_SHORT_FAMILY_RANK_WITNESS");
        context.BranchTrace.Add("PATCHED_SHORT_FAMILY_RANK");
        _metrics.Bump(context,"legacy.unshifted.short.family.rank.witness");
        _metrics.Bump(context,"patched.short.family.rank.dispatch");
        context.Status="PATCHED_SHORT_FAMILY_RANK_COMPLETE";
        context.Phase=context.Status;
    }


    public void DispatchLegacyReversedWideRank(MonsterContext context)
    {
        if(context is null ||
           !string.Equals(context.Status,"BOOTSTRAP_READY",StringComparison.Ordinal))
            throw new MonsterValidationException("ترتيب الأسرة الواسعة يتطلب تأسيساً.");
        if(context.LegacyQueriedBowlId is not int id || id is < 1 or > 6 ||
           context.LegacyBowlQuestionSeal is not int seal || seal is not (21 or 31) ||
           context.LegacyWideFamilySize is not BigInteger n ||
           n<=((BigInteger.One<<127)-BigInteger.One) ||
           context.LegacyAnswerStepIndex is not BigInteger k || !k.IsZero ||
           context.LegacyReversedWideRankResult.HasValue ||
           context.LegacyShortFamilyRankResult.HasValue ||
           context.PatchedShortFamilyRankResult.HasValue ||
           context.PatchedAnswerAtResult.HasValue ||
           context.LegacyOneBasedAnswerAtResult.HasValue ||
           context.PatchedBowlQuestionResult is not null ||
           context.LegacyUnsealedBowlQuestionResult is not null ||
           context.PatchedNextBowlResult.HasValue ||
           context.LegacySauceFinalBowls is not null ||
           context.PatchedSauceFinalBowls is not null ||
           context.PatchedVisibleDrops is not null)
            throw new MonsterValidationException("سياق الأسرة الواسعة مكرر أو ناقص.");

        var candidate=_legacyWideRank.Handle(context);
        var step=candidate.Step;
        var oneBased=step.Historical;
        var sealedQuestion=oneBased.Question;
        var oldQuestion=sealedQuestion.Historical;
        var correctedNext=oldQuestion.Historical;
        var oldNext=correctedNext.Historical;
        var source=oldNext.Sauce.Historical.Source;
        var sauceOld=oldNext.Sauce.Historical;
        var sauceCorrect=oldNext.Sauce.Patched;

        _validation.ValidateVisibleDropPatch(context,source);
        _validation.ValidateLegacyOverwrittenSauce(context,sauceOld);
        _validation.ValidateProtectedDrop46Sauce(context,oldNext.Sauce);
        _validation.ValidateLegacyFixedNextBowl(context,oldNext);
        _validation.ValidatePatchedNextBowl(context,correctedNext);
        _validation.ValidateLegacyUnsealedBowlQuestion(context,oldQuestion);
        _validation.ValidatePatchedBowlQuestion(context,sealedQuestion);
        _validation.ValidateLegacyOneBasedAnswerStep(context,oneBased);
        _validation.ValidatePatchedAnswerStep(context,step);
        _validation.ValidateLegacyReversedWideRank(context,candidate);

        // تثبيت واحد فقط بعد كل الفحوص؛ كل سجلات الخطوات السابقة مستقلة.
        context.PatchedCountsResult=source.Counts;
        context.PatchedStoneRows=source.Stones;
        context.LegacyHiddenReversed=source.ReversedHiddenStorage;
        context.PatchedHiddenAccess=source.HiddenAccessor;
        context.PatchedVisibleDrops=source.Visible;
        context.LegacyDiagnosticDrop46Order=sauceOld.DiagnosticDrop46Order;
        context.LegacyOverwrittenQueryOrder=sauceOld.OverwrittenQueryOrder;
        context.LegacyPostStirOrders=sauceOld.PostStirOrders;
        context.LegacySauceBowlsAfterDrops=sauceOld.BowlsAfterDrops;
        context.LegacySauceFinalBowls=sauceOld.FinalBowls;
        context.PatchedOrderAt46Latch=sauceCorrect.OrderAt46Latch;
        context.PatchedSauceBowlsAfterDrops=sauceCorrect.BowlsAfterDrops;
        context.PatchedSauceFinalBowls=sauceCorrect.FinalBowls;
        context.PatchedPostStirOrders=sauceCorrect.PostStirOrders;
        context.LegacyFixedNextBowlResult=oldNext.LegacyNextBowlId;
        context.PatchedNextBowlResult=correctedNext.NextBowlId;
        context.LegacyUnsealedBowlQuestionResult=oldQuestion.Answer;
        context.PatchedBowlQuestionResult=sealedQuestion.Answer;
        context.LegacyOneBasedAnswerAtResult=oneBased.Value;
        context.PatchedAnswerAtResult=step.Value;
        context.LegacyReversedWideRankResult=candidate.Rank;

        context.BranchTrace.Add("LEGACY_OVERWRITTEN_DROP46_ORDER_WITNESS");
        context.BranchTrace.Add("PROTECTED_DROP46_ORDER_LATCH_WITNESS");
        context.BranchTrace.Add("LEGACY_FIXED_NEXT_BOWL_WITNESS");
        context.BranchTrace.Add("PATCHED_NEXT_BOWL_ORDER_WITNESS");
        context.BranchTrace.Add("LEGACY_UNSEALED_BOWL_QUESTION_WITNESS");
        context.BranchTrace.Add("PATCHED_SEALED_BOWL_QUESTION_WITNESS");
        context.BranchTrace.Add("LEGACY_ONE_BASED_ANSWER_STEP_WITNESS");
        context.BranchTrace.Add("PATCHED_ZERO_BASED_ANSWER_STEP_WITNESS");
        context.BranchTrace.Add("LEGACY_REVERSED_WIDE_DIGITS");
        _metrics.Bump(context,"legacy.reversed.wide.digits.dispatch");
        context.Status="LEGACY_REVERSED_WIDE_DIGITS_COMPLETE";
        context.Phase=context.Status;
    }


    public void DispatchPatchedWideRank(MonsterContext context)
    {
        if(context is null ||
           !string.Equals(context.Status,"BOOTSTRAP_READY",StringComparison.Ordinal))
            throw new MonsterValidationException("يتطلب إصلاح الرتبة الواسعة سياقاً مؤسساً.");
        if(context.LegacyQueriedBowlId is not int id || id is < 1 or > 6 ||
           context.LegacyBowlQuestionSeal is not int seal || seal is not (21 or 31) ||
           context.LegacyWideFamilySize is not BigInteger n ||
           n<=((BigInteger.One<<127)-BigInteger.One) ||
           context.LegacyAnswerStepIndex is not BigInteger k || !k.IsZero ||
           context.PatchedWideRankResult.HasValue ||
           context.LegacyReversedWideRankResult.HasValue ||
           context.LegacyShortFamilyRankResult.HasValue ||
           context.PatchedShortFamilyRankResult.HasValue ||
           context.PatchedAnswerAtResult.HasValue ||
           context.LegacyOneBasedAnswerAtResult.HasValue ||
           context.PatchedBowlQuestionResult is not null ||
           context.LegacyUnsealedBowlQuestionResult is not null ||
           context.PatchedNextBowlResult.HasValue ||
           context.LegacySauceFinalBowls is not null ||
           context.PatchedSauceFinalBowls is not null ||
           context.PatchedVisibleDrops is not null)
            throw new MonsterValidationException("سياق الأسرة الواسعة مكرر أو غير صالح.");

        var candidate=_patchedWideRank.Handle(context);
        var oldWide=candidate.Historical;
        var step=oldWide.Step;
        var oneBased=step.Historical;
        var sealedQuestion=oneBased.Question;
        var oldQuestion=sealedQuestion.Historical;
        var correctedNext=oldQuestion.Historical;
        var oldNext=correctedNext.Historical;
        var source=oldNext.Sauce.Historical.Source;
        var sauceOld=oldNext.Sauce.Historical;
        var sauceCorrect=oldNext.Sauce.Patched;

        _validation.ValidateVisibleDropPatch(context,source);
        _validation.ValidateLegacyOverwrittenSauce(context,sauceOld);
        _validation.ValidateProtectedDrop46Sauce(context,oldNext.Sauce);
        _validation.ValidateLegacyFixedNextBowl(context,oldNext);
        _validation.ValidatePatchedNextBowl(context,correctedNext);
        _validation.ValidateLegacyUnsealedBowlQuestion(context,oldQuestion);
        _validation.ValidatePatchedBowlQuestion(context,sealedQuestion);
        _validation.ValidateLegacyOneBasedAnswerStep(context,oneBased);
        _validation.ValidatePatchedAnswerStep(context,step);
        _validation.ValidateLegacyReversedWideRank(context,oldWide);
        _validation.ValidatePatchedWideRank(context,candidate);

        // الدليل القديم والجواب الجديد يُلتزمان معاً بعد قبول المرشح.
        context.PatchedCountsResult=source.Counts;
        context.PatchedStoneRows=source.Stones;
        context.LegacyHiddenReversed=source.ReversedHiddenStorage;
        context.PatchedHiddenAccess=source.HiddenAccessor;
        context.PatchedVisibleDrops=source.Visible;
        context.LegacyDiagnosticDrop46Order=sauceOld.DiagnosticDrop46Order;
        context.LegacyOverwrittenQueryOrder=sauceOld.OverwrittenQueryOrder;
        context.LegacyPostStirOrders=sauceOld.PostStirOrders;
        context.LegacySauceBowlsAfterDrops=sauceOld.BowlsAfterDrops;
        context.LegacySauceFinalBowls=sauceOld.FinalBowls;
        context.PatchedOrderAt46Latch=sauceCorrect.OrderAt46Latch;
        context.PatchedSauceBowlsAfterDrops=sauceCorrect.BowlsAfterDrops;
        context.PatchedSauceFinalBowls=sauceCorrect.FinalBowls;
        context.PatchedPostStirOrders=sauceCorrect.PostStirOrders;
        context.LegacyFixedNextBowlResult=oldNext.LegacyNextBowlId;
        context.PatchedNextBowlResult=correctedNext.NextBowlId;
        context.LegacyUnsealedBowlQuestionResult=oldQuestion.Answer;
        context.PatchedBowlQuestionResult=sealedQuestion.Answer;
        context.LegacyOneBasedAnswerAtResult=oneBased.Value;
        context.PatchedAnswerAtResult=step.Value;
        context.LegacyReversedWideRankResult=oldWide.Rank;
        context.PatchedWideRankResult=candidate.Rank;

        context.BranchTrace.Add("LEGACY_OVERWRITTEN_DROP46_ORDER_WITNESS");
        context.BranchTrace.Add("PROTECTED_DROP46_ORDER_LATCH_WITNESS");
        context.BranchTrace.Add("LEGACY_FIXED_NEXT_BOWL_WITNESS");
        context.BranchTrace.Add("PATCHED_NEXT_BOWL_ORDER_WITNESS");
        context.BranchTrace.Add("LEGACY_UNSEALED_BOWL_QUESTION_WITNESS");
        context.BranchTrace.Add("PATCHED_SEALED_BOWL_QUESTION_WITNESS");
        context.BranchTrace.Add("LEGACY_ONE_BASED_ANSWER_STEP_WITNESS");
        context.BranchTrace.Add("PATCHED_ZERO_BASED_ANSWER_STEP_WITNESS");
        context.BranchTrace.Add("LEGACY_REVERSED_WIDE_DIGITS_WITNESS");
        context.BranchTrace.Add("PATCHED_WIDE_DIGIT_ORDER");
        _metrics.Bump(context,"legacy.reversed.wide.digits.witness");
        _metrics.Bump(context,"patched.wide.digit.order.dispatch");
        context.Status="PATCHED_WIDE_DIGIT_ORDER_COMPLETE";
        context.Phase=context.Status;
    }


    public void DispatchLegacyInclusiveWideLimit(MonsterContext context)
    {
        if(context is null ||
           !string.Equals(context.Status,"BOOTSTRAP_READY",StringComparison.Ordinal))
            throw new MonsterValidationException("يتطلب شاهد الحدّ سياقاً مؤسساً.");
        if(context.LegacyQueriedBowlId is not int id || id is < 1 or > 6 ||
           context.LegacyBowlQuestionSeal is not int seal || seal is not (21 or 31) ||
           context.LegacyWideFamilySize is not BigInteger n ||
           n<=((BigInteger.One<<127)-BigInteger.One) ||
           context.LegacyAnswerStepIndex is not BigInteger k || !k.IsZero ||
           context.LegacyInclusiveWideLimitRankResult.HasValue ||
           context.PatchedWideRankResult.HasValue ||
           context.LegacyReversedWideRankResult.HasValue ||
           context.PatchedAnswerAtResult.HasValue ||
           context.LegacyOneBasedAnswerAtResult.HasValue ||
           context.PatchedBowlQuestionResult is not null ||
           context.LegacyUnsealedBowlQuestionResult is not null ||
           context.PatchedNextBowlResult.HasValue ||
           context.LegacySauceFinalBowls is not null ||
           context.PatchedSauceFinalBowls is not null ||
           context.PatchedVisibleDrops is not null)
            throw new MonsterValidationException("حالة شاهد الحدّ مكررة أو ناقصة.");

        var candidate=_inclusiveWideLimit.Handle(context);
        var wide=candidate.Previous;
        var oldWide=wide.Historical;
        var step=oldWide.Step;
        var oneBased=step.Historical;
        var sealedQuestion=oneBased.Question;
        var oldQuestion=sealedQuestion.Historical;
        var correctedNext=oldQuestion.Historical;
        var oldNext=correctedNext.Historical;
        var source=oldNext.Sauce.Historical.Source;
        var sauceOld=oldNext.Sauce.Historical;
        var sauceCorrect=oldNext.Sauce.Patched;

        _validation.ValidateVisibleDropPatch(context,source);
        _validation.ValidateLegacyOverwrittenSauce(context,sauceOld);
        _validation.ValidateProtectedDrop46Sauce(context,oldNext.Sauce);
        _validation.ValidateLegacyFixedNextBowl(context,oldNext);
        _validation.ValidatePatchedNextBowl(context,correctedNext);
        _validation.ValidateLegacyUnsealedBowlQuestion(context,oldQuestion);
        _validation.ValidatePatchedBowlQuestion(context,sealedQuestion);
        _validation.ValidateLegacyOneBasedAnswerStep(context,oneBased);
        _validation.ValidatePatchedAnswerStep(context,step);
        _validation.ValidateLegacyReversedWideRank(context,oldWide);
        _validation.ValidatePatchedWideRank(context,wide);
        _validation.ValidateLegacyInclusiveWideLimit(context,candidate);

        context.PatchedCountsResult=source.Counts;
        context.PatchedStoneRows=source.Stones;
        context.LegacyHiddenReversed=source.ReversedHiddenStorage;
        context.PatchedHiddenAccess=source.HiddenAccessor;
        context.PatchedVisibleDrops=source.Visible;
        context.LegacyDiagnosticDrop46Order=sauceOld.DiagnosticDrop46Order;
        context.LegacyOverwrittenQueryOrder=sauceOld.OverwrittenQueryOrder;
        context.LegacyPostStirOrders=sauceOld.PostStirOrders;
        context.LegacySauceBowlsAfterDrops=sauceOld.BowlsAfterDrops;
        context.LegacySauceFinalBowls=sauceOld.FinalBowls;
        context.PatchedOrderAt46Latch=sauceCorrect.OrderAt46Latch;
        context.PatchedSauceBowlsAfterDrops=sauceCorrect.BowlsAfterDrops;
        context.PatchedSauceFinalBowls=sauceCorrect.FinalBowls;
        context.PatchedPostStirOrders=sauceCorrect.PostStirOrders;
        context.LegacyFixedNextBowlResult=oldNext.LegacyNextBowlId;
        context.PatchedNextBowlResult=correctedNext.NextBowlId;
        context.LegacyUnsealedBowlQuestionResult=oldQuestion.Answer;
        context.PatchedBowlQuestionResult=sealedQuestion.Answer;
        context.LegacyOneBasedAnswerAtResult=oneBased.Value;
        context.PatchedAnswerAtResult=step.Value;
        context.LegacyReversedWideRankResult=oldWide.Rank;
        context.PatchedWideRankResult=wide.Rank;
        context.LegacyInclusiveWideLimitRankResult=candidate.Rank;

        context.BranchTrace.Add("LEGACY_OVERWRITTEN_DROP46_ORDER_WITNESS");
        context.BranchTrace.Add("PROTECTED_DROP46_ORDER_LATCH_WITNESS");
        context.BranchTrace.Add("LEGACY_FIXED_NEXT_BOWL_WITNESS");
        context.BranchTrace.Add("PATCHED_NEXT_BOWL_ORDER_WITNESS");
        context.BranchTrace.Add("LEGACY_UNSEALED_BOWL_QUESTION_WITNESS");
        context.BranchTrace.Add("PATCHED_SEALED_BOWL_QUESTION_WITNESS");
        context.BranchTrace.Add("LEGACY_ONE_BASED_ANSWER_STEP_WITNESS");
        context.BranchTrace.Add("PATCHED_ZERO_BASED_ANSWER_STEP_WITNESS");
        context.BranchTrace.Add("LEGACY_REVERSED_WIDE_DIGITS_WITNESS");
        context.BranchTrace.Add("PATCHED_WIDE_DIGIT_ORDER_WITNESS");
        context.BranchTrace.Add("LEGACY_INCLUSIVE_WIDE_LIMIT");
        _metrics.Bump(context,"legacy.inclusive.wide.limit.dispatch");
        context.Status="LEGACY_INCLUSIVE_WIDE_LIMIT_COMPLETE";
        context.Phase=context.Status;
    }

    public void DispatchPatchedInclusiveWideLimit(MonsterContext context)
    {
        if(context is null ||
           !string.Equals(context.Status,"BOOTSTRAP_READY",StringComparison.Ordinal))
            throw new MonsterValidationException("تتطلب رقعة الحدّ سياقاً مؤسساً.");
        if(context.LegacyQueriedBowlId is not int id || id is < 1 or > 6 ||
           context.LegacyBowlQuestionSeal is not int seal || seal is not (21 or 31) ||
           context.LegacyWideFamilySize is not BigInteger n ||
           n<=((BigInteger.One<<127)-BigInteger.One) ||
           context.LegacyAnswerStepIndex is not BigInteger k || !k.IsZero ||
           context.LegacyInclusiveWideLimitRankResult.HasValue ||
           context.PatchedInclusiveWideLimitRankResult.HasValue ||
           context.PatchedWideRankResult.HasValue ||
           context.LegacyReversedWideRankResult.HasValue ||
           context.PatchedAnswerAtResult.HasValue ||
           context.LegacyOneBasedAnswerAtResult.HasValue ||
           context.PatchedBowlQuestionResult is not null ||
           context.LegacyUnsealedBowlQuestionResult is not null ||
           context.PatchedNextBowlResult.HasValue ||
           context.LegacySauceFinalBowls is not null ||
           context.PatchedSauceFinalBowls is not null ||
           context.PatchedVisibleDrops is not null)
            throw new MonsterValidationException("حالة شاهد الحدّ مكررة أو ناقصة.");

        var candidate=_patchedInclusiveWideLimit.Handle(context);
        var oldCandidate=candidate.Historical;
        var wide=oldCandidate.Previous;
        var oldWide=wide.Historical;
        var step=oldWide.Step;
        var oneBased=step.Historical;
        var sealedQuestion=oneBased.Question;
        var oldQuestion=sealedQuestion.Historical;
        var correctedNext=oldQuestion.Historical;
        var oldNext=correctedNext.Historical;
        var source=oldNext.Sauce.Historical.Source;
        var sauceOld=oldNext.Sauce.Historical;
        var sauceCorrect=oldNext.Sauce.Patched;

        _validation.ValidateVisibleDropPatch(context,source);
        _validation.ValidateLegacyOverwrittenSauce(context,sauceOld);
        _validation.ValidateProtectedDrop46Sauce(context,oldNext.Sauce);
        _validation.ValidateLegacyFixedNextBowl(context,oldNext);
        _validation.ValidatePatchedNextBowl(context,correctedNext);
        _validation.ValidateLegacyUnsealedBowlQuestion(context,oldQuestion);
        _validation.ValidatePatchedBowlQuestion(context,sealedQuestion);
        _validation.ValidateLegacyOneBasedAnswerStep(context,oneBased);
        _validation.ValidatePatchedAnswerStep(context,step);
        _validation.ValidateLegacyReversedWideRank(context,oldWide);
        _validation.ValidatePatchedWideRank(context,wide);
        _validation.ValidateLegacyInclusiveWideLimit(context,oldCandidate);
        _validation.ValidatePatchedInclusiveWideLimit(context,candidate);

        context.PatchedCountsResult=source.Counts;
        context.PatchedStoneRows=source.Stones;
        context.LegacyHiddenReversed=source.ReversedHiddenStorage;
        context.PatchedHiddenAccess=source.HiddenAccessor;
        context.PatchedVisibleDrops=source.Visible;
        context.LegacyDiagnosticDrop46Order=sauceOld.DiagnosticDrop46Order;
        context.LegacyOverwrittenQueryOrder=sauceOld.OverwrittenQueryOrder;
        context.LegacyPostStirOrders=sauceOld.PostStirOrders;
        context.LegacySauceBowlsAfterDrops=sauceOld.BowlsAfterDrops;
        context.LegacySauceFinalBowls=sauceOld.FinalBowls;
        context.PatchedOrderAt46Latch=sauceCorrect.OrderAt46Latch;
        context.PatchedSauceBowlsAfterDrops=sauceCorrect.BowlsAfterDrops;
        context.PatchedSauceFinalBowls=sauceCorrect.FinalBowls;
        context.PatchedPostStirOrders=sauceCorrect.PostStirOrders;
        context.LegacyFixedNextBowlResult=oldNext.LegacyNextBowlId;
        context.PatchedNextBowlResult=correctedNext.NextBowlId;
        context.LegacyUnsealedBowlQuestionResult=oldQuestion.Answer;
        context.PatchedBowlQuestionResult=sealedQuestion.Answer;
        context.LegacyOneBasedAnswerAtResult=oneBased.Value;
        context.PatchedAnswerAtResult=step.Value;
        context.LegacyReversedWideRankResult=oldWide.Rank;
        context.PatchedWideRankResult=wide.Rank;
        context.LegacyInclusiveWideLimitRankResult=oldCandidate.Rank;
        context.PatchedInclusiveWideLimitRankResult=candidate.Rank;

        context.BranchTrace.Add("LEGACY_OVERWRITTEN_DROP46_ORDER_WITNESS");
        context.BranchTrace.Add("PROTECTED_DROP46_ORDER_LATCH_WITNESS");
        context.BranchTrace.Add("LEGACY_FIXED_NEXT_BOWL_WITNESS");
        context.BranchTrace.Add("PATCHED_NEXT_BOWL_ORDER_WITNESS");
        context.BranchTrace.Add("LEGACY_UNSEALED_BOWL_QUESTION_WITNESS");
        context.BranchTrace.Add("PATCHED_SEALED_BOWL_QUESTION_WITNESS");
        context.BranchTrace.Add("LEGACY_ONE_BASED_ANSWER_STEP_WITNESS");
        context.BranchTrace.Add("PATCHED_ZERO_BASED_ANSWER_STEP_WITNESS");
        context.BranchTrace.Add("LEGACY_REVERSED_WIDE_DIGITS_WITNESS");
        context.BranchTrace.Add("PATCHED_WIDE_DIGIT_ORDER_WITNESS");
        context.BranchTrace.Add("LEGACY_INCLUSIVE_WIDE_LIMIT_WITNESS");
        context.BranchTrace.Add("PATCHED_INCLUSIVE_WIDE_LIMIT");
        _metrics.Bump(context,"legacy.inclusive.wide.limit.witness");
        _metrics.Bump(context,"patched.inclusive.wide.limit.dispatch");
        context.Status="PATCHED_INCLUSIVE_WIDE_LIMIT_COMPLETE";
        context.Phase=context.Status;
    }

    public void DispatchLegacyWideRejectionDirection(MonsterContext context)
    {
        if(context is null ||
           !string.Equals(context.Status,"BOOTSTRAP_READY",StringComparison.Ordinal))
            throw new MonsterValidationException("تتطلب رقعة الحدّ سياقاً مؤسساً.");
        if(context.LegacyQueriedBowlId is not int id || id is < 1 or > 6 ||
           context.LegacyBowlQuestionSeal is not int seal || seal is not (21 or 31) ||
           context.LegacyWideFamilySize is not BigInteger n ||
           n<=((BigInteger.One<<127)-BigInteger.One) ||
           context.LegacyAnswerStepIndex is not BigInteger k || !k.IsZero ||
           context.LegacyInclusiveWideLimitRankResult.HasValue ||
           context.PatchedInclusiveWideLimitRankResult.HasValue ||
           context.LegacyRejectionDirectionRankResult.HasValue ||
           context.PatchedWideRankResult.HasValue ||
           context.LegacyReversedWideRankResult.HasValue ||
           context.PatchedAnswerAtResult.HasValue ||
           context.LegacyOneBasedAnswerAtResult.HasValue ||
           context.PatchedBowlQuestionResult is not null ||
           context.LegacyUnsealedBowlQuestionResult is not null ||
           context.PatchedNextBowlResult.HasValue ||
           context.LegacySauceFinalBowls is not null ||
           context.PatchedSauceFinalBowls is not null ||
           context.PatchedVisibleDrops is not null)
            throw new MonsterValidationException("حالة شاهد الحدّ مكررة أو ناقصة.");

        var rejected=_legacyRejectionDirection.Handle(context);
        var candidate=rejected.Previous;
        var oldCandidate=candidate.Historical;
        var wide=oldCandidate.Previous;
        var oldWide=wide.Historical;
        var step=oldWide.Step;
        var oneBased=step.Historical;
        var sealedQuestion=oneBased.Question;
        var oldQuestion=sealedQuestion.Historical;
        var correctedNext=oldQuestion.Historical;
        var oldNext=correctedNext.Historical;
        var source=oldNext.Sauce.Historical.Source;
        var sauceOld=oldNext.Sauce.Historical;
        var sauceCorrect=oldNext.Sauce.Patched;

        _validation.ValidateVisibleDropPatch(context,source);
        _validation.ValidateLegacyOverwrittenSauce(context,sauceOld);
        _validation.ValidateProtectedDrop46Sauce(context,oldNext.Sauce);
        _validation.ValidateLegacyFixedNextBowl(context,oldNext);
        _validation.ValidatePatchedNextBowl(context,correctedNext);
        _validation.ValidateLegacyUnsealedBowlQuestion(context,oldQuestion);
        _validation.ValidatePatchedBowlQuestion(context,sealedQuestion);
        _validation.ValidateLegacyOneBasedAnswerStep(context,oneBased);
        _validation.ValidatePatchedAnswerStep(context,step);
        _validation.ValidateLegacyReversedWideRank(context,oldWide);
        _validation.ValidatePatchedWideRank(context,wide);
        _validation.ValidateLegacyInclusiveWideLimit(context,oldCandidate);
        _validation.ValidatePatchedInclusiveWideLimit(context,candidate);
        _validation.ValidateLegacyWideRejectionDirection(context,rejected);

        context.PatchedCountsResult=source.Counts;
        context.PatchedStoneRows=source.Stones;
        context.LegacyHiddenReversed=source.ReversedHiddenStorage;
        context.PatchedHiddenAccess=source.HiddenAccessor;
        context.PatchedVisibleDrops=source.Visible;
        context.LegacyDiagnosticDrop46Order=sauceOld.DiagnosticDrop46Order;
        context.LegacyOverwrittenQueryOrder=sauceOld.OverwrittenQueryOrder;
        context.LegacyPostStirOrders=sauceOld.PostStirOrders;
        context.LegacySauceBowlsAfterDrops=sauceOld.BowlsAfterDrops;
        context.LegacySauceFinalBowls=sauceOld.FinalBowls;
        context.PatchedOrderAt46Latch=sauceCorrect.OrderAt46Latch;
        context.PatchedSauceBowlsAfterDrops=sauceCorrect.BowlsAfterDrops;
        context.PatchedSauceFinalBowls=sauceCorrect.FinalBowls;
        context.PatchedPostStirOrders=sauceCorrect.PostStirOrders;
        context.LegacyFixedNextBowlResult=oldNext.LegacyNextBowlId;
        context.PatchedNextBowlResult=correctedNext.NextBowlId;
        context.LegacyUnsealedBowlQuestionResult=oldQuestion.Answer;
        context.PatchedBowlQuestionResult=sealedQuestion.Answer;
        context.LegacyOneBasedAnswerAtResult=oneBased.Value;
        context.PatchedAnswerAtResult=step.Value;
        context.LegacyReversedWideRankResult=oldWide.Rank;
        context.PatchedWideRankResult=wide.Rank;
        context.LegacyInclusiveWideLimitRankResult=oldCandidate.Rank;
        context.PatchedInclusiveWideLimitRankResult=candidate.Rank;
        context.LegacyRejectionDirectionRankResult=rejected.Rank;

        context.BranchTrace.Add("LEGACY_OVERWRITTEN_DROP46_ORDER_WITNESS");
        context.BranchTrace.Add("PROTECTED_DROP46_ORDER_LATCH_WITNESS");
        context.BranchTrace.Add("LEGACY_FIXED_NEXT_BOWL_WITNESS");
        context.BranchTrace.Add("PATCHED_NEXT_BOWL_ORDER_WITNESS");
        context.BranchTrace.Add("LEGACY_UNSEALED_BOWL_QUESTION_WITNESS");
        context.BranchTrace.Add("PATCHED_SEALED_BOWL_QUESTION_WITNESS");
        context.BranchTrace.Add("LEGACY_ONE_BASED_ANSWER_STEP_WITNESS");
        context.BranchTrace.Add("PATCHED_ZERO_BASED_ANSWER_STEP_WITNESS");
        context.BranchTrace.Add("LEGACY_REVERSED_WIDE_DIGITS_WITNESS");
        context.BranchTrace.Add("PATCHED_WIDE_DIGIT_ORDER_WITNESS");
        context.BranchTrace.Add("LEGACY_INCLUSIVE_WIDE_LIMIT_WITNESS");
        context.BranchTrace.Add("PATCHED_INCLUSIVE_WIDE_LIMIT_WITNESS");
        context.BranchTrace.Add("LEGACY_WIDE_REJECTION_DIRECTION");
        _metrics.Bump(context,"legacy.inclusive.wide.limit.witness");
        _metrics.Bump(context,"patched.inclusive.wide.limit.witness");
        _metrics.Bump(context,"legacy.wide.rejection.direction.dispatch");
        context.Status="LEGACY_WIDE_REJECTION_DIRECTION_COMPLETE";
        context.Phase=context.Status;
    }

    public void DispatchPatchedRejectionDirection(MonsterContext context)
    {
        if(context is null ||
           !string.Equals(context.Status,"BOOTSTRAP_READY",StringComparison.Ordinal))
            throw new MonsterValidationException("تتطلب رقعة الحدّ سياقاً مؤسساً.");
        if(context.LegacyQueriedBowlId is not int id || id is < 1 or > 6 ||
           context.LegacyBowlQuestionSeal is not int seal || seal is not (21 or 31) ||
           context.LegacyWideFamilySize is not BigInteger n ||
           n<=((BigInteger.One<<127)-BigInteger.One) ||
           context.LegacyAnswerStepIndex is not BigInteger k || !k.IsZero ||
           context.LegacyInclusiveWideLimitRankResult.HasValue ||
           context.PatchedInclusiveWideLimitRankResult.HasValue ||
           context.LegacyRejectionDirectionRankResult.HasValue ||
           context.PatchedRejectionDirectionRankResult.HasValue ||
           context.PatchedWideRankResult.HasValue ||
           context.LegacyReversedWideRankResult.HasValue ||
           context.PatchedAnswerAtResult.HasValue ||
           context.LegacyOneBasedAnswerAtResult.HasValue ||
           context.PatchedBowlQuestionResult is not null ||
           context.LegacyUnsealedBowlQuestionResult is not null ||
           context.PatchedNextBowlResult.HasValue ||
           context.LegacySauceFinalBowls is not null ||
           context.PatchedSauceFinalBowls is not null ||
           context.PatchedVisibleDrops is not null)
            throw new MonsterValidationException("حالة شاهد الحدّ مكررة أو ناقصة.");

        var patched=_patchedRejectionDirection.Handle(context);
        var rejected=patched.Historical;
        var candidate=rejected.Previous;
        var oldCandidate=candidate.Historical;
        var wide=oldCandidate.Previous;
        var oldWide=wide.Historical;
        var step=oldWide.Step;
        var oneBased=step.Historical;
        var sealedQuestion=oneBased.Question;
        var oldQuestion=sealedQuestion.Historical;
        var correctedNext=oldQuestion.Historical;
        var oldNext=correctedNext.Historical;
        var source=oldNext.Sauce.Historical.Source;
        var sauceOld=oldNext.Sauce.Historical;
        var sauceCorrect=oldNext.Sauce.Patched;

        _validation.ValidateVisibleDropPatch(context,source);
        _validation.ValidateLegacyOverwrittenSauce(context,sauceOld);
        _validation.ValidateProtectedDrop46Sauce(context,oldNext.Sauce);
        _validation.ValidateLegacyFixedNextBowl(context,oldNext);
        _validation.ValidatePatchedNextBowl(context,correctedNext);
        _validation.ValidateLegacyUnsealedBowlQuestion(context,oldQuestion);
        _validation.ValidatePatchedBowlQuestion(context,sealedQuestion);
        _validation.ValidateLegacyOneBasedAnswerStep(context,oneBased);
        _validation.ValidatePatchedAnswerStep(context,step);
        _validation.ValidateLegacyReversedWideRank(context,oldWide);
        _validation.ValidatePatchedWideRank(context,wide);
        _validation.ValidateLegacyInclusiveWideLimit(context,oldCandidate);
        _validation.ValidatePatchedInclusiveWideLimit(context,candidate);
        _validation.ValidateLegacyWideRejectionDirection(context,rejected);
        _validation.ValidatePatchedRejectionDirection(context,patched);

        context.PatchedCountsResult=source.Counts;
        context.PatchedStoneRows=source.Stones;
        context.LegacyHiddenReversed=source.ReversedHiddenStorage;
        context.PatchedHiddenAccess=source.HiddenAccessor;
        context.PatchedVisibleDrops=source.Visible;
        context.LegacyDiagnosticDrop46Order=sauceOld.DiagnosticDrop46Order;
        context.LegacyOverwrittenQueryOrder=sauceOld.OverwrittenQueryOrder;
        context.LegacyPostStirOrders=sauceOld.PostStirOrders;
        context.LegacySauceBowlsAfterDrops=sauceOld.BowlsAfterDrops;
        context.LegacySauceFinalBowls=sauceOld.FinalBowls;
        context.PatchedOrderAt46Latch=sauceCorrect.OrderAt46Latch;
        context.PatchedSauceBowlsAfterDrops=sauceCorrect.BowlsAfterDrops;
        context.PatchedSauceFinalBowls=sauceCorrect.FinalBowls;
        context.PatchedPostStirOrders=sauceCorrect.PostStirOrders;
        context.LegacyFixedNextBowlResult=oldNext.LegacyNextBowlId;
        context.PatchedNextBowlResult=correctedNext.NextBowlId;
        context.LegacyUnsealedBowlQuestionResult=oldQuestion.Answer;
        context.PatchedBowlQuestionResult=sealedQuestion.Answer;
        context.LegacyOneBasedAnswerAtResult=oneBased.Value;
        context.PatchedAnswerAtResult=step.Value;
        context.LegacyReversedWideRankResult=oldWide.Rank;
        context.PatchedWideRankResult=wide.Rank;
        context.LegacyInclusiveWideLimitRankResult=oldCandidate.Rank;
        context.PatchedInclusiveWideLimitRankResult=candidate.Rank;
        context.LegacyRejectionDirectionRankResult=rejected.Rank;
        context.PatchedRejectionDirectionRankResult=patched.Rank;

        context.BranchTrace.Add("LEGACY_OVERWRITTEN_DROP46_ORDER_WITNESS");
        context.BranchTrace.Add("PROTECTED_DROP46_ORDER_LATCH_WITNESS");
        context.BranchTrace.Add("LEGACY_FIXED_NEXT_BOWL_WITNESS");
        context.BranchTrace.Add("PATCHED_NEXT_BOWL_ORDER_WITNESS");
        context.BranchTrace.Add("LEGACY_UNSEALED_BOWL_QUESTION_WITNESS");
        context.BranchTrace.Add("PATCHED_SEALED_BOWL_QUESTION_WITNESS");
        context.BranchTrace.Add("LEGACY_ONE_BASED_ANSWER_STEP_WITNESS");
        context.BranchTrace.Add("PATCHED_ZERO_BASED_ANSWER_STEP_WITNESS");
        context.BranchTrace.Add("LEGACY_REVERSED_WIDE_DIGITS_WITNESS");
        context.BranchTrace.Add("PATCHED_WIDE_DIGIT_ORDER_WITNESS");
        context.BranchTrace.Add("LEGACY_INCLUSIVE_WIDE_LIMIT_WITNESS");
        context.BranchTrace.Add("PATCHED_INCLUSIVE_WIDE_LIMIT_WITNESS");
        context.BranchTrace.Add("LEGACY_WIDE_REJECTION_DIRECTION_WITNESS");
        context.BranchTrace.Add("PATCHED_REJECTION_DIRECTION");
        _metrics.Bump(context,"legacy.inclusive.wide.limit.witness");
        _metrics.Bump(context,"patched.inclusive.wide.limit.witness");
        _metrics.Bump(context,"legacy.wide.rejection.direction.witness");
        _metrics.Bump(context,"patched.rejection.direction.dispatch");
        context.Status="PATCHED_REJECTION_DIRECTION_COMPLETE";
        context.Phase=context.Status;
    }

    public void DispatchLegacyDoubleOffsetWideRank(MonsterContext context)
    {
        if(context is null ||
           !string.Equals(context.Status,"BOOTSTRAP_READY",StringComparison.Ordinal))
            throw new MonsterValidationException("تتطلب رقعة الحدّ سياقاً مؤسساً.");
        if(context.LegacyQueriedBowlId is not int id || id is < 1 or > 6 ||
           context.LegacyBowlQuestionSeal is not int seal || seal is not (21 or 31) ||
           context.LegacyWideFamilySize is not BigInteger n ||
           n<=((BigInteger.One<<127)-BigInteger.One) ||
           context.LegacyAnswerStepIndex is not BigInteger k || !k.IsZero ||
           context.LegacyInclusiveWideLimitRankResult.HasValue ||
           context.PatchedInclusiveWideLimitRankResult.HasValue ||
           context.LegacyRejectionDirectionRankResult.HasValue ||
           context.PatchedRejectionDirectionRankResult.HasValue ||
           context.LegacyDoubleOffsetWideRankResult.HasValue ||
           context.PatchedWideRankResult.HasValue ||
           context.LegacyReversedWideRankResult.HasValue ||
           context.PatchedAnswerAtResult.HasValue ||
           context.LegacyOneBasedAnswerAtResult.HasValue ||
           context.PatchedBowlQuestionResult is not null ||
           context.LegacyUnsealedBowlQuestionResult is not null ||
           context.PatchedNextBowlResult.HasValue ||
           context.LegacySauceFinalBowls is not null ||
           context.PatchedSauceFinalBowls is not null ||
           context.PatchedVisibleDrops is not null)
            throw new MonsterValidationException("حالة شاهد الحدّ مكررة أو ناقصة.");

        var output=_doubleOffsetWideRank.Handle(context);
        var patched=output.Previous;
        var rejected=patched.Historical;
        var candidate=rejected.Previous;
        var oldCandidate=candidate.Historical;
        var wide=oldCandidate.Previous;
        var oldWide=wide.Historical;
        var step=oldWide.Step;
        var oneBased=step.Historical;
        var sealedQuestion=oneBased.Question;
        var oldQuestion=sealedQuestion.Historical;
        var correctedNext=oldQuestion.Historical;
        var oldNext=correctedNext.Historical;
        var source=oldNext.Sauce.Historical.Source;
        var sauceOld=oldNext.Sauce.Historical;
        var sauceCorrect=oldNext.Sauce.Patched;

        _validation.ValidateVisibleDropPatch(context,source);
        _validation.ValidateLegacyOverwrittenSauce(context,sauceOld);
        _validation.ValidateProtectedDrop46Sauce(context,oldNext.Sauce);
        _validation.ValidateLegacyFixedNextBowl(context,oldNext);
        _validation.ValidatePatchedNextBowl(context,correctedNext);
        _validation.ValidateLegacyUnsealedBowlQuestion(context,oldQuestion);
        _validation.ValidatePatchedBowlQuestion(context,sealedQuestion);
        _validation.ValidateLegacyOneBasedAnswerStep(context,oneBased);
        _validation.ValidatePatchedAnswerStep(context,step);
        _validation.ValidateLegacyReversedWideRank(context,oldWide);
        _validation.ValidatePatchedWideRank(context,wide);
        _validation.ValidateLegacyInclusiveWideLimit(context,oldCandidate);
        _validation.ValidatePatchedInclusiveWideLimit(context,candidate);
        _validation.ValidateLegacyWideRejectionDirection(context,rejected);
        _validation.ValidatePatchedRejectionDirection(context,patched);
        _validation.ValidateLegacyDoubleOffsetWideRank(context,output);

        context.PatchedCountsResult=source.Counts;
        context.PatchedStoneRows=source.Stones;
        context.LegacyHiddenReversed=source.ReversedHiddenStorage;
        context.PatchedHiddenAccess=source.HiddenAccessor;
        context.PatchedVisibleDrops=source.Visible;
        context.LegacyDiagnosticDrop46Order=sauceOld.DiagnosticDrop46Order;
        context.LegacyOverwrittenQueryOrder=sauceOld.OverwrittenQueryOrder;
        context.LegacyPostStirOrders=sauceOld.PostStirOrders;
        context.LegacySauceBowlsAfterDrops=sauceOld.BowlsAfterDrops;
        context.LegacySauceFinalBowls=sauceOld.FinalBowls;
        context.PatchedOrderAt46Latch=sauceCorrect.OrderAt46Latch;
        context.PatchedSauceBowlsAfterDrops=sauceCorrect.BowlsAfterDrops;
        context.PatchedSauceFinalBowls=sauceCorrect.FinalBowls;
        context.PatchedPostStirOrders=sauceCorrect.PostStirOrders;
        context.LegacyFixedNextBowlResult=oldNext.LegacyNextBowlId;
        context.PatchedNextBowlResult=correctedNext.NextBowlId;
        context.LegacyUnsealedBowlQuestionResult=oldQuestion.Answer;
        context.PatchedBowlQuestionResult=sealedQuestion.Answer;
        context.LegacyOneBasedAnswerAtResult=oneBased.Value;
        context.PatchedAnswerAtResult=step.Value;
        context.LegacyReversedWideRankResult=oldWide.Rank;
        context.PatchedWideRankResult=wide.Rank;
        context.LegacyInclusiveWideLimitRankResult=oldCandidate.Rank;
        context.PatchedInclusiveWideLimitRankResult=candidate.Rank;
        context.LegacyRejectionDirectionRankResult=rejected.Rank;
        context.PatchedRejectionDirectionRankResult=patched.Rank;
        context.LegacyDoubleOffsetWideRankResult=output.Rank;

        context.BranchTrace.Add("LEGACY_OVERWRITTEN_DROP46_ORDER_WITNESS");
        context.BranchTrace.Add("PROTECTED_DROP46_ORDER_LATCH_WITNESS");
        context.BranchTrace.Add("LEGACY_FIXED_NEXT_BOWL_WITNESS");
        context.BranchTrace.Add("PATCHED_NEXT_BOWL_ORDER_WITNESS");
        context.BranchTrace.Add("LEGACY_UNSEALED_BOWL_QUESTION_WITNESS");
        context.BranchTrace.Add("PATCHED_SEALED_BOWL_QUESTION_WITNESS");
        context.BranchTrace.Add("LEGACY_ONE_BASED_ANSWER_STEP_WITNESS");
        context.BranchTrace.Add("PATCHED_ZERO_BASED_ANSWER_STEP_WITNESS");
        context.BranchTrace.Add("LEGACY_REVERSED_WIDE_DIGITS_WITNESS");
        context.BranchTrace.Add("PATCHED_WIDE_DIGIT_ORDER_WITNESS");
        context.BranchTrace.Add("LEGACY_INCLUSIVE_WIDE_LIMIT_WITNESS");
        context.BranchTrace.Add("PATCHED_INCLUSIVE_WIDE_LIMIT_WITNESS");
        context.BranchTrace.Add("LEGACY_WIDE_REJECTION_DIRECTION_WITNESS");
        context.BranchTrace.Add("PATCHED_REJECTION_DIRECTION_WITNESS");
        context.BranchTrace.Add("LEGACY_DOUBLE_OFFSET_WIDE_RANK");
        _metrics.Bump(context,"legacy.wide.rejection.direction.witness");
        _metrics.Bump(context,"patched.rejection.direction.witness");
        _metrics.Bump(context,"patched.inclusive.wide.limit.witness");
        _metrics.Bump(context,"legacy.double.offset.wide.rank.dispatch");
        context.Status="LEGACY_DOUBLE_OFFSET_WIDE_RANK_COMPLETE";
        context.Phase=context.Status;
    }

    public void DispatchPatchedDoubleOffsetWideRank(MonsterContext context)
    {
        if(context is null ||
           !string.Equals(context.Status,"BOOTSTRAP_READY",StringComparison.Ordinal))
            throw new MonsterValidationException("تتطلب رقعة الحدّ سياقاً مؤسساً.");
        if(context.LegacyQueriedBowlId is not int id || id is < 1 or > 6 ||
           context.LegacyBowlQuestionSeal is not int seal || seal is not (21 or 31) ||
           context.LegacyWideFamilySize is not BigInteger n ||
           n<=((BigInteger.One<<127)-BigInteger.One) ||
           context.LegacyAnswerStepIndex is not BigInteger k || !k.IsZero ||
           context.LegacyInclusiveWideLimitRankResult.HasValue ||
           context.PatchedInclusiveWideLimitRankResult.HasValue ||
           context.LegacyRejectionDirectionRankResult.HasValue ||
           context.PatchedRejectionDirectionRankResult.HasValue ||
           context.LegacyDoubleOffsetWideRankResult.HasValue ||
           context.PatchedDoubleOffsetWideRankResult.HasValue ||
           context.PatchedWideRankResult.HasValue ||
           context.LegacyReversedWideRankResult.HasValue ||
           context.PatchedAnswerAtResult.HasValue ||
           context.LegacyOneBasedAnswerAtResult.HasValue ||
           context.PatchedBowlQuestionResult is not null ||
           context.LegacyUnsealedBowlQuestionResult is not null ||
           context.PatchedNextBowlResult.HasValue ||
           context.LegacySauceFinalBowls is not null ||
           context.PatchedSauceFinalBowls is not null ||
           context.PatchedVisibleDrops is not null)
            throw new MonsterValidationException("حالة شاهد الحدّ مكررة أو ناقصة.");

        var candidate39=_patchedDoubleOffsetWideRank.Handle(context);
        var output=candidate39.Historical;
        var patched=output.Previous;
        var rejected=patched.Historical;
        var candidate=rejected.Previous;
        var oldCandidate=candidate.Historical;
        var wide=oldCandidate.Previous;
        var oldWide=wide.Historical;
        var step=oldWide.Step;
        var oneBased=step.Historical;
        var sealedQuestion=oneBased.Question;
        var oldQuestion=sealedQuestion.Historical;
        var correctedNext=oldQuestion.Historical;
        var oldNext=correctedNext.Historical;
        var source=oldNext.Sauce.Historical.Source;
        var sauceOld=oldNext.Sauce.Historical;
        var sauceCorrect=oldNext.Sauce.Patched;

        _validation.ValidateVisibleDropPatch(context,source);
        _validation.ValidateLegacyOverwrittenSauce(context,sauceOld);
        _validation.ValidateProtectedDrop46Sauce(context,oldNext.Sauce);
        _validation.ValidateLegacyFixedNextBowl(context,oldNext);
        _validation.ValidatePatchedNextBowl(context,correctedNext);
        _validation.ValidateLegacyUnsealedBowlQuestion(context,oldQuestion);
        _validation.ValidatePatchedBowlQuestion(context,sealedQuestion);
        _validation.ValidateLegacyOneBasedAnswerStep(context,oneBased);
        _validation.ValidatePatchedAnswerStep(context,step);
        _validation.ValidateLegacyReversedWideRank(context,oldWide);
        _validation.ValidatePatchedWideRank(context,wide);
        _validation.ValidateLegacyInclusiveWideLimit(context,oldCandidate);
        _validation.ValidatePatchedInclusiveWideLimit(context,candidate);
        _validation.ValidateLegacyWideRejectionDirection(context,rejected);
        _validation.ValidatePatchedRejectionDirection(context,patched);
        _validation.ValidateLegacyDoubleOffsetWideRank(context,output);
        _validation.ValidatePatchedDoubleOffsetWideRank(context,candidate39);

        context.PatchedCountsResult=source.Counts;
        context.PatchedStoneRows=source.Stones;
        context.LegacyHiddenReversed=source.ReversedHiddenStorage;
        context.PatchedHiddenAccess=source.HiddenAccessor;
        context.PatchedVisibleDrops=source.Visible;
        context.LegacyDiagnosticDrop46Order=sauceOld.DiagnosticDrop46Order;
        context.LegacyOverwrittenQueryOrder=sauceOld.OverwrittenQueryOrder;
        context.LegacyPostStirOrders=sauceOld.PostStirOrders;
        context.LegacySauceBowlsAfterDrops=sauceOld.BowlsAfterDrops;
        context.LegacySauceFinalBowls=sauceOld.FinalBowls;
        context.PatchedOrderAt46Latch=sauceCorrect.OrderAt46Latch;
        context.PatchedSauceBowlsAfterDrops=sauceCorrect.BowlsAfterDrops;
        context.PatchedSauceFinalBowls=sauceCorrect.FinalBowls;
        context.PatchedPostStirOrders=sauceCorrect.PostStirOrders;
        context.LegacyFixedNextBowlResult=oldNext.LegacyNextBowlId;
        context.PatchedNextBowlResult=correctedNext.NextBowlId;
        context.LegacyUnsealedBowlQuestionResult=oldQuestion.Answer;
        context.PatchedBowlQuestionResult=sealedQuestion.Answer;
        context.LegacyOneBasedAnswerAtResult=oneBased.Value;
        context.PatchedAnswerAtResult=step.Value;
        context.LegacyReversedWideRankResult=oldWide.Rank;
        context.PatchedWideRankResult=wide.Rank;
        context.LegacyInclusiveWideLimitRankResult=oldCandidate.Rank;
        context.PatchedInclusiveWideLimitRankResult=candidate.Rank;
        context.LegacyRejectionDirectionRankResult=rejected.Rank;
        context.PatchedRejectionDirectionRankResult=patched.Rank;
        context.LegacyDoubleOffsetWideRankResult=output.Rank;
        context.PatchedDoubleOffsetWideRankResult=candidate39.Rank;

        context.BranchTrace.Add("LEGACY_OVERWRITTEN_DROP46_ORDER_WITNESS");
        context.BranchTrace.Add("PROTECTED_DROP46_ORDER_LATCH_WITNESS");
        context.BranchTrace.Add("LEGACY_FIXED_NEXT_BOWL_WITNESS");
        context.BranchTrace.Add("PATCHED_NEXT_BOWL_ORDER_WITNESS");
        context.BranchTrace.Add("LEGACY_UNSEALED_BOWL_QUESTION_WITNESS");
        context.BranchTrace.Add("PATCHED_SEALED_BOWL_QUESTION_WITNESS");
        context.BranchTrace.Add("LEGACY_ONE_BASED_ANSWER_STEP_WITNESS");
        context.BranchTrace.Add("PATCHED_ZERO_BASED_ANSWER_STEP_WITNESS");
        context.BranchTrace.Add("LEGACY_REVERSED_WIDE_DIGITS_WITNESS");
        context.BranchTrace.Add("PATCHED_WIDE_DIGIT_ORDER_WITNESS");
        context.BranchTrace.Add("LEGACY_INCLUSIVE_WIDE_LIMIT_WITNESS");
        context.BranchTrace.Add("PATCHED_INCLUSIVE_WIDE_LIMIT_WITNESS");
        context.BranchTrace.Add("LEGACY_WIDE_REJECTION_DIRECTION_WITNESS");
        context.BranchTrace.Add("PATCHED_REJECTION_DIRECTION_WITNESS");
        context.BranchTrace.Add("LEGACY_DOUBLE_OFFSET_WIDE_RANK_WITNESS");
        context.BranchTrace.Add("PATCHED_DOUBLE_OFFSET_WIDE_RANK");
        _metrics.Bump(context,"legacy.wide.rejection.direction.witness");
        _metrics.Bump(context,"patched.rejection.direction.witness");
        _metrics.Bump(context,"patched.inclusive.wide.limit.witness");
        _metrics.Bump(context,"legacy.double.offset.wide.rank.witness");
        _metrics.Bump(context,"patched.double.offset.wide.rank.dispatch");
        context.Status="PATCHED_DOUBLE_OFFSET_WIDE_RANK_COMPLETE";
        context.Phase=context.Status;
    }

    public void DispatchSavePatched(MonsterContext context)
    {
        if (!string.Equals(context.Status, "BOOTSTRAP_READY", StringComparison.Ordinal))
            throw new MonsterValidationException("يتطلب مسار الرقعة سياقاً جديداً أتمّ التأسيس.");
        if (context.LegacySaveInput is not BigInteger input)
            throw new MonsterValidationException("لم تُقدَّم قيمة لحفظ الرقعة.");

        // يستمر المعالج القديم في العمل الفعلي، ولا تُمحى نتيجته الخاطئة.
        DispatchLegacySave(context);

        // تُحسب القيمة المرشحة وتُفحص قبل تثبيتها في الحالة الدلالية.
        context.Phase = "SAVE_PATCH_VALIDATION";
        var pending = _savePatch.SavePatch(input);
        _validation.ValidateSavePatchResult(context, pending);
        context.PatchedSaveResult = pending;

        context.BranchTrace.Add("SAVE_PATCH");
        _metrics.Bump(context, "save.patch.dispatch");
        context.Status = "SAVE_PATCH_COMPLETE";
        context.Phase = "SAVE_PATCH_COMPLETE";
    }
}

public sealed class MonsterManager
{
    private readonly MonsterDispatcher _dispatcher;

    public MonsterManager()
    {
        var validation = new MonsterValidationManager();
        var metrics = new MonsterMetricsManager();
        _dispatcher = new MonsterDispatcher(validation, metrics);
    }

    public MonsterContext Prepare(BigInteger calculationDay, BigInteger targetDay)
    {
        var context = new MonsterContext(calculationDay, targetDay) { RetryBudget = 0 };
        _dispatcher.DispatchBootstrap(context);
        return context;
    }

    public BigInteger EvaluateLegacySave(BigInteger calculationDay, BigInteger targetDay, BigInteger value)
    {
        var context = Prepare(calculationDay, targetDay);
        context.LegacySaveInput = value;
        _dispatcher.DispatchLegacySave(context);
        return context.LegacySaveResult
            ?? throw new MonsterValidationException("لم يُنتج مسار الحفظ القديم قيمة.");
    }

    public MonsterContext ExecuteSavePatched(BigInteger calculationDay, BigInteger targetDay, BigInteger value)
    {
        var context = Prepare(calculationDay, targetDay);
        context.LegacySaveInput = value;
        _dispatcher.DispatchSavePatched(context);
        return context;
    }

    public MonsterContext ExecuteLegacyDayTag(BigInteger calculationDay, BigInteger targetDay, BigInteger day)
    {
        var context = Prepare(calculationDay, targetDay);
        context.LegacyDayInput = day;
        _dispatcher.DispatchLegacyDayTag(context);
        return context;
    }

    public BigInteger EvaluateLegacyDayTag(BigInteger calculationDay, BigInteger targetDay, BigInteger day)
    {
        var context = ExecuteLegacyDayTag(calculationDay, targetDay, day);
        return context.LegacyDayTagResult
            ?? throw new MonsterValidationException("لم يُنتج مسار اليوم القديم عدّاً.");
    }

    public MonsterContext ExecuteDayTagPatched(BigInteger calculationDay, BigInteger targetDay, BigInteger day)
    {
        var context = Prepare(calculationDay, targetDay);
        context.LegacyDayInput = day;
        _dispatcher.DispatchDayTagPatched(context);
        return context;
    }

    public BigInteger EvaluateDayTag(BigInteger calculationDay, BigInteger targetDay, BigInteger day)
    {
        var context = ExecuteDayTagPatched(calculationDay, targetDay, day);
        return context.PatchedDayTagResult
            ?? throw new MonsterValidationException("لم تُنتج رقعة عدّ اليوم قيمةً.");
    }

    public MonsterContext ExecuteLegacyDistance(BigInteger calculationDay, BigInteger targetDay)
    {
        var context = Prepare(calculationDay, targetDay);
        _dispatcher.DispatchLegacyDistance(context);
        return context;
    }

    public BigInteger EvaluateLegacyDistance(BigInteger calculationDay, BigInteger targetDay)
    {
        var context = ExecuteLegacyDistance(calculationDay, targetDay);
        return context.LegacyDistanceResult
            ?? throw new MonsterValidationException("لم يُنتج المسار التاريخي مسافةً.");
    }

    public MonsterContext ExecutePatchedCounts(BigInteger calculationDay, BigInteger targetDay)
    {
        var context = Prepare(calculationDay, targetDay);
        _dispatcher.DispatchPatchedCounts(context);
        return context;
    }

    public MonsterWorkCounts EvaluateWorkCounts(BigInteger calculationDay, BigInteger targetDay)
    {
        var context = ExecutePatchedCounts(calculationDay, targetDay);
        return context.PatchedCountsResult
            ?? throw new MonsterValidationException("لم تُثبت رقعة المسافة خماسية حساب.");
    }

    public MonsterContext ExecuteLegacyStones(BigInteger calculationDay, BigInteger targetDay)
    {
        var context = Prepare(calculationDay, targetDay);
        _dispatcher.DispatchLegacyStones(context);
        return context;
    }

    public BigInteger[][] EvaluateLegacyStones(BigInteger calculationDay, BigInteger targetDay)
    {
        var context = ExecuteLegacyStones(calculationDay, targetDay);
        return context.LegacyStoneRows
            ?? throw new MonsterValidationException("لم يُنتج المسار التاريخي صفوف الأحجار.");
    }

    public MonsterContext ExecutePatchedStones(BigInteger calculationDay, BigInteger targetDay)
    {
        var context = Prepare(calculationDay, targetDay);
        _dispatcher.DispatchPatchedStones(context);
        return context;
    }

    public BigInteger[][] EvaluatePatchedStones(BigInteger calculationDay, BigInteger targetDay)
    {
        var context = ExecutePatchedStones(calculationDay, targetDay);
        return context.PatchedStoneRows
            ?? throw new MonsterValidationException("لم تُثبت صفوف الأحجار في الرقعة الرابعة.");
    }

    public MonsterContext ExecuteLegacyHiddenDrops(BigInteger calculationDay, BigInteger targetDay)
    {
        var context = Prepare(calculationDay, targetDay);
        _dispatcher.DispatchLegacyHiddenDrops(context);
        return context;
    }

    public BigInteger[] EvaluateLegacyHiddenDrops(BigInteger calculationDay, BigInteger targetDay)
    {
        var context = ExecuteLegacyHiddenDrops(calculationDay, targetDay);
        return context.LegacyHiddenReversed
            ?? throw new MonsterValidationException("لم تُثبَّت القطرات التاريخية المعكوسة.");
    }

    public MonsterContext ExecutePatchedHiddenAccess(BigInteger calculationDay, BigInteger targetDay)
    {
        var context = Prepare(calculationDay, targetDay);
        _dispatcher.DispatchPatchedHiddenAccess(context);
        return context;
    }

    public BigInteger EvaluateHiddenDrop(BigInteger calculationDay, BigInteger targetDay, int k)
    {
        if (k is < 1 or > 7)
            throw new MonsterValidationException("رتبة قرب القطرة المطلوبة خارج المجال.");
        var context = ExecutePatchedHiddenAccess(calculationDay, targetDay);
        return context.PatchedHiddenAccess?.HiddenByNearness(k)
            ?? throw new MonsterValidationException("لم تُثبَّت رقعة الوصول إلى القطرات الخفية.");
    }

    public MonsterContext ExecuteLegacyPrior(
        BigInteger calculationDay, BigInteger targetDay,
        BigInteger[] dropStore, int i, int back)
    {
        if (dropStore is null || dropStore.Length != 47 ||
            dropStore[0] != BigInteger.Zero)
            throw new MonsterValidationException("مخزن القطرات الظاهرة المطلوب غير صالح.");
        if (i is < 1 or > 46 || back is not (1 or 3 or 7))
            throw new MonsterValidationException("رقم القطرة أو الرجوع غير صالح.");

        var context = Prepare(calculationDay, targetDay);
        context.LegacyPriorDropStore = (BigInteger[])dropStore.Clone();
        context.LegacyPriorVisibleIndex = i;
        context.LegacyPriorBack = back;
        _dispatcher.DispatchLegacyPrior(context);
        return context;
    }

    public BigInteger EvaluateLegacyPrior(
        BigInteger calculationDay, BigInteger targetDay,
        BigInteger[] dropStore, int i, int back)
    {
        var context = ExecuteLegacyPrior(calculationDay, targetDay, dropStore, i, back);
        return context.LegacyPriorResult
            ?? throw new MonsterValidationException("لم تُنتج القراءة التاريخية قيمة قطرة.");
    }

    public MonsterContext ExecutePatchedPrior(
        BigInteger calculationDay, BigInteger targetDay,
        BigInteger[] dropStore, int i, int back)
    {
        if (dropStore is null || dropStore.Length != 47 ||
            dropStore[0] != BigInteger.Zero ||
            i is < 1 or > 46 || back is not (1 or 3 or 7))
            throw new MonsterValidationException("مدخلات الرجوع إلى القطرة غير صحيحة.");

        var context = Prepare(calculationDay, targetDay);
        context.LegacyPriorDropStore = (BigInteger[])dropStore.Clone();
        context.LegacyPriorVisibleIndex = i;
        context.LegacyPriorBack = back;
        _dispatcher.DispatchPatchedPrior(context);
        return context;
    }

    public BigInteger EvaluatePrior(
        BigInteger calculationDay, BigInteger targetDay,
        BigInteger[] dropStore, int i, int back)
    {
        var context = ExecutePatchedPrior(calculationDay, targetDay, dropStore, i, back);
        return context.PatchedPriorResult
            ?? throw new MonsterValidationException("لم تُثبت نتيجة الرجوع المصححة.");
    }

    public MonsterContext ExecuteLegacyVisibleGrind(
        BigInteger calculationDay, BigInteger targetDay, int ordinal)
    {
        if (ordinal is < 1 or > 11)
            throw new MonsterValidationException("الطحن المطلوب خارج الأرقام الإحدى عشرة.");
        var context = Prepare(calculationDay, targetDay);
        context.LegacyGrindOrdinal = ordinal;
        _dispatcher.DispatchLegacyVisibleGrind(context);
        return context;
    }

    public LegacyGrindRow EvaluateLegacyVisibleGrind(
        BigInteger calculationDay, BigInteger targetDay, int ordinal)
    {
        var context = ExecuteLegacyVisibleGrind(calculationDay, targetDay, ordinal);
        return context.LegacyGrindResult
            ?? throw new MonsterValidationException("لم يُنتج مسار الطحن القديم صفّاً.");
    }

    public MonsterContext ExecutePatchedVisibleDrops(
        BigInteger calculationDay, BigInteger targetDay)
    {
        var context = Prepare(calculationDay, targetDay);
        _dispatcher.DispatchVisibleDropsPatched(context);
        return context;
    }

    public BigInteger[] EvaluateVisibleDrops(BigInteger calculationDay, BigInteger targetDay)
    {
        var context = ExecutePatchedVisibleDrops(calculationDay, targetDay);
        return context.PatchedVisibleDrops
            ?? throw new MonsterValidationException("لم تُثبت القطرات الظاهرة بعد رقعة الحارس.");
    }

    public BigInteger EvaluateVisibleDrop(BigInteger calculationDay, BigInteger targetDay, int i)
    {
        if (i is < 1 or > 46)
            throw new MonsterValidationException("رقم القطرة الظاهرة خارج المجال.");
        var context = ExecutePatchedVisibleDrops(calculationDay, targetDay);
        return context.PatchedVisibleDrops?[i]
            ?? throw new MonsterValidationException("لم تُثبت القطرة الظاهرة المطلوبة.");
    }

    public MonsterContext ExecuteLegacyBowlOrder(
        BigInteger calculationDay, BigInteger targetDay, BigInteger dropValue)
    {
        var context = Prepare(calculationDay, targetDay);
        context.LegacyBowlOrderInput = dropValue;
        _dispatcher.DispatchLegacyBowlOrder(context);
        return context;
    }

    public int[] EvaluateLegacyBowlOrder(
        BigInteger calculationDay, BigInteger targetDay, BigInteger dropValue)
    {
        var context = ExecuteLegacyBowlOrder(calculationDay, targetDay, dropValue);
        return context.LegacyBowlOrderResult ??
            throw new MonsterValidationException("لم يُنتج ترتيب الأوعية القديم.");
    }

    public MonsterContext ExecuteLegacyBowlOrderFromVisibleDrop(
        BigInteger calculationDay, BigInteger targetDay, int index)
    {
        if (index is < 1 or > 46)
            throw new MonsterValidationException("رقم القطرة الظاهرة خارج المجال.");

        // هذه القطرة تأتي من سلسلة الطحْن المصححة فعلياً، لا من مرجع الاختبار.
        var dropValue = EvaluateVisibleDrop(calculationDay, targetDay, index);
        var context = Prepare(calculationDay, targetDay);
        context.LegacyBowlVisibleIndex = index;
        context.LegacyBowlOrderInput = dropValue;
        _dispatcher.DispatchLegacyBowlOrder(context);
        return context;
    }

    public int[] EvaluateLegacyBowlOrderFromVisibleDrop(
        BigInteger calculationDay, BigInteger targetDay, int index)
    {
        return ExecuteLegacyBowlOrderFromVisibleDrop(calculationDay, targetDay, index)
            .LegacyBowlOrderResult ?? throw new MonsterValidationException(
                "لم يُنتج ترتيب الأوعية من القطرة الظاهرة.");
    }

    public MonsterContext ExecutePatchedBowlOrder(
        BigInteger calculationDay, BigInteger targetDay, BigInteger dropValue)
    {
        var context = Prepare(calculationDay, targetDay);
        context.LegacyBowlOrderInput = dropValue;
        _dispatcher.DispatchBowlOrderPatched(context);
        return context;
    }

    public int[] EvaluateBowlOrder(
        BigInteger calculationDay, BigInteger targetDay, BigInteger dropValue)
    {
        return ExecutePatchedBowlOrder(calculationDay, targetDay, dropValue)
            .PatchedBowlOrderResult
            ?? throw new MonsterValidationException("لم يُثبت ترتيب الأوعية المصحح.");
    }

    public MonsterContext ExecutePatchedBowlOrderFromVisibleDrop(
        BigInteger calculationDay, BigInteger targetDay, int index)
    {
        if (index is < 1 or > 46)
            throw new MonsterValidationException("موضع القطرة الظاهرة خارج المجال.");
        var drop = EvaluateVisibleDrop(calculationDay, targetDay, index);
        var context = Prepare(calculationDay, targetDay);
        context.LegacyBowlVisibleIndex = index;
        context.LegacyBowlOrderInput = drop;
        _dispatcher.DispatchBowlOrderPatched(context);
        return context;
    }

    public int[] EvaluateBowlOrderFromVisibleDrop(
        BigInteger calculationDay, BigInteger targetDay, int index)
    {
        return ExecutePatchedBowlOrderFromVisibleDrop(
            calculationDay, targetDay, index).PatchedBowlOrderResult
            ?? throw new MonsterValidationException("لم يُنتج ترتيب القطرة الظاهرة.");
    }

    public MonsterContext ExecuteLegacyFixedBowlPours(
        BigInteger calculationDay, BigInteger targetDay, int visibleIndex)
    {
        if (visibleIndex is < 1 or > 46)
            throw new MonsterValidationException("موضع القطرة المرئية للصبّ خارج المجال.");
        var context = Prepare(calculationDay, targetDay);
        context.LegacyPourVisibleIndex = visibleIndex;
        _dispatcher.DispatchLegacyPours(context);
        return context;
    }

    public BigInteger[] EvaluateLegacyFixedBowlPours(
        BigInteger calculationDay, BigInteger targetDay, int visibleIndex)
    {
        return ExecuteLegacyFixedBowlPours(calculationDay, targetDay, visibleIndex)
            .LegacyPoursResult ?? throw new MonsterValidationException(
                "لم تُثبَت المزائج القديمة للأوعية الثلاثة.");
    }

    public MonsterContext ExecutePatchedBowlPours(
        BigInteger calculationDay,BigInteger targetDay,int visibleIndex)
    {
        if (visibleIndex is < 1 or > 46)
            throw new MonsterValidationException("القطرة المطلوبة للصبّ المصحح خارج المجال.");
        var context=Prepare(calculationDay,targetDay);
        context.LegacyPourVisibleIndex=visibleIndex;
        _dispatcher.DispatchBowlAliasPatched(context);
        return context;
    }

    public BigInteger[] EvaluatePatchedBowlPours(
        BigInteger calculationDay,BigInteger targetDay,int visibleIndex)
        => ExecutePatchedBowlPours(calculationDay,targetDay,visibleIndex)
            .PatchedPoursResult ??
            throw new MonsterValidationException("لم تُثبت الصبّات المصححة للأوعية.");

    public MonsterContext ExecuteLegacyInPlaceStir(
        BigInteger calculationDay,BigInteger targetDay,int visibleIndex)
    {
        if (visibleIndex is < 1 or > 46)
            throw new MonsterValidationException("موضع القطرة المطلوبة للتحريك خارج المجال.");
        var context=Prepare(calculationDay,targetDay);
        context.LegacyPourVisibleIndex=visibleIndex;
        _dispatcher.DispatchLegacyInPlaceStir(context);
        return context;
    }

    public BigInteger[] EvaluateLegacyInPlaceStir(
        BigInteger calculationDay,BigInteger targetDay,int visibleIndex)
        => ExecuteLegacyInPlaceStir(calculationDay,targetDay,visibleIndex)
            .LegacyStirredBowls ??
            throw new MonsterValidationException("لم تُنتج أوعية التحريك التاريخية.");

    public MonsterContext ExecutePatchedBowlStir(
        BigInteger calculationDay,BigInteger targetDay,int visibleIndex)
    {
        if(visibleIndex is < 1 or > 46)
            throw new MonsterValidationException("موضع القطرة للتحريك بالظل خارج المجال.");
        var context=Prepare(calculationDay,targetDay);
        context.LegacyPourVisibleIndex=visibleIndex;
        _dispatcher.DispatchShadowBowlStir(context);
        return context;
    }

    public BigInteger[] EvaluatePatchedBowlStir(
        BigInteger calculationDay,BigInteger targetDay,int visibleIndex)
        => ExecutePatchedBowlStir(calculationDay,targetDay,visibleIndex)
            .PatchedStirredBowls ??
            throw new MonsterValidationException("لم تُنتج أوعية التحريك المصححة.");

    public MonsterContext ExecuteLegacyOverwrittenSauce(
        BigInteger calculationDay,BigInteger targetDay)
    {
        var context=Prepare(calculationDay,targetDay);
        _dispatcher.DispatchLegacyOverwrittenSauce(context);
        return context;
    }

    public LegacySauceResult EvaluateLegacyOverwrittenSauce(
        BigInteger calculationDay,BigInteger targetDay)
    {
        var context=ExecuteLegacyOverwrittenSauce(calculationDay,targetDay);
        if(context.LegacySauceFinalBowls is null ||
           context.LegacyOverwrittenQueryOrder is null)
            throw new MonsterValidationException("لم تكتمل الصلصة القديمة.");
        return new LegacySauceResult(
            (BigInteger[])context.LegacySauceFinalBowls.Clone(),
            (int[])context.LegacyOverwrittenQueryOrder.Clone());
    }

    public MonsterContext ExecuteProtectedDrop46Sauce(
        BigInteger calculationDay,BigInteger targetDay)
    {
        var context=Prepare(calculationDay,targetDay);
        _dispatcher.DispatchProtectedDrop46Sauce(context);
        return context;
    }

    public LegacySauceResult EvaluateLatchedSauce(
        BigInteger calculationDay,BigInteger targetDay)
    {
        var context=ExecuteProtectedDrop46Sauce(calculationDay,targetDay);
        if(context.PatchedSauceFinalBowls is null ||
           context.PatchedOrderAt46Latch is null)
            throw new MonsterValidationException("لم تُعتمد الصلصة ذات الالتقاط المحمي.");
        return new LegacySauceResult(
            (BigInteger[])context.PatchedSauceFinalBowls.Clone(),
            (int[])context.PatchedOrderAt46Latch.Clone());
    }


    public MonsterContext ExecuteLegacyFixedNextBowl(
        BigInteger calculationDay, BigInteger targetDay, int queriedBowlId)
    {
        if (queriedBowlId is < 1 or > 6)
            throw new MonsterValidationException("هوية الوعاء المطلوبة خارج المجال.");
        var context=Prepare(calculationDay,targetDay);
        context.LegacyQueriedBowlId=queriedBowlId;
        _dispatcher.DispatchLegacyFixedNextBowl(context);
        return context;
    }

    public int EvaluateLegacyFixedNextBowl(
        BigInteger calculationDay, BigInteger targetDay, int queriedBowlId)
        => ExecuteLegacyFixedNextBowl(calculationDay,targetDay,queriedBowlId)
            .LegacyFixedNextBowlResult ??
            throw new MonsterValidationException("لم يكتمل اختيار الجار القديم.");


    public MonsterContext ExecutePatchedNextBowl(
        BigInteger calculationDay, BigInteger targetDay, int queriedBowlId)
    {
        if (queriedBowlId is < 1 or > 6)
            throw new MonsterValidationException("هوية الوعاء المطلوبة خارج المجال.");
        var context = Prepare(calculationDay,targetDay);
        context.LegacyQueriedBowlId = queriedBowlId;
        _dispatcher.DispatchPatchedNextBowl(context);
        return context;
    }

    public int EvaluateNextBowl(
        BigInteger calculationDay, BigInteger targetDay, int queriedBowlId)
        => ExecutePatchedNextBowl(calculationDay,targetDay,queriedBowlId)
            .PatchedNextBowlResult ??
            throw new MonsterValidationException("لم يُنتج مسار الرقعة الجار المصحح.");


    public MonsterContext ExecuteLegacyUnsealedBowlQuestion(
        BigInteger calculationDay,BigInteger targetDay,int queriedBowlId,int seal)
    {
        if (queriedBowlId is < 1 or > 6 || seal is not (21 or 31))
            throw new MonsterValidationException("معرّف الوعاء أو حاتم السؤال غير صالح.");
        var context=Prepare(calculationDay,targetDay);
        context.LegacyQueriedBowlId=queriedBowlId;
        context.LegacyBowlQuestionSeal=seal;
        _dispatcher.DispatchLegacyUnsealedBowlQuestion(context);
        return context;
    }

    public LegacyBowlQuestionResult EvaluateLegacyUnsealedBowlQuestion(
        BigInteger calculationDay,BigInteger targetDay,int queriedBowlId,int seal)
        => ExecuteLegacyUnsealedBowlQuestion(
            calculationDay,targetDay,queriedBowlId,seal)
            .LegacyUnsealedBowlQuestionResult ??
            throw new MonsterValidationException("لم يكتمل سؤال الصلصة التاريخي.");


    public MonsterContext ExecutePatchedBowlQuestion(
        BigInteger calculationDay,BigInteger targetDay,int queriedBowlId,int seal)
    {
        if (queriedBowlId is < 1 or > 6 || seal is not (21 or 31))
            throw new MonsterValidationException("رقم الوعاء أو حاتم السؤال غير صالح.");
        var context=Prepare(calculationDay,targetDay);
        context.LegacyQueriedBowlId=queriedBowlId;
        context.LegacyBowlQuestionSeal=seal;
        _dispatcher.DispatchPatchedBowlQuestion(context);
        return context;
    }

    public LegacyBowlQuestionResult EvaluateBowlQuestion(
        BigInteger calculationDay,BigInteger targetDay,int queriedBowlId,int seal)
        => ExecutePatchedBowlQuestion(calculationDay,targetDay,queriedBowlId,seal)
            .PatchedBowlQuestionResult ??
            throw new MonsterValidationException("لم يكتمل جواب سؤال الصلصة المصحح.");


    public MonsterContext ExecuteLegacyOneBasedAnswer(
        BigInteger calculationDay, BigInteger targetDay,
        int queriedBowlId, int seal, BigInteger k)
    {
        if (queriedBowlId is < 1 or > 6 || seal is not (21 or 31) || k < 0)
            throw new MonsterValidationException("مدخلات تيار الإجابات التاريخي غير مقبولة.");
        var context=Prepare(calculationDay,targetDay);
        context.LegacyQueriedBowlId=queriedBowlId;
        context.LegacyBowlQuestionSeal=seal;
        context.LegacyAnswerStepIndex=k;
        _dispatcher.DispatchLegacyOneBasedAnswer(context);
        return context;
    }

    public BigInteger EvaluateLegacyOneBasedAnswer(
        BigInteger calculationDay, BigInteger targetDay,
        int queriedBowlId, int seal, BigInteger k)
        => ExecuteLegacyOneBasedAnswer(calculationDay,targetDay,queriedBowlId,seal,k)
            .LegacyOneBasedAnswerAtResult ??
            throw new MonsterValidationException("لم تُنتج الخطوة التاريخية جواباً.");


    public MonsterContext ExecutePatchedAnswerStep(
        BigInteger calculationDay,BigInteger targetDay,
        int queriedBowlId,int seal,BigInteger k)
    {
        if (queriedBowlId is < 1 or > 6 || seal is not (21 or 31) || k<0)
            throw new MonsterValidationException("هوية الوعاء أو حاتمه أو رقم الخطوة غير مقبول.");
        var context=Prepare(calculationDay,targetDay);
        context.LegacyQueriedBowlId=queriedBowlId;
        context.LegacyBowlQuestionSeal=seal;
        context.LegacyAnswerStepIndex=k;
        _dispatcher.DispatchPatchedAnswerStep(context);
        return context;
    }

    public BigInteger EvaluateAnswerAt(
        BigInteger calculationDay,BigInteger targetDay,
        int queriedBowlId,int seal,BigInteger k)
        => ExecutePatchedAnswerStep(
            calculationDay,targetDay,queriedBowlId,seal,k)
           .PatchedAnswerAtResult ??
           throw new MonsterValidationException("لم يُنتج تيار الإجابات خطوة مصححة.");


    public MonsterContext ExecuteLegacyUnshiftedShortRank(
        BigInteger calculationDay,BigInteger targetDay,
        int queriedBowlId,int seal,BigInteger familySize)
    {
        if(queriedBowlId is < 1 or > 6 || seal is not (21 or 31) ||
           familySize<1 || familySize>((BigInteger.One<<127)-BigInteger.One))
            throw new MonsterValidationException("مدخلات الأسرة القصيرة غير صالحة.");
        var context=Prepare(calculationDay,targetDay);
        context.LegacyQueriedBowlId=queriedBowlId;
        context.LegacyBowlQuestionSeal=seal;
        context.LegacyAnswerStepIndex=BigInteger.Zero;
        context.LegacyShortFamilySize=familySize;
        _dispatcher.DispatchLegacyUnshiftedShortRank(context);
        return context;
    }

    public BigInteger EvaluateLegacyUnshiftedShortRank(
        BigInteger calculationDay,BigInteger targetDay,
        int queriedBowlId,int seal,BigInteger familySize)
        => ExecuteLegacyUnshiftedShortRank(
            calculationDay,targetDay,queriedBowlId,seal,familySize)
            .LegacyShortFamilyRankResult ??
            throw new MonsterValidationException("لم تكتمل رتبة الأسرة القصيرة التاريخية.");


    public MonsterContext ExecutePatchedShortRank(
        BigInteger calculationDay,BigInteger targetDay,
        int queriedBowlId,int seal,BigInteger familySize)
    {
        if(queriedBowlId is < 1 or > 6 || seal is not (21 or 31) ||
           familySize<1 || familySize>((BigInteger.One<<127)-BigInteger.One))
            throw new MonsterValidationException("مدخلات رقعة الأسرة القصيرة غير صالحة.");
        var context=Prepare(calculationDay,targetDay);
        context.LegacyQueriedBowlId=queriedBowlId;
        context.LegacyBowlQuestionSeal=seal;
        context.LegacyAnswerStepIndex=BigInteger.Zero;
        context.LegacyShortFamilySize=familySize;
        _dispatcher.DispatchPatchedShortRank(context);
        return context;
    }

    public BigInteger EvaluateShortFamilyRank(
        BigInteger calculationDay,BigInteger targetDay,
        int queriedBowlId,int seal,BigInteger familySize)
        => ExecutePatchedShortRank(
            calculationDay,targetDay,queriedBowlId,seal,familySize)
            .PatchedShortFamilyRankResult ??
            throw new MonsterValidationException("لم تُنتج الأسرة القصيرة رتبة مصححة.");


    public MonsterContext ExecuteLegacyReversedWideRank(
        BigInteger calculationDay,BigInteger targetDay,
        int queriedBowlId,int seal,BigInteger familySize)
    {
        if(queriedBowlId is < 1 or > 6 || seal is not (21 or 31) ||
           familySize<=((BigInteger.One<<127)-BigInteger.One))
            throw new MonsterValidationException("سؤال الأسرة الواسعة غير صالح.");
        var context=Prepare(calculationDay,targetDay);
        context.LegacyQueriedBowlId=queriedBowlId;
        context.LegacyBowlQuestionSeal=seal;
        context.LegacyAnswerStepIndex=BigInteger.Zero;
        context.LegacyWideFamilySize=familySize;
        _dispatcher.DispatchLegacyReversedWideRank(context);
        return context;
    }

    public BigInteger EvaluateLegacyReversedWideRank(
        BigInteger calculationDay,BigInteger targetDay,
        int queriedBowlId,int seal,BigInteger familySize)
        => ExecuteLegacyReversedWideRank(
            calculationDay,targetDay,queriedBowlId,seal,familySize)
            .LegacyReversedWideRankResult ??
            throw new MonsterValidationException("لم تكتمل نتيجة الأسرة الواسعة القديمة.");


    public MonsterContext ExecutePatchedWideRank(
        BigInteger calculationDay,BigInteger targetDay,
        int queriedBowlId,int seal,BigInteger familySize)
    {
        if(queriedBowlId is < 1 or > 6 || seal is not (21 or 31) ||
           familySize<=((BigInteger.One<<127)-BigInteger.One))
            throw new MonsterValidationException("سؤال الأسرة الواسعة غير صالح.");
        var context=Prepare(calculationDay,targetDay);
        context.LegacyQueriedBowlId=queriedBowlId;
        context.LegacyBowlQuestionSeal=seal;
        context.LegacyAnswerStepIndex=BigInteger.Zero;
        context.LegacyWideFamilySize=familySize;
        _dispatcher.DispatchPatchedWideRank(context);
        return context;
    }

    public BigInteger EvaluateWideFamilyRank(
        BigInteger calculationDay,BigInteger targetDay,
        int queriedBowlId,int seal,BigInteger familySize)
        => ExecutePatchedWideRank(calculationDay,targetDay,queriedBowlId,seal,familySize)
            .PatchedWideRankResult ??
            throw new MonsterValidationException("لم تصدر رتبة الأسرة الواسعة المصححة.");


    public MonsterContext ExecuteLegacyInclusiveWideLimit(
        BigInteger calculationDay,BigInteger targetDay,
        int queriedBowlId,int seal,BigInteger familySize)
    {
        if(queriedBowlId is < 1 or > 6 || seal is not (21 or 31) ||
           familySize<=((BigInteger.One<<127)-BigInteger.One))
            throw new MonsterValidationException("مدخلات الأسرة الواسعة غير صالحة.");
        var context=Prepare(calculationDay,targetDay);
        context.LegacyQueriedBowlId=queriedBowlId;
        context.LegacyBowlQuestionSeal=seal;
        context.LegacyAnswerStepIndex=BigInteger.Zero;
        context.LegacyWideFamilySize=familySize;
        _dispatcher.DispatchLegacyInclusiveWideLimit(context);
        return context;
    }

    public BigInteger EvaluateLegacyInclusiveWideLimit(
        BigInteger calculationDay,BigInteger targetDay,
        int queriedBowlId,int seal,BigInteger familySize)
        => ExecuteLegacyInclusiveWideLimit(calculationDay,targetDay,queriedBowlId,seal,familySize)
           .LegacyInclusiveWideLimitRankResult ??
           throw new MonsterValidationException("لم يصدر شاهد الحدّ التاريخي.");

    public MonsterContext ExecutePatchedInclusiveWideLimit(
        BigInteger calculationDay,BigInteger targetDay,
        int queriedBowlId,int seal,BigInteger familySize)
    {
        if(queriedBowlId is < 1 or > 6 || seal is not (21 or 31) ||
           familySize<=((BigInteger.One<<127)-BigInteger.One))
            throw new MonsterValidationException("مدخلات الأسرة الواسعة غير صالحة.");
        var context=Prepare(calculationDay,targetDay);
        context.LegacyQueriedBowlId=queriedBowlId;
        context.LegacyBowlQuestionSeal=seal;
        context.LegacyAnswerStepIndex=BigInteger.Zero;
        context.LegacyWideFamilySize=familySize;
        _dispatcher.DispatchPatchedInclusiveWideLimit(context);
        return context;
    }

    public BigInteger EvaluateInclusiveWideLimit(
        BigInteger calculationDay,BigInteger targetDay,
        int queriedBowlId,int seal,BigInteger familySize)
        => ExecutePatchedInclusiveWideLimit(calculationDay,targetDay,queriedBowlId,seal,familySize)
           .PatchedInclusiveWideLimitRankResult ??
           throw new MonsterValidationException("لم تصدر رتبة قبول الحدّ المصححة.");

    public MonsterContext ExecuteLegacyWideRejectionDirection(
        BigInteger calculationDay,BigInteger targetDay,
        int queriedBowlId,int seal,BigInteger familySize)
    {
        if(queriedBowlId is < 1 or > 6 || seal is not (21 or 31) ||
           familySize<=((BigInteger.One<<127)-BigInteger.One))
            throw new MonsterValidationException("مدخلات الأسرة الواسعة غير صالحة.");
        var context=Prepare(calculationDay,targetDay);
        context.LegacyQueriedBowlId=queriedBowlId;
        context.LegacyBowlQuestionSeal=seal;
        context.LegacyAnswerStepIndex=BigInteger.Zero;
        context.LegacyWideFamilySize=familySize;
        _dispatcher.DispatchLegacyWideRejectionDirection(context);
        return context;
    }

    public BigInteger EvaluateLegacyWideRejectionDirection(
        BigInteger calculationDay,BigInteger targetDay,
        int queriedBowlId,int seal,BigInteger familySize)
        => ExecuteLegacyWideRejectionDirection(calculationDay,targetDay,queriedBowlId,seal,familySize)
           .LegacyRejectionDirectionRankResult ??
           throw new MonsterValidationException("لم يصدر شاهد اتجاه رفض الأسرة الواسعة.");

    public MonsterContext ExecutePatchedRejectionDirection(
        BigInteger calculationDay,BigInteger targetDay,
        int queriedBowlId,int seal,BigInteger familySize)
    {
        if(queriedBowlId is < 1 or > 6 || seal is not (21 or 31) ||
           familySize<=((BigInteger.One<<127)-BigInteger.One))
            throw new MonsterValidationException("مدخلات الأسرة الواسعة غير صالحة.");
        var context=Prepare(calculationDay,targetDay);
        context.LegacyQueriedBowlId=queriedBowlId;
        context.LegacyBowlQuestionSeal=seal;
        context.LegacyAnswerStepIndex=BigInteger.Zero;
        context.LegacyWideFamilySize=familySize;
        _dispatcher.DispatchPatchedRejectionDirection(context);
        return context;
    }

    public BigInteger EvaluateRejectionDirection(
        BigInteger calculationDay,BigInteger targetDay,
        int queriedBowlId,int seal,BigInteger familySize)
        => ExecutePatchedRejectionDirection(calculationDay,targetDay,queriedBowlId,seal,familySize)
           .PatchedRejectionDirectionRankResult ??
           throw new MonsterValidationException("لم يصدر شاهد اتجاه رفض الأسرة الواسعة.");

    public MonsterContext ExecuteLegacyDoubleOffsetWideRank(
        BigInteger calculationDay,BigInteger targetDay,
        int queriedBowlId,int seal,BigInteger familySize)
    {
        if(queriedBowlId is < 1 or > 6 || seal is not (21 or 31) ||
           familySize<=((BigInteger.One<<127)-BigInteger.One))
            throw new MonsterValidationException("مدخلات الأسرة الواسعة غير صالحة.");
        var context=Prepare(calculationDay,targetDay);
        context.LegacyQueriedBowlId=queriedBowlId;
        context.LegacyBowlQuestionSeal=seal;
        context.LegacyAnswerStepIndex=BigInteger.Zero;
        context.LegacyWideFamilySize=familySize;
        _dispatcher.DispatchLegacyDoubleOffsetWideRank(context);
        return context;
    }

    public BigInteger EvaluateLegacyDoubleOffsetWideRank(
        BigInteger calculationDay,BigInteger targetDay,
        int queriedBowlId,int seal,BigInteger familySize)
        => ExecuteLegacyDoubleOffsetWideRank(calculationDay,targetDay,queriedBowlId,seal,familySize)
           .LegacyDoubleOffsetWideRankResult ??
           throw new MonsterValidationException("لم يصدر شاهد إخراج المرتبة الواسعة التاريخي.");

    public MonsterContext ExecutePatchedDoubleOffsetWideRank(
        BigInteger calculationDay,BigInteger targetDay,
        int queriedBowlId,int seal,BigInteger familySize)
    {
        if(queriedBowlId is < 1 or > 6 || seal is not (21 or 31) ||
           familySize<=((BigInteger.One<<127)-BigInteger.One))
            throw new MonsterValidationException("مدخلات الأسرة الواسعة غير صالحة.");
        var context=Prepare(calculationDay,targetDay);
        context.LegacyQueriedBowlId=queriedBowlId;
        context.LegacyBowlQuestionSeal=seal;
        context.LegacyAnswerStepIndex=BigInteger.Zero;
        context.LegacyWideFamilySize=familySize;
        _dispatcher.DispatchPatchedDoubleOffsetWideRank(context);
        return context;
    }

    public BigInteger EvaluateDoubleOffsetWideRank(
        BigInteger calculationDay,BigInteger targetDay,
        int queriedBowlId,int seal,BigInteger familySize)
        => ExecutePatchedDoubleOffsetWideRank(calculationDay,targetDay,queriedBowlId,seal,familySize)
           .PatchedDoubleOffsetWideRankResult ??
           throw new MonsterValidationException("لم تصدر الرتبة الواسعة المصححة.");

    public BigInteger EvaluateSave(BigInteger calculationDay, BigInteger targetDay, BigInteger value)
    {
        var context = ExecuteSavePatched(calculationDay, targetDay, value);
        return context.PatchedSaveResult
            ?? throw new MonsterValidationException("لم يُنتج مسار الرقعة قيمة محفوظة.");
    }
}
