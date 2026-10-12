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

    public BigInteger EvaluateSave(BigInteger calculationDay, BigInteger targetDay, BigInteger value)
    {
        var context = ExecuteSavePatched(calculationDay, targetDay, value);
        return context.PatchedSaveResult
            ?? throw new MonsterValidationException("لم يُنتج مسار الرقعة قيمة محفوظة.");
    }
}
