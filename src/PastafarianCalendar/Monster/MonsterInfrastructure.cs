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

    public BigInteger EvaluateSave(BigInteger calculationDay, BigInteger targetDay, BigInteger value)
    {
        var context = ExecuteSavePatched(calculationDay, targetDay, value);
        return context.PatchedSaveResult
            ?? throw new MonsterValidationException("لم يُنتج مسار الرقعة قيمة محفوظة.");
    }
}
